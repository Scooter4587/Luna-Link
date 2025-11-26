extends Node
class_name CrewRegistry

var _next_id: int = 1
var crew_by_id: Dictionary = {} # id -> CrewPawn


func register_crew(pawn: CrewPawn) -> int:
	var id := _next_id
	_next_id += 1

	crew_by_id[id] = pawn
	return id


func unregister_crew(id: int) -> void:
	crew_by_id.erase(id)


func get_crew(id: int) -> CrewPawn:
	return crew_by_id.get(id, null)
