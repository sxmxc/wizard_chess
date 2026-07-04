extends GutTest

const ChessMatch := preload("res://scripts/simulation/chess_match.gd")


func test_initial_position_has_standard_setup_and_legal_moves() -> void:
	var chess_match := ChessMatch.new()

	assert_eq(chess_match.to_fen(), ChessMatch.STARTING_FEN)
	assert_eq(chess_match.get_legal_moves_for_color(ChessMatch.WHITE).size(), 20)
	assert_eq(chess_match.get_legal_moves_for_color(ChessMatch.BLACK).size(), 20)
	assert_false(chess_match.is_in_check(ChessMatch.WHITE))
	assert_false(chess_match.is_in_check(ChessMatch.BLACK))
	assert_eq(chess_match.outcome["status"], ChessMatch.STATUS_ACTIVE)


func test_en_passant_is_generated_and_resolved() -> void:
	var chess_match := ChessMatch.new()

	assert_true(chess_match.apply_coordinate_move(_sq("e2"), _sq("e4")))
	assert_true(chess_match.apply_coordinate_move(_sq("a7"), _sq("a6")))
	assert_true(chess_match.apply_coordinate_move(_sq("e4"), _sq("e5")))
	assert_true(chess_match.apply_coordinate_move(_sq("d7"), _sq("d5")))

	var moves := chess_match.get_legal_moves_from(_sq("e5"))
	assert_true(_has_move(moves, _sq("d6")))
	assert_true(chess_match.apply_coordinate_move(_sq("e5"), _sq("d6")))

	assert_not_null(chess_match.get_piece(_sq("d6")))
	assert_null(chess_match.get_piece(_sq("d5")))
	assert_eq(chess_match.get_piece(_sq("d6"))["type"], ChessMatch.PIECE_PAWN)
	assert_string_contains(chess_match.move_history.back()["notation"], "e.p.")


func test_kingside_castle_moves_king_and_rook() -> void:
	var chess_match := ChessMatch.new()

	assert_true(chess_match.apply_coordinate_move(_sq("g1"), _sq("f3")))
	assert_true(chess_match.apply_coordinate_move(_sq("a7"), _sq("a6")))
	assert_true(chess_match.apply_coordinate_move(_sq("e2"), _sq("e4")))
	assert_true(chess_match.apply_coordinate_move(_sq("a6"), _sq("a5")))
	assert_true(chess_match.apply_coordinate_move(_sq("f1"), _sq("e2")))
	assert_true(chess_match.apply_coordinate_move(_sq("a5"), _sq("a4")))
	assert_true(chess_match.apply_coordinate_move(_sq("e1"), _sq("g1")))

	assert_eq(chess_match.get_piece(_sq("g1"))["type"], ChessMatch.PIECE_KING)
	assert_eq(chess_match.get_piece(_sq("f1"))["type"], ChessMatch.PIECE_ROOK)
	assert_null(chess_match.get_piece(_sq("e1")))
	assert_null(chess_match.get_piece(_sq("h1")))
	assert_eq(chess_match.move_history.back()["notation"], "O-O")


func test_promotion_requires_choice_and_records_result() -> void:
	var chess_match := ChessMatch.new()
	chess_match.load_fen("4k3/P7/8/8/8/8/8/4K3 w - - 0 1")

	var promotion_moves := chess_match.get_legal_moves_from(_sq("a7"))
	assert_eq(promotion_moves.size(), 4)
	assert_true(chess_match.apply_coordinate_move(_sq("a7"), _sq("a8"), ChessMatch.PIECE_QUEEN))

	assert_eq(chess_match.get_piece(_sq("a8"))["type"], ChessMatch.PIECE_QUEEN)
	assert_string_contains(chess_match.move_history.back()["notation"], "=Q")


func test_checkmate_is_detected_from_fools_mate() -> void:
	var chess_match := ChessMatch.new()

	assert_true(chess_match.apply_coordinate_move(_sq("f2"), _sq("f3")))
	assert_true(chess_match.apply_coordinate_move(_sq("e7"), _sq("e5")))
	assert_true(chess_match.apply_coordinate_move(_sq("g2"), _sq("g4")))
	assert_true(chess_match.apply_coordinate_move(_sq("d8"), _sq("h4")))

	assert_eq(chess_match.outcome["status"], ChessMatch.STATUS_CHECKMATE)
	assert_eq(chess_match.outcome["winner"], ChessMatch.BLACK)
	assert_string_ends_with(chess_match.move_history.back()["notation"], "#")


func test_stalemate_position_is_detected() -> void:
	var chess_match := ChessMatch.new()
	chess_match.load_fen("7k/5Q2/6K1/8/8/8/8/8 b - - 0 1")

	assert_eq(chess_match.outcome["status"], ChessMatch.STATUS_STALEMATE)


func test_threefold_repetition_can_be_claimed() -> void:
	var chess_match := ChessMatch.new()

	assert_true(chess_match.apply_coordinate_move(_sq("g1"), _sq("f3")))
	assert_true(chess_match.apply_coordinate_move(_sq("g8"), _sq("f6")))
	assert_true(chess_match.apply_coordinate_move(_sq("f3"), _sq("g1")))
	assert_true(chess_match.apply_coordinate_move(_sq("f6"), _sq("g8")))
	assert_true(chess_match.apply_coordinate_move(_sq("g1"), _sq("f3")))
	assert_true(chess_match.apply_coordinate_move(_sq("g8"), _sq("f6")))
	assert_true(chess_match.apply_coordinate_move(_sq("f3"), _sq("g1")))
	assert_true(chess_match.apply_coordinate_move(_sq("f6"), _sq("g8")))

	assert_eq(chess_match.claimable_draw_reason, ChessMatch.DRAW_THREEFOLD_REPETITION)
	assert_true(chess_match.claim_draw())
	assert_eq(chess_match.outcome["status"], ChessMatch.STATUS_DRAW)


func test_only_kings_is_immediate_draw_by_insufficient_material() -> void:
	var chess_match := ChessMatch.new()
	chess_match.load_fen("8/8/8/8/8/8/4k3/4K3 w - - 0 1")

	assert_eq(chess_match.outcome["status"], ChessMatch.STATUS_DRAW)
	assert_eq(chess_match.outcome["reason"], ChessMatch.DRAW_INSUFFICIENT_MATERIAL)


func _sq(value: String) -> Vector2i:
	return ChessMatch.new().algebraic_to_square(value)


func _has_move(moves: Array, destination: Vector2i) -> bool:
	for move in moves:
		if move["to"] == destination:
			return true
	return false
