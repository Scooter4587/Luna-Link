extends RefCounted
class_name RoomDragService

## Jednoduchý helper na ťahanie obdĺžnika v grid-e.
## - pracuje v "cell" súradniciach (Vector2i)
## - vyráta Rect2i od min(a,b) po max(a,b) vrátane (size + 1)

var is_dragging: bool = false
var start_cell: Vector2i = Vector2i.ZERO
var current_cell: Vector2i = Vector2i.ZERO


func start(cell: Vector2i) -> void:
	is_dragging = true
	start_cell = cell
	current_cell = cell


func update(cell: Vector2i) -> void:
	if not is_dragging:
		return
	current_cell = cell


func end(cell: Vector2i) -> Rect2i:
	if not is_dragging:
		# vrátime prázdny rect, caller si to ošetrí
		return Rect2i(Vector2i.ZERO, Vector2i.ZERO)
	current_cell = cell
	is_dragging = false
	return get_rect()


func get_rect() -> Rect2i:
	var min_x: int = min(start_cell.x, current_cell.x)
	var max_x: int = max(start_cell.x, current_cell.x)
	var min_y: int = min(start_cell.y, current_cell.y)
	var max_y: int = max(start_cell.y, current_cell.y)

	var size: Vector2i = Vector2i(
		max_x - min_x + 1,
		max_y - min_y + 1
	)

	return Rect2i(Vector2i(min_x, min_y), size)


func reset() -> void:
	is_dragging = false
	start_cell = Vector2i.ZERO
	current_cell = Vector2i.ZERO
