extends Node

const PlacementServiceScript: GDScript = preload("res://scripts/services/placement_service.gd")

func _ready() -> void:
	# 1) Footprint test - ostáva
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

	# 2) Validácia - BM extractor na resource node, nič neblokuje
	var ctx_ok: Dictionary = {
		"occupied_cells": {},                           # nič nie je obsadené
		"resource_cells": [Vector2i(10, 9)],           # resource tile pod extraktorom
	}
	var res_ok: Dictionary = PlacementServiceScript.validate_placement(
		"bm_extractor",
		extractor_cells,
		ctx_ok
	)
	print("Validate extractor (on resource, free): ", res_ok)

	# 3) Validácia - BM extractor na resource, ale jeden tile obsadený
	var ctx_blocked: Dictionary = {
		"occupied_cells": {Vector2i(11, 9): true},     # jeden z footprint tiles je obsadený
		"resource_cells": [Vector2i(10, 9)],
	}
	var res_blocked: Dictionary = PlacementServiceScript.validate_placement(
		"bm_extractor",
		extractor_cells,
		ctx_blocked
	)
	print("Validate extractor (tile occupied): ", res_blocked)

	# 4) Validácia - foundation s FreeArea, ale kolízia
	var ctx_foundation: Dictionary = {
		"occupied_cells": {Vector2i(1, 0): true},      # v strede rectu je obsadený tile
		"resource_cells": [],
	}
	var res_foundation: Dictionary = PlacementServiceScript.validate_placement(
		"foundation_basic",
		foundation_cells,
		ctx_foundation
	)
	print("Validate foundation (with occupied tile): ", res_foundation)