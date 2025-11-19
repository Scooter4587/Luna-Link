extends Node2D
## Build mód: výber nástroja z UI, ťahanie obdĺžnika a vytvorenie ConstructionSite.
## Foundation/Extractor:
## - footprint + validáciu rieši PlacementService
## - cost + build_time čítame z BuildingsCfg
## - ConstructionSite spúšťame cez ConstructionServiceScript

enum Tool { NONE, EXTERIOR_COMPLEX, EXTERIOR_EXTRACTOR }

const SNAP_RADIUS_PX: float = 96.0                     # dosah pre snap na ResourceNode
const ConstructionServiceScript: GDScript = preload("res://scripts/services/construction_service.gd")

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

	var building_id: String = "foundation_basic"

	# --- VALIDÁCIA PLACEMENTU cez PlacementService ---------------------------
	# rect_drag footprint – použijeme pôvodné a,b (funkcia už rieši min/max)
	var footprint: Array[Vector2i] = PlacementService.get_footprint(
		building_id,
		a,
		b
	)

	var ctx: Dictionary = {}
	ctx["occupied_cells"] = _compute_occupied_cells()
	ctx["resource_cells"] = []  # foundation nepotrebuje resource node

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

	if not bool(ghost_info.get("is_valid", true)):
		print("[BuildMode] Invalid placement for %s: %s" % [
			building_id,
			ghost_info.get("errors", [])
		])
		return  # STOP – foundation sa nepostaví
	# -------------------------------------------------------------------------

	# --- RESOURCE COST: cez BuildingsCfg/ConstructionServiceScript ------------------
	var cost: Dictionary = ConstructionServiceScript.compute_cost(building_id, size)
	if not cost.is_empty():
		if not State.try_spend(cost):
			print("[BuildMode] Not enough resources for ", building_id, " required=", cost)
			for res_id in cost.keys():
				var need: float = float(cost[res_id])
				var have: float = State.get_resource(res_id)
				print("   - ", res_id, " need=", need, " have=", have)
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

	# --- ConstructionSite cez ConstructionServiceScript ----------------------------
	var site: Node2D = ConstructionServiceScript.spawn_site({
		"building_id": building_id,
		"site_scene": construction_site_scene,
		"construction_parent": construction_root_node,
		"terrain_grid": terrain_grid,
		"top_left_cell": Vector2i(minx, miny),
		"size_cells": size,
		"cell_px": cell_px,
		"buildings_root_path": buildings_root,
		"building_scene": building_scene,
		"inside_build_scene": inside_build_scene,
		"use_interior": true,
	})
	if site == null:
		return

	print("[BuildMode] ConstructionSite created @", Vector2i(minx, miny),
		" size=", size, " cost=", cost)


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

	# --- 1) Footprint + pozícia podľa BuildingsCfg ----------------------------
	var building_id := "bm_extractor"
	var cfg := BuildingsCfg.get_building(building_id)
	if cfg.is_empty():
		push_error("[BuildMode] Missing cfg for bm_extractor v BuildingsCfg")
		return

	var footprint_size: Vector2i = (cfg.get("size_cells", Vector2i.ONE) as Vector2i)

	# stred grid tile pod node
	var snap_center: Vector2 = _grid_center_from_world(node_at_center.global_position)
	var top_left_cell: Vector2i = _top_left_cell_for_center(snap_center, footprint_size)

	# pre validáciu potrebujeme zoznam všetkých buniek footprintu
	var footprint: Array[Vector2i] = []
	for y in footprint_size.y:
		for x in footprint_size.x:
			footprint.append(Vector2i(top_left_cell.x + x, top_left_cell.y + y))

	# --- 2) Validácia cez PlacementService ------------------------------------
	var ctx: Dictionary = {}
	ctx["occupied_cells"] = _compute_occupied_cells()   # hotové budovy + ConstructionSite
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
		return  # STOP
	# -------------------------------------------------------------------------

	# --- 3) Resource cost cez BuildingsCfg/ConstructionServiceScript ----------------
	var cost: Dictionary = ConstructionServiceScript.compute_cost(building_id, footprint_size)
	if not cost.is_empty():
		if not State.try_spend(cost):
			print("[BuildMode] Not enough resources for ", building_id, " required=", cost)
			for res_id in cost.keys():
				var need: float = float(cost[res_id])
				var have: float = State.get_resource(res_id)
				print("   - ", res_id, " need=", need, " have=", have)
			return
	# -------------------------------------------------------------------------

	# --- 4) ConstructionSite vytvárame cez ConstructionServiceScript ----------------
	var construction_root_node: Node = get_node_or_null(construction_root)
	if construction_root_node == null:
		push_error("[BuildMode] construction_root not found for extractor")
		return

	var site: Node2D = ConstructionServiceScript.spawn_site({
		"building_id": building_id,
		"site_scene": construction_site_scene,
		"construction_parent": construction_root_node,
		"terrain_grid": terrain_grid,
		"top_left_cell": top_left_cell,
		"size_cells": footprint_size,
		"cell_px": cell_px,
		"buildings_root_path": buildings_root,
		"building_scene": extractor_scene,
		"use_interior": false,
		"use_center_override": true,
		"spawn_center_override_world": snap_center,
		"visual_px_size": BuildCfg.EXTRACTOR_GHOST_PX,
		"linked_resource_node_path": node_at_center.get_path(),
	})
	if site == null:
		return

	# Označ node, že je obsadený (aby sme tam nestavali druhý extractor)
	node_at_center.has_extractor = true

	print("[BuildMode] Extractor construction started @", top_left_cell,
		" size=", footprint_size, " node=", node_at_center.node_id, " cost=", cost)


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

	# --- FOUNDATION TOOL (EXTERIOR_COMPLEX) ---
	if current_tool == Tool.EXTERIOR_COMPLEX:
		var ghost_data: Dictionary = _get_foundation_ghost_data()
		var footprint: Array = ghost_data.get("footprint", [])
		var ghost_info: Dictionary = ghost_data.get("ghost_info", {})
		var per_cell_state: Dictionary = ghost_info.get("per_cell_state", {})
		var _is_valid: bool = bool(ghost_info.get("is_valid", true))

		if footprint.is_empty():
			return

		# set buniek pre rýchle zisťovanie, či je tile na okraji
		var cells_dict: Dictionary = {}
		for cell_any in footprint:
			cells_dict[cell_any as Vector2i] = true

		# každý tile vo footprint-e vykreslíme zvlášť
		for cell_any in footprint:
			var cell: Vector2i = cell_any as Vector2i

			var hc: Dictionary = _cell_corners_world(cell)
			var tl_tile_world: Vector2 = hc["tl"]
			var br_tile_world: Vector2 = hc["br"]
			var tl_tile_local: Vector2 = to_local(tl_tile_world)
			var br_tile_local: Vector2 = to_local(br_tile_world)
			var rect: Rect2 = Rect2(tl_tile_local, br_tile_local - tl_tile_local)

			var state: int = int(per_cell_state.get(cell, 0))  # 0 = OK, 1 = blocked

			# výplň vnútorných tile-ov
			if state == 0:
				draw_rect(rect, BuildCfg.GHOST_FILL, true)
			else:
				draw_rect(rect, Color(1, 0.2, 0.2, 0.35), true)

			# tenká mriežka
			draw_rect(rect, BuildCfg.GHOST_TILE_STROKE, false, 1.5)

			# --- zistenie, či je tile na okraji footprintu (imitácia múru) ---
			var is_edge: bool = false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if not cells_dict.has(cell + d):
					is_edge = true
					break

			if is_edge:
				# hrubší obrys = „múr“ po obvode budovy
				draw_rect(rect, BuildCfg.GHOST_TILE_STROKE, false, 6.0)

	# --- EXTRACTOR TOOL (EXTERIOR_EXTRACTOR) ---
	elif current_tool == Tool.EXTERIOR_EXTRACTOR:
		if terrain_grid == null:
			return

		var data: Dictionary = _get_extractor_ghost_data()
		var footprint2: Array = data.get("footprint", [])
		var ghost_info2: Dictionary = data.get("ghost_info", {})
		var per_cell_state2: Dictionary = ghost_info2.get("per_cell_state", {})
		var has_snap_node: bool = bool(data.get("has_node", false))

		# Ak nemáme footprint, nakreslíme len malý červený ghost pod kurzorom
		if footprint2.is_empty():
			var ghost_px_fb: Vector2 = BuildCfg.EXTRACTOR_GHOST_PX
			var center_world_fb: Vector2 = _grid_center_from_world(get_global_mouse_position())
			var tl_world_fb: Vector2 = center_world_fb - ghost_px_fb * 0.5
			var rect_fallback: Rect2 = Rect2(to_local(tl_world_fb), ghost_px_fb)
			draw_rect(rect_fallback, Color(1, 0, 0, 0.12), true)
			draw_rect(rect_fallback, Color(1, 0, 0, 0.9), false, 1.5)
			return

		# Zistíme, či je aspoň jeden tile blokovaný
		var is_valid: bool = bool(ghost_info2.get("is_valid", true))
		for cell_any2 in footprint2:
			var cell2: Vector2i = cell_any2 as Vector2i
			var state_idx: int = int(per_cell_state2.get(cell2, 0))
			if state_idx != 0:
				is_valid = false
				break

		# Bounding box footprintu v grid coords
		var minx :=  999999
		var miny :=  999999
		var maxx := -999999
		var maxy := -999999
		for cell_any3 in footprint2:
			var c: Vector2i = cell_any3 as Vector2i
			if c.x < minx: minx = c.x
			if c.y < miny: miny = c.y
			if c.x > maxx: maxx = c.x
			if c.y > maxy: maxy = c.y

		var center_x: int = int(float(minx + maxx) * 0.5)
		var center_y: int = int(float(miny + maxy) * 0.5)
		var center_cell := Vector2i(center_x, center_y)
		var center_world: Vector2 = _cell_to_world_center(center_cell)

		# Veľký ghost podľa BuildCfg.EXTRACTOR_GHOST_PX
		var ghost_px: Vector2 = BuildCfg.EXTRACTOR_GHOST_PX
		var tl_world: Vector2 = center_world - ghost_px * 0.5
		var rect: Rect2 = Rect2(to_local(tl_world), ghost_px)

		if has_snap_node and is_valid:
			# zelený ghost (valid + snapnutý na node)
			draw_rect(rect, Color(0.1, 0.9, 0.3, 0.15), true)
			draw_rect(rect, Color(0.1, 1.0, 0.1, 0.95), false, 1.5)
		else:
			# červený ghost (buď mimo node, alebo blokovaný MinClearRadius / kolíziou)
			draw_rect(rect, Color(1, 0, 0, 0.12), true)
			draw_rect(rect, Color(1, 0, 0, 0.9), false, 1.5)


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
	var cells: Array[Vector2i] = []
	if terrain_grid == null:
		return cells

	for n in get_tree().get_nodes_in_group("resource_nodes"):
		if n is ResourceNode:
			var rn := n as ResourceNode
			var world_pos: Vector2 = rn.global_position
			var local_tm: Vector2 = terrain_grid.to_local(world_pos)
			var cell: Vector2i = terrain_grid.local_to_map(local_tm)
			cells.append(cell)
	return cells


func _get_foundation_ghost_data() -> Dictionary:
	var building_id := "foundation_basic"

	# určíme start/end podľa toho, či ťaháš rect, alebo len hooveruješ
	var start_cell: Vector2i
	var end_cell: Vector2i

	if dragging and current_tool == Tool.EXTERIOR_COMPLEX:
		start_cell = drag_a
		end_cell = drag_b
	else:
		start_cell = hover_cell
		end_cell = hover_cell

	var footprint: Array[Vector2i] = PlacementService.get_footprint(
		building_id,
		start_cell,
		end_cell
	)

	# kontext pre validáciu
	var ctx: Dictionary = {}
	ctx["occupied_cells"] = _compute_occupied_cells()
	ctx["resource_cells"] = []  # foundation nepotrebuje resource tiles

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

	return {
		"footprint": footprint,
		"ghost_info": ghost_info,
	}


func _get_extractor_ghost_data() -> Dictionary:
	var building_id := "bm_extractor"

	if terrain_grid == null:
		return {
			"footprint": [],
			"ghost_info": {},
			"has_node": false,
		}

	var cfg := BuildingsCfg.get_building(building_id)
	var size: Vector2i = (cfg.get("size_cells", Vector2i.ONE) as Vector2i)
	var local_pivot: Vector2i = (cfg.get("pivot_cell", Vector2i.ZERO) as Vector2i)

	# nájdi najbližší voľný ResourceNode – ten určí snap pozíciu
	var near: ResourceNode = _find_nearest_free_node(get_global_mouse_position(), SNAP_RADIUS_PX)

	var pivot_cell: Vector2i
	if near != null:
		# center v strede resource noda, potom top-left a z neho pivot tile
		var center_world: Vector2 = _grid_center_from_world(near.global_position)
		var tl_cell: Vector2i = _top_left_cell_for_center(center_world, size)
		pivot_cell = tl_cell + local_pivot
	else:
		# fallback: pivot na bunke pod kurzorom (aj tak bude invalid, lebo OnResourceNode)
		pivot_cell = _mouse_cell()

	var footprint: Array[Vector2i] = PlacementService.get_footprint(
		building_id,
		pivot_cell,
		pivot_cell
	)

	var ctx: Dictionary = {}
	var occ: Dictionary = _compute_occupied_cells()
	ctx["occupied_cells"] = occ
	ctx["resource_cells"] = _compute_resource_cells()

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

	return {
		"footprint": footprint,
		"ghost_info": ghost_info,
		"has_node": near != null,
	}


func _draw_ghost_tile(cell: Vector2i, state_idx: int) -> void:
	var hc: Dictionary = _cell_corners_world(cell)
	var tl_world: Vector2 = hc["tl"]
	var br_world: Vector2 = hc["br"]
	var tl_local: Vector2 = to_local(tl_world)
	var br_local: Vector2 = to_local(br_world)
	var rect: Rect2 = Rect2(tl_local, br_local - tl_local)

	match state_idx:
		0:
			draw_rect(rect, BuildCfg.GHOST_FILL, true)
		1:
			draw_rect(rect, Color(1, 0.2, 0.2, 0.35), true)
		_:
			draw_rect(rect, Color(1, 1, 0.2, 0.35), true)

	draw_rect(rect, BuildCfg.GHOST_TILE_STROKE, false, 1.5)
