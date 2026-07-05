class_name WizardMatchHudSidebar
extends TabContainer

signal card_selected(card_instance_id: String)
signal threat_toggled(enabled: bool)
signal coordinates_toggled(enabled: bool)
signal perspective_selected(index: int)
signal ai_toggled(enabled: bool, color: String)

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

var active_card_ids: Array[String] = []
var white_graveyard_card_ids: Array[String] = []
var black_graveyard_card_ids: Array[String] = []


func _ready() -> void:
	set_tab_title(0, "History")
	set_tab_title(1, "Active")
	set_tab_title(2, "Graveyards")
	set_tab_title(3, "Settings")
	perspective_option.add_item("Auto")
	perspective_option.add_item("White")
	perspective_option.add_item("Black")
	active_cards_list.item_selected.connect(_on_card_list_selected.bind(active_card_ids))
	white_graveyard_list.item_selected.connect(_on_card_list_selected.bind(white_graveyard_card_ids))
	black_graveyard_list.item_selected.connect(_on_card_list_selected.bind(black_graveyard_card_ids))
	threat_toggle.toggled.connect(func(enabled: bool) -> void: threat_toggled.emit(enabled))
	coordinates_toggle.toggled.connect(func(enabled: bool) -> void: coordinates_toggled.emit(enabled))
	perspective_option.item_selected.connect(func(index: int) -> void: perspective_selected.emit(index))
	white_ai_button.toggled.connect(func(enabled: bool) -> void: ai_toggled.emit(enabled, "white"))
	black_ai_button.toggled.connect(func(enabled: bool) -> void: ai_toggled.emit(enabled, "black"))


func set_histories(move_entries: Array[String], event_entries: Array[String]) -> void:
	_replace_list_items(move_history_list, move_entries)
	_replace_list_items(event_history_list, event_entries)


func set_active_cards(entries: Array[Dictionary]) -> void:
	active_card_ids.clear()
	active_cards_list.clear()
	for entry in entries:
		active_card_ids.append(str(entry.get("card_instance_id", "")))
		active_cards_list.add_item(str(entry.get("label", "Unknown Card")))
	if entries.is_empty():
		active_cards_list.add_item("(no active cards)")


func set_graveyards(white_entries: Array[Dictionary], black_entries: Array[Dictionary]) -> void:
	_set_card_list(white_graveyard_list, white_graveyard_card_ids, white_entries)
	_set_card_list(black_graveyard_list, black_graveyard_card_ids, black_entries)


func set_settings(threat_enabled: bool, coordinates_enabled: bool, perspective_index: int, white_ai_enabled: bool, black_ai_enabled: bool) -> void:
	threat_toggle.set_pressed_no_signal(threat_enabled)
	coordinates_toggle.set_pressed_no_signal(coordinates_enabled)
	perspective_option.select(perspective_index)
	white_ai_button.set_pressed_no_signal(white_ai_enabled)
	black_ai_button.set_pressed_no_signal(black_ai_enabled)


func set_ai_status(action_text: String, timing_text: String) -> void:
	last_ai_action_label.text = action_text
	ai_timing_label.text = timing_text


func set_ai_action_text(action_text: String) -> void:
	last_ai_action_label.text = action_text


func set_ai_timing_text(timing_text: String) -> void:
	ai_timing_label.text = timing_text


func _replace_list_items(list: ItemList, entries: Array[String]) -> void:
	list.clear()
	for entry in entries:
		list.add_item(entry)


func _set_card_list(list: ItemList, card_ids: Array[String], entries: Array[Dictionary]) -> void:
	card_ids.clear()
	list.clear()
	for entry in entries:
		card_ids.append(str(entry.get("card_instance_id", "")))
		list.add_item(str(entry.get("label", "Unknown Card")))
	if entries.is_empty():
		list.add_item("(empty)")


func _on_card_list_selected(index: int, card_ids: Array[String]) -> void:
	if index < 0 or index >= card_ids.size():
		return
	var card_instance_id := card_ids[index]
	if not card_instance_id.is_empty():
		card_selected.emit(card_instance_id)
