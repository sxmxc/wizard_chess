extends Control

const LIGHT_SQUARE := Color("e7d7b1")
const DARK_SQUARE := Color("9f7b55")
const SELECTED_SQUARE := Color("7fc97f")
const LEGAL_SQUARE := Color("f6d365")

const RULES_RESOURCE_PATH := "res://content/config/default_wizard_match_rules.tres"
const DECK_RESOURCE_PATH := "res://content/decks/sample_ai_battle_deck.tres"
const WHITE_AI_PROFILE_PATH := "res://content/ai/beginner_aggressive_ai.tres"
const BLACK_AI_PROFILE_PATH := "res://content/ai/intermediate_positional_ai.tres"
const AI_STEP_DELAY_SECONDS := 0.03

var wizard_match: WizardMatch
var match_rules: WizardMatchRules
var match_deck: DeckDefinition
var ai_controllers := {}
var ai_enabled_by_color := {
	ChessMatch.WHITE: false,
	ChessMatch.BLACK: true,
}

var selected_square: Variant = null
var selected_moves: Array = []
var board_buttons := {}

var status_label: Label
var detail_label: Label
var white_summary_label: Label
var black_summary_label: Label
var white_hand_list: ItemList
var black_hand_list: ItemList
var effects_label: Label
var last_ai_action_label: Label
var ai_timing_label: Label
var action_panel: VBoxContainer
var move_history_list: ItemList
var event_history_list: ItemList
var white_ai_button: Button
var black_ai_button: Button
var ai_timer: Timer


func _ready() -> void:
	_load_resources()
	_build_ui()
	_start_new_match()


func _load_resources() -> void:
	match_rules = load(RULES_RESOURCE_PATH) as WizardMatchRules
	match_deck = CardCatalog.load_deck_definition(DECK_RESOURCE_PATH)
	ai_controllers = {
		ChessMatch.WHITE: WizardMatchAiController.new(load(WHITE_AI_PROFILE_PATH) as WizardMatchAiProfile),
		ChessMatch.BLACK: WizardMatchAiController.new(load(BLACK_AI_PROFILE_PATH) as WizardMatchAiProfile),
	}


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	ai_timer = Timer.new()
	ai_timer.one_shot = true
	ai_timer.wait_time = AI_STEP_DELAY_SECONDS
	ai_timer.timeout.connect(_on_ai_timer_timeout)
	add_child(ai_timer)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var board_column := VBoxContainer.new()
	board_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_column.add_theme_constant_override("separation", 8)
	root.add_child(board_column)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 22)
	board_column.add_child(status_label)

	detail_label = Label.new()
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	board_column.add_child(detail_label)

	var board_grid := GridContainer.new()
	board_grid.columns = 8
	board_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_grid.add_theme_constant_override("h_separation", 2)
	board_grid.add_theme_constant_override("v_separation", 2)
	board_column.add_child(board_grid)

	for rank in range(8):
		for file in range(8):
			var square := Vector2i(file, rank)
			var button := Button.new()
			button.custom_minimum_size = Vector2(78, 78)
			button.clip_text = true
			button.pressed.connect(_on_board_square_pressed.bind(square))
			board_grid.add_child(button)
			board_buttons[square] = button

	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size = Vector2(440, 0)
	sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_theme_constant_override("separation", 10)
	root.add_child(sidebar)

	var title := Label.new()
	title.text = "Wizard Match Dev UI"
	title.add_theme_font_size_override("font_size", 20)
	sidebar.add_child(title)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	sidebar.add_child(button_row)

	var reset_button := Button.new()
	reset_button.text = "New Match"
	reset_button.pressed.connect(_on_new_match_pressed)
	button_row.add_child(reset_button)

	var step_ai_button := Button.new()
	step_ai_button.text = "Step AI"
	step_ai_button.pressed.connect(_on_step_ai_pressed)
	button_row.add_child(step_ai_button)

	var use_ai_button := Button.new()
	use_ai_button.text = "Use AI Suggestion"
	use_ai_button.pressed.connect(_on_use_ai_suggestion_pressed)
	button_row.add_child(use_ai_button)

	var ai_row := HBoxContainer.new()
	ai_row.add_theme_constant_override("separation", 8)
	sidebar.add_child(ai_row)

	white_ai_button = Button.new()
	white_ai_button.toggle_mode = true
	white_ai_button.toggled.connect(_on_ai_toggle.bind(ChessMatch.WHITE))
	ai_row.add_child(white_ai_button)

	black_ai_button = Button.new()
	black_ai_button.toggle_mode = true
	black_ai_button.toggled.connect(_on_ai_toggle.bind(ChessMatch.BLACK))
	ai_row.add_child(black_ai_button)

	last_ai_action_label = Label.new()
	last_ai_action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sidebar.add_child(last_ai_action_label)

	ai_timing_label = Label.new()
	ai_timing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sidebar.add_child(ai_timing_label)

	white_summary_label = Label.new()
	white_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sidebar.add_child(white_summary_label)

	var white_hand_title := Label.new()
	white_hand_title.text = "White Hand"
	sidebar.add_child(white_hand_title)

	white_hand_list = ItemList.new()
	white_hand_list.custom_minimum_size = Vector2(0, 92)
	white_hand_list.select_mode = ItemList.SELECT_SINGLE
	sidebar.add_child(white_hand_list)

	black_summary_label = Label.new()
	black_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sidebar.add_child(black_summary_label)

	var black_hand_title := Label.new()
	black_hand_title.text = "Black Hand"
	sidebar.add_child(black_hand_title)

	black_hand_list = ItemList.new()
	black_hand_list.custom_minimum_size = Vector2(0, 92)
	black_hand_list.select_mode = ItemList.SELECT_SINGLE
	sidebar.add_child(black_hand_list)

	effects_label = Label.new()
	effects_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sidebar.add_child(effects_label)

	var actions_title := Label.new()
	actions_title.text = "Available Actions"
	actions_title.add_theme_font_size_override("font_size", 18)
	sidebar.add_child(actions_title)

	var actions_scroll := ScrollContainer.new()
	actions_scroll.custom_minimum_size = Vector2(0, 180)
	actions_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(actions_scroll)

	action_panel = VBoxContainer.new()
	action_panel.add_theme_constant_override("separation", 6)
	actions_scroll.add_child(action_panel)

	var history_split := HSplitContainer.new()
	history_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(history_split)

	var move_column := VBoxContainer.new()
	history_split.add_child(move_column)

	var move_title := Label.new()
	move_title.text = "Move History"
	move_column.add_child(move_title)

	move_history_list = ItemList.new()
	move_history_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	move_column.add_child(move_history_list)

	var event_column := VBoxContainer.new()
	history_split.add_child(event_column)

	var event_title := Label.new()
	event_title.text = "Event Log"
	event_column.add_child(event_title)

	event_history_list = ItemList.new()
	event_history_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	event_column.add_child(event_history_list)


func _start_new_match() -> void:
	wizard_match = WizardMatch.new(match_rules)
	last_ai_action_label.text = "AI: ready"
	ai_timing_label.text = "AI timings: no samples yet"
	selected_square = null
	selected_moves.clear()
	wizard_match.start_match(match_deck, match_deck, 17)
	white_ai_button.button_pressed = ai_enabled_by_color[ChessMatch.WHITE]
	black_ai_button.button_pressed = ai_enabled_by_color[ChessMatch.BLACK]
	_refresh_ui()
	_queue_ai_step_if_needed()


func _refresh_ui() -> void:
	_refresh_status()
	_refresh_board()
	_refresh_player_summaries()
	_refresh_hand_lists()
	_refresh_effects()
	_refresh_histories()
	_refresh_action_panel()
	_refresh_ai_buttons()
	_refresh_ai_timings()


func _refresh_status() -> void:
	var actor := _current_actor_color()
	var actor_label := "None" if actor.is_empty() else actor.capitalize()
	var chess_outcome := wizard_match.chess_state.outcome
	status_label.text = "State: %s | Phase: %s | Actor: %s | Turn: %d" % [
		wizard_match.state.capitalize(),
		wizard_match.phase.capitalize(),
		actor_label,
		wizard_match.turn_number,
	]
	if chess_outcome["status"] != ChessMatch.STATUS_ACTIVE:
		status_label.text += " | Chess: %s" % _chess_outcome_text(chess_outcome)

	var ai_actor: bool = bool(ai_enabled_by_color.get(actor, false))
	detail_label.text = "Click a piece to move during the Move phase. Use the action list for cards, setup, reactions, and end-step controls."
	if ai_actor:
		detail_label.text = "AI controls %s. Autoplay will continue while its action window is open." % actor_label
	elif wizard_match.phase == WizardMatch.PHASE_MOVE and actor == ChessMatch.WHITE and selected_square != null:
		detail_label.text = "Selected %s. Choose a highlighted destination." % wizard_match.chess_engine.square_to_algebraic(selected_square)


func _refresh_board() -> void:
	for square in board_buttons.keys():
		var button: Button = board_buttons[square]
		button.text = _square_text(square)
		button.modulate = _square_color(square)


func _refresh_player_summaries() -> void:
	white_summary_label.text = _player_summary_text(ChessMatch.WHITE)
	black_summary_label.text = _player_summary_text(ChessMatch.BLACK)


func _refresh_hand_lists() -> void:
	_refresh_hand_list(ChessMatch.WHITE, white_hand_list)
	_refresh_hand_list(ChessMatch.BLACK, black_hand_list)


func _refresh_hand_list(color: String, list: ItemList) -> void:
	list.clear()
	var legal_card_ids := {}
	for action_value in wizard_match.get_legal_card_actions(color):
		var action: Dictionary = action_value
		legal_card_ids[str(action["card_instance_id"])] = true

	for card_state_value in wizard_match.get_player_state(color).get("hand", []):
		var card_state: Dictionary = card_state_value
		var instance_id := str(card_state["instance_id"])
		var playable_prefix := "[Play] " if legal_card_ids.has(instance_id) else ""
		list.add_item("%s%s (%s, %d)" % [
			playable_prefix,
			str(card_state["display_name"]),
			str(card_state["card_type"]),
			int(card_state["mana_cost"]),
		])

	if list.item_count == 0:
		list.add_item("(empty)")


func _refresh_effects() -> void:
	var parts: Array[String] = []
	for effect_value in wizard_match.get_active_effects():
		var effect: Dictionary = effect_value
		parts.append("%s(%s)" % [
			str(effect.get("source_card_id", "")),
			str(effect.get("duration", "")),
		])
	effects_label.text = "Active Effects: %s" % (", ".join(parts) if not parts.is_empty() else "none")


func _refresh_histories() -> void:
	move_history_list.clear()
	for entry in wizard_match.chess_state.move_history:
		var prefix := "%d." % entry["turn_number"] if entry["color"] == ChessMatch.WHITE else "%d..." % entry["turn_number"]
		move_history_list.add_item("%s %s" % [prefix, entry["notation"]])

	event_history_list.clear()
	for event_value in wizard_match.get_event_history():
		var event: Dictionary = event_value
		event_history_list.add_item(str(event.get("type", "")))
		if event_history_list.item_count > 60:
			event_history_list.remove_item(0)


func _refresh_action_panel() -> void:
	for child in action_panel.get_children():
		child.queue_free()

	var actor := _current_actor_color()
	if actor.is_empty():
		return

	if ai_enabled_by_color.get(actor, false):
		var label := Label.new()
		label.text = "Autoplay enabled for %s." % actor.capitalize()
		action_panel.add_child(label)
		return

	match wizard_match.state:
		WizardMatch.STATE_SETUP:
			_add_action_button("Keep Opening Hand", _on_keep_hand_pressed)
			_add_action_button("Mulligan All", _on_mulligan_all_pressed)
		WizardMatch.STATE_ACTIVE:
			_refresh_active_action_panel(actor)
		_:
			_add_action_button("Start New Match", _on_new_match_pressed)


func _refresh_active_action_panel(actor: String) -> void:
	match wizard_match.phase:
		WizardMatch.PHASE_BEGINNING:
			_add_action_button("Resolve Beginning Phase", _on_resolve_beginning_pressed)
		WizardMatch.PHASE_PREPARATION:
			_add_card_action_buttons(actor)
			_add_action_button("Finish Preparation Phase", _on_finish_preparation_pressed)
		WizardMatch.PHASE_MOVE:
			var label := Label.new()
			label.text = "Select a %s piece on the board to move." % actor.capitalize()
			action_panel.add_child(label)
		WizardMatch.PHASE_REACTION:
			_add_card_action_buttons(actor)
			_add_action_button("Pass Reaction Priority", _on_pass_reaction_pressed)
		WizardMatch.PHASE_END:
			var discard_count := wizard_match.get_pending_hand_limit_discard_count(actor)
			if discard_count > 0:
				_add_discard_action_buttons(actor, discard_count)
			else:
				_add_action_button("Resolve End Phase", _on_resolve_end_pressed)


func _add_card_action_buttons(actor: String) -> void:
	var legal_actions := wizard_match.get_legal_card_actions(actor)
	if legal_actions.is_empty():
		var label := Label.new()
		label.text = "No legal card plays."
		action_panel.add_child(label)
		return

	for action_value in legal_actions:
		var action: Dictionary = action_value
		var button := Button.new()
		button.text = _card_action_label(actor, action)
		button.pressed.connect(_on_card_action_pressed.bind(action))
		action_panel.add_child(button)


func _add_discard_action_buttons(actor: String, discard_count: int) -> void:
	var hand: Array = wizard_match.get_player_state(actor).get("hand", [])
	for combination in _build_card_combinations(hand, discard_count):
		var ids: Array[String] = []
		var labels: Array[String] = []
		for card_state_value in combination:
			var card_state: Dictionary = card_state_value
			ids.append(str(card_state["instance_id"]))
			labels.append(str(card_state["display_name"]))
		var button := Button.new()
		button.text = "Discard: %s" % ", ".join(labels)
		button.pressed.connect(_on_discard_selection_pressed.bind(ids))
		action_panel.add_child(button)


func _refresh_ai_buttons() -> void:
	white_ai_button.text = "White AI: %s" % ("On" if ai_enabled_by_color[ChessMatch.WHITE] else "Off")
	black_ai_button.text = "Black AI: %s" % ("On" if ai_enabled_by_color[ChessMatch.BLACK] else "Off")


func _refresh_ai_timings() -> void:
	var lines: Array[String] = []
	for color in [ChessMatch.WHITE, ChessMatch.BLACK]:
		var controller: WizardMatchAiController = ai_controllers.get(color)
		if controller == null:
			continue
		lines.append("%s: %s" % [color.capitalize(), controller.format_last_timing_report()])
	ai_timing_label.text = "\n".join(lines)


func _on_board_square_pressed(square: Vector2i) -> void:
	var actor := _current_actor_color()
	if actor.is_empty() or ai_enabled_by_color.get(actor, false):
		return
	if wizard_match.state != WizardMatch.STATE_ACTIVE or wizard_match.phase != WizardMatch.PHASE_MOVE:
		return

	for move_value in selected_moves:
		var move: Dictionary = move_value
		if move["to"] != square:
			continue
		var result: Dictionary = wizard_match.apply_move_action(wizard_match.chess_engine.create_move_action(
			move["from"],
			move["to"],
			str(move.get("promotion", "queen"))
		))
		_after_action(result, "Move %s to %s" % [
			wizard_match.chess_engine.square_to_algebraic(move["from"]),
			wizard_match.chess_engine.square_to_algebraic(move["to"]),
		])
		return

	var piece = wizard_match.chess_engine.get_piece(square)
	if piece == null or str(piece["color"]) != actor:
		selected_square = null
		selected_moves.clear()
		_refresh_ui()
		return

	selected_square = square
	selected_moves = wizard_match.chess_engine.get_legal_moves_from(square)
	_refresh_ui()


func _on_new_match_pressed() -> void:
	_start_new_match()


func _on_step_ai_pressed() -> void:
	_process_ai_step()


func _on_use_ai_suggestion_pressed() -> void:
	var actor := _current_actor_color()
	if actor.is_empty():
		return
	var result: Dictionary = ai_controllers[actor].apply_next_action(wizard_match, actor)
	_after_action(result, "AI suggested action for %s" % actor.capitalize())


func _on_ai_toggle(enabled: bool, color: String) -> void:
	ai_enabled_by_color[color] = enabled
	_refresh_ui()
	_queue_ai_step_if_needed()


func _on_keep_hand_pressed() -> void:
	_after_action(wizard_match.keep_opening_hand(_current_actor_color()), "Keep opening hand")


func _on_mulligan_all_pressed() -> void:
	var actor := _current_actor_color()
	var hand_ids: Array[String] = []
	for card_state_value in wizard_match.get_player_state(actor).get("hand", []):
		hand_ids.append(str(card_state_value["instance_id"]))
	_after_action(wizard_match.perform_mulligan(actor, hand_ids), "Mulligan opening hand")


func _on_resolve_beginning_pressed() -> void:
	_after_action({"ok": wizard_match.resolve_beginning_phase()}, "Resolve beginning phase")


func _on_finish_preparation_pressed() -> void:
	_after_action({"ok": wizard_match.finish_preparation_phase()}, "Finish preparation phase")


func _on_pass_reaction_pressed() -> void:
	_after_action({"ok": wizard_match.pass_reaction_phase()}, "Pass reaction priority")


func _on_resolve_end_pressed() -> void:
	_after_action({"ok": wizard_match.resolve_end_phase()}, "Resolve end phase")


func _on_card_action_pressed(action: Dictionary) -> void:
	_after_action(
		wizard_match.play_card_from_hand(str(action["card_instance_id"]), action.get("targets", [])),
		"Play %s" % str(action["card_id"])
	)


func _on_discard_selection_pressed(card_instance_ids: Array[String]) -> void:
	_after_action(
		wizard_match.discard_cards_for_hand_limit(card_instance_ids),
		"Resolve hand limit discard"
	)


func _after_action(result: Dictionary, label: String) -> void:
	selected_square = null
	selected_moves.clear()
	if bool(result.get("ok", false)):
		last_ai_action_label.text = "%s: ok" % label
	else:
		last_ai_action_label.text = "%s: %s" % [label, str(result.get("reason", "failed"))]
	_refresh_ui()
	_queue_ai_step_if_needed()


func _queue_ai_step_if_needed() -> void:
	var actor := _current_actor_color()
	if actor.is_empty() or not ai_enabled_by_color.get(actor, false):
		return
	if ai_timer.time_left > 0.0:
		return
	ai_timer.start()


func _on_ai_timer_timeout() -> void:
	_process_ai_step()


func _process_ai_step() -> void:
	var actor := _current_actor_color()
	if actor.is_empty() or not ai_enabled_by_color.get(actor, false):
		return
	var result: Dictionary = ai_controllers[actor].apply_next_action(wizard_match, actor)
	last_ai_action_label.text = "AI %s: %s" % [actor.capitalize(), str(result.get("reason", "ok"))]
	if bool(result.get("ok", false)):
		last_ai_action_label.text = "AI %s acted." % actor.capitalize()
	selected_square = null
	selected_moves.clear()
	_refresh_ui()
	_queue_ai_step_if_needed()


func _current_actor_color() -> String:
	if wizard_match == null:
		return ""
	if wizard_match.state == WizardMatch.STATE_SETUP:
		for color in [ChessMatch.WHITE, ChessMatch.BLACK]:
			if bool(wizard_match.get_player_state(color).get("mulligan_available", false)):
				return color
		return ""
	if wizard_match.state != WizardMatch.STATE_ACTIVE:
		return ""
	match wizard_match.phase:
		WizardMatch.PHASE_BEGINNING, WizardMatch.PHASE_PREPARATION, WizardMatch.PHASE_MOVE:
			return wizard_match.chess_state.active_color
		WizardMatch.PHASE_REACTION:
			return wizard_match.reaction_priority_color
		WizardMatch.PHASE_END:
			for color in [ChessMatch.WHITE, ChessMatch.BLACK]:
				if wizard_match.get_pending_hand_limit_discard_count(color) > 0:
					return color
			return ChessMatch.BLACK if wizard_match.chess_state.active_color == ChessMatch.WHITE else ChessMatch.WHITE
		_:
			return ""


func _square_text(square: Vector2i) -> String:
	var piece = wizard_match.chess_engine.get_piece(square)
	var label := ""
	if piece != null:
		label = _piece_label(piece)
	var attached_cards: Array[String] = []
	for color in [ChessMatch.WHITE, ChessMatch.BLACK]:
		for card_state_value in wizard_match.get_player_state(color).get("battlefield", []):
			var card_state: Dictionary = card_state_value
			if str(card_state.get("attached_to", "")) == wizard_match.chess_engine.square_to_algebraic(square):
				attached_cards.append(str(card_state["display_name"]))
	if attached_cards.is_empty():
		return label
	return "%s\n[%s]" % [label, attached_cards[0].substr(0, min(attached_cards[0].length(), 6))]


func _piece_label(piece: Dictionary) -> String:
	var color_prefix := "W" if piece["color"] == ChessMatch.WHITE else "B"
	var piece_letter := ""
	match piece["type"]:
		ChessMatch.PIECE_PAWN:
			piece_letter = "P"
		ChessMatch.PIECE_KNIGHT:
			piece_letter = "N"
		ChessMatch.PIECE_BISHOP:
			piece_letter = "B"
		ChessMatch.PIECE_ROOK:
			piece_letter = "R"
		ChessMatch.PIECE_QUEEN:
			piece_letter = "Q"
		ChessMatch.PIECE_KING:
			piece_letter = "K"
	return "%s%s" % [color_prefix, piece_letter]


func _square_color(square: Vector2i) -> Color:
	if selected_square != null and square == selected_square:
		return SELECTED_SQUARE
	for move_value in selected_moves:
		var move: Dictionary = move_value
		if move["to"] == square:
			return LEGAL_SQUARE
	return LIGHT_SQUARE if (square.x + square.y) % 2 == 0 else DARK_SQUARE


func _player_summary_text(color: String) -> String:
	var player_state := wizard_match.get_player_state(color)
	var battlefield_cards: Array[String] = []
	for card_state_value in player_state.get("battlefield", []):
		battlefield_cards.append(str(card_state_value["card_id"]))
	var hand_cards: Array[String] = []
	for card_state_value in player_state.get("hand", []):
		hand_cards.append(str(card_state_value["card_id"]))
	return "%s | mana %d/%d | deck %d | hand %d [%s] | battlefield [%s] | graveyard %d" % [
		color.capitalize(),
		int(player_state.get("mana", 0)),
		int(player_state.get("maximum_mana", 0)),
		player_state.get("deck", []).size(),
		player_state.get("hand", []).size(),
		", ".join(hand_cards),
		", ".join(battlefield_cards),
		player_state.get("graveyard", []).size(),
	]


func _card_action_label(actor: String, action: Dictionary) -> String:
	var target_labels: Array[String] = []
	for target_value in action.get("targets", []):
		var target: Dictionary = target_value
		target_labels.append(str(target.get("square", "")))
	if target_labels.is_empty():
		return "%s plays %s" % [actor.capitalize(), str(action["card_id"])]
	return "%s plays %s -> %s" % [actor.capitalize(), str(action["card_id"]), ", ".join(target_labels)]


func _chess_outcome_text(outcome: Dictionary) -> String:
	match str(outcome.get("status", "")):
		ChessMatch.STATUS_CHECKMATE:
			return "checkmate (%s wins)" % str(outcome.get("winner", "")).capitalize()
		ChessMatch.STATUS_STALEMATE:
			return "stalemate"
		ChessMatch.STATUS_DRAW:
			return "draw (%s)" % str(outcome.get("reason", ""))
		_:
			return "active"


func _add_action_button(label: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.pressed.connect(callback)
	action_panel.add_child(button)


func _build_card_combinations(cards: Array, count: int) -> Array:
	var combinations: Array = []
	_build_card_combinations_recursive(cards, count, 0, [], combinations)
	return combinations


func _build_card_combinations_recursive(cards: Array, count: int, index: int, current: Array, combinations: Array) -> void:
	if current.size() == count:
		combinations.append(current.duplicate(true))
		return
	if index >= cards.size():
		return

	current.append(cards[index])
	_build_card_combinations_recursive(cards, count, index + 1, current, combinations)
	current.pop_back()
	_build_card_combinations_recursive(cards, count, index + 1, current, combinations)
