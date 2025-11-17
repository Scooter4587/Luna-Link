extends Node

const PlacementServiceScript: GDScript = preload("res://scripts/services/placement_service.gd")

func _ready() -> void:
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
