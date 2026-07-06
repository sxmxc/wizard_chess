extends TextureRect
class_name WizardMatchBoardSquare

const PIECE_INSET := 6.0

var square: Vector2i = Vector2i.ZERO
var background_rect: ColorRect
var piece_rect: TextureRect
var coordinate_label: Label
var target_indicator: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_overlay_nodes()


func set_square_visuals(
	next_icon: Texture2D,
	next_fill_color: Color,
	coordinate_text: String,
	next_tooltip: String
) -> void:
	_ensure_overlay_nodes()
	background_rect.color = next_fill_color
	background_rect.visible = next_fill_color.a > 0.01
	piece_rect.texture = next_icon
	piece_rect.visible = next_icon != null
	coordinate_label.text = coordinate_text
	coordinate_label.visible = not coordinate_text.is_empty()
	tooltip_text = next_tooltip


func set_target_emphasis(is_target: bool, is_hovered_target: bool) -> void:
	_ensure_overlay_nodes()
	target_indicator.visible = is_target
	target_indicator.text = "◆" if is_hovered_target else "•"
	target_indicator.add_theme_color_override(
		"font_color",
		Color(0.75, 0.98, 1.0, 1.0) if is_hovered_target else Color(0.08, 0.28, 0.38, 0.62)
	)


func _ensure_overlay_nodes() -> void:
	if background_rect == null:
		background_rect = get_node_or_null("OverlayTint") as ColorRect
		if background_rect == null:
			background_rect = ColorRect.new()
			background_rect.name = "OverlayTint"
			background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			background_rect.color = Color(1, 1, 1, 0)
			background_rect.visible = false
			add_child(background_rect)

	if piece_rect == null:
		piece_rect = get_node_or_null("PieceVisual") as TextureRect
		if piece_rect == null:
			piece_rect = TextureRect.new()
			piece_rect.name = "PieceVisual"
			piece_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			piece_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			piece_rect.offset_left = PIECE_INSET
			piece_rect.offset_top = PIECE_INSET
			piece_rect.offset_right = -PIECE_INSET
			piece_rect.offset_bottom = -PIECE_INSET
			piece_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			piece_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			piece_rect.visible = false
			add_child(piece_rect)

	if coordinate_label == null:
		coordinate_label = get_node_or_null("CoordinateLabel") as Label
		if coordinate_label == null:
			coordinate_label = Label.new()
			coordinate_label.name = "CoordinateLabel"
			coordinate_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			coordinate_label.position = Vector2(4, 2)
			coordinate_label.size = Vector2(26, 16)
			coordinate_label.add_theme_font_size_override("font_size", 9)
			coordinate_label.add_theme_color_override("font_color", Color(0.35, 0.27, 0.17, 0.9))
			coordinate_label.visible = false
			add_child(coordinate_label)

	if target_indicator == null:
		target_indicator = get_node_or_null("TargetIndicator") as Label
		if target_indicator == null:
			target_indicator = Label.new()
			target_indicator.name = "TargetIndicator"
			target_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
			target_indicator.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			target_indicator.position = Vector2(-23, 2)
			target_indicator.size = Vector2(20, 20)
			target_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			target_indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			target_indicator.add_theme_font_size_override("font_size", 15)
			target_indicator.add_theme_constant_override("outline_size", 2)
			target_indicator.add_theme_color_override("font_outline_color", Color(0.02, 0.06, 0.1, 0.72))
			target_indicator.visible = false
			add_child(target_indicator)
