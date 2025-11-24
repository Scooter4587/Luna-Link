extends Node
class_name PlacementService
## PlacementService
## - Počíta tile-footprint budovy podľa BuildingsCfg.
## - Validuje placement podľa zoznamu rules v BuildingsCfg.placement_rules.
##
## PODPOROVANÉ:
##   footprint_type:
##     - "fixed"      → pevný footprint okolo pivot tile
##     - "rect_drag"  → obdĺžnik ťahaný myšou (foundation, rooms)
##     - "path"       → TODO (napr. power_cable)
##
##   rules:
##     - "FreeArea"        → nesmie kolidovať s occupied_cells
##     - "OnResourceNode"  → footprint musí obsahovať aspoň jeden resource tile
##     - "MinClearRadius"  → Chebyshev vzdialenosť od iných budov
##     - "NoExtractorPresent" → placeholder (zatiaľ nič nerobí)
##
## CTX PRE validate_placement():
##   ctx = {
##     "occupied_cells": Dictionary(Vector2i -> bool),
##     "resource_cells": Array[Vector2i],
##   }
##
## VÝSLEDOK validate_placement():
## {
##   "is_valid": bool,
##   "errors": Array[String],
##   "per_cell": Dictionary(Vector2i -> bool),
## }

# --------------------------------------------------
# FOOTPRINT
# --------------------------------------------------

static func get_footprint(
	building_id: String,
	start_cell: Vector2i,
	end_cell: Vector2i = start_cell
) -> Array[Vector2i]:
	## Vráti zoznam grid buniek, ktoré budova zaberie.
	## - pre "fixed": start_cell je pivot tile
	## - pre "rect_drag": start_cell & end_cell definujú obdĺžnik (bez ohľadu na smer)
	var cfg: Dictionary = BuildingsCfg.get_building(building_id)
	if cfg.is_empty():
		print("PlacementService: missing cfg for '%s'" % building_id)
		return []

	var footprint_type: String = String(cfg.get("footprint_type", "fixed"))

	match footprint_type:
		"fixed":
			return _make_fixed_footprint(start_cell, cfg)
		"rect_drag":
			return _make_rect_drag_footprint(start_cell, end_cell)
		# "path" budeme riešiť neskôr (napr. power_cable)
		_:
			print("PlacementService: unsupported footprint_type '%s' for '%s'" % [footprint_type, building_id])
			return []


static func _make_fixed_footprint(pivot_cell: Vector2i, cfg: Dictionary) -> Array[Vector2i]:
	## Footprint pre budovu s fixným rozmerom.
	## - size_cells = (šírka, výška) v tiles
	## - pivot_cell v cfg = lokálny tile, ktorý sedí na pivot_cell
	var result: Array[Vector2i] = []

	var size: Vector2i = cfg.get("size_cells", Vector2i.ONE) as Vector2i
	var local_pivot: Vector2i = cfg.get("pivot_cell", Vector2i.ZERO) as Vector2i

	for y: int in size.y:
		for x: int in size.x:
			var local: Vector2i = Vector2i(x, y)
			var offset: Vector2i = local - local_pivot
			var world_cell: Vector2i = pivot_cell + offset
			result.append(world_cell)

	return result


static func _make_rect_drag_footprint(start_cell: Vector2i, end_cell: Vector2i) -> Array[Vector2i]:
	## Footprint pre obdĺžnik ťahaný myšou (foundation, rooms).
	## Nezáleží na smere ťahania – použijeme min/max.
	var result: Array[Vector2i] = []

	var min_x: int = min(start_cell.x, end_cell.x)
	var max_x: int = max(start_cell.x, end_cell.x)
	var min_y: int = min(start_cell.y, end_cell.y)
	var max_y: int = max(start_cell.y, end_cell.y)

	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			result.append(Vector2i(x, y))

	return result


# --------------------------------------------------
# VALIDATION
# --------------------------------------------------

static func validate_placement(
	building_id: String,
	footprint: Array[Vector2i],
	ctx: Dictionary
) -> Dictionary:
	## Hlavný vstup pre všetky build rules.
	## - načíta rules z BuildingsCfg[building_id].placement_rules
	## - aplikuje ich a vráti combined výsledok

	var cfg: Dictionary = BuildingsCfg.get_building(building_id)
	if cfg.is_empty():
		return {
			"is_valid": false,
			"errors": ["Missing building config for '%s'" % building_id],
			"per_cell": {},
		}

	var rules: Array = cfg.get("placement_rules", []) as Array

	var is_valid: bool = true
	var errors: Array[String] = []
	var per_cell: Dictionary = {}

	# default: všetky tiles sú OK, kým nejaké pravidlo nepovie inak
	for cell_any in footprint:
		var cell: Vector2i = cell_any as Vector2i
		per_cell[cell] = true

	for rule_any in rules:
		var rule_name: String = rule_any as String

		match rule_name:
			"FreeArea":
				var free_result: Dictionary = _rule_free_area(footprint, ctx)
				if not bool(free_result.get("ok", true)):
					is_valid = false

					var blocked_cells: Array = free_result.get("blocked_cells", []) as Array
					var err_list: Array = free_result.get("errors", []) as Array

					for e_any in err_list:
						errors.append(str(e_any))

					for cell_any in blocked_cells:
						var c: Vector2i = cell_any as Vector2i
						per_cell[c] = false

			"OnResourceNode":
				var res_result: Dictionary = _rule_on_resource_node(footprint, ctx)
				if not bool(res_result.get("ok", true)):
					is_valid = false
					var err_list2: Array = res_result.get("errors", []) as Array
					for e_any in err_list2:
						errors.append(str(e_any))

			"NoExtractorPresent":
				# Placeholder – logika sa doplní, keď budeme mať systém „extraktor vs node“ pevne hotový.
				pass

			"MinClearRadius":
				var mcr_result: Dictionary = _rule_min_clear_radius(building_id, footprint, ctx)
				if not bool(mcr_result.get("is_valid", true)):
					is_valid = false

					var err_str: String = mcr_result.get("error", "") as String
					if err_str != "":
						errors.append(err_str)

					var blocked_cells_mcr: Array = mcr_result.get("blocked_cells", []) as Array
					for cell_any in blocked_cells_mcr:
						var c2: Vector2i = cell_any as Vector2i
						per_cell[c2] = false

			_:
				# Neznáme pravidlo – ticho ignorujeme (forward compatibility).
				pass

	return {
		"is_valid": is_valid,
		"errors": errors,
		"per_cell": per_cell,
	}


# --- Rule: FreeArea ----------------------------------------------------------

static func _rule_free_area(footprint: Array[Vector2i], ctx: Dictionary) -> Dictionary:
	## FreeArea: žiadny tile z footprintu nesmie byť v occupied_cells == true.
	var occupied: Dictionary = ctx.get("occupied_cells", {}) as Dictionary

	var blocked: Array[Vector2i] = []

	for cell_any in footprint:
		var cell: Vector2i = cell_any as Vector2i
		if occupied.has(cell) and bool(occupied.get(cell, false)):
			blocked.append(cell)

	var ok: bool = blocked.is_empty()
	var errors: Array[String] = []
	if not ok:
		errors.append("FreeArea: %d tiles are already occupied" % blocked.size())

	return {
		"ok": ok,
		"errors": errors,
		"blocked_cells": blocked,
	}


# --- Rule: OnResourceNode ----------------------------------------------------

static func _rule_on_resource_node(footprint: Array[Vector2i], ctx: Dictionary) -> Dictionary:
	## OnResourceNode: aspoň jeden tile z footprintu musí byť v resource_cells.
	var res_cells_any: Array = ctx.get("resource_cells", []) as Array

	var res_cells: Array[Vector2i] = []
	for item in res_cells_any:
		if item is Vector2i:
			res_cells.append(item as Vector2i)

	var ok: bool = false

	for cell_any in footprint:
		var cell: Vector2i = cell_any as Vector2i
		for rc in res_cells:
			if cell == rc:
				ok = true
				break
		if ok:
			break

	var errors: Array[String] = []
	if not ok:
		errors.append("OnResourceNode: footprint does not cover any resource cell")

	return {
		"ok": ok,
		"errors": errors,
		"blocked_cells": [],  # tento rule priamo neblokuje konkrétne tiles
	}


# --- Rule: MinClearRadius ----------------------------------------------------

static func _rule_min_clear_radius(
	building_id: String,
	footprint: Array[Vector2i],
	ctx: Dictionary
) -> Dictionary:
	## MinClearRadius:
	## - číta radius z BuildingsCfg[building_id].min_clear_radius
	## - ak je 0 alebo chýba → rule sa ignoruje
	## - ak je > 0, počítame Chebyshev vzdialenosť od occupied_cells
	## - pri kolízii:
	##     - is_valid = false
	##     - error text pre UI/debug
	##     - blocked_cells = celý footprint (ghost celý červený)

	var result := {
		"is_valid": true,
		"error": "",
		"blocked_cells": [] as Array[Vector2i],
	}

	var cfg: Dictionary = BuildingsCfg.get_building(building_id)
	if cfg.is_empty():
		return result

	var radius: int = int(cfg.get("min_clear_radius", 0))
	if radius <= 0:
		return result  # pre väčšinu budov nič nerobíme

	var occupied: Dictionary = ctx.get("occupied_cells", {}) as Dictionary
	if occupied.is_empty():
		return result

	var has_violation: bool = false

	# Chebyshev vzdialenosť: max(|dx|, |dy|) <= radius
	for f_any in footprint:
		var f: Vector2i = f_any as Vector2i
		for occ_key in occupied.keys():
			var oc: Vector2i = occ_key as Vector2i
			var dx: int = abs(f.x - oc.x)
			var dy: int = abs(f.y - oc.y)
			if max(dx, dy) <= radius:
				has_violation = true
				break
		if has_violation:
			break

	if has_violation:
		result["is_valid"] = false
		result["error"] = "MinClearRadius: buildings too close (radius=%d)" % radius

		var blocked: Array[Vector2i] = []
		for f_any in footprint:
			blocked.append(f_any as Vector2i)
		result["blocked_cells"] = blocked

	return result