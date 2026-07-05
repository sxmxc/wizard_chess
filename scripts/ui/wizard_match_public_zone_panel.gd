extends PanelContainer
class_name WizardMatchPublicZonePanel

var title_label: Label
var body_label: Label
var visual_slots: Array[TextureRect] = []


func _ready() -> void:
	var labels := _find_labels(self)
	if labels.size() > 0:
		title_label = labels[0]
	if labels.size() > 1:
		body_label = labels[1]
	visual_slots = _find_texture_rects(self)


func set_zone(title: String, lines: Array[String]) -> void:
	if not is_node_ready():
		call_deferred("set_zone", title, lines)
		return
	if title_label != null:
		title_label.text = title
	if body_label != null:
		body_label.text = "(none)" if lines.is_empty() else "\n".join(lines)


func set_visual_entries(title: String, entries: Array[Dictionary]) -> void:
	if not is_node_ready():
		call_deferred("set_visual_entries", title, entries)
		return
	if title_label != null:
		title_label.text = title
	if body_label != null:
		body_label.text = str(entries.size())
	for index in range(visual_slots.size()):
		var slot := visual_slots[index]
		var has_entry := index < entries.size()
		slot.visible = has_entry
		if not has_entry:
			slot.texture = null
			slot.tooltip_text = ""
			continue
		var entry: Dictionary = entries[index]
		slot.texture = entry.get("texture", null)
		slot.modulate = entry.get("modulate", Color.WHITE)
		slot.tooltip_text = str(entry.get("tooltip", ""))


func _find_labels(root: Node) -> Array[Label]:
	var labels: Array[Label] = []
	for child in root.get_children():
		var label := child as Label
		if label != null:
			labels.append(label)
		labels.append_array(_find_labels(child))
	return labels


func _find_texture_rects(root: Node) -> Array[TextureRect]:
	var slots: Array[TextureRect] = []
	for child in root.get_children():
		var texture_rect := child as TextureRect
		if texture_rect != null and texture_rect.name == "SlotVisual":
			slots.append(texture_rect)
		slots.append_array(_find_texture_rects(child))
	return slots
