extends Control

const LIGHT_SQUARE := Color("e7d7b1")
const DARK_SQUARE := Color("9f7b55")
const SELECTED_SQUARE := Color("7fc97f")
const LEGAL_SQUARE := Color("f6d365")

var chess_match: ChessMatch
var selected_square = null
var selected_moves: Array = []
var pending_promotion_moves: Array = []
var board_buttons := {}

var status_label: Label
var detail_label: Label
var claim_draw_button: Button
var history_list: ItemList
var promotion_bar: HBoxContainer


func _ready() -> void:
	chess_match = ChessMatch.new()
	_build_ui()
	_refresh_ui()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 20)
	margin.add_child(root)

	var board_column := VBoxContainer.new()
	board_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(board_column)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 22)
	board_column.add_child(status_label)

	detail_label = Label.new()
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	board_column.add_child(detail_label)

	promotion_bar = HBoxContainer.new()
	promotion_bar.visible = false
	promotion_bar.add_theme_constant_override("separation", 8)
	board_column.add_child(promotion_bar)

	var board_grid := GridContainer.new()
	board_grid.columns = 8
	board_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_grid.add_theme_constant_override("h_separation", 2)
	board_grid.add_theme_constant_override("v_separation", 2)
	board_column.add_child(board_grid)

	for rank in range(8):
		for file in range(8):
			var square := Vector2i(file, rank)
			var button := Button.new()
			button.custom_minimum_size = Vector2(88, 88)
			button.clip_text = true
			button.pressed.connect(_on_board_square_pressed.bind(square))
			board_grid.add_child(button)
			board_buttons[square] = button

	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size = Vector2(320, 0)
	sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_theme_constant_override("separation", 10)
	root.add_child(sidebar)

	var reset_button := Button.new()
	reset_button.text = "New Match"
	reset_button.pressed.connect(_on_reset_pressed)
	sidebar.add_child(reset_button)

	claim_draw_button = Button.new()
	claim_draw_button.text = "Claim Draw"
	claim_draw_button.disabled = true
	claim_draw_button.pressed.connect(_on_claim_draw_pressed)
	sidebar.add_child(claim_draw_button)

	var history_title := Label.new()
	history_title.text = "Move History"
	history_title.add_theme_font_size_override("font_size", 18)
	sidebar.add_child(history_title)

	history_list = ItemList.new()
	history_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(history_list)


func _refresh_ui() -> void:
	_refresh_status()
	_refresh_board()
	_refresh_history()
	_refresh_claim_button()


func _refresh_status() -> void:
	var outcome = chess_match.outcome
	if outcome["status"] == ChessMatch.STATUS_ACTIVE:
		status_label.text = "Turn %d: %s to move" % [
			chess_match.fullmove_number,
			_match_color_name(chess_match.active_color),
		]
		if chess_match.is_in_check(chess_match.active_color):
			status_label.text += " (check)"
	else:
		status_label.text = _outcome_text()

	if pending_promotion_moves.is_empty():
		detail_label.text = "Select a piece, then select a legal destination."
	else:
		detail_label.text = "Choose a promotion piece to complete the move."


func _refresh_board() -> void:
	for square in board_buttons.keys():
		var button: Button = board_buttons[square]
		button.text = _square_text(square)
		button.modulate = _square_color(square)


func _refresh_history() -> void:
	history_list.clear()
	for entry in chess_match.move_history:
		var prefix := "%d." % entry["turn_number"] if entry["color"] == ChessMatch.WHITE else "%d..." % entry["turn_number"]
		history_list.add_item("%s %s" % [prefix, entry["notation"]])


func _refresh_claim_button() -> void:
	var reason := chess_match.claimable_draw_reason
	claim_draw_button.disabled = reason.is_empty() or chess_match.outcome["status"] != ChessMatch.STATUS_ACTIVE
	if reason == ChessMatch.DRAW_THREEFOLD_REPETITION:
		claim_draw_button.text = "Claim Draw (Threefold)"
	elif reason == ChessMatch.DRAW_FIFTY_MOVE_RULE:
		claim_draw_button.text = "Claim Draw (50-Move)"
	else:
		claim_draw_button.text = "Claim Draw"


func _square_text(square: Vector2i) -> String:
	var piece = chess_match.get_piece(square)
	if piece == null:
		return ""
	return "%s\n%s" % [_piece_label(piece), chess_match.square_to_algebraic(square)]


func _piece_label(piece: Dictionary) -> String:
	var color_prefix := "W" if piece["color"] == ChessMatch.WHITE else "B"
	var piece_letter := ""
	match piece["type"]:
		ChessMatch.PIECE_PAWN:
			piece_letter = "P"
		ChessMatch.PIECE_KNIGHT:
			piece_letter = "N"
		ChessMatch.PIECE_BISHOP:
			piece_letter = "B"
		ChessMatch.PIECE_ROOK:
			piece_letter = "R"
		ChessMatch.PIECE_QUEEN:
			piece_letter = "Q"
		ChessMatch.PIECE_KING:
			piece_letter = "K"
	return "%s%s" % [color_prefix, piece_letter]


func _square_color(square: Vector2i) -> Color:
	if selected_square != null and square == selected_square:
		return SELECTED_SQUARE
	for move in selected_moves:
		if move["to"] == square:
			return LEGAL_SQUARE
	return LIGHT_SQUARE if (square.x + square.y) % 2 == 0 else DARK_SQUARE


func _on_board_square_pressed(square: Vector2i) -> void:
	if not pending_promotion_moves.is_empty():
		return
	if chess_match.outcome["status"] != ChessMatch.STATUS_ACTIVE:
		return

	for move in selected_moves:
		if move["to"] != square:
			continue
		var destination_moves := _moves_to_square(square)
		if destination_moves.size() == 1:
			_commit_move(destination_moves[0])
		else:
			_show_promotion_choices(destination_moves)
		return

	var piece = chess_match.get_piece(square)
	if piece != null and piece["color"] == chess_match.active_color:
		selected_square = square
		selected_moves = chess_match.get_legal_moves_from(square)
	else:
		_clear_selection()

	_refresh_ui()


func _moves_to_square(square: Vector2i) -> Array:
	var destination_moves: Array = []
	for move in selected_moves:
		if move["to"] == square:
			destination_moves.append(move)
	return destination_moves


func _show_promotion_choices(moves: Array) -> void:
	pending_promotion_moves = moves
	promotion_bar.visible = true
	for child in promotion_bar.get_children():
		child.queue_free()

	for move in moves:
		var button := Button.new()
		button.text = move["promotion"].capitalize()
		button.pressed.connect(_on_promotion_selected.bind(move))
		promotion_bar.add_child(button)

	_refresh_status()


func _on_promotion_selected(move: Dictionary) -> void:
	_commit_move(move)


func _commit_move(move: Dictionary) -> void:
	chess_match.apply_move(move)
	_clear_selection()
	_refresh_ui()


func _clear_selection() -> void:
	selected_square = null
	selected_moves.clear()
	pending_promotion_moves.clear()
	promotion_bar.visible = false


func _on_claim_draw_pressed() -> void:
	chess_match.claim_draw()
	_clear_selection()
	_refresh_ui()


func _on_reset_pressed() -> void:
	chess_match.reset()
	_clear_selection()
	_refresh_ui()


func _outcome_text() -> String:
	var outcome = chess_match.outcome
	match outcome["status"]:
		ChessMatch.STATUS_CHECKMATE:
			return "Checkmate: %s wins" % _match_color_name(outcome["winner"])
		ChessMatch.STATUS_STALEMATE:
			return "Draw: stalemate"
		ChessMatch.STATUS_DRAW:
			match outcome["reason"]:
				ChessMatch.DRAW_INSUFFICIENT_MATERIAL:
					return "Draw: insufficient material"
				ChessMatch.DRAW_THREEFOLD_REPETITION:
					return "Draw: threefold repetition"
				ChessMatch.DRAW_FIFTY_MOVE_RULE:
					return "Draw: fifty-move rule"
			return "Draw"
		_:
			return "Match in progress"


func _match_color_name(color: String) -> String:
	return color.capitalize()
