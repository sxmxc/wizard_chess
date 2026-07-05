extends PanelContainer
class_name WizardMatchTurnActionPanel

@onready var detail_label: Label = %DetailLabel
@onready var action_hint_label: Label = %ActionHintLabel
@onready var action_bar: HBoxContainer = %ActionBar


func set_phase_summary(detail: String, hint: String) -> void:
	if not is_node_ready():
		call_deferred("set_phase_summary", detail, hint)
		return
	detail_label.text = detail
	action_hint_label.text = hint


func clear_actions() -> void:
	if not is_node_ready():
		call_deferred("clear_actions")
		return
	for child in action_bar.get_children():
		child.queue_free()


func add_action(label: String, callback: Callable, disabled: bool = false, primary: bool = false) -> Button:
	if not is_node_ready():
		return null
	var button := Button.new()
	button.text = label
	button.disabled = disabled
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size = Vector2(0, 36 if primary else 30)
	if primary:
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color(0.96, 0.90, 0.72, 1.0))
		button.add_theme_constant_override("outline_size", 2)
		button.add_theme_color_override("font_outline_color", Color(0.02, 0.015, 0.01, 1.0))
	if callback.is_valid():
		button.pressed.connect(callback)
	action_bar.add_child(button)
	return button


func show_waiting(message: String, hint: String) -> void:
	clear_actions()
	set_phase_summary(message, hint)
