extends Control
class_name WizardMatchBoardView

signal square_pressed(square: Vector2i)
signal square_hovered(square: Vector2i)
signal square_unhovered(square: Vector2i)
signal square_dropped(square: Vector2i, data: Variant)

const INVALID_SQUARE := Vector2i(-1, -1)
const BOARD_EDGE := 8
const DRAG_THRESHOLD := 10.0

@export var light_square_color: Color = Color("f0dfb2")
@export var dark_square_color: Color = Color("7d5738")

var screen: Control
var hovered_square: Vector2i = INVALID_SQUARE
var square_visuals := {}
var square_buttons := {}
var visual_squares: Array[WizardMatchBoardSquare] = []
var piece_nodes := {}
var board_grid: GridContainer
var viewer_color: String = ChessEngine.WHITE
var pointer_down_square: Vector2i = INVALID_SQUARE
var pointer_down_position: Vector2 = Vector2.ZERO
var is_pointer_down: bool = false
var drag_started_for_press: bool = false


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_cache_scene_nodes()
	resized.connect(_layout_board)
	_layout_board()


func set_square_visual(square: Vector2i, icon: Texture2D, fill_color: Color, tooltip: String, show_coordinates: bool) -> void:
	_ensure_square_cache()
	square_visuals[square] = {
		"icon": icon,
		"fill_color": fill_color,
		"tooltip": tooltip,
		"show_coordinates": show_coordinates,
	}
	var button := _square_node(square)
	if button != null:
		button.set_square_visuals(
			icon,
			_square_overlay_color(square, fill_color),
			_square_name(square) if show_coordinates else "",
			tooltip
		)
	if icon == null:
		piece_nodes.erase(square)
	else:
		piece_nodes[square] = button


func set_square_target_emphasis(square: Vector2i, is_target: bool, is_hovered_target: bool) -> void:
	_ensure_square_cache()
	if not square_buttons.has(square):
		return
	var button := _square_node(square)
	if button == null:
		return
	button.set_target_emphasis(is_target, is_hovered_target)


func get_square_center_global(square: Vector2i) -> Vector2:
	_ensure_square_cache()
	return _fallback_square_center_global(square)


func square_at_global_position(next_global_position: Vector2) -> Vector2i:
	_ensure_square_cache()
	return _square_at_position(get_global_transform_with_canvas().affine_inverse() * next_global_position)


func get_square_rect(square: Vector2i) -> Rect2:
	_ensure_square_cache()
	return _fallback_square_rect_local(square)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover_square(_square_at_position(event.position))
		if is_pointer_down and not drag_started_for_press and pointer_down_square != INVALID_SQUARE and pointer_down_position.distance_to(event.position) >= DRAG_THRESHOLD:
			if piece_nodes.has(pointer_down_square) and screen != null and screen.has_method("on_board_piece_drag_started"):
				drag_started_for_press = true
				screen.on_board_piece_drag_started(pointer_down_square, get_global_mouse_position())
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var square := _square_at_position(event.position)
		if square != INVALID_SQUARE:
			pointer_down_square = square
			pointer_down_position = event.position
			is_pointer_down = true
			drag_started_for_press = false
			square_pressed.emit(square)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_pointer_down = false
		drag_started_for_press = false
		pointer_down_square = INVALID_SQUARE


func _get_drag_data(_at_position: Vector2):
	return null


func _can_drop_data(local_drop_position: Vector2, data) -> bool:
	var square := _square_at_position(local_drop_position)
	_update_hover_square(square)
	return square != INVALID_SQUARE and screen != null and screen.can_drop_on_square(square, data)


func _drop_data(local_drop_position: Vector2, data) -> void:
	var square := _square_at_position(local_drop_position)
	_update_hover_square(square)
	if square == INVALID_SQUARE:
		return
	square_dropped.emit(square, data)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and hovered_square != INVALID_SQUARE:
		var previous := hovered_square
		hovered_square = INVALID_SQUARE
		square_unhovered.emit(previous)
	elif what == NOTIFICATION_MOUSE_EXIT:
		is_pointer_down = false
		drag_started_for_press = false
		pointer_down_square = INVALID_SQUARE


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


func _square_at_position(local_position: Vector2) -> Vector2i:
	return _fallback_square_at_position(local_position)


func get_square_buttons() -> Dictionary:
	_ensure_square_cache()
	return square_buttons.duplicate()


func get_piece_nodes() -> Dictionary:
	_ensure_square_cache()
	return piece_nodes.duplicate()


func _cache_scene_nodes() -> void:
	board_grid = get_node("BoardFrame/BoardSurface/SquareGrid") as GridContainer
	visual_squares.clear()
	for child in board_grid.get_children():
		var square_node := child as WizardMatchBoardSquare
		if square_node == null:
			continue
		visual_squares.append(square_node)
	_rebuild_square_map()


func set_screen(next_screen: Control) -> void:
	screen = next_screen


func set_viewer_color(color: String) -> void:
	_ensure_square_cache()
	var next_color := color if color == ChessEngine.BLACK else ChessEngine.WHITE
	if viewer_color == next_color and not square_buttons.is_empty():
		return
	viewer_color = next_color
	_rebuild_square_map()
	if is_node_ready():
		_apply_cached_visuals()


func _layout_board() -> void:
	if board_grid == null:
		return
	_apply_cached_visuals()


func _rebuild_square_map() -> void:
	square_buttons.clear()
	for index in range(visual_squares.size()):
		var visual_square := Vector2i(index % BOARD_EDGE, index / BOARD_EDGE)
		var logical_square := _visual_to_logical(visual_square)
		var square_node := visual_squares[index]
		square_node.square = logical_square
		square_buttons[logical_square] = square_node


func _logical_to_visual(square: Vector2i) -> Vector2i:
	if viewer_color != ChessEngine.BLACK:
		return square
	return Vector2i(BOARD_EDGE - 1 - square.x, BOARD_EDGE - 1 - square.y)


func _visual_to_logical(square: Vector2i) -> Vector2i:
	if viewer_color != ChessEngine.BLACK:
		return square
	return Vector2i(BOARD_EDGE - 1 - square.x, BOARD_EDGE - 1 - square.y)


func _square_name(square: Vector2i) -> String:
	return "%s%d" % [char(97 + square.x), 8 - square.y]


func _square_overlay_color(square: Vector2i, fill_color: Color) -> Color:
	var base_color := light_square_color if (square.x + square.y) % 2 == 0 else dark_square_color
	if _colors_match(base_color, fill_color):
		return Color(1, 1, 1, 0)
	return Color(fill_color.r, fill_color.g, fill_color.b, 0.68)


func _colors_match(a: Color, b: Color, epsilon: float = 0.015) -> bool:
	return absf(a.r - b.r) <= epsilon and absf(a.g - b.g) <= epsilon and absf(a.b - b.b) <= epsilon


func _apply_cached_visuals() -> void:
	for square in square_buttons.keys():
		var button: WizardMatchBoardSquare = square_buttons[square]
		if button == null:
			continue
		button.square = square
		if square_visuals.has(square):
			var visual: Dictionary = square_visuals[square]
			button.set_square_visuals(
				visual["icon"],
				_square_overlay_color(square, visual["fill_color"]),
				_square_name(square) if visual["show_coordinates"] else "",
				str(visual["tooltip"])
			)
		else:
			button.set_square_visuals(null, Color(1, 1, 1, 0), "", "")


func _square_node(square: Vector2i) -> WizardMatchBoardSquare:
	if square.x < 0 or square.x >= BOARD_EDGE or square.y < 0 or square.y >= BOARD_EDGE:
		return null
	var visual_square := _logical_to_visual(square)
	var index := visual_square.y * BOARD_EDGE + visual_square.x
	if index < 0 or index >= visual_squares.size():
		return null
	return visual_squares[index]


func _ensure_square_cache() -> void:
	if board_grid == null and has_node("BoardFrame/BoardSurface/SquareGrid"):
		board_grid = get_node("BoardFrame/BoardSurface/SquareGrid") as GridContainer
	if not visual_squares.is_empty():
		return
	if board_grid == null:
		return
	_cache_scene_nodes()


func _fallback_square_center_global(square: Vector2i) -> Vector2:
	var local_rect := _fallback_square_rect_local(square)
	return get_global_transform_with_canvas() * local_rect.get_center()


func _fallback_square_rect_local(square: Vector2i) -> Rect2:
	var visual_square := _logical_to_visual(square)
	var cell_size := _fallback_cell_size()
	var grid_origin := board_grid.position
	var h_separation := float(board_grid.get_theme_constant("h_separation"))
	var v_separation := float(board_grid.get_theme_constant("v_separation"))
	var local_position := grid_origin + Vector2(
		visual_square.x * (cell_size.x + h_separation),
		visual_square.y * (cell_size.y + v_separation)
	)
	return Rect2(local_position, cell_size)


func _fallback_square_at_position(local_position: Vector2) -> Vector2i:
	var cell_size := _fallback_cell_size()
	var grid_local := local_position - board_grid.position
	if grid_local.x < 0.0 or grid_local.y < 0.0:
		return INVALID_SQUARE
	var h_separation := float(board_grid.get_theme_constant("h_separation"))
	var v_separation := float(board_grid.get_theme_constant("v_separation"))
	var stride_x := cell_size.x + h_separation
	var stride_y := cell_size.y + v_separation
	if stride_x <= 0.0 or stride_y <= 0.0:
		return INVALID_SQUARE
	var visual_file := int(floor(grid_local.x / stride_x))
	var visual_rank := int(floor(grid_local.y / stride_y))
	if visual_file < 0 or visual_file >= BOARD_EDGE or visual_rank < 0 or visual_rank >= BOARD_EDGE:
		return INVALID_SQUARE
	return _visual_to_logical(Vector2i(visual_file, visual_rank))


func _fallback_cell_size() -> Vector2:
	if visual_squares.is_empty() or visual_squares[0] == null:
		return Vector2.ZERO
	var square_node := visual_squares[0]
	return square_node.custom_minimum_size if not square_node.custom_minimum_size.is_zero_approx() else Vector2(92, 92)
