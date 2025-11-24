extends Node
class_name GhostService
## GhostService
## Pomocná služba pre build ghosty.
##
## ÚLOHA:
## - vezme výstup z PlacementService.validate_placement()
## - z `footprint` + `validation` vyrobí prehľad pre UI/ghost:
##     - celková validitaplacementu
##     - per-tile stav (OK / BLOCKED)
##     - zoznam chýb (texty pre debug / UI)
##
## OČAKÁVANÝ VSTUP (validation):
## {
##   "is_valid": bool,
##   "per_cell": Dictionary(Vector2i -> bool),
##   "errors": Array[String],
## }
##
## VÝSTUP:
## {
##   "building_id": String,
##   "is_valid": bool,
##   "per_cell_state": Dictionary(Vector2i -> int), # CellState.VALID/BLOCKED
##   "errors": Array[String],
## }

enum CellState {
	VALID = 0,
	BLOCKED = 1,
}

static func build_ghost_info(
	building_id: String,
	footprint: Array[Vector2i],
	validation: Dictionary
) -> Dictionary:
	var info: Dictionary = {
		"building_id": building_id,
		"is_valid": true,
		"per_cell_state": {},
		"errors": [],
	}

	# 1) Celková validita
	var is_valid: bool = bool(validation.get("is_valid", true))
	info["is_valid"] = is_valid

	# 2) Per-tile stav (VALID/BLOCKED) podľa validation.per_cell
	var per_cell_validation: Dictionary = validation.get("per_cell", {}) as Dictionary
	var per_cell_state: Dictionary = {}

	for cell_any in footprint:
		var cell: Vector2i = cell_any as Vector2i
		var ok: bool = true
		if per_cell_validation.has(cell):
			ok = bool(per_cell_validation.get(cell, true))
		per_cell_state[cell] = (CellState.VALID if ok else CellState.BLOCKED)

	info["per_cell_state"] = per_cell_state

	# 3) Errors → Array[String]
	var errors: Array[String] = []
	var errors_any: Array = validation.get("errors", []) as Array
	for e_any in errors_any:
		errors.append(str(e_any))

	info["errors"] = errors

	return info