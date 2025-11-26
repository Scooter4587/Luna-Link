# scripts/buildings/exterior/LandingPad.gd
extends Node2D
class_name LandingPad

## Toto je bod, kde má spawnúť posádka (Marker2D alebo iný Node2D).
@export var crew_spawn_point: NodePath


func get_crew_spawn_position() -> Vector2:
	# Hlavný vstup pre CrewManager.
	if crew_spawn_point.is_empty():
		# Ak nie je nastavený, použijeme pozíciu rootu.
		return global_position

	var node := get_node_or_null(crew_spawn_point)
	if node is Node2D:
		return (node as Node2D).global_position

	return global_position
