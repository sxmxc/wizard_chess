extends Control
class_name WizardMatchBoardView

signal square_pressed(square: Vector2i)
signal square_hovered(square: Vector2i)
signal square_unhovered(square: Vector2i)
signal square_dropped(square: Vector2i, data: Variant)

const INVALID_SQUARE := Vector2i(-1, -1)

@export var board_padding: float = 8.0
@export var light_square_color: Color = Color("e7d7b1")
@export var dark_square_color: Color = Color("9f7b55")
@export var coordinate_color: Color = Color(0.35, 0.27, 0.17, 0.9)

var screen: Control
var hovered_square: Vector2i = INVALID_SQUARE
var square_visuals := {}


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func set_square_visual(square: Vector2i, icon: Texture2D, fill_color: Color, tooltip: String, show_coordinates: bool) -> void:
	square_visuals[square] = {
		"icon": icon,
		"fill_color": fill_color,
		"tooltip": tooltip,
		"show_coordinates": show_coordinates,
	}
	queue_redraw()


func get_square_center_global(square: Vector2i) -> Vector2:
	return global_position + get_square_rect(square).get_center()


func square_at_global_position(next_global_position: Vector2) -> Vector2i:
	return _square_at_position(get_global_transform_with_canvas().affine_inverse() * next_global_position)


func get_square_rect(square: Vector2i) -> Rect2:
	var board_rect := _board_rect()
	var cell_size := board_rect.size.x / 8.0
	return Rect2(
		board_rect.position + Vector2(square.x * cell_size, square.y * cell_size),
		Vector2(cell_size, cell_size)
	)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover_square(_square_at_position(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var square := _square_at_position(event.position)
		if square != INVALID_SQUARE:
			square_pressed.emit(square)


func _get_drag_data(at_position: Vector2):
	return null


func _can_drop_data(at_position: Vector2, data) -> bool:
	var square := _square_at_position(at_position)
	return square != INVALID_SQUARE and screen != null and screen.can_drop_on_square(square, data)


func _drop_data(at_position: Vector2, data) -> void:
	var square := _square_at_position(at_position)
	if square == INVALID_SQUARE:
		return
	square_dropped.emit(square, data)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and hovered_square != INVALID_SQUARE:
		var previous := hovered_square
		hovered_square = INVALID_SQUARE
		square_unhovered.emit(previous)


func _draw() -> void:
	var board_rect := _board_rect()
	var cell_size := board_rect.size.x / 8.0
	draw_rect(board_rect.grow(4.0), Color(0.08, 0.07, 0.06, 0.95), false, 8.0)

	for rank in range(8):
		for file in range(8):
			var square := Vector2i(file, rank)
			var rect := Rect2(board_rect.position + Vector2(file * cell_size, rank * cell_size), Vector2(cell_size, cell_size))
			var fill_color := light_square_color if (file + rank) % 2 == 0 else dark_square_color
			if square_visuals.has(square):
				fill_color = square_visuals[square]["fill_color"]
			draw_rect(rect, fill_color)
			draw_rect(rect, Color(0, 0, 0, 0.15), false, 1.0)

			if square_visuals.has(square) and square_visuals[square]["show_coordinates"]:
				draw_string(
					ThemeDB.fallback_font,
					rect.position + Vector2(4.0, 12.0),
					_square_name(square),
					HORIZONTAL_ALIGNMENT_LEFT,
					-1.0,
					10,
					coordinate_color
				)

			if square_visuals.has(square):
				var icon: Texture2D = square_visuals[square]["icon"]
				if icon != null:
					var inset := cell_size * 0.12
					draw_texture_rect(icon, rect.grow_individual(-inset, -inset, -inset, -inset), false)


func _update_hover_square(square: Vector2i) -> void:
	if square == hovered_square:
		return
	var previous := hovered_square
	hovered_square = square
	if previous != INVALID_SQUARE:
		square_unhovered.emit(previous)
	if hovered_square != INVALID_SQUARE:
		if square_visuals.has(hovered_square):
			tooltip_text = str(square_visuals[hovered_square]["tooltip"])
		square_hovered.emit(hovered_square)
	else:
		tooltip_text = ""


func _square_at_position(position: Vector2) -> Vector2i:
	var board_rect := _board_rect()
	if not board_rect.has_point(position):
		return INVALID_SQUARE
	var cell_size := board_rect.size.x / 8.0
	var local := position - board_rect.position
	return Vector2i(int(local.x / cell_size), int(local.y / cell_size))


func _board_rect() -> Rect2:
	var edge: float = min(size.x, size.y) - board_padding * 2.0
	var board_size := Vector2(edge, edge)
	return Rect2((size - board_size) * 0.5, board_size)


func _square_name(square: Vector2i) -> String:
	return "%s%d" % [char(97 + square.x), 8 - square.y]
