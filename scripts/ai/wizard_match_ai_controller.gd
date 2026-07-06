extends RefCounted
class_name WizardMatchAiController

const MATE_SCORE := 100000.0
const LOG_THRESHOLD_USEC := 20_000

var profile: WizardMatchAiProfile
var last_timing_report := {}
var _active_timing_report := {}


func _init(ai_profile: WizardMatchAiProfile = null) -> void:
	profile = ai_profile if ai_profile != null else _make_default_profile()


func build_turn_plan(match: WizardMatch, color: String) -> Array:
	if not _is_action_window_for_color(match, color):
		return []

	_begin_timing_report(match, color)
	_active_timing_report["planning_mode"] = "full_turn"
	var clone_started_usec := Time.get_ticks_usec()
	var simulated := match.clone()
	_add_timing("clone_usec", Time.get_ticks_usec() - clone_started_usec)
	var plan: Array = []
	var preparation_cards_played := 0

	while true:
		var selection_started_usec := Time.get_ticks_usec()
		var action := _choose_action_for_current_state(simulated, color, preparation_cards_played)
		_add_timing("action_selection_usec", Time.get_ticks_usec() - selection_started_usec)
		if action.is_empty():
			break

		plan.append(action)
		var apply_started_usec := Time.get_ticks_usec()
		if not _apply_planned_action(simulated, action):
			_add_timing("action_apply_usec", Time.get_ticks_usec() - apply_started_usec)
			break
		_add_timing("action_apply_usec", Time.get_ticks_usec() - apply_started_usec)
		_increment_timing("planned_actions")

		if action["type"] == "play_card":
			preparation_cards_played += 1

		if simulated.state == WizardMatch.STATE_COMPLETE:
			break
		if not _is_action_window_for_color(simulated, color):
			break

	_finish_timing_report(plan)
	return plan


func choose_next_action(match: WizardMatch, color: String) -> Dictionary:
	return _choose_next_action_internal(match, color)


func apply_next_action(match: WizardMatch, color: String) -> Dictionary:
	var action := choose_next_action(match, color)
	if action.is_empty():
		return {
			"ok": false,
			"reason": "no_action_available",
		}
	return _apply_planned_action(match, action)


func preview_turn_plan(match: WizardMatch, color: String) -> Array:
	return build_turn_plan(match, color)


func _choose_action_for_current_state(match: WizardMatch, color: String, preparation_cards_played: int) -> Dictionary:
	if match.state == WizardMatch.STATE_SETUP:
		return _choose_setup_action(match, color)
	if match.state != WizardMatch.STATE_ACTIVE:
		return {}

	if match.phase == WizardMatch.PHASE_BEGINNING:
		return {"type": "resolve_beginning_phase"}

	if match.phase == WizardMatch.PHASE_PREPARATION:
		if preparation_cards_played < profile.max_preparation_cards_per_turn:
			var card_action := _choose_best_card_action(match, color, false)
			if not card_action.is_empty():
				return card_action
		return {"type": "finish_preparation_phase"}

	if match.phase == WizardMatch.PHASE_MOVE:
		return _choose_best_move_action(match, color)

	if match.phase == WizardMatch.PHASE_REACTION:
		var reaction_action := _choose_best_card_action(match, color, true)
		if not reaction_action.is_empty():
			return reaction_action
		return {"type": "pass_reaction_phase"}

	if match.phase == WizardMatch.PHASE_END:
		var discard_count := match.get_pending_hand_limit_discard_count(color)
		if discard_count > 0:
			return _choose_hand_limit_discard(match, color, discard_count)
		return {"type": "resolve_end_phase"}

	return {}


func _choose_next_action_internal(match: WizardMatch, color: String) -> Dictionary:
	if not _is_action_window_for_color(match, color):
		return {}

	_begin_timing_report(match, color)
	_active_timing_report["planning_mode"] = "single_action"

	var preparation_cards_played := 0
	if match.phase == WizardMatch.PHASE_PREPARATION:
		preparation_cards_played = _estimate_preparation_cards_played(match, color)

	var selection_started_usec := Time.get_ticks_usec()
	var action := _choose_action_for_current_state(match, color, preparation_cards_played)
	_add_timing("action_selection_usec", Time.get_ticks_usec() - selection_started_usec)
	var report_plan: Array = []
	if not action.is_empty():
		report_plan.append(action)
	_finish_timing_report(report_plan)
	return action


func _choose_setup_action(match: WizardMatch, color: String) -> Dictionary:
	var player_state := match.get_player_state(color)
	if not bool(player_state.get("mulligan_available", false)):
		return {}

	var hand: Array = player_state.get("hand", [])
	var high_cost_ids: Array[String] = []
	for card_state_value in hand:
		var card_state: Dictionary = card_state_value
		if int(card_state.get("mana_cost", 0)) >= 2:
			high_cost_ids.append(str(card_state["instance_id"]))

	var should_mulligan := false
	match profile.difficulty:
		WizardMatchAiProfile.DIFFICULTY_BEGINNER:
			should_mulligan = hand.size() > 0 and high_cost_ids.size() == hand.size()
		WizardMatchAiProfile.DIFFICULTY_INTERMEDIATE:
			should_mulligan = high_cost_ids.size() >= max(1, hand.size() - 1)
		_:
			should_mulligan = float(high_cost_ids.size()) > float(hand.size()) * 0.5

	if should_mulligan and not high_cost_ids.is_empty():
		return {
			"type": "perform_mulligan",
			"color": color,
			"card_instance_ids": high_cost_ids,
		}
	return {
		"type": "keep_opening_hand",
		"color": color,
	}


func _choose_best_card_action(match: WizardMatch, color: String, reaction_only: bool) -> Dictionary:
	var best_action := {}
	var best_score := profile.card_play_threshold
	var action_fetch_started_usec := Time.get_ticks_usec()
	var legal_actions := match.get_legal_card_actions(color)
	_add_timing("card_action_enumeration_usec", Time.get_ticks_usec() - action_fetch_started_usec)
	_increment_timing("card_action_batches")
	_add_timing("card_action_candidates", legal_actions.size())
	for action_value in legal_actions:
		var action: Dictionary = action_value
		var scoring_started_usec := Time.get_ticks_usec()
		var score := _score_card_action(match, color, action, reaction_only)
		_add_timing("card_scoring_usec", Time.get_ticks_usec() - scoring_started_usec)
		if score <= best_score:
			continue
		if score == best_score and _card_action_sort_key(action) >= _card_action_sort_key(best_action):
			continue
		best_score = score
		best_action = {
			"type": "play_card",
			"card_instance_id": str(action["card_instance_id"]),
			"targets": action.get("targets", []).duplicate(true),
			"score": score,
		}
	return best_action


func _choose_best_move_action(match: WizardMatch, color: String) -> Dictionary:
	var move_gen_started_usec := Time.get_ticks_usec()
	var legal_moves := match.chess_engine.get_legal_moves_for_color(color)
	_add_timing("move_generation_usec", Time.get_ticks_usec() - move_gen_started_usec)
	_add_timing("legal_move_count", legal_moves.size())
	if legal_moves.is_empty():
		return {}
	legal_moves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _move_order_score(a) > _move_order_score(b)
	)
	legal_moves = _trim_moves(legal_moves, profile.max_root_moves_considered)
	_add_timing("root_moves_considered", legal_moves.size())

	var best_move: Dictionary = legal_moves[0]
	var best_score := -INF
	for move_value in legal_moves:
		var move: Dictionary = move_value
		var move_score_started_usec := Time.get_ticks_usec()
		var score := _score_move(match.chess_engine, move, color)
		_add_timing("move_scoring_usec", Time.get_ticks_usec() - move_score_started_usec)
		var move_key := _move_sort_key(move)
		if score > best_score or (is_equal_approx(score, best_score) and move_key < _move_sort_key(best_move)):
			best_score = score
			best_move = move
	return {
		"type": "move",
		"action": match.chess_engine.create_move_action(
			best_move["from"],
			best_move["to"],
			str(best_move.get("promotion", ""))
		),
		"score": best_score,
	}


func _choose_hand_limit_discard(match: WizardMatch, color: String, discard_count: int) -> Dictionary:
	var player_state := match.get_player_state(color)
	var scored_cards: Array = []
	for card_state_value in player_state.get("hand", []):
		var card_state: Dictionary = card_state_value
		scored_cards.append({
			"instance_id": str(card_state["instance_id"]),
			"score": _score_card_state_for_retention(match, color, card_state),
		})

	scored_cards.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(float(a["score"]), float(b["score"])):
			return float(a["score"]) < float(b["score"])
		return str(a["instance_id"]) < str(b["instance_id"])
	)

	var discard_ids: Array[String] = []
	for index in range(min(discard_count, scored_cards.size())):
		discard_ids.append(str(scored_cards[index]["instance_id"]))
	return {
		"type": "discard_cards_for_hand_limit",
		"card_instance_ids": discard_ids,
	}


func _score_card_action(match: WizardMatch, color: String, action: Dictionary, reaction_only: bool) -> float:
	var player_state := match.get_player_state(color)
	var hand: Array = player_state.get("hand", [])
	var card_state := {}
	for card_state_value in hand:
		var candidate: Dictionary = card_state_value
		if str(candidate["instance_id"]) == str(action["card_instance_id"]):
			card_state = candidate
			break
	if card_state.is_empty():
		return -INF

	var card_type := str(card_state.get("card_type", ""))
	if reaction_only and card_type != CardDefinition.TYPE_REACTION:
		return -INF

	var score := _score_card_state_for_retention(match, color, card_state)
	score -= float(card_state.get("mana_cost", 0)) * 0.1

	var targets: Array = action.get("targets", [])
	if card_type == CardDefinition.TYPE_UNIT:
		score += 1.0
		if not targets.is_empty():
			score += _score_piece_target(match, color, targets[0]) * 0.35
	elif card_type == CardDefinition.TYPE_TRAP:
		score += 0.8 * profile.trap_weight
		if not targets.is_empty():
			score += _score_trap_target(match, color, targets[0])
	elif card_type == CardDefinition.TYPE_REACTION:
		score += 0.9 * profile.reaction_weight
		if not targets.is_empty():
			score += _score_piece_target(match, color, targets[0]) * 0.2
	elif card_type == CardDefinition.TYPE_ENVIRONMENT:
		score += 0.7 * profile.position_weight
		if _has_battlefield_card_type(player_state.get("battlefield", []), CardDefinition.TYPE_ENVIRONMENT):
			score -= 0.35
	elif card_type == CardDefinition.TYPE_ARTIFACT:
		score += 0.65 * profile.defense_weight
	elif card_type == CardDefinition.TYPE_SPELL:
		score += 0.35
		if not targets.is_empty():
			score += _score_piece_target(match, color, targets[0]) * 0.2

	if match.phase == WizardMatch.PHASE_REACTION:
		score += 0.4 * profile.reaction_weight
	return score


func _score_card_state_for_retention(match: WizardMatch, color: String, card_state: Dictionary) -> float:
	var card_type := str(card_state.get("card_type", ""))
	var mana_cost := float(card_state.get("mana_cost", 0))
	var score := 0.4 - mana_cost * 0.05
	match card_type:
		CardDefinition.TYPE_UNIT:
			score += 0.9 * profile.defense_weight
		CardDefinition.TYPE_REACTION:
			score += 0.8 * profile.reaction_weight
		CardDefinition.TYPE_TRAP:
			score += 0.7 * profile.trap_weight
		CardDefinition.TYPE_ENVIRONMENT:
			score += 0.6 * profile.position_weight
		CardDefinition.TYPE_ARTIFACT:
			score += 0.55 * profile.defense_weight
		CardDefinition.TYPE_SPELL:
			score += 0.35 * profile.aggression_weight

	var current_mana := int(match.get_player_state(color).get("mana", 0))
	if mana_cost > current_mana + 1:
		score -= 0.2
	return score


func _score_piece_target(match: WizardMatch, color: String, target: Dictionary) -> float:
	var square_name := str(target.get("square", ""))
	if square_name.is_empty():
		return 0.0
	var square := match.chess_engine.algebraic_to_square(square_name)
	var piece = match.chess_engine.get_piece(square)
	if piece == null:
		return 0.0

	var piece_value := _piece_value(str(piece["type"]))
	var score := piece_value * 0.08
	var under_attack := match.chess_engine.is_square_attacked(square, _opponent(str(piece["color"])))
	if str(piece["color"]) == color and under_attack:
		score += 0.6 * profile.defense_weight
	elif str(piece["color"]) != color and under_attack:
		score += 0.3 * profile.aggression_weight
	return score


func _score_trap_target(match: WizardMatch, color: String, target: Dictionary) -> float:
	var square_name := str(target.get("square", ""))
	if square_name.is_empty():
		return 0.0
	var square := match.chess_engine.algebraic_to_square(square_name)
	var enemy_color := _opponent(color)
	var enemy_moves := match.chess_engine.get_legal_moves_for_color(enemy_color)
	var potential_triggers := 0
	for move_value in enemy_moves:
		var move: Dictionary = move_value
		if move["to"] == square:
			potential_triggers += 1

	var centrality: float = 3.5 - max(absf(float(square.x) - 3.5), absf(float(square.y) - 3.5))
	return float(potential_triggers) * 0.25 + centrality * 0.08


func _score_move(chess_engine: ChessEngine, move: Dictionary, color: String) -> float:
	var clone_started_usec := Time.get_ticks_usec()
	var simulated := chess_engine.clone()
	simulated.apply_move(move)
	_add_timing("move_simulation_clone_usec", Time.get_ticks_usec() - clone_started_usec)
	var search_started_usec := Time.get_ticks_usec()
	var score := _search_chess(simulated, max(profile.chess_search_depth - 1, 0), color, -INF, INF)
	_add_timing("search_usec", Time.get_ticks_usec() - search_started_usec)
	return score


func _search_chess(chess_position: ChessEngine, depth: int, perspective: String, alpha: float, beta: float) -> float:
	_increment_timing("search_nodes")
	if depth <= 0 or chess_position.outcome["status"] != ChessEngine.STATUS_ACTIVE:
		_increment_timing("search_leaf_nodes")
		return _evaluate_chess_position(chess_position, perspective)

	var legal_moves := chess_position.get_legal_moves_for_color(chess_position.active_color)
	if legal_moves.is_empty():
		return _evaluate_chess_position(chess_position, perspective)
	legal_moves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _move_order_score(a) > _move_order_score(b)
	)
	legal_moves = _trim_moves(legal_moves, profile.max_search_branching)

	var maximizing := chess_position.active_color == perspective
	var best_score := -INF if maximizing else INF
	for move_value in legal_moves:
		var move: Dictionary = move_value
		var simulated := chess_position.clone()
		simulated.apply_move(move)
		var score := _search_chess(simulated, depth - 1, perspective, alpha, beta)
		if maximizing:
			best_score = max(best_score, score)
			alpha = max(alpha, best_score)
		else:
			best_score = min(best_score, score)
			beta = min(beta, best_score)
		if beta <= alpha:
			_increment_timing("search_cutoffs")
			break
	return best_score


func get_last_timing_report() -> Dictionary:
	return last_timing_report.duplicate(true)


func format_last_timing_report() -> String:
	if last_timing_report.is_empty():
		return "AI timings: no samples yet"
	return "AI timings %s %s %s %s | total %.2f ms | clone %.2f | select %.2f | apply %.2f | move gen %.2f | move score %.2f | card enum %.2f | card score %.2f | search %.2f | nodes %d" % [
		str(last_timing_report.get("profile_id", "")),
		str(last_timing_report.get("color", "")),
		str(last_timing_report.get("phase", "")),
		str(last_timing_report.get("planning_mode", "")),
		_usec_to_msec(int(last_timing_report.get("total_usec", 0))),
		_usec_to_msec(int(last_timing_report.get("clone_usec", 0))),
		_usec_to_msec(int(last_timing_report.get("action_selection_usec", 0))),
		_usec_to_msec(int(last_timing_report.get("action_apply_usec", 0))),
		_usec_to_msec(int(last_timing_report.get("move_generation_usec", 0))),
		_usec_to_msec(int(last_timing_report.get("move_scoring_usec", 0))),
		_usec_to_msec(int(last_timing_report.get("card_action_enumeration_usec", 0))),
		_usec_to_msec(int(last_timing_report.get("card_scoring_usec", 0))),
		_usec_to_msec(int(last_timing_report.get("search_usec", 0))),
		int(last_timing_report.get("search_nodes", 0)),
	]


func _evaluate_chess_position(chess_position: ChessEngine, perspective: String) -> float:
	var outcome := chess_position.outcome
	if outcome["status"] == ChessEngine.STATUS_CHECKMATE:
		return MATE_SCORE if str(outcome["winner"]) == perspective else -MATE_SCORE
	if outcome["status"] in [ChessEngine.STATUS_DRAW, ChessEngine.STATUS_STALEMATE]:
		return 0.0

	var material := 0.0
	var center_control := 0.0
	var king_safety := 0.0
	for rank in range(8):
		for file in range(8):
			var square := Vector2i(file, rank)
			var piece = chess_position.get_piece(square)
			if piece == null:
				continue
			var perspective_sign := 1.0 if str(piece["color"]) == perspective else -1.0
			material += perspective_sign * _piece_value(str(piece["type"]))
			if square in [Vector2i(3, 3), Vector2i(4, 3), Vector2i(3, 4), Vector2i(4, 4)]:
				center_control += perspective_sign * 0.25
			if str(piece["type"]) == ChessEngine.PIECE_KING:
				var attackers := 1.0 if chess_position.is_square_attacked(square, _opponent(str(piece["color"]))) else 0.0
				king_safety += (-attackers if perspective_sign > 0.0 else attackers) * 0.75

	var mobility := float(chess_position.get_legal_moves_for_color(perspective).size() - chess_position.get_legal_moves_for_color(_opponent(perspective)).size()) * 0.05
	var check_pressure := 0.0
	if chess_position.is_in_check(_opponent(perspective)):
		check_pressure += 0.45 * profile.aggression_weight
	if chess_position.is_in_check(perspective):
		check_pressure -= 0.55 * profile.defense_weight

	return (
		material
		+ center_control * profile.position_weight
		+ mobility
		+ king_safety * profile.defense_weight
		+ check_pressure
	)


func _apply_planned_action(match: WizardMatch, action: Dictionary) -> Dictionary:
	match str(action.get("type", "")):
		"keep_opening_hand":
			return match.keep_opening_hand(str(action.get("color", _actor_for_setup(match))))
		"perform_mulligan":
			return match.perform_mulligan(str(action.get("color", _actor_for_setup(match))), action.get("card_instance_ids", []))
		"resolve_beginning_phase":
			return {"ok": match.resolve_beginning_phase()}
		"finish_preparation_phase":
			return {"ok": match.finish_preparation_phase()}
		"play_card":
			return match.play_card_from_hand(str(action["card_instance_id"]), action.get("targets", []))
		"move":
			return match.apply_move_action(action.get("action", {}))
		"pass_reaction_phase":
			return {"ok": match.pass_reaction_phase()}
		"resolve_end_phase":
			return {"ok": match.resolve_end_phase()}
		"discard_cards_for_hand_limit":
			return match.discard_cards_for_hand_limit(action.get("card_instance_ids", []))
		_:
			return {
				"ok": false,
				"reason": "unknown_planned_action",
			}


func _is_action_window_for_color(match: WizardMatch, color: String) -> bool:
	if match.state == WizardMatch.STATE_SETUP:
		return bool(match.get_player_state(color).get("mulligan_available", false))
	if match.state != WizardMatch.STATE_ACTIVE:
		return false
	if match.phase == WizardMatch.PHASE_BEGINNING or match.phase == WizardMatch.PHASE_PREPARATION or match.phase == WizardMatch.PHASE_MOVE:
		return match.chess_state.active_color == color
	if match.phase == WizardMatch.PHASE_REACTION:
		return match.reaction_priority_color == color
	if match.phase == WizardMatch.PHASE_END:
		return match.get_pending_hand_limit_discard_count(color) > 0 or _end_phase_actor(match) == color
	return false


func _end_phase_actor(match: WizardMatch) -> String:
	return _opponent(match.chess_state.active_color)


func _estimate_preparation_cards_played(_match: WizardMatch, _color: String) -> int:
	return 0


func _actor_for_setup(match: WizardMatch) -> String:
	for color in [ChessEngine.WHITE, ChessEngine.BLACK]:
		if bool(match.get_player_state(color).get("mulligan_available", false)):
			return color
	return ChessEngine.WHITE


func _has_battlefield_card_type(cards: Array, card_type: String) -> bool:
	for card_state_value in cards:
		var card_state: Dictionary = card_state_value
		if str(card_state.get("card_type", "")) == card_type:
			return true
	return false


func _piece_value(piece_type: String) -> float:
	match piece_type:
		ChessEngine.PIECE_PAWN:
			return 1.0
		ChessEngine.PIECE_KNIGHT:
			return 3.1
		ChessEngine.PIECE_BISHOP:
			return 3.25
		ChessEngine.PIECE_ROOK:
			return 5.0
		ChessEngine.PIECE_QUEEN:
			return 9.0
		ChessEngine.PIECE_KING:
			return 0.0
		_:
			return 0.0


func _card_action_sort_key(action: Dictionary) -> String:
	if action.is_empty():
		return "~"
	var target_parts: Array[String] = []
	for target_value in action.get("targets", []):
		var target: Dictionary = target_value
		target_parts.append("%s:%s" % [str(target.get("type", "")), str(target.get("square", ""))])
	target_parts.sort()
	return "%s|%s|%s" % [
		str(action.get("card_id", "")),
		str(action.get("card_instance_id", "")),
		",".join(target_parts),
	]


func _move_sort_key(move: Dictionary) -> String:
	return "%s|%s|%s" % [
		_square_to_algebraic(move["from"]),
		_square_to_algebraic(move["to"]),
		str(move.get("promotion", "")),
	]


func _move_order_score(move: Dictionary) -> float:
	var score := 0.0
	if bool(move.get("is_capture", false)):
		score += 10.0 + _piece_value(str(move.get("captured_piece_type", ""))) - (_piece_value(str(move.get("piece_type", ""))) * 0.1)
	if bool(move.get("is_castle_kingside", false)) or bool(move.get("is_castle_queenside", false)):
		score += 1.5
	if not str(move.get("promotion", "")).is_empty():
		score += 8.0 + _piece_value(str(move.get("promotion", "")))
	if bool(move.get("is_en_passant", false)):
		score += 2.0
	return score


func _trim_moves(moves: Array, limit: int) -> Array:
	if limit <= 0 or moves.size() <= limit:
		return moves
	return moves.slice(0, limit)


func _square_to_algebraic(square: Vector2i) -> String:
	return "%s%d" % [ChessEngine.FILE_LETTERS[square.x], 8 - square.y]


func _opponent(color: String) -> String:
	return ChessEngine.BLACK if color == ChessEngine.WHITE else ChessEngine.WHITE


func _make_default_profile() -> WizardMatchAiProfile:
	var default_profile := WizardMatchAiProfile.new()
	default_profile.profile_id = "default_positional"
	default_profile.display_name = "Default Positional"
	default_profile.difficulty = WizardMatchAiProfile.DIFFICULTY_INTERMEDIATE
	default_profile.personality = WizardMatchAiProfile.PERSONALITY_POSITIONAL
	default_profile.chess_search_depth = 2
	default_profile.max_root_moves_considered = 8
	default_profile.max_search_branching = 8
	default_profile.max_preparation_cards_per_turn = 1
	default_profile.card_play_threshold = 0.85
	default_profile.aggression_weight = 1.0
	default_profile.defense_weight = 1.1
	default_profile.position_weight = 1.15
	default_profile.reaction_weight = 1.0
	default_profile.trap_weight = 1.0
	return default_profile


func _begin_timing_report(match: WizardMatch, color: String) -> void:
	_active_timing_report = {
		"profile_id": profile.profile_id,
		"color": color,
		"state": match.state,
		"phase": match.phase,
		"started_usec": Time.get_ticks_usec(),
		"clone_usec": 0,
		"action_selection_usec": 0,
		"action_apply_usec": 0,
		"planned_actions": 0,
		"card_action_batches": 0,
		"card_action_candidates": 0,
		"card_action_enumeration_usec": 0,
		"card_scoring_usec": 0,
		"move_generation_usec": 0,
		"legal_move_count": 0,
		"root_moves_considered": 0,
		"move_scoring_usec": 0,
		"move_simulation_clone_usec": 0,
		"search_usec": 0,
		"search_nodes": 0,
		"search_leaf_nodes": 0,
		"search_cutoffs": 0,
	}


func _finish_timing_report(plan: Array) -> void:
	if _active_timing_report.is_empty():
		return
	_active_timing_report["total_usec"] = Time.get_ticks_usec() - int(_active_timing_report["started_usec"])
	_active_timing_report["plan_length"] = plan.size()
	last_timing_report = _active_timing_report.duplicate(true)
	if int(last_timing_report.get("total_usec", 0)) >= LOG_THRESHOLD_USEC:
		Log.info("[AI] Slow plan detected", last_timing_report)
	_active_timing_report = {}


func _add_timing(key: String, amount: int) -> void:
	if _active_timing_report.is_empty():
		return
	_active_timing_report[key] = int(_active_timing_report.get(key, 0)) + amount


func _increment_timing(key: String, amount: int = 1) -> void:
	_add_timing(key, amount)


func _usec_to_msec(value: int) -> float:
	return snappedf(float(value) / 1000.0, 0.01)
