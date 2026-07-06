extends GutTest

const NETWORK_WIZARD_MATCH_SCREEN_PATH := "res://scenes/chess/network_wizard_match_screen.tscn"


class FakeBridge extends NetworkMatchBridge:
	var submitted_actions: Array[Dictionary] = []
	var reset_requested := false

	func submit_local_action(action: Dictionary) -> void:
		submitted_actions.append(action.duplicate(true))

	func reset_match() -> bool:
		reset_requested = true
		return true


func test_network_wizard_match_screen_reuses_local_wizard_ui_and_submits_actions_through_bridge() -> void:
	var bootstrap := Node.new()
	bootstrap.name = "Bootstrap"
	get_tree().root.add_child(bootstrap)
	autofree(bootstrap)

	var network_root := Node.new()
	network_root.name = "NetworkRoot"
	bootstrap.add_child(network_root)

	var bridge := FakeBridge.new()
	bridge.name = "MatchBridge"
	network_root.add_child(bridge)

	var deck := _make_deck()
	bridge.wizard_match = WizardMatch.new(_make_rules())
	assert_true(bridge.wizard_match.start_match(deck, deck, 17)["ok"])
	var local_player_id := bridge._create_player_session(ChessEngine.WHITE)
	bridge.local_player_id = local_player_id
	bridge.players_by_id[local_player_id]["connected"] = true

	var packed_scene := load(NETWORK_WIZARD_MATCH_SCREEN_PATH) as PackedScene
	assert_not_null(packed_scene)

	var screen = packed_scene.instantiate()
	bootstrap.add_child(screen)
	autofree(screen)

	assert_eq(screen.match_bridge, bridge)
	assert_not_null(screen.board_view)
	assert_eq(screen.ai_enabled_by_color[ChessEngine.WHITE], false)
	assert_eq(screen.ai_enabled_by_color[ChessEngine.BLACK], false)
	assert_true(screen.match_sidebar.white_ai_button.disabled)
	assert_true(screen.match_sidebar.black_ai_button.disabled)
	assert_eq(screen._display_color(), ChessEngine.WHITE)
	assert_true(screen.status_label.text.contains("Seat: White"))

	screen._on_keep_hand_pressed()
	assert_eq(bridge.submitted_actions.size(), 1)
	assert_eq(str(bridge.submitted_actions[0].get("type", "")), WizardMatch.ACTION_TYPE_KEEP_OPENING_HAND)
	assert_string_contains(screen.match_sidebar.last_ai_action_label.text, "pending server")

	screen._on_new_match_pressed()
	assert_true(bridge.reset_requested)


func test_network_wizard_match_screen_presents_black_client_as_local_owner() -> void:
	var bootstrap := Node.new()
	bootstrap.name = "Bootstrap"
	get_tree().root.add_child(bootstrap)
	autofree(bootstrap)

	var network_root := Node.new()
	network_root.name = "NetworkRoot"
	bootstrap.add_child(network_root)

	var bridge := FakeBridge.new()
	bridge.name = "MatchBridge"
	network_root.add_child(bridge)

	var deck := _make_deck()
	bridge.wizard_match = WizardMatch.new(_make_rules())
	assert_true(bridge.wizard_match.start_match(deck, deck, 17)["ok"])
	var local_player_id := bridge._create_player_session(ChessEngine.BLACK)
	bridge.local_player_id = local_player_id
	bridge.players_by_id[local_player_id]["connected"] = true

	var packed_scene := load(NETWORK_WIZARD_MATCH_SCREEN_PATH) as PackedScene
	var screen = packed_scene.instantiate()
	bootstrap.add_child(screen)
	autofree(screen)

	assert_eq(screen._display_color(), ChessEngine.BLACK)
	assert_eq(screen.local_hand_title_label.text, "Black Hand")
	assert_eq(screen.opponent_hand_title_label.text, "White Hand")
	assert_eq(screen.local_status_view.player_color, ChessEngine.BLACK)
	assert_eq(screen.opponent_status_view.player_color, ChessEngine.WHITE)
	assert_eq(screen.local_status_view.portrait_texture, screen.black_portrait_texture)
	assert_eq(screen.opponent_status_view.portrait_texture, screen.white_portrait_texture)
	assert_eq(screen.board_view.square_at_global_position(screen.board_view.get_square_center_global(Vector2i(0, 0))), Vector2i(0, 0))


func test_network_wizard_match_screen_submits_targeted_card_plays_through_bridge() -> void:
	var bootstrap := Node.new()
	bootstrap.name = "Bootstrap"
	get_tree().root.add_child(bootstrap)
	autofree(bootstrap)

	var network_root := Node.new()
	network_root.name = "NetworkRoot"
	bootstrap.add_child(network_root)

	var bridge := FakeBridge.new()
	bridge.name = "MatchBridge"
	network_root.add_child(bridge)

	var rules := _make_rules()
	rules.mana_gained_per_turn = 1
	var trap_card := CardDefinition.new()
	trap_card.card_id = "network_targeted_trap"
	trap_card.display_name = "Network Targeted Trap"
	trap_card.card_type = CardDefinition.TYPE_TRAP
	trap_card.school = "Prototype"
	trap_card.target_requirements = PackedStringArray(["Play on empty square."])
	var trap_deck := DeckDefinition.new()
	trap_deck.cards = [trap_card, trap_card.duplicate(true), trap_card.duplicate(true)]
	bridge.wizard_match = WizardMatch.new(rules)
	assert_true(bridge.wizard_match.start_match(trap_deck, _make_deck(), 23)["ok"])
	assert_true(bridge.wizard_match.keep_opening_hand(ChessEngine.WHITE)["ok"])
	assert_true(bridge.wizard_match.keep_opening_hand(ChessEngine.BLACK)["ok"])
	assert_true(bridge.wizard_match.resolve_beginning_phase())
	var local_player_id := bridge._create_player_session(ChessEngine.WHITE)
	bridge.local_player_id = local_player_id
	bridge.players_by_id[local_player_id]["connected"] = true

	var packed_scene := load(NETWORK_WIZARD_MATCH_SCREEN_PATH) as PackedScene
	var screen = packed_scene.instantiate()
	bootstrap.add_child(screen)
	autofree(screen)

	var trap_id := _hand_card_instance_id(bridge.wizard_match.get_player_state(ChessEngine.WHITE), "network_targeted_trap")
	screen.selected_card_instance_id = trap_id
	screen._play_selected_card_on_square(_sq("e5"))

	assert_eq(bridge.submitted_actions.size(), 1)
	assert_eq(str(bridge.submitted_actions[0].get("type", "")), WizardMatch.ACTION_TYPE_PLAY_CARD)
	assert_eq(str(bridge.submitted_actions[0].get("card_instance_id", "")), trap_id)
	assert_eq(str(Array(bridge.submitted_actions[0].get("targets", []))[0].get("square", "")), "e5")


func test_network_wizard_match_screen_renders_battlefield_and_graveyard_from_client_snapshot() -> void:
	var bootstrap := Node.new()
	bootstrap.name = "Bootstrap"
	get_tree().root.add_child(bootstrap)
	autofree(bootstrap)

	var network_root := Node.new()
	network_root.name = "NetworkRoot"
	bootstrap.add_child(network_root)

	var bridge := FakeBridge.new()
	bridge.name = "MatchBridge"
	network_root.add_child(bridge)

	var rules := _make_rules()
	rules.opening_hand_size = 3
	rules.mana_gained_per_turn = 4
	var authoritative_match := WizardMatch.new(rules)
	var white_deck := DeckDefinition.new()
	white_deck.cards = [
		CardCatalog.load_card_definition("res://content/cards/sample_mana_storm.tres"),
		CardCatalog.load_card_definition("res://content/cards/sample_runic_snare.tres"),
		CardCatalog.load_card_definition("res://content/cards/sample_arcane_burst.tres"),
	]
	var black_deck := _make_deck()
	assert_true(authoritative_match.start_match(white_deck, black_deck, 22)["ok"])
	assert_true(authoritative_match.keep_opening_hand(ChessEngine.WHITE)["ok"])
	assert_true(authoritative_match.keep_opening_hand(ChessEngine.BLACK)["ok"])
	assert_true(authoritative_match.resolve_beginning_phase())
	var white_state := authoritative_match.get_player_state(ChessEngine.WHITE)
	assert_true(authoritative_match.play_card_from_hand(_hand_card_instance_id(white_state, "sample_mana_storm"))["ok"])
	white_state = authoritative_match.get_player_state(ChessEngine.WHITE)
	assert_true(authoritative_match.play_card_from_hand(
		_hand_card_instance_id(white_state, "sample_runic_snare"),
		[authoritative_match.create_square_target(_sq("e5"))]
	)["ok"])
	white_state = authoritative_match.get_player_state(ChessEngine.WHITE)
	assert_true(authoritative_match.play_card_from_hand(_hand_card_instance_id(white_state, "sample_arcane_burst"))["ok"])

	bridge.wizard_match.load_state_snapshot(authoritative_match.create_network_snapshot(ChessEngine.WHITE))
	var local_player_id := bridge._create_player_session(ChessEngine.WHITE)
	bridge.local_player_id = local_player_id
	bridge.players_by_id[local_player_id]["connected"] = true

	var packed_scene := load(NETWORK_WIZARD_MATCH_SCREEN_PATH) as PackedScene
	var screen = packed_scene.instantiate()
	bootstrap.add_child(screen)
	autofree(screen)

	assert_eq(screen.environment_zone_panel.body_label.text, "1")
	assert_eq(screen.traps_zone_panel.body_label.text, "1")
	assert_eq(screen.local_graveyard_pile.count_label.text, "1")
	assert_true(screen.environment_zone_panel.visual_slots[0].visible)
	assert_true(screen.traps_zone_panel.visual_slots[0].visible)
	assert_true(screen.local_graveyard_pile.top_card_widget.visible)


func _make_rules() -> WizardMatchRules:
	var rules := WizardMatchRules.new()
	rules.opening_hand_size = 3
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
	card.card_id = "network_ui_spell"
	card.display_name = "Network UI Spell"
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
