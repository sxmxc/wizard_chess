extends RefCounted
class_name GameEventQueue

var _pending_events: Array[Dictionary] = []
var _resolved_events: Array[Dictionary] = []
var _next_sequence: int = 1


func enqueue(event: Dictionary) -> Dictionary:
	var normalized: Dictionary = {
		"sequence": _next_sequence,
		"type": str(event.get("type", "")),
		"payload": event.get("payload", {}).duplicate(true),
	}
	_next_sequence += 1
	_pending_events.append(normalized)
	return normalized


func enqueue_many(events: Array) -> void:
	for event_value in events:
		enqueue(event_value)


func resolve_all(resolver: Callable = Callable()) -> Array:
	while not _pending_events.is_empty():
		var event: Dictionary = _pending_events.pop_front()
		_resolved_events.append(event)
		if resolver.is_null():
			continue
		var generated: Variant = resolver.call(event)
		if generated is Array:
			enqueue_many(generated)
	return _resolved_events.duplicate(true)


func clear() -> void:
	_pending_events.clear()
	_resolved_events.clear()
	_next_sequence = 1


func load_history(history: Array) -> void:
	_pending_events.clear()
	_resolved_events = history.duplicate(true)
	_next_sequence = 1
	for event_value in _resolved_events:
		_next_sequence = max(_next_sequence, int(event_value.get("sequence", 0)) + 1)


func get_pending_events() -> Array:
	return _pending_events.duplicate(true)


func get_resolved_events() -> Array:
	return _resolved_events.duplicate(true)
