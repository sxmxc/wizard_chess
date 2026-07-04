extends GutTest

const SAMPLE_AI_DECK_PATH := "res://content/decks/sample_ai_battle_deck.tres"
const BEGINNER_AI_PATH := "res://content/ai/beginner_aggressive_ai.tres"
const INTERMEDIATE_AI_PATH := "res://content/ai/intermediate_positional_ai.tres"


func test_ai_setup_choice_is_deterministic() -> void:
	var match_a := _make_match()
	var match_b := _make_match()
	var white_ai := _load_ai(BEGINNER_AI_PATH)

	assert_true(match_a.start_match(_load_deck(), _load_deck(), 21)["ok"])
	assert_true(match_b.start_match(_load_deck(), _load_deck(), 21)["ok"])

	var action_a := white_ai.choose_next_action(match_a, ChessMatch.WHITE)
	var action_b := white_ai.choose_next_action(match_b, ChessMatch.WHITE)

	assert_eq(action_a, action_b)
	assert_true(action_a.has("type"))


func test_ai_executes_legal_turn_actions_through_move_phase() -> void:
	var wizard_match := _make_match()
	var white_ai := _load_ai(BEGINNER_AI_PATH)
	var black_ai := _load_ai(INTERMEDIATE_AI_PATH)

	assert_true(wizard_match.start_match(_load_deck(), _load_deck(), 22)["ok"])
	assert_true(white_ai.apply_next_action(wizard_match, ChessMatch.WHITE)["ok"])
	assert_true(black_ai.apply_next_action(wizard_match, ChessMatch.BLACK)["ok"])

	var safety_limit := 8
	while safety_limit > 0 and wizard_match.phase != WizardMatch.PHASE_REACTION:
		safety_limit -= 1
		assert_true(white_ai.apply_next_action(wizard_match, ChessMatch.WHITE)["ok"])

	assert_eq(wizard_match.phase, WizardMatch.PHASE_REACTION)
	assert_eq(wizard_match.chess_state.move_history.size(), 1)
	assert_eq(wizard_match.reaction_priority_color, ChessMatch.WHITE)


func test_ai_self_play_can_finish_forced_match() -> void:
	var wizard_match := _make_match()
	var white_ai := _load_ai(BEGINNER_AI_PATH)
	var black_ai := _load_ai(INTERMEDIATE_AI_PATH)

	assert_true(wizard_match.start_match(_load_deck(), _load_deck(), 23)["ok"])
	assert_true(white_ai.apply_next_action(wizard_match, ChessMatch.WHITE)["ok"])
	assert_true(black_ai.apply_next_action(wizard_match, ChessMatch.BLACK)["ok"])

	wizard_match.chess_engine.load_fen("7k/6Q1/6K1/8/8/8/8/8 w - - 0 1")

	var safety_limit := 12
	while safety_limit > 0 and wizard_match.state != WizardMatch.STATE_COMPLETE:
		safety_limit -= 1
		var actor := _current_actor_color(wizard_match)
		var controller := white_ai if actor == ChessMatch.WHITE else black_ai
		assert_true(controller.apply_next_action(wizard_match, actor)["ok"])

	assert_eq(wizard_match.state, WizardMatch.STATE_COMPLETE)
	assert_eq(wizard_match.chess_state.outcome["status"], ChessMatch.STATUS_CHECKMATE)
	assert_eq(wizard_match.chess_state.outcome["winner"], ChessMatch.WHITE)


func _make_match() -> WizardMatch:
	var rules := load("res://content/config/default_wizard_match_rules.tres") as WizardMatchRules
	return WizardMatch.new(rules)


func _load_ai(resource_path: String) -> WizardMatchAiController:
	return WizardMatchAiController.new(load(resource_path) as WizardMatchAiProfile)


func _load_deck() -> DeckDefinition:
	return CardCatalog.load_deck_definition(SAMPLE_AI_DECK_PATH)


func _current_actor_color(wizard_match: WizardMatch) -> String:
	if wizard_match.state == WizardMatch.STATE_SETUP:
		for color in [ChessMatch.WHITE, ChessMatch.BLACK]:
			if bool(wizard_match.get_player_state(color).get("mulligan_available", false)):
				return color
		return ""
	if wizard_match.phase in [WizardMatch.PHASE_BEGINNING, WizardMatch.PHASE_PREPARATION, WizardMatch.PHASE_MOVE]:
		return wizard_match.chess_state.active_color
	if wizard_match.phase == WizardMatch.PHASE_REACTION:
		return wizard_match.reaction_priority_color
	for color in [ChessMatch.WHITE, ChessMatch.BLACK]:
		if wizard_match.get_pending_hand_limit_discard_count(color) > 0:
			return color
	return ChessMatch.BLACK if wizard_match.chess_state.active_color == ChessMatch.WHITE else ChessMatch.WHITE
