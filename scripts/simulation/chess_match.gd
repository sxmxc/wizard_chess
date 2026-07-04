extends RefCounted
class_name ChessMatch

const WHITE := ChessEngine.WHITE
const BLACK := ChessEngine.BLACK
const COLORS := ChessEngine.COLORS

const STATUS_ACTIVE := ChessEngine.STATUS_ACTIVE
const STATUS_CHECKMATE := ChessEngine.STATUS_CHECKMATE
const STATUS_STALEMATE := ChessEngine.STATUS_STALEMATE
const STATUS_DRAW := ChessEngine.STATUS_DRAW

const ACTION_TYPE_MOVE := ChessEngine.ACTION_TYPE_MOVE
const ACTION_TYPE_CLAIM_DRAW := ChessEngine.ACTION_TYPE_CLAIM_DRAW

const DRAW_INSUFFICIENT_MATERIAL := ChessEngine.DRAW_INSUFFICIENT_MATERIAL
const DRAW_THREEFOLD_REPETITION := ChessEngine.DRAW_THREEFOLD_REPETITION
const DRAW_FIFTY_MOVE_RULE := ChessEngine.DRAW_FIFTY_MOVE_RULE

const PIECE_PAWN := ChessEngine.PIECE_PAWN
const PIECE_KNIGHT := ChessEngine.PIECE_KNIGHT
const PIECE_BISHOP := ChessEngine.PIECE_BISHOP
const PIECE_ROOK := ChessEngine.PIECE_ROOK
const PIECE_QUEEN := ChessEngine.PIECE_QUEEN
const PIECE_KING := ChessEngine.PIECE_KING

const PROMOTION_PIECES := ChessEngine.PROMOTION_PIECES
const FILE_LETTERS := ChessEngine.FILE_LETTERS
const STARTING_FEN := ChessEngine.STARTING_FEN

var state: ChessState
var engine: ChessEngine

var board: Array:
	get:
		return state.board
	set(value):
		state.board = value

var active_color: String:
	get:
		return state.active_color
	set(value):
		state.active_color = value

var castling_rights: Dictionary:
	get:
		return state.castling_rights
	set(value):
		state.castling_rights = value

var en_passant_target:
	get:
		return state.en_passant_target
	set(value):
		state.en_passant_target = value

var halfmove_clock: int:
	get:
		return state.halfmove_clock
	set(value):
		state.halfmove_clock = value

var fullmove_number: int:
	get:
		return state.fullmove_number
	set(value):
		state.fullmove_number = value

var move_history: Array:
	get:
		return state.move_history
	set(value):
		state.move_history = value

var position_history: Dictionary:
	get:
		return state.position_history
	set(value):
		state.position_history = value

var claimable_draw_reason: String:
	get:
		return state.claimable_draw_reason
	set(value):
		state.claimable_draw_reason = value

var outcome: Dictionary:
	get:
		return state.outcome
	set(value):
		state.outcome = value


func _init(skip_reset: bool = false) -> void:
	state = ChessState.new()
	engine = ChessEngine.new(state, skip_reset)


func reset() -> void:
	engine.reset()


func load_fen(fen: String) -> void:
	engine.load_fen(fen)


func to_fen(include_counters: bool = true) -> String:
	return engine.to_fen(include_counters)


func clone() -> ChessMatch:
	var copy := ChessMatch.new(true)
	copy.load_state_snapshot(create_state_snapshot())
	return copy


func get_piece(square: Vector2i):
	return engine.get_piece(square)


func get_legal_moves_from(square: Vector2i) -> Array:
	return engine.get_legal_moves_from(square)


func get_legal_moves_for_color(color: String) -> Array:
	return engine.get_legal_moves_for_color(color)


func apply_move(move: Dictionary) -> bool:
	return engine.apply_move(move)


func apply_coordinate_move(from_square: Vector2i, to_square: Vector2i, promotion: String = "") -> bool:
	return engine.apply_coordinate_move(from_square, to_square, promotion)


func claim_draw() -> bool:
	return engine.claim_draw()


func create_state_snapshot() -> Dictionary:
	return engine.create_state_snapshot()


func load_state_snapshot(snapshot: Dictionary) -> void:
	engine.load_state_snapshot(snapshot)


func create_move_action(from_square: Vector2i, to_square: Vector2i, promotion: String = "") -> Dictionary:
	return engine.create_move_action(from_square, to_square, promotion)


func apply_action_payload(action: Dictionary) -> Dictionary:
	return engine.apply_action_payload(action)


func is_in_check(color: String) -> bool:
	return engine.is_in_check(color)


func is_square_attacked(square: Vector2i, by_color: String) -> bool:
	return engine.is_square_attacked(square, by_color)


func has_insufficient_material() -> bool:
	return engine.has_insufficient_material()


func square_to_algebraic(square: Vector2i) -> String:
	return engine.square_to_algebraic(square)


func algebraic_to_square(value: String) -> Vector2i:
	return engine.algebraic_to_square(value)


func is_inside_board(square: Vector2i) -> bool:
	return engine.is_inside_board(square)
