extends Node2D
## Plán stavby: kreslí výrazný ghost, odpočítava čas a po dokončení spawnne Building.

@export var terrain_grid: TileMapLayer
@export var top_left_cell: Vector2i = Vector2i.ZERO
@export var size_cells: Vector2i = Vector2i(4, 3)
@export var cell_px: int = 128

@export var building_scene: PackedScene
@export var inside_build_scene: PackedScene
@export var buildings_root_path: NodePath = NodePath("../Buildings")

@export var sec_per_tile: float = 0.50
@export var max_build_time: float = 30.0
@export var min_build_time: float = 1.0

@export var dev_mode: bool = true
@export var dev_total_time: float = 10.0

var build_time_total: float = 1.0
var build_time_left: float = 1.0
var started: bool = false

## -- Nastaví trvanie (dev alebo podľa veľkosti) a spustí odpočet.
func _ready() -> void:
	# drž konzistenciu s BuildCfg
	if cell_px != BuildCfg.CELL_PX:
		cell_px = BuildCfg.CELL_PX

	var tiles_count: int = size_cells.x * size_cells.y
	if dev_mode:
		build_time_total = max(dev_total_time, 0.1)
	else:
		var proposed: float = float(tiles_count) * sec_per_tile
		if max_build_time > 0.0:
			build_time_total = clamp(proposed, min_build_time, max_build_time)
		else:
			build_time_total = max(proposed, min_build_time)

	build_time_left = build_time_total
	z_index = 500
	set_process(true)
	started = true
	queue_redraw()
	print("[ConstructionSite] ready tl=", top_left_cell, " size=", size_cells,
		" total=", build_time_total, "s  tg_is_null=", terrain_grid == null)

## -- Tick: odpočítava čas, drží ghost na obrazovke.
func _process(dt: float) -> void:
	if not started:
		return
	build_time_left -= dt
	if build_time_left <= 0.0:
		_finalize_build()
		return
	queue_redraw()

## -- Dokončí stavbu a spawnne Building presne do ľavého-horného rohu výberu.
func _finalize_build() -> void:
	started = false
	set_process(false)

	# nájdi cieľový root (Buildings) – vrátane fallbackov
	var root: Node = get_node_or_null(buildings_root_path)
	if root == null:
		var world: Node = get_tree().get_current_scene()
		if world != null:
			root = world.get_node_or_null("Buildings")
	if root == null:
		var any: Node = get_tree().get_root().find_child("Buildings", true, false)
		if any != null:
			root = any

	# validácia referencií
	if root == null or building_scene == null or inside_build_scene == null or terrain_grid == null:
		push_error("[ConstructionSite] finalize aborted (missing refs) "
			+ "path=" + str(buildings_root_path)
			+ " root=" + str(root)
			+ " bld=" + str(building_scene)
			+ " inside=" + str(inside_build_scene)
			+ " tg=" + str(terrain_grid))
		queue_free()
		return

	# Inštancia mimo stromu + properties pred add_child()
	var bld_raw: Node = building_scene.instantiate()
	bld_raw.set("size_cells", size_cells)
	bld_raw.set("interior_scene", inside_build_scene)
	bld_raw.set("cell_px", BuildCfg.CELL_PX)

	var bld2d: Node2D = bld_raw as Node2D
	if bld2d != null:
		bld2d.z_index = 200

		# TOP-LEFT roh natiahnutého výberu v WORLD súradniciach
		var tl_world: Vector2 = _cell_corners_world(top_left_cell)["tl"]

		# Pozícia v lokálnych súradniciach rootu (ak je Node2D), inak globálne
		if root is Node2D:
			bld2d.position = (root as Node2D).to_local(tl_world)
		else:
			bld2d.global_position = tl_world

	# až teraz vložiť do stromu
	root.add_child(bld_raw)

	print("[ConstructionSite] DONE → Building spawned @", top_left_cell, " size=", size_cells,
		" into=", root.get_path())
	queue_free()

## -- Kreslí výrazný ghost (cyan) + % a ETA; ostáva viditeľný počas celej stavby.
func _draw() -> void:
	if terrain_grid == null:
		# vizuálne varovanie, ak chýba grid
		var warn_rect: Rect2 = Rect2(Vector2(-32, -32), Vector2(64, 64))
		draw_rect(warn_rect, Color(1,0,0,0.6), true)
		draw_rect(warn_rect, Color(1,1,1,1.0), false, 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(-30, -40), "NO GRID",
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(1,1,1,1))
		return

	# Inkluzívny výber: posledná bunka je top_left + size - (1,1)
	var tl_c: Vector2i = top_left_cell
	var br_c: Vector2i = top_left_cell + size_cells - Vector2i(1, 1)

	# Prepočet rohov na WORLD → lokálne súradnice ConstructionSite
	var tl_world: Vector2 = _cell_corners_world(tl_c)["tl"]
	var br_world: Vector2 = _cell_corners_world(br_c)["br"]
	var tl_local: Vector2 = to_local(tl_world)
	var br_local: Vector2 = to_local(br_world)
	var build_rect: Rect2 = Rect2(tl_local, br_local - tl_local)

	# Progres
	var p: float = 1.0 - clamp(build_time_left / max(0.0001, build_time_total), 0.0, 1.0)
	var eta: float = max(0.0, build_time_left)

	# Overlay
	draw_rect(build_rect, BuildCfg.GHOST_FILL, true)
	draw_rect(build_rect, BuildCfg.GHOST_STROKE, false, 3.0)

	# Percentá + ETA
	var font: Font = ThemeDB.fallback_font
	var percent: int = int(round(p * 100.0))
	var eta_1dec: float = round(eta * 10.0) / 10.0
	var label: String = str(percent) + "%  (" + str(eta_1dec) + "s)"
	draw_string(font, tl_local + Vector2(10, 28), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color(1,1,1,1))

## Reálny rozmer jednej dlaždice podľa TileSetu (fallback na BuildCfg.CELL_PX)
func _tile_px() -> Vector2:
	if terrain_grid != null and terrain_grid.tile_set != null:
		var sz: Vector2i = terrain_grid.tile_set.tile_size
		return Vector2(sz.x, sz.y)
	return Vector2(BuildCfg.CELL_PX, BuildCfg.CELL_PX)

## Rohy jednej bunky v WORLD súradniciach (počítané z jej stredu)
func _cell_corners_world(cell: Vector2i) -> Dictionary:
	var half := _tile_px() * 0.5
	var center_local: Vector2 = terrain_grid.map_to_local(cell)
	var center_world: Vector2 = terrain_grid.to_global(center_local)
	return { "tl": center_world - half, "br": center_world + half }
