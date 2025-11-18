# res://scripts/exterior/ConstructionSite.gd
extends Node2D
# ConstructionSite: vizuálny plán stavby + odpočet času do dokončenia.
# Jednotný mechanizmus pre foundation aj fixné budovy (napr. extractor).
# Pauza / rýchlosť funguje, keď bežíme na herných hodinách/minútach (GameClock).

# --- Vstupy z BuildMode / Inspectoru -----------------------------------------

@export var terrain_grid: TileMapLayer
@export var top_left_cell: Vector2i = Vector2i.ZERO
@export var size_cells: Vector2i = Vector2i(4, 3)
@export var cell_px: int = 128

@export var building_scene: PackedScene              # výsledná budova po dokončení
@export var inside_build_scene: PackedScene          # interiér (voliteľné)
@export var buildings_root_path: NodePath = NodePath("../Buildings")

# Časovanie – typ behu
enum BuildTimeMode { REALTIME_SECONDS = 0, GAME_MINUTES_FIXED = 1, GAME_HOURS_FIXED = 2 }
@export var time_mode: BuildTimeMode = BuildTimeMode.GAME_HOURS_FIXED

# Parametre pre mód GAME_MINUTES_FIXED / GAME_HOURS_FIXED
@export var build_game_minutes: int = 10             # použije sa pri GAME_MINUTES_FIXED
@export var build_game_hours: int = 1                # použije sa pri GAME_HOURS_FIXED

# Parametre pre fallback REALTIME_SECONDS (zachované kvôli dev testom)
@export var sec_per_tile: float = 0.50               # sekúnd / tile (len pre REALTIME_SECONDS)
@export var max_build_time: float = 30.0             # cap v s; <=0 = bez capu (len pre REALTIME_SECONDS)
@export var min_build_time: float = 1.0              # min v s (len pre REALTIME_SECONDS)

# DEV pomocník pre realtime testy (len pri REALTIME_SECONDS)
@export var dev_mode: bool = false
@export var dev_total_time: float = 10.0             # fixné sekundy (len pre REALTIME_SECONDS)

# Foundation zvyčajne spúšťa interiér po dokončení
@export var use_interior: bool = false

# Pri fixných exteriéroch (napr. extractor) vieme určiť presný world stred spawnu
@export var use_center_override: bool = false
@export var spawn_center_override_world: Vector2 = Vector2.ZERO

@export var visual_px_size: Vector2 = Vector2.ZERO
@export var linked_resource_node_path: NodePath = NodePath("")

# --- Interné runtime premenné ------------------------------------------------

var build_time_total: float = 1.0    # v sekundách / minútach / hodinách podľa time_mode
var build_time_left: float = 1.0
var started: bool = false
var _game_clock: Node = null

# guard aby sme nesypali error stále dokola
var _warned_missing_root: bool = false

# --- Lifecycle ----------------------------------------------------------------

func _ready() -> void:
	add_to_group("buildings")
	# Nastav celkový "čas" podľa time_mode
	match time_mode:
		BuildTimeMode.GAME_HOURS_FIXED:
			build_time_total = float(max(1, build_game_hours))
		BuildTimeMode.GAME_MINUTES_FIXED:
			build_time_total = float(max(1, build_game_minutes))
		BuildTimeMode.REALTIME_SECONDS:
			var tiles_count: int = max(1, size_cells.x * size_cells.y)
			var proposed: float = float(tiles_count) * sec_per_tile
			if dev_mode:
				build_time_total = max(dev_total_time, 0.1)
			elif max_build_time > 0.0:
				build_time_total = clamp(proposed, min_build_time, max_build_time)
			else:
				build_time_total = max(proposed, min_build_time)
		_:
			build_time_total = 1.0  # bezpečný default

	build_time_left = build_time_total

	# Režim spracovania: realtime beží v _process, ostatné cez GameClock signály
	set_process(time_mode == BuildTimeMode.REALTIME_SECONDS)

	# Pripoj správny clock (aby pauza/rýchlosť fungovali)
	match time_mode:
		BuildTimeMode.GAME_HOURS_FIXED:
			_connect_clock_hours()
		BuildTimeMode.GAME_MINUTES_FIXED:
			_connect_clock_minutes()
		_:
			pass

	z_index = 500
	started = true
	queue_redraw()

	# Debug info bez ternáru
	var mode_txt := "REALTIME"
	if time_mode == BuildTimeMode.GAME_MINUTES_FIXED:
		mode_txt = "GAME_MINUTES"
	elif time_mode == BuildTimeMode.GAME_HOURS_FIXED:
		mode_txt = "GAME_HOURS"

	var unit_txt := "s"
	if time_mode == BuildTimeMode.GAME_MINUTES_FIXED:
		unit_txt = "min"
	elif time_mode == BuildTimeMode.GAME_HOURS_FIXED:
		unit_txt = "h"

	print("[ConstructionSite] ready (", mode_txt, ") tl=", top_left_cell, " size=", size_cells,
		" total=", build_time_total, unit_txt, "  tg_is_null=", terrain_grid == null)

func _process(dt: float) -> void:
	# Len pre REALTIME_SECONDS
	if not started or time_mode != BuildTimeMode.REALTIME_SECONDS:
		return

	build_time_left -= dt
	if build_time_left <= 0.0:
		_finalize_build()
		return
	queue_redraw()

# --- Clock napojenia ----------------------------------------------------------

# Minútový clock (pre GAME_MINUTES_FIXED)
func _connect_clock_minutes() -> void:
	var root: Node = get_tree().get_root()
	var clock: Node = root.find_child("GameClock", true, false)
	if clock == null:
		for n in root.find_children("*", "", true, false):
			if n.has_signal("minute_changed"):
				clock = n
				break
	if clock == null:
		push_warning("[ConstructionSite] time_mode=GAME_MINUTES_FIXED, GameClock sa nenašiel.")
		return
	if not clock.has_signal("minute_changed"):
		push_warning("[ConstructionSite] Nájdený GameClock nemá signál minute_changed.")
		return
	_game_clock = clock
	clock.minute_changed.connect(_on_clock_minute_changed)
	print("[ConstructionSite] Connected to GameClock.minute_changed @", clock.get_path())

func _on_clock_minute_changed(_year: int, _month_index: int, _day: int, _hour: int, _minute: int) -> void:
	if not started or time_mode != BuildTimeMode.GAME_MINUTES_FIXED:
		return
	build_time_left -= 1.0
	if build_time_left <= 0.0:
		_finalize_build()
		return
	queue_redraw()

# Hodinový clock (pre GAME_HOURS_FIXED)
func _connect_clock_hours() -> void:
	var root: Node = get_tree().get_root()
	var clock: Node = root.find_child("GameClock", true, false)
	if clock == null:
		for n in root.find_children("*", "", true, false):
			if n.has_signal("hour_changed"):
				clock = n
				break
	if clock == null:
		push_warning("[ConstructionSite] time_mode=GAME_HOURS_FIXED, GameClock sa nenašiel.")
		return
	if not clock.has_signal("hour_changed"):
		push_warning("[ConstructionSite] Nájdený GameClock nemá signál hour_changed.")
		return
	_game_clock = clock
	clock.hour_changed.connect(_on_clock_hour_changed)
	print("[ConstructionSite] Connected to GameClock.hour_changed @", clock.get_path())

func _on_clock_hour_changed(_year: int, _month_index: int, _day: int, _hour: int) -> void:
	if not started or time_mode != BuildTimeMode.GAME_HOURS_FIXED:
		return
	build_time_left -= 1.0
	if build_time_left <= 0.0:
		_finalize_build()
		return
	queue_redraw()

# --- Dokončenie stavby --------------------------------------------------------

func _finalize_build() -> void:
	var parent2d: Node2D = _get_buildings_root()
	if parent2d == null:
		# Skúsime znova pri najbližšom ticku, nespamujeme log.
		return

	if building_scene == null:
		push_error("[ConstructionSite] building_scene is null – niet čo spawniť")
		return

	var b: Node = building_scene.instantiate()
	if not (b is Node2D):
		push_error("[ConstructionSite] building_scene nie je Node2D – očakávam 2D budovu")
		return
	var b2d: Node2D = b as Node2D

	# Pozícia v závislosti od režimu centrovania
	var spawn_world: Vector2
	if use_center_override:
		spawn_world = spawn_center_override_world
	else:
		var tl_local: Vector2 = terrain_grid.map_to_local(top_left_cell)
		spawn_world = terrain_grid.to_global(tl_local)

	# Prenos parametrov do budovy (ak ich podporuje)
	b2d.set("cell_px", cell_px)
	b2d.set("size_cells", size_cells)
	b2d.set("top_left_cell", top_left_cell)
	if inside_build_scene != null and _has_property(b2d, &"interior_scene"):
		b2d.set("interior_scene", inside_build_scene)
	if _has_property(b2d, &"terrain_grid"):
		b2d.set("terrain_grid", terrain_grid)
	if _has_property(b2d, &"top_left_cell"):
		b2d.set("top_left_cell", top_left_cell)

	# Najprv nastav pozíciu (v lokálnych coords parenta), až potom add_child
	var local_pos: Vector2 = parent2d.to_local(spawn_world)
	b2d.position = local_pos
	parent2d.add_child(b2d)
	
	# Prepoj extractor ↔ ResourceNode (ak je nastavená cesta)
	if linked_resource_node_path != NodePath(""):
		# Pošli link budove, ak má takú property
		if _has_property(b2d, &"linked_resource_node_path"):
			b2d.set("linked_resource_node_path", linked_resource_node_path)

		# Skús nájsť ResourceNode a dať mu spätný link na extractor
		var rn: Node = get_tree().get_root().get_node_or_null(linked_resource_node_path)
		if rn != null:
			if _has_property(rn, &"extractor_path"):
				rn.set("extractor_path", b2d.get_path())
			if _has_property(rn, &"has_extractor"):
				rn.set("has_extractor", true)

	_disconnect_clock()
	queue_free()

	# print("[ConstructionSite] DONE → Building spawned @", top_left_cell, " size=", size_cells, " into=", parent2d.get_path())

# --- Kreslenie ghostu / progress ---------------------------------------------

func _draw() -> void:
	if terrain_grid == null:
		# červený „NO GRID“ štvorec ako varovanie
		var warn_rect: Rect2 = Rect2(Vector2(-32, -32), Vector2(64, 64))
		draw_rect(warn_rect, Color(1,0,0,0.6), true)
		draw_rect(warn_rect, Color(1,1,1,1.0), false, 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(-30, -40), "NO GRID",
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(1,1,1,1))
		return

	var build_rect: Rect2
	var label_anchor: Vector2

	# 1) Špeciálny vizuál (napr. extractor) – veľkosť v pixeloch
	if visual_px_size != Vector2.ZERO and use_center_override:
		var center_world: Vector2 = spawn_center_override_world
		var half_visual: Vector2 = visual_px_size * 0.5
		var tl_world: Vector2 = center_world - half_visual
		var tl_local: Vector2 = to_local(tl_world)

		build_rect = Rect2(tl_local, visual_px_size)
		label_anchor = tl_local
	else:
		# 2) Pôvodný tile-based rect (foundation a normálne budovy)
		var tl_c: Vector2i = top_left_cell
		var br_c: Vector2i = top_left_cell + size_cells - Vector2i(1, 1)

		var tsize: Vector2 = _tile_px()
		var half: Vector2 = tsize * 0.5

		var tl_world_center: Vector2 = terrain_grid.to_global(terrain_grid.map_to_local(tl_c))
		var br_world_center: Vector2 = terrain_grid.to_global(terrain_grid.map_to_local(br_c))

		var tl_world: Vector2 = tl_world_center - half
		var br_world: Vector2 = br_world_center + half

		var tl_local2: Vector2 = to_local(tl_world)
		var br_local2: Vector2 = to_local(br_world)

		build_rect = Rect2(tl_local2, br_local2 - tl_local2)
		label_anchor = tl_local2

	# --- Progres 0..1 + texty -------------------------------------------------
	var p: float = 1.0 - clamp(build_time_left / max(0.0001, build_time_total), 0.0, 1.0)
	var eta: float = max(0.0, build_time_left)

	draw_rect(build_rect, Color(0.2, 0.8, 1.0, 0.35), true)
	draw_rect(build_rect, Color(1, 1, 1, 1.0), false, 3.0)

	var unit: String = "s"
	if time_mode == BuildTimeMode.GAME_MINUTES_FIXED:
		unit = "min"
	elif time_mode == BuildTimeMode.GAME_HOURS_FIXED:
		unit = "h"

	var font: Font = ThemeDB.fallback_font
	var percent: int = int(round(p * 100.0))
	var eta_1dec: float = round(eta * 10.0) / 10.0
	var label: String = str(percent) + "%  (" + str(eta_1dec) + unit + ")"

	draw_string(font, label_anchor + Vector2(10, 28), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color(1,1,1,1))


# --- Pomocníci ----------------------------------------------------------------

# Veľkosť jedného tile v pixeloch podľa aktuálneho TileMapLayeru (WORLD delta)
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
		w = float(cell_px)
	if h <= 0.0:
		h = float(cell_px)

	return Vector2(w, h)

# Overí, či objekt má danú property (napr. "interior_scene")
func _has_property(obj: Object, prop_name: StringName) -> bool:
	for pd in obj.get_property_list():
		if pd is Dictionary and pd.has("name") and String(pd["name"]) == String(prop_name):
			return true
	return false

# Bezpečne nájde koreň pre umiestnenie hotovej budovy.
func _get_buildings_root() -> Node2D:
	# 1) explicitná cesta z exportu
	var p: NodePath = buildings_root_path
	if p != NodePath(""):
		var n: Node = get_node_or_null(p)
		if n is Node2D:
			return n as Node2D

	# 2) fallback: súrodenec ../Buildings
	var sib: Node = get_node_or_null("../Buildings")
	if sib is Node2D:
		return sib as Node2D

	# 3) fallback: globálne vyhľadanie podľa mena
	var any: Node = get_tree().get_root().find_child("Buildings", true, false)
	if any is Node2D:
		return any as Node2D

	if not _warned_missing_root:
		_warned_missing_root = true
		push_error("[ConstructionSite] buildings_root not found (path neplatný a fallbacky zlyhali)")
	return null

func _disconnect_clock() -> void:
	if _game_clock == null:
		return
	# Odpoj podľa použitého režimu
	if time_mode == BuildTimeMode.GAME_MINUTES_FIXED:
		# bezpečne – len ak je pripojené
		if _game_clock.is_connected("minute_changed", Callable(self, "_on_clock_minute_changed")):
			_game_clock.disconnect("minute_changed", Callable(self, "_on_clock_minute_changed"))
	elif time_mode == BuildTimeMode.GAME_HOURS_FIXED:
		if _game_clock.is_connected("hour_changed", Callable(self, "_on_clock_hour_changed")):
			_game_clock.disconnect("hour_changed", Callable(self, "_on_clock_hour_changed"))

func get_occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	# Predpokladám, že ConstructionSite má tieto premenne:
	# - top_left_cell: Vector2i
	# - size_cells:    Vector2i
	var tl: Vector2i = top_left_cell

	for y: int in size_cells.y:
		for x: int in size_cells.x:
			cells.append(Vector2i(tl.x + x, tl.y + y))

	return cells
