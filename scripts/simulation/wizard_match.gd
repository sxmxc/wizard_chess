extends RefCounted
class_name WizardMatch

const STATE_SETUP := "setup"
const STATE_ACTIVE := "active"
const STATE_COMPLETE := "complete"

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

const ACTION_TYPE_ADVANCE_PHASE := "advance_phase"
const ACTION_TYPE_PLAY_CARD := "play_card"
const ACTION_TYPE_MOVE := "move"

var chess_state := ChessState.new()
var chess_engine := ChessEngine.new(chess_state)
var rules: WizardMatchRules
var event_queue := GameEventQueue.new()
var state: String = STATE_SETUP
var phase: String = PHASE_BEGINNING
var turn_number: int = 0
var rng_seed: int = 1
var _next_card_instance_id: int = 1
var players := {}


func _init(match_rules: WizardMatchRules = null) -> void:
	rules = match_rules if match_rules != null else WizardMatchRules.new()
	_reset_players()


func start_match(white_deck: DeckDefinition, black_deck: DeckDefinition, seed: int = 1) -> void:
	chess_engine.reset()
	event_queue.clear()
	state = STATE_ACTIVE
	phase = PHASE_BEGINNING
	turn_number = 1
	rng_seed = seed
	_next_card_instance_id = 1
	_reset_players()
	_initialize_player(ChessMatch.WHITE, white_deck, seed)
	_initialize_player(ChessMatch.BLACK, black_deck, seed + 1)
	event_queue.enqueue({
		"type": "match_started",
		"payload": {
			"seed": rng_seed,
			"active_color": chess_state.active_color,
		},
	})
	event_queue.resolve_all()


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

	var result := chess_engine.apply_action_payload(action)
	if not result["ok"]:
		return result

	event_queue.enqueue({
		"type": "chess_move_resolved",
		"payload": {
			"action": action.duplicate(true),
			"fen": chess_engine.to_fen(),
		},
	})
	event_queue.resolve_all()
	phase = PHASE_REACTION
	return _result(true)


func pass_reaction_phase() -> bool:
	if not _can_run_phase(PHASE_REACTION):
		return false
	phase = PHASE_END
	event_queue.enqueue({
		"type": "reaction_phase_passed",
		"payload": {
			"next_phase": phase,
		},
	})
	event_queue.resolve_all()
	return true


func resolve_end_phase() -> bool:
	if not _can_run_phase(PHASE_END):
		return false

	var active_color := _inactive_color()
	_enforce_maximum_hand_size(active_color)
	event_queue.enqueue({
		"type": "turn_ended",
		"payload": {
			"completed_color": active_color,
			"next_color": chess_state.active_color,
		},
	})
	event_queue.resolve_all()
	turn_number += 1
	phase = PHASE_BEGINNING
	_refresh_state_from_chess()
	return true


func play_card_from_hand(card_instance_id: String) -> Dictionary:
	if state != STATE_ACTIVE:
		return _result(false, "match_not_active")

	var active_color := chess_state.active_color
	var player: Dictionary = players[active_color]
	var hand: Array = player["hand"]
	var hand_index := _find_card_index(hand, card_instance_id)
	if hand_index < 0:
		return _result(false, "card_not_in_hand")

	var card_state: Dictionary = hand[hand_index]
	var play_error := _validate_card_play(card_state)
	if not play_error.is_empty():
		return _result(false, play_error)

	player["mana"] = int(player["mana"]) - int(card_state["mana_cost"])
	hand.remove_at(hand_index)
	var destination_zone := ZONE_GRAVEYARD
	if bool(card_state.get("persistent", false)):
		destination_zone = ZONE_BATTLEFIELD
	player[destination_zone].append(card_state)
	players[active_color] = player

	event_queue.enqueue({
		"type": "mana_spent",
		"payload": {
			"color": active_color,
			"mana_cost": card_state["mana_cost"],
			"remaining_mana": player["mana"],
		},
	})
	event_queue.enqueue({
		"type": "card_played",
		"payload": {
			"color": active_color,
			"card_id": card_state["card_id"],
			"card_instance_id": card_state["instance_id"],
			"destination_zone": destination_zone,
		},
	})
	event_queue.resolve_all()
	return _result(true)


func get_player_state(color: String) -> Dictionary:
	return players.get(color, {}).duplicate(true)


func create_state_snapshot() -> Dictionary:
	return {
		"state": state,
		"phase": phase,
		"turn_number": turn_number,
		"rng_seed": rng_seed,
		"next_card_instance_id": _next_card_instance_id,
		"rules": {
			"opening_hand_size": rules.opening_hand_size,
			"maximum_hand_size": rules.maximum_hand_size,
			"starting_mana": rules.starting_mana,
			"maximum_mana_cap": rules.maximum_mana_cap,
			"mana_gained_per_turn": rules.mana_gained_per_turn,
			"cards_drawn_per_turn": rules.cards_drawn_per_turn,
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
	rules = restored_rules
	state = str(snapshot.get("state", STATE_SETUP))
	phase = str(snapshot.get("phase", PHASE_BEGINNING))
	turn_number = int(snapshot.get("turn_number", 0))
	rng_seed = int(snapshot.get("rng_seed", 1))
	_next_card_instance_id = int(snapshot.get("next_card_instance_id", 1))
	players = snapshot.get("players", {}).duplicate(true)
	chess_engine.load_state_snapshot(snapshot.get("chess_state", snapshot.get("chess_match", {})))
	event_queue.load_history(snapshot.get("event_history", []))


func _initialize_player(color: String, deck: DeckDefinition, seed: int) -> void:
	var runtime_deck := _create_runtime_deck(color, deck)
	_shuffle_cards(runtime_deck, seed)
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
	}
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
			"owner": color,
			"controller": color,
			"persistent": card.is_persistent_type(),
			"resource_path": card.resource_path,
		})
		_next_card_instance_id += 1
	return runtime_deck


func _shuffle_cards(cards: Array, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for index in range(cards.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temp = cards[index]
		cards[index] = cards[swap_index]
		cards[swap_index] = temp


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


func _enforce_maximum_hand_size(color: String) -> void:
	var player: Dictionary = players[color]
	while player["hand"].size() > rules.maximum_hand_size:
		var discarded_card: Dictionary = player["hand"].pop_back()
		player["graveyard"].append(discarded_card)
		event_queue.enqueue({
			"type": "hand_size_discard",
			"payload": {
				"color": color,
				"card_id": discarded_card["card_id"],
				"card_instance_id": discarded_card["instance_id"],
			},
		})
	players[color] = player


func _validate_card_play(card_state: Dictionary) -> String:
	if phase != PHASE_PREPARATION and phase != PHASE_REACTION:
		return "wrong_phase"

	if phase == PHASE_PREPARATION and str(card_state["card_type"]) == CardDefinition.TYPE_REACTION:
		return "reaction_only_phase"

	if phase == PHASE_REACTION and str(card_state["card_type"]) != CardDefinition.TYPE_REACTION:
		return "preparation_only_card_type"

	var player: Dictionary = players[chess_state.active_color]
	if int(player["mana"]) < int(card_state["mana_cost"]):
		return "insufficient_mana"

	return ""


func _refresh_state_from_chess() -> void:
	if chess_state.outcome["status"] != ChessMatch.STATUS_ACTIVE:
		state = STATE_COMPLETE


func _inactive_color() -> String:
	return ChessMatch.BLACK if chess_state.active_color == ChessMatch.WHITE else ChessMatch.WHITE


func _can_run_phase(expected_phase: String) -> bool:
	return state == STATE_ACTIVE and phase == expected_phase


func _find_card_index(cards: Array, card_instance_id: String) -> int:
	for index in range(cards.size()):
		if str(cards[index].get("instance_id", "")) == card_instance_id:
			return index
	return -1


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
		},
	}


func _result(ok: bool, reason: String = "") -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
	}
