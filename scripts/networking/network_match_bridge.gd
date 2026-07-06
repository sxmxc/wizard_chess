extends Node
class_name NetworkMatchBridge

const DEFAULT_PORT := 7000
const DEFAULT_MAX_CLIENTS := 2
const SESSION_STORE_PATH := "user://network_session.cfg"
const MATCH_COLORS := [ChessEngine.WHITE, ChessEngine.BLACK]
const RULES_RESOURCE_PATH := "res://content/config/default_wizard_match_rules.tres"
const DECK_RESOURCE_PATH := "res://content/decks/sample_ai_battle_deck.tres"

signal snapshot_applied(snapshot: Dictionary)
signal action_rejected(action: Dictionary, reason: String)
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal connection_succeeded
signal connection_failed
signal server_disconnected
signal session_updated(player_id: String, color: String)

var wizard_match := _create_authoritative_match()
var host_player_enabled := false
var players_by_id := {}
var peer_to_player := {}
var reconnect_token_to_player := {}
var local_player_id := ""
var local_reconnect_token := ""
var local_client_profile_id := "default"
var current_server_address := ""
var current_server_port := DEFAULT_PORT


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	_log_info("Ready.", {"path": get_path()})


func start_server(
	port: int = DEFAULT_PORT,
	max_clients: int = DEFAULT_MAX_CLIENTS,
	allow_host_player: bool = false
) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, max_clients)
	if error != OK:
		_log_error("Server creation failed.", {"port": port, "max_clients": max_clients, "error": error})
		return error

	multiplayer.multiplayer_peer = peer
	host_player_enabled = allow_host_player
	local_client_profile_id = "host" if allow_host_player else "server"
	current_server_address = ""
	current_server_port = port
	_reset_session_state()
	if allow_host_player:
		var host_player_id := _create_player_session(ChessEngine.WHITE)
		_bind_player_to_peer(host_player_id, 1)
		local_player_id = host_player_id
		local_reconnect_token = str(players_by_id[host_player_id]["reconnect_token"])
	_initialize_authoritative_match()
	_log_info("Server started.", {
		"port": port,
		"max_clients": max_clients,
		"host_player_enabled": allow_host_player,
	})
	_broadcast_snapshot()
	return OK


func start_client(address: String, port: int = DEFAULT_PORT, client_profile_id: String = "default") -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		_log_error("Client creation failed.", {"address": address, "port": port, "error": error})
		return error

	multiplayer.multiplayer_peer = peer
	host_player_enabled = false
	local_client_profile_id = client_profile_id
	current_server_address = address
	current_server_port = port
	_reset_session_state()
	_restore_local_session(address, port)
	_log_info("Client started.", {"address": address, "port": port})
	return OK


func stop_network() -> void:
	_log_info("Stopping multiplayer peer.")
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	peer_to_player.clear()


func reset_match() -> bool:
	if not multiplayer.is_server():
		_log_warn("Reset requested by non-server peer.")
		return false

	_log_info("Resetting authoritative match.")
	_initialize_authoritative_match()
	_broadcast_snapshot()
	return true


func submit_local_action(action: Dictionary) -> void:
	_log_info("Local action submitted.", {
		"peer_id": multiplayer.get_unique_id(),
		"action": action,
		"is_server": multiplayer.is_server(),
	})
	if multiplayer.is_server():
		_process_action(multiplayer.get_unique_id(), action)
		return

	submit_action.rpc_id(1, action)


func get_local_player_color() -> String:
	if local_player_id.is_empty():
		return ""
	return str(players_by_id.get(local_player_id, {}).get("color", ""))


func get_local_player_id() -> String:
	return local_player_id


func get_player_color_assignments() -> Dictionary:
	var assignments := {}
	for player_id in players_by_id.keys():
		var player_data: Dictionary = players_by_id[player_id]
		assignments[str(player_data.get("color", ""))] = {
			"player_id": player_id,
			"connected": bool(player_data.get("connected", false)),
		}
	return assignments


func is_local_players_turn() -> bool:
	var local_color := get_local_player_color()
	return wizard_match.can_color_submit_action(local_color)


@rpc("any_peer", "reliable")
func submit_action(action: Dictionary) -> void:
	if not multiplayer.is_server():
		_log_warn("Received submit_action on non-server peer.", {"action": action})
		return

	_process_action(multiplayer.get_remote_sender_id(), action)


@rpc("any_peer", "reliable")
func register_player_session(reconnect_token: String) -> void:
	if not multiplayer.is_server():
		_log_warn("Received register_player_session on non-server peer.")
		return

	_register_remote_peer(multiplayer.get_remote_sender_id(), reconnect_token)


@rpc("authority", "reliable")
func receive_snapshot(snapshot: Dictionary) -> void:
	_log_info("Snapshot received.", {
		"peer_id": multiplayer.get_unique_id(),
		"active_color": snapshot.get("chess_state", {}).get("fen", "").split(" ")[1] if str(snapshot.get("chess_state", {}).get("fen", "")).contains(" ") else "",
	})
	_apply_snapshot(snapshot)


@rpc("authority", "reliable")
func receive_action_rejection(action: Dictionary, reason: String) -> void:
	_log_warn("Action rejected by server.", {"action": action, "reason": reason})
	action_rejected.emit(action, reason)


@rpc("authority", "reliable")
func receive_session_assignment(player_id: String, reconnect_token: String, color: String) -> void:
	local_player_id = player_id
	local_reconnect_token = reconnect_token
	_persist_local_session()
	_log_info("Session assignment received.", {
		"player_id": player_id,
		"color": color,
	})
	session_updated.emit(player_id, color)


@rpc("authority", "reliable")
func receive_session_rejection(reason: String) -> void:
	_log_warn("Session registration rejected.", {"reason": reason})
	action_rejected.emit({"type": "session_registration"}, reason)


func _process_action(sender_id: int, action: Dictionary) -> void:
	_log_info("Processing action.", {"sender_id": sender_id, "action": action})
	var rejection_reason := _validate_action_sender(sender_id, action)
	if not rejection_reason.is_empty():
		_reject_action(sender_id, action, rejection_reason)
		return

	var assigned_color := str(players_by_id.get(str(peer_to_player.get(sender_id, "")), {}).get("color", ""))
	var result := wizard_match.apply_action(action, assigned_color)
	if not result["ok"]:
		_reject_action(sender_id, action, str(result["reason"]))
		return

	_log_info("Action accepted.", {
		"sender_id": sender_id,
		"action": action,
		"fen": wizard_match.chess_engine.to_fen(),
	})
	_broadcast_snapshot()


func _validate_action_sender(sender_id: int, _action: Dictionary) -> String:
	var player_id := str(peer_to_player.get(sender_id, ""))
	if player_id.is_empty():
		return "peer_not_registered"

	var assigned_color := str(players_by_id.get(player_id, {}).get("color", ""))
	if assigned_color.is_empty():
		return "peer_not_assigned"

	if not wizard_match.can_color_submit_action(assigned_color, _action):
		return "not_your_turn"

	return ""


func _reject_action(sender_id: int, action: Dictionary, reason: String) -> void:
	_log_warn("Rejecting action.", {
		"sender_id": sender_id,
		"action": action,
		"reason": reason,
	})
	if sender_id == multiplayer.get_unique_id():
		action_rejected.emit(action, reason)
		return

	receive_action_rejection.rpc_id(sender_id, action, reason)


func _broadcast_snapshot() -> void:
	var snapshot := _create_snapshot()
	_log_info("Broadcasting snapshot.", {
		"peer_count": multiplayer.get_peers().size(),
		"fen": snapshot.get("chess_state", {}).get("fen", ""),
		"session_players": snapshot.get("session_players", {}),
	})
	if multiplayer.is_server():
		var local_viewer_color := get_local_player_color()
		snapshot_applied.emit(_create_snapshot(local_viewer_color))
	else:
		_apply_snapshot(snapshot)

	if not multiplayer.is_server():
		return
	for peer_id in multiplayer.get_peers():
		var player_id := str(peer_to_player.get(peer_id, ""))
		var viewer_color := str(players_by_id.get(player_id, {}).get("color", ""))
		receive_snapshot.rpc_id(peer_id, _create_snapshot(viewer_color))


func _create_snapshot(viewer_color: String = "") -> Dictionary:
	var snapshot := wizard_match.create_network_snapshot(viewer_color)
	snapshot["session_players"] = _create_public_player_snapshot()
	return snapshot


func _apply_snapshot(snapshot: Dictionary) -> void:
	wizard_match.load_state_snapshot(snapshot)
	if not multiplayer.is_server():
		players_by_id = snapshot.get("session_players", {}).duplicate(true)
	_log_info("Snapshot applied.", {
		"peer_id": multiplayer.get_unique_id(),
		"fen": wizard_match.chess_engine.to_fen(),
		"session_players": _create_public_player_snapshot() if multiplayer.is_server() else players_by_id,
	})
	snapshot_applied.emit(snapshot)


func _on_peer_connected(peer_id: int) -> void:
	_log_info("Peer connected.", {"peer_id": peer_id, "is_server": multiplayer.is_server()})
	peer_connected.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	_log_info("Peer disconnected.", {"peer_id": peer_id, "is_server": multiplayer.is_server()})
	if multiplayer.is_server():
		var player_id := str(peer_to_player.get(peer_id, ""))
		if not player_id.is_empty():
			_mark_player_disconnected(player_id)
			peer_to_player.erase(peer_id)
		_broadcast_snapshot()
	peer_disconnected.emit(peer_id)


func _on_connected_to_server() -> void:
	_log_info("Connected to server.", {"peer_id": multiplayer.get_unique_id()})
	register_player_session.rpc_id(1, local_reconnect_token)
	connection_succeeded.emit()


func _on_connection_failed() -> void:
	_log_error("Connection to server failed.")
	connection_failed.emit()


func _on_server_disconnected() -> void:
	_log_error("Server disconnected.")
	server_disconnected.emit()


func _register_remote_peer(peer_id: int, reconnect_token: String) -> void:
	var player_id := _resolve_or_create_player(peer_id, reconnect_token)
	if player_id.is_empty():
		var rejection_reason := "match_full"
		if not reconnect_token.is_empty() and reconnect_token_to_player.has(reconnect_token):
			rejection_reason = "session_already_active"
		_log_warn("Rejecting session registration.", {"peer_id": peer_id, "reason": rejection_reason})
		receive_session_rejection.rpc_id(peer_id, rejection_reason)
		return

	var player_data: Dictionary = players_by_id[player_id]
	_log_info("Registered remote peer.", {
		"peer_id": peer_id,
		"player_id": player_id,
		"color": player_data.get("color", ""),
		"reconnected": reconnect_token == str(player_data.get("reconnect_token", "")) and not reconnect_token.is_empty(),
	})
	receive_session_assignment.rpc_id(
		peer_id,
		player_id,
		str(player_data.get("reconnect_token", "")),
		str(player_data.get("color", ""))
	)
	_send_snapshot_to_peer(peer_id)
	_broadcast_snapshot()


func _resolve_or_create_player(peer_id: int, reconnect_token: String) -> String:
	if not reconnect_token.is_empty():
		var existing_player_id := str(reconnect_token_to_player.get(reconnect_token, ""))
		if not existing_player_id.is_empty():
			if bool(players_by_id.get(existing_player_id, {}).get("connected", false)):
				_log_warn("Reconnect token belongs to an active player.", {
					"peer_id": peer_id,
					"player_id": existing_player_id,
				})
				return ""
			_bind_player_to_peer(existing_player_id, peer_id)
			return existing_player_id

	var color := _next_available_color()
	if color.is_empty():
		return ""

	var player_id := _create_player_session(color)
	_bind_player_to_peer(player_id, peer_id)
	return player_id


func _create_player_session(color: String) -> String:
	var player_id := _generate_identifier("player")
	var reconnect_token := _generate_identifier("token")
	players_by_id[player_id] = {
		"player_id": player_id,
		"color": color,
		"connected": false,
		"peer_id": 0,
		"reconnect_token": reconnect_token,
	}
	reconnect_token_to_player[reconnect_token] = player_id
	_log_info("Created player session.", {"player_id": player_id, "color": color})
	return player_id


func _bind_player_to_peer(player_id: String, peer_id: int) -> void:
	var previous_player_id := str(peer_to_player.get(peer_id, ""))
	if not previous_player_id.is_empty() and previous_player_id != player_id:
		_mark_player_disconnected(previous_player_id)

	var previous_peer_id := int(players_by_id.get(player_id, {}).get("peer_id", 0))
	if previous_peer_id > 0 and previous_peer_id != peer_id:
		peer_to_player.erase(previous_peer_id)

	peer_to_player[peer_id] = player_id
	players_by_id[player_id]["peer_id"] = peer_id
	players_by_id[player_id]["connected"] = true
	_log_info("Bound player to peer.", {"player_id": player_id, "peer_id": peer_id})


func _mark_player_disconnected(player_id: String) -> void:
	if not players_by_id.has(player_id):
		return
	players_by_id[player_id]["connected"] = false
	players_by_id[player_id]["peer_id"] = 0
	_log_info("Marked player disconnected.", {"player_id": player_id})


func _next_available_color() -> String:
	var taken_colors := []
	for player_id in players_by_id.keys():
		taken_colors.append(str(players_by_id[player_id].get("color", "")))

	for color in MATCH_COLORS:
		if not taken_colors.has(color):
			return color
	return ""


func _create_public_player_snapshot() -> Dictionary:
	var public_players := {}
	for player_id in players_by_id.keys():
		var player_data: Dictionary = players_by_id[player_id]
		public_players[player_id] = {
			"player_id": player_id,
			"color": str(player_data.get("color", "")),
			"connected": bool(player_data.get("connected", false)),
			"peer_id": int(player_data.get("peer_id", 0)),
		}
	return public_players


func _send_snapshot_to_peer(peer_id: int) -> void:
	_log_info("Sending snapshot to peer.", {"peer_id": peer_id})
	var player_id := str(peer_to_player.get(peer_id, ""))
	var viewer_color := str(players_by_id.get(player_id, {}).get("color", ""))
	receive_snapshot.rpc_id(peer_id, _create_snapshot(viewer_color))


func _reset_session_state() -> void:
	players_by_id.clear()
	peer_to_player.clear()
	reconnect_token_to_player.clear()
	local_player_id = ""
	local_reconnect_token = ""


func _persist_local_session() -> void:
	if current_server_address.is_empty():
		return

	var config := ConfigFile.new()
	config.load(SESSION_STORE_PATH)
	var section := _session_section_name(current_server_address, current_server_port, local_client_profile_id)
	config.set_value(section, "player_id", local_player_id)
	config.set_value(section, "reconnect_token", local_reconnect_token)
	var save_error := config.save(SESSION_STORE_PATH)
	if save_error != OK:
		_log_warn("Failed to persist local session.", {"error": save_error, "section": section})


func _restore_local_session(address: String, port: int) -> void:
	var config := ConfigFile.new()
	var load_error := config.load(SESSION_STORE_PATH)
	if load_error != OK:
		_log_info("No persisted session found.", {"address": address, "port": port})
		return

	var section := _session_section_name(address, port, local_client_profile_id)
	local_player_id = str(config.get_value(section, "player_id", ""))
	local_reconnect_token = str(config.get_value(section, "reconnect_token", ""))
	_log_info("Restored local session.", {
		"address": address,
		"port": port,
		"profile": local_client_profile_id,
		"has_player_id": not local_player_id.is_empty(),
		"has_reconnect_token": not local_reconnect_token.is_empty(),
	})


func _session_section_name(address: String, port: int, client_profile_id: String) -> String:
	return "%s:%d:%s" % [address, port, client_profile_id]


func _generate_identifier(prefix: String) -> String:
	return "%s_%s_%s" % [prefix, Time.get_ticks_usec(), randi()]


func _create_authoritative_match() -> WizardMatch:
	var rules := load(RULES_RESOURCE_PATH) as WizardMatchRules
	return WizardMatch.new(rules)


func _initialize_authoritative_match() -> void:
	wizard_match = _create_authoritative_match()
	var default_deck := CardCatalog.load_deck_definition(DECK_RESOURCE_PATH)
	if default_deck == null:
		_log_error("Failed to load default deck for authoritative match.", {"path": DECK_RESOURCE_PATH})
		return
	var result := wizard_match.start_match(default_deck, default_deck, 1)
	if not result["ok"]:
		_log_error("Failed to initialize authoritative WizardMatch.", {"reason": result["reason"]})
		return
	wizard_match.keep_opening_hand(ChessEngine.WHITE)
	wizard_match.keep_opening_hand(ChessEngine.BLACK)


func _role_label() -> String:
	return "Server" if multiplayer.is_server() else "Client"


func _log_prefix() -> String:
	return "[%s][NetworkMatchBridge]" % _role_label()


func _log_info(message: String, data: Variant = null) -> void:
	if data == null:
		Log.info("%s %s" % [_log_prefix(), message])
		return
	Log.info("%s %s" % [_log_prefix(), message], data)


func _log_warn(message: String, data: Variant = null) -> void:
	if data == null:
		Log.warn("%s %s" % [_log_prefix(), message])
		return
	Log.warn("%s %s" % [_log_prefix(), message], data)


func _log_error(message: String, data: Variant = null) -> void:
	if data == null:
		Log.error("%s %s" % [_log_prefix(), message])
		return
	Log.error("%s %s" % [_log_prefix(), message], data)
