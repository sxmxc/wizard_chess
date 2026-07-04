extends GutTest


func test_start_match_initializes_zones_and_opening_hands() -> void:
	var match_rules := _make_rules()
	var wizard_match := WizardMatch.new(match_rules)
	var deck := _make_mixed_deck()

	wizard_match.start_match(deck, deck, 7)

	var white_state := wizard_match.get_player_state(ChessMatch.WHITE)
	var black_state := wizard_match.get_player_state(ChessMatch.BLACK)
	assert_eq(wizard_match.state, WizardMatch.STATE_ACTIVE)
	assert_eq(wizard_match.phase, WizardMatch.PHASE_BEGINNING)
	assert_eq(white_state["hand"].size(), 2)
	assert_eq(black_state["hand"].size(), 2)
	assert_eq(white_state["deck"].size(), 1)
	assert_eq(black_state["deck"].size(), 1)


func test_beginning_phase_refreshes_mana_and_draws_card() -> void:
	var wizard_match := WizardMatch.new(_make_rules())
	var deck := _make_mixed_deck()

	wizard_match.start_match(deck, deck, 3)

	assert_true(wizard_match.resolve_beginning_phase())
	var white_state := wizard_match.get_player_state(ChessMatch.WHITE)
	assert_eq(wizard_match.phase, WizardMatch.PHASE_PREPARATION)
	assert_eq(white_state["maximum_mana"], 1)
	assert_eq(white_state["mana"], 1)
	assert_eq(white_state["hand"].size(), 3)
	assert_eq(white_state["deck"].size(), 0)


func test_play_card_spends_mana_and_moves_spell_to_graveyard() -> void:
	var wizard_match := WizardMatch.new(_make_rules())
	var white_deck := _make_uniform_deck(_make_card(CardDefinition.TYPE_SPELL, 1, "spell_a"))
	var black_deck := _make_uniform_deck(_make_card(CardDefinition.TYPE_SPELL, 1, "spell_b"))

	wizard_match.start_match(white_deck, black_deck, 2)
	assert_true(wizard_match.resolve_beginning_phase())

	var white_state := wizard_match.get_player_state(ChessMatch.WHITE)
	var spell_instance_id := str(white_state["hand"][0]["instance_id"])
	var result := wizard_match.play_card_from_hand(spell_instance_id)

	assert_true(result["ok"])
	white_state = wizard_match.get_player_state(ChessMatch.WHITE)
	assert_eq(white_state["mana"], 0)
	assert_eq(white_state["graveyard"].size(), 1)
	assert_eq(white_state["battlefield"].size(), 0)


func test_play_card_moves_persistent_card_to_battlefield() -> void:
	var wizard_match := WizardMatch.new(_make_rules())
	var artifact_deck := _make_uniform_deck(_make_card(CardDefinition.TYPE_ARTIFACT, 1, "artifact_a"))

	wizard_match.start_match(artifact_deck, artifact_deck, 5)
	assert_true(wizard_match.resolve_beginning_phase())

	var white_state := wizard_match.get_player_state(ChessMatch.WHITE)
	var card_instance_id := str(white_state["hand"][0]["instance_id"])
	var result := wizard_match.play_card_from_hand(card_instance_id)

	assert_true(result["ok"])
	white_state = wizard_match.get_player_state(ChessMatch.WHITE)
	assert_eq(white_state["battlefield"].size(), 1)
	assert_eq(white_state["graveyard"].size(), 0)


func test_chess_move_is_phase_gated_and_advances_to_reaction() -> void:
	var wizard_match := WizardMatch.new(_make_rules())
	var deck := _make_mixed_deck()

	wizard_match.start_match(deck, deck, 11)
	assert_true(wizard_match.resolve_beginning_phase())
	assert_true(wizard_match.finish_preparation_phase())

	var move_result := wizard_match.apply_move_action(
		wizard_match.chess_engine.create_move_action(_sq("e2"), _sq("e4"))
	)

	assert_true(move_result["ok"])
	assert_eq(wizard_match.phase, WizardMatch.PHASE_REACTION)
	assert_eq(wizard_match.chess_engine.to_fen(), "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1")


func test_snapshot_round_trip_preserves_framework_state() -> void:
	var wizard_match := WizardMatch.new(_make_rules())
	var deck := _make_mixed_deck()

	wizard_match.start_match(deck, deck, 13)
	assert_true(wizard_match.resolve_beginning_phase())
	assert_true(wizard_match.finish_preparation_phase())
	assert_true(wizard_match.apply_move_action(
		wizard_match.chess_engine.create_move_action(_sq("e2"), _sq("e4"))
	)["ok"])

	var snapshot := wizard_match.create_state_snapshot()
	var restored := WizardMatch.new()
	restored.load_state_snapshot(snapshot)

	assert_eq(restored.create_state_snapshot(), snapshot)


func test_card_catalog_loads_sample_resources() -> void:
	var card := CardCatalog.load_card_definition("res://content/cards/sample_arcane_burst.tres")
	var deck := CardCatalog.load_deck_definition("res://content/decks/sample_framework_deck.tres")

	assert_not_null(card)
	assert_eq(card.card_id, "sample_arcane_burst")
	assert_not_null(deck)
	assert_eq(deck.card_count(), 6)


func _make_rules() -> WizardMatchRules:
	var rules := WizardMatchRules.new()
	rules.opening_hand_size = 2
	rules.maximum_hand_size = 7
	rules.starting_mana = 0
	rules.maximum_mana_cap = 10
	rules.mana_gained_per_turn = 1
	rules.cards_drawn_per_turn = 1
	return rules


func _make_mixed_deck() -> DeckDefinition:
	var deck := DeckDefinition.new()
	deck.cards = [
		_make_card(CardDefinition.TYPE_SPELL, 1, "spell_a"),
		_make_card(CardDefinition.TYPE_ARTIFACT, 1, "artifact_a"),
		_make_card(CardDefinition.TYPE_SPELL, 1, "spell_b"),
	]
	return deck


func _make_uniform_deck(card: CardDefinition) -> DeckDefinition:
	var deck := DeckDefinition.new()
	deck.cards = [card, card, card]
	return deck


func _make_card(card_type: String, mana_cost: int, card_id: String) -> CardDefinition:
	var card := CardDefinition.new()
	card.card_id = card_id
	card.display_name = card_id.capitalize()
	card.card_type = card_type
	card.mana_cost = mana_cost
	card.school = "Prototype"
	return card


func _sq(value: String) -> Vector2i:
	return ChessMatch.new().algebraic_to_square(value)
