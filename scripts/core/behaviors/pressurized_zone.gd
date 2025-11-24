extends Node
class_name PressurizedZone
## PressurizedZone
## - Simuluje tlak a kyslík v jednej interiérovej zóne.
## - Žije na GameClock.minute_changed.
## - Dostáva vstupy:
##     * LifeSupportModule.get_zone_effect_per_minute()
##     * AirlockBehavior.notify_airlock_cycle(direction)

@export var zone_id: StringName = &"zone_main"

@export var initial_pressure_kpa: float = 0.0
@export var target_pressure_kpa: float = 101.3
@export var initial_oxygen_level: float = 0.0   # 0..1

@export var leak_pressure_kpa_per_min: float = 0.0
@export var leak_o2_per_min: float = 0.0        # 0..1 za minútu

@export var airlock_pressure_loss_kpa: float = 5.0
@export var airlock_o2_loss: float = 0.05       # 5% pri jednom cykle

@export var debug_log_every_minute: bool = false

var pressure_kpa: float
var oxygen_level: float

var _life_support_modules: Array[LifeSupportModule] = []
var _airlocks: Array[AirlockBehavior] = []


func _ready() -> void:
	pressure_kpa = initial_pressure_kpa
	oxygen_level = initial_oxygen_level
	_connect_clock()

	if _should_debug():
		print("[PressurizedZone] ready id=", zone_id,
			" P=", pressure_kpa, "kPa O2=", oxygen_level)


func _connect_clock() -> void:
	if typeof(Clock) == TYPE_NIL:
		push_warning("[PressurizedZone] Clock autoload not found – zone simulation disabled")
		return
	if not Clock.has_signal("minute_changed"):
		push_warning("[PressurizedZone] Clock has no minute_changed signal")
		return
	if not Clock.is_connected("minute_changed", Callable(self, "_on_clock_minute_changed")):
		Clock.minute_changed.connect(_on_clock_minute_changed)


func register_life_support_module(ls: LifeSupportModule) -> void:
	if ls == null:
		return
	if _life_support_modules.has(ls):
		return
	_life_support_modules.append(ls)
	if _should_debug():
		print("[PressurizedZone] registered LifeSupportModule ", ls.name, " to ", zone_id)


func register_airlock(al: AirlockBehavior) -> void:
	if al == null:
		return
	if _airlocks.has(al):
		return
	_airlocks.append(al)
	if _should_debug():
		print("[PressurizedZone] registered Airlock ", al.name, " to ", zone_id)


func notify_airlock_cycle(direction: String) -> void:
	# jednoduchý model: pri každom cykle niečo stratíme
	pressure_kpa = max(0.0, pressure_kpa - airlock_pressure_loss_kpa)
	oxygen_level = clamp(oxygen_level - airlock_o2_loss, 0.0, 1.0)

	if _should_debug():
		print("[PressurizedZone] airlock cycle dir=", direction,
			" new P=", pressure_kpa, " O2=", oxygen_level)


func _on_clock_minute_changed(_y: int, _m: int, _d: int, _h: int, _min: int) -> void:
	# 1) únik
	pressure_kpa = max(0.0, pressure_kpa - leak_pressure_kpa_per_min)
	oxygen_level = clamp(oxygen_level - leak_o2_per_min, 0.0, 1.0)

	# 2) life support moduly
	for ls in _life_support_modules:
		if ls != null and ls.has_method("get_zone_effect_per_minute"):
			var eff_any := ls.get_zone_effect_per_minute()
			if eff_any is Dictionary:
				var eff: Dictionary = eff_any
				var dp: float = float(eff.get("pressure_delta", 0.0))
				var do2: float = float(eff.get("oxygen_delta", 0.0))
				pressure_kpa += dp
				oxygen_level += do2
				if _should_debug() and (dp != 0.0 or do2 != 0.0):
					print("[PressurizedZone] tick from ", ls.name,
						" dp=", dp, " dO2=", do2)

	# clamp limity
	var max_p: float = target_pressure_kpa * 1.2
	if pressure_kpa > max_p:
		pressure_kpa = max_p
	if pressure_kpa < 0.0:
		pressure_kpa = 0.0
	oxygen_level = clamp(oxygen_level, 0.0, 1.0)

	if _should_debug() or debug_log_every_minute:
		print("[PressurizedZone] minute tick id=", zone_id,
			" P=", snapped(pressure_kpa, 0.1),
			"kPa O2=", snapped(oxygen_level * 100.0, 0.1), "%")


func get_status() -> Dictionary:
	return {
		"zone_id": zone_id,
		"pressure_kpa": pressure_kpa,
		"oxygen_level": oxygen_level,
		"target_pressure_kpa": target_pressure_kpa,
	}


func _should_debug() -> bool:
	return DebugFlags.MASTER_DEBUG and DebugFlags.DEBUG_LIFE_SUPPORT
