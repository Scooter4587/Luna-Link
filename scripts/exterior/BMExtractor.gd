extends Node2D
class_name BMExtractor
## BMExtractor
## - Každú hernú HODINU pridá výstup z pripojeného ResourceNode do GameState (State).
## - Primárny link dostane cez ConstructionSite (linked_resource_node_path).
## - Ak link chýba, fallback: nájde najbližší ResourceNode v dosahu (auto_find_radius).
## - Produkcia = ResourceNode.get_output_per_hour() * production_multiplier.

@export var auto_find_radius: float = 400.0           ## dosah pre fallback hľadanie najbližšieho node
@export var production_multiplier: float = 1.0        ## multiplikátor produkcie (napr. upgrade, výskum)
@export var debug_logs: bool = false                   ## zapnúť/vypnúť debug logy

@export var size_cells: Vector2i = Vector2i(2, 2)     ## grid footprint (prepíše ConstructionSite)
var top_left_cell: Vector2i = Vector2i.ZERO           ## ľavý-horný tile v grid coords (prepíše ConstructionSite)

@export var linked_resource_node_path: NodePath = NodePath("")  ## nastaví ConstructionSite pri spawne

var _linked_node: ResourceNode = null                 ## aktuálne pripojený ResourceNode
var _clock: Node = null                               ## referenca na GameClock (autoload Clock)

var _build_cfg: Dictionary = BuildingsCfg.get_building("bm_extractor")


func _ready() -> void:
	## Po spawne:
	## - pridaj do skupiny "buildings" (pre occupied tiles)
	## - nájdi ResourceNode (najprv export path, potom nearest)
	## - napoj sa na GameClock.hour_changed
	add_to_group("buildings")
	add_to_group("bm_extractors")

	if debug_logs:
		print("[BMExtractor] ready, cfg=", _build_cfg)

	# 1) Pokus o priamy link z ConstructionSite cez NodePath
	_try_link_from_path()

	# 2) Ak stále nič, fallback na nearest-node
	if _linked_node == null:
		_linked_node = _find_nearest_node()

	# 3) Ak ani potom nemáme node, skúsime to o frame neskôr (po tom, čo sa všetko spawnne)
	if _linked_node == null:
		call_deferred("_late_link_attempt")
		return

	# 4) Máme platný ResourceNode → môžeme napojiť clock
	_connect_clock()
	if debug_logs:
		_print_link_ok()


func _try_link_from_path() -> void:
	## Skúsi nájsť ResourceNode podľa linked_resource_node_path (nastaví ConstructionSite).
	if linked_resource_node_path == NodePath(""):
		return

	var rn := get_tree().get_root().get_node_or_null(linked_resource_node_path)
	if rn is ResourceNode:
		_linked_node = rn
	else:
		push_warning("[BMExtractor] linked_resource_node_path neukazuje na ResourceNode: %s"
			% str(linked_resource_node_path))


func _late_link_attempt() -> void:
	## Druhý pokus o link – beží deferred, keď už je scéna viac-menej stabilná.
	if _linked_node == null:
		_linked_node = _find_nearest_node()

	if _linked_node == null:
		push_warning("[BMExtractor] No ResourceNode near " + str(global_position))
		return

	_connect_clock()
	if debug_logs:
		_print_link_ok()


func _exit_tree() -> void:
	## Pri odmazaní budovy sa odpoj z clocku.
	_disconnect_clock()


func _print_link_ok() -> void:
	if _linked_node == null:
		print("[BMExtractor] link FAILED (linked_node == null)")
		return

	var rn := _linked_node
	print("[BMExtractor] Linked to ResourceNode id=%s name=%s path=%s" % [
		rn.node_id,
		rn.name,
		rn.get_path()
	])


func _connect_clock() -> void:
	## Napoj sa na autoload Clock.hour_changed (GameClock).
	if _linked_node == null:
		return

	if typeof(Clock) == TYPE_NIL:
		push_warning("[BMExtractor] Autoload Clock nenašiel – production disabled.")
		return

	if not Clock.has_signal("hour_changed"):
		push_warning("[BMExtractor] Clock nemá signál hour_changed → production disabled.")
		return

	_clock = Clock
	if not _clock.is_connected("hour_changed", Callable(self, "_on_clock_hour_changed")):
		_clock.hour_changed.connect(_on_clock_hour_changed)


func _disconnect_clock() -> void:
	if _clock == null:
		return

	if _clock.is_connected("hour_changed", Callable(self, "_on_clock_hour_changed")):
		_clock.disconnect("hour_changed", Callable(self, "_on_clock_hour_changed"))

	_clock = null


func _on_clock_hour_changed(_y: int, _m: int, _d: int, _h: int) -> void:
	## Callback z GameClock – raz za hernú hodinu:
	## - zober output z ResourceNode
	## - aplikuj production_multiplier
	## - pridaj do State
	if _linked_node == null or _linked_node.depleted:
		return

	var res_id: StringName = _linked_node.get_resource_id()
	if res_id == StringName():
		return

	var amount: float = _linked_node.get_output_per_hour() * production_multiplier
	if amount <= 0.0:
		return

	State.add_resource(res_id, amount)

	if debug_logs:
		print("[BMExtractor] +", amount, " ", res_id, " from node=", _linked_node.node_id)


func _find_nearest_node() -> ResourceNode:
	## Najde najbližší ResourceNode v dosahu auto_find_radius od tejto budovy.
	var best: ResourceNode = null
	var best_d2: float = auto_find_radius * auto_find_radius

	for n in get_tree().get_nodes_in_group("resource_nodes"):
		if n is ResourceNode:
			var rn := n as ResourceNode
			var d2 := global_position.distance_squared_to(rn.global_position)
			if d2 <= best_d2:
				best_d2 = d2
				best = rn

	return best


func get_occupied_cells() -> Array[Vector2i]:
	## Kontrakt pre PlacementService: vráť všetky grid bunky, ktoré budova zaberá.
	var cells: Array[Vector2i] = []
	var tl: Vector2i = top_left_cell

	for y: int in size_cells.y:
		for x: int in size_cells.x:
			cells.append(Vector2i(tl.x + x, tl.y + y))

	return cells


func get_linked_node() -> ResourceNode:
	## Používa GameState.get_hourly_production() – vráti pripojený ResourceNode.
	return _linked_node
