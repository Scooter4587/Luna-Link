extends Node
class_name GhostService

## GhostService:
## - Prepojí výsledok validate_placement() s tým, čo bude ghost potrebovať.
## - Z footprintu + validation spraví prehľad:
##     - či je placement celkovo validný
##     - ktoré bunky sú OK / bloknuté
##     - aké chyby nastali (texty pre UI/debug)

enum CellState {
	VALID = 0,
	BLOCKED = 1,
}

static func build_ghost_info(
	building_id: String,
	footprint: Array[Vector2i],
	validation: Dictionary
) -> Dictionary:
	var info: Dictionary = {}

	info["building_id"] = building_id

	var is_valid_var: Variant = validation.get("is_valid", true)
	var is_valid: bool = bool(is_valid_var)
	info["is_valid"] = is_valid

	var per_cell_var: Variant = validation.get("per_cell", {})
	var per_cell_validation: Dictionary = per_cell_var as Dictionary

	var per_cell_state: Dictionary = {}
	for cell_any in footprint:
		var cell: Vector2i = cell_any as Vector2i
		var ok: bool = true
		if per_cell_validation.has(cell):
			ok = bool(per_cell_validation.get(cell, true))
		per_cell_state[cell] = (CellState.VALID if ok else CellState.BLOCKED)

	info["per_cell_state"] = per_cell_state

	var errors_var: Variant = validation.get("errors", [])
	var errors_any: Array = errors_var as Array
	var errors: Array[String] = []
	for e_any in errors_any:
		errors.append(e_any as String)

	info["errors"] = errors

	return info
