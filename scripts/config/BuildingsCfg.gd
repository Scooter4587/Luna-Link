extends Node
class_name BuildingsCfg

## Data-driven konfigurácia všetkých building typov v hre.
##
## Kľúče v definícii jednej budovy:
## - id: String                    # interný identifikátor
## - display_name: String          # text do UI
## - domain: String                # "exterior" | "interior"
## - footprint_type: String        # "fixed" | "rect_drag" | "path"
## - anchor_type: String           # "free" | "on_resource_node" | "on_foundation" | "inside_room" ...
## - size_cells: Vector2i          # základný tile footprint (môže byť 1x1 pre rect_drag)
## - pivot_cell: Vector2i          # ukotvenie v rámci footprintu
## - placement_rules: Array[String]# mená pravidiel, ktoré rieši PlacementService
##
## - time_mode: String             # "game_hours" | "game_minutes" | "realtime_seconds"
## - build_time_per_tile: float    # voliteľné – čas / tile (v jednotkách podľa time_mode)
## - build_time_total: float       # voliteľné – fixný čas (v jednotkách podľa time_mode)
##
## - cost_per_tile: Dictionary     # voliteľné – resource_id -> množstvo / tile
## - cost: Dictionary              # voliteľné – fixná cena (resource_id -> množstvo)
##
## - behaviors: Array[Dictionary]  # zoznam behavior modulov (type + config)
## - min_clear_radius: int         # voliteľné – minimálna vzdialenosť od iných budov (v tiles)

const BUILDINGS: Dictionary = {
	# -------------------------------------------------------------------------
	# FOUNDATION BASIC – ťahaný obdĺžnik, cost a čas sú PER TILE
	# -------------------------------------------------------------------------
	"foundation_basic": {
		"id": "foundation_basic",
		"display_name": "Basic Foundation",
		"domain": "exterior",
		"footprint_type": "rect_drag",
		"anchor_type": "free",
		"size_cells": Vector2i(1, 1),
		"pivot_cell": Vector2i(0, 0),
		"placement_rules": [
			"FreeArea",
			"MinClearRadius",
		],
		"min_clear_radius": 6,

		# Časovanie – game_hours, per-tile (rovnaké ako predtým BuildCfg.FOUNDATION_HOURS_PER_TILE)
		"time_mode": "game_hours",
		"build_time_per_tile": 0.05,  # 20 tiles ≈ 1 herná hodina

		# Cena – per tile
		"cost_per_tile": {
			&"building_materials": 5.0,
		},

		"behaviors": [
			# foundation zatiaľ bez špeciálneho správania
		],
	},

	# -------------------------------------------------------------------------
	# BM EXTRACTOR – fixný footprint, fixná cena aj čas (3h v game_minutes)
	# -------------------------------------------------------------------------
	"bm_extractor": {
		"id": "bm_extractor",
		"display_name": "BM Extractor",
		"domain": "exterior",
		"footprint_type": "fixed",
		"anchor_type": "on_resource_node",
		"size_cells": Vector2i(2, 2),  # placeholder, upresníme neskôr
		"pivot_cell": Vector2i(0, 1),  # placeholder, podľa grafiky
		"placement_rules": [
			"FreeArea",
			"OnResourceNode",
			"NoExtractorPresent",
			"MinClearRadius",
		],
		"min_clear_radius": 6,

		# Časovanie – 3 herné HODINY v MINÚTACH (180 min)
		"time_mode": "game_minutes",
		"build_time_total": 3.0 * 60.0,

		# Cena – fixná
		"cost": {
			&"building_materials": 100.0,
			&"equipment": 20.0,
		},

		"behaviors": [
			# TODO: doplniť v 0.0.45 (ProductionHourly, PowerConsumer)
		],
	},

	# -------------------------------------------------------------------------
	# SOLAR PANEL – placeholder, fixed footprint + fixný čas
	# -------------------------------------------------------------------------
	"solar_panel": {
		"id": "solar_panel",
		"display_name": "Solar Panel",
		"domain": "exterior",
		"footprint_type": "fixed",
		"anchor_type": "free", # neskôr možno "on_foundation"
		"size_cells": Vector2i(2, 1),  # placeholder
		"pivot_cell": Vector2i(0, 0),  # placeholder
		"placement_rules": [
			"FreeArea",
		],

		"time_mode": "game_hours",
		"build_time_total": 2.0,  # placeholder

		"cost": {
			# TODO: doplniť reálne hodnoty
		},

		"behaviors": [
			# TODO: PowerProducer v 0.0.45+
		],
	},

	# -------------------------------------------------------------------------
	# POWER CABLE – path, zatiaľ fixný čas (neskôr per-tile podľa dĺžky pathu)
	# -------------------------------------------------------------------------
	"power_cable": {
		"id": "power_cable",
		"display_name": "Power Cable",
		"domain": "exterior",
		"footprint_type": "path",
		"anchor_type": "free",
		"size_cells": Vector2i(1, 1),
		"pivot_cell": Vector2i(0, 0),
		"placement_rules": [
			"FreeArea",
		],

		"time_mode": "game_hours",
		"build_time_total": 0.1,  # placeholder – veľmi rýchle

		"cost": {
			# TODO: doplniť
		},

		"behaviors": [
			# TODO: PowerLink / network behavior v 0.0.5+
		],
	},

	# -------------------------------------------------------------------------
	# BASIC ROOM – interiér, rect_drag, per-tile cost/čas
	# -------------------------------------------------------------------------
	"room_basic": {
		"id": "room_basic",
		"display_name": "Basic Room",
		"domain": "interior",
		"footprint_type": "rect_drag",
		"anchor_type": "on_foundation",
		"size_cells": Vector2i(1, 1),  # unit tile pre rect_drag
		"pivot_cell": Vector2i(0, 0),
		"placement_rules": [
			"OnFoundation",
			"FreeArea",
		],

		"time_mode": "game_hours",
		"build_time_per_tile": 0.10,  # placeholder – 10 tiles ≈ 1h

		"cost_per_tile": {
			# TODO: reálne hodnoty (napr. BM + Equipment per tile)
		},

		"behaviors": [
			# TODO: room-level behavior (life support, comfort, ...)
		],
	},
}


static func get_building(id: String) -> Dictionary:
	## Vráti konfiguráciu budovy podľa id.
	## Ak id neexistuje, vráti prázdny Dictionary.
	return BUILDINGS.get(id, {})


static func get_all_ids() -> PackedStringArray:
	## Vráti zoznam všetkých definovaných building id.
	var ids: PackedStringArray = []
	for key in BUILDINGS.keys():
		ids.append(str(key))
	return ids
