extends Control

var address_input: LineEdit
var port_input: SpinBox
var profile_input: LineEdit
var status_label: Label
var launch_defaults := {
	"address": "127.0.0.1",
	"port": NetworkMatchBridge.DEFAULT_PORT,
	"profile": "default",
}


func _ready() -> void:
	_build_ui()


func set_status_message(message: String) -> void:
	if status_label != null:
		status_label.text = message


func set_launch_defaults(defaults: Dictionary) -> void:
	launch_defaults["address"] = str(defaults.get("address", launch_defaults["address"]))
	launch_defaults["port"] = int(defaults.get("port", launch_defaults["port"]))
	launch_defaults["profile"] = str(defaults.get("profile", launch_defaults["profile"]))
	if address_input != null:
		address_input.text = launch_defaults["address"]
	if port_input != null:
		port_input.value = launch_defaults["port"]
	if profile_input != null:
		profile_input.text = launch_defaults["profile"]


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	var panel := PanelContainer.new()
	margin.add_child(panel)

	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(420, 0)
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)

	var title := Label.new()
	title.text = "Wizard Chess Dev Launcher"
	title.add_theme_font_size_override("font_size", 28)
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose a local session, host a server, or connect to one."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(subtitle)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(status_label)

	var local_button := Button.new()
	local_button.text = "Play Local Hotseat"
	local_button.pressed.connect(_on_local_pressed)
	root.add_child(local_button)

	var local_ai_button := Button.new()
	local_ai_button.text = "Play Vs AI (Dev)"
	local_ai_button.pressed.connect(_on_local_ai_pressed)
	root.add_child(local_ai_button)

	var host_button := Button.new()
	host_button.text = "Host Network Match"
	host_button.pressed.connect(_on_host_pressed)
	root.add_child(host_button)

	var form := GridContainer.new()
	form.columns = 2
	form.add_theme_constant_override("h_separation", 12)
	form.add_theme_constant_override("v_separation", 8)
	root.add_child(form)

	var address_label := Label.new()
	address_label.text = "Server Address"
	form.add_child(address_label)

	address_input = LineEdit.new()
	address_input.text = launch_defaults["address"]
	form.add_child(address_input)

	var port_label := Label.new()
	port_label.text = "Port"
	form.add_child(port_label)

	port_input = SpinBox.new()
	port_input.min_value = 1
	port_input.max_value = 65535
	port_input.value = launch_defaults["port"]
	port_input.step = 1
	port_input.rounded = true
	form.add_child(port_input)

	var profile_label := Label.new()
	profile_label.text = "Client Profile"
	form.add_child(profile_label)

	profile_input = LineEdit.new()
	profile_input.text = launch_defaults["profile"]
	form.add_child(profile_input)

	var connect_button := Button.new()
	connect_button.text = "Connect To Server"
	connect_button.pressed.connect(_on_connect_pressed)
	root.add_child(connect_button)


func _on_local_pressed() -> void:
	_bootstrap().start_local_session()


func _on_local_ai_pressed() -> void:
	_bootstrap().start_local_ai_session()


func _on_host_pressed() -> void:
	var profile := profile_input.text.strip_edges()
	if profile.is_empty():
		profile = "host"
	_bootstrap().start_host_session(int(port_input.value), NetworkMatchBridge.DEFAULT_MAX_CLIENTS, false, profile)


func _on_connect_pressed() -> void:
	var address := address_input.text.strip_edges()
	var profile := profile_input.text.strip_edges()
	if address.is_empty():
		status_label.text = "Enter a server address."
		return
	if profile.is_empty():
		status_label.text = "Enter a client profile."
		return
	_bootstrap().start_client_session(address, int(port_input.value), false, profile)


func _bootstrap():
	return get_node("/root/Bootstrap")
