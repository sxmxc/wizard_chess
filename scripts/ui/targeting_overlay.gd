extends Control
class_name TargetingOverlay

@export var valid_color := Color("60d6ff")
@export var invalid_color := Color("8493a3")
@export var line_width: float = 4.0

var source_global := Vector2.ZERO
var destination_global := Vector2.ZERO
var target_is_valid: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func present(next_source_global: Vector2, next_destination_global: Vector2, is_valid: bool) -> void:
	source_global = next_source_global
	destination_global = next_destination_global
	target_is_valid = is_valid
	visible = source_global != Vector2.ZERO and destination_global != Vector2.ZERO
	queue_redraw()


func clear() -> void:
	visible = false
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	var inverse_transform := get_global_transform_with_canvas().affine_inverse()
	var source: Vector2 = inverse_transform * source_global
	var destination: Vector2 = inverse_transform * destination_global
	var distance: float = source.distance_to(destination)
	var lift := clampf(distance * 0.22, 54.0, 132.0)
	var control: Vector2 = source.lerp(destination, 0.5) + Vector2(0.0, -lift)
	var points := PackedVector2Array()
	for index in range(25):
		var t := float(index) / 24.0
		points.append(source * (1.0 - t) * (1.0 - t) + control * 2.0 * (1.0 - t) * t + destination * t * t)
	var color := valid_color if target_is_valid else invalid_color
	draw_polyline(points, Color(0.02, 0.05, 0.08, 0.58), line_width + 3.0, true)
	draw_polyline(points, color, line_width, true)
	var direction: Vector2 = (destination - points[points.size() - 2]).normalized()
	var normal := Vector2(-direction.y, direction.x)
	var arrow_tip := destination
	var arrow_base := destination - direction * 15.0
	draw_colored_polygon(PackedVector2Array([arrow_tip, arrow_base + normal * 6.0, arrow_base - normal * 6.0]), color)
	draw_circle(destination, 8.0, Color(color, 0.16))
	draw_arc(destination, 8.0, 0.0, TAU, 24, color, 2.0, true)
