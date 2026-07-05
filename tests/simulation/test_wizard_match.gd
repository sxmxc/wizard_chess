extends GutTest


func test_start_match_initializes_setup_state_and_opening_hands() -> void:
	var wizard_match := WizardMatch.new(_make_rules())
	var deck := _make_mixed_deck()

	var result := wizard_match.start_match(deck, deck, 7)

	var white_state := wizard_match.get_player_state(ChessMatch.WHITE)
	var black_state := wizard_match.get_player_state(ChessMatch.BLACK)
	assert_true(result["ok"])
	assert_eq(wizard_match.state, WizardMatch.STATE_SETUP)
	assert_eq(wizard_match.setup_step, WizardMatch.SETUP_STEP_MULLIGAN)
	assert_eq(wizard_match.phase, WizardMatch.PHASE_BEGINNING)
	assert_eq(white_state["hand"].size(), 2)
	assert_eq(black_state["hand"].size(), 2)
	assert_eq(white_state["deck"].size(), 1)
	assert_eq(black_state["deck"].size(), 1)


func test_keep_opening_hands_completes_setup() -> void:
	var wizard_match := WizardMatch.new(_make_rules())
	var deck := _make_mixed_deck()

	assert_true(wizard_match.start_match(deck, deck, 3)["ok"])
	assert_true(wizard_match.keep_opening_hand(ChessMatch.WHITE)["ok"])
	assert_true(wizard_match.keep_opening_hand(ChessMatch.BLACK)["ok"])

	assert_eq(wizard_match.state, WizardMatch.STATE_ACTIVE)
	assert_eq(wizard_match.setup_step, WizardMatch.SETUP_STEP_READY)


func test_mulligan_returns_selected_cards_and_draws_replacements() -> void:
	var wizard_match := WizardMatch.new(_make_rules())
	var deck := _make_mixed_deck()

	assert_true(wizard_match.start_match(deck, deck, 9)["ok"])
	var white_state := wizard_match.get_player_state(ChessMatch.WHITE)
	var replaced_id := str(white_state["hand"][0]["instance_id"])

	assert_true(wizard_match.perform_mulligan(ChessMatch.WHITE, [replaced_id])["ok"])
	assert_true(wizard_match.keep_opening_hand(ChessMatch.BLACK)["ok"])

	white_state = wizard_match.get_player_state(ChessMatch.WHITE)
	assert_false(white_state["mulligan_available"])
	assert_eq(white_state["hand"].size(), 2)
	assert_eq(white_state["deck"].size(), 1)
	assert_eq(wizard_match.state, WizardMatch.STATE_ACTIVE)


func test_beginning_phase_refreshes_mana_and_draws_card() -> void:
	var wizard_match := _start_active_match()

	assert_true(wizard_match.resolve_beginning_phase())
	var white_state := wizard_match.get_player_state(ChessMatch.WHITE)
	assert_eq(wizard_match.phase, WizardMatch.PHASE_PREPARATION)
	assert_eq(white_state["maximum_mana"], 1)
	assert_eq(white_state["mana"], 1)
	assert_eq(white_state["hand"].size(), 3)
	assert_eq(white_state["deck"].size(), 0)


func test_play_card_spends_mana_and_moves_spell_to_graveyard() -> void:
	var rules := _make_rules()
	rules.mana_gained_per_turn = 2
	var wizard_match := WizardMatch.new(rules)
	var white_deck := _make_uniform_deck(_make_card(CardDefinition.TYPE_SPELL, 1, "spell_a"))
	var black_deck := _make_uniform_deck(_make_card(CardDefinition.TYPE_SPELL, 1, "spell_b"))

	assert_true(wizard_match.start_match(white_deck, black_deck, 2)["ok"])
	assert_true(wizard_match.keep_opening_hand(ChessMatch.WHITE)["ok"])
	assert_true(wizard_match.keep_opening_hand(ChessMatch.BLACK)["ok"])
	assert_true(wizard_match.resolve_beginning_phase())

	var white_state := wizard_match.get_player_state(ChessMatch.WHITE)
	var spell_instance_id := str(white_state["hand"][0]["instance_id"])
	var result := wizard_match.play_card_from_hand(spell_instance_id)

	assert_true(result["ok"])
	white_state = wizard_match.get_player_state(ChessMatch.WHITE)
	assert_eq(white_state["mana"], 1)
	assert_eq(white_state["graveyard"].size(), 1)
	assert_eq(white_state["battlefield"].size(), 0)


func test_unit_card_requires_valid_target_and_replaces_existing_unit() -> void:
	var rules := _make_rules()
	rules.mana_gained_per_turn = 2
	var wizard_match := WizardMatch.new(rules)
	var unit_a := _make_card(CardDefinition.TYPE_UNIT, 0, "unit_a", ["Target friendly piece."])
	var unit_b := _make_card(CardDefinition.TYPE_UNIT, 0, "unit_b", ["Target friendly piece."])
	var white_deck := DeckDefinition.new()
	white_deck.cards = [unit_a, unit_b, unit_a]
	var black_deck := _make_uniform_deck(_make_card(CardDefinition.TYPE_SPELL, 0, "spell_b"))

	assert_true(wizard_match.start_match(white_deck, black_deck, 4)["ok"])
	assert_true(wizard_match.keep_opening_hand(ChessMatch.WHITE)["ok"])
	assert_true(wizard_match.keep_opening_hand(ChessMatch.BLACK)["ok"])
	assert_true(wizard_match.resolve_beginning_phase())

	var white_state := wizard_match.get_player_state(ChessMatch.WHITE)
	var first_unit_id := str(white_state["hand"][0]["instance_id"])
	var second_unit_id := str(white_state["hand"][1]["instance_id"])
	var target := wizard_match.create_piece_target(_sq("e2"))

	assert_true(wizard_match.play_card_from_hand(first_unit_id, [target])["ok"])
	var invalid_target_result := wizard_match.play_card_from_hand(second_unit_id, [wizard_match.create_piece_target(_sq("e7"))])
	assert_false(invalid_target_result["ok"])
	assert_eq(invalid_target_result["reason"], "invalid_target")

	white_state = wizard_match.get_player_state(ChessMatch.WHITE)
	second_unit_id = str(white_state["hand"][0]["instance_id"])
	assert_true(wizard_match.play_card_from_hand(second_unit_id, [target])["ok"])

	white_state = wizard_match.get_player_state(ChessMatch.WHITE)
	assert_eq(white_state["battlefield"].size(), 1)
	assert_eq(white_state["graveyard"].size(), 1)
	assert_eq(white_state["battlefield"][0]["attached_to"], "e2")
	assert_eq(wizard_match.get_active_effects().size(), 1)
	assert_eq(wizard_match.get_active_effects()[0]["attached_to"], "e2")


func test_reaction_card_requires_trigger_and_reaction_priority() -> void:
	var rules := _make_rules()
	rules.mana_gained_per_turn = 1
	var wizard_match := WizardMatch.new(rules)
	var white_deck := _make_uniform_deck(_make_card(CardDefinition.TYPE_SPELL, 0, "white_spell"))
	var reaction := _make_card(CardDefinition.TYPE_REACTION, 0, "black_reaction")
	reaction.trigger_condition = "after_piece_moves"
	reaction.effect_duration = WizardMatch.EFFECT_DURATION_UNTIL_END_OF_TURN
	reaction.effect_tags = PackedStringArray(["ward"])
	var black_deck := _make_uniform_deck(reaction)

	assert_true(wizard_match.start_match(white_deck, black_deck, 5)["ok"])
	assert_true(wizard_match.keep_opening_hand(ChessMatch.WHITE)["ok"])
	assert_true(wizard_match.keep_opening_hand(ChessMatch.BLACK)["ok"])
	assert_true(wizard_match.resolve_beginning_phase())
	assert_true(wizard_match.finish_preparation_phase())
	assert_true(wizard_match.apply_move_action(
		wizard_match.chess_engine.create_move_action(_sq("e2"), _sq("e4"))
	)["ok"])

	var black_state := wizard_match.get_player_state(ChessMatch.BLACK)
	var reaction_id := str(black_state["hand"][0]["instance_id"])
	var denied_result := wizard_match.play_card_from_hand(reaction_id)
	assert_false(denied_result["ok"])
	assert_eq(denied_result["reason"], "not_reaction_priority")

	assert_true(wizard_match.pass_reaction_phase())
	assert_true(wizard_match.play_card_from_hand(reaction_id)["ok"])
	assert_eq(wizard_match.get_player_state(ChessMatch.BLACK)["graveyard"].size(), 1)
	assert_eq(wizard_match.get_active_effects().size(), 1)
	assert_eq(wizard_match.get_active_effects()[0]["source_card_type"], CardDefinition.TYPE_REACTION)

	assert_true(wizard_match.pass_reaction_phase())
	assert_true(wizard_match.pass_reaction_phase())
	assert_true(wizard_match.resolve_end_phase())
	assert_eq(wizard_match.get_active_effects().size(), 0)


func test_trap_card_triggers_when_opposing_piece_enters_square() -> void:
	var rules := _make_rules()
	rules.mana_gained_per_turn = 1
	var wizard_match := WizardMatch.new(rules)
	var trap := _make_card(CardDefinition.TYPE_TRAP, 0, "explosive_rune", ["Play on empty square."])
	trap.trigger_condition = "when_opposing_piece_enters"
	trap.effect_tags = PackedStringArray(["burning"])
	var white_deck := _make_uniform_deck(trap)
	var black_deck := _make_uniform_deck(_make_card(CardDefinition.TYPE_SPELL, 0, "black_spell"))

	assert_true(wizard_match.start_match(white_deck, black_deck, 6)["ok"])
	assert_true(wizard_match.keep_opening_hand(ChessMatch.WHITE)["ok"])
	assert_true(wizard_match.keep_opening_hand(ChessMatch.BLACK)["ok"])
	assert_true(wizard_match.resolve_beginning_phase())

	var white_state := wizard_match.get_player_state(ChessMatch.WHITE)
	var trap_id := str(white_state["hand"][0]["instance_id"])
	assert_true(wizard_match.play_card_from_hand(trap_id, [wizard_match.create_square_target(_sq("e5"))])["ok"])
	assert_eq(wizard_match.get_active_effects().size(), 1)
	assert_true(wizard_match.finish_preparation_phase())
	assert_true(wizard_match.apply_move_action(
		wizard_match.chess_engine.create_move_action(_sq("a2"), _sq("a3"))
	)["ok"])
	assert_true(wizard_match.pass_reaction_phase())
	assert_true(wizard_match.pass_reaction_phase())
	assert_true(wizard_match.resolve_end_phase())
	assert_true(wizard_match.resolve_beginning_phase())
	assert_true(wizard_match.finish_preparation_phase())
	assert_true(wizard_match.apply_move_action(
		wizard_match.chess_engine.create_move_action(_sq("e7"), _sq("e5"))
	)["ok"])

	white_state = wizard_match.get_player_state(ChessMatch.WHITE)
	assert_eq(white_state["battlefield"].size(), 0)
	assert_eq(white_state["graveyard"].size(), 1)
	assert_eq(wizard_match.get_active_effects().size(), 0)


func test_environment_replaces_previous_environment_and_artifact_persists() -> void:
	var rules := _make_rules()
	rules.mana_gained_per_turn = 3
	var wizard_match := WizardMatch.new(rules)
	var environment_a := _make_card(CardDefinition.TYPE_ENVIRONMENT, 1, "blizzard")
	environment_a.effect_tags = PackedStringArray(["slow"])
	var environment_b := _make_card(CardDefinition.TYPE_ENVIRONMENT, 1, "holy_ground")
	environment_b.effect_tags = PackedStringArray(["sanctified"])
	var artifact := _make_card(CardDefinition.TYPE_ARTIFACT, 1, "crystal_ball")
	artifact.effect_tags = PackedStringArray(["scry"])
	var white_deck := DeckDefinition.new()
	white_deck.cards = [environment_a, environment_b, artifact]
	var black_deck := _make_uniform_deck(_make_card(CardDefinition.TYPE_SPELL, 0, "black_spell"))

	assert_true(wizard_match.start_match(white_deck, black_deck, 12)["ok"])
	assert_true(wizard_match.keep_opening_hand(ChessMatch.WHITE)["ok"])
	assert_true(wizard_match.keep_opening_hand(ChessMatch.BLACK)["ok"])
	assert_true(wizard_match.resolve_beginning_phase())

	var white_state := wizard_match.get_player_state(ChessMatch.WHITE)
	assert_true(wizard_match.play_card_from_hand(_hand_card_instance_id(white_state, "blizzard"))["ok"])
	assert_true(wizard_match.play_card_from_hand(_hand_card_instance_id(wizard_match.get_player_state(ChessMatch.WHITE), "holy_ground"))["ok"])
	assert_true(wizard_match.play_card_from_hand(_hand_card_instance_id(wizard_match.get_player_state(ChessMatch.WHITE), "crystal_ball"))["ok"])

	white_state = wizard_match.get_player_state(ChessMatch.WHITE)
	assert_eq(white_state["battlefield"].size(), 2)
	assert_eq(white_state["graveyard"].size(), 1)
	var active_effect_ids := []
	for effect_value in wizard_match.get_active_effects():
		active_effect_ids.append(effect_value["source_card_id"])
	assert_eq(active_effect_ids.size(), 2)
	assert_has(active_effect_ids, "holy_ground")
	assert_has(active_effect_ids, "crystal_ball")


func test_chess_move_is_phase_gated_and_advances_to_reaction() -> void:
	var wizard_match := _start_active_match()

	assert_true(wizard_match.resolve_beginning_phase())
	assert_true(wizard_match.finish_preparation_phase())

	var move_result := wizard_match.apply_move_action(
		wizard_match.chess_engine.create_move_action(_sq("e2"), _sq("e4"))
	)

	assert_true(move_result["ok"])
	assert_eq(wizard_match.phase, WizardMatch.PHASE_REACTION)
	assert_eq(wizard_match.chess_engine.to_fen(), "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1")


func test_end_phase_requires_explicit_hand_limit_discard() -> void:
	var rules := _make_rules()
	rules.maximum_hand_size = 2
	var wizard_match := _start_active_match(rules)

	assert_true(wizard_match.resolve_beginning_phase())
	assert_true(wizard_match.finish_preparation_phase())
	assert_true(wizard_match.apply_move_action(
		wizard_match.chess_engine.create_move_action(_sq("e2"), _sq("e4"))
	)["ok"])
	assert_true(wizard_match.pass_reaction_phase())
	assert_true(wizard_match.pass_reaction_phase())
	assert_true(wizard_match.resolve_end_phase())

	assert_eq(wizard_match.get_pending_hand_limit_discard_count(ChessMatch.WHITE), 1)
	var white_state := wizard_match.get_player_state(ChessMatch.WHITE)
	var discard_id := str(white_state["hand"][0]["instance_id"])
	assert_true(wizard_match.discard_cards_for_hand_limit([discard_id])["ok"])

	white_state = wizard_match.get_player_state(ChessMatch.WHITE)
	assert_eq(white_state["hand"].size(), 2)
	assert_eq(white_state["graveyard"].size(), 1)
	assert_eq(wizard_match.phase, WizardMatch.PHASE_BEGINNING)
	assert_eq(wizard_match.turn_number, 2)


func test_snapshot_round_trip_preserves_framework_state() -> void:
	var wizard_match := _start_active_match()

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
	assert_not_null(card.art_texture)
	assert_eq(card.art_texture.resource_path, "res://assets/ui/wizard_match/arcane_card_art.png")
	assert_not_null(deck)
	assert_eq(deck.card_count(), 6)


func test_runtime_cards_preserve_authored_art_texture_path() -> void:
	var card := _make_card(CardDefinition.TYPE_SPELL, 1, "spell_with_art")
	card.art_texture = load("res://assets/ui/wizard_match/order_card_art.png") as Texture2D
	var deck := _make_uniform_deck(card)
	var wizard_match := WizardMatch.new(_make_rules())

	assert_true(wizard_match.start_match(deck, deck, 18)["ok"])

	var white_state := wizard_match.get_player_state(ChessMatch.WHITE)
	assert_eq(white_state["hand"][0]["art_texture_path"], "res://assets/ui/wizard_match/order_card_art.png")


func test_deck_validation_rejects_oversized_legendary_copies() -> void:
	var rules := _make_rules()
	var wizard_match := WizardMatch.new(rules)
	var legendary := _make_card(CardDefinition.TYPE_ARTIFACT, 0, "legendary_artifact")
	legendary.rarity = CardDefinition.RARITY_LEGENDARY
	var illegal_deck := DeckDefinition.new()
	illegal_deck.cards = [legendary, legendary, legendary]
	var legal_deck := _make_uniform_deck(_make_card(CardDefinition.TYPE_SPELL, 0, "legal_spell"))

	var result := wizard_match.start_match(illegal_deck, legal_deck, 15)

	assert_false(result["ok"])
	assert_eq(result["reason"], "too_many_legendary_copies")


func _start_active_match(rules: WizardMatchRules = null) -> WizardMatch:
	var match_rules := rules if rules != null else _make_rules()
	var wizard_match := WizardMatch.new(match_rules)
	var deck := _make_mixed_deck()
	assert_true(wizard_match.start_match(deck, deck, 11)["ok"])
	assert_true(wizard_match.keep_opening_hand(ChessMatch.WHITE)["ok"])
	assert_true(wizard_match.keep_opening_hand(ChessMatch.BLACK)["ok"])
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
	deck.cards = [card, card.duplicate(true), card.duplicate(true)]
	return deck


func _make_card(card_type: String, mana_cost: int, card_id: String, target_requirements: Array = []) -> CardDefinition:
	var card := CardDefinition.new()
	card.card_id = card_id
	card.display_name = card_id.capitalize()
	card.card_type = card_type
	card.mana_cost = mana_cost
	card.school = "Prototype"
	card.target_requirements = PackedStringArray(target_requirements)
	card.effect_tags = PackedStringArray()
	return card


func _sq(value: String) -> Vector2i:
	return ChessMatch.new().algebraic_to_square(value)


func _hand_card_instance_id(player_state: Dictionary, card_id: String) -> String:
	for card_state in player_state["hand"]:
		if str(card_state["card_id"]) == card_id:
			return str(card_state["instance_id"])
	return ""
