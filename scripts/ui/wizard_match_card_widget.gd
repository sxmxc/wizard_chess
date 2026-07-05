extends Button
class_name WizardMatchCardWidget

const CARD_BACK_TEXTURE := preload("res://assets/ui/wizard_match/card_back.png")

var screen: Control
var card_state: Dictionary = {}
var art_texture: Texture2D
var viewer_color: String = ""
var is_face_down: bool = false

@onready var glow_rect: ColorRect = %GlowRect
@onready var shadow_rect: ColorRect = %ShadowRect
@onready var card_back_rect: TextureRect = %CardBackRect
@onready var art_rect: TextureRect = %ArtRect
@onready var title_label: Label = %TitleLabel
@onready var type_label: Label = %TypeLabel
@onready var rules_label: Label = %RulesLabel
@onready var mana_badge: PanelContainer = %ManaBadge
@onready var mana_label: Label = %ManaLabel
@onready var state_badge: Label = %StateBadge


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func configure(
	next_screen: Control,
	next_card_state: Dictionary,
	next_viewer_color: String,
	next_art_texture: Texture2D,
	next_is_face_down: bool
) -> void:
	screen = next_screen
	card_state = next_card_state
	viewer_color = next_viewer_color
	art_texture = next_art_texture
	is_face_down = next_is_face_down
	_refresh_content()


func set_visual_state(is_playable: bool, is_selected: bool, is_multi_selected: bool) -> void:
	if not is_node_ready():
		call_deferred("set_visual_state", is_playable, is_selected, is_multi_selected)
		return
	var glow_color := Color(0, 0, 0, 0)
	if is_multi_selected:
		glow_color = Color("9fdd95")
	elif is_selected:
		glow_color = Color("ffd35f")
	elif is_playable:
		glow_color = Color("59c9ff")
	glow_rect.color = glow_color
	modulate = Color(1, 1, 1) if is_playable or is_selected or is_multi_selected else Color(0.72, 0.72, 0.76)
	state_badge.visible = is_playable and not is_face_down


func set_spotlight_active(is_active: bool) -> void:
	if not is_node_ready():
		call_deferred("set_spotlight_active", is_active)
		return
	scale = Vector2.ONE * (1.12 if is_active else 1.0)
	shadow_rect.color = Color(0, 0, 0, 0.3 if is_active else 0.18)
	z_index = 20 if is_active else 0


func get_card_center_global() -> Vector2:
	return global_position + (size * 0.5)


func get_card_instance_id() -> String:
	return str(card_state.get("instance_id", ""))


func _get_drag_data(_at_position: Vector2):
	return null


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if screen != null and not is_face_down:
			screen.on_card_widget_drag_started(self)


func _refresh_content() -> void:
	if not is_node_ready():
		return
	card_back_rect.texture = CARD_BACK_TEXTURE
	card_back_rect.visible = is_face_down
	art_rect.visible = not is_face_down
	mana_badge.visible = not is_face_down
	title_label.visible = not is_face_down
	type_label.visible = not is_face_down
	rules_label.visible = not is_face_down
	state_badge.visible = false

	if is_face_down:
		art_rect.texture = null
		tooltip_text = "Hidden card"
		return

	art_rect.texture = art_texture
	title_label.text = str(card_state.get("display_name", card_state.get("card_id", "Card")))
	type_label.text = "%s  %s" % [
		str(card_state.get("card_type", "")).capitalize(),
		str(card_state.get("school", "")).capitalize(),
	]
	rules_label.text = _trim_rules_text(str(card_state.get("rules_text", "")))
	mana_label.text = str(int(card_state.get("mana_cost", 0)))
	tooltip_text = screen._card_tooltip(card_state, "hand") if screen != null else title_label.text


func _trim_rules_text(rules_text: String) -> String:
	if rules_text.length() <= 68:
		return rules_text
	return rules_text.substr(0, 65) + "..."


func _on_mouse_entered() -> void:
	if screen != null and not is_face_down:
		screen.on_card_widget_hovered(self)


func _on_mouse_exited() -> void:
	if screen != null and not is_face_down:
		screen.on_card_widget_unhovered(self)
