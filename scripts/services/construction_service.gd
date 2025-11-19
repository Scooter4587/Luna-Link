extends Node
class_name ConstructionService

## ConstructionService:
## - Centrálne rieši:
##     * výpočet resource cost podľa BuildingsCfg (per-tile + fixná časť)
##     * nastavenie časovania na ConstructionSite (time_mode + build_game_hours/minutes)
##     * spawn ConstructionSite scény na správneho parenta
##
## Cieľ:
## - BuildMode rieši iba:
##     * kde a čo chceme stavať (building_id, top_left_cell, size_cells)
##     * či máme dosť resourcov (State.try_spend)
## - Všetky magic čísla o cene a čase sú v BuildingsCfg.

# Musí sedieť s enum BuildTimeMode v ConstructionSite.gd:
# enum BuildTimeMode { REALTIME_SECONDS = 0, GAME_MINUTES_FIXED = 1, GAME_HOURS_FIXED = 2 }
const TIME_MODE_REALTIME_SECONDS: int = 0
const TIME_MODE_GAME_MINUTES: int = 1
const TIME_MODE_GAME_HOURS: int = 2


# -----------------------------------------------------------------------------
# PUBLIC API: COST
# -----------------------------------------------------------------------------

static func compute_cost(building_id: String, size_cells: Vector2i) -> Dictionary:
	## Vráti Dictionary resource_id -> množstvo pre danú budovu a veľkosť.
	## - využíva "cost_per_tile" a "cost" z BuildingsCfg
	var cfg: Dictionary = BuildingsCfg.get_building(building_id)
	if cfg.is_empty():
		push_warning("[ConstructionService] compute_cost: unknown building_id '%s'" % building_id)
		return {}

	var result: Dictionary = {}
	var tiles: int = max(1, size_cells.x * size_cells.y)

	# Per-tile cost (napr. foundation_basic)
	if cfg.has("cost_per_tile"):
		var per_tile_any: Variant = cfg.get("cost_per_tile", {})
		var per_tile: Dictionary = per_tile_any as Dictionary

		for id_any in per_tile.keys():
			var res_id: StringName = StringName(id_any)
			var per_val: float = float(per_tile[res_id])
			var prev: float = float(result.get(res_id, 0.0))
			result[res_id] = prev + per_val * float(tiles)

	# Fixná cost (napr. bm_extractor)
	if cfg.has("cost"):
		var flat_any: Variant = cfg.get("cost", {})
		var flat: Dictionary = flat_any as Dictionary

		for id_any in flat.keys():
			var res_id2: StringName = StringName(id_any)
			var add_val: float = float(flat[res_id2])
			var prev2: float = float(result.get(res_id2, 0.0))
			result[res_id2] = prev2 + add_val

	return result


# -----------------------------------------------------------------------------
# PUBLIC API: SPAWN CONSTRUCTION SITE
# -----------------------------------------------------------------------------
##
## Použitie:
##   var site := ConstructionService.spawn_site({
##       "building_id": "foundation_basic",
##       "site_scene": construction_site_scene,
##       "construction_parent": construction_root_node,
##       "terrain_grid": terrain_grid,
##       "top_left_cell": Vector2i(minx, miny),
##       "size_cells": size,
##       "cell_px": cell_px,
##       "buildings_root_path": buildings_root,
##       "building_scene": building_scene,
##       "inside_build_scene": inside_build_scene,
##       "use_interior": true,
##   })
##
## Voliteľné kľúče (napr. extractor):
##   "use_center_override": bool
##   "spawn_center_override_world": Vector2
##   "visual_px_size": Vector2
##   "linked_resource_node_path": NodePath

static func spawn_site(config: Dictionary) -> Node2D:
	if not config.has("building_id") or not config.has("site_scene"):
		push_error("[ConstructionService] spawn_site: missing 'building_id' or 'site_scene'")
		return null

	var building_id: String = String(config["building_id"])
	var site_scene: PackedScene = config["site_scene"] as PackedScene
	if site_scene == null:
		push_error("[ConstructionService] spawn_site: site_scene is null")
		return null

	var parent: Node = config.get("construction_parent", null)
	if parent == null:
		push_error("[ConstructionService] spawn_site: construction_parent is null")
		return null

	var site: Node2D = site_scene.instantiate() as Node2D
	if site == null:
		push_error("[ConstructionService] spawn_site: instanced site is not Node2D")
		return null

	# Povinné údaje
	if config.has("terrain_grid"):
		site.set("terrain_grid", config["terrain_grid"])
	if config.has("top_left_cell"):
		site.set("top_left_cell", config["top_left_cell"])
	if config.has("size_cells"):
		site.set("size_cells", config["size_cells"])
	if config.has("cell_px"):
		site.set("cell_px", config["cell_px"])
	if config.has("building_scene"):
		site.set("building_scene", config["building_scene"])
	if config.has("inside_build_scene"):
		site.set("inside_build_scene", config["inside_build_scene"])
	if config.has("buildings_root_path"):
		site.set("buildings_root_path", config["buildings_root_path"])

	# Voliteľné flagy / override parametre
	if config.has("use_interior"):
		site.set("use_interior", bool(config["use_interior"]))
	if config.has("use_center_override"):
		site.set("use_center_override", bool(config["use_center_override"]))
	if config.has("spawn_center_override_world"):
		site.set("spawn_center_override_world", config["spawn_center_override_world"])
	if config.has("visual_px_size"):
		site.set("visual_px_size", config["visual_px_size"])
	if config.has("linked_resource_node_path"):
		site.set("linked_resource_node_path", config["linked_resource_node_path"])

	# Z-index + group
	site.z_index = 500
	site.add_to_group("construction_sites")

	# Nastav časovanie podľa BuildingsCfg
	var size_any: Variant = config.get("size_cells", Vector2i.ONE)
	var size_cells: Vector2i = size_any as Vector2i
	_setup_time_for_site(building_id, size_cells, site)

	# Až teraz pridáme do stromu → _ready() už uvidí nastavené hodnoty
	parent.add_child(site)

	return site


# -----------------------------------------------------------------------------
# INTERNAL: time_mode + build_time_xx
# -----------------------------------------------------------------------------

static func _map_time_mode(str_mode: String) -> int:
	var m: String = str_mode.to_lower()
	match m:
		"realtime_seconds":
			return TIME_MODE_REALTIME_SECONDS
		"game_minutes":
			return TIME_MODE_GAME_MINUTES
		"game_hours":
			return TIME_MODE_GAME_HOURS
		_:
			push_warning("[ConstructionService] Unknown time_mode '%s', fallback 'game_hours'" % str_mode)
			return TIME_MODE_GAME_HOURS


static func _setup_time_for_site(building_id: String, size_cells: Vector2i, site: Node) -> void:
	var cfg: Dictionary = BuildingsCfg.get_building(building_id)
	if cfg.is_empty():
		push_warning("[ConstructionService] _setup_time_for_site: unknown building_id '%s'" % building_id)
		return

	var time_mode_str: String = String(cfg.get("time_mode", "game_hours"))
	var mode_enum: int = _map_time_mode(time_mode_str)
	site.set("time_mode", mode_enum)

	var tiles: int = max(1, size_cells.x * size_cells.y)
	var total: float

	if cfg.has("build_time_per_tile"):
		var per_tile: float = float(cfg.get("build_time_per_tile", 0.0))
		total = max(1.0, per_tile * float(tiles))
	else:
		total = max(1.0, float(cfg.get("build_time_total", 1.0)))

	match mode_enum:
		TIME_MODE_GAME_HOURS:
			var hours: int = int(ceil(total))
			site.set("build_game_hours", max(1, hours))
		TIME_MODE_GAME_MINUTES:
			var minutes: int = int(ceil(total))
			site.set("build_game_minutes", max(1, minutes))
		TIME_MODE_REALTIME_SECONDS:
			# Dev režim cez realtime – používame dev_total_time
			site.set("dev_mode", true)
			site.set("dev_total_time", total)
