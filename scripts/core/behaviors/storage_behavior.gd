extends Node
class_name StorageBehavior

## StorageBehavior
## - generické lokálne skladovanie (napr. warehouse_small)
## - nepoužíva GameState, drží vlastný slovník "stored"
## - kapacity sú definované v capacity_per_resource

@export var capacity_per_resource: Dictionary = {}  # { &"building_materials": 500.0, ... }

var stored: Dictionary = {}

func _ready() -> void:
	# Inicializuj sklad na 0 pre všetky definované resources.
	for id in capacity_per_resource.keys():
		stored[id] = 0.0

func get_stored(id: StringName) -> float:
	if stored.has(id):
		return float(stored[id])
	return 0.0

func get_capacity(id: StringName) -> float:
	if capacity_per_resource.has(id):
		return float(capacity_per_resource[id])
	# -1 = unlimited kapacita
	return -1.0

## Vráti reálne uloženú (alebo odobratú) hodnotu (delta).
func add_to_storage(id: StringName, amount: float) -> float:
	if amount == 0.0:
		return 0.0

	var current: float = get_stored(id)
	var capacity: float = get_capacity(id)

	var new_value: float = current + amount

	if capacity >= 0.0:
		new_value = clamp(new_value, 0.0, capacity)
	else:
		new_value = max(new_value, 0.0)

	var delta: float = new_value - current
	stored[id] = new_value
	return delta
