extends Node2D
class_name BMExtractor
# Každú hernú HODINU pridá výstup z pripojeného ResourceNode do State.

@export var auto_find_radius: float = 400.0
@export var production_multiplier: float = 1.0
@export var debug_logs: bool = true

@export var size_cells: Vector2i = Vector2i(2, 2)  # alebo nechaj default, ConstructionSite to prepíše
var top_left_cell: Vector2i = Vector2i.ZERO

@export var linked_resource_node_path: NodePath = NodePath("")  # nastaví ConstructionSite
var linked_resource_node: ResourceNode = null

var build_cfg: Dictionary = BuildingsCfg.get_building("bm_extractor")
var linked_node: ResourceNode = null
var _clock: Node = null



func _ready() -> void:
	add_to_group("buildings")
	add_to_group("bm_extractors")
	print("BMExtractor build cfg:", build_cfg)

	# 1) Pokus o priamy link z ConstructionSite cez NodePath
	if linked_resource_node_path != NodePath(""):
		var rn := get_tree().get_root().get_node_or_null(linked_resource_node_path)
		if rn is ResourceNode:
			linked_node = rn
		else:
			push_warning("[BMExtractor] linked_resource_node_path neukazuje na ResourceNode: %s" % str(linked_resource_node_path))

	# 2) Ak stále nič, fallback na pôvodný nearest-node mechanizmus
	if linked_node == null:
		linked_node = _find_nearest_node()

	# 3) Ak ani potom nemáme node, skúsime to o frame neskôr
	if linked_node == null:
		call_deferred("_late_link_attempt")
		return

	# 4) Máme platný ResourceNode → môžeme napojiť clock a log
	_connect_clock()
	if debug_logs:
		_print_link_ok()

func _late_link_attempt() -> void:
	# tento behne po pridaní do stromu + po nastavení pozície
	linked_node = _find_nearest_node()
	if linked_node == null:
		push_warning("[BMExtractor] No ResourceNode near " + str(global_position))
		return
	_connect_clock()
	if debug_logs:
		_print_link_ok()

func _exit_tree() -> void:
	_disconnect_clock()


func _print_link_ok() -> void:
	if linked_node == null:
		print("[BMExtractor] link FAILED (linked_node == null)")
		return

	var rn := linked_node
	print("[BMExtractor] Linked to ResourceNode id=%s name=%s path=%s" % [
		rn.node_id,
		rn.name,
		rn.get_path()
	])

func _connect_clock() -> void:
	if linked_node == null:
		return
	var root := get_tree().get_root()
	var clock: Node = null
	if root.has_node("Clock"):
		clock = root.get_node("Clock")
	else:
		clock = root.find_child("GameClock", true, false)
	if clock == null or not clock.has_signal("hour_changed"):
		push_warning("[BMExtractor] GameClock.hour_changed not found → production disabled.")
		return
	_clock = clock
	if not _clock.is_connected("hour_changed", Callable(self, "_on_clock_hour_changed")):
		_clock.hour_changed.connect(_on_clock_hour_changed)

func _disconnect_clock() -> void:
	if _clock != null and _clock.is_connected("hour_changed", Callable(self, "_on_clock_hour_changed")):
		_clock.disconnect("hour_changed", Callable(self, "_on_clock_hour_changed"))
	_clock = null

func _on_clock_hour_changed(_y: int, _m: int, _d: int, _h: int) -> void:
	if linked_node == null or linked_node.depleted:
		return
	var key: StringName = StringName(linked_node.get_resource_id())
	if key == StringName():
		return
	var amount: float = linked_node.get_output_per_hour() * production_multiplier
	if amount <= 0.0:
		return

	State.add_resource(key, amount)

	# jemne zobuď UI, ak počúva
	if State.has_signal("resources_changed"):
		State.emit_signal("resources_changed")

	#if debug_logs:
	#	print("[BMExtractor] +", amount, " ", key)

func _find_nearest_node() -> ResourceNode:
	var best: ResourceNode = null
	var best_d2: float = auto_find_radius * auto_find_radius
	for n in get_tree().get_nodes_in_group("resource_nodes"):
		if n is ResourceNode:
			var d2 := global_position.distance_squared_to((n as ResourceNode).global_position)
			if d2 <= best_d2:
				best_d2 = d2
				best = n
	return best

func get_occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var tl: Vector2i = top_left_cell

	for y: int in size_cells.y:
		for x: int in size_cells.x:
			cells.append(Vector2i(tl.x + x, tl.y + y))

	return cells

func get_linked_node() -> ResourceNode:
	return linked_node
