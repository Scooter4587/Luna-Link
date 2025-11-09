# res://scripts/build/ConstructionSite.gd
extends Node2D
# Plán stavby: kreslí výrazný ghost, odpočítava čas a po dokončení spawnne Building.

@export var terrain_grid: TileMapLayer
@export var top_left_cell: Vector2i = Vector2i.ZERO
@export var size_cells: Vector2i = Vector2i(4, 3)
@export var cell_px: int = 128

@export var building_scene: PackedScene
@export var inside_build_scene: PackedScene
@export var buildings_root_path: NodePath = NodePath("../Buildings")

# Produkčné časovanie
@export var sec_per_tile: float = 0.50      # 0.5 s / tile
@export var max_build_time: float = 30.0     # cap (s); 0 alebo <0 = bez capu
@export var min_build_time: float = 1.0      # minimálne trvanie (s)

# DEV režim (krátky test)
@export var dev_mode: bool = true            # pri teste nechaj true
@export var dev_total_time: float = 10.0     # fixných ~10 s na stavbu

var build_time_total: float = 1.0
var build_time_left: float = 1.0
var started: bool = false

# -- Nastaví trvanie (dev: fix 10 s; prod: podľa veľkosti) a spustí odpočet.
func _ready() -> void:
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

# -- Tick: odpočítava čas, drží ghost na obrazovke.
func _process(dt: float) -> void:
	if not started:
		return
	build_time_left -= dt
	if build_time_left <= 0.0:
		_finalize_build()
		return
	queue_redraw()

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

	# --- INŠTANCIA MIMO STROMU + NASTAVIŤ PROPERTIES PRED add_child() ---
	var bld_raw: Node = building_scene.instantiate()
	bld_raw.set("size_cells", size_cells)
	bld_raw.set("interior_scene", inside_build_scene)

	var bld2d: Node2D = bld_raw as Node2D
	if bld2d != null:
		bld2d.z_index = 200
		# umiestnenie: ľavý-horný roh výberu
		var tl_world_center: Vector2 = terrain_grid.to_global(terrain_grid.map_to_local(top_left_cell))
		var top_left_world: Vector2 = tl_world_center - Vector2(float(cell_px), float(cell_px)) * 0.5
		if root is Node2D:
			var pos_in_root: Vector2 = (root as Node2D).to_local(top_left_world)
			bld2d.position = pos_in_root

	# až teraz vložiť do stromu → _ready uvidí nastavené exporty
	root.add_child(bld_raw)

	print("[ConstructionSite] DONE → Building spawned @", top_left_cell, " size=", size_cells,
		" into=", root.get_path())
	queue_free()

# -- Kreslí výrazný ghost (cyan) + % a ETA; ostáva viditeľný počas celej stavby.
func _draw() -> void:
	# varovanie keď nie je grid (aj vizuálne)
	if terrain_grid == null:
		var warn_rect: Rect2 = Rect2(Vector2(-32, -32), Vector2(64, 64))
		draw_rect(warn_rect, Color(1,0,0,0.6), true)
		draw_rect(warn_rect, Color(1,1,1,1.0), false, 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(-30, -40), "NO GRID",
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(1,1,1,1))
		return

	# prepočet rohov do lokálnych súradníc ConstructionSite
	var tl_c: Vector2i = top_left_cell
	var br_c: Vector2i = top_left_cell + size_cells - Vector2i(1, 1)

	var tl_world: Vector2 = terrain_grid.to_global(terrain_grid.map_to_local(tl_c)) - Vector2(float(cell_px), float(cell_px)) * 0.5
	var br_world: Vector2 = terrain_grid.to_global(terrain_grid.map_to_local(br_c)) + Vector2(float(cell_px), float(cell_px)) * 0.5

	var tl_local: Vector2 = to_local(tl_world)
	var br_local: Vector2 = to_local(br_world)
	var build_rect: Rect2 = Rect2(tl_local, br_local - tl_local)

	# progres 0..1 + texty
	var p: float = 1.0 - clamp(build_time_left / max(0.0001, build_time_total), 0.0, 1.0)
	var eta: float = max(0.0, build_time_left)

	# výrazný overlay (cyan) + hrubý biely okraj
	draw_rect(build_rect, Color(0.2, 0.8, 1.0, 0.35), true)
	draw_rect(build_rect, Color(1, 1, 1, 1.0), false, 3.0)

	# percentá + ETA (1 desatinné miesto, typy explicitne)
	var font: Font = ThemeDB.fallback_font
	var percent: int = int(round(p * 100.0))
	var eta_1dec: float = round(eta * 10.0) / 10.0
	var label: String = str(percent) + "%  (" + str(eta_1dec) + "s)"
	draw_string(font, tl_local + Vector2(10, 28), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color(1,1,1,1))
