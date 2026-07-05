extends Button
class_name WizardMatchHandCardButton

var screen: Control
var card_state: Dictionary = {}


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _get_drag_data(_at_position: Vector2):
	if screen == null:
		return null
	return screen.get_hand_card_drag_data(card_state)
