extends Node2D
## Building
## - Generická exteriérová budova.
## - Po spawne (z ConstructionSite) sa pridá do skupiny "buildings".
## - Môže mať interiér (Inside_Build), ktorý si cez metódu setup(size_cells)
##   pripraví podlahy a steny, alebo fallback tilemapový režim.
##
## Kľúčové vlastnosti:
## - size_cells: footprint v grid tiles (šírka, výška)
## - top_left_cell: grid pozícia ľavého-horného tile
## - terrain_grid: TileMapLayer povrchu (pre interiér / navigáciu, voliteľné)

@export var size_cells: Vector2i = Vector2i(4, 3)   ## nastavené ConstructionSite pri spawne
@export var interior_scene: PackedScene = null      ## Inside_Build.tscn (môže byť null)
@export var cell_px: int = 128                      ## veľkosť tiles, držíme v súlade s BuildCfg

@export var terrain_grid: TileMapLayer = null
@export var top_left_cell: Vector2i = Vector2i.ZERO

var interior: Node2D = null                         ## instancovaný interiér (ak existuje)


func set_interior_scene(p: PackedScene) -> void:
	## Umožní ConstructionSite doplniť interiérovú scénu ešte pred _ready().
	interior_scene = p


func _ready() -> void:
	## Po spawne:
	## - pridaj do skupiny "buildings"
	## - zosúľaď cell_px s BuildCfg
	## - spawnni interiér, ak je definovaný
	add_to_group("buildings")

	if cell_px != BuildCfg.CELL_PX:
		cell_px = BuildCfg.CELL_PX

	print("[Building] _ready size=", size_cells,
		" interior_scene is null? ", interior_scene == null)

	_spawn_interior()


func _spawn_interior() -> void:
	## Vytvorí interiér (Inside_Build):
	## 1) Ak interior_scene = null → nič nebudujeme.
	## 2) Ak interiér má metódu setup(size_cells) → delegujeme na ňu.
	## 3) Inak fallback: nájdeme Floors/Walls TileMapLayer a vygenerujeme
	##    podlahu + obvodové múry.
	if interior_scene == null:
		return

	interior = interior_scene.instantiate() as Node2D
	if interior == null:
		push_warning("[Building] failed to instantiate interior_scene")
		return

	add_child(interior)
	interior.position = Vector2.ZERO

	# Preferovaný spôsob – Inside_Build.gd má setup(size_cells)
	if interior.has_method("setup"):
		interior.call("setup", size_cells)
		return

	# Fallback – priamo ručne položíme tiles do Floors / Walls
	var floors := interior.find_child("Floors", true, false) as TileMapLayer
	var walls  := interior.find_child("Walls",  true, false) as TileMapLayer
	if floors == null or walls == null:
		push_warning("[Building] Fallback: Floors alebo Walls chýbajú v Inside_Build.")
		return

	var floor_src := floors.tile_set.get_source_id(0)
	var wall_src  := walls.tile_set.get_source_id(0)

	# Floor fill
	for y: int in size_cells.y:
		for x: int in size_cells.x:
			floors.set_cell(Vector2i(x, y), floor_src, BuildCfg.FOUNDATION_FLOOR_ATLAS, 0)

	# Perimeter walls (1 tile hrúbka interiéru)
	for x: int in size_cells.x:
		walls.set_cell(Vector2i(x, 0),                wall_src, BuildCfg.FOUNDATION_WALL_ATLAS, 0)
		walls.set_cell(Vector2i(x, size_cells.y - 1), wall_src, BuildCfg.FOUNDATION_WALL_ATLAS, 0)
	for y: int in size_cells.y:
		walls.set_cell(Vector2i(0, y),                wall_src, BuildCfg.FOUNDATION_WALL_ATLAS, 0)
		walls.set_cell(Vector2i(size_cells.x - 1, y), wall_src, BuildCfg.FOUNDATION_WALL_ATLAS, 0)


func get_occupied_cells() -> Array[Vector2i]:
	## Kontrakt pre PlacementService: vráť grid bunky, ktoré budova obsadzuje.
	var cells: Array[Vector2i] = []
	var tl: Vector2i = top_left_cell

	for y: int in size_cells.y:
		for x: int in size_cells.x:
			cells.append(Vector2i(tl.x + x, tl.y + y))

	return cells
