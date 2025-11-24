extends Node
class_name LifeSupportModule

## LifeSupportModule
## - pripnutý na budovu typu oxygen_generator_small
## - každú hernú hodinu:
##   * ak je budova powered,
##   * pokúsi sa minúť water_per_hour z resource "water"
##   * za úspech pridá oxygen_per_hour do:
##       - PressurizedZone (ak je zadaná),
##       - inak do globálneho resource "oxygen_units".

@export var water_per_hour: float = 1.0
@export var oxygen_per_hour: float = 5.0

## Ak je vyplnený, LifeSupportModule pošle kyslík do konkrétnej zóny.
@export var zone_path: NodePath

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("behavior_hourly")

func _on_behavior_hour_tick(hours: float) -> void:
	if Engine.is_editor_hint():
		return

	if not _is_building_powered():
		return

	var game_state: Variant = _get_game_state()
	if game_state == null:
		return

	var factor: float = max(hours, 0.0)
	if factor <= 0.0:
		return

	var water_need: float = water_per_hour * factor
	if water_need <= 0.0:
		return

	# Ak nemáme dosť vody, modul nič nerobí.
	if not game_state.can_spend(&"water", water_need):
		return

	# Spotrebuj vodu.
	game_state.spend_resource(&"water", water_need)

	var oxygen_gain: float = oxygen_per_hour * factor
	if oxygen_gain <= 0.0:
		return

	# Ak máme zónu, pošleme kyslík tam. Inak do globálneho oxygen_units.
	var zone: Variant = _get_zone()
	if zone != null and zone.has_method("add_oxygen_units"):
		zone.add_oxygen_units(oxygen_gain)
	else:
		game_state.add_resource(&"oxygen_units", oxygen_gain)

func _get_game_state():
	var root: Node = get_tree().root
	if root == null:
		return null
	if root.has_node("GameState"):
		return root.get_node("GameState")
	push_warning("[LifeSupportModule] GameState node not found at /root/GameState.")
	return null

func _get_zone():
	if zone_path.is_empty():
		return null
	var host: Node = get_parent()
	if host == null:
		return null
	return host.get_node_or_null(zone_path)

func _is_building_powered() -> bool:
	var host: Node = get_parent()
	if host == null:
		return true
	if not host.has_method("get"):
		return true
	var value: Variant = host.get("is_powered")
	if value is bool:
		return value
	return true
