extends Node
## ProductionSystem (autoload)
## - Agreguje produkciu z modulov v skupine "production_modules".
## - Každý modul môže mať:
##     get_production_per_hour() -> { resource_id: delta }
## - Raz za hernú hodinu:
##     - spočíta všetky delty
##     - aplikuje ich do GameState (State)

var last_tick_delta: Dictionary = {}
var last_tick_modules: int = 0


func _ready() -> void:
	_connect_clock()


func _connect_clock() -> void:
	if typeof(Clock) == TYPE_NIL:
		push_warning("[ProductionSystem] Autoload Clock not found – production ticks disabled.")
		return
	if not Clock.has_signal("hour_changed"):
		push_warning("[ProductionSystem] Clock has no signal hour_changed – production ticks disabled.")
		return
	if not Clock.is_connected("hour_changed", Callable(self, "_on_clock_hour_changed")):
		Clock.hour_changed.connect(_on_clock_hour_changed)
	if _should_debug():
		print("[ProductionSystem] Connected to Clock.hour_changed")


func _on_clock_hour_changed(_y: int, _m: int, _d: int, _h: int) -> void:
	var modules: Array = get_tree().get_nodes_in_group("production_modules")
	last_tick_modules = modules.size()
	var totals: Dictionary = {}

	for m in modules:
		if m != null and m.has_method("get_production_per_hour"):
			var out_any = m.get_production_per_hour()
			if out_any is Dictionary:
				var out: Dictionary = out_any
				if out.is_empty():
					continue
				for res_any in out.keys():
					var res_id: StringName = StringName(res_any)
					var delta: float = float(out[res_any])
					var prev: float = float(totals.get(res_id, 0.0))
					totals[res_id] = prev + delta
					if _should_debug() and abs(delta) > 0.0001:
						print("[ProductionSystem] module=", m.name,
							" res=", res_id, " delta_per_hour=", delta)

	last_tick_delta = totals

	if typeof(State) == TYPE_NIL:
		if _should_debug() and not totals.is_empty():
			print("[ProductionSystem] State autoload missing, totals not applied:", totals)
		return

	for res_id in totals.keys():
		var d: float = float(totals[res_id])
		if abs(d) <= 0.0001:
			continue
		State.add_resource(res_id, d)

	if _should_debug() and not totals.is_empty():
		print("[ProductionSystem] HOUR TICK modules=", last_tick_modules,
			" totals=", totals)


func _should_debug() -> bool:
	return DebugFlags.MASTER_DEBUG
