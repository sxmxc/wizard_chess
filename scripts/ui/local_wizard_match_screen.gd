extends Control

const LIGHT_SQUARE := Color("f0dfb2")
const DARK_SQUARE := Color("7d5738")
const SELECTED_SQUARE := Color("6fd38c")
const LEGAL_SQUARE := Color("ffe27b")
const CARD_TARGET_HOVER_TINT := Color("5bc8e8")
const THREATENED_SQUARE := Color("cb7f7f")
const RULES_RESOURCE_PATH := "res://content/config/default_wizard_match_rules.tres"
const DECK_RESOURCE_PATH := "res://content/decks/sample_ai_battle_deck.tres"
const WHITE_AI_PROFILE_PATH := "res://content/ai/beginner_aggressive_ai.tres"
const BLACK_AI_PROFILE_PATH := "res://content/ai/intermediate_positional_ai.tres"
const AI_STEP_DELAY_SECONDS := 0.03
const CARD_WIDGET_SCENE := preload("res://scenes/ui/wizard_match_card_widget.tscn")
const CARD_BACK_WIDGET_SCENE := preload("res://scenes/ui/wizard_match_card_back_widget.tscn")
const ARCANE_CARD_ART := preload("res://assets/ui/wizard_match/arcane_card_art.png")
const ORDER_CARD_ART := preload("res://assets/ui/wizard_match/order_card_art.png")
const PIECE_ATLAS := preload("res://assets/ui/wizard_match/piece_atlas.png")
const CARD_BACK_TEXTURE := preload("res://assets/ui/wizard_match/card_back.png")
const UI_DRAG_LOGGING := false

enum PerspectiveMode {
	AUTO,
	WHITE,
	BLACK,
}

var wizard_match: WizardMatch
var match_rules: WizardMatchRules
var match_deck: DeckDefinition
var ai_controllers := {}
var ai_enabled_by_color := {
	ChessEngine.WHITE: false,
	ChessEngine.BLACK: true,
}

var perspective_mode: PerspectiveMode = PerspectiveMode.AUTO
var threat_overlay_enabled: bool = false
var show_coordinates: bool = false
var processed_event_count: int = 0
var recent_notifications: Array[String] = []
var rendered_perspective_color: String = ""

var selected_square: Variant = null
var selected_moves: Array = []
var selected_card_instance_id: String = ""
var selected_hand_card_ids := {}
var board_buttons := {}
var board_button_by_name := {}
var local_hand_widgets := {}
var opponent_hand_widgets := {}
var last_card_centers := {}
var piece_icon_cache := {}
var hovered_square: Variant = null
var hovered_card_widget: WizardMatchCardWidget
var previous_state_snapshot: Dictionary = {}
var toast_message_count: int = 0
var utility_sidebar_open: bool = false
@onready var ai_timer: Timer = %AiTimer
@onready var interaction_controller: CardInteractionController = %CardInteractionController
@onready var status_label: Label = %StatusLabel
@onready var utilities_button: Button = %UtilitiesButton
@onready var notification_toast: PanelContainer = %NotificationToast
@onready var notification_toast_label: Label = %NotificationToastLabel
@onready var detail_label: Label = %DetailLabel
@onready var action_hint_label: Label = %ActionHintLabel
@onready var opponent_summary_label: Label = %OpponentSummaryLabel
@onready var opponent_deck_label: Label = %OpponentDeckLabel
@onready var opponent_graveyard_label: Label = %OpponentGraveyardLabel
@onready var opponent_top_graveyard_label: Label = %OpponentTopGraveyardLabel
@onready var opponent_status_view: WizardMatchPlayerStatusView = %OpponentStatusView
@onready var environment_label: Label = %EnvironmentLabel
@onready var local_summary_label: Label = %LocalSummaryLabel
@onready var local_deck_label: Label = %LocalDeckLabel
@onready var local_graveyard_label: Label = %LocalGraveyardLabel
@onready var local_library_label: Label = %LocalLibraryLabel
@onready var local_status_view: WizardMatchPlayerStatusView = %LocalStatusView
@onready var board_view: WizardMatchBoardView = %BoardView
@onready var opponent_hand_title_label: Label = %OpponentHandTitleLabel
@onready var opponent_hand_row: HandFanView = %OpponentHandRow
@onready var local_hand_title_label: Label = %LocalHandTitleLabel
@onready var local_hand_row: HandFanView = %LocalHandRow
@onready var action_bar: HBoxContainer = %ActionBar
@onready var turn_action_panel: WizardMatchTurnActionPanel = $HudLayer/TurnPanel
@onready var inspect_popup: WizardMatchInspectorView = %InspectPopup
@onready var match_sidebar: WizardMatchHudSidebar = %MatchSidebar
@onready var hud_layout := %HudLayout as WizardMatchHudLayout
@onready var notification_layer: CanvasLayer = $NotificationLayer
@onready var targeting_overlay: TargetingOverlay = %TargetingOverlay
@onready var opponent_hand_panel: Control = $HudLayer/OpponentHandPanel
@onready var local_hand_panel: Control = $HudLayer/LocalHandPanel
@onready var opponent_deck_pile: WizardMatchPileView = $HudLayer/OpponentLibraryPanel
@onready var opponent_graveyard_pile: WizardMatchPileView = $HudLayer/OpponentGraveyardPanel
@onready var local_deck_pile: WizardMatchPileView = $HudLayer/PlayerLibraryPanel
@onready var local_graveyard_pile: WizardMatchPileView = $HudLayer/PlayerGraveyardPanel
@onready var environment_zone_panel: WizardMatchPublicZonePanel = $HudLayer/EnvironmentZonePanel
@onready var artifacts_zone_panel: WizardMatchPublicZonePanel = $HudLayer/ArtifactsZonePanel
@onready var traps_zone_panel: WizardMatchPublicZonePanel = $HudLayer/TrapsZonePanel
@onready var captures_zone_panel: WizardMatchPublicZonePanel = $HudLayer/CapturesZonePanel


func _ready() -> void:
	_load_resources()
	_configure_static_ui()
	_start_new_match()


func _input(event: InputEvent) -> void:
	if interaction_controller.is_dragging() and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cancel_active_interaction()
		get_viewport().set_input_as_handled()
		return
	if interaction_controller.is_dragging() and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_cancel_active_interaction()
		get_viewport().set_input_as_handled()
		return
	if not interaction_controller.is_dragging():
		return
	if event is InputEventMouseMotion:
		interaction_controller.update_cursor(event.global_position)
		_update_manual_drag_hover_state()
		interaction_controller.update_preview_position()
		_update_targeting_line()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		interaction_controller.update_cursor(event.global_position)
		_finalize_active_drag()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and interaction_controller != null and interaction_controller.is_dragging():
		_cancel_active_interaction()
		return
	if what == NOTIFICATION_DRAG_END:
		if not interaction_controller.is_dragging():
			return
		interaction_controller.update_cursor(get_global_mouse_position())
		_finalize_active_drag()


func _log_drag(message: String, payload: Dictionary = {}) -> void:
	if not UI_DRAG_LOGGING:
		return
	print("[WizardMatchUI] %s %s" % [message, JSON.stringify(payload)])


func _load_resources() -> void:
	match_rules = load(RULES_RESOURCE_PATH) as WizardMatchRules
	match_deck = CardCatalog.load_deck_definition(DECK_RESOURCE_PATH)
	ai_controllers = {
		ChessEngine.WHITE: WizardMatchAiController.new(load(WHITE_AI_PROFILE_PATH) as WizardMatchAiProfile),
		ChessEngine.BLACK: WizardMatchAiController.new(load(BLACK_AI_PROFILE_PATH) as WizardMatchAiProfile),
	}


func _configure_static_ui() -> void:
	ai_timer.one_shot = true
	ai_timer.wait_time = AI_STEP_DELAY_SECONDS
	ai_timer.timeout.connect(_on_ai_timer_timeout)
	resized.connect(_update_overlay_layout)
	board_view.set_screen(self)
	board_view.square_pressed.connect(_on_board_square_pressed)
	board_view.square_hovered.connect(_on_board_square_hovered)
	board_view.square_unhovered.connect(_on_board_square_unhovered)
	board_view.square_dropped.connect(handle_square_drop)
	board_buttons = board_view.get_square_buttons()
	board_button_by_name.clear()
	for square in board_buttons.keys():
		var button: WizardMatchBoardSquareButton = board_buttons[square]
		board_button_by_name[_square_name(square)] = button

	match_sidebar.card_selected.connect(_on_sidebar_card_selected)
	match_sidebar.threat_toggled.connect(_on_threat_toggled)
	match_sidebar.coordinates_toggled.connect(_on_coordinates_toggled)
	match_sidebar.perspective_selected.connect(_on_perspective_selected)
	match_sidebar.ai_toggled.connect(_on_ai_toggle)
	call_deferred("_update_overlay_layout")


func _start_new_match() -> void:
	wizard_match = WizardMatch.new(match_rules)
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
	match_sidebar.set_ai_status("AI: ready", "AI timings: no samples yet")
	wizard_match.start_match(match_deck, match_deck, 17)
	_refresh_ui()
	previous_state_snapshot = wizard_match.create_state_snapshot()
	_queue_ai_step_if_needed()


func _refresh_ui() -> void:
	_refresh_status()
	_refresh_notifications()
	_refresh_player_zones()
	_refresh_environment()
	_refresh_board()
	_refresh_hands()
	_refresh_action_bar()
	_refresh_histories()
	_refresh_graveyards()
	_refresh_active_cards()
	_refresh_inspector()
	_refresh_settings_controls()
	_refresh_ai_timings()
	_update_targeting_line()
	_update_overlay_layout()


func _update_overlay_layout() -> void:
	if not is_node_ready() or hud_layout == null:
		return
	hud_layout.apply_layout(get_viewport_rect().size)


func _refresh_status() -> void:
	var actor := _current_actor_color()
	var actor_label := "None" if actor.is_empty() else actor.capitalize()
	status_label.text = "Turn %d  %s  %s" % [wizard_match.turn_number, wizard_match.phase.capitalize(), actor_label]
	if wizard_match.chess_state.outcome["status"] != ChessEngine.STATUS_ACTIVE:
		status_label.text += "  %s" % _chess_outcome_text(wizard_match.chess_state.outcome)

	if _local_actor_locked_by_ai():
		detail_label.text = "Waiting"
	elif wizard_match.state == WizardMatch.STATE_SETUP:
		detail_label.text = "Opening Hand"
	elif wizard_match.phase == WizardMatch.PHASE_MOVE:
		detail_label.text = "Move"
	elif wizard_match.phase == WizardMatch.PHASE_PREPARATION:
		detail_label.text = "Preparation"
	elif wizard_match.phase == WizardMatch.PHASE_REACTION:
		detail_label.text = "Reaction"
	else:
		detail_label.text = "Inspect"
	utilities_button.text = "Tools ▼" if utility_sidebar_open else "Tools"


func _refresh_notifications() -> void:
	var events := wizard_match.get_event_history()
	while processed_event_count < events.size():
		var event: Dictionary = events[processed_event_count]
		var note := _important_notification_text(event)
		if not note.is_empty():
			recent_notifications.append(note)
			if recent_notifications.size() > 4:
				recent_notifications.remove_at(0)
			_show_notification_toast(note)
		processed_event_count += 1

	if recent_notifications.is_empty():
		notification_toast.visible = false


func _refresh_player_zones() -> void:
	var display_color := _display_color()
	var opponent_color := _opponent(display_color)

	opponent_summary_label.text = ""
	local_summary_label.text = ""

	var opponent_state := wizard_match.get_player_state(opponent_color)
	var local_state := wizard_match.get_player_state(display_color)
	opponent_deck_label.text = str(opponent_state.get("deck", []).size())
	opponent_graveyard_label.text = str(opponent_state.get("graveyard", []).size())
	opponent_top_graveyard_label.text = str(opponent_state.get("graveyard", []).size())
	local_deck_label.text = str(local_state.get("deck", []).size())
	local_graveyard_label.text = str(local_state.get("graveyard", []).size())
	local_library_label.text = str(local_state.get("deck", []).size())
	opponent_deck_pile.set_pile_state(opponent_color, "Deck", opponent_state.get("deck", []).size())
	opponent_graveyard_pile.set_pile_state(opponent_color, "Graveyard", opponent_state.get("graveyard", []).size(), _top_card_name(opponent_state.get("graveyard", [])), _top_card_art_path(opponent_state.get("graveyard", [])), _top_card_state(opponent_state.get("graveyard", [])))
	local_deck_pile.set_pile_state(display_color, "Deck", local_state.get("deck", []).size())
	local_graveyard_pile.set_pile_state(display_color, "Graveyard", local_state.get("graveyard", []).size(), _top_card_name(local_state.get("graveyard", [])), _top_card_art_path(local_state.get("graveyard", [])), _top_card_state(local_state.get("graveyard", [])))
	opponent_status_view.set_player_state(
		opponent_color,
		int(opponent_state.get("mana", 0)),
		int(opponent_state.get("maximum_mana", 0))
	)
	local_status_view.set_player_state(
		display_color,
		int(local_state.get("mana", 0)),
		int(local_state.get("maximum_mana", 0))
	)


func _refresh_environment() -> void:
	var environment_lines: Array[String] = []
	for color in [ChessEngine.WHITE, ChessEngine.BLACK]:
		for card_state_value in wizard_match.get_player_state(color).get("battlefield", []):
			var card_state: Dictionary = card_state_value
			if str(card_state.get("card_type", "")) != CardDefinition.TYPE_ENVIRONMENT:
				continue
			environment_lines.append("%s: %s" % [color.capitalize(), str(card_state.get("display_name", card_state["card_id"]))])
	environment_label.text = "" if environment_lines.is_empty() else " | ".join(environment_lines)
	environment_zone_panel.set_visual_entries("Environment", _environment_visual_entries())
	artifacts_zone_panel.set_visual_entries("Artifacts", _artifact_visual_entries())
	traps_zone_panel.set_visual_entries("Traps", _active_trap_visual_entries())
	captures_zone_panel.set_visual_entries("Captured Pieces", _captured_piece_visual_entries())


func _top_card_name(cards: Array) -> String:
	if cards.is_empty():
		return ""
	var card_state: Dictionary = cards[cards.size() - 1]
	return str(card_state.get("display_name", card_state.get("card_id", "")))


func _top_card_art_path(cards: Array) -> String:
	if cards.is_empty():
		return ""
	var card_state: Dictionary = cards[cards.size() - 1]
	return str(card_state.get("art_texture_path", ""))


func _top_card_state(cards: Array) -> Dictionary:
	if cards.is_empty():
		return {}
	return cards[cards.size() - 1]


func _environment_visual_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for color in [ChessEngine.WHITE, ChessEngine.BLACK]:
		for card_state_value in wizard_match.get_player_state(color).get("battlefield", []):
			var card_state: Dictionary = card_state_value
			if str(card_state.get("card_type", "")) != CardDefinition.TYPE_ENVIRONMENT:
				continue
			entries.append({
				"texture": _card_art_texture(card_state),
				"tooltip": "%s Environment: %s" % [color.capitalize(), str(card_state.get("display_name", card_state["card_id"]))],
			})
	return entries


func _artifact_visual_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for color in [ChessEngine.WHITE, ChessEngine.BLACK]:
		for card_state_value in wizard_match.get_player_state(color).get("battlefield", []):
			var card_state: Dictionary = card_state_value
			if str(card_state.get("card_type", "")) != CardDefinition.TYPE_ARTIFACT:
				continue
			entries.append({
				"texture": _card_art_texture(card_state),
				"tooltip": "%s Artifact: %s" % [color.capitalize(), str(card_state.get("display_name", card_state["card_id"]))],
			})
	return entries


func _active_trap_visual_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var viewer := _display_color()
	for color in [ChessEngine.WHITE, ChessEngine.BLACK]:
		for card_state_value in wizard_match.get_player_state(color).get("battlefield", []):
			var card_state: Dictionary = card_state_value
			if str(card_state.get("card_type", "")) != CardDefinition.TYPE_TRAP:
				continue
			var square_name := str(card_state.get("placed_on", ""))
			var is_hidden: bool = bool(card_state.get("face_down", false)) and color != viewer
			var card_label := "Face-down Trap" if is_hidden else str(card_state.get("display_name", card_state["card_id"]))
			var location_label := "" if square_name.is_empty() or is_hidden else " on %s" % square_name
			entries.append({
				"texture": CARD_BACK_TEXTURE if is_hidden else _card_art_texture(card_state),
				"tooltip": "%s: %s%s" % [color.capitalize(), card_label, location_label],
			})
	return entries


func _captured_piece_visual_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for entry_value in wizard_match.chess_state.move_history:
		var entry: Dictionary = entry_value
		var move: Dictionary = entry.get("move", {})
		if not bool(move.get("is_capture", false)):
			continue
		var captor_color := str(entry.get("color", ""))
		var piece_type := str(move.get("captured_piece_type", ""))
		if captor_color.is_empty() or piece_type.is_empty():
			continue
		var captured_color := _opponent(captor_color)
		entries.append({
			"texture": _piece_icon({
				"color": captured_color,
				"type": piece_type,
			}),
			"tooltip": "%s captured %s %s" % [captor_color.capitalize(), captured_color.capitalize(), piece_type.capitalize()],
		})
	return entries


func _refresh_board() -> void:
	var target_square_names := _selected_card_target_square_names()
	for square in board_buttons.keys():
		var piece = wizard_match.chess_engine.get_piece(square)
		board_view.set_square_visual(
			square,
			_piece_icon(piece),
			_square_color(square),
			_square_tooltip(square),
			show_coordinates
		)
		var is_card_target: bool = target_square_names.has(wizard_match.chess_engine.square_to_algebraic(square))
		board_view.set_square_target_emphasis(
			square,
			is_card_target,
			is_card_target and hovered_square != null and square == hovered_square
		)


func _refresh_hands() -> void:
	for child in opponent_hand_row.get_children():
		child.queue_free()
	for child in local_hand_row.get_children():
		child.queue_free()
	opponent_hand_widgets.clear()
	local_hand_widgets.clear()

	var display_color := _display_color()
	var opponent_color := _opponent(display_color)
	var opponent_hand: Array = wizard_match.get_player_state(opponent_color).get("hand", [])
	var local_hand: Array = wizard_match.get_player_state(display_color).get("hand", [])

	opponent_hand_title_label.text = "%s Hand" % opponent_color.capitalize()
	local_hand_title_label.text = "%s Hand" % display_color.capitalize()

	for card_state_value in opponent_hand:
		var card_state: Dictionary = card_state_value
		var widget := CARD_BACK_WIDGET_SCENE.instantiate() as WizardMatchCardBackWidget
		widget.configure(str(card_state["instance_id"]))
		opponent_hand_row.add_child(widget)
		opponent_hand_widgets[str(card_state["instance_id"])] = widget

	if local_hand.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Hand is empty."
		empty_label.position = Vector2(22, 72)
		local_hand_row.add_child(empty_label)
	else:
		var playable_ids := _legal_card_ids(display_color)
		for card_state_value in local_hand:
			var card_state: Dictionary = card_state_value
			var card_id := str(card_state["instance_id"])
			var widget := CARD_WIDGET_SCENE.instantiate() as WizardMatchCardWidget
			widget.configure(self, card_state, display_color, _card_art_texture(card_state), false)
			widget.pressed.connect(_on_hand_card_pressed.bind(card_id))
			widget.set_visual_state(
				playable_ids.has(card_id),
				selected_card_instance_id == card_id,
				selected_hand_card_ids.has(card_id)
			)
			local_hand_row.add_child(widget)
			local_hand_widgets[card_id] = widget
	_refresh_hand_fan_views()


func on_card_widget_hovered(widget: WizardMatchCardWidget) -> void:
	if hovered_card_widget != null and is_instance_valid(hovered_card_widget):
		hovered_card_widget.set_spotlight_active(false)
	hovered_card_widget = widget
	hovered_card_widget.set_spotlight_active(true)
	selected_card_instance_id = str(widget.card_state.get("instance_id", ""))
	_refresh_inspector()
	_update_targeting_line()


func on_card_widget_unhovered(widget: WizardMatchCardWidget) -> void:
	if hovered_card_widget == widget:
		hovered_card_widget.set_spotlight_active(false)
		hovered_card_widget = null
	_update_targeting_line()


func _update_targeting_line() -> void:
	var source := Vector2.ZERO
	var destination := Vector2.ZERO
	var target_is_valid := false
	match interaction_controller.drag_kind():
		"piece":
			if interaction_controller.source_square == null:
				targeting_overlay.clear()
				return
			source = _board_square_center_global(interaction_controller.source_square)
			destination = interaction_controller.cursor_global
			var piece_target := board_view.square_at_global_position(destination)
			target_is_valid = piece_target != WizardMatchBoardView.INVALID_SQUARE and _can_drop_piece_on_square(piece_target, {"from_square": interaction_controller.source_square})
		"card_target":
			source = _card_target_anchor_global(interaction_controller.card_instance_id)
			destination = _active_card_target_destination_global()
			target_is_valid = hovered_square != null and _can_play_selected_card_on_square(hovered_square)
		"card_play":
			source = _card_target_anchor_global(interaction_controller.card_instance_id)
			destination = interaction_controller.cursor_global
			target_is_valid = not local_hand_row.get_global_rect().has_point(destination)
		_:
			if hovered_square == null or selected_card_instance_id.is_empty():
				targeting_overlay.clear()
				return
			if not _can_play_selected_card_on_square(hovered_square):
				targeting_overlay.clear()
				return
			source = _card_target_anchor_global(selected_card_instance_id)
			destination = _board_square_center_global(hovered_square)
			target_is_valid = true
	if source == Vector2.ZERO or destination == Vector2.ZERO:
		targeting_overlay.clear()
		return
	targeting_overlay.present(source, destination, target_is_valid)


func _active_card_target_destination_global() -> Vector2:
	if hovered_square != null and _can_play_selected_card_on_square(hovered_square):
		return _board_square_center_global(hovered_square)
	return interaction_controller.cursor_global


func _card_source_global(card_instance_id: String) -> Vector2:
	if local_hand_widgets.has(card_instance_id):
		return local_hand_row.get_card_center_global(card_instance_id)
	if opponent_hand_widgets.has(card_instance_id):
		return opponent_hand_row.get_card_center_global(card_instance_id)
	return last_card_centers.get(card_instance_id, Vector2.ZERO)


func _card_target_anchor_global(card_instance_id: String) -> Vector2:
	var widget: Control = null
	if local_hand_widgets.has(card_instance_id):
		widget = local_hand_widgets[card_instance_id]
	elif opponent_hand_widgets.has(card_instance_id):
		widget = opponent_hand_widgets[card_instance_id]
	if widget == null or not is_instance_valid(widget):
		return _card_source_global(card_instance_id)
	return widget.global_position + Vector2(widget.size.x * 0.5, widget.size.y * 0.18)


func _refresh_hand_fan_views() -> void:
	local_hand_row.set_targeted_card_instance_id(interaction_controller.card_instance_id if interaction_controller.state == CardInteractionController.State.CARD_TARGETING else "")
	opponent_hand_row.set_targeted_card_instance_id("")
	local_hand_row.refresh_layout()
	opponent_hand_row.refresh_layout()
	_cache_hand_card_centers()


func _cache_hand_card_centers() -> void:
	for card_id in local_hand_widgets.keys():
		last_card_centers[str(card_id)] = local_hand_row.get_card_center_global(str(card_id))
	for card_id in opponent_hand_widgets.keys():
		last_card_centers[str(card_id)] = opponent_hand_row.get_card_center_global(str(card_id))


func _begin_active_drag_preview(preview: Control) -> void:
	interaction_controller.set_preview(preview, notification_layer)


func _update_active_drag_preview() -> void:
	interaction_controller.update_preview_position()


func _update_manual_drag_hover_state() -> void:
	var previous_hovered_square = hovered_square
	if interaction_controller.state == CardInteractionController.State.PIECE_DRAGGING or interaction_controller.state == CardInteractionController.State.CARD_TARGETING:
		var square := board_view.square_at_global_position(interaction_controller.cursor_global)
		if square == WizardMatchBoardView.INVALID_SQUARE:
			hovered_square = null
		else:
			hovered_square = square
	else:
		hovered_square = null
	if hovered_square != previous_hovered_square:
		_refresh_board()


func _refresh_action_bar() -> void:
	turn_action_panel.clear_actions()

	var actor := _current_actor_color()
	if actor.is_empty():
		turn_action_panel.set_phase_summary(detail_label.text, "No action window is currently open.")
		return

	if ai_enabled_by_color.get(actor, false):
		turn_action_panel.show_waiting("%s AI" % actor.capitalize(), "Autoplay is active for the current actor.")
		return

	match wizard_match.state:
		WizardMatch.STATE_SETUP:
			_build_setup_actions()
		WizardMatch.STATE_ACTIVE:
			_build_active_actions(actor)
		_:
			_add_action_button("New Match", _on_new_match_pressed, false, true)
			turn_action_panel.set_phase_summary("Complete", "Match complete.")


func _build_setup_actions() -> void:
	_add_action_button("Keep Hand", _on_keep_hand_pressed, false, true)
	_add_action_button("Mulligan Selected", _on_mulligan_selected_pressed, selected_hand_card_ids.is_empty())
	_add_action_button("Mulligan All", _on_mulligan_all_pressed)
	turn_action_panel.set_phase_summary("Opening Hand", "Select cards to replace.")


func _build_active_actions(actor: String) -> void:
	match wizard_match.phase:
		WizardMatch.PHASE_BEGINNING:
			_add_action_button("Resolve Beginning", _on_resolve_beginning_pressed, false, true)
			turn_action_panel.set_phase_summary("Beginning", "Draw and refresh mana.")
		WizardMatch.PHASE_PREPARATION:
			if not selected_card_instance_id.is_empty():
				_add_action_button("Clear Card", _clear_card_selection)
			if _selected_card_has_zero_target_action(_selected_card_actions()):
				_add_action_button("Play Selected Card", _on_play_selected_card_pressed, false, true)
			_add_action_button("Finish Preparation", _on_finish_preparation_pressed, false, selected_card_instance_id.is_empty())
			turn_action_panel.set_phase_summary("Preparation", "Play cards, then finish.")
		WizardMatch.PHASE_MOVE:
			turn_action_panel.set_phase_summary("Move", "Move a %s piece." % actor.capitalize())
		WizardMatch.PHASE_REACTION:
			if not selected_card_instance_id.is_empty():
				_add_action_button("Clear Card", _clear_card_selection)
			if _selected_card_has_zero_target_action(_selected_card_actions()):
				_add_action_button("Play Selected Reaction", _on_play_selected_card_pressed, false, true)
			_add_action_button("Pass Priority", _on_pass_reaction_pressed, false, selected_card_instance_id.is_empty())
			turn_action_panel.set_phase_summary("Reaction", "React or pass.")
		WizardMatch.PHASE_END:
			var discard_count := wizard_match.get_pending_hand_limit_discard_count(actor)
			if discard_count > 0:
				_add_action_button("Discard Selected", _on_discard_selected_pressed, selected_hand_card_ids.size() != discard_count, true)
				turn_action_panel.set_phase_summary("Cleanup", "Discard %d card(s)." % discard_count)
			else:
				_add_action_button("Resolve End", _on_resolve_end_pressed, false, true)
				turn_action_panel.set_phase_summary("End", "Resolve turn end.")


func _refresh_histories() -> void:
	var move_entries: Array[String] = []
	for entry in wizard_match.chess_state.move_history:
		var prefix := "%d." % entry["turn_number"] if entry["color"] == ChessEngine.WHITE else "%d..." % entry["turn_number"]
		move_entries.append("%s %s" % [prefix, entry["notation"]])

	var event_entries: Array[String] = []
	for event_value in wizard_match.get_event_history():
		event_entries.append(_event_summary_text(event_value))
	match_sidebar.set_histories(move_entries, event_entries)


func _refresh_graveyards() -> void:
	var white_cards: Array = wizard_match.get_player_state(ChessEngine.WHITE).get("graveyard", [])
	var black_cards: Array = wizard_match.get_player_state(ChessEngine.BLACK).get("graveyard", [])
	match_sidebar.set_graveyards(
		_build_sidebar_card_entries(white_cards, ChessEngine.WHITE),
		_build_sidebar_card_entries(black_cards, ChessEngine.BLACK)
	)


func _build_sidebar_card_entries(cards: Array, owner_color: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var viewer := _display_color()
	for card_state_value in cards:
		entries.append({
			"card_instance_id": str(card_state_value.get("instance_id", "")),
			"label": _card_public_list_label(card_state_value, owner_color, viewer),
		})
	return entries


func _refresh_active_cards() -> void:
	var entries: Array[Dictionary] = []
	var viewer := _display_color()
	for color in [ChessEngine.WHITE, ChessEngine.BLACK]:
		for card_state_value in wizard_match.get_player_state(color).get("battlefield", []):
			entries.append({
				"card_instance_id": str(card_state_value.get("instance_id", "")),
				"label": _card_public_list_label(card_state_value, color, viewer),
			})
	match_sidebar.set_active_cards(entries)


func _refresh_inspector() -> void:
	if not selected_card_instance_id.is_empty():
		var entry := _find_card_entry(selected_card_instance_id)
		if not entry.is_empty():
			_set_card_inspector(entry["card_state"], str(entry["zone"]), str(entry["owner_color"]))
			return
	if selected_square != null:
		_set_square_inspector(selected_square)
		return
	inspect_popup.clear_inspection()


func _show_notification_toast(message: String) -> void:
	toast_message_count += 1
	var toast_token := toast_message_count
	notification_toast_label.text = message
	notification_toast.visible = true
	notification_toast.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(notification_toast, "modulate", Color(1, 1, 1, 1), 0.12)
	tween.tween_interval(1.5)
	tween.tween_property(notification_toast, "modulate", Color(1, 1, 1, 0), 0.28)
	tween.finished.connect(func() -> void:
		if toast_token == toast_message_count:
			notification_toast.visible = false
	)


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
		ai_enabled_by_color[ChessEngine.WHITE],
		ai_enabled_by_color[ChessEngine.BLACK]
	)


func _refresh_ai_timings() -> void:
	var lines: Array[String] = []
	for color in [ChessEngine.WHITE, ChessEngine.BLACK]:
		var controller: WizardMatchAiController = ai_controllers.get(color)
		lines.append("%s: %s" % [color.capitalize(), controller.format_last_timing_report()])
	match_sidebar.set_ai_timing_text("\n".join(lines))


func _on_board_square_pressed(square: Vector2i) -> void:
	selected_square = square
	hovered_square = square
	if _can_play_selected_card_on_square(square):
		_play_selected_card_on_square(square)
		return

	var actor := _current_actor_color()
	if actor.is_empty() or ai_enabled_by_color.get(actor, false):
		_refresh_ui()
		return

	if wizard_match.state == WizardMatch.STATE_ACTIVE and wizard_match.phase == WizardMatch.PHASE_MOVE and actor == _display_color():
		for move_value in selected_moves:
			var move: Dictionary = move_value
			if move["to"] != square:
				continue
			_commit_move(move)
			return
		var piece = wizard_match.chess_engine.get_piece(square)
		if piece != null and str(piece["color"]) == actor:
			selected_moves = wizard_match.chess_engine.get_legal_moves_from(square)
			selected_card_instance_id = ""
		else:
			selected_moves.clear()
		_refresh_ui()


func _on_board_square_hovered(square: Vector2i) -> void:
	hovered_square = square
	_refresh_board()
	_update_targeting_line()


func _on_board_square_unhovered(square: Vector2i) -> void:
	if hovered_square == square:
		hovered_square = null
	_refresh_board()
	_update_targeting_line()


func _on_hand_card_pressed(card_instance_id: String) -> void:
	selected_square = null
	selected_moves.clear()

	if wizard_match.state == WizardMatch.STATE_SETUP or _is_hand_limit_selection_active():
		if selected_hand_card_ids.has(card_instance_id):
			selected_hand_card_ids.erase(card_instance_id)
		else:
			selected_hand_card_ids[card_instance_id] = true
		selected_card_instance_id = card_instance_id
		_refresh_ui()
		return

	selected_hand_card_ids.clear()
	selected_card_instance_id = "" if selected_card_instance_id == card_instance_id else card_instance_id
	_refresh_ui()


func on_card_widget_drag_started(widget: WizardMatchCardWidget, cursor_global: Vector2) -> void:
	var card_instance_id := str(widget.card_state.get("instance_id", ""))
	if card_instance_id.is_empty():
		return
	if wizard_match.state == WizardMatch.STATE_SETUP or _is_hand_limit_selection_active():
		return
	selected_square = null
	selected_moves.clear()
	selected_hand_card_ids.clear()
	selected_card_instance_id = card_instance_id
	if _card_has_square_targets(card_instance_id):
		interaction_controller.begin_card_drag(card_instance_id, cursor_global, true)
	elif _card_has_zero_target_action(card_instance_id):
		interaction_controller.begin_card_drag(card_instance_id, cursor_global, false)
	else:
		interaction_controller.reset_drag()
	if interaction_controller.state == CardInteractionController.State.CARD_DRAGGING:
		_begin_active_drag_preview(_build_card_drag_preview(widget.card_state))
	if interaction_controller.is_dragging():
		_log_drag("card_drag_started", {
			"card_instance_id": card_instance_id,
			"kind": interaction_controller.drag_kind(),
		})
	_refresh_ui()


func on_board_piece_drag_started(square: Vector2i, cursor_global: Vector2) -> void:
	if wizard_match.state != WizardMatch.STATE_ACTIVE or wizard_match.phase != WizardMatch.PHASE_MOVE:
		return
	var actor := _current_actor_color()
	if actor.is_empty() or actor != _display_color() or ai_enabled_by_color.get(actor, false):
		return
	var piece = wizard_match.chess_engine.get_piece(square)
	if piece == null or str(piece["color"]) != actor:
		return
	selected_square = square
	selected_moves = wizard_match.chess_engine.get_legal_moves_from(square)
	selected_card_instance_id = ""
	interaction_controller.begin_piece_drag(square, cursor_global)
	_begin_active_drag_preview(_build_piece_drag_preview(piece))
	_log_drag("piece_drag_started", {"square": _square_name(square)})
	_refresh_ui()


func on_card_widget_drag_updated(cursor_global: Vector2) -> void:
	if not interaction_controller.is_dragging():
		return
	interaction_controller.update_cursor(cursor_global)
	_update_manual_drag_hover_state()
	_update_active_drag_preview()
	_update_targeting_line()


func on_card_widget_drag_released(cursor_global: Vector2) -> void:
	if not interaction_controller.is_dragging():
		return
	interaction_controller.update_cursor(cursor_global)
	_finalize_active_drag()


func _on_new_match_pressed() -> void:
	_start_new_match()


func _on_step_ai_pressed() -> void:
	_process_ai_step()


func _on_use_ai_suggestion_pressed() -> void:
	var actor := _current_actor_color()
	if actor.is_empty():
		return
	_after_action(ai_controllers[actor].apply_next_action(wizard_match, actor), "AI suggested action")


func _on_ai_toggle(enabled: bool, color: String) -> void:
	ai_enabled_by_color[color] = enabled
	_refresh_ui()
	_queue_ai_step_if_needed()


func _on_keep_hand_pressed() -> void:
	_after_action(wizard_match.keep_opening_hand(_current_actor_color()), "Keep hand")


func _on_mulligan_selected_pressed() -> void:
	var ids: Array[String] = []
	for card_id in selected_hand_card_ids.keys():
		ids.append(str(card_id))
	_after_action(wizard_match.perform_mulligan(_current_actor_color(), ids), "Mulligan selected")


func _on_mulligan_all_pressed() -> void:
	var actor := _current_actor_color()
	var ids: Array[String] = []
	for card_state_value in wizard_match.get_player_state(actor).get("hand", []):
		ids.append(str(card_state_value["instance_id"]))
	_after_action(wizard_match.perform_mulligan(actor, ids), "Mulligan all")


func _on_resolve_beginning_pressed() -> void:
	_after_action({"ok": wizard_match.resolve_beginning_phase()}, "Resolve beginning")


func _on_finish_preparation_pressed() -> void:
	_after_action({"ok": wizard_match.finish_preparation_phase()}, "Finish preparation")


func _on_pass_reaction_pressed() -> void:
	_after_action({"ok": wizard_match.pass_reaction_phase()}, "Pass priority")


func _on_resolve_end_pressed() -> void:
	_after_action({"ok": wizard_match.resolve_end_phase()}, "Resolve end")


func _on_play_selected_card_pressed() -> void:
	var action := _first_zero_target_action(_selected_card_actions())
	if action.is_empty():
		return
	_after_action(wizard_match.play_card_from_hand(str(action["card_instance_id"]), action.get("targets", [])), "Play selected card")


func _on_discard_selected_pressed() -> void:
	var ids: Array[String] = []
	for card_id in selected_hand_card_ids.keys():
		ids.append(str(card_id))
	_after_action(wizard_match.discard_cards_for_hand_limit(ids), "Discard selected")


func _on_sidebar_card_selected(card_instance_id: String) -> void:
	selected_card_instance_id = card_instance_id
	selected_square = null
	selected_moves.clear()
	_refresh_ui()


func _on_threat_toggled(enabled: bool) -> void:
	threat_overlay_enabled = enabled
	_refresh_ui()


func _on_coordinates_toggled(enabled: bool) -> void:
	show_coordinates = enabled
	_refresh_ui()


func _on_perspective_selected(index: int) -> void:
	match index:
		1:
			perspective_mode = PerspectiveMode.WHITE
		2:
			perspective_mode = PerspectiveMode.BLACK
		_:
			perspective_mode = PerspectiveMode.AUTO
	_refresh_ui()


func _on_utilities_button_pressed() -> void:
	utility_sidebar_open = not utility_sidebar_open
	_update_utility_sidebar_visibility()
	_refresh_status()


func _update_utility_sidebar_visibility() -> void:
	if match_sidebar == null:
		return
	match_sidebar.visible = utility_sidebar_open


func _after_action(result: Dictionary, label: String) -> void:
	var before_snapshot := previous_state_snapshot.duplicate(true)
	selected_moves.clear()
	selected_card_instance_id = ""
	selected_hand_card_ids.clear()
	interaction_controller.reset_drag()
	hovered_square = null
	match_sidebar.set_ai_action_text("%s: %s" % [label, "ok" if bool(result.get("ok", false)) else str(result.get("reason", "failed"))])
	_refresh_ui()
	var after_snapshot := wizard_match.create_state_snapshot()
	call_deferred("_animate_state_transition", before_snapshot, after_snapshot)
	previous_state_snapshot = after_snapshot
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
	var before_snapshot := previous_state_snapshot.duplicate(true)
	var result: Dictionary = ai_controllers[actor].apply_next_action(wizard_match, actor)
	match_sidebar.set_ai_action_text("AI %s: %s" % [actor.capitalize(), "acted" if bool(result.get("ok", false)) else str(result.get("reason", "failed"))])
	selected_moves.clear()
	selected_card_instance_id = ""
	selected_hand_card_ids.clear()
	interaction_controller.reset_drag()
	hovered_square = null
	_refresh_ui()
	var after_snapshot := wizard_match.create_state_snapshot()
	call_deferred("_animate_state_transition", before_snapshot, after_snapshot)
	previous_state_snapshot = after_snapshot
	_queue_ai_step_if_needed()


func _animate_state_transition(before_snapshot: Dictionary, after_snapshot: Dictionary) -> void:
	if before_snapshot.is_empty() or after_snapshot.is_empty():
		return
	await _animate_piece_transition(before_snapshot, after_snapshot)
	await _animate_card_transitions(before_snapshot, after_snapshot)


func _animate_piece_transition(before_snapshot: Dictionary, after_snapshot: Dictionary) -> void:
	var before_history: Array = before_snapshot.get("chess_state", {}).get("move_history", [])
	var after_history: Array = after_snapshot.get("chess_state", {}).get("move_history", [])
	if after_history.size() <= before_history.size():
		return
	var last_entry: Dictionary = after_history.back()
	var move: Dictionary = last_entry.get("move", {})
	var from_square: Vector2i = move.get("from", Vector2i(-1, -1))
	var to_square: Vector2i = move.get("to", Vector2i(-1, -1))
	if not board_buttons.has(from_square) or not board_buttons.has(to_square):
		return

	var moving_piece := {
		"color": str(last_entry.get("color", "")),
		"type": str(move.get("promotion", move.get("piece_type", ""))),
	}
	var from_center := _board_square_center_global(from_square)
	var to_center := _board_square_center_global(to_square)
	var sprite := TextureRect.new()
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.texture = _piece_icon(moving_piece)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.size = Vector2(68, 68)
	sprite.position = from_center - (sprite.size * 0.5)
	add_child(sprite)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position", to_center - (sprite.size * 0.5), 0.24)
	await tween.finished
	sprite.queue_free()

	if bool(move.get("is_castle_kingside", false)) or bool(move.get("is_castle_queenside", false)):
		await _animate_castle_rook_move(str(last_entry.get("color", "")), bool(move.get("is_castle_kingside", false)))


func _animate_castle_rook_move(color: String, is_kingside: bool) -> void:
	var rook_from := Vector2i(7, 7) if color == ChessEngine.WHITE and is_kingside else (
		Vector2i(0, 7) if color == ChessEngine.WHITE else (
			Vector2i(7, 0) if is_kingside else Vector2i(0, 0)
		)
	)
	var rook_to := Vector2i(5, 7) if color == ChessEngine.WHITE and is_kingside else (
		Vector2i(3, 7) if color == ChessEngine.WHITE else (
			Vector2i(5, 0) if is_kingside else Vector2i(3, 0)
		)
	)
	var piece: Variant = wizard_match.chess_engine.get_piece(rook_to)
	if piece == null:
		return
	var from_center := _board_square_center_global(rook_from)
	var to_center := _board_square_center_global(rook_to)
	var sprite := TextureRect.new()
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.texture = _piece_icon(piece)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.size = Vector2(68, 68)
	sprite.position = from_center - (sprite.size * 0.5)
	add_child(sprite)
	var tween := create_tween()
	tween.tween_property(sprite, "position", to_center - (sprite.size * 0.5), 0.18)
	await tween.finished
	sprite.queue_free()


func _animate_card_transitions(before_snapshot: Dictionary, after_snapshot: Dictionary) -> void:
	var before_lookup := _card_zone_lookup(before_snapshot)
	var after_lookup := _card_zone_lookup(after_snapshot)
	for card_instance_id in after_lookup.keys():
		if not before_lookup.has(card_instance_id):
			continue
		var before_entry: Dictionary = before_lookup[card_instance_id]
		var after_entry: Dictionary = after_lookup[card_instance_id]
		if str(before_entry.get("zone", "")) == str(after_entry.get("zone", "")):
			continue
		await _animate_card_transition(before_entry, after_entry)


func _animate_card_transition(before_entry: Dictionary, after_entry: Dictionary) -> void:
	var source := _zone_anchor_global(before_entry)
	var destination := _zone_anchor_global(after_entry)
	if source == Vector2.ZERO or destination == Vector2.ZERO:
		return

	var card_state: Dictionary = after_entry.get("card_state", before_entry.get("card_state", {}))
	var widget := CARD_WIDGET_SCENE.instantiate() as WizardMatchCardWidget
	widget.configure(
		self,
		card_state,
		_display_color(),
		_card_art_texture(card_state),
		bool(card_state.get("face_down", false)) and str(after_entry.get("zone", "")) != "graveyard"
	)
	widget.position = source - Vector2(66, 94)
	widget.size = Vector2(132, 188)
	widget.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(widget)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(widget, "position", destination - Vector2(66, 94), 0.26)
	tween.parallel().tween_property(widget, "rotation_degrees", 0.0, 0.26)
	await tween.finished
	widget.queue_free()


func _card_zone_lookup(snapshot: Dictionary) -> Dictionary:
	var lookup := {}
	for color in [ChessEngine.WHITE, ChessEngine.BLACK]:
		var player_state: Dictionary = snapshot.get("players", {}).get(color, {})
		for zone in ["deck", "hand", "battlefield", "graveyard", "exile"]:
			for card_state_value in player_state.get(zone, []):
				var card_state: Dictionary = card_state_value
				lookup[str(card_state.get("instance_id", ""))] = {
					"owner_color": color,
					"zone": zone,
					"card_state": card_state,
				}
	return lookup


func _zone_anchor_global(entry: Dictionary) -> Vector2:
	var owner_color := str(entry.get("owner_color", ""))
	var zone := str(entry.get("zone", ""))
	var card_state: Dictionary = entry.get("card_state", {})
	match zone:
		"deck":
			return opponent_deck_label.global_position + Vector2(42, -60) if owner_color == _opponent(_display_color()) else local_deck_label.global_position + Vector2(42, -60)
		"graveyard":
			return opponent_graveyard_label.global_position + Vector2(42, -60) if owner_color == _opponent(_display_color()) else local_graveyard_label.global_position + Vector2(42, -60)
		"hand":
			return _card_source_global(str(card_state.get("instance_id", "")))
		"battlefield":
			var square_name := str(card_state.get("attached_to", card_state.get("placed_on", "")))
			if not square_name.is_empty() and board_button_by_name.has(square_name):
				return _board_square_center_global(board_button_by_name[square_name].square)
			return board_view.global_position + (board_view.size * 0.5)
		_:
			return board_view.global_position + (board_view.size * 0.5)


func _board_square_center_global(square: Vector2i) -> Vector2:
	if not board_buttons.has(square):
		return Vector2.ZERO
	return board_view.get_square_center_global(square)


func _current_actor_color() -> String:
	if wizard_match.state == WizardMatch.STATE_SETUP:
		for color in [ChessEngine.WHITE, ChessEngine.BLACK]:
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
			for color in [ChessEngine.WHITE, ChessEngine.BLACK]:
				if wizard_match.get_pending_hand_limit_discard_count(color) > 0:
					return color
			return _opponent(wizard_match.chess_state.active_color)
		_:
			return ""


func _display_color() -> String:
	match perspective_mode:
		PerspectiveMode.WHITE:
			return ChessEngine.WHITE
		PerspectiveMode.BLACK:
			return ChessEngine.BLACK
		_:
			pass
	var non_ai_colors: Array[String] = []
	for color in [ChessEngine.WHITE, ChessEngine.BLACK]:
		if not ai_enabled_by_color.get(color, false):
			non_ai_colors.append(color)
	if non_ai_colors.size() == 1:
		return non_ai_colors[0]
	var actor := _current_actor_color()
	if non_ai_colors.has(actor):
		return actor
	return ChessEngine.WHITE


func _opponent(color: String) -> String:
	return ChessEngine.BLACK if color == ChessEngine.WHITE else ChessEngine.WHITE


func _square_text(square: Vector2i) -> String:
	var lines: Array[String] = []
	if show_coordinates:
		lines.append(wizard_match.chess_engine.square_to_algebraic(square))
	var piece = wizard_match.chess_engine.get_piece(square)
	lines.append("" if piece == null else _piece_label(piece))
	var markers := _square_marker_text(square)
	if not markers.is_empty():
		lines.append(markers)
	return "\n".join(lines)


func _square_name(square: Vector2i) -> String:
	return "%s%d" % [char(97 + square.x), 8 - square.y]


func _piece_icon(piece: Variant) -> Texture2D:
	if piece == null:
		return null
	var piece_type := str(piece.get("type", ""))
	var color := str(piece.get("color", ""))
	var cache_key := "%s:%s" % [color, piece_type]
	if piece_icon_cache.has(cache_key):
		return piece_icon_cache[cache_key]

	var cell_width := int(float(PIECE_ATLAS.get_width()) / 6.0)
	var cell_height := int(float(PIECE_ATLAS.get_height()) / 2.0)
	var column := 0
	match piece_type:
		ChessEngine.PIECE_PAWN:
			column = 0
		ChessEngine.PIECE_KNIGHT:
			column = 1
		ChessEngine.PIECE_BISHOP:
			column = 2
		ChessEngine.PIECE_ROOK:
			column = 3
		ChessEngine.PIECE_QUEEN:
			column = 4
		ChessEngine.PIECE_KING:
			column = 5
	var row := 0 if color == ChessEngine.WHITE else 1
	var atlas := AtlasTexture.new()
	atlas.atlas = PIECE_ATLAS
	atlas.region = Rect2(column * cell_width, row * cell_height, cell_width, cell_height)
	piece_icon_cache[cache_key] = atlas
	return atlas


func _card_art_texture(card_state: Dictionary) -> Texture2D:
	var art_texture_path := str(card_state.get("art_texture_path", ""))
	if not art_texture_path.is_empty():
		var texture := load(art_texture_path) as Texture2D
		if texture != null:
			return texture
	match str(card_state.get("school", "")):
		"Order":
			return ORDER_CARD_ART
		_:
			return ARCANE_CARD_ART


func _piece_label(piece: Dictionary) -> String:
	var color_prefix := "W" if piece["color"] == ChessEngine.WHITE else "B"
	var piece_letter := ""
	match piece["type"]:
		ChessEngine.PIECE_PAWN:
			piece_letter = "P"
		ChessEngine.PIECE_KNIGHT:
			piece_letter = "N"
		ChessEngine.PIECE_BISHOP:
			piece_letter = "B"
		ChessEngine.PIECE_ROOK:
			piece_letter = "R"
		ChessEngine.PIECE_QUEEN:
			piece_letter = "Q"
		ChessEngine.PIECE_KING:
			piece_letter = "K"
	return "%s%s" % [color_prefix, piece_letter]


func _square_marker_text(square: Vector2i) -> String:
	var labels: Array[String] = []
	var square_name := wizard_match.chess_engine.square_to_algebraic(square)
	var viewer := _display_color()
	for color in [ChessEngine.WHITE, ChessEngine.BLACK]:
		for card_state_value in wizard_match.get_player_state(color).get("battlefield", []):
			var card_state: Dictionary = card_state_value
			if str(card_state.get("attached_to", "")) == square_name:
				labels.append("Unit")
			elif str(card_state.get("placed_on", "")) == square_name:
				if bool(card_state.get("face_down", false)) and color != viewer:
					continue
				labels.append("Trap")
	if labels.is_empty():
		return ""
	return "[" + ", ".join(labels) + "]"


func _square_tooltip(square: Vector2i) -> String:
	var lines: Array[String] = []
	lines.append("Square: %s" % wizard_match.chess_engine.square_to_algebraic(square))
	var piece = wizard_match.chess_engine.get_piece(square)
	lines.append("Piece: empty" if piece == null else "Piece: %s %s" % [str(piece["color"]).capitalize(), str(piece["type"]).capitalize()])
	var attached_cards := _attached_cards_for_square(square)
	if not attached_cards.is_empty():
		lines.append("Attached cards: %s" % ", ".join(attached_cards))
	if threat_overlay_enabled and _is_threatened_square(square):
		lines.append("Threatened by %s" % _opponent(_display_color()).capitalize())
	return "\n".join(lines)


func _square_color(square: Vector2i) -> Color:
	if selected_square != null and square == selected_square:
		return SELECTED_SQUARE
	var base_color := LIGHT_SQUARE if (square.x + square.y) % 2 == 0 else DARK_SQUARE
	if interaction_controller.state == CardInteractionController.State.CARD_TARGETING and hovered_square != null and square == hovered_square and _can_play_selected_card_on_square(square):
		return base_color.lerp(CARD_TARGET_HOVER_TINT, 0.34)
	for move_value in selected_moves:
		if move_value["to"] == square:
			return LEGAL_SQUARE
	if threat_overlay_enabled and _is_threatened_square(square):
		return THREATENED_SQUARE
	return base_color


func _is_threatened_square(square: Vector2i) -> bool:
	return wizard_match.chess_engine.is_square_attacked(square, _opponent(_display_color()))


func _legal_card_ids(color: String) -> Dictionary:
	var ids := {}
	for action_value in wizard_match.get_legal_card_actions(color):
		ids[str(action_value["card_instance_id"])] = true
	return ids


func _selected_card_actions() -> Array:
	var actions: Array = []
	if selected_card_instance_id.is_empty():
		return actions
	for action_value in wizard_match.get_legal_card_actions(_display_color()):
		if str(action_value["card_instance_id"]) == selected_card_instance_id:
			actions.append(action_value)
	return actions


func _selected_card_has_zero_target_action(actions: Array) -> bool:
	return not _first_zero_target_action(actions).is_empty()


func _first_zero_target_action(actions: Array) -> Dictionary:
	for action_value in actions:
		if action_value.get("targets", []).is_empty():
			return action_value
	return {}


func _selected_card_target_square_names() -> Dictionary:
	var square_names := {}
	for action_value in _selected_card_actions():
		for target_value in action_value.get("targets", []):
			var square_name := str(target_value.get("square", ""))
			if not square_name.is_empty():
				square_names[square_name] = true
	return square_names


func _can_play_selected_card_on_square(square: Vector2i) -> bool:
	return not selected_card_instance_id.is_empty() and _matching_card_action_for_square(selected_card_instance_id, square) != null


func _play_selected_card_on_square(square: Vector2i) -> void:
	var action = _matching_card_action_for_square(selected_card_instance_id, square)
	if action == null:
		return
	_after_action(wizard_match.play_card_from_hand(str(action["card_instance_id"]), action.get("targets", [])), "Play targeted card")


func _matching_card_action_for_square(card_instance_id: String, square: Vector2i):
	var square_name := wizard_match.chess_engine.square_to_algebraic(square)
	for action_value in wizard_match.get_legal_card_actions(_display_color()):
		if str(action_value["card_instance_id"]) != card_instance_id:
			continue
		for target_value in action_value.get("targets", []):
			if str(target_value.get("square", "")) == square_name:
				return action_value
	return null


func _clear_card_selection() -> void:
	selected_card_instance_id = ""
	_refresh_ui()


func _is_hand_limit_selection_active() -> bool:
	var actor := _current_actor_color()
	return wizard_match.state == WizardMatch.STATE_ACTIVE and wizard_match.phase == WizardMatch.PHASE_END and wizard_match.get_pending_hand_limit_discard_count(actor) > 0 and actor == _display_color()


func _local_actor_locked_by_ai() -> bool:
	var actor := _current_actor_color()
	return not actor.is_empty() and ai_enabled_by_color.get(actor, false)


func get_square_drag_data(square: Vector2i):
	on_board_piece_drag_started(square, get_global_mouse_position())
	return {"type": "board_piece", "from_square": square}


func get_hand_card_drag_data(card_state: Dictionary):
	var actor := _current_actor_color()
	if actor.is_empty() or actor != _display_color() or ai_enabled_by_color.get(actor, false):
		return null
	if wizard_match.state != WizardMatch.STATE_ACTIVE:
		return null
	if wizard_match.phase != WizardMatch.PHASE_PREPARATION and wizard_match.phase != WizardMatch.PHASE_REACTION:
		return null
	var instance_id := str(card_state.get("instance_id", ""))
	if _selected_card_actions_for_id(instance_id).is_empty():
		return null
	selected_square = null
	selected_moves.clear()
	selected_hand_card_ids.clear()
	selected_card_instance_id = instance_id
	if _card_has_square_targets(instance_id):
		interaction_controller.begin_card_drag(instance_id, get_global_mouse_position(), true)
	elif _card_has_zero_target_action(instance_id):
		interaction_controller.begin_card_drag(instance_id, get_global_mouse_position(), false)
	else:
		interaction_controller.reset_drag()
	_refresh_ui()
	return {"type": "hand_card", "card_instance_id": instance_id}


func can_drop_on_square(square: Vector2i, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	match str(data.get("type", "")):
		"board_piece":
			return _can_drop_piece_on_square(square, data)
		"hand_card":
			return _matching_card_action_for_square(str(data.get("card_instance_id", "")), square) != null
		_:
			return false


func handle_square_drop(square: Vector2i, data) -> void:
	if not can_drop_on_square(square, data):
		return
	match str(data.get("type", "")):
		"board_piece":
			_drop_piece_on_square(square, data)
		"hand_card":
			selected_card_instance_id = str(data.get("card_instance_id", ""))
			_play_selected_card_on_square(square)


func _can_drop_piece_on_square(square: Vector2i, data: Dictionary) -> bool:
	var from_square: Vector2i = data.get("from_square", Vector2i(-1, -1))
	for move_value in wizard_match.chess_engine.get_legal_moves_from(from_square):
		if move_value["to"] == square:
			return true
	return false


func _drop_piece_on_square(square: Vector2i, data: Dictionary) -> void:
	var from_square: Vector2i = data.get("from_square", Vector2i(-1, -1))
	for move_value in wizard_match.chess_engine.get_legal_moves_from(from_square):
		if move_value["to"] == square:
			_commit_move(move_value)
			return


func _commit_move(move: Dictionary) -> void:
	_after_action(
		wizard_match.apply_move_action(wizard_match.chess_engine.create_move_action(move["from"], move["to"], str(move.get("promotion", "queen")))),
		"Move %s to %s" % [
			wizard_match.chess_engine.square_to_algebraic(move["from"]),
			wizard_match.chess_engine.square_to_algebraic(move["to"]),
		]
	)


func _build_piece_drag_preview(piece: Dictionary) -> Control:
	var preview := Control.new()
	preview.custom_minimum_size = Vector2(84, 84)
	var glow := ColorRect.new()
	glow.color = Color(0.25, 0.65, 1.0, 0.22)
	glow.size = Vector2(84, 84)
	preview.add_child(glow)
	var icon_rect := TextureRect.new()
	icon_rect.texture = _piece_icon(piece)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.position = Vector2(10, 10)
	icon_rect.size = Vector2(64, 64)
	preview.add_child(icon_rect)
	return preview


func _build_card_drag_preview(card_state: Dictionary) -> Control:
	var widget := CARD_WIDGET_SCENE.instantiate() as WizardMatchCardWidget
	widget.configure(self, card_state, _display_color(), _card_art_texture(card_state), false)
	widget.set_visual_state(true, true, false)
	widget.mouse_filter = Control.MOUSE_FILTER_IGNORE
	widget.scale = Vector2.ONE * 0.9
	return widget


func _selected_card_actions_for_id(card_instance_id: String) -> Array:
	var actions: Array = []
	for action_value in wizard_match.get_legal_card_actions(_display_color()):
		if str(action_value["card_instance_id"]) == card_instance_id:
			actions.append(action_value)
	return actions


func _card_has_square_targets(card_instance_id: String) -> bool:
	for action_value in _selected_card_actions_for_id(card_instance_id):
		for target_value in action_value.get("targets", []):
			if not str(target_value.get("square", "")).is_empty():
				return true
	return false


func _card_has_zero_target_action(card_instance_id: String) -> bool:
	return not _first_zero_target_action(_selected_card_actions_for_id(card_instance_id)).is_empty()


func _finalize_active_drag() -> void:
	var drag_kind := interaction_controller.drag_kind()
	var drag_square = interaction_controller.source_square
	var drag_card_id := interaction_controller.card_instance_id
	var release_position := interaction_controller.cursor_global
	interaction_controller.clear_preview()

	match drag_kind:
		"piece":
			var square := board_view.square_at_global_position(release_position)
			_log_drag("piece_drag_released", {
				"source": _square_name(drag_square) if drag_square != null else "",
				"target": "" if square == WizardMatchBoardView.INVALID_SQUARE else _square_name(square),
			})
			if square != WizardMatchBoardView.INVALID_SQUARE:
				for move_value in wizard_match.chess_engine.get_legal_moves_from(drag_square):
					var move: Dictionary = move_value
					if move["to"] == square:
						_commit_move(move)
						return
		"card_target":
			var target_square := board_view.square_at_global_position(release_position)
			_log_drag("card_target_released", {
				"card_instance_id": drag_card_id,
				"target": "" if target_square == WizardMatchBoardView.INVALID_SQUARE else _square_name(target_square),
			})
			if target_square != WizardMatchBoardView.INVALID_SQUARE:
				selected_card_instance_id = drag_card_id
				if _can_play_selected_card_on_square(target_square):
					_play_selected_card_on_square(target_square)
					return
		"card_play":
			var released_outside_hand := not local_hand_row.get_global_rect().has_point(release_position)
			_log_drag("card_play_released", {
				"card_instance_id": drag_card_id,
				"released_outside_hand": released_outside_hand,
			})
			if released_outside_hand:
				selected_card_instance_id = drag_card_id
				_on_play_selected_card_pressed()
				return
	_cancel_active_interaction()


func _cancel_active_interaction() -> void:
	var card_instance_id := interaction_controller.card_instance_id
	interaction_controller.reset_drag()
	if not card_instance_id.is_empty() and local_hand_widgets.has(card_instance_id):
		var widget: WizardMatchCardWidget = local_hand_widgets[card_instance_id]
		if is_instance_valid(widget):
			widget.cancel_pointer_interaction()
	selected_card_instance_id = ""
	selected_square = null
	selected_moves.clear()
	hovered_square = null
	targeting_overlay.clear()
	_refresh_ui()


func _player_public_summary_text(color: String, viewer_color: String) -> String:
	var player_state := wizard_match.get_player_state(color)
	var label := "%s  %d/%d mana  %d hand  %d active" % [
		color.capitalize(),
		int(player_state.get("mana", 0)),
		int(player_state.get("maximum_mana", 0)),
		player_state.get("hand", []).size(),
		player_state.get("battlefield", []).size(),
	]
	if color == viewer_color:
		label += "  Priority %s" % ("Yes" if wizard_match.reaction_priority_color == color else "No")
	return label


func _card_button_text(card_state: Dictionary, viewer_color: String) -> String:
	var header := "%s (%d)" % [str(card_state.get("display_name", card_state["card_id"])), int(card_state.get("mana_cost", 0))]
	var type_line := str(card_state.get("card_type", "")).capitalize()
	var rules := str(card_state.get("rules_text", ""))
	if rules.length() > 72:
		rules = rules.substr(0, 69) + "..."
	var playable_prefix := "[Play]\n" if _legal_card_ids(viewer_color).has(str(card_state["instance_id"])) else ""
	return "%s%s\n%s\n%s" % [playable_prefix, header, type_line, rules]


func _card_tooltip(card_state: Dictionary, zone: String) -> String:
	var lines: Array[String] = []
	lines.append("%s (%s)" % [str(card_state.get("display_name", card_state["card_id"])), str(card_state.get("card_type", "")).capitalize()])
	lines.append("Mana: %d" % int(card_state.get("mana_cost", 0)))
	lines.append("Zone: %s" % zone.capitalize())
	var target_requirements: Array = card_state.get("target_requirements", [])
	if not target_requirements.is_empty():
		lines.append("Targets: %s" % ", ".join(target_requirements))
	var rules_text := str(card_state.get("rules_text", ""))
	if not rules_text.is_empty():
		lines.append("Rules: %s" % rules_text)
	return "\n".join(lines)


func _card_public_list_label(card_state: Dictionary, owner_color: String, viewer_color: String) -> String:
	if bool(card_state.get("face_down", false)) and owner_color != viewer_color:
		return "%s Face-down Trap" % owner_color.capitalize()
	return "%s %s" % [owner_color.capitalize(), str(card_state.get("display_name", card_state["card_id"]))]


func _find_card_entry(card_instance_id: String) -> Dictionary:
	for color in [ChessEngine.WHITE, ChessEngine.BLACK]:
		var player_state := wizard_match.get_player_state(color)
		for zone in ["hand", "battlefield", "graveyard", "deck", "exile"]:
			for card_state_value in player_state.get(zone, []):
				if str(card_state_value.get("instance_id", "")) == card_instance_id:
					return {
						"owner_color": color,
						"zone": zone,
						"card_state": card_state_value,
					}
	return {}


func _set_card_inspector(card_state: Dictionary, zone: String, owner_color: String) -> void:
	inspect_popup.show_card(card_state, zone, owner_color, _card_art_texture(card_state))


func _set_square_inspector(square: Vector2i) -> void:
	var piece = wizard_match.chess_engine.get_piece(square)
	var attached_cards := _attached_cards_for_square(square)
	var move_labels: Array[String] = []
	for move_value in wizard_match.chess_engine.get_legal_moves_from(square):
		move_labels.append(wizard_match.chess_engine.square_to_algebraic(move_value["to"]))
	var piece_description := "empty" if piece == null else "%s %s" % [str(piece["color"]).capitalize(), str(piece["type"]).capitalize()]
	inspect_popup.show_square(
		wizard_match.chess_engine.square_to_algebraic(square),
		_piece_icon(piece),
		piece_description,
		attached_cards,
		move_labels,
		_is_threatened_square(square)
	)


func _attached_cards_for_square(square: Vector2i) -> Array[String]:
	var square_name := wizard_match.chess_engine.square_to_algebraic(square)
	var labels: Array[String] = []
	for color in [ChessEngine.WHITE, ChessEngine.BLACK]:
		for card_state_value in wizard_match.get_player_state(color).get("battlefield", []):
			if str(card_state_value.get("attached_to", "")) == square_name:
				labels.append(str(card_state_value.get("display_name", card_state_value["card_id"])))
	return labels


func _event_summary_text(event: Dictionary) -> String:
	var event_type := str(event.get("type", ""))
	var payload: Dictionary = event.get("payload", {})
	match event_type:
		"match_started":
			return "Match started"
		"opening_hand_kept":
			return "%s kept opening hand." % str(payload.get("color", "")).capitalize()
		"mulligan_resolved":
			return "%s mulliganed %d." % [str(payload.get("color", "")).capitalize(), int(payload.get("cards_replaced", 0))]
		"beginning_phase_resolved":
			return "%s refreshed mana." % str(payload.get("color", "")).capitalize()
		"chess_move_resolved":
			var action: Dictionary = payload.get("action", {})
			return "%s moved %s to %s." % [str(payload.get("color", "")).capitalize(), str(action.get("from", "")), str(action.get("to", ""))]
		"card_played":
			return "%s played %s." % [str(payload.get("color", "")).capitalize(), str(payload.get("card_id", ""))]
		"trap_triggered":
			return "%s triggered on %s." % [str(payload.get("card_id", "")), str(payload.get("square", ""))]
		"hand_limit_discard_required":
			return "%s must discard %d." % [str(payload.get("color", "")).capitalize(), int(payload.get("discard_count", 0))]
		_:
			return event_type.replace("_", " ").capitalize()


func _important_notification_text(event: Dictionary) -> String:
	var event_type := str(event.get("type", ""))
	var payload: Dictionary = event.get("payload", {})
	match event_type:
		"chess_move_resolved":
			var action: Dictionary = payload.get("action", {})
			return "%s moved %s-%s" % [str(payload.get("color", "")).capitalize(), str(action.get("from", "")), str(action.get("to", ""))]
		"card_played":
			return "%s played %s" % [str(payload.get("color", "")).capitalize(), str(payload.get("card_id", ""))]
		"environment_replaced":
			return "Environment changed"
		"trap_triggered":
			return "%s triggered" % str(payload.get("card_id", ""))
		_:
			return ""


func _chess_outcome_text(outcome: Dictionary) -> String:
	match str(outcome.get("status", "")):
		ChessEngine.STATUS_CHECKMATE:
			return "checkmate (%s wins)" % str(outcome.get("winner", "")).capitalize()
		ChessEngine.STATUS_STALEMATE:
			return "stalemate"
		ChessEngine.STATUS_DRAW:
			return "draw (%s)" % str(outcome.get("reason", ""))
		_:
			return "active"


func _add_action_button(label: String, callback: Callable, disabled: bool = false, primary: bool = false) -> void:
	turn_action_panel.add_action(label, callback, disabled, primary)
