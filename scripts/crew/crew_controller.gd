# res://scripts/crew/crew_controller.gd
extends Node2D
class_name CrewController

@export var hud_panel: CrewHudPanelUI

var selected: CrewPawn = null


func _ready() -> void:
	print("CrewController ready, hud_panel =", hud_panel)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click()


func _handle_left_click() -> void:
	var crew := _pick_crew_at_mouse()
	# ak netrafíš postavu, crew bude null → tým pádom sa len zruší výber
	_set_selected(crew)


func _handle_right_click() -> void:
	if selected == null:
		return

	var mouse_world_pos := get_global_mouse_position()
	selected.command_move_to(mouse_world_pos)


func _set_selected(crew: CrewPawn) -> void:
	# crew môže byť null (klik na prázdny terén)
	if selected == crew:
		return

	# zruš highlight na starom
	if selected != null:
		selected.set_selected(false)

	# nastav nové selected (alebo null)
	selected = crew

	# zapni highlight na novom
	if selected != null:
		selected.set_selected(true)

	# update HUD
	if hud_panel != null:
		hud_panel.set_crew(selected)

	# debug logy – ale len keď je selected != null
	if DebugFlags.MASTER_DEBUG and DebugFlags.DEBUG_CREW:
		if selected != null:
			print("Selected crew:", selected.crew_id)
		else:
			print("Selected crew: none")


func _pick_crew_at_mouse() -> CrewPawn:
	var mouse_world_pos := get_global_mouse_position()

	var params := PhysicsPointQueryParameters2D.new()
	params.position = mouse_world_pos
	params.collide_with_areas = false
	params.collide_with_bodies = true

	var results := get_world_2d().direct_space_state.intersect_point(params, 32)

	for hit in results:
		var body = hit.collider
		if body is CrewPawn:
			return body

	return null
