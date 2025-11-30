extends Node2D
class_name RoomMode

## RoomMode: rieši INTERIOR ROOMS (Quarters / Mess / Airlock).
## - počúva BuildUI.building_selected
## - pre interior rooms robí rect-drag a instancuje RoomArea2D

const ROOM_CELL_PX: int = 16
const ROOM_CELL_SIZE_PX: Vector2 = Vector2(ROOM_CELL_PX, ROOM_CELL_PX)

var _hover_cell: Vector2i = Vector2i.ZERO
var _has_hover: bool = false

var is_active: bool = false
var current_room_building_id: String = ""
var current_room_type_id: StringName = &""

var _is_dragging: bool = false
var _drag_start_cell: Vector2i = Vector2i.ZERO
var _drag_current_cell: Vector2i = Vector2i.ZERO
var _current_room_node: RoomArea2D = null



func _ready() -> void:
	
	# default: vypnuté, zapíname až pri výbere room z UI
	set_process(false)
	set_process_unhandled_input(false)
	z_index = 50  # nech overlayy neprebijú terrain / buildings

	# nájdeme BuildUI vedľa BuildMode: ../UI/BuildUI
	var ui: Node = get_node_or_null("../UI/BuildUI")
	if ui != null and ui.has_signal("building_selected"):
		ui.building_selected.connect(_on_build_ui_building_selected)
		if DebugFlags.MASTER_DEBUG and DebugFlags.DEBUG_ROOMS:
			print("[RoomMode] Connected to BuildUI.building_selected")
	else:
		push_warning("[RoomMode] UI/BuildUI not found or missing signal 'building_selected'")


func _on_build_ui_building_selected(building_id: String) -> void:
	_cancel_current_drag()

	# prázdny string = nič nevybraté (napr. RMB cancel z UI)
	if building_id == "":
		_deactivate()
		return

	var cfg: Dictionary = BuildingsCfg.get_building(building_id)
	if cfg.is_empty():
		if DebugFlags.MASTER_DEBUG and DebugFlags.DEBUG_ROOMS:
			print("[RoomMode] Unknown building_id: %s" % building_id)
		_deactivate()
		return

	var ui_group: String = cfg.get("ui_group", "")
	var domain: String = cfg.get("domain", "")
	var category: String = cfg.get("category", "")

	var is_room_building: bool = (ui_group == "interior_rooms") \
		or (domain == "interior" and category == "interior")

	if not is_room_building:
		if DebugFlags.MASTER_DEBUG and DebugFlags.DEBUG_ROOMS:
			print("[RoomMode] building_id %s nie je interior room → RoomMode OFF" % building_id)
		_deactivate()
		return

	current_room_building_id = building_id
	current_room_type_id = _map_building_to_room_type(building_id)

	is_active = true
	_has_hover = false  # reset
	set_process_unhandled_input(true)
	set_process(true)
	queue_redraw()

	if DebugFlags.MASTER_DEBUG and DebugFlags.DEBUG_ROOMS:
		print("[RoomMode] Selected ROOM building: %s -> room_type_id=%s"
			% [building_id, str(current_room_type_id)])



func _map_building_to_room_type(building_id: String) -> StringName:
	## Krok 1: jednoduché mapovanie build ID -> RoomCfg ID.
	## Neskôr to vieme spraviť dátovo v BuildingsCfg.
	match building_id:
		"room_quarters_basic":
			return RoomCfg.TYPE_QUARTERS_BASIC
		"room_mess_hall_basic":
			return RoomCfg.TYPE_MESS_HALL_BASIC
		"room_airlock_basic":
			return RoomCfg.TYPE_AIRLOCK_BASIC
		_:
			# fallback: skúsime použiť rovnaký názov, ak by sa to zhodovalo
			return StringName(building_id)


func _deactivate() -> void:
	is_active = false
	current_room_building_id = ""
	current_room_type_id = &""
	_has_hover = false
	_cancel_current_drag()
	set_process(false)
	set_process_unhandled_input(false)
	queue_redraw()


func _cancel_current_drag() -> void:
	_is_dragging = false
	_drag_start_cell = Vector2i.ZERO
	_drag_current_cell = Vector2i.ZERO

	if _current_room_node != null and is_instance_valid(_current_room_node):
		_current_room_node.queue_free()
	_current_room_node = null


func _process(_delta: float) -> void:
	# zatiaľ nič extra – overlay rieši RoomArea2D
	pass


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton

		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_start_drag()
			else:
				_finish_drag()

		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			# RMB = cancel room tool
			_deactivate()
			get_viewport().set_input_as_handled()
			return

	elif event is InputEventMouseMotion:
		var cell: Vector2i = _mouse_room_cell()
		if cell != _hover_cell:
			_hover_cell = cell
			_has_hover = true
			queue_redraw()

		if _is_dragging:
			_update_drag()


# --------------------------------------------------------------------
# Drag logika – čisto v RoomMode, bez externého helperu / _drag
# --------------------------------------------------------------------

func _mouse_room_cell() -> Vector2i:
	var pos: Vector2 = get_global_mouse_position()
	return Vector2i(
		int(floor(pos.x / ROOM_CELL_PX)),
		int(floor(pos.y / ROOM_CELL_PX))
	)

func _start_drag() -> void:
	if not is_active:
		return

	var cell: Vector2i = _mouse_room_cell()
	_drag_start_cell = cell
	_drag_current_cell = cell
	_is_dragging = true

	# vytvoríme novú RoomArea2D inštanciu – ghost počas ťahania
	_current_room_node = RoomArea2D.new()
	add_child(_current_room_node)

	_current_room_node.room_type_id = current_room_type_id
	_current_room_node.cell_size_px = ROOM_CELL_SIZE_PX
	_current_room_node.draw_overlay = true
	_current_room_node.is_ghost = true
	_current_room_node.debug_use_initial_rect = false
	_current_room_node.z_index = 100

	var rect := Rect2i(cell, Vector2i.ONE)
	_current_room_node.set_bounds_rect_cells(rect)

	if DebugFlags.MASTER_DEBUG and DebugFlags.DEBUG_ROOMS:
		print("[RoomMode] Drag start cell=", cell, " type=", str(current_room_type_id))


func _update_drag() -> void:
	if _current_room_node == null:
		return

	var cell: Vector2i = _mouse_room_cell()
	if cell == _drag_current_cell:
		return

	_drag_current_cell = cell
	var rect: Rect2i = _make_rect(_drag_start_cell, _drag_current_cell)
	_current_room_node.set_bounds_rect_cells(rect)


func _make_rect(a: Vector2i, b: Vector2i) -> Rect2i:
	var min_x: int = min(a.x, b.x)
	var min_y: int = min(a.y, b.y)
	var max_x: int = max(a.x, b.x)
	var max_y: int = max(a.y, b.y)

	var size_x: int = max_x - min_x + 1
	var size_y: int = max_y - min_y + 1

	return Rect2i(Vector2i(min_x, min_y), Vector2i(size_x, size_y))


func _finish_drag() -> void:
	if not _is_dragging:
		return

	_is_dragging = false

	if _current_room_node == null:
		return

	var rect: Rect2i = _make_rect(_drag_start_cell, _drag_current_cell)

	# 1) Min. veľkosť podľa RoomCfg
	var min_size: Vector2i = RoomCfg.get_min_size(current_room_type_id)
	if rect.size.x < min_size.x or rect.size.y < min_size.y:
		if DebugFlags.MASTER_DEBUG and DebugFlags.DEBUG_ROOMS:
			print("[RoomMode] rect too small (%s), required min=(%s) → cancel room"
				% [str(rect.size), str(min_size)])
		_current_room_node.queue_free()
		_current_room_node = null
		return

	# 2) Overlap check – ak máme Room_Registry funkciu
	if Room_Registry.has_method("find_overlapping_room"):
		var overlapping: RoomArea2D = Room_Registry.find_overlapping_room(rect) as RoomArea2D
		if overlapping != null:
			if DebugFlags.MASTER_DEBUG and DebugFlags.DEBUG_ROOMS:
				print("[RoomMode] rect %s overlaps existing room → cancel" % str(rect))
			_current_room_node.queue_free()
			_current_room_node = null
			return

	# 3) requires_floor / hub FOUNDATION INTERIOR clip
	var requires_floor: bool = RoomCfg.requires_floor(current_room_type_id)
	if requires_floor:
		# a) vôbec existuje nejaký hub?
		if not State.hub_foundation_ready:
			if DebugFlags.MASTER_DEBUG and DebugFlags.DEBUG_ROOMS:
				print("[RoomMode] hub foundation not ready → cancel room")
			_current_room_node.queue_free()
			_current_room_node = null
			return

		# b) musí ležať komplet vnútri „interior rectu“ nejakej foundation (hub.grow(-1))
		if not State.any_hub_interior_encloses(rect):
			if DebugFlags.MASTER_DEBUG and DebugFlags.DEBUG_ROOMS:
				var hubs_str := ""
				for h in State.get_hub_foundation_rects():
					hubs_str += str(h) + " "
				print("[RoomMode] rect %s is outside hub interior(s) → cancel  hubs=[%s]"
					% [str(rect), hubs_str])
			_current_room_node.queue_free()
			_current_room_node = null
			return

	# 4) finálne potvrdenie roomky – už nie ghost
	_current_room_node.is_ghost = false
	_current_room_node.set_bounds_rect_cells(rect)

	if DebugFlags.MASTER_DEBUG and DebugFlags.DEBUG_ROOMS:
		print("[RoomMode] Drag end rect=", rect, " type=", str(current_room_type_id))

	_current_room_node = null



func _draw() -> void:
	if not is_active:
		return
	if _is_dragging:
		# počas ťahania sa kreslí len RoomArea2D, ghost tu neriešime
		return
	if not _has_hover:
		return
	if current_room_type_id == StringName():
		return

	# 👇 Ghost = presne 1 room tile
	var rect_cells := Rect2i(_hover_cell, Vector2i.ONE)

	var origin_px := Vector2(
		rect_cells.position.x * ROOM_CELL_SIZE_PX.x,
		rect_cells.position.y * ROOM_CELL_SIZE_PX.y
	)
	var size_px := Vector2(
		rect_cells.size.x * ROOM_CELL_SIZE_PX.x,
		rect_cells.size.y * ROOM_CELL_SIZE_PX.y
	)
	var rect_px := Rect2(origin_px, size_px)

	var color: Color = RoomCfg.get_debug_color(current_room_type_id)
	color.a = 0.25
	var border := Color(color.r, color.g, color.b, min(color.a + 0.2, 1.0))

	draw_rect(rect_px, color, true)
	draw_rect(rect_px, border, false)
