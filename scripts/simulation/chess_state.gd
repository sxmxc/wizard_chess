extends RefCounted
class_name ChessState

const STATUS_ACTIVE := "active"
const WHITE := "white"

var board: Array = []
var active_color: String = WHITE
var castling_rights: Dictionary = {}
var en_passant_target: Variant = null
var halfmove_clock: int = 0
var fullmove_number: int = 1
var move_history: Array = []
var position_history: Dictionary = {}
var claimable_draw_reason: String = ""
var outcome: Dictionary = {
	"status": STATUS_ACTIVE,
	"winner": "",
	"reason": "",
}


func duplicate_deep() -> ChessState:
	var copy := ChessState.new()
	copy.board = _duplicate_board()
	copy.active_color = active_color
	copy.castling_rights = castling_rights.duplicate(true)
	copy.en_passant_target = en_passant_target
	copy.halfmove_clock = halfmove_clock
	copy.fullmove_number = fullmove_number
	copy.move_history = move_history.duplicate(true)
	copy.position_history = position_history.duplicate(true)
	copy.claimable_draw_reason = claimable_draw_reason
	copy.outcome = outcome.duplicate(true)
	return copy


func _duplicate_board() -> Array:
	var copied_board: Array = []
	for rank in range(board.size()):
		var row: Array = []
		for file in range(board[rank].size()):
			var piece = board[rank][file]
			row.append(null if piece == null else piece.duplicate(true))
		copied_board.append(row)
	return copied_board
