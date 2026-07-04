extends Node

const LOCAL_CHESS_SCENE := preload("res://scenes/chess/local_chess_screen.tscn")

func _ready() -> void:
	if OS.has_feature("headless"):
		get_tree().quit()
		return

	get_tree().change_scene_to_packed.call_deferred(LOCAL_CHESS_SCENE)
