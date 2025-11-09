extends Node2D
# Build mód: výber nástroja z UI, ghost 1× tile, ťahanie obdĺžnika a vytvorenie ConstructionSite.

enum Tool { NONE, EXTERIOR_COMPLEX }

@export var terrain_grid: TileMapLayer
@export var buildings_root: NodePath = NodePath("../Buildings")
@export var construction_root: NodePath = NodePath("../Construction")

@export var building_scene: PackedScene
@export var inside_build_scene: PackedScene
@export var construction_site_scene: PackedScene

@export var cell_px: int = 128

var current_tool: Tool = Tool.NONE
var dragging: bool = false
var drag_a: Vector2i = Vector2i.ZERO
var drag_b: Vector2i = Vector2i.ZERO
var hover_cell: Vector2i = Vector2i.ZERO

func _ready() -> void:
	set_process_unhandled_input(true)
	queue_redraw()
	z_index = 1000

	# --- AUTOWIRE terrain_grid (typované) ---
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

	# --- UI signál (typované) ---
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

# Reakcia na kliky v spodnej lište – Build=0
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

# Vstupy myši: začiatok/koniec ťahania a živý ghost tile pod kurzorom.
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

# Vytvorí a nakonfiguruje ConstructionSite podľa ťahaného obdĺžnika.
# Vytvorí a nakonfiguruje ConstructionSite podľa ťahaného obdĺžnika.
func _submit_construction(a: Vector2i, b: Vector2i) -> void:
	var minx: int = mini(a.x, b.x)
	var miny: int = mini(a.y, b.y)
	var maxx: int = maxi(a.x, b.x)
	var maxy: int = maxi(a.y, b.y)
	var size: Vector2i = Vector2i(maxx - minx + 1, maxy - miny + 1)

	if size.x < 2 or size.y < 2:
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

	# 1) Inštancia mimo stromu (typované)
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

	# Test: fixných ~10 s
	site.set("dev_mode", true)
	site.set("dev_total_time", 10.0)

	# 3) Až teraz pridať do stromu
	construction_root_node.add_child(site)

	# Debug (typované)
	var scr: Script = site.get_script()
	print("[BuildMode] Site added @", site.get_path(), " script=", scr)
	print("[BuildMode] Site exports -> tl=", site.get("top_left_cell"),
		" size=", site.get("size_cells"),
		" tg_is_null=", site.get("terrain_grid") == null)

	site.add_to_group("construction_sites")

	print("[BuildMode] ConstructionSite created @", Vector2i(minx, miny), " size=", size)

# Kreslenie ghostov (1 tile + obdĺžnik).
func _draw() -> void:
	if terrain_grid == null:
		return

	if current_tool == Tool.EXTERIOR_COMPLEX:
		# 1× tile ghost
		var hc_world: Vector2 = _cell_to_world_center(hover_cell)
		var hc_local: Vector2 = to_local(hc_world)
		var tile_rect: Rect2 = Rect2(
			hc_local - Vector2(float(cell_px), float(cell_px)) * 0.5,
			Vector2(float(cell_px), float(cell_px))
		)
		draw_rect(tile_rect, Color(1,1,1,0.12), true)
		draw_rect(tile_rect, Color(1,1,1,0.8), false, 1.5)

	if dragging and current_tool == Tool.EXTERIOR_COMPLEX:
		var minx: int = mini(drag_a.x, drag_b.x)
		var miny: int = mini(drag_a.y, drag_b.y)
		var maxx: int = maxi(drag_a.x, drag_b.x)
		var maxy: int = maxi(drag_a.y, drag_b.y)

		var tl_world: Vector2 = _cell_to_world_center(Vector2i(minx, miny)) - Vector2(float(cell_px), float(cell_px)) * 0.5
		var br_world: Vector2 = _cell_to_world_center(Vector2i(maxx, maxy)) + Vector2(float(cell_px), float(cell_px)) * 0.5
		var tl_local: Vector2 = to_local(tl_world)
		var br_local: Vector2 = to_local(br_world)
		var rect: Rect2 = Rect2(tl_local, br_local - tl_local)

		draw_rect(rect, Color(1,1,1,0.12), true)
		draw_rect(rect, Color(1,1,1,0.9), false, 2.0)

# Pomocníci
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
