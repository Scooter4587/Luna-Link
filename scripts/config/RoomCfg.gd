extends Node
class_name RoomCfg

# ---------------------------------------------------------
# Room type IDs – používaj ich všade v kóde, nie raw stringy
# ---------------------------------------------------------

const TYPE_QUARTERS_BASIC: StringName = &"quarters_basic"
const TYPE_MESS_HALL_BASIC: StringName = &"mess_hall_basic"
const TYPE_AIRLOCK_BASIC: StringName = &"airlock_basic"

# ---------------------------------------------------------
# Hlavný dictionary so všetkými definíciami miestností
# Source-of-truth pre rooms
# ---------------------------------------------------------
# Poznámka:
# - *_size_cells sú v "room grid" – t.j. vnútorné bunky, nie world tiles
# - capacity je "koľko ľudí tento typ miestnosti zvládne pohodlne"
# ---------------------------------------------------------

static var ROOMS: Dictionary = {
	TYPE_QUARTERS_BASIC: {
		"id": TYPE_QUARTERS_BASIC,
        "requires_foundation": true,
		"display_name": "Crew Quarters (Basic)",
		"category": "quarters",               # na filtrovanie v UI
		"min_size_cells": Vector2i(3, 2),     # minimálny obrys
		"default_size_cells": Vector2i(3, 2), # čo ponúkneme pri drag-build
		"base_capacity": 4,                   # koľko crew pohodlne spí
		"max_capacity": 4,                    # hard cap (do budúcna)
		"debug_color": Color(0.3, 0.6, 1.0, 0.3),
		"icon_name": "room_quarters_basic",   # pre budúci UI atlas
		"tags": ["sleep", "room", "interior"],
		"need_effects": {                     # hook pre 0.0.66
			"sleep": {
				"rest_per_hour": 25.0,       # +sleep need / hod
				"oxygen_safe": true
			}
		}
	},

	TYPE_MESS_HALL_BASIC: {
		"id": TYPE_MESS_HALL_BASIC,
        "requires_foundation": true,
		"display_name": "Mess Hall (Basic)",
		"category": "mess_hall",
		"min_size_cells": Vector2i(3, 2),
		"default_size_cells": Vector2i(3, 2),
		"base_capacity": 6,                   # koľko ľudí vie reálne obslúžiť
		"max_capacity": 8,
		"debug_color": Color(0.3, 1.0, 0.3, 0.3),
		"icon_name": "room_mess_hall_basic",
		"tags": ["eat", "room", "interior"],
		"need_effects": {
			"hunger": {
				"food_per_meal": 1.0,        # neskôr hook na sklad jedla
				"satiety_per_meal": 40.0
			}
		}
	},

	TYPE_AIRLOCK_BASIC: {
		"id": TYPE_AIRLOCK_BASIC,
        "requires_foundation": true,
		"display_name": "Airlock (Basic)",
		"category": "airlock",
		"min_size_cells": Vector2i(2, 2),
		"default_size_cells": Vector2i(2, 2),
		"base_capacity": 2,                   # koľko ľudí môže naraz riešiť prechod
		"max_capacity": 2,
		"debug_color": Color(1.0, 0.8, 0.2, 0.35),
		"icon_name": "room_airlock_basic",
		"tags": ["airlock", "oxygen_boundary"],
		"is_airlock": true,                   # pre AirlockController / nav
		"need_effects": {
			"oxygen": {
				"pressure_safe_inside": true,
				"exposed_outside": true     # mimo airlocku = vacuum
			}
		}
	}
}

# ---------------------------------------------------------
# Helper funkcie – budú používané RoomArea2D, RoomRegistry,
# Crew AI, UI apod.
# ---------------------------------------------------------

static func get_room_ids() -> Array[StringName]:
	return ROOMS.keys()

static func has_room(room_type_id: StringName) -> bool:
	return ROOMS.has(room_type_id)

static func get_room_def(room_type_id: StringName) -> Dictionary:
	if not ROOMS.has(room_type_id):
		push_warning("RoomCfg: unknown room_type_id: %s" % room_type_id)
		return {}
	return ROOMS[room_type_id]

static func get_min_size(room_type_id: StringName) -> Vector2i:
	var def := get_room_def(room_type_id)
	if def.is_empty():
		return Vector2i.ZERO
	return def.get("min_size_cells", Vector2i.ONE)

static func get_default_size(room_type_id: StringName) -> Vector2i:
	var def := get_room_def(room_type_id)
	if def.is_empty():
		return Vector2i.ZERO
	return def.get("default_size_cells", def.get("min_size_cells", Vector2i.ONE))

static func get_base_capacity(room_type_id: StringName) -> int:
	var def := get_room_def(room_type_id)
	if def.is_empty():
		return 0
	return int(def.get("base_capacity", 0))

static func get_debug_color(room_type_id: StringName) -> Color:
	var def := get_room_def(room_type_id)
	if def.is_empty():
		return Color(1, 1, 1, 0.1)
	return def.get("debug_color", Color(1, 1, 1, 0.1))

static func is_airlock(room_type_id: StringName) -> bool:
	var def := get_room_def(room_type_id)
	if def.is_empty():
		return false
	return def.get("is_airlock", false)
