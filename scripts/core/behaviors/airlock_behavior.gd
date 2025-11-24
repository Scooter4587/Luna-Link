extends Node2D
class_name AirlockBehavior
## AirlockBehavior
## - Riadi logiku airlocku (debug verzia).
## - Je v skupine "airlocks" → DebugAirlock ho nájde.
## - Metódy:
##     request_open_from_inside()
##     request_open_from_outside()
## - Pri cykle notifikujeme PressurizedZone a logujeme.

@export var internal_zone_path: NodePath
@export var external_zone_path: NodePath
@export var cycle_duration_sec: float = 5.0
@export var auto_register_with_zones: bool = true

enum AirlockState { IDLE, CYCLING }

var _state: AirlockState = AirlockState.IDLE
var _internal_zone: PressurizedZone = null
var _external_zone: PressurizedZone = null


func _ready() -> void:
	add_to_group("airlocks")
	_resolve_zones()

	if auto_register_with_zones:
		if _internal_zone != null:
			_internal_zone.register_airlock(self)
		if _external_zone != null:
			_external_zone.register_airlock(self)

	if _should_debug():
		var internal_label: String = "null"
		if _internal_zone != null:
			internal_label = str(_internal_zone.zone_id)

		var external_label: String = "null"
		if _external_zone != null:
			external_label = str(_external_zone.zone_id)

		print("[Airlock] ready name=", name,
			" internal_zone=", internal_label,
			" external_zone=", external_label)


func _resolve_zones() -> void:
	if internal_zone_path != NodePath(""):
		var n_in := get_node_or_null(internal_zone_path)
		if n_in is PressurizedZone:
			_internal_zone = n_in
	if external_zone_path != NodePath(""):
		var n_out := get_node_or_null(external_zone_path)
		if n_out is PressurizedZone:
			_external_zone = n_out


func request_open_from_inside() -> void:
	_start_cycle("inside_to_outside")


func request_open_from_outside() -> void:
	_start_cycle("outside_to_inside")


func _start_cycle(direction: String) -> void:
	if _state == AirlockState.CYCLING:
		if _should_debug():
			print("[Airlock] ", name, " is already cycling, ignoring request ", direction)
		return

	_state = AirlockState.CYCLING

	if _should_debug():
		print("[Airlock] cycle START name=", name, " dir=", direction)

	# Notifikuj zóny – samotné straty rieši PressurizedZone
	if _internal_zone != null:
		_internal_zone.notify_airlock_cycle(direction)
	if _external_zone != null:
		_external_zone.notify_airlock_cycle(direction)

	_run_cycle_timer(direction)


func _run_cycle_timer(direction: String) -> void:
	await get_tree().create_timer(max(0.1, cycle_duration_sec)).timeout

	_state = AirlockState.IDLE
	if _should_debug():
		print("[Airlock] cycle END   name=", name, " dir=", direction)


func _should_debug() -> bool:
	return DebugFlags.MASTER_DEBUG
