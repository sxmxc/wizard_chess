extends GutTest


func test_network_snapshot_round_trip_preserves_client_visible_state() -> void:
	var source_match := _start_active_match()
	assert_true(source_match.resolve_beginning_phase())
	assert_true(source_match.finish_preparation_phase())
	assert_true(source_match.apply_action({
		"type": WizardMatch.ACTION_TYPE_MOVE,
		"action": source_match.chess_engine.create_move_action(_sq("e2"), _sq("e4")),
	}, ChessEngine.WHITE)["ok"])

	var snapshot := source_match.create_network_snapshot(ChessEngine.WHITE)
	var restored_match := WizardMatch.new(_make_rules())
	restored_match.load_state_snapshot(snapshot)

	assert_eq(restored_match.chess_engine.to_fen(), source_match.chess_engine.to_fen())
	assert_eq(restored_match.phase, source_match.phase)
	assert_eq(restored_match.get_player_state(ChessEngine.WHITE)["hand_count"], source_match.get_player_state(ChessEngine.WHITE)["hand"].size())
	assert_eq(restored_match.get_player_state(ChessEngine.BLACK)["hand_count"], source_match.get_player_state(ChessEngine.BLACK)["hand"].size())


func test_move_action_payload_applies_server_safe_move() -> void:
	var wizard_match := _start_active_match()
	assert_true(wizard_match.resolve_beginning_phase())
	assert_true(wizard_match.finish_preparation_phase())

	var result := wizard_match.apply_action({
		"type": WizardMatch.ACTION_TYPE_MOVE,
		"action": wizard_match.chess_engine.create_move_action(_sq("e2"), _sq("e4")),
	}, ChessEngine.WHITE)

	assert_true(result["ok"])
	assert_eq(wizard_match.chess_engine.to_fen(), "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1")


func test_illegal_action_payload_is_rejected_without_state_change() -> void:
	var wizard_match := _start_active_match()
	assert_true(wizard_match.resolve_beginning_phase())
	assert_true(wizard_match.finish_preparation_phase())
	var before_fen := wizard_match.chess_engine.to_fen()

	var result := wizard_match.apply_action({
		"type": WizardMatch.ACTION_TYPE_MOVE,
		"action": {
			"type": WizardMatch.ACTION_TYPE_MOVE,
			"from": "e2",
			"to": "e5",
		},
	}, ChessEngine.WHITE)

	assert_false(result["ok"])
	assert_eq(result["reason"], "illegal_move")
	assert_eq(wizard_match.chess_engine.to_fen(), before_fen)


func test_network_snapshot_preserves_public_battlefield_and_graveyard_state() -> void:
	var rules := _make_rules()
	rules.opening_hand_size = 3
	rules.required_deck_size = 3
	rules.mana_gained_per_turn = 4
	var source_match := WizardMatch.new(rules)
	var white_deck := DeckDefinition.new()
	white_deck.cards = [
		CardCatalog.load_card_definition("res://content/cards/sample_mana_storm.tres"),
		CardCatalog.load_card_definition("res://content/cards/sample_runic_snare.tres"),
		CardCatalog.load_card_definition("res://content/cards/sample_arcane_burst.tres"),
	]
	var black_deck := _make_deck()

	assert_true(source_match.start_match(white_deck, black_deck, 21)["ok"])
	assert_true(source_match.keep_opening_hand(ChessEngine.WHITE)["ok"])
	assert_true(source_match.keep_opening_hand(ChessEngine.BLACK)["ok"])
	assert_true(source_match.resolve_beginning_phase())

	var white_state := source_match.get_player_state(ChessEngine.WHITE)
	assert_true(source_match.play_card_from_hand(_hand_card_instance_id(white_state, "sample_mana_storm"))["ok"])
	white_state = source_match.get_player_state(ChessEngine.WHITE)
	assert_true(source_match.play_card_from_hand(
		_hand_card_instance_id(white_state, "sample_runic_snare"),
		[source_match.create_square_target(_sq("e5"))]
	)["ok"])
	white_state = source_match.get_player_state(ChessEngine.WHITE)
	assert_true(source_match.play_card_from_hand(_hand_card_instance_id(white_state, "sample_arcane_burst"))["ok"])

	var white_snapshot := source_match.create_network_snapshot(ChessEngine.WHITE)
	var white_restored := WizardMatch.new(_make_rules())
	white_restored.load_state_snapshot(white_snapshot)
	var restored_white_state := white_restored.get_player_state(ChessEngine.WHITE)
	assert_eq(restored_white_state["battlefield"].size(), 2)
	assert_eq(restored_white_state["graveyard"].size(), 1)
	assert_eq(str(restored_white_state["battlefield"][0].get("card_type", "")), CardDefinition.TYPE_ENVIRONMENT)
	assert_eq(str(restored_white_state["battlefield"][1].get("card_type", "")), CardDefinition.TYPE_TRAP)
	assert_eq(str(restored_white_state["battlefield"][1].get("placed_on", "")), "e5")
	assert_eq(str(restored_white_state["graveyard"][0].get("card_id", "")), "sample_arcane_burst")

	var black_snapshot := source_match.create_network_snapshot(ChessEngine.BLACK)
	var black_restored := WizardMatch.new(_make_rules())
	black_restored.load_state_snapshot(black_snapshot)
	var restored_from_black_view := black_restored.get_player_state(ChessEngine.WHITE)
	assert_eq(restored_from_black_view["battlefield"].size(), 2)
	assert_eq(restored_from_black_view["graveyard"].size(), 1)
	assert_eq(str(restored_from_black_view["battlefield"][0].get("card_id", "")), "sample_mana_storm")
	assert_eq(str(restored_from_black_view["battlefield"][1].get("card_type", "")), CardDefinition.TYPE_TRAP)
	assert_true(bool(restored_from_black_view["battlefield"][1].get("face_down", false)))
	assert_eq(str(restored_from_black_view["graveyard"][0].get("card_id", "")), "sample_arcane_burst")


func _start_active_match() -> WizardMatch:
	var wizard_match := WizardMatch.new(_make_rules())
	var deck := _make_deck()
	assert_true(wizard_match.start_match(deck, deck, 13)["ok"])
	assert_true(wizard_match.keep_opening_hand(ChessEngine.WHITE)["ok"])
	assert_true(wizard_match.keep_opening_hand(ChessEngine.BLACK)["ok"])
	return wizard_match


func _make_rules() -> WizardMatchRules:
	var rules := WizardMatchRules.new()
	rules.opening_hand_size = 2
	rules.maximum_hand_size = 7
	rules.starting_mana = 0
	rules.maximum_mana_cap = 10
	rules.mana_gained_per_turn = 1
	rules.cards_drawn_per_turn = 1
	rules.required_deck_size = 3
	rules.maximum_card_copies = 3
	return rules


func _make_deck() -> DeckDefinition:
	var card := CardDefinition.new()
	card.card_id = "network_spell"
	card.display_name = "Network Spell"
	card.card_type = CardDefinition.TYPE_SPELL
	card.school = "Prototype"
	var deck := DeckDefinition.new()
	deck.cards = [card, card.duplicate(true), card.duplicate(true)]
	return deck


func _hand_card_instance_id(player_state: Dictionary, card_id: String) -> String:
	for card_state in player_state.get("hand", []):
		if str(card_state.get("card_id", "")) == card_id:
			return str(card_state.get("instance_id", ""))
	return ""


func _sq(value: String) -> Vector2i:
	return ChessEngine.new().algebraic_to_square(value)
