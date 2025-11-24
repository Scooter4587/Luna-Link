extends Node
## EnergySystem (autoload)
## - Agreguje energiu z modulov v skupine "energy_modules".
## - Každý modul môže mať metódu get_energy_delta_per_hour():
##     > kladná hodnota = výroba
##     > záporná hodnota = spotreba
## - Raz za hernú hodinu:
##     - spočíta čistý delta
##     - pridá ho do ResourceManageru (RESOURCE_ENERGY)

var last_tick_net: float = 0.0
var last_tick_modules: int = 0


func _ready() -> void:
	_connect_clock()


func _connect_clock() -> void:
	if typeof(Clock) == TYPE_NIL:
		push_warning("[EnergySystem] Autoload Clock not found – energy ticks disabled.")
		return
	if not Clock.has_signal("hour_changed"):
		push_warning("[EnergySystem] Clock has no signal hour_changed – energy ticks disabled.")
		return
	if not Clock.is_connected("hour_changed", Callable(self, "_on_clock_hour_changed")):
		Clock.hour_changed.connect(_on_clock_hour_changed)
	if _should_debug():
		print("[EnergySystem] Connected to Clock.hour_changed")


func _on_clock_hour_changed(_y: int, _m: int, _d: int, _h: int) -> void:
	var modules: Array = get_tree().get_nodes_in_group("energy_modules")
	last_tick_modules = modules.size()
	var net: float = 0.0

	for m in modules:
		if m != null and m.has_method("get_energy_delta_per_hour"):
			var delta_any = m.get_energy_delta_per_hour()
			var delta: float = float(delta_any)
			net += delta
			if _should_debug() and abs(delta) > 0.0001:
				print("[EnergySystem] module=", m.name, " delta_per_hour=", delta)

	last_tick_net = net

	if typeof(ResourceManager) == TYPE_NIL:
		if _should_debug():
			print("[EnergySystem] ResourceManager not available, net=", net, " not applied.")
		return

	var energy_id: StringName = ResourceManager.RESOURCE_ENERGY
	var current: float = ResourceManager.get_amount(energy_id)
	var new_value: float = max(0.0, current + net)
	ResourceManager.set_amount(energy_id, new_value)

	if _should_debug():
		print("[EnergySystem] HOUR TICK modules=", last_tick_modules,
			" net=", net, " energy: ", current, " -> ", new_value)


func _should_debug() -> bool:
	# Zatiaľ iba master flag, nech nič nepadá na chýbajúcich DEBUG_XXX
	return DebugFlags.MASTER_DEBUG
