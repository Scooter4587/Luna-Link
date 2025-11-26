# scripts/crew/crew_manager.gd
class_name CrewManager
extends Node2D
# Node, ktorý budeš mať niekde v hlavnej scéne hubu.

## Scéna, ktorú použijeme ako vizuál posádky
@export var crew_pawn_scene: PackedScene

## Bod, kde sa posádka zjaví na začiatku – napr. Marker2D nad landing_pad_basic
@export var landing_pad_node: NodePath

## Všetci členovia posádky (čisto logické objekty)
var crew_states: Array[CrewState] = []

## Nody, ktoré reprezentujú jednotlivých členov posádky v scéne
var crew_pawns: Array[CrewPawn] = []


func _ready() -> void:
	# 0.0.61: pri štarte scenára spawneme jedného testovacieho člena
	_spawn_initial_crew()


func _spawn_initial_crew() -> void:
	var spawn_position := _get_spawn_position()
	print("Crew spawn pos: ", spawn_position)
	
	# Zatiaľ jedného testovacieho člena
	var state := CrewState.new(&"Crew 1")
	state.home_room_id = &"room_quarters_basic"  # placeholder
	state.work_station_id = &"work_station_placeholder"  # placeholder

	crew_states.append(state)
	_spawn_pawn_for_state(state, spawn_position)


func _spawn_pawn_for_state(state: CrewState, world_position: Vector2) -> void:
	if crew_pawn_scene == null:
		push_error("CrewManager: crew_pawn_scene nie je nastavená.")
		return

	var pawn := crew_pawn_scene.instantiate() as CrewPawn
	pawn.global_position = world_position
	pawn.setup(state)

	add_child(pawn)
	crew_pawns.append(pawn)


func _get_spawn_position() -> Vector2:
	if landing_pad_node.is_empty():
		push_warning("CrewManager: landing_pad_node nie je nastavený, používam (0, 0).")
		return Vector2.ZERO

	var node := get_node_or_null(landing_pad_node)

	if node == null:
		push_warning("CrewManager: landing_pad_node neexistuje v scéne, používam (0, 0).")
		return Vector2.ZERO

	# Preferujeme LandingPad skript (štúdiové riešenie).
	if node is LandingPad:
		return (node as LandingPad).get_crew_spawn_position()

	# Fallback – keby tam nebol skript, zoberieme pozíciu rootu.
	if node is Node2D:
		return (node as Node2D).global_position

	return Vector2.ZERO
