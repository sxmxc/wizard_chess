extends Control
class_name WizardMatchBoardView

signal square_pressed(square: Vector2i)
signal square_hovered(square: Vector2i)
signal square_unhovered(square: Vector2i)
signal square_dropped(square: Vector2i, data: Variant)

const INVALID_SQUARE := Vector2i(-1, -1)
const BOARD_EDGE := 8

@export var board_padding: float = 8.0
@export var square_gap: float = 0.0
@export var light_square_color: Color = Color("e7d7b1")
@export var dark_square_color: Color = Color("9f7b55")
@export var board_frame_color: Color = Color(0.08, 0.07, 0.06, 0.95)

var screen: Control
var hovered_square: Vector2i = INVALID_SQUARE
var square_visuals := {}
var square_buttons := {}
var visual_buttons := {}
var piece_nodes := {}
var board_container: Control
var board_grid: GridContainer
var piece_layer: Control
var viewer_color: String = ChessEngine.WHITE


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_build_board_nodes()
	resized.connect(_layout_board)
	_layout_board()


func set_square_visual(square: Vector2i, icon: Texture2D, fill_color: Color, tooltip: String, show_coordinates: bool) -> void:
	square_visuals[square] = {
		"icon": icon,
		"fill_color": fill_color,
		"tooltip": tooltip,
		"show_coordinates": show_coordinates,
	}
	if square_buttons.has(square):
		var button: WizardMatchBoardSquareButton = square_buttons[square]
		button.set_square_visuals(icon, tooltip, fill_color, _square_name(square) if show_coordinates else "")
	if icon == null:
		if piece_nodes.has(square):
			var existing_piece: WizardMatchBoardPiece = piece_nodes[square]
			existing_piece.visible = false
	else:
		var piece := _ensure_piece_node(square)
		piece.configure(square, icon, tooltip)
		piece.position = get_square_rect(square).position
		piece.size = get_square_rect(square).size


func set_square_target_emphasis(square: Vector2i, is_target: bool, is_hovered_target: bool) -> void:
	if not square_buttons.has(square):
		return
	var button: WizardMatchBoardSquareButton = square_buttons[square]
	button.set_target_emphasis(is_target, is_hovered_target)


func get_square_center_global(square: Vector2i) -> Vector2:
	return global_position + get_square_rect(square).get_center()


func square_at_global_position(next_global_position: Vector2) -> Vector2i:
	return _square_at_position(get_global_transform_with_canvas().affine_inverse() * next_global_position)


func get_square_rect(square: Vector2i) -> Rect2:
	var board_rect := _board_rect()
	var cell_size := _cell_size(board_rect)
	var visual_square := _logical_to_visual(square)
	return Rect2(
		board_rect.position + Vector2(visual_square.x * (cell_size + square_gap), visual_square.y * (cell_size + square_gap)),
		Vector2(cell_size, cell_size)
	)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover_square(_square_at_position(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var square := _square_at_position(event.position)
		if square != INVALID_SQUARE:
			square_pressed.emit(square)


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
	var board_rect := _board_rect()
	if not board_rect.has_point(local_position):
		return INVALID_SQUARE
	var cell_size := _cell_size(board_rect)
	var local := local_position - board_rect.position
	var step := cell_size + square_gap
	var visual_square := Vector2i(
		clampi(int(local.x / step), 0, BOARD_EDGE - 1),
		clampi(int(local.y / step), 0, BOARD_EDGE - 1)
	)
	return _visual_to_logical(visual_square)


func _board_rect() -> Rect2:
	var edge: float = min(size.x, size.y) - board_padding * 2.0
	var board_size := Vector2(edge, edge)
	return Rect2((size - board_size) * 0.5, board_size)


func get_square_buttons() -> Dictionary:
	return square_buttons.duplicate()


func get_piece_nodes() -> Dictionary:
	return piece_nodes.duplicate()


func _build_board_nodes() -> void:
	if board_container != null:
		return
	board_container = Control.new()
	board_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(board_container)

	board_grid = GridContainer.new()
	board_grid.columns = BOARD_EDGE
	board_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_container.add_child(board_grid)

	piece_layer = Control.new()
	piece_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_container.add_child(piece_layer)

	for rank in range(BOARD_EDGE):
		for file in range(BOARD_EDGE):
			var visual_square := Vector2i(file, rank)
			var button := WizardMatchBoardSquareButton.new()
			button.square = _visual_to_logical(visual_square)
			button.screen = screen
			button.pressed.connect(func(next_button := button) -> void:
				square_pressed.emit(next_button.square)
			)
			button.mouse_entered.connect(func(next_button := button) -> void:
				_update_hover_square(next_button.square)
			)
			button.mouse_exited.connect(func(next_button := button) -> void:
				if hovered_square == next_button.square:
					_update_hover_square(INVALID_SQUARE)
			)
			board_grid.add_child(button)
			visual_buttons[visual_square] = button
	_rebuild_square_button_map()


func set_screen(next_screen: Control) -> void:
	screen = next_screen
	for button_value in visual_buttons.values():
		var button: WizardMatchBoardSquareButton = button_value
		button.screen = next_screen
	for piece_value in piece_nodes.values():
		var piece: WizardMatchBoardPiece = piece_value
		piece.screen = next_screen


func set_viewer_color(color: String) -> void:
	var next_color := color if color == ChessEngine.BLACK else ChessEngine.WHITE
	if viewer_color == next_color and not square_buttons.is_empty():
		return
	viewer_color = next_color
	_rebuild_square_button_map()
	if is_node_ready():
		_layout_board()


func _layout_board() -> void:
	if board_container == null or board_grid == null:
		return
	var board_rect := _board_rect()
	var cell_size := _cell_size(board_rect)
	board_container.position = board_rect.position
	board_container.size = board_rect.size
	board_grid.position = Vector2.ZERO
	board_grid.size = board_rect.size
	for visual_square in visual_buttons.keys():
		var button: WizardMatchBoardSquareButton = visual_buttons[visual_square]
		var logical_square := _visual_to_logical(visual_square)
		button.square = logical_square
		button.custom_minimum_size = Vector2(cell_size, cell_size)
		button.size = Vector2(cell_size, cell_size)
		if square_visuals.has(logical_square):
			var visual: Dictionary = square_visuals[logical_square]
			button.set_square_visuals(
				visual["icon"],
				visual["tooltip"],
				visual["fill_color"],
				_square_name(logical_square) if visual["show_coordinates"] else ""
			)
		var piece_node := piece_nodes.get(logical_square) as WizardMatchBoardPiece
		if piece_node != null:
			piece_node.position = get_square_rect(logical_square).position
			piece_node.size = Vector2(cell_size, cell_size)


func _cell_size(board_rect: Rect2) -> float:
	return (board_rect.size.x - square_gap * float(BOARD_EDGE - 1)) / float(BOARD_EDGE)


func _ensure_piece_node(square: Vector2i) -> WizardMatchBoardPiece:
	if piece_nodes.has(square):
		return piece_nodes[square]
	var piece := WizardMatchBoardPiece.new()
	piece.screen = screen
	piece.piece_pressed.connect(func(next_square: Vector2i) -> void:
		square_pressed.emit(next_square)
	)
	piece.piece_drag_started.connect(func(next_square: Vector2i, cursor_global: Vector2) -> void:
		if screen != null and screen.has_method("on_board_piece_drag_started"):
			screen.on_board_piece_drag_started(next_square, cursor_global)
	)
	piece.piece_hovered.connect(func(next_square: Vector2i) -> void:
		_update_hover_square(next_square)
	)
	piece.piece_unhovered.connect(func(next_square: Vector2i) -> void:
		if hovered_square == next_square:
			_update_hover_square(INVALID_SQUARE)
	)
	piece_layer.add_child(piece)
	piece_nodes[square] = piece
	return piece


func _rebuild_square_button_map() -> void:
	square_buttons.clear()
	for rank in range(BOARD_EDGE):
		for file in range(BOARD_EDGE):
			var logical_square := Vector2i(file, rank)
			square_buttons[logical_square] = visual_buttons.get(_logical_to_visual(logical_square))


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
