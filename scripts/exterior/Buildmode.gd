extends Node2D
## Build mód: výber nástroja z UI, ťahanie obdĺžnika a vytvorenie ConstructionSite.
## Foundation beží na GAME_HOURS; Extractor beží na GAME_MINUTES a snapne sa na tile ResourceNode.

enum Tool { NONE, EXTERIOR_COMPLEX, EXTERIOR_EXTRACTOR }

const PlacementServiceScript: GDScript = preload("res://scripts/services/placement_service.gd")
const GhostServiceScript: GDScript = preload("res://scripts/services/ghost_service.gd")

const FOUNDATION_COST_PER_TILE_BM: float = 5.0
const EXTRACTOR_COST_BM: float = 100.0
const EXTRACTOR_COST_EQ: float = 20.0
const EXTRACTOR_BUILD_MINUTES: int = 3 * 60            # 3 herné hodiny (v minútach)
const CS_TIME_MODE_GAME_MINUTES := 1                   # ConstructionSite.BuildTimeMode.GAME_MINUTES_FIXED
const SNAP_RADIUS_PX: float = 96.0                     # dosah pre snap na ResourceNode

@export var terrain_grid: TileMapLayer
@export var buildings_root: NodePath = NodePath("../Buildings")
@export var construction_root: NodePath = NodePath("../Construction")

@export var building_scene: PackedScene
@export var inside_build_scene: PackedScene
@export var construction_site_scene: PackedScene
@export var extractor_scene: PackedScene               # BMExtractor.tscn

@export var cell_px: int = 128
@export var ghost_scale: float = 0.5   # rezerva, zatiaľ nepoužité

var current_tool: Tool = Tool.NONE
var dragging: bool = false
var drag_a: Vector2i = Vector2i.ZERO
var drag_b: Vector2i = Vector2i.ZERO
var hover_cell: Vector2i = Vector2i.ZERO

const TM_REALTIME      := 0
const TM_GAME_MINUTES  := 1
const TM_GAME_HOURS    := 2

func _ready() -> void:
	set_process_unhandled_input(true)
	queue_redraw()
	z_index = 1000

	# --- AUTOWIRE terrain_grid ---
	if terrain_grid == null:
		var terrain: Node = get_node_or_null("../Terrain")
		if terrain != null:
			var candidate: TileMapLayer = null
			for ch in terrain.get_children():
				if ch is TileMapLayer:
					candidate = ch
					if ch.name.to_lower().contains("ground"):
						candidate = ch
						break
			if candidate != null:
				terrain_grid = candidate
				print("[BuildMode] Autowired terrain_grid -> ", candidate.name)
	if terrain_grid == null:
		push_error("[BuildMode] terrain_grid is NULL – priraď v Inspectore (Terrain/Main_Ground).")

	# --- UI signál (BuildUI/BtnBuild fallback) ---
	var ui: Node = get_node_or_null("../UI/BuildUI")
	if ui != null:
		if ui.has_signal("tool_requested"):
			ui.tool_requested.connect(on_ui_tool_requested)
			print("[BuildMode] UI signal connected")
		else:
			var btn: Button = ui.find_child("BtnBuild", true, false) as Button
			if btn != null:
				btn.pressed.connect(func(): on_ui_tool_requested(0))
				print("[BuildMode] Fallback: BtnBuild connected")
	else:
		push_warning("[BuildMode] UI/BuildUI not found")

## Reakcia na kliky v spodnej lište – Build=0
func on_ui_tool_requested(tool_id: int) -> void:
	dragging = false

	match tool_id:
		0:
			# Build → foundation (ťahanie obdĺžnika)
			current_tool = Tool.EXTERIOR_COMPLEX
			if terrain_grid != null:
				hover_cell = _mouse_cell()
			print("[BuildMode] Tool=FOUNDATION; hover=", hover_cell, " tg=", terrain_grid)

		2:
			# Utilities → Extractor tool (stavba na resource node)
			current_tool = Tool.EXTERIOR_EXTRACTOR
			if terrain_grid != null:
				hover_cell = _mouse_cell()
			print("[BuildMode] Tool=EXTRACTOR; hover=", hover_cell, " tg=", terrain_grid)

		_:
			current_tool = Tool.NONE
			print("[BuildMode] Tool=NONE")

	queue_redraw()


## Vstupy myši: začiatok/koniec ťahania a klik pre extractor.
func _unhandled_input(e: InputEvent) -> void:
	# ESC → zrušiť drag a tool
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_ESCAPE:
		dragging = false
		current_tool = Tool.NONE
		queue_redraw()
		return

	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			if terrain_grid == null:
				return

			if current_tool == Tool.EXTERIOR_COMPLEX:
				# Začiatok ťahania obdĺžnika pre foundation
				dragging = true
				drag_a = _mouse_cell()
				drag_b = drag_a
				print("[BuildMode] Drag start @", drag_a)
				queue_redraw()

			elif current_tool == Tool.EXTERIOR_EXTRACTOR:
				# Extractor: snap na najbližší voľný ResourceNode v dosahu
				var near: ResourceNode = _find_nearest_free_node(get_global_mouse_position(), SNAP_RADIUS_PX)
				if near != null:
					_start_extractor_at_node(near)
				else:
					print("[BuildMode] No ResourceNode near cursor – extractor must be placed on a node.")
		else:
			# Uvoľnenie LMB
			if dragging and current_tool == Tool.EXTERIOR_COMPLEX:
				print("[BuildMode] Drag end   @", drag_b)
				_submit_construction(drag_a, drag_b)
			dragging = false
			queue_redraw()

	elif e is InputEventMouseMotion:
		if terrain_grid == null:
			return

		if current_tool == Tool.EXTERIOR_COMPLEX or current_tool == Tool.EXTERIOR_EXTRACTOR:
			var c: Vector2i = _mouse_cell()
			if c != hover_cell:
				hover_cell = c
				if dragging and current_tool == Tool.EXTERIOR_COMPLEX:
					drag_b = c
				queue_redraw()


## Vytvorí a nakonfiguruje ConstructionSite podľa ťahaného obdĺžnika (FOUNDATION).
func _submit_construction(a: Vector2i, b: Vector2i) -> void:
	var minx: int = mini(a.x, b.x)
	var miny: int = mini(a.y, b.y)
	var maxx: int = maxi(a.x, b.x)
	var maxy: int = maxi(a.y, b.y)
	var size: Vector2i = Vector2i(maxx - minx + 1, maxy - miny + 1)

	# Minimálny rozmer – aspoň 2x2 tiles
	if size.x < 2 or size.y < 2:
		print("[BuildMode] Ignored: size too small =", size)
		return

	# --- VALIDÁCIA PLACEMENTU cez PlacementService ---------------------------
	var building_id: String = "foundation_basic"

	# rect_drag footprint – použijeme pôvodné a,b (funkcia už rieši min/max)
	var footprint: Array[Vector2i] = PlacementServiceScript.get_footprint(
		building_id,
		a,
		b
	)

	var ctx: Dictionary = {}
	ctx["occupied_cells"] = _compute_occupied_cells()
	ctx["resource_cells"] = []  # foundation nepotrebuje resource node

	var validation: Dictionary = PlacementServiceScript.validate_placement(
		building_id,
		footprint,
		ctx
	)

	var ghost_info: Dictionary = GhostServiceScript.build_ghost_info(
		building_id,
		footprint,
		validation
	)

	if not bool(ghost_info.get("is_valid", true)):
		print("[BuildMode] Invalid placement for %s: %s" % [
			building_id,
			ghost_info.get("errors", [])
		])
		return  # STOP – foundation sa nepostaví
	# -------------------------------------------------------------------------

	# --- RESOURCE COST: Foundation žerie Building Materials -------------------
	var tile_count: int = size.x * size.y
	var total_cost_bm: float = float(tile_count) * FOUNDATION_COST_PER_TILE_BM
	var cost := { &"building_materials": total_cost_bm }

	if not State.try_spend(cost):
		var have_bm: float = State.get_resource(&"building_materials")
		print("[BuildMode] Not enough Building Materials for foundation. Need=",
			total_cost_bm, " have=", have_bm, " tiles=", tile_count, " size=", size)
		return
	# -------------------------------------------------------------------------

	if construction_site_scene == null or building_scene == null or inside_build_scene == null:
		push_error("[BuildMode] Missing scenes: site or building or inside is null")
		return
	if terrain_grid == null:
		push_error("[BuildMode] terrain_grid is null")
		return

	var construction_root_node: Node = get_node_or_null(construction_root)
	if construction_root_node == null:
		push_error("[BuildMode] construction_root not found")
		return

	# 1) Inštancia ConstructionSite mimo stromu
	var site: Node2D = construction_site_scene.instantiate() as Node2D
	site.name = "ConstructionSite_%d_%d" % [minx, miny]

	# 2) Nastaviť exporty ešte mimo stromu
	site.set("terrain_grid", terrain_grid)
	site.set("top_left_cell", Vector2i(minx, miny))
	site.set("size_cells", size)
	site.set("cell_px", cell_px)
	site.set("building_scene", building_scene)
	site.set("inside_build_scene", inside_build_scene)
	site.set("buildings_root_path", buildings_root)
	site.set("z_index", 500)

	# --- beh na HODINÁCH (pauza/rýchlosť ovláda GameClock) ---
	# ConstructionSite.BuildTimeMode.GAME_HOURS_FIXED = 2
	site.set("time_mode", 2)

	var hours := int(ceil(float(tile_count) * BuildCfg.FOUNDATION_HOURS_PER_TILE))
	site.set("build_game_hours", max(1, hours))

	# foundation po dokončení vytvorí interiér
	site.set("use_interior", true)

	# 3) Až teraz pridať do stromu
	construction_root_node.add_child(site)

	# Debug
	var scr: Script = site.get_script()
	print("[BuildMode] Site added @", site.get_path(), " script=", scr)
	print("[BuildMode] Site exports -> tl=", site.get("top_left_cell"),
		" size=", site.get("size_cells"),
		" tg_is_null=", site.get("terrain_grid") == null)

	site.add_to_group("construction_sites")

	print("[BuildMode] ConstructionSite created @", Vector2i(minx, miny),
		" size=", size, " tiles=", tile_count, " cost_BM=", total_cost_bm)


# --- EXTRACTOR: spustenie stavby priamo na ResourceNode (snap center) --------
func _start_extractor_at_node(node_at_center: ResourceNode) -> void:
	if extractor_scene == null:
		push_error("[BuildMode] extractor_scene is null – priraď BMExtractor.tscn v Inspectore.")
		return
	if construction_site_scene == null:
		push_error("[BuildMode] construction_site_scene is null – priraď ConstructionSite.tscn v Inspectore.")
		return
	if terrain_grid == null:
		push_error("[BuildMode] terrain_grid is null v _start_extractor_at_node()")
		return
	if node_at_center == null:
		return
	if node_at_center.has_extractor:
		print("[BuildMode] Node ", node_at_center.name, " už má extractor (alebo rozostavaný).")
		return

	# --- 1) Vypočítaj footprint podľa BuildingsCfg + pozície node ----------------
	var building_id := "bm_extractor"
	var cfg := BuildingsCfg.get_building(building_id)
	if cfg.is_empty():
		push_error("[BuildMode] Missing cfg for bm_extractor v BuildingsCfg")
		return

	var footprint_size: Vector2i = cfg.get("size_cells", Vector2i.ONE)

	# stred grid tile pod node
	var snap_center: Vector2 = _grid_center_from_world(node_at_center.global_position)
	var top_left_cell: Vector2i = _top_left_cell_for_center(snap_center, footprint_size)

	# pre validity-check potrebujeme zoznam všetkých buniek footprintu
	var footprint: Array[Vector2i] = []
	for y in footprint_size.y:
		for x in footprint_size.x:
			footprint.append(Vector2i(top_left_cell.x + x, top_left_cell.y + y))

	# --- 2) Validácia cez PlacementService --------------------------------------
	var ctx: Dictionary = {}
	ctx["occupied_cells"] = _compute_occupied_cells()   # všetky hotové budovy + ConstructionSite
	ctx["resource_cells"] = _compute_resource_cells()   # pozície resource nodov

	var validation: Dictionary = PlacementService.validate_placement(
		building_id,
		footprint,
		ctx
	)

	var ghost_info: Dictionary = GhostService.build_ghost_info(
		building_id,
		footprint,
		validation
	)

	if not bool(ghost_info.get("is_valid", false)):
		print("[BuildMode] Invalid placement for %s: %s" % [
			building_id,
			ghost_info.get("errors", [])
		])
		return  # STOP – ani neskúšaj stavať, ani nestrhávaj resource

	# --- 3) Resource cost až po úspešnej validácii ------------------------------
	var cost: Dictionary = {
		&"building_materials": EXTRACTOR_COST_BM,
		&"equipment": EXTRACTOR_COST_EQ,
	}
	if not State.try_spend(cost):
		var have_bm: float = State.get_resource(&"building_materials")
		var have_eq: float = State.get_resource(&"equipment")
		print("[BuildMode] Not enough resources for extractor. Need BM=",
			EXTRACTOR_COST_BM, " EQ=", EXTRACTOR_COST_EQ,
			" have BM=", have_bm, " EQ=", have_eq)
		return

	# --- 4) ConstructionSite vytvárame až teraz --------------------------------
	var construction_root_node: Node = get_node_or_null(construction_root)
	if construction_root_node == null:
		push_error("[BuildMode] construction_root not found for extractor")
		return

	var site: Node2D = construction_site_scene.instantiate() as Node2D
	site.name = "ExtractorSite_%d_%d" % [top_left_cell.x, top_left_cell.y]

	site.set("terrain_grid", terrain_grid)
	site.set("top_left_cell", top_left_cell)
	site.set("size_cells", footprint_size)
	site.set("cell_px", cell_px)
	site.set("building_scene", extractor_scene)
	site.set("buildings_root_path", buildings_root)
	site.set("z_index", 500)

	# 3 herné hodiny (v minútach) podľa GameClock
	site.set("time_mode", CS_TIME_MODE_GAME_MINUTES)
	site.set("build_game_minutes", EXTRACTOR_BUILD_MINUTES)
	site.set("use_interior", false)

	# Finálna budova presne na snap center
	site.set("use_center_override", true)
	site.set("spawn_center_override_world", snap_center)

	construction_root_node.add_child(site)

	# Označ node, že je obsadený
	node_at_center.has_extractor = true

	print("[BuildMode] Extractor construction started @", top_left_cell,
		" size=", footprint_size, " (snap center) node=", node_at_center.node_id)


# --- Helpery výpočtu veľkostí a pozícií --------------------------------------

func _tile_px() -> Vector2:
	if terrain_grid == null:
		return Vector2(float(cell_px), float(cell_px))

	var p0_local: Vector2 = terrain_grid.map_to_local(Vector2i(0, 0))
	var p1_local: Vector2 = terrain_grid.map_to_local(Vector2i(1, 0))
	var p2_local: Vector2 = terrain_grid.map_to_local(Vector2i(0, 1))

	var p0_world: Vector2 = terrain_grid.to_global(p0_local)
	var p1_world: Vector2 = terrain_grid.to_global(p1_local)
	var p2_world: Vector2 = terrain_grid.to_global(p2_local)

	var w: float = abs(p1_world.x - p0_world.x)
	var h: float = abs(p2_world.y - p0_world.y)

	if w <= 0.0:
		w = float(BuildCfg.CELL_PX)
	if h <= 0.0:
		h = float(BuildCfg.CELL_PX)

	return Vector2(w, h)

func _cell_corners_world(cell: Vector2i) -> Dictionary:
	var half := _tile_px() * 0.5
	var center_local: Vector2 = terrain_grid.map_to_local(cell)
	var center_world: Vector2 = terrain_grid.to_global(center_local)
	return { "tl": center_world - half, "br": center_world + half }

func _cell_to_world_center(cell: Vector2i) -> Vector2:
	var p_local: Vector2 = terrain_grid.map_to_local(cell)
	return terrain_grid.to_global(p_local)

func _grid_center_from_world(world_pos: Vector2) -> Vector2:
	var local_tm: Vector2 = terrain_grid.to_local(world_pos)
	var cell: Vector2i = terrain_grid.local_to_map(local_tm)
	var cell_local_center: Vector2 = terrain_grid.map_to_local(cell)
	return terrain_grid.to_global(cell_local_center)

func _top_left_cell_for_center(center_world: Vector2, footprint_cells: Vector2i) -> Vector2i:
	var t: Vector2 = _tile_px()
	var foot_px: Vector2 = Vector2(footprint_cells.x * t.x, footprint_cells.y * t.y)
	var top_left_world: Vector2 = center_world - foot_px * 0.5
	var tl_local_tm: Vector2 = terrain_grid.to_local(top_left_world)
	return terrain_grid.local_to_map(tl_local_tm)

func _extractor_footprint_cells() -> Vector2i:
	var t: Vector2 = _tile_px()
	var gx: float = BuildCfg.EXTRACTOR_GHOST_PX.x
	var gy: float = BuildCfg.EXTRACTOR_GHOST_PX.y
	var cx: int = int(ceil(gx / max(1.0, t.x)))
	var cy: int = int(ceil(gy / max(1.0, t.y)))
	if cx < 1:
		cx = 1
	if cy < 1:
		cy = 1
	return Vector2i(cx, cy)

func _find_nearest_free_node(world_pos: Vector2, max_dist_px: float) -> ResourceNode:
	var best: ResourceNode = null
	var best_d2: float = max_dist_px * max_dist_px
	for n in get_tree().get_nodes_in_group("resource_nodes"):
		if n is ResourceNode and not (n as ResourceNode).has_extractor:
			var d2 := world_pos.distance_squared_to((n as ResourceNode).global_position)
			if d2 <= best_d2:
				best_d2 = d2
				best = n
	return best


## Kreslí ghost:
## - FOUNDATION: 1 tile pod kurzorom + ťahaný obdĺžnik s prstencom
## - EXTRACTOR: modré snap hinty na voľných nodoch + pod kurzorom červený/zelený ghost (200×200 px)
func _draw() -> void:
	if terrain_grid == null:
		return

	if current_tool == Tool.EXTERIOR_COMPLEX:
		var hc: Dictionary = _cell_corners_world(hover_cell)
		var tl_tile_world: Vector2 = hc["tl"]
		var br_tile_world: Vector2 = hc["br"]
		var tl_tile_local: Vector2 = to_local(tl_tile_world)
		var br_tile_local: Vector2 = to_local(br_tile_world)
		var tile_rect: Rect2 = Rect2(tl_tile_local, br_tile_local - tl_tile_local)
		draw_rect(tile_rect, BuildCfg.GHOST_TILE, true)
		draw_rect(tile_rect, BuildCfg.GHOST_TILE_STROKE, false, 1.5)

		if dragging:
			var minx: int = mini(drag_a.x, drag_b.x)
			var miny: int = mini(drag_a.y, drag_b.y)
			var maxx: int = maxi(drag_a.x, drag_b.x)
			var maxy: int = maxi(drag_a.y, drag_b.y)

			var hc_tl: Dictionary = _cell_corners_world(Vector2i(minx, miny))
			var hc_br: Dictionary = _cell_corners_world(Vector2i(maxx, maxy))
			var tl_world: Vector2 = hc_tl["tl"]
			var br_world: Vector2 = hc_br["br"]

			var tl_local: Vector2 = to_local(tl_world)
			var br_local: Vector2 = to_local(br_world)
			var rect: Rect2 = Rect2(tl_local, br_local - tl_local)

			draw_rect(rect, BuildCfg.GHOST_FILL, true)

			var tsize: Vector2 = _tile_px()
			var tpx: float = float(BuildCfg.FOUNDATION_WALL_THICKNESS) * tsize.x
			var tpy: float = float(BuildCfg.FOUNDATION_WALL_THICKNESS) * tsize.y

			draw_rect(Rect2(rect.position, Vector2(rect.size.x, tpy)), BuildCfg.GHOST_STROKE, true)
			draw_rect(Rect2(rect.position, Vector2(tpx, rect.size.y)), BuildCfg.GHOST_STROKE, true)
			draw_rect(Rect2(Vector2(rect.position.x, rect.end.y - tpy), Vector2(rect.size.x, tpy)), BuildCfg.GHOST_STROKE, true)
			draw_rect(Rect2(Vector2(rect.end.x - tpx, rect.position.y), Vector2(tpx, rect.size.y)), BuildCfg.GHOST_STROKE, true)

	elif current_tool == Tool.EXTERIOR_EXTRACTOR:
		var ghost_px: Vector2 = BuildCfg.EXTRACTOR_GHOST_PX

		for n in get_tree().get_nodes_in_group("resource_nodes"):
			if n is ResourceNode and not (n as ResourceNode).has_extractor:
				var c_world: Vector2 = _grid_center_from_world((n as ResourceNode).global_position)
				var tlw: Vector2 = c_world - ghost_px * 0.5
				var rect_hint: Rect2 = Rect2(to_local(tlw), ghost_px)
				draw_rect(rect_hint, BuildCfg.GHOST_HINT_FILL, true)
				draw_rect(rect_hint, BuildCfg.GHOST_HINT_STROKE, false, 1.3)

		var near: ResourceNode = _find_nearest_free_node(get_global_mouse_position(), SNAP_RADIUS_PX)
		if near != null:
			var snap_c: Vector2 = _grid_center_from_world(near.global_position)
			var tlw_ok: Vector2 = snap_c - ghost_px * 0.5
			var rect_ok: Rect2 = Rect2(to_local(tlw_ok), ghost_px)
			draw_rect(rect_ok, Color(0.1, 0.9, 0.3, 0.15), true)
			draw_rect(rect_ok, Color(0.1, 1.0, 0.1, 0.95), false, 1.5)
		else:
			var mouse_c: Vector2 = _grid_center_from_world(get_global_mouse_position())
			var tlw_bad: Vector2 = mouse_c - ghost_px * 0.5
			var rect_bad: Rect2 = Rect2(to_local(tlw_bad), ghost_px)
			draw_rect(rect_bad, Color(1, 0, 0, 0.12), true)
			draw_rect(rect_bad, Color(1, 0, 0, 0.9), false, 1.5)


# --- Pomocníci vstupu --------------------------------------------------------

func _mouse_cell() -> Vector2i:
	if terrain_grid == null:
		push_error("[BuildMode] terrain_grid is null in _mouse_cell()")
		return hover_cell
	var mouse_world: Vector2 = get_global_mouse_position()
	var mouse_local_tm: Vector2 = terrain_grid.to_local(mouse_world)
	return terrain_grid.local_to_map(mouse_local_tm)

func _compute_occupied_cells() -> Dictionary:
	var occupied: Dictionary = {}

	var nodes: Array = get_tree().get_nodes_in_group("buildings")
	for node in nodes:
		if node.has_method("get_occupied_cells"):
			var cells_any: Array = node.get_occupied_cells()
			for c_any in cells_any:
				var cell: Vector2i = c_any as Vector2i
				occupied[cell] = true

	return occupied

func _compute_resource_cells() -> Array[Vector2i]:
	var res: Array[Vector2i] = []
	if terrain_grid == null:
		return res

	for n in get_tree().get_nodes_in_group("resource_nodes"):
		if n is ResourceNode:
			var rn := n as ResourceNode
			var local_tm: Vector2 = terrain_grid.to_local(rn.global_position)
			var cell: Vector2i = terrain_grid.local_to_map(local_tm)
			res.append(cell)
	return res
