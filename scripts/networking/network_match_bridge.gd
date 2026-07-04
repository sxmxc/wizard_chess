extends Node
class_name NetworkMatchBridge

const DEFAULT_PORT := 7000
const DEFAULT_MAX_CLIENTS := 2

signal snapshot_applied(snapshot: Dictionary)
signal action_rejected(action: Dictionary, reason: String)
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal connection_succeeded
signal connection_failed
signal server_disconnected

var chess_match := ChessMatch.new()
var player_colors := {}
var host_player_enabled := false


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func start_server(port: int = DEFAULT_PORT, max_clients: int = DEFAULT_MAX_CLIENTS, allow_host_player: bool = false) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, max_clients)
	if error != OK:
		return error

	multiplayer.multiplayer_peer = peer
	host_player_enabled = allow_host_player
	player_colors.clear()
	if allow_host_player:
		player_colors[1] = ChessMatch.WHITE
	_broadcast_snapshot()
	return OK


func start_client(address: String, port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		return error

	multiplayer.multiplayer_peer = peer
	host_player_enabled = false
	player_colors.clear()
	return OK


func stop_network() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	player_colors.clear()


func reset_match() -> bool:
	if not multiplayer.is_server():
		return false

	chess_match.reset()
	_broadcast_snapshot()
	return true


func submit_local_action(action: Dictionary) -> void:
	if multiplayer.is_server():
		_process_action(multiplayer.get_unique_id(), action)
		return

	submit_action.rpc_id(1, action)


func get_local_player_color() -> String:
	return str(player_colors.get(multiplayer.get_unique_id(), ""))


func is_local_players_turn() -> bool:
	var local_color := get_local_player_color()
	return not local_color.is_empty() and local_color == chess_match.active_color


@rpc("any_peer", "reliable")
func submit_action(action: Dictionary) -> void:
	if not multiplayer.is_server():
		return

	_process_action(multiplayer.get_remote_sender_id(), action)


@rpc("authority", "reliable")
func receive_snapshot(snapshot: Dictionary) -> void:
	_apply_snapshot(snapshot)


@rpc("authority", "reliable")
func receive_action_rejection(action: Dictionary, reason: String) -> void:
	action_rejected.emit(action, reason)


func _process_action(sender_id: int, action: Dictionary) -> void:
	var rejection_reason := _validate_action_sender(sender_id, action)
	if not rejection_reason.is_empty():
		_reject_action(sender_id, action, rejection_reason)
		return

	var result := chess_match.apply_action_payload(action)
	if not result["ok"]:
		_reject_action(sender_id, action, str(result["reason"]))
		return

	_broadcast_snapshot()


func _validate_action_sender(sender_id: int, action: Dictionary) -> String:
	var assigned_color := str(player_colors.get(sender_id, ""))
	if assigned_color.is_empty():
		return "peer_not_assigned"

	if assigned_color != chess_match.active_color:
		return "not_your_turn"

	var action_type := str(action.get("type", ""))
	if action_type != ChessMatch.ACTION_TYPE_MOVE and action_type != ChessMatch.ACTION_TYPE_CLAIM_DRAW:
		return "unsupported_action"

	return ""


func _reject_action(sender_id: int, action: Dictionary, reason: String) -> void:
	if sender_id == multiplayer.get_unique_id():
		action_rejected.emit(action, reason)
		return

	receive_action_rejection.rpc_id(sender_id, action, reason)


func _broadcast_snapshot() -> void:
	var snapshot := _create_snapshot()
	_apply_snapshot(snapshot)
	if not multiplayer.is_server():
		return

	for peer_id in multiplayer.get_peers():
		receive_snapshot.rpc_id(peer_id, snapshot)


func _create_snapshot() -> Dictionary:
	var snapshot := chess_match.create_state_snapshot()
	snapshot["player_colors"] = player_colors.duplicate(true)
	return snapshot


func _apply_snapshot(snapshot: Dictionary) -> void:
	chess_match.load_state_snapshot(snapshot)
	player_colors = snapshot.get("player_colors", {}).duplicate(true)
	snapshot_applied.emit(snapshot)


func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		_assign_player_color(peer_id)
		_send_snapshot_to_peer(peer_id)
		_broadcast_snapshot()
	peer_connected.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	if multiplayer.is_server():
		player_colors.erase(peer_id)
		_broadcast_snapshot()
	peer_disconnected.emit(peer_id)


func _on_connected_to_server() -> void:
	connection_succeeded.emit()


func _on_connection_failed() -> void:
	connection_failed.emit()


func _on_server_disconnected() -> void:
	server_disconnected.emit()


func _assign_player_color(peer_id: int) -> void:
	if player_colors.has(peer_id):
		return

	for color in [ChessMatch.WHITE, ChessMatch.BLACK]:
		if not player_colors.values().has(color):
			player_colors[peer_id] = color
			return


func _send_snapshot_to_peer(peer_id: int) -> void:
	receive_snapshot.rpc_id(peer_id, _create_snapshot())
