extends Node

func _ready() -> void:
	print("Wizard Chess bootstrap ready.")

	if OS.has_feature("headless"):
		get_tree().quit()
