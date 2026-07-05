extends Control
class_name HandFanView

@export var is_opponent_hand: bool = false
@export var local_card_size: Vector2 = Vector2(124, 177)
@export var opponent_card_size: Vector2 = Vector2(86, 122)
@export var local_curve_height_per_card: float = 2.0
@export var opponent_curve_height_per_card: float = 0.55
@export var local_rotation_scale: float = 3.0
@export var opponent_rotation_scale: float = 2.2
@export var local_overlap_ratio: float = 0.62
@export var opponent_overlap_ratio: float = 0.48
@export var local_bottom_margin: float = 8.0
@export var opponent_top_margin: float = -28.0
@export var opponent_arc_drop_scale: float = 0.24
@export var targeted_preview_y: float = -54.0

var targeted_card_instance_id: String = ""


func _ready() -> void:
	resized.connect(_queue_layout)
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)
	for child in get_children():
		_on_child_entered_tree(child)
	_queue_layout()


func set_targeted_card_instance_id(card_instance_id: String) -> void:
	if targeted_card_instance_id == card_instance_id:
		return
	targeted_card_instance_id = card_instance_id
	_queue_layout()


func refresh_layout() -> void:
	if not is_node_ready():
		return
	var widgets := _card_widgets()
	if widgets.is_empty():
		return

	if not is_opponent_hand and not targeted_card_instance_id.is_empty():
		_layout_local_targeting_fan(widgets)
		return
	_layout_standard_fan(widgets, is_opponent_hand)


func _layout_local_targeting_fan(widgets: Array[Control]) -> void:
	var card_size := _resolved_card_size(widgets, local_card_size)
	var base_y: float = _base_y(card_size)
	var target_x := (size.x - card_size.x) * 0.5
	var target_widget: Control = null
	var side_widgets: Array[Control] = []

	for widget in widgets:
		if _card_instance_id(widget) == targeted_card_instance_id:
			target_widget = widget
		else:
			side_widgets.append(widget)

	if target_widget == null:
		_layout_standard_fan(widgets, false)
		return

	var natural_step: float = card_size.x * local_overlap_ratio
	var side_count := side_widgets.size()
	var left_count := int(ceil(float(side_count) * 0.5))
	var right_count := side_count - left_count
	var gap_width := card_size.x * 0.9

	for index in range(side_count):
		var card := side_widgets[index]
		_apply_card_dimensions(card, card_size, false)

		var side_index := index if index < left_count else index - left_count
		var direction := -1.0 if index < left_count else 1.0
		var fan_rank := float(left_count - side_index) if direction < 0.0 else float(side_index + 1)
		var distance_from_center := gap_width * 0.5 + natural_step * fan_rank
		var normalized_rank: float = 0.0 if side_count <= 1 else fan_rank / float(maxi(left_count, right_count))
		var arc_offset: float = minf(26.0, 8.0 + float(side_count) * 1.8) * (1.0 - 0.35 * normalized_rank)
		var position_x := target_x + direction * distance_from_center - card_size.x * 0.5
		var position_y: float = base_y - arc_offset
		card.position = Vector2(position_x, position_y)
		card.rotation_degrees = direction * min(12.0, 3.5 + fan_rank * 1.65)
		card.z_index = 120 - int(fan_rank * 10.0) + index
		card.set_meta("fan_z_index", card.z_index)
		card.set_meta("fan_position", card.position)

	_apply_card_dimensions(target_widget, card_size, false)
	target_widget.position = Vector2(target_x, targeted_preview_y)
	target_widget.rotation_degrees = 0.0
	target_widget.z_index = 200
	target_widget.set_meta("fan_z_index", target_widget.z_index)
	target_widget.set_meta("fan_position", target_widget.position)
	_center_visible_fan(widgets)


func _layout_standard_fan(widgets: Array[Control], next_is_opponent_hand: bool) -> void:
	var count := widgets.size()
	var requested_size := opponent_card_size if next_is_opponent_hand else local_card_size
	var card_size := _resolved_card_size(widgets, requested_size)
	var natural_step: float = card_size.x * (opponent_overlap_ratio if next_is_opponent_hand else local_overlap_ratio)
	var available_span: float = max(0.0, size.x - card_size.x)
	var step: float = 0.0 if count <= 1 else min(natural_step, available_span / float(count - 1))
	var total_width: float = card_size.x if count <= 1 else card_size.x + step * float(count - 1)
	var start_x: float = max(0.0, (size.x - total_width) * 0.5)
	var curve_height: float = min(30.0, 10.0 + float(count) * (opponent_curve_height_per_card if next_is_opponent_hand else local_curve_height_per_card))
	var rotation_scale: float = opponent_rotation_scale if next_is_opponent_hand else local_rotation_scale
	var base_y: float = _base_y(card_size)
	var center_index: float = float(count - 1) * 0.5

	for index in range(count):
		var card: Control = widgets[index]
		_apply_card_dimensions(card, card_size, next_is_opponent_hand)

		var centered_index: float = float(index) - center_index
		var normalized_distance: float = 0.0 if center_index <= 0.0 else abs(centered_index) / center_index
		var arc_offset: float = curve_height * (1.0 - normalized_distance * normalized_distance)
		var position_x: float = start_x + step * float(index)
		var position_y: float = base_y + arc_offset * opponent_arc_drop_scale if next_is_opponent_hand else base_y - arc_offset
		card.rotation_degrees = -centered_index * rotation_scale if next_is_opponent_hand else centered_index * rotation_scale
		card.z_index = 100 - int(abs(centered_index) * 20.0) + index
		card.set_meta("fan_z_index", card.z_index)
		card.position = Vector2(position_x, position_y)
		card.set_meta("fan_position", card.position)

	_center_visible_fan(widgets)


func _center_visible_fan(widgets: Array[Control]) -> void:
	if widgets.is_empty():
		return
	var min_x := INF
	var max_x := -INF
	for widget in widgets:
		var rect := _rotated_card_bounds(widget)
		min_x = minf(min_x, rect.position.x)
		max_x = maxf(max_x, rect.end.x)
	if min_x == INF or max_x == -INF:
		return
	var visible_center_x := (min_x + max_x) * 0.5
	var desired_center_x := size.x * 0.5
	var offset_x := desired_center_x - visible_center_x
	if absf(offset_x) < 0.25:
		return
	for widget in widgets:
		widget.position.x += offset_x
		widget.set_meta("fan_position", widget.position)


func _rotated_card_bounds(card: Control) -> Rect2:
	var card_rotation := deg_to_rad(card.rotation_degrees)
	var transform := Transform2D(card_rotation, card.scale, 0.0, card.position)
	transform.origin += card.pivot_offset - transform.basis_xform(card.pivot_offset)
	return _card_bounds_for_transform(card, transform)


func _card_bounds_for_transform(card: Control, transform: Transform2D) -> Rect2:
	var corners := [
		Vector2.ZERO,
		Vector2(card.size.x, 0.0),
		card.size,
		Vector2(0.0, card.size.y),
	]
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF
	for corner in corners:
		var transformed: Vector2 = transform * corner
		min_x = minf(min_x, transformed.x)
		min_y = minf(min_y, transformed.y)
		max_x = maxf(max_x, transformed.x)
		max_y = maxf(max_y, transformed.y)
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))


func get_card_center_global(card_instance_id: String) -> Vector2:
	for widget in _card_widgets():
		if _card_instance_id(widget) == card_instance_id:
			return widget.get_card_center_global()
	return Vector2.ZERO


func get_card_widgets() -> Array[Control]:
	return _card_widgets()


func get_card_visual_bounds_global(card: Control) -> Rect2:
	return _card_visual_bounds_with_canvas(card)


func get_all_card_visual_bounds_global() -> Array[Rect2]:
	var bounds: Array[Rect2] = []
	for widget in _card_widgets():
		bounds.append(get_card_visual_bounds_global(widget))
	return bounds


func _queue_layout() -> void:
	if not is_node_ready():
		return
	call_deferred("refresh_layout")


func _on_child_entered_tree(child: Node) -> void:
	var control := child as Control
	if control == null:
		return
	if not control.minimum_size_changed.is_connected(_queue_layout):
		control.minimum_size_changed.connect(_queue_layout)
	_queue_layout()


func _on_child_exiting_tree(_child: Node) -> void:
	_queue_layout()


func _card_widgets() -> Array[Control]:
	var widgets: Array[Control] = []
	for child in get_children():
		var widget := child as Control
		if widget != null and widget.has_method("get_card_instance_id"):
			widgets.append(widget)
	return widgets


func _card_instance_id(card: Control) -> String:
	if not card.has_method("get_card_instance_id"):
		return ""
	return str(card.get_card_instance_id())


func _resolved_card_size(widgets: Array[Control], requested_size: Vector2) -> Vector2:
	if is_opponent_hand:
		return requested_size
	var resolved_size := requested_size
	for widget in widgets:
		var minimum_size := widget.get_combined_minimum_size()
		resolved_size.x = maxf(resolved_size.x, minimum_size.x)
		resolved_size.y = maxf(resolved_size.y, minimum_size.y)
	return resolved_size


func _apply_card_dimensions(card: Control, visual_size: Vector2, next_is_opponent_hand: bool) -> void:
	var nominal_size := card.get_combined_minimum_size()
	card.size = nominal_size
	card.scale = Vector2(visual_size.x / nominal_size.x, visual_size.y / nominal_size.y)
	card.pivot_offset = _card_pivot_offset(nominal_size, next_is_opponent_hand)


func _card_visual_bounds_with_canvas(card: Control) -> Rect2:
	var transform := card.get_global_transform_with_canvas()
	if not card.offset_transform_enabled:
		return _card_bounds_for_transform(card, transform)
	var pivot := card.offset_transform_pivot + card.size * card.offset_transform_pivot_ratio
	var visual_position := card.offset_transform_position + card.size * card.offset_transform_position_ratio
	var corners := [
		Vector2.ZERO,
		Vector2(card.size.x, 0.0),
		card.size,
		Vector2(0.0, card.size.y),
	]
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF
	for corner in corners:
		var local_offset: Vector2 = corner - pivot
		local_offset = Vector2(
			local_offset.x * card.offset_transform_scale.x,
			local_offset.y * card.offset_transform_scale.y
		).rotated(card.offset_transform_rotation)
		var transformed: Vector2 = transform * (visual_position + pivot + local_offset)
		min_x = minf(min_x, transformed.x)
		min_y = minf(min_y, transformed.y)
		max_x = maxf(max_x, transformed.x)
		max_y = maxf(max_y, transformed.y)
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))


func _base_y(card_size: Vector2) -> float:
	if is_opponent_hand:
		return opponent_top_margin
	return max(0.0, size.y - card_size.y - local_bottom_margin)


func _card_pivot_offset(card_size: Vector2, next_is_opponent_hand: bool) -> Vector2:
	if next_is_opponent_hand:
		return Vector2(card_size.x * 0.5, 0.0)
	return Vector2(card_size.x * 0.5, card_size.y)
