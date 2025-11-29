extends Area2D
class_name RoomArea2D

## Jedna konkrétna miestnosť v hre (napr. Quarters #3).

# ---------------------------------------------------------
# Exportované parametre
# ---------------------------------------------------------

@export var room_type_id: StringName = RoomCfg.TYPE_QUARTERS_BASIC:
	set(value):
		room_type_id = value
		_refresh_from_cfg()

## Veľkosť jednej interiérovej bunky v pixeloch
@export var cell_size_px: Vector2 = Vector2(32, 32)

## Či sa má kresliť overlay (ghost / debug)
@export var draw_overlay: bool = true:
	set(value):
		draw_overlay = value
		queue_redraw()

## Ghost režim (napr. pri build preview)
@export var is_ghost: bool = false:
	set(value):
		is_ghost = value
		queue_redraw()

@export_group("Debug")
@export var debug_use_initial_rect: bool = true
@export var debug_initial_size_cells: Vector2i = Vector2i(3, 2)

# ---------------------------------------------------------
# Runtime údaje
# ---------------------------------------------------------

var room_instance_id: int = -1

## Obdĺžnik v "room grid" súradniciach
var bounds_rect_cells: Rect2i = Rect2i(Vector2i.ZERO, Vector2i(1, 1))

## Všetky bunky miestnosti
var bounds_cells: Array[Vector2i] = []

## Kapacita miestnosti
var max_capacity: int = 0

## Aktuálny počet occupantov
var current_occupants: int = 0

## Foundation, v ktorom táto miestnosť existuje (-1 = zatiaľ nepriradené)
var foundation_id: int = -1

## Interný flag, či je zaregistrovaná v Room_Registry
var _is_registered: bool = false

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _label: Label = $Label


func _ready() -> void:
	# 1) Ak je default 1x1, nastavíme debug rect
	if debug_use_initial_rect and bounds_rect_cells.size == Vector2i(1, 1):
		var rect := Rect2i(Vector2i.ZERO, debug_initial_size_cells)
		set_bounds_rect_cells(rect)

	# 2) načítame definíciu z RoomCfg
	_refresh_from_cfg()
	_update_collision_shape()
	_update_label()
	queue_redraw()

	# 3) registrácia do Room_Registry (len v hre, nie v editore)
	if not Engine.is_editor_hint():
		if not _is_registered:
			Room_Registry.register_room(self)
			_is_registered = true


func _exit_tree() -> void:
	if not Engine.is_editor_hint() and _is_registered:
		Room_Registry.unregister_room(self)
		_is_registered = false


# ---------------------------------------------------------
# Refresh z RoomCfg
# ---------------------------------------------------------

func _refresh_from_cfg() -> void:
	if not RoomCfg.has_room(room_type_id):
		push_warning("RoomArea2D: unknown room_type_id: %s" % room_type_id)
		max_capacity = 0
		return

	max_capacity = RoomCfg.get_base_capacity(room_type_id)
	_update_label()
	queue_redraw()


# ---------------------------------------------------------
# Bounds / bunky
# ---------------------------------------------------------

func set_bounds_rect_cells(rect: Rect2i) -> void:
	bounds_rect_cells = rect
	_rebuild_cells_from_rect()
	_update_collision_shape()
	queue_redraw()


func _rebuild_cells_from_rect() -> void:
	bounds_cells.clear()

	var start_x := bounds_rect_cells.position.x
	var end_x := bounds_rect_cells.position.x + bounds_rect_cells.size.x
	var start_y := bounds_rect_cells.position.y
	var end_y := bounds_rect_cells.position.y + bounds_rect_cells.size.y

	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			bounds_cells.append(Vector2i(x, y))


# ---------------------------------------------------------
# Kapacita / occupancy
# ---------------------------------------------------------

func get_capacity() -> int:
	return max_capacity


func has_free_slot() -> bool:
	return current_occupants < max_capacity


func try_register_occupant(_crew_id: int) -> bool:
	# slot systém doplníme neskôr, zatiaľ len počítame
	if not has_free_slot():
		return false
	current_occupants += 1
	_update_label()
	return true


func unregister_occupant(_crew_id: int) -> void:
	if current_occupants > 0:
		current_occupants -= 1
	_update_label()

## Rezidenti (crew_id), ktorí tu bývajú – naplníme v 0.0.65.
var assigned_residents: Array[int] = []

## Worker crew_id, ktorí tu pracujú – naplníme v 0.0.65.
var assigned_workers: Array[int] = []

func set_foundation_id(new_foundation_id: int) -> void:
	if new_foundation_id == foundation_id:
		return

	var old_foundation_id := foundation_id
	foundation_id = new_foundation_id

	if not Engine.is_editor_hint() and _is_registered:
		Room_Registry.notify_foundation_changed(self, old_foundation_id, foundation_id)

# ---------------------------------------------------------
# Vizuál – overlay a label
# ---------------------------------------------------------

func _process(_delta: float) -> void:
	# Rezervované na neskoršie debug/preblikávanie
	pass


func _draw() -> void:
	if not draw_overlay:
		return

	if bounds_cells.is_empty():
		_rebuild_cells_from_rect()

	var color := _get_overlay_color()

	for cell in bounds_cells:
		var origin_px := Vector2(cell.x * cell_size_px.x, cell.y * cell_size_px.y)
		var rect_px := Rect2(origin_px, cell_size_px)

		# výplň
		draw_rect(rect_px, color, true)

		# jemný okraj
		var border_color := Color(color.r, color.g, color.b, min(color.a + 0.2, 1.0))
		draw_rect(rect_px, border_color, false)


func _get_overlay_color() -> Color:
	var c := RoomCfg.get_debug_color(room_type_id)
	if is_ghost:
		c.a *= 0.6
	return c


func _update_label() -> void:
	if _label == null:
		return

	var def := RoomCfg.get_room_def(room_type_id)
	var display_name: String = def.get("display_name", str(room_type_id))

	var id_part := "#%d" % room_instance_id if room_instance_id >= 0 else "(unassigned)"
	var occ_part := "%d/%d" % [current_occupants, max_capacity]

	_label.text = "%s %s\n%s" % [display_name, id_part, occ_part]

	var center_px := _get_bounds_center_px()
	_label.position = center_px


func _get_bounds_center_px() -> Vector2:
	var rect := bounds_rect_cells
	var center_cell_x := rect.position.x + rect.size.x * 0.5
	var center_cell_y := rect.position.y + rect.size.y * 0.5
	return Vector2(center_cell_x * cell_size_px.x, center_cell_y * cell_size_px.y)


func _update_collision_shape() -> void:
	if _collision_shape == null:
		return

	var rect_shape := _collision_shape.shape
	if rect_shape == null or not (rect_shape is RectangleShape2D):
		rect_shape = RectangleShape2D.new()
		_collision_shape.shape = rect_shape

	var size_px := Vector2(
		bounds_rect_cells.size.x * cell_size_px.x,
		bounds_rect_cells.size.y * cell_size_px.y
	)
	rect_shape.size = size_px

	var center_px := _get_bounds_center_px()
	_collision_shape.position = center_px
