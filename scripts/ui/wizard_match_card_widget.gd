extends Control
class_name WizardMatchCardWidget

signal pressed

const CARD_BACK_TEXTURE := preload("res://assets/ui/wizard_match/card_back.png")
const RARITY_ICONS_TEXTURE := preload("res://assets/ui/wizard_match/card_front/rarity_icons.png")
const DRAG_THRESHOLD := 14.0
const HOVER_SCALE := 1.34
const HOVER_Z_INDEX := 720

var screen: Control
var card_state: Dictionary = {}
var art_texture: Texture2D
var viewer_color: String = ""
var is_face_down: bool = false
var is_pointer_down: bool = false
var is_dragging: bool = false
var pointer_down_global: Vector2 = Vector2.ZERO

@onready var glow_rect: ColorRect = %GlowRect
@onready var shadow_rect: ColorRect = %ShadowRect
@onready var card_back_rect: TextureRect = %CardBackRect
@onready var card_face_root: Control = %CardFaceRoot
@onready var art_rect: TextureRect = %ArtRect
@onready var mana_pip_rect: TextureRect = %ManaPipRect
@onready var rarity_icon_rect: TextureRect = %RarityIconRect
@onready var title_label: Label = %TitleLabel
@onready var type_label: Label = %TypeLabel
@onready var rules_label: Label = %RulesLabel
@onready var mana_label: Label = %ManaLabel
@onready var state_badge: Label = %StateBadge


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	offset_transform_enabled = true
	offset_transform_visual_only = true
	offset_transform_pivot_ratio = Vector2(0.5, 1.0)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_apply_mouse_passthrough(self)
	_refresh_content()


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
	offset_transform_position = Vector2(0.0, -80.0 if is_active else 0.0)
	offset_transform_scale = Vector2.ONE * (HOVER_SCALE if is_active else 1.0)
	shadow_rect.color = Color(0, 0, 0, 0.3 if is_active else 0.18)
	z_index = HOVER_Z_INDEX if is_active else int(get_meta("fan_z_index", 0))


func get_card_center_global() -> Vector2:
	return get_global_transform_with_canvas() * (size * 0.5)


func get_card_instance_id() -> String:
	return str(card_state.get("instance_id", ""))


func cancel_pointer_interaction() -> void:
	is_pointer_down = false
	is_dragging = false


func _get_drag_data(_at_position: Vector2):
	return null


func _gui_input(event: InputEvent) -> void:
	if is_face_down or screen == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_pointer_down = true
			is_dragging = false
			pointer_down_global = get_global_mouse_position()
		else:
			if is_pointer_down and not is_dragging:
				pressed.emit()
			is_pointer_down = false
			is_dragging = false
	elif event is InputEventMouseMotion and is_pointer_down:
		var current_global := get_global_mouse_position()
		if not is_dragging and pointer_down_global.distance_to(current_global) >= DRAG_THRESHOLD:
			is_dragging = true
			screen.on_card_widget_drag_started(self, current_global)


func _refresh_content() -> void:
	if not is_node_ready():
		call_deferred("_refresh_content")
		return
	card_back_rect.texture = CARD_BACK_TEXTURE
	card_back_rect.visible = is_face_down
	card_face_root.visible = not is_face_down
	state_badge.visible = false

	if is_face_down:
		art_rect.texture = null
		tooltip_text = "Hidden card"
		return

	art_rect.texture = art_texture
	rarity_icon_rect.texture = _rarity_icon_texture(str(card_state.get("rarity", CardDefinition.RARITY_COMMON)))
	title_label.text = str(card_state.get("display_name", card_state.get("card_id", "Card")))
	type_label.text = "%s  %s" % [
		str(card_state.get("card_type", "")).capitalize(),
		str(card_state.get("school", "")).capitalize(),
	]
	rules_label.text = _trim_rules_text(str(card_state.get("rules_text", "")))
	mana_label.text = str(int(card_state.get("mana_cost", 0)))
	tooltip_text = screen._card_tooltip(card_state, "hand") if screen != null else title_label.text


func _rarity_icon_texture(rarity: String) -> AtlasTexture:
	var index := 0
	match rarity:
		CardDefinition.RARITY_UNCOMMON:
			index = 1
		CardDefinition.RARITY_RARE:
			index = 2
		CardDefinition.RARITY_LEGENDARY:
			index = 3
	var atlas := AtlasTexture.new()
	atlas.atlas = RARITY_ICONS_TEXTURE
	var icon_width := int(float(RARITY_ICONS_TEXTURE.get_width()) / 4.0)
	atlas.region = Rect2(index * icon_width, 0, icon_width, RARITY_ICONS_TEXTURE.get_height())
	return atlas


func _trim_rules_text(rules_text: String) -> String:
	if rules_text.length() <= 68:
		return rules_text
	return rules_text.substr(0, 65) + "..."


func _apply_mouse_passthrough(root: Node) -> void:
	for child in root.get_children():
		var control := child as Control
		if control != null:
			control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_mouse_passthrough(child)


func _on_mouse_entered() -> void:
	if screen != null and not is_face_down:
		screen.on_card_widget_hovered(self)


func _on_mouse_exited() -> void:
	if screen != null and not is_face_down:
		screen.on_card_widget_unhovered(self)
