extends Node
class_name AirlockBehavior

## -------------------------------------------------------
## AirlockBehavior
##
## Univerzálna logika airlocku (crew aj vehicle).
## - 2 dvere: inside / outside.
## - Nikdy nie sú otvorené oboje naraz.
## - Prechod prebieha cez "cycle" s trvaním v sekundách.
## - Pripravuje hooky pre pathfinding a resource spotrebu.
## -------------------------------------------------------

signal airlock_state_changed(
	airlock: Node,
	new_state: int,
	inside_open: bool,
	outside_open: bool,
	is_cycling: bool
)

enum AirlockState {
	CLOSED_BOTH,  ## oboje dvere zatvorené, airlock je idle
	OPEN_INSIDE,  ## otvorené vnútorné dvere
	OPEN_OUTSIDE, ## otvorené vonkajšie dvere
	CYCLING,      ## prebieha equalizácia/odtlakovanie – všetko zatvorené
}

enum Direction {
	FROM_INSIDE,  ## crew/vozidlo ide z interiéru von
	FROM_OUTSIDE, ## crew/vozidlo ide zvonku dnu
}

## Režim airlocku – zatiaľ len infotext (crew / vehicle).
@export var mode: StringName = &"crew"

## Ako dlho trvá jeden cyklus (v sekundách).
@export var cycle_duration_seconds: float = 10.0

## Hooky do budúcna – spotreba resource počas cyklu.
@export var uses_energy_per_cycle: float = 0.0
@export var uses_oxygen_units_per_cycle: float = 0.0

## Aktuálny stav airlocku.
var _state: int = AirlockState.CLOSED_BOTH

## Cieľ po skončení cyklu (inside→outside alebo naopak).
var _pending_direction: int = Direction.FROM_INSIDE

## Timer na meranie trvania cyklu.
var _cycle_timer: Timer

## Group name – aby sme airlocky vedeli nájsť cez get_nodes_in_group().
const GROUP_AIRLOCKS: StringName = &"airlocks"


func _ready() -> void:
	## Pri štarte:
	## - pridá node do group "airlocks"
	## - vytvorí Timer pre cyklus
	## - pošle initial stav (closed_both)
	add_to_group(GROUP_AIRLOCKS)

	_cycle_timer = Timer.new()
	_cycle_timer.one_shot = true
	add_child(_cycle_timer)
	_cycle_timer.timeout.connect(_on_cycle_timer_timeout)

	_emit_state_changed()


func request_open_from_inside() -> void:
	## API: crew/vozidlo chce ísť z interiéru → von.
	## - Ak už sú vnútorné dvere otvorené, nerobíme nič.
	## - Ak sú otvorené vonkajšie dvere, najprv ich "zavrieme".
	## - Spustíme cyklus smerom von (FROM_INSIDE).
	if _is_cycling():
		return

	if _state == AirlockState.OPEN_INSIDE:
		return

	if _state == AirlockState.OPEN_OUTSIDE:
		_state = AirlockState.CLOSED_BOTH
		_emit_state_changed()

	_start_cycle(Direction.FROM_INSIDE)


func request_open_from_outside() -> void:
	## API: crew/vozidlo chce ísť zvonku → dnu.
	## Logika je zrkadlová voči request_open_from_inside().
	if _is_cycling():
		return

	if _state == AirlockState.OPEN_OUTSIDE:
		return

	if _state == AirlockState.OPEN_INSIDE:
		_state = AirlockState.CLOSED_BOTH
		_emit_state_changed()

	_start_cycle(Direction.FROM_OUTSIDE)


func is_passable_from_inside() -> bool:
	## Hook pre pathfinding:
	## True = cesta z interiéru cez airlock je práve možná.
	return _state == AirlockState.OPEN_INSIDE


func is_passable_from_outside() -> bool:
	## Hook pre pathfinding:
	## True = cesta zvonku cez airlock je práve možná.
	return _state == AirlockState.OPEN_OUTSIDE


func _is_cycling() -> bool:
	## Pomocná funkcia: či práve prebieha cyklus.
	return _state == AirlockState.CYCLING


func _start_cycle(direction: int) -> void:
	## Spustí nový cyklus:
	## - nastaví stav na CYCLING,
	## - uloží cieľový smer (inside→outside alebo outside→inside),
	## - ak je cycle_duration_seconds <= 0, cyklus skončí okamžite,
	## - inak spustí Timer.
	_state = AirlockState.CYCLING
	_pending_direction = direction
	_emit_state_changed()

	if cycle_duration_seconds <= 0.0:
		_finish_cycle()
	else:
		_cycle_timer.start(cycle_duration_seconds)


func _on_cycle_timer_timeout() -> void:
	## Callback z Timeru – cyklus skončil.
	_finish_cycle()


func _finish_cycle() -> void:
	## Ukončí cyklus podľa uloženého smeru:
	## - FROM_INSIDE → otvoríme vonkajšie dvere
	## - FROM_OUTSIDE → otvoríme vnútorné dvere
	## V tejto verzii zatiaľ len meníme stav a logujeme.
	match _pending_direction:
		Direction.FROM_INSIDE:
			_state = AirlockState.OPEN_OUTSIDE
		Direction.FROM_OUTSIDE:
			_state = AirlockState.OPEN_INSIDE
		_:
			_state = AirlockState.CLOSED_BOTH

	# TODO: tu neskôr:
	# - odpísať energiu / oxygen_units z ResourceManageru
	# - prípadne spawnúť eventy (chybné dvere, leak, atď.)

	_emit_state_changed()


func _emit_state_changed() -> void:
	## Pošle signal a vypíše debug do konzoly.
	var inside_open: bool = _state == AirlockState.OPEN_INSIDE
	var outside_open: bool = _state == AirlockState.OPEN_OUTSIDE
	var is_cycling: bool = _state == AirlockState.CYCLING

	airlock_state_changed.emit(self, _state, inside_open, outside_open, is_cycling)

	print(
		"[Airlock] state -> ",
		_state_to_string(_state),
		" | inside_open=",
		str(inside_open),
		" outside_open=",
		str(outside_open),
		" cycling=",
		str(is_cycling)
	)


func _state_to_string(state: int) -> String:
	## Pomocná funkcia pre čitateľný log.
	match state:
		AirlockState.CLOSED_BOTH:
			return "CLOSED_BOTH"
		AirlockState.OPEN_INSIDE:
			return "OPEN_INSIDE"
		AirlockState.OPEN_OUTSIDE:
			return "OPEN_OUTSIDE"
		AirlockState.CYCLING:
			return "CYCLING"
		_:
			return "UNKNOWN"
