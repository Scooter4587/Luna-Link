extends Node
class_name PlacementService

## PlacementService:
## - Počíta footprint budovy (zoznam buniek v gride) podľa BuildingsCfg.
## - Zatiaľ riešime len:
##   - footprint_type = "fixed"
##   - footprint_type = "rect_drag"
## - "path" (power_cable) doplníme neskôr.

static func get_footprint(building_id: String, start_cell: Vector2i, end_cell: Vector2i = start_cell) -> Array[Vector2i]:
	## Vráti zoznam grid buniek, ktoré budova zaberie.
	## - pre "fixed": start_cell sa berie ako pivot bunka (napr. stred / kotviaci bod)
	## - pre "rect_drag": start_cell a end_cell definujú obdĺžnik (nezávisle od smeru ťahania)
	var cfg: Dictionary = BuildingsCfg.get_building(building_id)
	if cfg.is_empty():
		print("PlacementService: missing cfg for '%s'" % building_id)
		return []

	var footprint_type: String = (cfg.get("footprint_type", "fixed") as String)

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

	var size: Vector2i = (cfg.get("size_cells", Vector2i.ONE) as Vector2i)
	var local_pivot: Vector2i = (cfg.get("pivot_cell", Vector2i.ZERO) as Vector2i)

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
