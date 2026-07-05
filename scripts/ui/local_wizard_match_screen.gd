extends Control

const LIGHT_SQUARE := Color("e7d7b1")
const DARK_SQUARE := Color("9f7b55")
const SELECTED_SQUARE := Color("83c47d")
const LEGAL_SQUARE := Color("f0d879")
const CARD_TARGET_SQUARE := Color("8eb8ff")
const THREATENED_SQUARE := Color("cb7f7f")
const PLAYABLE_CARD_COLOR := Color(1.0, 1.0, 1.0)
const DIMMED_CARD_COLOR := Color(0.72, 0.72, 0.72)
const SELECTED_CARD_COLOR := Color("ffe39a")
const SELECTION_CARD_COLOR := Color("9fdd95")

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
var show_coordinates: bool = true
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
var active_card_entries: Array = []
var white_graveyard_entries: Array = []
var black_graveyard_entries: Array = []
var previous_state_snapshot: Dictionary = {}
var toast_message_count: int = 0
var active_drag_kind: String = ""
var active_drag_source_square: Variant = null
var active_drag_card_instance_id: String = ""
var active_drag_cursor_global: Vector2 = Vector2.ZERO

@onready var ai_timer: Timer = %AiTimer
@onready var targeting_line: Line2D = %TargetingLine
@onready var status_label: Label = %StatusLabel
@onready var notification_toast: PanelContainer = %NotificationToast
@onready var notification_toast_label: Label = %NotificationToastLabel
@onready var detail_label: Label = %DetailLabel
@onready var action_hint_label: Label = %ActionHintLabel
@onready var opponent_summary_label: Label = %OpponentSummaryLabel
@onready var opponent_deck_label: Label = %OpponentDeckLabel
@onready var opponent_graveyard_label: Label = %OpponentGraveyardLabel
@onready var opponent_top_graveyard_label: Label = %OpponentTopGraveyardLabel
@onready var opponent_hero_name_label: Label = %OpponentHeroNameLabel
@onready var opponent_mana_label: Label = %OpponentManaLabel
@onready var environment_label: Label = %EnvironmentLabel
@onready var local_summary_label: Label = %LocalSummaryLabel
@onready var local_deck_label: Label = %LocalDeckLabel
@onready var local_graveyard_label: Label = %LocalGraveyardLabel
@onready var local_library_label: Label = %LocalLibraryLabel
@onready var local_hero_name_label: Label = %LocalHeroNameLabel
@onready var local_mana_label: Label = %LocalManaLabel
@onready var board_view: WizardMatchBoardView = %BoardView
@onready var play_drop_zone: WizardMatchCardPlayZone = %PlayDropZone
@onready var opponent_hand_title_label: Label = %OpponentHandTitleLabel
@onready var opponent_hand_row: Control = %OpponentHandRow
@onready var local_hand_title_label: Label = %LocalHandTitleLabel
@onready var local_hand_row: Control = %LocalHandRow
@onready var action_bar: HBoxContainer = %ActionBar
@onready var inspect_popup: PanelContainer = %InspectPopup
@onready var inspect_title_label: Label = %InspectTitleLabel
@onready var spotlight_art: TextureRect = %SpotlightArt
@onready var spotlight_back: TextureRect = %SpotlightBack
@onready var inspect_body_label: Label = %InspectBodyLabel
@onready var active_cards_list: ItemList = %ActiveCardsList
@onready var move_history_list: ItemList = %MoveHistoryList
@onready var event_history_list: ItemList = %EventHistoryList
@onready var white_graveyard_list: ItemList = %WhiteGraveyardList
@onready var black_graveyard_list: ItemList = %BlackGraveyardList
@onready var threat_toggle: CheckButton = %ThreatToggle
@onready var coordinates_toggle: CheckButton = %CoordinatesToggle
@onready var perspective_option: OptionButton = %PerspectiveOption
@onready var white_ai_button: CheckButton = %WhiteAiButton
@onready var black_ai_button: CheckButton = %BlackAiButton
@onready var last_ai_action_label: Label = %LastAiActionLabel
@onready var ai_timing_label: Label = %AiTimingLabel


func _ready() -> void:
	_load_resources()
	_configure_static_ui()
	_start_new_match()


func _input(event: InputEvent) -> void:
	if active_drag_kind.is_empty():
		return
	if event is InputEventMouseMotion:
		active_drag_cursor_global = event.global_position
		_update_targeting_line()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		active_drag_cursor_global = event.global_position
		_finalize_active_drag()


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
	perspective_option.add_item("Auto")
	perspective_option.add_item("White")
	perspective_option.add_item("Black")
	board_view.screen = self
	play_drop_zone.screen = self
	board_view.square_pressed.connect(_on_board_square_pressed)
	board_view.square_hovered.connect(_on_board_square_hovered)
	board_view.square_unhovered.connect(_on_board_square_unhovered)
	board_view.square_dropped.connect(handle_square_drop)
	for rank in range(8):
		for file in range(8):
			var square := Vector2i(file, rank)
			board_buttons[square] = square
			board_button_by_name[_square_name(square)] = square

	active_cards_list.item_selected.connect(_on_active_card_selected)
	white_graveyard_list.item_selected.connect(_on_white_graveyard_selected)
	black_graveyard_list.item_selected.connect(_on_black_graveyard_selected)
	threat_toggle.toggled.connect(_on_threat_toggled)
	coordinates_toggle.toggled.connect(_on_coordinates_toggled)
	perspective_option.item_selected.connect(_on_perspective_selected)
	white_ai_button.toggled.connect(_on_ai_toggle.bind(ChessEngine.WHITE))
	black_ai_button.toggled.connect(_on_ai_toggle.bind(ChessEngine.BLACK))
	local_hand_row.resized.connect(_layout_local_hand_cards)
	opponent_hand_row.resized.connect(_layout_opponent_hand_cards)


func _start_new_match() -> void:
	wizard_match = WizardMatch.new(match_rules)
	selected_square = null
	selected_moves.clear()
	selected_card_instance_id = ""
	selected_hand_card_ids.clear()
	hovered_square = null
	hovered_card_widget = null
	active_drag_kind = ""
	active_drag_source_square = null
	active_drag_card_instance_id = ""
	processed_event_count = 0
	recent_notifications.clear()
	rendered_perspective_color = ""
	last_ai_action_label.text = "AI: ready"
	ai_timing_label.text = "AI timings: no samples yet"
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


func _refresh_status() -> void:
	var actor := _current_actor_color()
	var actor_label := "None" if actor.is_empty() else actor.capitalize()
	status_label.text = "Turn %d  %s  %s" % [wizard_match.turn_number, wizard_match.phase.capitalize(), actor_label]
	if wizard_match.chess_state.outcome["status"] != ChessEngine.STATUS_ACTIVE:
		status_label.text += "  %s" % _chess_outcome_text(wizard_match.chess_state.outcome)

	if _local_actor_locked_by_ai():
		detail_label.text = "AI acting."
	elif wizard_match.state == WizardMatch.STATE_SETUP:
		detail_label.text = "Opening hand."
	elif wizard_match.phase == WizardMatch.PHASE_MOVE:
		detail_label.text = "Move a piece."
	elif wizard_match.phase == WizardMatch.PHASE_PREPARATION:
		detail_label.text = "Play cards."
	elif wizard_match.phase == WizardMatch.PHASE_REACTION:
		detail_label.text = "Reaction window."
	else:
		detail_label.text = "Inspect selection."


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

	opponent_summary_label.text = _player_public_summary_text(opponent_color, display_color)
	local_summary_label.text = _player_public_summary_text(display_color, display_color)

	var opponent_state := wizard_match.get_player_state(opponent_color)
	var local_state := wizard_match.get_player_state(display_color)
	opponent_deck_label.text = "Deck: %d" % opponent_state.get("deck", []).size()
	opponent_graveyard_label.text = "Graveyard: %d" % opponent_state.get("graveyard", []).size()
	opponent_top_graveyard_label.text = "Graveyard: %d" % opponent_state.get("graveyard", []).size()
	local_deck_label.text = "Deck: %d" % local_state.get("deck", []).size()
	local_graveyard_label.text = "Graveyard: %d" % local_state.get("graveyard", []).size()
	local_library_label.text = "Deck: %d" % local_state.get("deck", []).size()
	opponent_hero_name_label.text = "%s Wizard" % opponent_color.capitalize()
	opponent_mana_label.text = "%d/%d mana" % [int(opponent_state.get("mana", 0)), int(opponent_state.get("maximum_mana", 0))]
	local_hero_name_label.text = "%s Wizard" % display_color.capitalize()
	local_mana_label.text = "%d/%d mana" % [int(local_state.get("mana", 0)), int(local_state.get("maximum_mana", 0))]


func _refresh_environment() -> void:
	var environment_text := "none"
	for color in [ChessEngine.WHITE, ChessEngine.BLACK]:
		for card_state_value in wizard_match.get_player_state(color).get("battlefield", []):
			var card_state: Dictionary = card_state_value
			if str(card_state.get("card_type", "")) != CardDefinition.TYPE_ENVIRONMENT:
				continue
			environment_text = "%s (%s)" % [str(card_state.get("display_name", card_state["card_id"])), color.capitalize()]
	environment_label.text = "Environment: %s" % environment_text


func _refresh_board() -> void:
	for square in board_buttons.keys():
		var piece = wizard_match.chess_engine.get_piece(square)
		board_view.set_square_visual(
			square,
			_piece_icon(piece),
			_square_color(square),
			_square_tooltip(square),
			show_coordinates
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
	call_deferred("_layout_local_hand_cards")
	call_deferred("_layout_opponent_hand_cards")


func _layout_local_hand_cards() -> void:
	_layout_hand_fan(local_hand_row, local_hand_widgets, false)


func _layout_opponent_hand_cards() -> void:
	_layout_hand_fan(opponent_hand_row, opponent_hand_widgets, true)


func _layout_hand_fan(root: Control, widgets_by_id: Dictionary, is_opponent: bool) -> void:
	if not is_instance_valid(root):
		return
	var widgets: Array[Control] = []
	for child in root.get_children():
		var widget := child as Control
		if widget != null:
			widgets.append(widget)
	if widgets.is_empty():
		return

	var count := widgets.size()
	var card_size := Vector2(84, 120) if is_opponent else Vector2(108, 154)
	var radius: float = 520.0 if is_opponent else 640.0
	var spread_degrees: float = min(24.0, 8.0 + (count - 1) * (4.0 if is_opponent else 3.2))
	var start_angle: float = deg_to_rad(-spread_degrees * 0.5)
	var end_angle: float = deg_to_rad(spread_degrees * 0.5)
	var center := Vector2(root.size.x * 0.5, -radius + 148.0) if is_opponent else Vector2(root.size.x * 0.5, root.size.y + radius - 10.0)

	for index in range(count):
		var card: Control = widgets[index]
		card.size = card_size
		card.pivot_offset = Vector2(card_size.x * 0.5, card_size.y * 0.88)
		var t: float = 0.5 if count <= 1 else float(index) / float(count - 1)
		var angle: float = lerp(start_angle, end_angle, t)
		var anchor := center + Vector2(sin(angle) * radius, cos(angle) * radius) if is_opponent else center + Vector2(sin(angle) * radius, -cos(angle) * radius)
		var x: float = anchor.x - (card_size.x * 0.5)
		var y: float = anchor.y - (card_size.y * 0.88)
		var card_id: String = card.get_card_instance_id() if card.has_method("get_card_instance_id") else ""
		if not is_opponent and active_drag_kind.begins_with("card") and active_drag_card_instance_id == card_id:
			x = (root.size.x - card_size.x) * 0.5
			y = -82.0
			angle = 0.0
		card.position = Vector2(x, y)
		card.rotation_degrees = rad_to_deg(angle) * (0.55 if is_opponent else 0.78)
		card.z_index = 10 + index
		last_card_centers[card_id] = card.get_card_center_global()


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
	match active_drag_kind:
		"piece":
			if active_drag_source_square == null:
				targeting_line.visible = false
				return
			source = _board_square_center_global(active_drag_source_square)
			destination = active_drag_cursor_global
		"card_target":
			source = _card_source_global(active_drag_card_instance_id)
			destination = active_drag_cursor_global
		"card_play":
			source = _card_source_global(active_drag_card_instance_id)
			destination = active_drag_cursor_global
		_:
			if hovered_square == null or selected_card_instance_id.is_empty():
				targeting_line.visible = false
				return
			if not _can_play_selected_card_on_square(hovered_square):
				targeting_line.visible = false
				return
			source = _card_source_global(selected_card_instance_id)
			destination = _board_square_center_global(hovered_square)
	if source == Vector2.ZERO or destination == Vector2.ZERO:
		targeting_line.visible = false
		return
	var midpoint := source.lerp(destination, 0.5) + Vector2(0, -140)
	targeting_line.points = PackedVector2Array([
		targeting_line.to_local(source),
		targeting_line.to_local(midpoint),
		targeting_line.to_local(destination),
	])
	targeting_line.visible = true


func _card_source_global(card_instance_id: String) -> Vector2:
	if local_hand_widgets.has(card_instance_id):
		var widget: Control = local_hand_widgets[card_instance_id]
		return widget.get_card_center_global()
	if opponent_hand_widgets.has(card_instance_id):
		var opponent_widget: Control = opponent_hand_widgets[card_instance_id]
		return opponent_widget.get_card_center_global()
	return last_card_centers.get(card_instance_id, Vector2.ZERO)


func _refresh_action_bar() -> void:
	for child in action_bar.get_children():
		child.queue_free()

	var actor := _current_actor_color()
	if actor.is_empty():
		action_hint_label.text = "No action window is currently open."
		return

	if ai_enabled_by_color.get(actor, false):
		var ai_label := Label.new()
		ai_label.text = "%s is AI-controlled." % actor.capitalize()
		action_bar.add_child(ai_label)
		action_hint_label.text = "Autoplay is active for the current actor."
		return

	match wizard_match.state:
		WizardMatch.STATE_SETUP:
			_build_setup_actions()
		WizardMatch.STATE_ACTIVE:
			_build_active_actions(actor)
		_:
			_add_action_button("New Match", _on_new_match_pressed)
			action_hint_label.text = "Match complete."


func _build_setup_actions() -> void:
	_add_action_button("Keep Hand", _on_keep_hand_pressed)
	_add_action_button("Mulligan Selected", _on_mulligan_selected_pressed, selected_hand_card_ids.is_empty())
	_add_action_button("Mulligan All", _on_mulligan_all_pressed)
	action_hint_label.text = "Select cards to replace."


func _build_active_actions(actor: String) -> void:
	match wizard_match.phase:
		WizardMatch.PHASE_BEGINNING:
			_add_action_button("Resolve Beginning", _on_resolve_beginning_pressed)
			action_hint_label.text = "Draw and refresh mana."
		WizardMatch.PHASE_PREPARATION:
			if not selected_card_instance_id.is_empty():
				_add_action_button("Clear Card", _clear_card_selection)
			if _selected_card_has_zero_target_action(_selected_card_actions()):
				_add_action_button("Play Selected Card", _on_play_selected_card_pressed)
			_add_action_button("Finish Preparation", _on_finish_preparation_pressed)
			action_hint_label.text = "Play cards, then finish."
		WizardMatch.PHASE_MOVE:
			action_hint_label.text = "Move a %s piece." % actor.capitalize()
		WizardMatch.PHASE_REACTION:
			if not selected_card_instance_id.is_empty():
				_add_action_button("Clear Card", _clear_card_selection)
			if _selected_card_has_zero_target_action(_selected_card_actions()):
				_add_action_button("Play Selected Reaction", _on_play_selected_card_pressed)
			_add_action_button("Pass Priority", _on_pass_reaction_pressed)
			action_hint_label.text = "React or pass."
		WizardMatch.PHASE_END:
			var discard_count := wizard_match.get_pending_hand_limit_discard_count(actor)
			if discard_count > 0:
				_add_action_button("Discard Selected", _on_discard_selected_pressed, selected_hand_card_ids.size() != discard_count)
				action_hint_label.text = "Discard %d card(s)." % discard_count
			else:
				_add_action_button("Resolve End", _on_resolve_end_pressed)
				action_hint_label.text = "Resolve turn end."


func _refresh_histories() -> void:
	move_history_list.clear()
	for entry in wizard_match.chess_state.move_history:
		var prefix := "%d." % entry["turn_number"] if entry["color"] == ChessEngine.WHITE else "%d..." % entry["turn_number"]
		move_history_list.add_item("%s %s" % [prefix, entry["notation"]])

	event_history_list.clear()
	for event_value in wizard_match.get_event_history():
		event_history_list.add_item(_event_summary_text(event_value))


func _refresh_graveyards() -> void:
	white_graveyard_entries = wizard_match.get_player_state(ChessEngine.WHITE).get("graveyard", [])
	black_graveyard_entries = wizard_match.get_player_state(ChessEngine.BLACK).get("graveyard", [])
	_refresh_graveyard_list(white_graveyard_list, white_graveyard_entries, ChessEngine.WHITE)
	_refresh_graveyard_list(black_graveyard_list, black_graveyard_entries, ChessEngine.BLACK)


func _refresh_graveyard_list(list: ItemList, cards: Array, owner_color: String) -> void:
	list.clear()
	if cards.is_empty():
		list.add_item("(empty)")
		return
	var viewer := _display_color()
	for card_state_value in cards:
		list.add_item(_card_public_list_label(card_state_value, owner_color, viewer))


func _refresh_active_cards() -> void:
	active_cards_list.clear()
	active_card_entries.clear()
	var viewer := _display_color()
	for color in [ChessEngine.WHITE, ChessEngine.BLACK]:
		for card_state_value in wizard_match.get_player_state(color).get("battlefield", []):
			active_card_entries.append({
				"owner_color": color,
				"card_state": card_state_value,
			})
			active_cards_list.add_item(_card_public_list_label(card_state_value, color, viewer))
	if active_cards_list.item_count == 0:
		active_cards_list.add_item("(no active cards)")


func _refresh_inspector() -> void:
	if not selected_card_instance_id.is_empty():
		var entry := _find_card_entry(selected_card_instance_id)
		if not entry.is_empty():
			inspect_popup.visible = true
			_set_card_inspector(entry["card_state"], str(entry["zone"]), str(entry["owner_color"]))
			return
	if selected_square != null:
		inspect_popup.visible = true
		_set_square_inspector(selected_square)
		return
	inspect_popup.visible = false
	inspect_title_label.text = "Selection"
	inspect_body_label.text = "Select a square or card to inspect it."
	spotlight_art.texture = null
	spotlight_back.visible = false


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
	threat_toggle.button_pressed = threat_overlay_enabled
	coordinates_toggle.button_pressed = show_coordinates
	white_ai_button.button_pressed = ai_enabled_by_color[ChessEngine.WHITE]
	black_ai_button.button_pressed = ai_enabled_by_color[ChessEngine.BLACK]
	match perspective_mode:
		PerspectiveMode.WHITE:
			perspective_option.select(1)
		PerspectiveMode.BLACK:
			perspective_option.select(2)
		_:
			perspective_option.select(0)


func _refresh_ai_timings() -> void:
	var lines: Array[String] = []
	for color in [ChessEngine.WHITE, ChessEngine.BLACK]:
		var controller: WizardMatchAiController = ai_controllers.get(color)
		lines.append("%s: %s" % [color.capitalize(), controller.format_last_timing_report()])
	ai_timing_label.text = "\n".join(lines)


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
			active_drag_kind = "piece"
			active_drag_source_square = square
			active_drag_cursor_global = get_global_mouse_position()
		else:
			selected_moves.clear()
	_refresh_ui()


func _on_board_square_hovered(square: Vector2i) -> void:
	hovered_square = square
	_update_targeting_line()


func _on_board_square_unhovered(square: Vector2i) -> void:
	if hovered_square == square:
		hovered_square = null
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


func on_card_widget_drag_started(widget: WizardMatchCardWidget) -> void:
	var card_instance_id := str(widget.card_state.get("instance_id", ""))
	if card_instance_id.is_empty():
		return
	if wizard_match.state == WizardMatch.STATE_SETUP or _is_hand_limit_selection_active():
		return
	selected_square = null
	selected_moves.clear()
	selected_hand_card_ids.clear()
	selected_card_instance_id = card_instance_id
	active_drag_card_instance_id = card_instance_id
	active_drag_cursor_global = get_global_mouse_position()
	if _card_has_square_targets(card_instance_id):
		active_drag_kind = "card_target"
	elif _card_has_zero_target_action(card_instance_id):
		active_drag_kind = "card_play"
	else:
		active_drag_kind = ""
	_refresh_ui()


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


func _on_active_card_selected(index: int) -> void:
	if index < 0 or index >= active_card_entries.size():
		return
	selected_card_instance_id = str(active_card_entries[index]["card_state"]["instance_id"])
	selected_square = null
	selected_moves.clear()
	_refresh_ui()


func _on_white_graveyard_selected(index: int) -> void:
	_select_graveyard_card(index, white_graveyard_entries)


func _on_black_graveyard_selected(index: int) -> void:
	_select_graveyard_card(index, black_graveyard_entries)


func _select_graveyard_card(index: int, entries: Array) -> void:
	if index < 0 or index >= entries.size():
		return
	selected_card_instance_id = str(entries[index]["instance_id"])
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


func _after_action(result: Dictionary, label: String) -> void:
	var before_snapshot := previous_state_snapshot.duplicate(true)
	selected_moves.clear()
	selected_card_instance_id = ""
	selected_hand_card_ids.clear()
	active_drag_kind = ""
	active_drag_source_square = null
	active_drag_card_instance_id = ""
	last_ai_action_label.text = "%s: %s" % [label, "ok" if bool(result.get("ok", false)) else str(result.get("reason", "failed"))]
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
	last_ai_action_label.text = "AI %s: %s" % [actor.capitalize(), "acted" if bool(result.get("ok", false)) else str(result.get("reason", "failed"))]
	selected_moves.clear()
	selected_card_instance_id = ""
	selected_hand_card_ids.clear()
	active_drag_kind = ""
	active_drag_source_square = null
	active_drag_card_instance_id = ""
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

	var cell_width := int(PIECE_ATLAS.get_width() / 6)
	var cell_height := int(PIECE_ATLAS.get_height() / 2)
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
	for color in [ChessEngine.WHITE, ChessEngine.BLACK]:
		for card_state_value in wizard_match.get_player_state(color).get("battlefield", []):
			var card_state: Dictionary = card_state_value
			if str(card_state.get("attached_to", "")) == square_name:
				labels.append("Unit")
			elif str(card_state.get("placed_on", "")) == square_name:
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
	if _selected_card_target_square_names().has(wizard_match.chess_engine.square_to_algebraic(square)):
		return CARD_TARGET_SQUARE
	for move_value in selected_moves:
		if move_value["to"] == square:
			return LEGAL_SQUARE
	if threat_overlay_enabled and _is_threatened_square(square):
		return THREATENED_SQUARE
	return LIGHT_SQUARE if (square.x + square.y) % 2 == 0 else DARK_SQUARE


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


func can_drop_on_play_zone(data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if str(data.get("type", "")) != "hand_card":
		return false
	var card_instance_id := str(data.get("card_instance_id", ""))
	return not _first_zero_target_action(_selected_card_actions_for_id(card_instance_id)).is_empty()


func handle_play_zone_drop(data) -> void:
	if not can_drop_on_play_zone(data):
		return
	selected_card_instance_id = str(data.get("card_instance_id", ""))
	_on_play_selected_card_pressed()


func _is_hand_limit_selection_active() -> bool:
	var actor := _current_actor_color()
	return wizard_match.state == WizardMatch.STATE_ACTIVE and wizard_match.phase == WizardMatch.PHASE_END and wizard_match.get_pending_hand_limit_discard_count(actor) > 0 and actor == _display_color()


func _local_actor_locked_by_ai() -> bool:
	var actor := _current_actor_color()
	return not actor.is_empty() and ai_enabled_by_color.get(actor, false)


func get_square_drag_data(square: Vector2i):
	if wizard_match.state != WizardMatch.STATE_ACTIVE or wizard_match.phase != WizardMatch.PHASE_MOVE:
		return null
	var actor := _current_actor_color()
	if actor.is_empty() or actor != _display_color() or ai_enabled_by_color.get(actor, false):
		return null
	var piece = wizard_match.chess_engine.get_piece(square)
	if piece == null or str(piece["color"]) != actor:
		return null
	selected_square = square
	selected_moves = wizard_match.chess_engine.get_legal_moves_from(square)
	selected_card_instance_id = ""
	_refresh_ui()
	set_drag_preview(_build_piece_drag_preview(piece))
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
	_refresh_ui()
	set_drag_preview(_build_card_drag_preview(card_state))
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
	var drag_kind := active_drag_kind
	var drag_square = active_drag_source_square
	var drag_card_id := active_drag_card_instance_id
	active_drag_kind = ""
	active_drag_source_square = null
	active_drag_card_instance_id = ""

	match drag_kind:
		"piece":
			var square := board_view.square_at_global_position(active_drag_cursor_global)
			if square != WizardMatchBoardView.INVALID_SQUARE:
				for move_value in wizard_match.chess_engine.get_legal_moves_from(drag_square):
					var move: Dictionary = move_value
					if move["to"] == square:
						_commit_move(move)
						return
		"card_target":
			var target_square := board_view.square_at_global_position(active_drag_cursor_global)
			if target_square != WizardMatchBoardView.INVALID_SQUARE:
				selected_card_instance_id = drag_card_id
				if _can_play_selected_card_on_square(target_square):
					_play_selected_card_on_square(target_square)
					return
		"card_play":
			if play_drop_zone.get_global_rect().has_point(active_drag_cursor_global):
				selected_card_instance_id = drag_card_id
				_on_play_selected_card_pressed()
				return
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
	inspect_title_label.text = str(card_state.get("display_name", card_state["card_id"]))
	spotlight_art.texture = _card_art_texture(card_state)
	spotlight_back.visible = bool(card_state.get("face_down", false)) and zone != "graveyard"
	var lines: Array[String] = []
	lines.append("Owner: %s" % owner_color.capitalize())
	lines.append("Zone: %s" % zone.capitalize())
	lines.append("Type: %s" % str(card_state.get("card_type", "")).capitalize())
	lines.append("Mana Cost: %d" % int(card_state.get("mana_cost", 0)))
	var target_requirements: Array = card_state.get("target_requirements", [])
	if not target_requirements.is_empty():
		lines.append("Targeting: %s" % ", ".join(target_requirements))
	var attached_to := str(card_state.get("attached_to", ""))
	if not attached_to.is_empty():
		lines.append("Attached To: %s" % attached_to)
	var placed_on := str(card_state.get("placed_on", ""))
	if not placed_on.is_empty():
		lines.append("Placed On: %s" % placed_on)
	var rules_text := str(card_state.get("rules_text", ""))
	if not rules_text.is_empty():
		lines.append("")
		lines.append(rules_text)
	inspect_body_label.text = "\n".join(lines)


func _set_square_inspector(square: Vector2i) -> void:
	var piece = wizard_match.chess_engine.get_piece(square)
	inspect_title_label.text = "Square %s" % wizard_match.chess_engine.square_to_algebraic(square)
	spotlight_art.texture = _piece_icon(piece)
	spotlight_back.visible = false
	var lines: Array[String] = []
	lines.append("Piece: empty" if piece == null else "Piece: %s %s" % [str(piece["color"]).capitalize(), str(piece["type"]).capitalize()])
	var attached_cards := _attached_cards_for_square(square)
	lines.append("Attached Units: %s" % ("none" if attached_cards.is_empty() else ", ".join(attached_cards)))
	var move_labels: Array[String] = []
	for move_value in wizard_match.chess_engine.get_legal_moves_from(square):
		move_labels.append(wizard_match.chess_engine.square_to_algebraic(move_value["to"]))
	lines.append("Legal Moves: %s" % ("none" if move_labels.is_empty() else ", ".join(move_labels)))
	lines.append("Threatened: %s" % ("yes" if _is_threatened_square(square) else "no"))
	inspect_body_label.text = "\n".join(lines)


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


func _add_action_button(label: String, callback: Callable, disabled: bool = false) -> void:
	var button := Button.new()
	button.text = label
	button.disabled = disabled
	button.pressed.connect(callback)
	action_bar.add_child(button)
