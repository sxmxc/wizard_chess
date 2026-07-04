extends RefCounted
class_name WizardMatch

const STATE_SETUP := "setup"
const STATE_ACTIVE := "active"
const STATE_COMPLETE := "complete"

const SETUP_STEP_MULLIGAN := "mulligan"
const SETUP_STEP_READY := "ready"

const PHASE_BEGINNING := "beginning"
const PHASE_PREPARATION := "preparation"
const PHASE_MOVE := "move"
const PHASE_REACTION := "reaction"
const PHASE_END := "end"

const ZONE_DECK := "deck"
const ZONE_HAND := "hand"
const ZONE_BATTLEFIELD := "battlefield"
const ZONE_GRAVEYARD := "graveyard"
const ZONE_EXILE := "exile"

const TARGET_TYPE_PIECE := "piece"
const TARGET_TYPE_SQUARE := "square"

const ACTION_TYPE_ADVANCE_PHASE := "advance_phase"
const ACTION_TYPE_PLAY_CARD := "play_card"
const ACTION_TYPE_MOVE := "move"
const EFFECT_DURATION_UNTIL_END_OF_TURN := "until_end_of_turn"
const EFFECT_DURATION_WHILE_ATTACHED := "while_attached"
const EFFECT_DURATION_WHILE_ON_BATTLEFIELD := "while_on_battlefield"
const EFFECT_DURATION_UNTIL_TRIGGERED := "until_triggered"

var chess_state := ChessState.new()
var chess_engine := ChessEngine.new(chess_state)
var rules: WizardMatchRules
var event_queue := GameEventQueue.new()
var state: String = STATE_SETUP
var setup_step: String = SETUP_STEP_MULLIGAN
var phase: String = PHASE_BEGINNING
var turn_number: int = 0
var rng_seed: int = 1
var pending_hand_limit_discard_color: String = ""
var pending_hand_limit_discard_count: int = 0
var reaction_priority_color: String = ""
var consecutive_reaction_passes: int = 0
var reaction_window: Array = []
var active_effects: Array = []
var _next_card_instance_id: int = 1
var _shuffle_nonce: int = 0
var players := {}


func _init(match_rules: WizardMatchRules = null) -> void:
	rules = match_rules if match_rules != null else WizardMatchRules.new()
	_reset_players()


func start_match(white_deck: DeckDefinition, black_deck: DeckDefinition, seed: int = 1) -> Dictionary:
	var white_validation := _validate_deck(white_deck)
	if not white_validation["ok"]:
		return white_validation

	var black_validation := _validate_deck(black_deck)
	if not black_validation["ok"]:
		return black_validation

	chess_engine.reset()
	event_queue.clear()
	state = STATE_SETUP
	setup_step = SETUP_STEP_MULLIGAN
	phase = PHASE_BEGINNING
	turn_number = 1
	rng_seed = seed
	_shuffle_nonce = 0
	pending_hand_limit_discard_color = ""
	pending_hand_limit_discard_count = 0
	reaction_priority_color = ""
	consecutive_reaction_passes = 0
	reaction_window = []
	active_effects = []
	_next_card_instance_id = 1
	_reset_players()
	_initialize_player(ChessMatch.WHITE, white_deck)
	_initialize_player(ChessMatch.BLACK, black_deck)
	event_queue.enqueue({
		"type": "match_started",
		"payload": {
			"seed": rng_seed,
			"active_color": chess_state.active_color,
			"setup_step": setup_step,
		},
	})
	event_queue.resolve_all()
	return _result(true)


func keep_opening_hand(color: String) -> Dictionary:
	if state != STATE_SETUP or setup_step != SETUP_STEP_MULLIGAN:
		return _result(false, "setup_not_waiting_for_mulligan")
	if not players.has(color):
		return _result(false, "unknown_player")

	var player: Dictionary = players[color]
	if not bool(player.get("mulligan_available", false)):
		return _result(false, "mulligan_unavailable")

	player["mulligan_available"] = false
	player["setup_ready"] = true
	players[color] = player
	event_queue.enqueue({
		"type": "opening_hand_kept",
		"payload": {
			"color": color,
			"hand_size": player["hand"].size(),
		},
	})
	_complete_setup_if_ready()
	return _result(true)


func perform_mulligan(color: String, card_instance_ids: Array[String]) -> Dictionary:
	if state != STATE_SETUP or setup_step != SETUP_STEP_MULLIGAN:
		return _result(false, "setup_not_waiting_for_mulligan")
	if not players.has(color):
		return _result(false, "unknown_player")

	var player: Dictionary = players[color]
	if not bool(player.get("mulligan_available", false)):
		return _result(false, "mulligan_unavailable")

	var selected_cards := _take_cards_from_hand(player, card_instance_ids)
	if selected_cards.size() != card_instance_ids.size():
		return _result(false, "invalid_mulligan_selection")

	for card_state in selected_cards:
		player["deck"].append(card_state)
		event_queue.enqueue({
			"type": "mulligan_returned",
			"payload": {
				"color": color,
				"card_id": card_state["card_id"],
				"card_instance_id": card_state["instance_id"],
			},
		})

	player["mulligan_available"] = false
	player["setup_ready"] = true
	players[color] = player
	_reshuffle_player_deck(color)
	_draw_cards(color, selected_cards.size())
	event_queue.enqueue({
		"type": "mulligan_resolved",
		"payload": {
			"color": color,
			"cards_replaced": selected_cards.size(),
			"hand_size": players[color]["hand"].size(),
		},
	})
	_complete_setup_if_ready()
	return _result(true)


func resolve_beginning_phase() -> bool:
	if not _can_run_phase(PHASE_BEGINNING):
		return false

	var active_color := chess_state.active_color
	var player: Dictionary = players[active_color]
	player["maximum_mana"] = min(
		int(player["maximum_mana"]) + rules.mana_gained_per_turn,
		rules.maximum_mana_cap
	)
	player["mana"] = int(player["maximum_mana"])
	players[active_color] = player
	_draw_cards(active_color, rules.cards_drawn_per_turn)
	player = players[active_color]
	event_queue.enqueue({
		"type": "beginning_phase_resolved",
		"payload": {
			"color": active_color,
			"mana": player["mana"],
			"maximum_mana": player["maximum_mana"],
		},
	})
	event_queue.resolve_all()
	phase = PHASE_PREPARATION
	return true


func finish_preparation_phase() -> bool:
	if not _can_run_phase(PHASE_PREPARATION):
		return false
	phase = PHASE_MOVE
	event_queue.enqueue({
		"type": "phase_advanced",
		"payload": {
			"phase": phase,
			"color": chess_state.active_color,
		},
	})
	event_queue.resolve_all()
	return true


func apply_move_action(action: Dictionary) -> Dictionary:
	if not _can_run_phase(PHASE_MOVE):
		return _result(false, "wrong_phase")

	var acting_color := _turn_player_color()
	var legal_move: Variant = _resolve_action_to_legal_move(action)
	if legal_move == null:
		return _result(false, "illegal_move")

	var result := chess_engine.apply_action_payload(action)
	if not result["ok"]:
		return result

	_sync_attached_units_after_move(legal_move)
	event_queue.enqueue({
		"type": "chess_move_resolved",
		"payload": {
			"color": acting_color,
			"action": action.duplicate(true),
			"move": legal_move.duplicate(true),
			"fen": chess_engine.to_fen(),
		},
	})
	event_queue.resolve_all()
	phase = PHASE_REACTION
	reaction_priority_color = acting_color
	consecutive_reaction_passes = 0
	reaction_window = [_build_reaction_window_entry("after_piece_moves", {
		"color": acting_color,
		"from": str(action["from"]),
		"to": str(action["to"]),
	})]
	if bool(legal_move.get("is_capture", false)):
		reaction_window.append(_build_reaction_window_entry("after_piece_captured", {
			"color": acting_color,
			"captured_square": chess_engine.square_to_algebraic(legal_move["captured_square"]),
			"captured_piece_type": str(legal_move.get("captured_piece_type", "")),
		}))
	if chess_engine.is_in_check(chess_state.active_color):
		reaction_window.append(_build_reaction_window_entry("when_king_in_check", {
			"checked_color": chess_state.active_color,
		}))
	_resolve_traps_for_move(acting_color, legal_move)
	return _result(true)


func pass_reaction_phase() -> bool:
	if not _can_run_phase(PHASE_REACTION):
		return false

	consecutive_reaction_passes += 1
	var passed_color := reaction_priority_color
	reaction_priority_color = _opponent(reaction_priority_color)
	event_queue.enqueue({
		"type": "reaction_priority_passed",
		"payload": {
			"color": passed_color,
			"next_priority": reaction_priority_color,
			"consecutive_passes": consecutive_reaction_passes,
		},
	})
	event_queue.resolve_all()
	if consecutive_reaction_passes < 2:
		return true

	phase = PHASE_END
	reaction_priority_color = ""
	consecutive_reaction_passes = 0
	reaction_window = []
	event_queue.enqueue({
		"type": "reaction_phase_passed",
		"payload": {
			"next_phase": phase,
		},
	})
	event_queue.resolve_all()
	return true


func resolve_end_phase() -> bool:
	if not _can_run_phase(PHASE_END) or pending_hand_limit_discard_count > 0:
		return false

	var completing_color := _inactive_color()
	var overflow_count := _hand_overflow_count(completing_color)
	if overflow_count > 0:
		pending_hand_limit_discard_color = completing_color
		pending_hand_limit_discard_count = overflow_count
		event_queue.enqueue({
			"type": "hand_limit_discard_required",
			"payload": {
				"color": completing_color,
				"discard_count": overflow_count,
			},
		})
		event_queue.resolve_all()
		return true

	_expire_temporary_effects("end_of_turn")
	_finish_turn(completing_color)
	return true


func discard_cards_for_hand_limit(card_instance_ids: Array[String]) -> Dictionary:
	if state != STATE_ACTIVE or phase != PHASE_END:
		return _result(false, "wrong_phase")
	if pending_hand_limit_discard_count <= 0 or pending_hand_limit_discard_color.is_empty():
		return _result(false, "no_hand_limit_discard_pending")
	if card_instance_ids.size() != pending_hand_limit_discard_count:
		return _result(false, "incorrect_discard_count")

	var player: Dictionary = players[pending_hand_limit_discard_color]
	var discarded_cards := _take_cards_from_hand(player, card_instance_ids)
	if discarded_cards.size() != card_instance_ids.size():
		return _result(false, "invalid_discard_selection")

	for card_state in discarded_cards:
		player["graveyard"].append(card_state)
		event_queue.enqueue({
			"type": "hand_size_discard",
			"payload": {
				"color": pending_hand_limit_discard_color,
				"card_id": card_state["card_id"],
				"card_instance_id": card_state["instance_id"],
			},
		})
	players[pending_hand_limit_discard_color] = player
	var completing_color := pending_hand_limit_discard_color
	pending_hand_limit_discard_color = ""
	pending_hand_limit_discard_count = 0
	_expire_temporary_effects("end_of_turn")
	_finish_turn(completing_color)
	return _result(true)


func play_card_from_hand(card_instance_id: String, targets: Array = []) -> Dictionary:
	if state != STATE_ACTIVE:
		return _result(false, "match_not_active")
	if pending_hand_limit_discard_count > 0:
		return _result(false, "hand_limit_discard_pending")

	var owner_color := _find_hand_owner(card_instance_id)
	if owner_color.is_empty():
		return _result(false, "card_not_in_hand")

	var acting_color := owner_color
	if phase == PHASE_PREPARATION and acting_color != _turn_player_color():
		return _result(false, "wrong_phase")
	if phase != PHASE_PREPARATION and phase != PHASE_REACTION:
		return _result(false, "wrong_phase")

	var player: Dictionary = players[acting_color]
	var hand: Array = player["hand"]
	var hand_index := _find_card_index(hand, card_instance_id)
	var card_state: Dictionary = hand[hand_index]
	var play_error := _validate_card_play(acting_color, card_state, targets)
	if not play_error.is_empty():
		return _result(false, play_error)

	player["mana"] = int(player["mana"]) - int(card_state["mana_cost"])
	hand.remove_at(hand_index)
	var resolved_card_state := card_state.duplicate(true)
	var destination_zone := _resolve_destination_zone(resolved_card_state)
	_apply_card_targets_to_state(resolved_card_state, targets)
	_apply_unit_attachment_replacement(player, resolved_card_state)
	_replace_environment_if_needed(resolved_card_state)
	player[destination_zone].append(resolved_card_state)
	players[acting_color] = player
	_register_card_effects(resolved_card_state)

	event_queue.enqueue({
		"type": "mana_spent",
		"payload": {
			"color": acting_color,
			"mana_cost": resolved_card_state["mana_cost"],
			"remaining_mana": player["mana"],
		},
	})
	event_queue.enqueue({
		"type": "card_played",
		"payload": {
			"color": acting_color,
			"card_id": resolved_card_state["card_id"],
			"card_instance_id": resolved_card_state["instance_id"],
			"destination_zone": destination_zone,
			"card_type": resolved_card_state["card_type"],
			"trigger_condition": str(resolved_card_state.get("trigger_condition", "")),
			"targets": _serialize_targets(targets),
		},
	})
	event_queue.resolve_all()
	_record_reaction_window_for_play(acting_color, resolved_card_state, destination_zone)
	if phase == PHASE_REACTION:
		consecutive_reaction_passes = 0
		reaction_priority_color = _opponent(acting_color)
	return _result(true)


func create_piece_target(square: Vector2i) -> Dictionary:
	return {
		"type": TARGET_TYPE_PIECE,
		"square": chess_engine.square_to_algebraic(square),
	}


func create_square_target(square: Vector2i) -> Dictionary:
	return {
		"type": TARGET_TYPE_SQUARE,
		"square": chess_engine.square_to_algebraic(square),
	}


func get_player_state(color: String) -> Dictionary:
	return players.get(color, {}).duplicate(true)


func get_pending_hand_limit_discard_count(color: String) -> int:
	if color != pending_hand_limit_discard_color:
		return 0
	return pending_hand_limit_discard_count


func get_active_effects() -> Array:
	return active_effects.duplicate(true)


func get_event_history() -> Array:
	return event_queue.get_resolved_events()


func clone() -> WizardMatch:
	var copy := WizardMatch.new()
	copy.load_state_snapshot(create_state_snapshot())
	return copy


func get_legal_card_actions(color: String) -> Array:
	if not players.has(color):
		return []

	var legal_actions: Array = []
	var player: Dictionary = players[color]
	for card_state_value in player["hand"]:
		var card_state: Dictionary = card_state_value
		var play_error := _validate_card_play(color, card_state, [])
		if play_error.is_empty():
			legal_actions.append({
				"card_instance_id": str(card_state["instance_id"]),
				"card_id": str(card_state["card_id"]),
				"targets": [],
			})
			continue

		if play_error != "incorrect_target_count":
			continue

		for targets in _enumerate_legal_targets_for_card(color, card_state):
			legal_actions.append({
				"card_instance_id": str(card_state["instance_id"]),
				"card_id": str(card_state["card_id"]),
				"targets": _serialize_targets(targets),
			})
	return legal_actions


func create_state_snapshot() -> Dictionary:
	return {
		"state": state,
		"setup_step": setup_step,
		"phase": phase,
		"turn_number": turn_number,
		"rng_seed": rng_seed,
		"shuffle_nonce": _shuffle_nonce,
		"pending_hand_limit_discard_color": pending_hand_limit_discard_color,
		"pending_hand_limit_discard_count": pending_hand_limit_discard_count,
		"reaction_priority_color": reaction_priority_color,
		"consecutive_reaction_passes": consecutive_reaction_passes,
		"reaction_window": reaction_window.duplicate(true),
		"active_effects": active_effects.duplicate(true),
		"next_card_instance_id": _next_card_instance_id,
		"rules": {
			"opening_hand_size": rules.opening_hand_size,
			"maximum_hand_size": rules.maximum_hand_size,
			"starting_mana": rules.starting_mana,
			"maximum_mana_cap": rules.maximum_mana_cap,
			"mana_gained_per_turn": rules.mana_gained_per_turn,
			"cards_drawn_per_turn": rules.cards_drawn_per_turn,
			"required_deck_size": rules.required_deck_size,
			"maximum_card_copies": rules.maximum_card_copies,
		},
		"players": players.duplicate(true),
		"chess_state": chess_engine.create_state_snapshot(),
		"event_history": event_queue.get_resolved_events(),
	}


func load_state_snapshot(snapshot: Dictionary) -> void:
	var restored_rules := WizardMatchRules.new()
	var rules_snapshot: Dictionary = snapshot.get("rules", {})
	restored_rules.opening_hand_size = int(rules_snapshot.get("opening_hand_size", restored_rules.opening_hand_size))
	restored_rules.maximum_hand_size = int(rules_snapshot.get("maximum_hand_size", restored_rules.maximum_hand_size))
	restored_rules.starting_mana = int(rules_snapshot.get("starting_mana", restored_rules.starting_mana))
	restored_rules.maximum_mana_cap = int(rules_snapshot.get("maximum_mana_cap", restored_rules.maximum_mana_cap))
	restored_rules.mana_gained_per_turn = int(rules_snapshot.get("mana_gained_per_turn", restored_rules.mana_gained_per_turn))
	restored_rules.cards_drawn_per_turn = int(rules_snapshot.get("cards_drawn_per_turn", restored_rules.cards_drawn_per_turn))
	restored_rules.required_deck_size = int(rules_snapshot.get("required_deck_size", restored_rules.required_deck_size))
	restored_rules.maximum_card_copies = int(rules_snapshot.get("maximum_card_copies", restored_rules.maximum_card_copies))
	rules = restored_rules
	state = str(snapshot.get("state", STATE_SETUP))
	setup_step = str(snapshot.get("setup_step", SETUP_STEP_MULLIGAN))
	phase = str(snapshot.get("phase", PHASE_BEGINNING))
	turn_number = int(snapshot.get("turn_number", 0))
	rng_seed = int(snapshot.get("rng_seed", 1))
	_shuffle_nonce = int(snapshot.get("shuffle_nonce", 0))
	pending_hand_limit_discard_color = str(snapshot.get("pending_hand_limit_discard_color", ""))
	pending_hand_limit_discard_count = int(snapshot.get("pending_hand_limit_discard_count", 0))
	reaction_priority_color = str(snapshot.get("reaction_priority_color", ""))
	consecutive_reaction_passes = int(snapshot.get("consecutive_reaction_passes", 0))
	reaction_window = snapshot.get("reaction_window", []).duplicate(true)
	active_effects = snapshot.get("active_effects", []).duplicate(true)
	_next_card_instance_id = int(snapshot.get("next_card_instance_id", 1))
	players = snapshot.get("players", {}).duplicate(true)
	chess_engine.load_state_snapshot(snapshot.get("chess_state", snapshot.get("chess_match", {})))
	event_queue.load_history(snapshot.get("event_history", []))


func _initialize_player(color: String, deck: DeckDefinition) -> void:
	var runtime_deck := _create_runtime_deck(color, deck)
	players[color] = {
		"color": color,
		"deck": runtime_deck,
		"hand": [],
		"battlefield": [],
		"graveyard": [],
		"exile": [],
		"mana": rules.starting_mana,
		"maximum_mana": rules.starting_mana,
		"mulligan_available": true,
		"setup_ready": false,
	}
	_reshuffle_player_deck(color)
	_draw_cards(color, rules.opening_hand_size)
	event_queue.enqueue({
		"type": "opening_hand_drawn",
		"payload": {
			"color": color,
			"hand_size": players[color]["hand"].size(),
			"deck_size": players[color]["deck"].size(),
		},
	})


func _create_runtime_deck(color: String, deck: DeckDefinition) -> Array:
	var runtime_deck: Array = []
	if deck == null:
		return runtime_deck
	for card in deck.cards:
		if card == null:
			continue
		runtime_deck.append({
			"instance_id": "card_%d" % _next_card_instance_id,
			"card_id": card.card_id,
			"display_name": card.display_name,
			"card_type": card.card_type,
			"school": card.school,
			"academy": card.academy,
			"rarity": card.rarity,
			"mana_cost": card.mana_cost,
			"rules_text": card.rules_text,
			"target_requirements": Array(card.target_requirements),
			"keywords": Array(card.keywords),
			"trigger_condition": card.trigger_condition,
			"effect_duration": card.effect_duration,
			"effect_tags": Array(card.effect_tags),
			"owner": color,
			"controller": color,
			"persistent": card.is_persistent_type(),
			"resource_path": card.resource_path,
			"face_down": card.card_type == CardDefinition.TYPE_TRAP,
			"attached_to": "",
			"placed_on": "",
		})
		_next_card_instance_id += 1
	return runtime_deck


func _draw_cards(color: String, count: int) -> void:
	var player: Dictionary = players[color]
	for _card_index in range(count):
		if player["deck"].is_empty():
			event_queue.enqueue({
				"type": "draw_failed",
				"payload": {
					"color": color,
				},
			})
			continue
		var drawn_card: Dictionary = player["deck"].pop_front()
		player["hand"].append(drawn_card)
		event_queue.enqueue({
			"type": "card_drawn",
			"payload": {
				"color": color,
				"card_id": drawn_card["card_id"],
				"card_instance_id": drawn_card["instance_id"],
			},
		})
	players[color] = player


func _validate_card_play(acting_color: String, card_state: Dictionary, targets: Array) -> String:
	if phase != PHASE_PREPARATION and phase != PHASE_REACTION:
		return "wrong_phase"

	if phase == PHASE_PREPARATION and str(card_state["card_type"]) == CardDefinition.TYPE_REACTION:
		return "reaction_only_phase"

	if phase == PHASE_REACTION and str(card_state["card_type"]) != CardDefinition.TYPE_REACTION:
		return "preparation_only_card_type"

	if phase == PHASE_REACTION:
		if acting_color != reaction_priority_color:
			return "not_reaction_priority"
		if not _is_reaction_trigger_active(card_state, acting_color):
			return "reaction_trigger_inactive"

	var player: Dictionary = players[acting_color]
	if int(player["mana"]) < int(card_state["mana_cost"]):
		return "insufficient_mana"

	return _validate_targets(acting_color, card_state, targets)


func _validate_targets(acting_color: String, card_state: Dictionary, targets: Array) -> String:
	var requirements: Array = card_state.get("target_requirements", [])
	if requirements.is_empty():
		if not targets.is_empty():
			return "unexpected_targets"
		return ""

	if requirements.size() != targets.size():
		return "incorrect_target_count"

	for index in range(requirements.size()):
		if not _requirement_matches_target(acting_color, str(requirements[index]), targets[index]):
			return "invalid_target"
	return ""


func _enumerate_legal_targets_for_card(acting_color: String, card_state: Dictionary) -> Array:
	var requirements: Array = card_state.get("target_requirements", [])
	if requirements.is_empty():
		return []

	var target_options: Array = []
	for requirement_value in requirements:
		var requirement := str(requirement_value)
		var options := _candidate_targets_for_requirement(acting_color, requirement)
		if options.is_empty():
			return []
		target_options.append(options)

	var combinations: Array = []
	_build_target_combinations(acting_color, card_state, target_options, 0, [], combinations)
	return combinations


func _build_target_combinations(
	acting_color: String,
	card_state: Dictionary,
	target_options: Array,
	index: int,
	current_targets: Array,
	combinations: Array
) -> void:
	if index >= target_options.size():
		if _validate_targets(acting_color, card_state, current_targets).is_empty():
			combinations.append(_serialize_targets(current_targets))
		return

	for target_value in target_options[index]:
		current_targets.append((target_value as Dictionary).duplicate(true))
		_build_target_combinations(acting_color, card_state, target_options, index + 1, current_targets, combinations)
		current_targets.pop_back()


func _candidate_targets_for_requirement(acting_color: String, requirement_text: String) -> Array:
	var options: Array = []
	for rank in range(8):
		for file in range(8):
			var square := Vector2i(file, rank)
			var piece = chess_engine.get_piece(square)
			if piece == null:
				var square_target := create_square_target(square)
				if _requirement_matches_target(acting_color, requirement_text, square_target):
					options.append(square_target)
				continue

			var piece_target := create_piece_target(square)
			if _requirement_matches_target(acting_color, requirement_text, piece_target):
				options.append(piece_target)
	return options


func _requirement_matches_target(acting_color: String, requirement_text: String, target: Dictionary) -> bool:
	var normalized := requirement_text.strip_edges().trim_suffix(".").to_lower()
	if normalized.begins_with("target "):
		normalized = normalized.substr(7)
	if normalized.begins_with("play on "):
		normalized = normalized.substr(8)

	if normalized.contains(" or "):
		for option in normalized.split(" or "):
			if _requirement_matches_target(acting_color, option, target):
				return true
		return false

	var target_square: Variant = _target_square(target)
	if target_square == null:
		return false

	if normalized == "empty square":
		return str(target.get("type", "")) == TARGET_TYPE_SQUARE and chess_engine.get_piece(target_square) == null

	var piece = chess_engine.get_piece(target_square)
	if piece == null:
		return false

	if str(target.get("type", "")) != TARGET_TYPE_PIECE:
		return false

	if normalized == "friendly piece":
		return piece["color"] == acting_color
	if normalized == "opposing piece":
		return piece["color"] != acting_color
	if normalized == "any piece":
		return true
	if normalized == "pawn" or normalized == "knight" or normalized == "bishop" or normalized == "rook" or normalized == "queen" or normalized == "king":
		return piece["type"] == normalized
	if normalized == "threatened rook":
		return piece["type"] == ChessMatch.PIECE_ROOK and chess_engine.is_square_attacked(target_square, _opponent(piece["color"]))
	if normalized == "bishop adjacent to your king":
		return piece["type"] == ChessMatch.PIECE_BISHOP and piece["color"] == acting_color and _is_adjacent_to_own_king(target_square, piece["color"])
	if normalized == "pawn beyond rank 5":
		return piece["type"] == ChessMatch.PIECE_PAWN and _is_pawn_beyond_rank_five(target_square, piece["color"])

	return false


func _resolve_destination_zone(card_state: Dictionary) -> String:
	return ZONE_BATTLEFIELD if bool(card_state.get("persistent", false)) else ZONE_GRAVEYARD


func _apply_card_targets_to_state(card_state: Dictionary, targets: Array) -> void:
	if targets.is_empty():
		return

	var primary_target: Dictionary = targets[0]
	var target_square: Variant = _target_square(primary_target)
	if target_square == null:
		return

	var square_name := chess_engine.square_to_algebraic(target_square)
	if str(card_state.get("card_type", "")) == CardDefinition.TYPE_UNIT:
		card_state["attached_to"] = square_name
	elif str(card_state.get("card_type", "")) == CardDefinition.TYPE_TRAP:
		card_state["placed_on"] = square_name
	else:
		card_state["targeted_square"] = square_name

	card_state["targeted_by"] = _serialize_targets(targets)


func _apply_unit_attachment_replacement(player: Dictionary, card_state: Dictionary) -> void:
	if str(card_state.get("card_type", "")) != CardDefinition.TYPE_UNIT:
		return

	var attached_to := str(card_state.get("attached_to", ""))
	if attached_to.is_empty():
		return

	var battlefield: Array = player["battlefield"]
	for index in range(battlefield.size() - 1, -1, -1):
		var existing_card: Dictionary = battlefield[index]
		if str(existing_card.get("card_type", "")) != CardDefinition.TYPE_UNIT:
			continue
		if str(existing_card.get("attached_to", "")) != attached_to:
			continue
		battlefield.remove_at(index)
		_remove_effects_for_card(str(existing_card["instance_id"]))
		player["graveyard"].append(existing_card)
		event_queue.enqueue({
			"type": "unit_replaced",
			"payload": {
				"color": str(player["color"]),
				"card_id": existing_card["card_id"],
				"card_instance_id": existing_card["instance_id"],
				"attached_to": attached_to,
			},
		})
		break


func _sync_attached_units_after_move(move: Dictionary) -> void:
	_capture_attached_units_at_square(move["captured_square"] if move["is_capture"] else Vector2i(-1, -1))
	if move["is_en_passant"]:
		_capture_attached_units_at_square(move["captured_square"])

	_move_attached_unit(move["from"], move["to"])

	if move["is_castle_kingside"]:
		var home_rank := 7 if str(move["color"]) == ChessMatch.WHITE else 0
		_move_attached_unit(Vector2i(7, home_rank), Vector2i(5, home_rank))
	elif move["is_castle_queenside"]:
		var queen_home_rank := 7 if str(move["color"]) == ChessMatch.WHITE else 0
		_move_attached_unit(Vector2i(0, queen_home_rank), Vector2i(3, queen_home_rank))


func _capture_attached_units_at_square(square: Vector2i) -> void:
	if square.x < 0:
		return
	var square_name := chess_engine.square_to_algebraic(square)
	for color in [ChessMatch.WHITE, ChessMatch.BLACK]:
		var player: Dictionary = players[color]
		var battlefield: Array = player["battlefield"]
		for index in range(battlefield.size() - 1, -1, -1):
			var card_state: Dictionary = battlefield[index]
			if str(card_state.get("card_type", "")) != CardDefinition.TYPE_UNIT:
				continue
			if str(card_state.get("attached_to", "")) != square_name:
				continue
			battlefield.remove_at(index)
			_remove_effects_for_card(str(card_state["instance_id"]))
			card_state["attached_to"] = ""
			player["graveyard"].append(card_state)
			event_queue.enqueue({
				"type": "attached_unit_destroyed",
				"payload": {
					"color": color,
					"card_id": card_state["card_id"],
					"card_instance_id": card_state["instance_id"],
					"former_square": square_name,
				},
			})
		players[color] = player


func _move_attached_unit(from_square: Vector2i, to_square: Vector2i) -> void:
	var from_name := chess_engine.square_to_algebraic(from_square)
	var to_name := chess_engine.square_to_algebraic(to_square)
	for color in [ChessMatch.WHITE, ChessMatch.BLACK]:
		var player: Dictionary = players[color]
		var battlefield: Array = player["battlefield"]
		for index in range(battlefield.size()):
			var card_state: Dictionary = battlefield[index]
			if str(card_state.get("card_type", "")) != CardDefinition.TYPE_UNIT:
				continue
			if str(card_state.get("attached_to", "")) != from_name:
				continue
			card_state["attached_to"] = to_name
			battlefield[index] = card_state
			_update_effect_square(str(card_state["instance_id"]), to_name)
		players[color] = player


func _resolve_action_to_legal_move(action: Dictionary):
	if str(action.get("type", "")) != ChessMatch.ACTION_TYPE_MOVE:
		return null
	if not action.has("from") or not action.has("to"):
		return null
	var from_square := chess_engine.algebraic_to_square(str(action["from"]))
	var to_square := chess_engine.algebraic_to_square(str(action["to"]))
	var promotion := str(action.get("promotion", ""))
	for legal_move in chess_engine.get_legal_moves_from(from_square):
		if legal_move["to"] == to_square and str(legal_move.get("promotion", "")) == promotion:
			return legal_move
	return null


func _complete_setup_if_ready() -> void:
	if not bool(players[ChessMatch.WHITE].get("setup_ready", false)):
		return
	if not bool(players[ChessMatch.BLACK].get("setup_ready", false)):
		return

	setup_step = SETUP_STEP_READY
	state = STATE_ACTIVE
	event_queue.enqueue({
		"type": "setup_completed",
		"payload": {
			"phase": phase,
			"turn_number": turn_number,
		},
	})
	event_queue.resolve_all()


func _finish_turn(completing_color: String) -> void:
	event_queue.enqueue({
		"type": "turn_ended",
		"payload": {
			"completed_color": completing_color,
			"next_color": chess_state.active_color,
		},
	})
	event_queue.resolve_all()
	turn_number += 1
	phase = PHASE_BEGINNING
	reaction_priority_color = ""
	consecutive_reaction_passes = 0
	reaction_window = []
	_refresh_state_from_chess()


func _hand_overflow_count(color: String) -> int:
	var player: Dictionary = players[color]
	return max(player["hand"].size() - rules.maximum_hand_size, 0)


func _target_square(target: Dictionary):
	var square_text := str(target.get("square", ""))
	if square_text.is_empty():
		return null
	return chess_engine.algebraic_to_square(square_text)


func _is_adjacent_to_own_king(square: Vector2i, color: String) -> bool:
	for rank in range(8):
		for file in range(8):
			var candidate := Vector2i(file, rank)
			var piece = chess_engine.get_piece(candidate)
			if piece == null or piece["color"] != color or piece["type"] != ChessMatch.PIECE_KING:
				continue
			return abs(candidate.x - square.x) <= 1 and abs(candidate.y - square.y) <= 1
	return false


func _is_pawn_beyond_rank_five(square: Vector2i, color: String) -> bool:
	var rank_from_white_perspective := 8 - square.y
	if color == ChessMatch.WHITE:
		return rank_from_white_perspective > 5
	return rank_from_white_perspective < 4


func _serialize_targets(targets: Array) -> Array:
	var serialized: Array = []
	for target_value in targets:
		serialized.append((target_value as Dictionary).duplicate(true))
	return serialized


func _reshuffle_player_deck(color: String) -> void:
	var player: Dictionary = players[color]
	_shuffle_nonce += 1
	_shuffle_cards(player["deck"], rng_seed + _shuffle_nonce)
	players[color] = player


func _shuffle_cards(cards: Array, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for index in range(cards.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temp = cards[index]
		cards[index] = cards[swap_index]
		cards[swap_index] = temp


func _take_cards_from_hand(player: Dictionary, card_instance_ids: Array[String]) -> Array:
	var removed_cards: Array = []
	var remaining_ids := card_instance_ids.duplicate()
	var hand: Array = player["hand"]
	for index in range(hand.size() - 1, -1, -1):
		var instance_id := str(hand[index].get("instance_id", ""))
		var remaining_index := remaining_ids.find(instance_id)
		if remaining_index < 0:
			continue
		removed_cards.append(hand[index])
		hand.remove_at(index)
		remaining_ids.remove_at(remaining_index)
	if not remaining_ids.is_empty():
		return []
	removed_cards.reverse()
	return removed_cards


func _validate_deck(deck: DeckDefinition) -> Dictionary:
	if deck == null:
		return _result(false, "missing_deck")
	if deck.card_count() != rules.required_deck_size:
		return _result(false, "invalid_deck_size")

	var copies_by_card_id := {}
	for card in deck.cards:
		if card == null:
			return _result(false, "deck_contains_null_card")
		var card_id := str(card.card_id)
		copies_by_card_id[card_id] = int(copies_by_card_id.get(card_id, 0)) + 1
		if int(copies_by_card_id[card_id]) > rules.maximum_card_copies:
			return _result(false, "too_many_card_copies")
		if card.rarity == CardDefinition.RARITY_LEGENDARY and int(copies_by_card_id[card_id]) > 1:
			return _result(false, "too_many_legendary_copies")
	return _result(true)


func _refresh_state_from_chess() -> void:
	if chess_state.outcome["status"] != ChessMatch.STATUS_ACTIVE:
		state = STATE_COMPLETE


func _inactive_color() -> String:
	return ChessMatch.BLACK if chess_state.active_color == ChessMatch.WHITE else ChessMatch.WHITE


func _opponent(color: String) -> String:
	return ChessMatch.BLACK if color == ChessMatch.WHITE else ChessMatch.WHITE


func _turn_player_color() -> String:
	if phase == PHASE_REACTION or phase == PHASE_END:
		return _inactive_color()
	return chess_state.active_color


func _can_run_phase(expected_phase: String) -> bool:
	return state == STATE_ACTIVE and phase == expected_phase and pending_hand_limit_discard_count == 0


func _find_card_index(cards: Array, card_instance_id: String) -> int:
	for index in range(cards.size()):
		if str(cards[index].get("instance_id", "")) == card_instance_id:
			return index
	return -1


func _find_hand_owner(card_instance_id: String) -> String:
	for color in [ChessMatch.WHITE, ChessMatch.BLACK]:
		if _find_card_index(players[color]["hand"], card_instance_id) >= 0:
			return color
	return ""


func _is_reaction_trigger_active(card_state: Dictionary, acting_color: String) -> bool:
	var trigger_condition := str(card_state.get("trigger_condition", "")).strip_edges().to_lower()
	if trigger_condition.is_empty():
		return true
	for window_entry_value in reaction_window:
		var window_entry: Dictionary = window_entry_value
		var window_trigger := str(window_entry.get("trigger", ""))
		var payload: Dictionary = window_entry.get("payload", {})
		match trigger_condition:
			"after_piece_moves":
				if window_trigger != "after_piece_moves":
					continue
				return true
			"after_piece_captured":
				if window_trigger != "after_piece_captured":
					continue
				return true
			"when_card_played":
				if window_trigger != "when_card_played":
					continue
				return true
			"when_friendly_card_played":
				if window_trigger != "when_card_played":
					continue
				return str(payload.get("color", "")) == acting_color
			"when_opposing_card_played":
				if window_trigger != "when_card_played":
					continue
				return str(payload.get("color", "")) == _opponent(acting_color)
			"when_king_in_check":
				if window_trigger != "when_king_in_check":
					continue
				return str(payload.get("checked_color", "")) == acting_color
			"at_end_of_turn":
				return phase == PHASE_REACTION
			_:
				if window_trigger != trigger_condition:
					continue
				if trigger_condition == str(payload.get("trigger_tag", "")):
					return true
	return false


func _build_reaction_window_entry(trigger_name: String, payload: Dictionary = {}) -> Dictionary:
	return {
		"trigger": trigger_name,
		"payload": payload.duplicate(true),
	}


func _record_reaction_window_for_play(acting_color: String, card_state: Dictionary, destination_zone: String) -> void:
	if phase != PHASE_REACTION:
		return
	reaction_window.append(_build_reaction_window_entry("when_card_played", {
		"color": acting_color,
		"card_id": str(card_state["card_id"]),
		"card_instance_id": str(card_state["instance_id"]),
		"card_type": str(card_state["card_type"]),
		"destination_zone": destination_zone,
	}))


func _replace_environment_if_needed(card_state: Dictionary) -> void:
	if str(card_state.get("card_type", "")) != CardDefinition.TYPE_ENVIRONMENT:
		return
	for color in [ChessMatch.WHITE, ChessMatch.BLACK]:
		var player: Dictionary = players[color]
		var battlefield: Array = player["battlefield"]
		for index in range(battlefield.size() - 1, -1, -1):
			var existing_card: Dictionary = battlefield[index]
			if str(existing_card.get("card_type", "")) != CardDefinition.TYPE_ENVIRONMENT:
				continue
			battlefield.remove_at(index)
			_remove_effects_for_card(str(existing_card["instance_id"]))
			player["graveyard"].append(existing_card)
			event_queue.enqueue({
				"type": "environment_replaced",
				"payload": {
					"color": color,
					"card_id": existing_card["card_id"],
					"card_instance_id": existing_card["instance_id"],
				},
			})
		players[color] = player


func _register_card_effects(card_state: Dictionary) -> void:
	var card_type := str(card_state.get("card_type", ""))
	var effect_duration := str(card_state.get("effect_duration", ""))
	if effect_duration.is_empty():
		match card_type:
			CardDefinition.TYPE_UNIT:
				effect_duration = EFFECT_DURATION_WHILE_ATTACHED
			CardDefinition.TYPE_TRAP:
				effect_duration = EFFECT_DURATION_UNTIL_TRIGGERED
			CardDefinition.TYPE_ENVIRONMENT:
				effect_duration = EFFECT_DURATION_WHILE_ON_BATTLEFIELD
			CardDefinition.TYPE_ARTIFACT:
				effect_duration = EFFECT_DURATION_WHILE_ON_BATTLEFIELD
			_:
				effect_duration = EFFECT_DURATION_UNTIL_END_OF_TURN if card_type == CardDefinition.TYPE_REACTION else ""
	if effect_duration.is_empty():
		return

	var effect_entry := {
		"source_card_id": str(card_state["card_id"]),
		"source_card_instance_id": str(card_state["instance_id"]),
		"source_card_type": card_type,
		"controller": str(card_state["controller"]),
		"duration": effect_duration,
		"effect_tags": Array(card_state.get("effect_tags", [])),
		"attached_to": str(card_state.get("attached_to", "")),
		"placed_on": str(card_state.get("placed_on", "")),
		"face_down": bool(card_state.get("face_down", false)),
	}
	active_effects.append(effect_entry)
	event_queue.enqueue({
		"type": "effect_activated",
		"payload": effect_entry.duplicate(true),
	})


func _remove_effects_for_card(card_instance_id: String) -> void:
	for index in range(active_effects.size() - 1, -1, -1):
		var effect_entry: Dictionary = active_effects[index]
		if str(effect_entry.get("source_card_instance_id", "")) != card_instance_id:
			continue
		active_effects.remove_at(index)
		event_queue.enqueue({
			"type": "effect_removed",
			"payload": effect_entry,
		})


func _update_effect_square(card_instance_id: String, square_name: String) -> void:
	for index in range(active_effects.size()):
		var effect_entry: Dictionary = active_effects[index]
		if str(effect_entry.get("source_card_instance_id", "")) != card_instance_id:
			continue
		effect_entry["attached_to"] = square_name
		active_effects[index] = effect_entry


func _resolve_traps_for_move(moving_color: String, move: Dictionary) -> void:
	var destination_name := chess_engine.square_to_algebraic(move["to"])
	for color in [ChessMatch.WHITE, ChessMatch.BLACK]:
		var player: Dictionary = players[color]
		var battlefield: Array = player["battlefield"]
		for index in range(battlefield.size() - 1, -1, -1):
			var trap_card: Dictionary = battlefield[index]
			if str(trap_card.get("card_type", "")) != CardDefinition.TYPE_TRAP:
				continue
			if str(trap_card.get("placed_on", "")) != destination_name:
				continue
			if not _does_trap_trigger(trap_card, moving_color):
				continue
			battlefield.remove_at(index)
			trap_card["face_down"] = false
			player["graveyard"].append(trap_card)
			_remove_effects_for_card(str(trap_card["instance_id"]))
			event_queue.enqueue({
				"type": "trap_triggered",
				"payload": {
					"color": color,
					"card_id": trap_card["card_id"],
					"card_instance_id": trap_card["instance_id"],
					"square": destination_name,
					"triggered_by": moving_color,
				},
			})
		players[color] = player
	event_queue.resolve_all()


func _does_trap_trigger(trap_card: Dictionary, moving_color: String) -> bool:
	var trigger_condition := str(trap_card.get("trigger_condition", "")).strip_edges().to_lower()
	if trigger_condition.is_empty():
		return moving_color != str(trap_card.get("controller", ""))
	match trigger_condition:
		"when_opposing_piece_enters":
			return moving_color != str(trap_card.get("controller", ""))
		"when_any_piece_enters":
			return true
		"when_friendly_piece_enters":
			return moving_color == str(trap_card.get("controller", ""))
		_:
			return false


func _expire_temporary_effects(expiry_point: String) -> void:
	if expiry_point != "end_of_turn":
		return
	for index in range(active_effects.size() - 1, -1, -1):
		var effect_entry: Dictionary = active_effects[index]
		if str(effect_entry.get("duration", "")) != EFFECT_DURATION_UNTIL_END_OF_TURN:
			continue
		active_effects.remove_at(index)
		event_queue.enqueue({
			"type": "effect_expired",
			"payload": effect_entry,
		})


func _reset_players() -> void:
	players = {
		ChessMatch.WHITE: {
			"color": ChessMatch.WHITE,
			"deck": [],
			"hand": [],
			"battlefield": [],
			"graveyard": [],
			"exile": [],
			"mana": 0,
			"maximum_mana": 0,
			"mulligan_available": true,
			"setup_ready": false,
		},
		ChessMatch.BLACK: {
			"color": ChessMatch.BLACK,
			"deck": [],
			"hand": [],
			"battlefield": [],
			"graveyard": [],
			"exile": [],
			"mana": 0,
			"maximum_mana": 0,
			"mulligan_available": true,
			"setup_ready": false,
		},
	}


func _result(ok: bool, reason: String = "") -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
	}
