extends "res://scripts/ui/local_chess_screen.gd"

var match_bridge: NetworkMatchBridge
var transient_message := ""


func _ready() -> void:
	match_bridge = get_node("/root/Bootstrap/NetworkRoot/MatchBridge")
	match_bridge.snapshot_applied.connect(_on_snapshot_applied)
	match_bridge.action_rejected.connect(_on_action_rejected)
	match_bridge.connection_succeeded.connect(_on_connection_succeeded)
	match_bridge.connection_failed.connect(_on_connection_failed)
	match_bridge.server_disconnected.connect(_on_server_disconnected)
	super._ready()


func _initialize_match() -> ChessMatch:
	if match_bridge == null:
		match_bridge = get_node("/root/Bootstrap/NetworkRoot/MatchBridge")
	return match_bridge.chess_match


func _refresh_status() -> void:
	super._refresh_status()
	var local_color := match_bridge.get_local_player_color()
	if local_color.is_empty():
		detail_label.text = "Waiting for a player assignment from the server."
		return

	if not transient_message.is_empty():
		detail_label.text = transient_message
		return

	if pending_promotion_moves.is_empty():
		if match_bridge.is_local_players_turn():
			detail_label.text = "You are %s. Select a piece, then select a legal destination." % local_color.capitalize()
		else:
			detail_label.text = "You are %s. Waiting for %s to move." % [
				local_color.capitalize(),
				_match_color_name(chess_match.active_color),
			]


func _request_move(move: Dictionary) -> void:
	match_bridge.submit_local_action(
		chess_match.create_move_action(move["from"], move["to"], str(move.get("promotion", "")))
	)


func _request_claim_draw() -> void:
	match_bridge.submit_local_action({
		"type": ChessMatch.ACTION_TYPE_CLAIM_DRAW,
	})


func _request_reset() -> void:
	match_bridge.reset_match()


func _can_submit_actions() -> bool:
	return match_bridge.is_local_players_turn()


func _can_reset_match() -> bool:
	return multiplayer.is_server()


func _on_snapshot_applied(_snapshot: Dictionary) -> void:
	transient_message = ""
	_refresh_ui()


func _on_action_rejected(_action: Dictionary, reason: String) -> void:
	transient_message = _rejection_text(reason)
	_refresh_ui()


func _on_connection_succeeded() -> void:
	transient_message = ""
	_refresh_ui()


func _on_connection_failed() -> void:
	transient_message = "Connection failed."
	_refresh_ui()


func _on_server_disconnected() -> void:
	transient_message = "Disconnected from server."
	_refresh_ui()


func _rejection_text(reason: String) -> String:
	match reason:
		"peer_not_assigned":
			return "The server has not assigned you a seat yet."
		"not_your_turn":
			return "It is not your turn."
		"illegal_move":
			return "The server rejected that move as illegal."
		"draw_unavailable":
			return "A draw cannot be claimed right now."
		_:
			return "Action rejected: %s" % reason
