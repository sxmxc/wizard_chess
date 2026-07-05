extends Button
class_name WizardMatchBoardSquareButton

@export var square: Vector2i = Vector2i.ZERO

var screen: Control
var background_rect: ColorRect
var coordinate_label: Label
var target_indicator: Label


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clip_text = false
	text = ""
	_setup_visual_children()


func set_square_visuals(
	_next_icon: Texture2D,
	next_tooltip: String,
	next_fill_color: Color,
	coordinate_text: String
) -> void:
	tooltip_text = next_tooltip
	background_rect.color = next_fill_color
	if coordinate_label != null:
		coordinate_label.text = coordinate_text


func set_target_emphasis(is_target: bool, is_hovered_target: bool) -> void:
	if target_indicator == null:
		return
	target_indicator.visible = is_target
	target_indicator.text = "◆" if is_hovered_target else "•"
	target_indicator.add_theme_color_override(
		"font_color",
		Color(0.75, 0.98, 1.0, 1.0) if is_hovered_target else Color(0.08, 0.28, 0.38, 0.62)
	)


func _setup_visual_children() -> void:
	if background_rect != null:
		return
	background_rect = ColorRect.new()
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background_rect)

	coordinate_label = Label.new()
	coordinate_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coordinate_label.position = Vector2(4, 2)
	coordinate_label.size = Vector2(26, 16)
	coordinate_label.add_theme_font_size_override("font_size", 9)
	coordinate_label.add_theme_color_override("font_color", Color(0.35, 0.27, 0.17, 0.9))
	add_child(coordinate_label)

	target_indicator = Label.new()
	target_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target_indicator.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	target_indicator.position = Vector2(-23, 2)
	target_indicator.size = Vector2(20, 20)
	target_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	target_indicator.add_theme_font_size_override("font_size", 15)
	target_indicator.add_theme_constant_override("outline_size", 2)
	target_indicator.add_theme_color_override("font_outline_color", Color(0.02, 0.06, 0.1, 0.72))
	target_indicator.visible = false
	add_child(target_indicator)


func _get_drag_data(_at_position: Vector2):
	if screen == null:
		return null
	return screen.get_square_drag_data(square)


func _can_drop_data(_at_position: Vector2, data) -> bool:
	return screen != null and screen.can_drop_on_square(square, data)


func _drop_data(_at_position: Vector2, data) -> void:
	if screen != null:
		screen.handle_square_drop(square, data)
