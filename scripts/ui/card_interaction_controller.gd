extends Node
class_name CardInteractionController

enum State {
	IDLE,
	CARD_SELECTED,
	CARD_DRAGGING,
	CARD_TARGETING,
	PIECE_SELECTED,
	PIECE_DRAGGING,
}

var state: State = State.IDLE
var card_instance_id: String = ""
var source_square: Variant = null
var cursor_global: Vector2 = Vector2.ZERO
var drag_preview: Control


func select_card(next_card_instance_id: String) -> void:
	reset_drag()
	card_instance_id = next_card_instance_id
	state = State.CARD_SELECTED if not card_instance_id.is_empty() else State.IDLE


func select_piece(next_source_square: Vector2i) -> void:
	reset_drag()
	source_square = next_source_square
	state = State.PIECE_SELECTED


func begin_card_drag(next_card_instance_id: String, next_cursor_global: Vector2, requires_target: bool) -> void:
	clear_preview()
	card_instance_id = next_card_instance_id
	source_square = null
	cursor_global = next_cursor_global
	state = State.CARD_TARGETING if requires_target else State.CARD_DRAGGING


func begin_piece_drag(next_source_square: Vector2i, next_cursor_global: Vector2) -> void:
	clear_preview()
	card_instance_id = ""
	source_square = next_source_square
	cursor_global = next_cursor_global
	state = State.PIECE_DRAGGING


func update_cursor(next_cursor_global: Vector2) -> void:
	cursor_global = next_cursor_global


func is_dragging() -> bool:
	return state == State.CARD_DRAGGING or state == State.CARD_TARGETING or state == State.PIECE_DRAGGING


func drag_kind() -> String:
	match state:
		State.CARD_DRAGGING:
			return "card_play"
		State.CARD_TARGETING:
			return "card_target"
		State.PIECE_DRAGGING:
			return "piece"
		_:
			return ""


func set_preview(preview: Control, parent: Node) -> void:
	clear_preview()
	drag_preview = preview
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(drag_preview)
	update_preview_position()


func update_preview_position() -> void:
	if drag_preview == null or not is_instance_valid(drag_preview):
		return
	var preview_size := drag_preview.size
	if preview_size == Vector2.ZERO:
		preview_size = drag_preview.custom_minimum_size
	if preview_size == Vector2.ZERO:
		preview_size = drag_preview.get_combined_minimum_size()
	drag_preview.position = cursor_global - preview_size * 0.5


func clear_preview() -> void:
	if drag_preview != null and is_instance_valid(drag_preview):
		drag_preview.queue_free()
	drag_preview = null


func reset_drag() -> void:
	clear_preview()
	card_instance_id = ""
	source_square = null
	cursor_global = Vector2.ZERO
	state = State.IDLE
