extends GutTest


func test_state_snapshot_round_trip_preserves_network_visible_state() -> void:
	var source_match := ChessMatch.new()
	assert_true(source_match.apply_coordinate_move(_sq("e2"), _sq("e4")))
	assert_true(source_match.apply_coordinate_move(_sq("e7"), _sq("e5")))
	assert_true(source_match.apply_coordinate_move(_sq("g1"), _sq("f3")))

	var snapshot := source_match.create_state_snapshot()
	var restored_match := ChessMatch.new()
	restored_match.load_state_snapshot(snapshot)

	assert_eq(restored_match.to_fen(), source_match.to_fen())
	assert_eq(restored_match.move_history, source_match.move_history)
	assert_eq(restored_match.claimable_draw_reason, source_match.claimable_draw_reason)
	assert_eq(restored_match.outcome, source_match.outcome)


func test_move_action_payload_applies_server_safe_move() -> void:
	var chess_match := ChessMatch.new()

	var result := chess_match.apply_action_payload({
		"type": ChessMatch.ACTION_TYPE_MOVE,
		"from": "e2",
		"to": "e4",
	})

	assert_true(result["ok"])
	assert_eq(chess_match.to_fen(), "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1")


func test_illegal_action_payload_is_rejected_without_state_change() -> void:
	var chess_match := ChessMatch.new()
	var before_fen := chess_match.to_fen()

	var result := chess_match.apply_action_payload({
		"type": ChessMatch.ACTION_TYPE_MOVE,
		"from": "e2",
		"to": "e5",
	})

	assert_false(result["ok"])
	assert_eq(result["reason"], "illegal_move")
	assert_eq(chess_match.to_fen(), before_fen)


func _sq(value: String) -> Vector2i:
	return ChessMatch.new().algebraic_to_square(value)
