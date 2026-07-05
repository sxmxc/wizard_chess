class_name WizardMatchInspectorView
extends PanelContainer

@onready var title_label: Label = %InspectTitleLabel
@onready var spotlight_art: TextureRect = %SpotlightArt
@onready var body_label: Label = %InspectBodyLabel
@onready var card_preview_center: CenterContainer = %CardPreviewCenter
@onready var card_preview: WizardMatchCardWidget = %CardPreview
@onready var square_preview_frame: PanelContainer = %SquarePreviewFrame


func clear_inspection() -> void:
	visible = false
	title_label.text = "Selection"
	body_label.text = "Select a square or card to inspect it."
	spotlight_art.texture = null
	card_preview_center.visible = false


func show_card(card_state: Dictionary, zone: String, owner_color: String, art_texture: Texture2D) -> void:
	visible = true
	title_label.text = str(card_state.get("display_name", card_state.get("card_id", "Unknown Card")))
	card_preview_center.visible = true
	card_preview.visible = true
	square_preview_frame.visible = false
	card_preview.configure(
		null,
		card_state,
		owner_color,
		art_texture,
		bool(card_state.get("face_down", false)) and zone != "graveyard"
	)
	var lines: Array[String] = []
	lines.append("Owner: %s  |  Zone: %s" % [owner_color.capitalize(), zone.capitalize()])
	var target_requirements: Array = card_state.get("target_requirements", [])
	if not target_requirements.is_empty():
		lines.append("Targeting: %s" % ", ".join(target_requirements))
	var attached_to := str(card_state.get("attached_to", ""))
	if not attached_to.is_empty():
		lines.append("Attached To: %s" % attached_to)
	var placed_on := str(card_state.get("placed_on", ""))
	if not placed_on.is_empty():
		lines.append("Placed On: %s" % placed_on)
	body_label.text = "\n".join(lines)


func show_square(
	square_name: String,
	piece_texture: Texture2D,
	piece_description: String,
	attached_cards: Array[String],
	legal_moves: Array[String],
	is_threatened: bool
) -> void:
	visible = true
	title_label.text = "Square %s" % square_name
	card_preview_center.visible = true
	card_preview.visible = false
	square_preview_frame.visible = true
	spotlight_art.texture = piece_texture
	var lines: Array[String] = []
	lines.append("Piece: %s" % piece_description)
	lines.append("Attached Units: %s" % ("none" if attached_cards.is_empty() else ", ".join(attached_cards)))
	lines.append("Legal Moves: %s" % ("none" if legal_moves.is_empty() else ", ".join(legal_moves)))
	lines.append("Threatened: %s" % ("yes" if is_threatened else "no"))
	body_label.text = "\n".join(lines)
