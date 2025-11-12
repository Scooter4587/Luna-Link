extends Node2D
## Building: po spawne vytvorí interiér (podlaha + obvodové múry) podľa size_cells.

@export var size_cells: Vector2i = Vector2i(4, 3)     # nastaví ConstructionSite pri spawne
@export var interior_scene: PackedScene               # Inside_Build.tscn
@export var cell_px: int = 128                        # len pre konzistenciu gridu

var interior: Node2D

## Vytvorí vnútro budovy podľa size_cells.
func _ready() -> void:
	# drž konzistenciu s BuildCfg
	if cell_px != BuildCfg.CELL_PX:
		cell_px = BuildCfg.CELL_PX

	print("[Building] _ready size=", size_cells, " interior_scene is null? ", interior_scene == null)
	_spawn_interior()

## Nainštancuje Inside_Build a zavolá jeho setup(size_cells); ak chýba, fallback.
func _spawn_interior() -> void:
	if interior_scene == null:
		push_error("[Building] interior_scene is null (Inside_Build.tscn nepriradené).")
		return

	interior = interior_scene.instantiate() as Node2D
	add_child(interior)
	interior.position = Vector2.ZERO  # ľavý-horný roh

	# Preferované: Inside_Build.gd má metódu setup(size_cells)
	if interior.has_method("setup"):
		interior.call("setup", size_cells)
		return

	# ---- Fallback, ak setup neexistuje: nájdi TileMapLayer-y a polož dlaždice ----
	var floors := interior.find_child("Floors", true, false) as TileMapLayer
	var walls  := interior.find_child("Walls",  true, false) as TileMapLayer
	if floors == null or walls == null:
		push_error("[Building] Fallback zlyhal: Floors alebo Walls chýbajú v Inside_Build.")
		return

	var floor_src := floors.tile_set.get_source_id(0)
	var wall_src  := walls.tile_set.get_source_id(0)

	# Floor fill
	for y in size_cells.y:
		for x in size_cells.x:
			floors.set_cell(Vector2i(x, y), floor_src, BuildCfg.FOUNDATION_FLOOR_ATLAS, 0)

	# Perimeter walls (1 tile hrúbka interiéru; vizuál=BuildCfg atlas)
	for x in size_cells.x:
		walls.set_cell(Vector2i(x, 0),                wall_src, BuildCfg.FOUNDATION_WALL_ATLAS, 0)                     
		walls.set_cell(Vector2i(x, size_cells.y - 1), wall_src, BuildCfg.FOUNDATION_WALL_ATLAS, 0)                     
	for y in size_cells.y:
		walls.set_cell(Vector2i(0, y),                wall_src, BuildCfg.FOUNDATION_WALL_ATLAS, 0)
		walls.set_cell(Vector2i(size_cells.x - 1, y), wall_src, BuildCfg.FOUNDATION_WALL_ATLAS, 0)
