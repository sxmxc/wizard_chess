extends Button
class_name WizardMatchBoardSquareButton

@export var square: Vector2i = Vector2i.ZERO

var screen: Control
var coordinate_label: Label


func _ready() -> void:
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	expand_icon = true
	clip_text = false
	_setup_coordinate_label()


func set_square_visuals(
	next_icon: Texture2D,
	next_tooltip: String,
	next_modulate: Color,
	coordinate_text: String
) -> void:
	icon = next_icon
	tooltip_text = next_tooltip
	modulate = next_modulate
	if coordinate_label != null:
		coordinate_label.text = coordinate_text


func _setup_coordinate_label() -> void:
	if coordinate_label != null:
		return
	coordinate_label = Label.new()
	coordinate_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coordinate_label.position = Vector2(4, 2)
	coordinate_label.size = Vector2(26, 16)
	coordinate_label.add_theme_font_size_override("font_size", 9)
	coordinate_label.add_theme_color_override("font_color", Color(0.88, 0.86, 0.78, 0.92))
	add_child(coordinate_label)


func _get_drag_data(_at_position: Vector2):
	if screen == null:
		return null
	return screen.get_square_drag_data(square)


func _can_drop_data(_at_position: Vector2, data) -> bool:
	return screen != null and screen.can_drop_on_square(square, data)


func _drop_data(_at_position: Vector2, data) -> void:
	if screen != null:
		screen.handle_square_drop(square, data)
