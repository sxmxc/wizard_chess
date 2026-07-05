extends PanelContainer
class_name WizardMatchCardPlayZone

var screen: Control


func _can_drop_data(_at_position: Vector2, data) -> bool:
	return screen != null and screen.can_drop_on_play_zone(data)


func _drop_data(_at_position: Vector2, data) -> void:
	if screen != null:
		screen.handle_play_zone_drop(data)
