extends Node2D
class_name InsideBuild
## InsideBuild: generuje interiér budovy (podlahu a obvodové múry)
## podľa size_cells, ktorý dostane zo skriptu Building.gd.

@export var floors_layer: TileMapLayer
@export var walls_layer:  TileMapLayer
@export var doors_layer:  TileMapLayer
@export var cell_px: int = 128


## setup(size_cells):
## - vyčistí všetky vrstvy (podlaha, múry, dvere)
## - vygeneruje plnú podlahu
## - vytvorí obvodový múr hrúbky 1 tile podľa BuildCfg atlasu
func setup(size_cells: Vector2i) -> void:
	# drž konzistenciu s BuildCfg
	if cell_px != BuildCfg.CELL_PX:
		cell_px = BuildCfg.CELL_PX

	if floors_layer == null or walls_layer == null:
		push_error("[InsideBuild] floors_layer alebo walls_layer nie je priradený.")
		return

	var floor_src: int = floors_layer.tile_set.get_source_id(0)
	var wall_src: int = walls_layer.tile_set.get_source_id(0)

	floors_layer.clear()
	walls_layer.clear()
	if doors_layer != null:
		doors_layer.clear()

	# Podlaha (plná plocha)
	for y in size_cells.y:
		for x in size_cells.x:
			floors_layer.set_cell(Vector2i(x, y), floor_src, BuildCfg.FOUNDATION_FLOOR_ATLAS, 0)

	# Obvodové múry (1 tile hrúbka interiéru; vizuál = BuildCfg atlas)
	for x in size_cells.x:
		walls_layer.set_cell(Vector2i(x, 0),                wall_src, BuildCfg.FOUNDATION_WALL_ATLAS, 0)
		walls_layer.set_cell(Vector2i(x, size_cells.y - 1), wall_src, BuildCfg.FOUNDATION_WALL_ATLAS, 0)
	for y in size_cells.y:
		walls_layer.set_cell(Vector2i(0, y),                wall_src, BuildCfg.FOUNDATION_WALL_ATLAS, 0)
		walls_layer.set_cell(Vector2i(size_cells.x - 1, y), wall_src, BuildCfg.FOUNDATION_WALL_ATLAS, 0)
