extends Node2D
## Inside_Build: generuje podlahu a obvodové múry pre danú veľkosť.

@export var floors_layer: TileMapLayer
@export var walls_layer:  TileMapLayer
@export var doors_layer:  TileMapLayer
@export var cell_px: int = 128

## Vygeneruje podlahu a obvodové múry podľa size_cells (z Building.gd).
func setup(size_cells: Vector2i) -> void:
	# drž konzistenciu s BuildCfg
	if cell_px != BuildCfg.CELL_PX:
		cell_px = BuildCfg.CELL_PX

	if floors_layer == null or walls_layer == null:
		push_error("[Inside_Build] floors_layer alebo walls_layer nie je priradený.")
		return

	var floor_src := floors_layer.tile_set.get_source_id(0)
	var wall_src  := walls_layer.tile_set.get_source_id(0)

	floors_layer.clear()
	walls_layer.clear()
	if doors_layer != null:
		doors_layer.clear()

	# Podlaha (plná plocha)
	for y in size_cells.y:
		for x in size_cells.x:
			floors_layer.set_cell(Vector2i(x, y), floor_src, BuildCfg.FOUNDATION_FLOOR_ATLAS, 0)

	# Obvodové múry (1 tile hrúbka interiéru; vizuál=BuildCfg atlas)
	for x in size_cells.x:
		walls_layer.set_cell(Vector2i(x, 0),                wall_src, BuildCfg.FOUNDATION_WALL_ATLAS, 0)
		walls_layer.set_cell(Vector2i(x, size_cells.y - 1), wall_src, BuildCfg.FOUNDATION_WALL_ATLAS, 0)
	for y in size_cells.y:
		walls_layer.set_cell(Vector2i(0, y),                wall_src, BuildCfg.FOUNDATION_WALL_ATLAS, 0)
		walls_layer.set_cell(Vector2i(size_cells.x - 1, y), wall_src, BuildCfg.FOUNDATION_WALL_ATLAS, 0)
