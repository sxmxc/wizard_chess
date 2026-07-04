extends Node

const DEV_LAUNCHER_SCENE := preload("res://scenes/app/dev_launcher_screen.tscn")
const LOCAL_CHESS_SCENE := preload("res://scenes/chess/local_chess_screen.tscn")
const LOCAL_WIZARD_MATCH_SCENE := preload("res://scenes/chess/local_wizard_match_screen.tscn")
const NETWORK_CHESS_SCENE := preload("res://scenes/chess/network_chess_screen.tscn")

@onready var match_bridge: NetworkMatchBridge = $NetworkRoot/MatchBridge
@onready var content_root: Node = $ContentRoot

var launcher_defaults := {
	"address": "127.0.0.1",
	"port": NetworkMatchBridge.DEFAULT_PORT,
	"profile": "default",
}

func _ready() -> void:
	var launch_options := _parse_launch_options(OS.get_cmdline_args())
	launcher_defaults = {
		"address": launch_options["address"],
		"port": launch_options["port"],
		"profile": launch_options["profile"],
	}
	if launch_options["mode"] == "server":
		if not start_dedicated_server(
			launch_options["port"],
			launch_options["max_clients"],
			true
		):
			return
		return

	if launch_options["mode"] == "host":
		if not start_host_session(
			launch_options["port"],
			launch_options["max_clients"],
			true,
			launch_options["profile"]
		):
			return
		return

	if launch_options["mode"] == "client":
		if not start_client_session(
			launch_options["address"],
			launch_options["port"],
			true,
			launch_options["profile"]
		):
			return
		return

	if OS.has_feature("headless"):
		_log_warn("Headless mode started without an explicit launch mode. Exiting.")
		get_tree().quit()
		return

	_show_dev_launcher()


func _load_content_scene(scene: PackedScene) -> void:
	for child in content_root.get_children():
		child.queue_free()
	content_root.add_child(scene.instantiate(), true)


func start_local_session() -> void:
	_log_info("Starting local hotseat session.", "Local")
	_load_content_scene(LOCAL_CHESS_SCENE)


func start_local_ai_session() -> void:
	_log_info("Starting local Wizard Match AI session.", "LocalAI")
	_load_content_scene(LOCAL_WIZARD_MATCH_SCENE)


func start_dedicated_server(port: int, max_clients: int, quit_on_failure: bool = false) -> bool:
	_log_info("Starting dedicated server.", "Server", {
		"port": port,
		"max_clients": max_clients,
	})
	var server_error: Error = match_bridge.start_server(port, max_clients, false)
	if server_error != OK:
		_log_error("Failed to start dedicated server.", "Server", {"error": server_error})
		if quit_on_failure:
			get_tree().quit()
		else:
			_show_dev_launcher("Failed to start dedicated server.")
		return false
	return true


func start_host_session(
	port: int,
	max_clients: int,
	quit_on_failure: bool = false,
	client_profile_id: String = "host"
) -> bool:
	_log_info("Starting host session.", "Host", {
		"port": port,
		"max_clients": max_clients,
		"profile": client_profile_id,
	})
	var host_error: Error = match_bridge.start_server(port, max_clients, true)
	if host_error != OK:
		_log_error("Failed to start host server.", "Host", {"error": host_error})
		if quit_on_failure:
			get_tree().quit()
		else:
			_show_dev_launcher("Failed to start host server.")
		return false
	_load_content_scene(NETWORK_CHESS_SCENE)
	return true


func start_client_session(
	address: String,
	port: int,
	quit_on_failure: bool = false,
	client_profile_id: String = "default"
) -> bool:
	_log_info("Connecting client.", "Client", {
		"address": address,
		"port": port,
		"profile": client_profile_id,
	})
	var client_error: Error = match_bridge.start_client(address, port, client_profile_id)
	if client_error != OK:
		_log_error("Failed to connect to server.", "Client", {
			"address": address,
			"port": port,
			"profile": client_profile_id,
			"error": client_error,
		})
		if quit_on_failure:
			get_tree().quit()
		else:
			_show_dev_launcher("Failed to connect to %s:%d." % [address, port])
		return false
	_load_content_scene(NETWORK_CHESS_SCENE)
	return true


func show_dev_launcher_with_message(message: String = "") -> void:
	_show_dev_launcher(message)


func _show_dev_launcher(message: String = "") -> void:
	_log_info("Showing development launcher.", "Launcher")
	_load_content_scene(DEV_LAUNCHER_SCENE)
	var launcher := content_root.get_child(content_root.get_child_count() - 1)
	if launcher.has_method("set_launch_defaults"):
		launcher.call("set_launch_defaults", launcher_defaults)
	if launcher.has_method("set_status_message"):
		launcher.call("set_status_message", message)


func _parse_launch_options(args: PackedStringArray) -> Dictionary:
	var options := {
		"mode": "local",
		"address": "127.0.0.1",
		"port": NetworkMatchBridge.DEFAULT_PORT,
		"max_clients": NetworkMatchBridge.DEFAULT_MAX_CLIENTS,
		"profile": "default",
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
		elif arg.begins_with("--profile="):
			options["profile"] = arg.trim_prefix("--profile=")

	return options


func _log_info(message: String, role: String = "Bootstrap", data: Variant = null) -> void:
	if data == null:
		Log.info("[Bootstrap][%s] %s" % [role, message])
		return
	Log.info("[Bootstrap][%s] %s" % [role, message], data)


func _log_warn(message: String, role: String = "Bootstrap", data: Variant = null) -> void:
	if data == null:
		Log.warn("[Bootstrap][%s] %s" % [role, message])
		return
	Log.warn("[Bootstrap][%s] %s" % [role, message], data)


func _log_error(message: String, role: String = "Bootstrap", data: Variant = null) -> void:
	if data == null:
		Log.error("[Bootstrap][%s] %s" % [role, message])
		return
	Log.error("[Bootstrap][%s] %s" % [role, message], data)
