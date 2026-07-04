extends RefCounted
class_name ChessEngine

const WHITE := "white"
const BLACK := "black"
const COLORS := [WHITE, BLACK]

const STATUS_ACTIVE := "active"
const STATUS_CHECKMATE := "checkmate"
const STATUS_STALEMATE := "stalemate"
const STATUS_DRAW := "draw"

const ACTION_TYPE_MOVE := "move"
const ACTION_TYPE_CLAIM_DRAW := "claim_draw"

const DRAW_INSUFFICIENT_MATERIAL := "insufficient_material"
const DRAW_THREEFOLD_REPETITION := "threefold_repetition"
const DRAW_FIFTY_MOVE_RULE := "fifty_move_rule"

const PIECE_PAWN := "pawn"
const PIECE_KNIGHT := "knight"
const PIECE_BISHOP := "bishop"
const PIECE_ROOK := "rook"
const PIECE_QUEEN := "queen"
const PIECE_KING := "king"

const PROMOTION_PIECES := [
	PIECE_QUEEN,
	PIECE_ROOK,
	PIECE_BISHOP,
	PIECE_KNIGHT,
]

const FILE_LETTERS := "abcdefgh"
const STARTING_FEN := "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

var state: ChessState


func _init(existing_state: ChessState = null, skip_reset: bool = false) -> void:
	state = existing_state if existing_state != null else ChessState.new()
	if not skip_reset:
		reset()


func reset() -> void:
	load_fen(STARTING_FEN)


func load_fen(fen: String) -> void:
	var parts := fen.strip_edges().split(" ", false)
	assert(parts.size() == 6)

	state.board = _create_empty_board()
	var rank_rows := parts[0].split("/")
	assert(rank_rows.size() == 8)

	for rank_index in range(8):
		var file_index := 0
		for token in rank_rows[rank_index]:
			var as_int := int(token)
			if as_int > 0:
				file_index += as_int
				continue

			var color := WHITE if token == token.to_upper() else BLACK
			var piece_type := _fen_piece_to_type(token.to_lower())
			state.board[rank_index][file_index] = _make_piece(piece_type, color)
			file_index += 1

	state.active_color = WHITE if parts[1] == "w" else BLACK
	state.castling_rights = {
		WHITE: {
			"king_side": parts[2].contains("K"),
			"queen_side": parts[2].contains("Q"),
		},
		BLACK: {
			"king_side": parts[2].contains("k"),
			"queen_side": parts[2].contains("q"),
		},
	}
	state.en_passant_target = null
	if parts[3] != "-":
		state.en_passant_target = algebraic_to_square(parts[3])
	state.halfmove_clock = int(parts[4])
	state.fullmove_number = int(parts[5])
	state.move_history = []
	state.position_history = {}
	_record_position()
	_refresh_outcome()


func to_fen(include_counters: bool = true) -> String:
	var rows: Array[String] = []
	for rank in range(8):
		var row := ""
		var empty_count := 0
		for file in range(8):
			var piece = state.board[rank][file]
			if piece == null:
				empty_count += 1
				continue
			if empty_count > 0:
				row += str(empty_count)
				empty_count = 0
			row += _piece_to_fen(piece)
		if empty_count > 0:
			row += str(empty_count)
		rows.append(row)

	var castling := ""
	if state.castling_rights[WHITE]["king_side"]:
		castling += "K"
	if state.castling_rights[WHITE]["queen_side"]:
		castling += "Q"
	if state.castling_rights[BLACK]["king_side"]:
		castling += "k"
	if state.castling_rights[BLACK]["queen_side"]:
		castling += "q"
	if castling.is_empty():
		castling = "-"

	var fen := "%s %s %s %s" % [
		"/".join(rows),
		"w" if state.active_color == WHITE else "b",
		castling,
		"-" if state.en_passant_target == null else square_to_algebraic(state.en_passant_target),
	]

	if include_counters:
		fen += " %d %d" % [state.halfmove_clock, state.fullmove_number]

	return fen


func clone_state() -> ChessState:
	return state.duplicate_deep()


func clone() -> ChessEngine:
	return ChessEngine.new(clone_state(), true)


func get_piece(square: Vector2i):
	if not is_inside_board(square):
		return null
	return state.board[square.y][square.x]


func get_legal_moves_from(square: Vector2i) -> Array:
	var piece = get_piece(square)
	if piece == null or piece["color"] != state.active_color or state.outcome["status"] != STATUS_ACTIVE:
		return []

	var legal_moves: Array = []
	for move in _generate_pseudo_legal_moves(square, piece):
		if not _would_leave_king_in_check(move, piece["color"]):
			legal_moves.append(move)
	return legal_moves


func get_legal_moves_for_color(color: String) -> Array:
	var legal_moves: Array = []
	for rank in range(8):
		for file in range(8):
			var square := Vector2i(file, rank)
			var piece = get_piece(square)
			if piece == null or piece["color"] != color:
				continue
			for move in _generate_pseudo_legal_moves(square, piece):
				if not _would_leave_king_in_check(move, color):
					legal_moves.append(move)
	return legal_moves


func apply_move(move: Dictionary) -> bool:
	if state.outcome["status"] != STATUS_ACTIVE:
		return false

	var legal_move = _find_matching_legal_move(move)
	if legal_move == null:
		return false

	_apply_move_unchecked(legal_move, true)
	return true


func apply_coordinate_move(from_square: Vector2i, to_square: Vector2i, promotion: String = "") -> bool:
	return apply_move({
		"from": from_square,
		"to": to_square,
		"promotion": promotion,
	})


func claim_draw() -> bool:
	if state.claimable_draw_reason.is_empty() or state.outcome["status"] != STATUS_ACTIVE:
		return false

	state.outcome = {
		"status": STATUS_DRAW,
		"winner": "",
		"reason": state.claimable_draw_reason,
	}
	return true


func create_state_snapshot() -> Dictionary:
	return {
		"fen": to_fen(),
		"move_history": state.move_history.duplicate(true),
		"position_history": state.position_history.duplicate(true),
		"claimable_draw_reason": state.claimable_draw_reason,
		"outcome": state.outcome.duplicate(true),
	}


func load_state_snapshot(snapshot: Dictionary) -> void:
	load_fen(str(snapshot.get("fen", STARTING_FEN)))
	state.move_history = snapshot.get("move_history", []).duplicate(true)
	state.position_history = snapshot.get("position_history", {}).duplicate(true)
	state.claimable_draw_reason = str(snapshot.get("claimable_draw_reason", ""))
	state.outcome = snapshot.get("outcome", state.outcome).duplicate(true)


func create_move_action(from_square: Vector2i, to_square: Vector2i, promotion: String = "") -> Dictionary:
	return {
		"type": ACTION_TYPE_MOVE,
		"from": square_to_algebraic(from_square),
		"to": square_to_algebraic(to_square),
		"promotion": promotion,
	}


func apply_action_payload(action: Dictionary) -> Dictionary:
	var action_type := str(action.get("type", ""))
	match action_type:
		ACTION_TYPE_MOVE:
			if not action.has("from") or not action.has("to"):
				return _action_result(false, "missing_move_coordinates")
			var promotion := str(action.get("promotion", ""))
			var from_square := algebraic_to_square(str(action["from"]))
			var to_square := algebraic_to_square(str(action["to"]))
			if not apply_coordinate_move(from_square, to_square, promotion):
				return _action_result(false, "illegal_move")
			return _action_result(true)
		ACTION_TYPE_CLAIM_DRAW:
			if not claim_draw():
				return _action_result(false, "draw_unavailable")
			return _action_result(true)
		_:
			return _action_result(false, "unknown_action")


func is_in_check(color: String) -> bool:
	var king_square = _find_king(color)
	if king_square == null:
		return false
	return is_square_attacked(king_square, _opponent(color))


func is_square_attacked(square: Vector2i, by_color: String) -> bool:
	var pawn_direction := -1 if by_color == BLACK else 1
	for file_offset in [-1, 1]:
		var pawn_square := square + Vector2i(file_offset, pawn_direction)
		var pawn = get_piece(pawn_square)
		if pawn != null and pawn["color"] == by_color and pawn["type"] == PIECE_PAWN:
			return true

	for offset in [
		Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(1, -2),
		Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, 2),
	]:
		var knight = get_piece(square + offset)
		if knight != null and knight["color"] == by_color and knight["type"] == PIECE_KNIGHT:
			return true

	if _is_attacked_by_slider(square, by_color, [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	], [PIECE_ROOK, PIECE_QUEEN]):
		return true

	if _is_attacked_by_slider(square, by_color, [
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1),
	], [PIECE_BISHOP, PIECE_QUEEN]):
		return true

	for offset in [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
	]:
		var king = get_piece(square + offset)
		if king != null and king["color"] == by_color and king["type"] == PIECE_KING:
			return true

	return false


func has_insufficient_material() -> bool:
	var minor_pieces: Array = []
	for rank in range(8):
		for file in range(8):
			var piece = state.board[rank][file]
			if piece == null or piece["type"] == PIECE_KING:
				continue
			if piece["type"] in [PIECE_PAWN, PIECE_ROOK, PIECE_QUEEN]:
				return false
			minor_pieces.append({
				"type": piece["type"],
				"color": piece["color"],
				"square": Vector2i(file, rank),
			})

	if minor_pieces.is_empty():
		return true

	if minor_pieces.size() == 1:
		return true

	var all_bishops := true
	for piece_data in minor_pieces:
		if piece_data["type"] != PIECE_BISHOP:
			all_bishops = false
			break
	if all_bishops:
		var first_color = _is_light_square(minor_pieces[0]["square"])
		for piece_data in minor_pieces:
			if _is_light_square(piece_data["square"]) != first_color:
				return false
		return true

	if minor_pieces.size() == 2:
		if minor_pieces[0]["type"] == PIECE_KNIGHT and minor_pieces[1]["type"] == PIECE_KNIGHT:
			return true

	return false


func square_to_algebraic(square: Vector2i) -> String:
	return "%s%d" % [FILE_LETTERS[square.x], 8 - square.y]


func algebraic_to_square(value: String) -> Vector2i:
	var square := value.strip_edges().to_lower()
	return Vector2i(FILE_LETTERS.find(square[0]), 8 - int(square.substr(1)))


func is_inside_board(square: Vector2i) -> bool:
	return square.x >= 0 and square.x < 8 and square.y >= 0 and square.y < 8


func _create_empty_board() -> Array:
	var created_board: Array = []
	for rank in range(8):
		var row: Array = []
		row.resize(8)
		for file in range(8):
			row[file] = null
		created_board.append(row)
	return created_board


func _make_piece(piece_type: String, color: String) -> Dictionary:
	return {
		"type": piece_type,
		"color": color,
	}


func _fen_piece_to_type(token: String) -> String:
	match token:
		"p":
			return PIECE_PAWN
		"n":
			return PIECE_KNIGHT
		"b":
			return PIECE_BISHOP
		"r":
			return PIECE_ROOK
		"q":
			return PIECE_QUEEN
		"k":
			return PIECE_KING
		_:
			push_error("Unknown FEN piece token: %s" % token)
			return PIECE_PAWN


func _piece_to_fen(piece: Dictionary) -> String:
	var token := ""
	match piece["type"]:
		PIECE_PAWN:
			token = "p"
		PIECE_KNIGHT:
			token = "n"
		PIECE_BISHOP:
			token = "b"
		PIECE_ROOK:
			token = "r"
		PIECE_QUEEN:
			token = "q"
		PIECE_KING:
			token = "k"
	return token.to_upper() if piece["color"] == WHITE else token


func _generate_pseudo_legal_moves(square: Vector2i, piece: Dictionary) -> Array:
	match piece["type"]:
		PIECE_PAWN:
			return _generate_pawn_moves(square, piece)
		PIECE_KNIGHT:
			return _generate_leaper_moves(square, piece, [
				Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(1, -2),
				Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, 2),
			])
		PIECE_BISHOP:
			return _generate_slider_moves(square, piece, [
				Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
			])
		PIECE_ROOK:
			return _generate_slider_moves(square, piece, [
				Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
			])
		PIECE_QUEEN:
			return _generate_slider_moves(square, piece, [
				Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
				Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
			])
		PIECE_KING:
			return _generate_king_moves(square, piece)
		_:
			return []


func _generate_pawn_moves(square: Vector2i, piece: Dictionary) -> Array:
	var moves: Array = []
	var direction := -1 if piece["color"] == WHITE else 1
	var start_rank := 6 if piece["color"] == WHITE else 1
	var promotion_rank := 0 if piece["color"] == WHITE else 7

	var one_step := square + Vector2i(0, direction)
	if is_inside_board(one_step) and get_piece(one_step) == null:
		var quiet_move := _build_move(square, one_step, piece)
		if one_step.y == promotion_rank:
			_append_promotion_moves(moves, quiet_move)
		else:
			moves.append(quiet_move)

		var two_step := square + Vector2i(0, direction * 2)
		if square.y == start_rank and get_piece(two_step) == null:
			moves.append(_build_move(square, two_step, piece, {
				"is_double_step": true,
			}))

	for file_offset in [-1, 1]:
		var target := square + Vector2i(file_offset, direction)
		if not is_inside_board(target):
			continue

		var occupant = get_piece(target)
		if occupant != null and occupant["color"] != piece["color"]:
			var capture_move := _build_move(square, target, piece)
			if target.y == promotion_rank:
				_append_promotion_moves(moves, capture_move)
			else:
				moves.append(capture_move)
			continue

		if state.en_passant_target != null and target == state.en_passant_target:
			var captured_square := Vector2i(target.x, square.y)
			var captured_piece = get_piece(captured_square)
			if captured_piece != null and captured_piece["color"] != piece["color"] and captured_piece["type"] == PIECE_PAWN:
				moves.append(_build_move(square, target, piece, {
					"is_en_passant": true,
					"captured_square": captured_square,
					"captured_piece_type": PIECE_PAWN,
					"is_capture": true,
				}))

	return moves


func _generate_leaper_moves(square: Vector2i, piece: Dictionary, offsets: Array) -> Array:
	var moves: Array = []
	for offset_value in offsets:
		var offset: Vector2i = offset_value
		var target: Vector2i = square + offset
		if not is_inside_board(target):
			continue
		var occupant = get_piece(target)
		if occupant == null or occupant["color"] != piece["color"]:
			moves.append(_build_move(square, target, piece))
	return moves


func _generate_slider_moves(square: Vector2i, piece: Dictionary, directions: Array) -> Array:
	var moves: Array = []
	for direction_value in directions:
		var direction: Vector2i = direction_value
		var target: Vector2i = square + direction
		while is_inside_board(target):
			var occupant = get_piece(target)
			if occupant == null:
				moves.append(_build_move(square, target, piece))
				target += direction
				continue

			if occupant["color"] != piece["color"]:
				moves.append(_build_move(square, target, piece))
			break
	return moves


func _generate_king_moves(square: Vector2i, piece: Dictionary) -> Array:
	var moves: Array = _generate_leaper_moves(square, piece, [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
	])

	if is_in_check(piece["color"]):
		return moves

	var home_rank := 7 if piece["color"] == WHITE else 0
	var rights = state.castling_rights[piece["color"]]
	if square == Vector2i(4, home_rank):
		if rights["king_side"] and _can_castle_through(piece["color"], [
			Vector2i(5, home_rank),
			Vector2i(6, home_rank),
		], Vector2i(7, home_rank)):
			moves.append(_build_move(square, Vector2i(6, home_rank), piece, {
				"is_castle_kingside": true,
			}))

		if rights["queen_side"] and _can_castle_through(piece["color"], [
			Vector2i(3, home_rank),
			Vector2i(2, home_rank),
		], Vector2i(0, home_rank), Vector2i(1, home_rank)):
			moves.append(_build_move(square, Vector2i(2, home_rank), piece, {
				"is_castle_queenside": true,
			}))

	return moves


func _can_castle_through(color: String, path_squares: Array, rook_square: Vector2i, extra_empty_square: Vector2i = Vector2i(-1, -1)) -> bool:
	var rook = get_piece(rook_square)
	if rook == null or rook["color"] != color or rook["type"] != PIECE_ROOK:
		return false

	for square in path_squares:
		if get_piece(square) != null or is_square_attacked(square, _opponent(color)):
			return false

	if extra_empty_square.x >= 0 and get_piece(extra_empty_square) != null:
		return false

	return true


func _build_move(from_square: Vector2i, to_square: Vector2i, piece: Dictionary, extra: Dictionary = {}) -> Dictionary:
	var occupant = get_piece(to_square)
	var move: Dictionary = {
		"from": from_square,
		"to": to_square,
		"piece_type": piece["type"],
		"color": piece["color"],
		"promotion": "",
		"is_capture": occupant != null,
		"captured_piece_type": "" if occupant == null else occupant["type"],
		"captured_square": to_square,
		"is_en_passant": false,
		"is_double_step": false,
		"is_castle_kingside": false,
		"is_castle_queenside": false,
	}
	for key in extra.keys():
		move[key] = extra[key]
	return move


func _append_promotion_moves(moves: Array, base_move: Dictionary) -> void:
	for promotion_piece in PROMOTION_PIECES:
		var promotion_move = base_move.duplicate(true)
		promotion_move["promotion"] = promotion_piece
		moves.append(promotion_move)


func _find_matching_legal_move(move: Dictionary):
	for legal_move in get_legal_moves_from(move["from"]):
		if legal_move["to"] != move["to"]:
			continue
		var requested_promotion: String = move.get("promotion", "")
		if legal_move["promotion"] == requested_promotion:
			return legal_move
	return null


func _would_leave_king_in_check(move: Dictionary, color: String) -> bool:
	var simulated := clone()
	simulated._apply_move_unchecked(move, false, false)
	return simulated.is_in_check(color)


func _apply_move_unchecked(move: Dictionary, record_history: bool, refresh_state: bool = true) -> void:
	var moving_piece: Dictionary = get_piece(move["from"]).duplicate(true)
	var moving_color: String = moving_piece["color"]
	var turn_number := state.fullmove_number
	var capture_happened := false

	state.board[move["from"].y][move["from"].x] = null

	if move["is_en_passant"]:
		var captured_square: Vector2i = move["captured_square"]
		if get_piece(captured_square) != null:
			state.board[captured_square.y][captured_square.x] = null
			capture_happened = true
	else:
		if get_piece(move["to"]) != null:
			capture_happened = true

	if move["is_castle_kingside"]:
		var home_rank := 7 if moving_color == WHITE else 0
		state.board[home_rank][5] = state.board[home_rank][7]
		state.board[home_rank][7] = null
	elif move["is_castle_queenside"]:
		var queen_home_rank := 7 if moving_color == WHITE else 0
		state.board[queen_home_rank][3] = state.board[queen_home_rank][0]
		state.board[queen_home_rank][0] = null

	if not move["promotion"].is_empty():
		moving_piece["type"] = move["promotion"]
	state.board[move["to"].y][move["to"].x] = moving_piece

	_update_castling_rights_after_move(move, moving_piece)

	state.en_passant_target = null
	if move["piece_type"] == PIECE_PAWN and move["is_double_step"]:
		state.en_passant_target = move["from"] + Vector2i(0, -1 if moving_color == WHITE else 1)

	if move["piece_type"] == PIECE_PAWN or capture_happened:
		state.halfmove_clock = 0
	else:
		state.halfmove_clock += 1

	state.active_color = _opponent(state.active_color)
	if moving_color == BLACK:
		state.fullmove_number += 1

	if refresh_state:
		_record_position()
		_refresh_outcome()

	if record_history:
		state.move_history.append({
			"turn_number": turn_number,
			"color": moving_color,
			"move": move.duplicate(true),
			"notation": _move_to_notation(move),
			"fen": to_fen(),
		})


func _update_castling_rights_after_move(move: Dictionary, moving_piece: Dictionary) -> void:
	var color: String = moving_piece["color"]
	if moving_piece["type"] == PIECE_KING:
		state.castling_rights[color]["king_side"] = false
		state.castling_rights[color]["queen_side"] = false
	elif moving_piece["type"] == PIECE_ROOK:
		if move["from"] == Vector2i(0, 7):
			state.castling_rights[WHITE]["queen_side"] = false
		elif move["from"] == Vector2i(7, 7):
			state.castling_rights[WHITE]["king_side"] = false
		elif move["from"] == Vector2i(0, 0):
			state.castling_rights[BLACK]["queen_side"] = false
		elif move["from"] == Vector2i(7, 0):
			state.castling_rights[BLACK]["king_side"] = false

	var captured_square: Vector2i = move["captured_square"]
	if move["is_capture"] and not move["is_en_passant"]:
		if captured_square == Vector2i(0, 7):
			state.castling_rights[WHITE]["queen_side"] = false
		elif captured_square == Vector2i(7, 7):
			state.castling_rights[WHITE]["king_side"] = false
		elif captured_square == Vector2i(0, 0):
			state.castling_rights[BLACK]["queen_side"] = false
		elif captured_square == Vector2i(7, 0):
			state.castling_rights[BLACK]["king_side"] = false


func _refresh_outcome() -> void:
	state.claimable_draw_reason = ""
	if has_insufficient_material():
		state.outcome = {
			"status": STATUS_DRAW,
			"winner": "",
			"reason": DRAW_INSUFFICIENT_MATERIAL,
		}
		return

	var legal_moves := get_legal_moves_for_color(state.active_color)
	if legal_moves.is_empty():
		if is_in_check(state.active_color):
			state.outcome = {
				"status": STATUS_CHECKMATE,
				"winner": _opponent(state.active_color),
				"reason": STATUS_CHECKMATE,
			}
		else:
			state.outcome = {
				"status": STATUS_STALEMATE,
				"winner": "",
				"reason": STATUS_STALEMATE,
			}
		return

	state.outcome = {
		"status": STATUS_ACTIVE,
		"winner": "",
		"reason": "",
	}

	var current_position_count: int = state.position_history.get(_position_key(), 0)
	if current_position_count >= 3:
		state.claimable_draw_reason = DRAW_THREEFOLD_REPETITION
	elif state.halfmove_clock >= 100:
		state.claimable_draw_reason = DRAW_FIFTY_MOVE_RULE


func _record_position() -> void:
	var key := _position_key()
	state.position_history[key] = int(state.position_history.get(key, 0)) + 1


func _position_key() -> String:
	return to_fen(false)


func _move_to_notation(move: Dictionary) -> String:
	if move["is_castle_kingside"]:
		return "O-O%s" % _notation_suffix()
	if move["is_castle_queenside"]:
		return "O-O-O%s" % _notation_suffix()

	var piece_letter := _piece_letter(move["piece_type"])
	var origin := square_to_algebraic(move["from"])
	var destination := square_to_algebraic(move["to"])
	var separator := "x" if move["is_capture"] else "-"
	var notation := "%s%s%s" % [piece_letter, origin, separator]
	notation += destination

	if move["is_en_passant"]:
		notation += " e.p."
	if not move["promotion"].is_empty():
		notation += "=%s" % _piece_letter(move["promotion"])

	return notation + _notation_suffix()


func _notation_suffix() -> String:
	if state.outcome["status"] == STATUS_CHECKMATE:
		return "#"
	if state.outcome["status"] == STATUS_ACTIVE and is_in_check(state.active_color):
		return "+"
	return ""


func _piece_letter(piece_type: String) -> String:
	match piece_type:
		PIECE_PAWN:
			return ""
		PIECE_KNIGHT:
			return "N"
		PIECE_BISHOP:
			return "B"
		PIECE_ROOK:
			return "R"
		PIECE_QUEEN:
			return "Q"
		PIECE_KING:
			return "K"
		_:
			return ""


func _find_king(color: String):
	for rank in range(8):
		for file in range(8):
			var piece = state.board[rank][file]
			if piece != null and piece["color"] == color and piece["type"] == PIECE_KING:
				return Vector2i(file, rank)
	return null


func _is_attacked_by_slider(square: Vector2i, by_color: String, directions: Array, piece_types: Array) -> bool:
	for direction_value in directions:
		var direction: Vector2i = direction_value
		var current: Vector2i = square + direction
		while is_inside_board(current):
			var occupant = get_piece(current)
			if occupant == null:
				current += direction
				continue
			if occupant["color"] == by_color and occupant["type"] in piece_types:
				return true
			break
	return false


func _opponent(color: String) -> String:
	return BLACK if color == WHITE else WHITE


func _is_light_square(square: Vector2i) -> bool:
	return (square.x + square.y) % 2 == 0


func _action_result(ok: bool, reason: String = "") -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
	}
