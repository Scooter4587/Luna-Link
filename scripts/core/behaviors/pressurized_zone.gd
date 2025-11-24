extends Node
class_name PressurizedZone

## PressurizedZone
## - reprezentuje natlakovaný vnútorný priestor (napr. hub_core)
## - zatiaľ drží iba lokálny oxygen buffer a status.
## - neskôr sa sem napojí spotreba posádky.

@export var zone_id: StringName = &"hub_zone_1"

@export var max_oxygen_units: float = 100.0
@export var low_threshold: float = 30.0
@export var critical_threshold: float = 10.0

var _oxygen_buffer: float = 0.0
var _status: String = "ok"  # "ok" | "low" | "critical" | "empty"

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("behavior_hourly")
	_update_status()

func _on_behavior_hour_tick(_hours: float) -> void:
	# Zatiaľ status iba prepočítame; spotrebu posádky doplníme až s crew.
	_update_status()

func add_oxygen_units(amount: float) -> void:
	if amount <= 0.0:
		return
	_oxygen_buffer = clamp(_oxygen_buffer + amount, 0.0, max_oxygen_units)
	_update_status()

func get_oxygen_fill() -> float:
	if max_oxygen_units <= 0.0:
		return 0.0
	return _oxygen_buffer / max_oxygen_units

func get_status() -> String:
	return _status

func _update_status() -> void:
	if _oxygen_buffer <= 0.0:
		_status = "empty"
	elif _oxygen_buffer <= critical_threshold:
		_status = "critical"
	elif _oxygen_buffer <= low_threshold:
		_status = "low"
	else:
		_status = "ok"
