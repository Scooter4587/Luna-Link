extends Node
class_name LifeSupportModule
## LifeSupportModule
## - Reprezentuje jeden životný modul (air/atmo) v rámci zóny.
## - Spotrebúva vodu + kyslík z GameState (State).
## - Dodáva kyslík a tlak do PressurizedZone.
## - Spotrebu energie reportuje cez EnergySystem (energy_modules).

@export var zone_path: NodePath = NodePath("")
@export var enabled: bool = true

@export var crew_capacity: int = 4
@export var crew_present: int = 4

@export var energy_consumption_per_hour: float = 5.0
@export var o2_units_per_crew_per_hour: float = 1.0
@export var water_per_crew_per_hour: float = 0.5

@export var pressure_support_kpa_per_hour: float = 20.0
@export var oxygen_zone_gain_per_minute: float = 0.01

var _zone: PressurizedZone = null


func _ready() -> void:
	# Pre EnergySystem + ProductionSystem (production zatiaľ nevyužíva LS)
	add_to_group("energy_modules")
	add_to_group("production_modules")

	_resolve_zone()
	if _zone != null:
		_zone.register_life_support_module(self)

	if _should_debug():
		var zone_label: String = "null"
		if _zone != null:
			zone_label = str(_zone.zone_id)
		print("[LifeSupportModule] ready name=", name,
			" zone=", zone_label,
			" crew_present=", crew_present)


func _resolve_zone() -> void:
	if zone_path != NodePath(""):
		var n := get_node_or_null(zone_path)
		if n is PressurizedZone:
			_zone = n
			return

	var cur: Node = get_parent()
	while cur != null and _zone == null:
		if cur is PressurizedZone:
			_zone = cur
			break
		cur = cur.get_parent()


## EnergySystem hook: kladné = výroba, záporné = spotreba
func get_energy_delta_per_hour() -> float:
	if not enabled or crew_present <= 0:
		return 0.0
	var total_energy: float = energy_consumption_per_hour
	return -total_energy


## ProductionSystem hook – zatiaľ nič, aby nebol double-count
func get_production_per_hour() -> Dictionary:
	return {}


## PressurizedZone hook:
## - volá sa raz za hernú minútu
## - vracia zmenu pre zónu:
##     { "oxygen_delta": float, "pressure_delta": float }
func get_zone_effect_per_minute() -> Dictionary:
	var result: Dictionary = {
		"oxygen_delta": 0.0,
		"pressure_delta": 0.0,
	}

	if not enabled or crew_present <= 0:
		return result

	if typeof(State) == TYPE_NIL:
		return result

	var o2_per_hour: float = o2_units_per_crew_per_hour * float(crew_present)
	var water_per_hour: float = water_per_crew_per_hour * float(crew_present)

	var o2_per_min: float = o2_per_hour / 60.0
	var water_per_min: float = water_per_hour / 60.0

	var cur_o2: float = State.get_resource(&"oxygen_units")
	var cur_water: float = State.get_resource(&"water")

	var can_run: bool = (cur_o2 >= o2_per_min and cur_water >= water_per_min)

	if not can_run:
		if _should_debug():
			print("[LifeSupportModule] insufficient resources for life support in ", name,
				" (o2=", cur_o2, " water=", cur_water,
				" need/min=", o2_per_min, "/", water_per_min, ")")
		return result

	# Zožereme resource z GameState
	State.add_resource(&"oxygen_units", -o2_per_min)
	State.add_resource(&"water", -water_per_min)

	# Efekt na zónu
	result["oxygen_delta"] = oxygen_zone_gain_per_minute
	result["pressure_delta"] = pressure_support_kpa_per_hour / 60.0

	if _should_debug():
		print("[LifeSupportModule] tick ", name,
			" used o2=", o2_per_min, " water=", water_per_min,
			" -> zone ΔO2=", result["oxygen_delta"],
			" ΔP=", result["pressure_delta"])

	return result


func _should_debug() -> bool:
	return DebugFlags.MASTER_DEBUG
