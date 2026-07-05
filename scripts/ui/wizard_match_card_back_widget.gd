extends Control
class_name WizardMatchCardBackWidget

const CARD_BACK_TEXTURE := preload("res://assets/ui/wizard_match/card_back.png")

var card_instance_id: String = ""

@onready var card_back_rect: TextureRect = %CardBackRect


func configure(next_card_instance_id: String) -> void:
	card_instance_id = next_card_instance_id
	if is_node_ready():
		card_back_rect.texture = CARD_BACK_TEXTURE


func get_card_center_global() -> Vector2:
	return global_position + (size * 0.5)


func get_card_instance_id() -> String:
	return card_instance_id


func _ready() -> void:
	card_back_rect.texture = CARD_BACK_TEXTURE
