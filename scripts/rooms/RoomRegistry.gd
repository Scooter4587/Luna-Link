extends Node
class_name RoomRegistry

## Jediný zdroj pravdy o všetkých RoomArea2D inštanciách v hre.

# ---------------------------------------------------------
# Debug flagy
# ---------------------------------------------------------

@export_group("Debug")
@export var DEBUG_ROOMS: bool = false
@export var DEBUG_NAV: bool = false
@export var DEBUG_AIRLOCK: bool = false


# ---------------------------------------------------------
# Údaje o miestnostiach
# ---------------------------------------------------------

var _next_room_id: int = 1

## Hlavná mapa: room_id -> RoomArea2D (uložené dynamicky)
var _rooms: Dictionary = {}

## Index podľa typu: room_type_id (StringName) -> Array[int]
var _rooms_by_type: Dictionary = {}

## Index podľa foundation_id: foundation_id (int) -> Array[int]
var _rooms_by_foundation: Dictionary = {}


func _ready() -> void:
	if DEBUG_ROOMS:
		print("[RoomRegistry] Ready – empty registry.")


# ---------------------------------------------------------
# Registrácia / odregistrácia miestností
# ---------------------------------------------------------

func register_room(room) -> int:
	## Pridelí miestnosti nové ID, uloží ju do máp a vráti id.
	## room očakávame typu RoomArea2D, ale netypujeme ho tvrdo kvôli VSCode warningom.
	if room == null:
		push_warning("[RoomRegistry] Tried to register null room.")
		return -1

	var id: int = _next_room_id
	_next_room_id += 1

	_rooms[id] = room
	room.room_instance_id = id

	# index podľa typu
	var t: StringName = room.room_type_id
	if not _rooms_by_type.has(t):
		_rooms_by_type[t] = []
	_rooms_by_type[t].append(id)

	# index podľa foundation (ak už má priradené foundation_id)
	if room.foundation_id != -1:
		_add_room_to_foundation(room.foundation_id, id)

	if DEBUG_ROOMS:
		print("[RoomRegistry] Registered room id=%d type=%s" % [id, str(t)])

	return id


func unregister_room(room) -> void:
	if room == null:
		return

	var id: int = room.room_instance_id
	if id <= 0:
		return
	if not _rooms.has(id):
		return

	var t: StringName = room.room_type_id
	var foundation_id: int = room.foundation_id

	_rooms.erase(id)

	if _rooms_by_type.has(t):
		var ids: Array = _rooms_by_type[t]
		ids.erase(id)
		if ids.is_empty():
			_rooms_by_type.erase(t)

	if foundation_id != -1 and _rooms_by_foundation.has(foundation_id):
		var f_ids: Array = _rooms_by_foundation[foundation_id]
		f_ids.erase(id)
		if f_ids.is_empty():
			_rooms_by_foundation.erase(foundation_id)

	if DEBUG_ROOMS:
		print("[RoomRegistry] Unregistered room id=%d type=%s" % [id, str(t)])


func _add_room_to_foundation(foundation_id: int, room_id: int) -> void:
	if not _rooms_by_foundation.has(foundation_id):
		_rooms_by_foundation[foundation_id] = []
	_rooms_by_foundation[foundation_id].append(room_id)
	if DEBUG_ROOMS:
		print("[RoomRegistry] Room id=%d assigned to foundation_id=%d" % [room_id, foundation_id])


func notify_foundation_changed(room, old_foundation_id: int, new_foundation_id: int) -> void:
	## Ak v budúcnosti zmeníš foundation, v ktorom miestnosť leží.
	if room == null:
		return
	var id: int = room.room_instance_id
	if id <= 0:
		return

	if old_foundation_id != -1 and _rooms_by_foundation.has(old_foundation_id):
		var f_ids: Array = _rooms_by_foundation[old_foundation_id]
		f_ids.erase(id)
		if f_ids.is_empty():
			_rooms_by_foundation.erase(old_foundation_id)

	if new_foundation_id != -1:
		_add_room_to_foundation(new_foundation_id, id)


# ---------------------------------------------------------
# Query API
# ---------------------------------------------------------

func get_room(room_id: int):
	return _rooms.get(room_id, null)


func get_all_rooms() -> Array:
	var result: Array = []
	for id in _rooms.keys():
		var room = _rooms[id]
		if room != null:
			result.append(room)
	return result


func get_rooms_of_type(room_type_id: StringName) -> Array:
	var result: Array = []
	var ids: Array = _rooms_by_type.get(room_type_id, [])
	for id in ids:
		var room = _rooms.get(id, null)
		if room != null:
			result.append(room)
	return result


func get_rooms_in_foundation(foundation_id: int) -> Array:
	var result: Array = []
	var ids: Array = _rooms_by_foundation.get(foundation_id, [])
	for id in ids:
		var room = _rooms.get(id, null)
		if room != null:
			result.append(room)
	return result


func get_airlocks() -> Array:
	var result: Array = []
	for id in _rooms.keys():
		var room = _rooms[id]
		if room == null:
			continue
		if RoomCfg.is_airlock(room.room_type_id):
			result.append(room)
	if DEBUG_AIRLOCK:
		print("[RoomRegistry] get_airlocks() -> %d items" % result.size())
	return result


func debug_print_summary() -> void:
	if not DEBUG_ROOMS:
		return

	print("[RoomRegistry] ---- SUMMARY ----")
	print("Total rooms: %d" % _rooms.size())
	for room_type_id in _rooms_by_type.keys():
		var ids: Array = _rooms_by_type[room_type_id]
		print("- %s: %d" % [str(room_type_id), ids.size()])
	print("------------------------")

func _process(_delta: float) -> void:
	_sync_debug_flags()

func _sync_debug_flags() -> void:
	if Engine.is_editor_hint():
		return

	var master := DebugFlags.MASTER_DEBUG

	DEBUG_ROOMS = master and DebugFlags.DEBUG_ROOMS
	DEBUG_NAV = master and DebugFlags.DEBUG_NAV
	DEBUG_AIRLOCK = master and DebugFlags.DEBUG_AIRLOCK