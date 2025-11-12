extends Node2D
## Build mód: výber nástroja z UI, ťahanie obdĺžnika a vytvorenie ConstructionSite.
## Zachované tvoje správanie (+ pridaný ghost prstenec so šírkou z BuildCfg).

enum Tool { NONE, EXTERIOR_COMPLEX }

@export var terrain_grid: TileMapLayer
@export var buildings_root: NodePath = NodePath("../Buildings")
@export var construction_root: NodePath = NodePath("../Construction")

@export var building_scene: PackedScene
@export var inside_build_scene: PackedScene
@export var construction_site_scene: PackedScene

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
	match tool_id:
		0:
			current_tool = Tool.EXTERIOR_COMPLEX
			dragging = false
			if terrain_grid != null:
				hover_cell = _mouse_cell()
			queue_redraw()
			print("[BuildMode] Tool=BUILD; hover=", hover_cell, " tg=", terrain_grid)
		_:
			current_tool = Tool.NONE
			dragging = false
			queue_redraw()
			print("[BuildMode] Tool=NONE")

## Vstupy myši: začiatok/koniec ťahania a živý ghost tile pod kurzorom.
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_ESCAPE:
		dragging = false
		queue_redraw()

	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			if current_tool == Tool.EXTERIOR_COMPLEX and terrain_grid != null:
				dragging = true
				drag_a = _mouse_cell()
				drag_b = drag_a
				print("[BuildMode] Drag start @", drag_a)
				queue_redraw()
		else:
			if dragging and current_tool == Tool.EXTERIOR_COMPLEX:
				print("[BuildMode] Drag end   @", drag_b)
				_submit_construction(drag_a, drag_b)
			dragging = false
			queue_redraw()
	elif e is InputEventMouseMotion:
		if current_tool == Tool.EXTERIOR_COMPLEX and terrain_grid != null:
			var c: Vector2i = _mouse_cell()
			if c != hover_cell:
				hover_cell = c
				if dragging:
					drag_b = c
				queue_redraw()

## Vytvorí a nakonfiguruje ConstructionSite podľa ťahaného obdĺžnika.
func _submit_construction(a: Vector2i, b: Vector2i) -> void:
	var minx: int = mini(a.x, b.x)
	var miny: int = mini(a.y, b.y)
	var maxx: int = maxi(a.x, b.x)
	var maxy: int = maxi(a.y, b.y)
	var size: Vector2i = Vector2i(maxx - minx + 1, maxy - miny + 1) # INKLUZÍVNE!

	if size.x < BuildCfg.FOUNDATION_MIN_SIZE.x or size.y < BuildCfg.FOUNDATION_MIN_SIZE.y:
		print("[BuildMode] Ignored: size too small =", size)
		return
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

	# 1) Inštancia mimo stromu
	var site: Node2D = construction_site_scene.instantiate() as Node2D
	site.name = "ConstructionSite_%d_%d" % [minx, miny]

	# 2) Nastaviť exporty mimo stromu
	site.set("terrain_grid", terrain_grid)
	site.set("top_left_cell", Vector2i(minx, miny))
	site.set("size_cells", size)
	site.set("cell_px", BuildCfg.CELL_PX)
	site.set("building_scene", building_scene)
	site.set("inside_build_scene", inside_build_scene)
	site.set("buildings_root_path", buildings_root)
	site.set("z_index", 500)

	# DEV: fix 10 s
	site.set("dev_mode", true)
	site.set("dev_total_time", 10.0)

	# 3) Až teraz pridať do stromu
	construction_root_node.add_child(site)

	var scr: Script = site.get_script()
	print("[BuildMode] Site added @", site.get_path(), " script=", scr)
	print("[BuildMode] Site exports -> tl=", site.get("top_left_cell"),
		" size=", site.get("size_cells"),
		" tg_is_null=", site.get("terrain_grid") == null)

	site.add_to_group("construction_sites")
	print("[BuildMode] ConstructionSite created @", Vector2i(minx, miny), " size=", size)

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

## Kreslí ghost (1 tile pod kurzorom) a počas ťahania aj obdĺžnik vo veľkosti výberu
func _draw() -> void:
	if terrain_grid == null or current_tool != Tool.EXTERIOR_COMPLEX:
		return

	# --- 1× tile ghost pod kurzorom ---
	var hc := _cell_corners_world(hover_cell)
	var tl_tile_world: Vector2 = (hc["tl"] as Vector2)
	var br_tile_world: Vector2 = (hc["br"] as Vector2)
	var tl_tile_local: Vector2 = to_local(tl_tile_world)
	var br_tile_local: Vector2 = to_local(br_tile_world)
	var tile_rect: Rect2 = Rect2(tl_tile_local, br_tile_local - tl_tile_local)
	draw_rect(tile_rect, BuildCfg.GHOST_TILE, true)
	draw_rect(tile_rect, BuildCfg.GHOST_TILE_STROKE, false, 1.5)

	# --- Obdĺžnik počas ťahania (INKLUZÍVNY výber) ---
	if dragging:
		var minx: int = mini(drag_a.x, drag_b.x)
		var miny: int = mini(drag_a.y, drag_b.y)
		var maxx: int = maxi(drag_a.x, drag_b.x)
		var maxy: int = maxi(drag_a.y, drag_b.y)

		var tl_world: Vector2 = (_cell_corners_world(Vector2i(minx, miny))["tl"] as Vector2)
		var br_world: Vector2 = (_cell_corners_world(Vector2i(maxx, maxy))["br"] as Vector2)
		var tl_local: Vector2 = to_local(tl_world)
		var br_local: Vector2 = to_local(br_world)
		var rect: Rect2 = Rect2(tl_local, br_local - tl_local)

		# výplň
		draw_rect(rect, BuildCfg.GHOST_FILL, true)

		# prstenec podľa hrúbky v tiles (prepočítané do px)
		var tsize: Vector2 = _tile_px()
		var tpx: float = float(BuildCfg.FOUNDATION_WALL_THICKNESS) * tsize.x
		var tpy: float = float(BuildCfg.FOUNDATION_WALL_THICKNESS) * tsize.y

		# top
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, tpy)), BuildCfg.GHOST_STROKE, true)
		# left
		draw_rect(Rect2(rect.position, Vector2(tpx, rect.size.y)), BuildCfg.GHOST_STROKE, true)
		# bottom
		draw_rect(Rect2(Vector2(rect.position.x, rect.end.y - tpy), Vector2(rect.size.x, tpy)), BuildCfg.GHOST_STROKE, true)
		# right
		draw_rect(Rect2(Vector2(rect.end.x - tpx, rect.position.y), Vector2(tpx, rect.size.y)), BuildCfg.GHOST_STROKE, true)


## Pomocníci
func _mouse_cell() -> Vector2i:
	if terrain_grid == null:
		push_error("[BuildMode] terrain_grid is null in _mouse_cell()")
		return hover_cell
	var mouse_world: Vector2 = get_global_mouse_position()
	var mouse_local_tm: Vector2 = terrain_grid.to_local(mouse_world)
	return terrain_grid.local_to_map(mouse_local_tm)

func _cell_to_world_center(cell: Vector2i) -> Vector2:
	var p_local: Vector2 = terrain_grid.map_to_local(cell)
	return terrain_grid.to_global(p_local)
