extends Node2D
class_name BMExtractor
# Každú hernú HODINU pridá výstup z pripojeného ResourceNode do State.

@export var auto_find_radius: float = 400.0
@export var production_multiplier: float = 1.0
@export var debug_logs: bool = false

var linked_node: ResourceNode = null
var _clock: Node = null

func _ready() -> void:
	# 1) skús nájsť hneď (malo by stačiť po fixe v ConstructionSite)
	linked_node = _find_nearest_node()
	if linked_node == null:
		# ak ešte nestojíme na finálnej pozícii, daj tomu 1 frame a skús znova
		call_deferred("_late_link_attempt")
	else:
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
	var res_id: StringName = StringName(linked_node.get_resource_id())
	print("[BMExtractor] Linked to node id=", linked_node.node_id,
		" res=", res_id, " out/h=", linked_node.get_output_per_hour() * production_multiplier)

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
