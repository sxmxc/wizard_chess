extends Control
class_name WizardMatchBoardPiece

signal piece_pressed(square: Vector2i)
signal piece_drag_started(square: Vector2i, cursor_global: Vector2)
signal piece_hovered(square: Vector2i)
signal piece_unhovered(square: Vector2i)

const DRAG_THRESHOLD := 10.0

var square: Vector2i = Vector2i.ZERO
var screen: Control
var is_pointer_down: bool = false
var is_dragging: bool = false
var pointer_down_global: Vector2 = Vector2.ZERO
var piece_rect: TextureRect


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_filter = Control.MOUSE_FILTER_STOP
	_setup_visuals()


func configure(next_square: Vector2i, icon: Texture2D, tooltip: String) -> void:
	square = next_square
	tooltip_text = tooltip
	if piece_rect == null:
		_setup_visuals()
	piece_rect.texture = icon
	visible = icon != null


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_pointer_down = true
			is_dragging = false
			pointer_down_global = get_global_mouse_position()
		else:
			if is_pointer_down and not is_dragging:
				piece_pressed.emit(square)
			is_pointer_down = false
			is_dragging = false
	elif event is InputEventMouseMotion and is_pointer_down:
		var current_global := get_global_mouse_position()
		if not is_dragging and pointer_down_global.distance_to(current_global) >= DRAG_THRESHOLD:
			is_dragging = true
			piece_drag_started.emit(square, current_global)


func _can_drop_data(_at_position: Vector2, data) -> bool:
	return screen != null and screen.can_drop_on_square(square, data)


func _drop_data(_at_position: Vector2, data) -> void:
	if screen != null:
		screen.handle_square_drop(square, data)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		piece_hovered.emit(square)
	elif what == NOTIFICATION_MOUSE_EXIT:
		piece_unhovered.emit(square)


func _setup_visuals() -> void:
	if piece_rect != null:
		return
	piece_rect = TextureRect.new()
	piece_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	piece_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	piece_rect.offset_left = 3.0
	piece_rect.offset_top = 3.0
	piece_rect.offset_right = -3.0
	piece_rect.offset_bottom = -3.0
	piece_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	piece_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(piece_rect)
