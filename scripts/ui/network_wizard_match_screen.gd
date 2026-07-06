extends "res://scripts/ui/wizard_match_screen.gd"

var match_bridge: NetworkMatchBridge
var transient_message := ""
var new_match_button: Button


func _ready() -> void:
	match_bridge = get_node("/root/Bootstrap/NetworkRoot/MatchBridge")
	match_bridge.snapshot_applied.connect(_on_snapshot_applied)
	match_bridge.action_rejected.connect(_on_action_rejected)
	match_bridge.connection_succeeded.connect(_on_connection_succeeded)
	match_bridge.connection_failed.connect(_on_connection_failed)
	match_bridge.server_disconnected.connect(_on_server_disconnected)
	match_bridge.session_updated.connect(_on_session_updated)
	ai_enabled_by_color[ChessEngine.WHITE] = false
	ai_enabled_by_color[ChessEngine.BLACK] = false
	super._ready()
	new_match_button = get_node("HudLayer/HeaderBar/NewMatchButton") as Button
	match_sidebar.white_ai_button.disabled = true
	match_sidebar.black_ai_button.disabled = true
	_refresh_host_controls()


func _start_new_match() -> void:
	wizard_match = match_bridge.wizard_match
	selected_square = null
	selected_moves.clear()
	selected_card_instance_id = ""
	selected_hand_card_ids.clear()
	hovered_square = null
	hovered_card_widget = null
	interaction_controller.reset_drag()
	processed_event_count = 0
	recent_notifications.clear()
	rendered_perspective_color = ""
	utility_sidebar_open = false
	_update_utility_sidebar_visibility()
	match_sidebar.set_ai_status("Network", "Server-authoritative WizardMatch")
	transient_message = ""
	_refresh_ui()
	previous_state_snapshot = wizard_match.create_state_snapshot()


func _refresh_status() -> void:
	_refresh_host_controls()
	super._refresh_status()
	var local_color := match_bridge.get_local_player_color()
	var local_player_id := match_bridge.get_local_player_id()
	if local_color.is_empty():
		status_label.text = "Seat: pending assignment\n%s" % status_label.text
		detail_label.text = "Waiting for a player assignment from the server."
		return

	status_label.text = "Seat: %s (%s)\n%s" % [
		local_color.capitalize(),
		local_player_id,
		status_label.text,
	]
	if not transient_message.is_empty():
		detail_label.text = transient_message
		return

	if wizard_match.state == WizardMatch.STATE_SETUP:
		if match_bridge.is_local_players_turn():
			detail_label.text = "Opening hand. Choose cards to keep or replace."
		else:
			detail_label.text = "Opening hand. Waiting for %s." % _current_actor_color().capitalize()
	elif match_bridge.is_local_players_turn():
		detail_label.text = "You are %s. %s" % [
			local_color.capitalize(),
			_phase_prompt_text(),
		]
	else:
		var actor := _current_actor_color()
		detail_label.text = "You are %s. Waiting for %s." % [
			local_color.capitalize(),
			"the server" if actor.is_empty() else actor.capitalize(),
		]
	detail_label.text += "\n%s" % _seat_summary_text()


func _refresh_action_bar() -> void:
	turn_action_panel.clear_actions()
	var local_color := match_bridge.get_local_player_color()
	if local_color.is_empty():
		turn_action_panel.set_phase_summary("Waiting", "Awaiting a seat assignment from the server.")
		return

	if wizard_match.state == WizardMatch.STATE_COMPLETE:
		if multiplayer.is_server():
			_add_action_button("New Match", _on_new_match_pressed, false, true)
			turn_action_panel.set_phase_summary("Complete", "Host can reset the match.")
		else:
			turn_action_panel.set_phase_summary("Complete", "Waiting for the host to reset the match.")
		return

	if not match_bridge.is_local_players_turn():
		var actor := _current_actor_color()
		turn_action_panel.set_phase_summary(
			"Waiting",
			"Priority belongs to %s." % ("the other player" if actor.is_empty() else actor.capitalize())
		)
		return

	super._refresh_action_bar()


func _refresh_settings_controls() -> void:
	var perspective_index := 0
	match perspective_mode:
		PerspectiveMode.WHITE:
			perspective_index = 1
		PerspectiveMode.BLACK:
			perspective_index = 2
	match_sidebar.set_settings(
		threat_overlay_enabled,
		show_coordinates,
		perspective_index,
		false,
		false
	)


func _refresh_ai_timings() -> void:
	match_sidebar.set_ai_timing_text("Network match\nLocal AI controls disabled")


func _display_color() -> String:
	match perspective_mode:
		PerspectiveMode.WHITE:
			return ChessEngine.WHITE
		PerspectiveMode.BLACK:
			return ChessEngine.BLACK
		_:
			pass
	var local_color := match_bridge.get_local_player_color()
	return ChessEngine.WHITE if local_color.is_empty() else local_color


func _on_ai_toggle(_enabled: bool, _color: String) -> void:
	_refresh_settings_controls()


func _on_new_match_pressed() -> void:
	_request_reset()


func _on_keep_hand_pressed() -> void:
	_submit_network_action({
		"type": WizardMatch.ACTION_TYPE_KEEP_OPENING_HAND,
	}, "Keep hand")


func _on_mulligan_selected_pressed() -> void:
	var ids: Array[String] = []
	for card_id in selected_hand_card_ids.keys():
		ids.append(str(card_id))
	_submit_network_action({
		"type": WizardMatch.ACTION_TYPE_PERFORM_MULLIGAN,
		"card_instance_ids": ids,
	}, "Mulligan selected")


func _on_mulligan_all_pressed() -> void:
	var ids: Array[String] = []
	for card_state_value in wizard_match.get_player_state(_display_color()).get("hand", []):
		ids.append(str(card_state_value["instance_id"]))
	_submit_network_action({
		"type": WizardMatch.ACTION_TYPE_PERFORM_MULLIGAN,
		"card_instance_ids": ids,
	}, "Mulligan all")


func _on_resolve_beginning_pressed() -> void:
	_submit_network_action({
		"type": WizardMatch.ACTION_TYPE_ADVANCE_PHASE,
	}, "Resolve beginning")


func _on_finish_preparation_pressed() -> void:
	_submit_network_action({
		"type": WizardMatch.ACTION_TYPE_ADVANCE_PHASE,
	}, "Finish preparation")


func _on_pass_reaction_pressed() -> void:
	_submit_network_action({
		"type": WizardMatch.ACTION_TYPE_ADVANCE_PHASE,
	}, "Pass priority")


func _on_resolve_end_pressed() -> void:
	_submit_network_action({
		"type": WizardMatch.ACTION_TYPE_ADVANCE_PHASE,
	}, "Resolve end")


func _on_play_selected_card_pressed() -> void:
	var action := _first_zero_target_action(_selected_card_actions())
	if action.is_empty():
		return
	_submit_network_action({
		"type": WizardMatch.ACTION_TYPE_PLAY_CARD,
		"card_instance_id": str(action["card_instance_id"]),
		"targets": action.get("targets", []),
	}, "Play selected card")


func _play_selected_card_on_square(square: Vector2i) -> void:
	var action_value: Variant = _matching_card_action_for_square(selected_card_instance_id, square)
	if action_value == null:
		return
	var action: Dictionary = action_value
	_submit_network_action({
		"type": WizardMatch.ACTION_TYPE_PLAY_CARD,
		"card_instance_id": str(action["card_instance_id"]),
		"targets": action.get("targets", []),
	}, "Play targeted card")


func _on_discard_selected_pressed() -> void:
	var ids: Array[String] = []
	for card_id in selected_hand_card_ids.keys():
		ids.append(str(card_id))
	_submit_network_action({
		"type": WizardMatch.ACTION_TYPE_DISCARD_FOR_HAND_LIMIT,
		"card_instance_ids": ids,
	}, "Discard selected")


func _commit_move(move: Dictionary) -> void:
	_submit_network_action(
		wizard_match.chess_engine.create_move_action(move["from"], move["to"], str(move.get("promotion", "queen"))),
		"Move %s to %s" % [
			wizard_match.chess_engine.square_to_algebraic(move["from"]),
			wizard_match.chess_engine.square_to_algebraic(move["to"]),
		]
	)


func _request_claim_draw() -> void:
	_submit_network_action({
		"type": ChessEngine.ACTION_TYPE_CLAIM_DRAW,
	}, "Claim draw")


func _request_reset() -> void:
	if match_bridge.reset_match():
		transient_message = ""
		return
	transient_message = "Only the host can reset the match."
	_refresh_ui()


func _on_snapshot_applied(_snapshot: Dictionary) -> void:
	var before_snapshot := previous_state_snapshot.duplicate(true)
	transient_message = ""
	processed_event_count = 0
	_refresh_ui()
	var after_snapshot := wizard_match.create_state_snapshot()
	call_deferred("_animate_state_transition", before_snapshot, after_snapshot)
	previous_state_snapshot = after_snapshot


func _on_action_rejected(_action: Dictionary, reason: String) -> void:
	transient_message = _rejection_text(reason)
	match_sidebar.set_ai_action_text("Rejected: %s" % reason)
	_refresh_ui()


func _on_connection_succeeded() -> void:
	transient_message = ""
	_refresh_ui()


func _on_connection_failed() -> void:
	transient_message = "Connection failed."
	_refresh_ui()


func _on_server_disconnected() -> void:
	transient_message = "Disconnected from server."
	_refresh_ui()


func _on_session_updated(_player_id: String, _color: String) -> void:
	transient_message = ""
	_refresh_ui()


func _refresh_host_controls() -> void:
	if new_match_button == null:
		return
	new_match_button.visible = multiplayer.is_server()


func _submit_network_action(action: Dictionary, label: String) -> void:
	transient_message = ""
	selected_moves.clear()
	selected_card_instance_id = ""
	selected_hand_card_ids.clear()
	interaction_controller.reset_drag()
	hovered_square = null
	match_sidebar.set_ai_action_text("%s: pending server" % label)
	match_bridge.submit_local_action(action)
	_refresh_ui()


func _phase_prompt_text() -> String:
	match wizard_match.phase:
		WizardMatch.PHASE_BEGINNING:
			return "Resolve the beginning phase."
		WizardMatch.PHASE_PREPARATION:
			return "Play cards or finish preparation."
		WizardMatch.PHASE_MOVE:
			return "Move a legal piece."
		WizardMatch.PHASE_REACTION:
			return "Play a reaction or pass priority."
		WizardMatch.PHASE_END:
			var discard_count := wizard_match.get_pending_hand_limit_discard_count(_display_color())
			if discard_count > 0:
				return "Discard %d card(s)." % discard_count
			return "Resolve the end phase."
		_:
			return "Inspect the match state."


func _seat_summary_text() -> String:
	var assignments := match_bridge.get_player_color_assignments()
	var white_assignment: Dictionary = assignments.get(ChessEngine.WHITE, {})
	var black_assignment: Dictionary = assignments.get(ChessEngine.BLACK, {})
	return "White: %s | Black: %s" % [
		_format_seat_summary(white_assignment),
		_format_seat_summary(black_assignment),
	]


func _format_seat_summary(assignment: Dictionary) -> String:
	if assignment.is_empty():
		return "open"
	return "%s (%s)" % [
		str(assignment.get("player_id", "")),
		"connected" if bool(assignment.get("connected", false)) else "disconnected",
	]


func _rejection_text(reason: String) -> String:
	match reason:
		"peer_not_registered":
			return "You are not registered with the match yet."
		"match_full":
			return "That match is already full."
		"session_already_active":
			return "That saved session is already active. Use a different client profile for another local client."
		"peer_not_assigned":
			return "The server has not assigned you a seat yet."
		"not_your_turn":
			return "It is not your turn."
		"illegal_move":
			return "The server rejected that move as illegal."
		"draw_unavailable":
			return "A draw cannot be claimed right now."
		"reaction_only_phase":
			return "That card can only be played during the reaction phase."
		"preparation_only_card_type":
			return "Only reaction cards may be played right now."
		"not_reaction_priority":
			return "You do not currently have reaction priority."
		"reaction_trigger_inactive":
			return "That reaction does not match the current trigger window."
		"insufficient_mana":
			return "You do not have enough mana for that card."
		"incorrect_target_count":
			return "That card needs a different number of targets."
		"invalid_target":
			return "The chosen targets are not legal."
		"card_not_in_hand":
			return "That card is no longer in your hand."
		"hand_limit_discard_pending":
			return "Resolve the required discard before taking another action."
		"incorrect_discard_count":
			return "Select exactly the required number of cards to discard."
		_:
			return "Action rejected: %s" % reason
