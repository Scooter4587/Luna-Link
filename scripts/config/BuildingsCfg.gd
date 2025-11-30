extends Node
class_name BuildingsCfg

## Data-driven konfigurácia všetkých building typov v hre.
##
## POVINNÉ KĽÚČE (per building):
## - id: String                 # interný identifikátor (zvyčajne rovnaký ako dictionary kľúč)
## - display_name: String       # text do UI
## - domain: String             # "exterior" | "interior"
## - category: String           # "foundation" | "exterior" | "interior" | "object"
## - footprint_type: String     # "fixed" | "rect_drag" | "path"
## - anchor_type: String        # "free" | "on_resource_node" | "on_foundation" | "inside_hub" | "adjacent_foundation" | ...
## - size_cells: Vector2i       # základný tile footprint (alebo unit tile pre rect_drag/path)
## - pivot_cell: Vector2i       # ukotvenie v rámci footprintu
## - placement_rules: Array     # mená pravidiel pre PlacementService (String)
##
## VOLITEĽNÉ:
## - min_size_cells: Vector2i   # minimálny rect size pre rect_drag (napr. 4x4)
## - max_size_cells: Vector2i   # maximálny rect size, ak chceme limit
## - min_clear_radius: int      # minimálna vzdialenosť od iných budov (v tiles)
##
## - time_mode: String          # "game_hours" | "game_minutes" | "realtime_seconds"
## - build_time_per_tile: float # čas / tile (pri rect_drag)
## - build_time_total: float    # fixný čas
##
## - cost_per_tile: Dictionary  # resource_id (StringName) -> množstvo / tile
## - cost: Dictionary           # resource_id (StringName) -> fixná cena
##
## - behaviors: Array[Dictionary] # zoznam behavior modulov (type + config Dictionary)
##
## - ui_group: String           # skupina pre build UI (napr. "foundation", "exterior_power", "interior_room")
## - ui_icon_id: String         # ID ikonky / placeholder textúry (môže byť rovnaké ako id)
## - max_instances: int         # globálny limit inštancií (napr. 1 pre hub_core)
## - required_objects: Array    # zoznam object id, ktoré roomka neskôr vyžaduje (napr. ["bunk_bed"])


const BUILDINGS: Dictionary = {
	# -------------------------------------------------------------------------
	# FOUNDATION BASIC – ťahaný obdĺžnik, cost a čas sú PER TILE
	# -------------------------------------------------------------------------
	"foundation_basic": {
		"id": "foundation_basic",
		"display_name": "Basic Foundation",
		"domain": "exterior",
		"category": "foundation",
		"footprint_type": "rect_drag",
		"anchor_type": "free",
		"size_cells": Vector2i(1, 1),
		"pivot_cell": Vector2i(0, 0),
		"placement_rules": [
			"FreeArea",
			"MinClearRadius",
		],
		"min_clear_radius": 6,

		"time_mode": "game_hours",
		"build_time_per_tile": 0.05,  # 20 tiles ≈ 1 herná hodina

		"cost_per_tile": {
			&"building_materials": 5.0,
		},

		"behaviors": [
			# foundation zatiaľ bez špeciálneho správania
		],

		"ui_group": "foundation",
		"ui_icon_id": "foundation_basic",
	},

	# -------------------------------------------------------------------------
	# LANDING PAD BASIC – prvý landing point na mesiaci
	# -------------------------------------------------------------------------
	"landing_pad_basic": {
		"id": "landing_pad_basic",
		"display_name": "Landing Pad (Basic)",
		"domain": "exterior",
		"category": "exterior",
		"footprint_type": "fixed",
		"anchor_type": "free",  # môže stáť samostatne, bez foundation
		"size_cells": Vector2i(6, 6),   # placeholder
		"pivot_cell": Vector2i(3, 3),   # stred, placeholder

		"placement_rules": [
			"FreeArea",
			"MinClearRadius",
		],
		"min_clear_radius": 8,

		"time_mode": "game_hours",
		"build_time_total": 4.0,  # placeholder

		"cost": {
			&"building_materials": 200.0,
			&"equipment": 40.0,
		},

		"behaviors": [
			# neskôr: LandingZone / zásielky zo Zeme / crew arrival
		],

		"ui_group": "exterior_logistics",
		"ui_icon_id": "landing_pad_basic",
	},

	# -------------------------------------------------------------------------
	# SOLAR PANEL ( pôvodný placeholder ) – nechávame kvôli kompatibilite
	# -------------------------------------------------------------------------
	"solar_panel": {
		"id": "solar_panel",
		"display_name": "Solar Panel (Legacy)",
		"domain": "exterior",
		"category": "exterior",
		"footprint_type": "fixed",
		"anchor_type": "free",
		"size_cells": Vector2i(2, 1),  # placeholder
		"pivot_cell": Vector2i(0, 0),  # placeholder
		"placement_rules": [
			"FreeArea",
		],

		"time_mode": "game_hours",
		"build_time_total": 2.0,  # placeholder

		"cost": {
			# legacy / dev-only, necháme prázdne
		},

		"behaviors": [
			# dev-only, nepoužívame v survival sete
		],

		"ui_group": "exterior_power",
		"ui_icon_id": "solar_panel",
	},

	# -------------------------------------------------------------------------
	# SOLAR PANEL BASIC – survival verzia, bez foundation
	# -------------------------------------------------------------------------
	"solar_panel_basic": {
		"id": "solar_panel_basic",
		"display_name": "Solar Panel (Basic)",
		"domain": "exterior",
		"category": "exterior",
		"footprint_type": "fixed",
		"anchor_type": "free",  # podľa tvojho komentára: nepotrebuje foundation
		"size_cells": Vector2i(2, 2),   # placeholder
		"pivot_cell": Vector2i(0, 0),

		"placement_rules": [
			"FreeArea",
		],

		"time_mode": "game_hours",
		"build_time_total": 1.5,  # placeholder

		"cost": {
			&"building_materials": 25.0,
			&"equipment": 5.0,
		},

		"behaviors": [
			{
				"type": "PowerProducer",
				"config": {
					"production_per_hour": 10.0,  # placeholder, neskôr vybalansujeme
				},
			},
		],

		"ui_group": "exterior_power",
		"ui_icon_id": "solar_panel_basic",
	},

	# -------------------------------------------------------------------------
	# BATTERY SMALL – exterior batéria, ideálne na foundation
	# -------------------------------------------------------------------------
	"battery_small": {
		"id": "battery_small",
		"display_name": "Battery (Small)",
		"domain": "exterior",
		"category": "exterior",
		"footprint_type": "fixed",
		"anchor_type": "on_foundation",  # držme ju pri hube / na stabilnej ploche
		"size_cells": Vector2i(2, 1),    # placeholder
		"pivot_cell": Vector2i(0, 0),

		"placement_rules": [
			"OnFoundation",
			"FreeArea",
		],

		"time_mode": "game_hours",
		"build_time_total": 1.0,

		"cost": {
			&"building_materials": 30.0,
			&"equipment": 10.0,
		},

		"behaviors": [
			{
				"type": "PowerStorage",
				"config": {
					"capacity": 100.0,
					"start_charge": 0.0,  # neskôr mapneme na current_charge v node
				},
			},
		],

		"ui_group": "exterior_power",
		"ui_icon_id": "battery_small",
	},

	# -------------------------------------------------------------------------
	# OXYGEN GENERATOR SMALL – ext. generátor O2, musí byť pri foundation
	# -------------------------------------------------------------------------
	"oxygen_generator_small": {
		"id": "oxygen_generator_small",
		"display_name": "Oxygen Generator (Small)",
		"domain": "exterior",
		"category": "exterior",
		"footprint_type": "fixed",
		"anchor_type": "adjacent_foundation",  # špecifický anchor: vedľa foundation
		"size_cells": Vector2i(2, 2),
		"pivot_cell": Vector2i(0, 0),

		"placement_rules": [
			"AdjacentToFoundation",  # budúca PlacementService logika
			"FreeArea",
		],

		"time_mode": "game_hours",
		"build_time_total": 2.0,

		"cost": {
			&"building_materials": 40.0,
			&"equipment": 15.0,
		},

		"behaviors": [
			{
				"type": "PowerConsumer",
				"config": {
					"consumption_per_hour": 5.0,
					"critical": true,
				},
			},
			{
				"type": "ProductionHourly",
				"config": {
					"input_resource_id": &"water",
					"input_per_hour": 1.0,
					"output_resource_id": &"oxygen_units",
					"output_per_hour": 2.0,
					"require_power": true,
					"require_full_input": true,
				},
			},
		],

		"ui_group": "exterior_life_support",
		"ui_icon_id": "oxygen_generator_small",
	},

	# -------------------------------------------------------------------------
	# ICE MINE BASIC – ext. ťažba ice na resource node
	# -------------------------------------------------------------------------
	"ice_mine_basic": {
		"id": "ice_mine_basic",
		"display_name": "Ice Mine (Basic)",
		"domain": "exterior",
		"category": "exterior",
		"footprint_type": "fixed",
		"anchor_type": "on_resource_node",
		"size_cells": Vector2i(2, 2),
		"pivot_cell": Vector2i(0, 0),

		"placement_rules": [
			"OnResourceNode",
			"NoExtractorPresent",
			"MinClearRadius",
		],
		"min_clear_radius": 4,

		"time_mode": "game_hours",
		"build_time_total": 3.0,

		"cost": {
			&"building_materials": 60.0,
			&"equipment": 20.0,
		},

		"behaviors": [
			{
				"type": "PowerConsumer",
				"config": {
					"consumption_per_hour": 4.0,
					"critical": false,
				},
			},
			{
				"type": "ProductionHourly",
				"config": {
					"input_resource_id": &"",          # ťažba z terénu
					"input_per_hour": 0.0,
					"output_resource_id": &"ice",
					"output_per_hour": 5.0,           # placeholder
					"require_power": true,
					"require_full_input": false,
				},
			},
		],

		"ui_group": "exterior_mining",
		"ui_icon_id": "ice_mine_basic",
	},

	# -------------------------------------------------------------------------
	# BM EXTRACTOR – zatiaľ ponechávame ako mining building mimo survival setu
	# -------------------------------------------------------------------------
	"bm_extractor": {
		"id": "bm_extractor",
		"display_name": "BM Extractor",
		"domain": "exterior",
		"category": "exterior",
		"footprint_type": "fixed",
		"anchor_type": "on_resource_node",
		"size_cells": Vector2i(2, 2),  # placeholder
		"pivot_cell": Vector2i(0, 1),  # placeholder
		"placement_rules": [
			"FreeArea",
			"OnResourceNode",
			"NoExtractorPresent",
			"MinClearRadius",
		],
		"min_clear_radius": 6,

		"time_mode": "game_minutes",
		"build_time_total": 3.0 * 60.0,  # 3 herné hodiny v minútach

		"cost": {
			&"building_materials": 100.0,
			&"equipment": 20.0,
		},

		"behaviors": [
			# TODO: ProductionHourly + PowerConsumer, keď budeme chcieť BM pipeline
		],

		"ui_group": "exterior_mining",
		"ui_icon_id": "bm_extractor",
	},

	# -------------------------------------------------------------------------
	# POWER CABLE – path, veľmi rýchla stavba
	# -------------------------------------------------------------------------
	"power_cable": {
		"id": "power_cable",
		"display_name": "Power Cable",
		"domain": "exterior",
		"category": "exterior",
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
			# TODO: doplniť podľa balancing
		},

		"behaviors": [
			# TODO: PowerLink / network behavior
		],

		"ui_group": "exterior_power",
		"ui_icon_id": "power_cable",
	},

	# -------------------------------------------------------------------------
	# HUB CORE – srdce hubu, interiér, jedinečný (max 1)
	# -------------------------------------------------------------------------
	"hub_core": {
		"id": "hub_core",
		"display_name": "Hub Core",
		"domain": "interior",
		"category": "interior",
		"footprint_type": "fixed",
		"anchor_type": "on_foundation",
		"size_cells": Vector2i(6, 6),  # placeholder
		"pivot_cell": Vector2i(3, 3),

		"placement_rules": [
			"OnFoundation",
			"FreeArea",
			"UniqueGlobal",  # PlacementService: povoliť max 1 v hre
		],

		"time_mode": "game_hours",
		"build_time_total": 4.0,

		"cost": {
			&"building_materials": 150.0,
			&"equipment": 40.0,
		},

		"behaviors": [
			{
				"type": "PowerConsumer",
				"config": {
					"consumption_per_hour": 5.0,
					"critical": true,
				},
			},
			{
				"type": "HubCore",
				"config": {
					# neskôr: bounds interiéru, základný life support atď.
				},
			},
		],

		"ui_group": "interior_core",
		"ui_icon_id": "hub_core",
		"max_instances": 1,
	},

	# -------------------------------------------------------------------------
	# AIRLOCK BASIC – prechod medzi exteriérom a interiérom
	# -------------------------------------------------------------------------
	"airlock_basic": {
		"id": "airlock_basic",
		"display_name": "Airlock (Basic)",
		"domain": "interior",
		"category": "interior",
		"footprint_type": "fixed",
		"anchor_type": "at_hub_edge",  # špecifický anchor: na okraji hub_core
		"size_cells": Vector2i(2, 2),
		"pivot_cell": Vector2i(1, 1),

		"placement_rules": [
			"OnFoundation",
			"AtHubEdge",
		],

		"time_mode": "game_hours",
		"build_time_total": 1.5,

		"cost": {
			&"building_materials": 40.0,
			&"equipment": 15.0,
		},

		"behaviors": [
			{
				"type": "PowerConsumer",
				"config": {
					"consumption_per_hour": 1.0,
					"critical": true,
				},
			},
			{
				"type": "Airlock",
				"config": {
					# neskôr: dve dvere, pravidlo "len jedny otvorené"
				},
			},
		],

		"ui_group": "interior_access",
		"ui_icon_id": "airlock_basic",
	},

	# -------------------------------------------------------------------------
	# CREW QUARTERS SMALL – pôvodná interiérová miestnosť (legacy / dev)
	# -------------------------------------------------------------------------
	"crew_quarters_small": {
		"id": "crew_quarters_small",
		"display_name": "Crew Quarters (Small)",
		"domain": "interior",
		"category": "interior",
		"footprint_type": "rect_drag",
		"anchor_type": "inside_hub",   # musí byť vnútri hub_core bounds
		"size_cells": Vector2i(1, 1),
		"pivot_cell": Vector2i(0, 0),

		"placement_rules": [
			"InsideHubBounds",
			"OnInteriorFloor",
			"NoOverlapInteriorRoom",
		],

		"min_size_cells": Vector2i(4, 4),

		"time_mode": "game_hours",
		"build_time_per_tile": 0.10,

		"cost_per_tile": {
			&"building_materials": 3.0,
		},

		"behaviors": [
			{
				"type": "PowerConsumer",
				"config": {
					"consumption_per_hour": 1.0,
					"critical": false,
				},
			},
			{
				"type": "CrewCapacity",
				"config": {
					"base_capacity": 4,  # placeholder – neskôr naviažeme na objekty (bunks)
				},
			},
		],

		"required_objects": [
			"bunk_bed",  # budúci object typ
		],

		"ui_group": "interior_room",
		"ui_icon_id": "crew_quarters_small",
	},

	# -------------------------------------------------------------------------
	# MESS HALL SMALL – pôvodná interiérová miestnosť (legacy / dev)
	# -------------------------------------------------------------------------
	"mess_hall_small": {
		"id": "mess_hall_small",
		"display_name": "Mess Hall (Small)",
		"domain": "interior",
		"category": "interior",
		"footprint_type": "rect_drag",
		"anchor_type": "inside_hub",
		"size_cells": Vector2i(1, 1),
		"pivot_cell": Vector2i(0, 0),

		"placement_rules": [
			"InsideHubBounds",
			"OnInteriorFloor",
			"NoOverlapInteriorRoom",
		],

		"min_size_cells": Vector2i(4, 4),

		"time_mode": "game_hours",
		"build_time_per_tile": 0.10,

		"cost_per_tile": {
			&"building_materials": 4.0,
		},

		"behaviors": [
			{
				"type": "PowerConsumer",
				"config": {
					"consumption_per_hour": 1.5,
					"critical": false,
				},
			},
			{
				"type": "CrewNeeds",
				"config": {
					# neskôr: vplyv na hunger / happiness
				},
			},
		],

		"required_objects": [
			"table",
			"chair",
		],

		"ui_group": "interior_room",
		"ui_icon_id": "mess_hall_small",
	},

	# -------------------------------------------------------------------------
	# WAREHOUSE SMALL – interiérový sklad
	# -------------------------------------------------------------------------
	"warehouse_small": {
		"id": "warehouse_small",
		"display_name": "Warehouse (Small)",
		"domain": "interior",
		"category": "interior",
		"footprint_type": "rect_drag",
		"anchor_type": "inside_hub",
		"size_cells": Vector2i(1, 1),
		"pivot_cell": Vector2i(0, 0),

		"placement_rules": [
			"InsideHubBounds",
			"OnInteriorFloor",
			"NoOverlapInteriorRoom",
		],

		"min_size_cells": Vector2i(4, 4),

		"time_mode": "game_hours",
		"build_time_per_tile": 0.08,

		"cost_per_tile": {
			&"building_materials": 3.0,
		},

		"behaviors": [
			{
				"type": "Storage",
				"config": {
					"capacity": 200.0,
				},
			},
		],

		"ui_group": "interior_room",
		"ui_icon_id": "warehouse_small",
	},

	# -------------------------------------------------------------------------
	# HYDROPONICS BASIC – interiérová produkcia jedla z vody
	# -------------------------------------------------------------------------
	"hydroponics_basic": {
		"id": "hydroponics_basic",
		"display_name": "Hydroponics (Basic)",
		"domain": "interior",
		"category": "interior",
		"footprint_type": "rect_drag",
		"anchor_type": "inside_hub",
		"size_cells": Vector2i(1, 1),
		"pivot_cell": Vector2i(0, 0),

		"placement_rules": [
			"InsideHubBounds",
			"OnInteriorFloor",
			"NoOverlapInteriorRoom",
		],

		"min_size_cells": Vector2i(4, 4),

		"time_mode": "game_hours",
		"build_time_per_tile": 0.12,

		"cost_per_tile": {
			&"building_materials": 4.0,
			&"equipment": 1.0,
		},

		"behaviors": [
			{
				"type": "PowerConsumer",
				"config": {
					"consumption_per_hour": 3.0,
					"critical": false,
				},
			},
			{
				"type": "ProductionHourly",
				"config": {
					"input_resource_id": &"water",
					"input_per_hour": 1.0,
					"output_resource_id": &"food",
					"output_per_hour": 2.0,
					"require_power": true,
					"require_full_input": true,
				},
			},
		],

		"ui_group": "interior_room",
		"ui_icon_id": "hydroponics_basic",
	},

	# -------------------------------------------------------------------------
	# BASIC ROOM – pôvodný generic interiér (môže zostať ako dev / sandbox)
	# -------------------------------------------------------------------------
	"room_basic": {
		"id": "room_basic",
		"display_name": "Basic Room",
		"domain": "interior",
		"category": "interior",
		"footprint_type": "rect_drag",
		"anchor_type": "on_foundation",
		"size_cells": Vector2i(1, 1),
		"pivot_cell": Vector2i(0, 0),
		"placement_rules": [
			"OnFoundation",
			"FreeArea",
		],

		"time_mode": "game_hours",
		"build_time_per_tile": 0.10,

		"cost_per_tile": {
			# dev-only placeholder
		},

		"behaviors": [
			# dev / sandbox room
		],

		"ui_group": "interior_room",
		"ui_icon_id": "room_basic",
	},

	# -------------------------------------------------------------------------
	# 0.0.63 – NOVÉ INTERIOR ROOM BUILDINGS (napojené na RoomCfg ID cez string)
	# -------------------------------------------------------------------------
	"room_quarters_basic": {
		"id": "room_quarters_basic",
		"display_name": "Room – Crew Quarters (Basic)",
		"domain": "interior",
		"category": "interior",
		"footprint_type": "rect_drag",
		"anchor_type": "inside_hub",
		"size_cells": Vector2i(1, 1),
		"pivot_cell": Vector2i(0, 0),

		"placement_rules": [
			"InsideFoundation",
		],

		# ID, ktore MUSI sediet s RoomCfg.TYPE_QUARTERS_BASIC (&"quarters_basic")
		"room_type_id": &"quarters_basic",
		"min_size_cells": Vector2i(3, 2),

		"time_mode": "game_hours",
		"build_time_per_tile": 0.05,

		"cost_per_tile": {
			&"building_materials": 3.0,
		},

		"ui_group": "interior_rooms",
		"ui_icon_id": "room_quarters_basic",
	},

	"room_mess_hall_basic": {
		"id": "room_mess_hall_basic",
		"display_name": "Room – Mess Hall (Basic)",
		"domain": "interior",
		"category": "interior",
		"footprint_type": "rect_drag",
		"anchor_type": "inside_hub",
		"size_cells": Vector2i(1, 1),
		"pivot_cell": Vector2i(0, 0),

		"placement_rules": [
			"InsideFoundation",
		],

		"room_type_id": &"mess_hall_basic",
		"min_size_cells": Vector2i(3, 2),

		"time_mode": "game_hours",
		"build_time_per_tile": 0.05,

		"cost_per_tile": {
			&"building_materials": 3.0,
		},

		"ui_group": "interior_rooms",
		"ui_icon_id": "room_mess_hall_basic",
	},

	"room_airlock_basic": {
		"id": "room_airlock_basic",
		"display_name": "Room – Airlock (Basic)",
		"domain": "interior",
		"category": "interior",
		"footprint_type": "rect_drag",
		"anchor_type": "inside_hub",
		"size_cells": Vector2i(1, 1),
		"pivot_cell": Vector2i(0, 0),

		"placement_rules": [
			"InsideFoundation",
		],

		"room_type_id": &"airlock_basic",
		"min_size_cells": Vector2i(2, 2),

		"time_mode": "game_hours",
		"build_time_per_tile": 0.05,

		"cost_per_tile": {
			&"building_materials": 3.0,
		},

		"ui_group": "interior_rooms",
		"ui_icon_id": "room_airlock_basic",
	},

	# -------------------------------------------------------------------------
	# 0.0.63 – INTERIOR OBJECTS (placeholdery, budu sa klast InsideRoom)
	# -------------------------------------------------------------------------
	"door_interior_basic": {
		"id": "door_interior_basic",
		"display_name": "Interior Door (Basic)",
		"domain": "interior",
		"category": "object",
		"footprint_type": "fixed",
		"anchor_type": "inside_hub",
		"size_cells": Vector2i(1, 1),
		"pivot_cell": Vector2i(0, 0),

		"placement_rules": [
			"InsideRoom",
		],

		"time_mode": "game_hours",
		"build_time_total": 0.25,

		"cost": {
			&"building_materials": 2.0,
		},

		"behaviors": [
			# neskor: Door / Navigation blocker, prepojene s AirlockController
		],

		"ui_group": "interior_objects",
		"ui_icon_id": "door_interior_basic",
	},

	"bed_basic": {
		"id": "bed_basic",
		"display_name": "Bed (Basic)",
		"domain": "interior",
		"category": "object",
		"footprint_type": "fixed",
		"anchor_type": "inside_hub",
		"size_cells": Vector2i(1, 2),
		"pivot_cell": Vector2i(0, 0),

		"placement_rules": [
			"InsideRoom",
		],

		"time_mode": "game_hours",
		"build_time_total": 0.5,

		"cost": {
			&"building_materials": 3.0,
		},

		"behaviors": [
			# neskor: ovplyvnuje sleep komfort v Quarters
		],

		"ui_group": "interior_objects",
		"ui_icon_id": "bed_basic",
	},

	"table_basic": {
		"id": "table_basic",
		"display_name": "Table (Basic)",
		"domain": "interior",
		"category": "object",
		"footprint_type": "fixed",
		"anchor_type": "inside_hub",
		"size_cells": Vector2i(2, 1),
		"pivot_cell": Vector2i(0, 0),

		"placement_rules": [
			"InsideRoom",
		],

		"time_mode": "game_hours",
		"build_time_total": 0.5,

		"cost": {
			&"building_materials": 3.0,
		},

		"behaviors": [
			# neskor: dekor + komfort v Mess Hall / Quarters
		],

		"ui_group": "interior_objects",
		"ui_icon_id": "table_basic",
	},
}


static func get_building(id: String) -> Dictionary:
	## Vráti konfiguráciu budovy podľa id.
	## Ak id neexistuje, vráti prázdny Dictionary.
	return BUILDINGS.get(id, {})


static func get_all_ids() -> PackedStringArray:
	## Vráti zoznam všetkých definovaných building id.
	var ids: PackedStringArray = PackedStringArray()
	for key in BUILDINGS.keys():
		ids.append(str(key))
	return ids


static func get_ids_by_category(category: String) -> PackedStringArray:
	## Helper pre build UI – vráti id všetkých budov s danou category.
	var result: PackedStringArray = PackedStringArray()
	for key in BUILDINGS.keys():
		var cfg: Dictionary = BUILDINGS[key]
		if cfg.get("category", "") == category:
			result.append(str(key))
	return result
