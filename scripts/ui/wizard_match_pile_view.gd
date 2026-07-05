extends PanelContainer
class_name WizardMatchPileView

@export var zone_name: String = "Deck"
@export var owner_color: String = ""

var count_label: Label
var visual_rect: TextureRect
var top_card_widget: WizardMatchCardWidget
var hidden_texture: Texture2D


func _ready() -> void:
	count_label = _find_first_label(self)
	visual_rect = _find_first_texture_rect(self)
	top_card_widget = _find_first_card_widget(self)
	if visual_rect != null:
		hidden_texture = visual_rect.texture
	_apply_tooltip(0)


func set_pile_state(next_owner_color: String, next_zone_name: String, count: int, top_card_name: String = "", top_card_art_path: String = "", top_card_state: Dictionary = {}) -> void:
	owner_color = next_owner_color
	zone_name = next_zone_name
	if count_label == null:
		count_label = _find_first_label(self)
	if visual_rect == null:
		visual_rect = _find_first_texture_rect(self)
		if visual_rect != null and hidden_texture == null:
			hidden_texture = visual_rect.texture
	if top_card_widget == null:
		top_card_widget = _find_first_card_widget(self)
	if count_label != null:
		count_label.text = str(count)
	var show_public_card := zone_name.to_lower() == "graveyard" and count > 0 and not top_card_state.is_empty() and top_card_widget != null
	if visual_rect != null:
		visual_rect.visible = not show_public_card
		visual_rect.texture = _zone_texture(top_card_art_path)
		visual_rect.modulate = _zone_modulate(count)
	if top_card_widget != null:
		top_card_widget.visible = show_public_card
		if show_public_card:
			top_card_widget.configure(null, top_card_state, owner_color, _zone_texture(top_card_art_path), false)
			top_card_widget.modulate = Color.WHITE
	_apply_tooltip(count, top_card_name)


func _apply_tooltip(count: int, top_card_name: String = "") -> void:
	var label := "%s %s: %d" % [owner_color.capitalize(), zone_name, count]
	if not top_card_name.is_empty():
		label += "\nTop: %s" % top_card_name
	tooltip_text = label.strip_edges()


func _zone_modulate(count: int) -> Color:
	if count <= 0:
		return Color(0.46, 0.46, 0.52, 0.58)
	if zone_name.to_lower() == "graveyard":
		return Color(1, 1, 1, 0.92)
	return Color(1, 1, 1, 1)


func _zone_texture(top_card_art_path: String) -> Texture2D:
	if zone_name.to_lower() != "graveyard":
		return hidden_texture
	if top_card_art_path.is_empty():
		return hidden_texture
	var texture := load(top_card_art_path) as Texture2D
	return texture if texture != null else hidden_texture


func _find_first_label(root: Node) -> Label:
	for child in root.get_children():
		if child is WizardMatchCardWidget:
			continue
		var label := child as Label
		if label != null:
			return label
		var nested := _find_first_label(child)
		if nested != null:
			return nested
	return null


func _find_first_texture_rect(root: Node) -> TextureRect:
	for child in root.get_children():
		if child is WizardMatchCardWidget:
			continue
		var texture_rect := child as TextureRect
		if texture_rect != null and texture_rect.name != "PileWellFrame":
			return texture_rect
		var nested := _find_first_texture_rect(child)
		if nested != null:
			return nested
	return null


func _find_first_card_widget(root: Node) -> WizardMatchCardWidget:
	for child in root.get_children():
		var card_widget := child as WizardMatchCardWidget
		if card_widget != null:
			return card_widget
		var nested := _find_first_card_widget(child)
		if nested != null:
			return nested
	return null
