extends Node
class_name PlacementService

## PlacementService:
## - Počíta footprint budovy podľa BuildingsCfg.
## - Validuje placement podľa pravidiel v BuildingsCfg.placement_rules.
##
## Zatiaľ podporujeme:
## - footprint_type: "fixed", "rect_drag"
## - rules: "FreeArea", "OnResourceNode"
## - "NoExtractorPresent" zatiaľ ignorujeme (pripravíme si ho do budúcna).


# --------------------------------------------------
# FOOTPRINT
# --------------------------------------------------

static func get_footprint(building_id: String, start_cell: Vector2i, end_cell: Vector2i = start_cell) -> Array[Vector2i]:
    ## Vráti zoznam grid buniek, ktoré budova zaberie.
    ## - pre "fixed": start_cell sa berie ako pivot bunka
    ## - pre "rect_drag": start_cell a end_cell definujú obdĺžnik (nezávisle od smeru ťahania)
    var cfg: Dictionary = BuildingsCfg.get_building(building_id)
    if cfg.is_empty():
        print("PlacementService: missing cfg for '%s'" % building_id)
        return []

    var footprint_type_var: Variant = cfg.get("footprint_type", "fixed")
    var footprint_type: String = footprint_type_var as String

    match footprint_type:
        "fixed":
            return _make_fixed_footprint(start_cell, cfg)
        "rect_drag":
            return _make_rect_drag_footprint(start_cell, end_cell)
        # "path" budeme riešiť neskôr (power_cable)
        _:
            print("PlacementService: unsupported footprint_type '%s' for '%s'" % [footprint_type, building_id])
            return []


static func _make_fixed_footprint(pivot_cell: Vector2i, cfg: Dictionary) -> Array[Vector2i]:
    ## Vytvorí footprint pre budovu s fixným rozmerom.
    ## - size_cells = (šírka, výška) v tiles
    ## - pivot_cell v cfg = ktorý lokálny tile je kotviaci bod (0..w-1, 0..h-1)
    var result: Array[Vector2i] = []

    var size_var: Variant = cfg.get("size_cells", Vector2i.ONE)
    var size: Vector2i = size_var as Vector2i

    var local_pivot_var: Variant = cfg.get("pivot_cell", Vector2i.ZERO)
    var local_pivot: Vector2i = local_pivot_var as Vector2i

    for y: int in size.y:
        for x: int in size.x:
            var local: Vector2i = Vector2i(x, y)
            var offset: Vector2i = local - local_pivot
            var world_cell: Vector2i = pivot_cell + offset
            result.append(world_cell)

    return result


static func _make_rect_drag_footprint(start_cell: Vector2i, end_cell: Vector2i) -> Array[Vector2i]:
    ## Vytvorí footprint pre obdĺžnik ťahaný myšou.
    ## Nezáleží na smere ťahania – urobíme min/max v oboch osiach.
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

## API:
## ctx = {
##   "occupied_cells": Dictionary(Vector2i -> bool), # ktoré tiles sú už obsadené
##   "resource_cells": Array[Vector2i],              # kde sú resource nody (pre OnResourceNode)
## }
##
## Výsledok:
## {
##   "is_valid": bool,
##   "errors": Array[String],
##   "per_cell": Dictionary(Vector2i -> bool),  # ktoré tiles sú OK / bloknuté (napr. pre ghost farby)
## }

static func validate_placement(building_id: String, footprint: Array[Vector2i], ctx: Dictionary) -> Dictionary:
    var cfg: Dictionary = BuildingsCfg.get_building(building_id)
    if cfg.is_empty():
        return {
            "is_valid": false,
            "errors": ["Missing building config for '%s'" % building_id],
            "per_cell": {},
        }

    var rules_var: Variant = cfg.get("placement_rules", [])
    var rules: Array = rules_var as Array

    var is_valid: bool = true
    var errors: Array[String] = []
    var per_cell: Dictionary = {}

    # default: všetky tiles sú OK, kým nejaké pravidlo nepovie inak
    for cell in footprint:
        per_cell[cell] = true

    for rule_any in rules:
        var rule_name: String = rule_any as String

        match rule_name:
            "FreeArea":
                var free_result: Dictionary = _rule_free_area(footprint, ctx)
                if not (free_result.get("ok", true) as bool):
                    is_valid = false

                    var blocked_var: Variant = free_result.get("blocked_cells", [])
                    var blocked_cells: Array = blocked_var as Array

                    var err_var: Variant = free_result.get("errors", [])
                    var err_list: Array = err_var as Array

                    for e_any in err_list:
                        errors.append(e_any as String)

                    for cell_any in blocked_cells:
                        var c: Vector2i = cell_any as Vector2i
                        per_cell[c] = false

            "OnResourceNode":
                var res_result: Dictionary = _rule_on_resource_node(footprint, ctx)
                if not (res_result.get("ok", true) as bool):
                    is_valid = false

                    var err_var2: Variant = res_result.get("errors", [])
                    var err_list2: Array = err_var2 as Array
                    for e_any in err_list2:
                        errors.append(e_any as String)

            "NoExtractorPresent":
                # TODO: implementovať neskôr (napojenie na systém budov)
                pass

            "MinClearRadius":
                var res_mcr := _rule_min_clear_radius(building_id, footprint, ctx)
                if not res_mcr.is_valid:
                    is_valid = false
                    errors.append(res_mcr.error)
                    for cell in res_mcr.blocked_cells:
                        per_cell[cell] = false

            _:
                # neznáme pravidlo – ignorujeme
                pass

    return {
        "is_valid": is_valid,
        "errors": errors,
        "per_cell": per_cell,
    }


static func _rule_free_area(footprint: Array[Vector2i], ctx: Dictionary) -> Dictionary:
    ## FreeArea: žiadny tile z footprintu nesmie byť v occupied_cells == true
    var occ_var: Variant = ctx.get("occupied_cells", {})
    var occupied: Dictionary = occ_var as Dictionary

    var blocked: Array[Vector2i] = []

    for cell in footprint:
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


static func _rule_on_resource_node(footprint: Array[Vector2i], ctx: Dictionary) -> Dictionary:
    ## OnResourceNode: aspoň jeden tile z footprintu musí byť v resource_cells.
    var res_var: Variant = ctx.get("resource_cells", [])
    var res_cells_any: Array = res_var as Array

    var res_cells: Array[Vector2i] = []
    for item in res_cells_any:
        if item is Vector2i:
            res_cells.append(item as Vector2i)

    var ok: bool = false

    for cell in footprint:
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
        "blocked_cells": [],
    }

static func _rule_min_clear_radius(
        building_id: String,
        footprint: Array[Vector2i],
        ctx: Dictionary
    ) -> Dictionary:
    var result := {
        "is_valid": true,
        "error": "",
        "blocked_cells": [] as Array[Vector2i],
    }

    var cfg := BuildingsCfg.get_building(building_id)
    if cfg.is_empty():
        return result

    var radius: int = int(cfg.get("min_clear_radius", 0))
    if radius <= 0:
        return result  # pre väčšinu budov nič nerobíme

    var occupied: Dictionary = ctx.get("occupied_cells", {})
    if occupied.is_empty():
        return result

    var has_violation := false

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

        # označíme CELÝ footprint novej budovy ako bloknutý,
        # aby ghost nebol červený len v jednom tile
        var blocked: Array[Vector2i] = []
        for f_any in footprint:
            blocked.append(f_any as Vector2i)
        result["blocked_cells"] = blocked

    return result