extends Node

const PlacementServiceScript: GDScript = preload("res://scripts/services/placement_service.gd")
const GhostServiceScript: GDScript = preload("res://scripts/services/ghost_service.gd")

func _ready() -> void:
	# 1) Footprint test
	var extractor_cells: Array[Vector2i] = PlacementServiceScript.get_footprint(
		"bm_extractor",
		Vector2i(10, 10)
	)
	print("Extractor footprint @ (10,10): ", extractor_cells)

	var foundation_cells: Array[Vector2i] = PlacementServiceScript.get_footprint(
		"foundation_basic",
		Vector2i(0, 0),
		Vector2i(2, 1)
	)
	print("Foundation rect footprint (0,0)-(2,1): ", foundation_cells)

	# 2) Valid + ghost OK
	var ctx_ok: Dictionary = {
		"occupied_cells": {},
		"resource_cells": [Vector2i(10, 9)],
	}
	var res_ok: Dictionary = PlacementServiceScript.validate_placement(
		"bm_extractor",
		extractor_cells,
		ctx_ok
	)
	print("Validate extractor (on resource, free): ", res_ok)

	var ghost_ok: Dictionary = GhostServiceScript.build_ghost_info(
		"bm_extractor",
		extractor_cells,
		res_ok
	)
	print("Ghost info extractor (OK): ", ghost_ok)

	# 3) Obsadený tile + ghost BLOCKED
	var ctx_blocked: Dictionary = {
		"occupied_cells": {Vector2i(11, 9): true},
		"resource_cells": [Vector2i(10, 9)],
	}
	var res_blocked: Dictionary = PlacementServiceScript.validate_placement(
		"bm_extractor",
		extractor_cells,
		ctx_blocked
	)
	print("Validate extractor (tile occupied): ", res_blocked)

	var ghost_blocked: Dictionary = GhostServiceScript.build_ghost_info(
		"bm_extractor",
		extractor_cells,
		res_blocked
	)
	print("Ghost info extractor (blocked): ", ghost_blocked)
