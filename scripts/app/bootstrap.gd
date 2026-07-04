extends Node

const LOCAL_CHESS_SCENE := preload("res://scenes/chess/local_chess_screen.tscn")
const NETWORK_CHESS_SCENE := preload("res://scenes/chess/network_chess_screen.tscn")

@onready var match_bridge: NetworkMatchBridge = $NetworkRoot/MatchBridge
@onready var content_root: Node = $ContentRoot

func _ready() -> void:
	var launch_options := _parse_launch_options(OS.get_cmdline_args())
	if launch_options["mode"] == "server":
		var server_error: Error = match_bridge.start_server(
			launch_options["port"],
			launch_options["max_clients"],
			false
		)
		if server_error != OK:
			push_error("Failed to start dedicated server: %s" % server_error)
			get_tree().quit()
		return

	if launch_options["mode"] == "host":
		var host_error: Error = match_bridge.start_server(
			launch_options["port"],
			launch_options["max_clients"],
			true
		)
		if host_error != OK:
			push_error("Failed to start host server: %s" % host_error)
			get_tree().quit()
			return
		_load_content_scene(NETWORK_CHESS_SCENE)
		return

	if launch_options["mode"] == "client":
		var client_error: Error = match_bridge.start_client(
			launch_options["address"],
			launch_options["port"]
		)
		if client_error != OK:
			push_error("Failed to connect to server: %s" % client_error)
			get_tree().quit()
			return
		_load_content_scene(NETWORK_CHESS_SCENE)
		return

	if OS.has_feature("headless"):
		get_tree().quit()
		return

	_load_content_scene(LOCAL_CHESS_SCENE)


func _load_content_scene(scene: PackedScene) -> void:
	for child in content_root.get_children():
		child.queue_free()
	content_root.add_child(scene.instantiate(), true)


func _parse_launch_options(args: PackedStringArray) -> Dictionary:
	var options := {
		"mode": "local",
		"address": "127.0.0.1",
		"port": NetworkMatchBridge.DEFAULT_PORT,
		"max_clients": NetworkMatchBridge.DEFAULT_MAX_CLIENTS,
	}

	for arg in args:
		if arg == "--server":
			options["mode"] = "server"
		elif arg == "--host":
			options["mode"] = "host"
		elif arg.begins_with("--connect="):
			options["mode"] = "client"
			options["address"] = arg.trim_prefix("--connect=")
		elif arg.begins_with("--port="):
			options["port"] = int(arg.trim_prefix("--port="))
		elif arg.begins_with("--max-clients="):
			options["max_clients"] = int(arg.trim_prefix("--max-clients="))

	return options
