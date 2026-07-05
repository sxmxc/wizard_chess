extends Control
class_name WizardMatchPlayerStatusView

@export var portrait_texture: Texture2D:
	set(value):
		_portrait_texture = value
		_apply_portrait()
	get:
		return _portrait_texture
@export var mana_texture: Texture2D:
	set(value):
		_mana_texture = value
		_apply_mana_texture()
	get:
		return _mana_texture

var player_color: String = ""
var current_mana: int = 0
var maximum_mana: int = 0
var _portrait_texture: Texture2D
var _mana_texture: Texture2D

@onready var portrait_rect: TextureRect = %PortraitTexture
@onready var mana_rect: TextureRect = %ManaTexture
@onready var mana_count_label: Label = %ManaCountLabel


func _ready() -> void:
	_apply_portrait()
	_apply_mana_texture()
	_refresh_mana_count()


func set_player_state(next_player_color: String, next_current_mana: int, next_maximum_mana: int) -> void:
	player_color = next_player_color
	current_mana = maxi(0, next_current_mana)
	maximum_mana = maxi(0, next_maximum_mana)
	tooltip_text = "%s wizard\nMana %d/%d" % [player_color.capitalize(), current_mana, maximum_mana]
	_refresh_mana_count()


func _apply_portrait() -> void:
	if not is_node_ready():
		return
	portrait_rect.texture = _portrait_texture


func _apply_mana_texture() -> void:
	if not is_node_ready():
		return
	mana_rect.texture = _mana_texture


func _refresh_mana_count() -> void:
	if not is_node_ready():
		return
	mana_count_label.text = str(current_mana)
