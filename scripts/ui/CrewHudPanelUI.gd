extends Control
class_name CrewHudPanelUI

var current_crew: CrewPawn = null

var name_label: Label
var status_label: Label
var o2_label: Label
var hunger_label: Label
var sleep_label: Label


func _ready() -> void:
	print("CrewHudPanelUI ready on node:", get_path())

	name_label = find_child("CrewNameLabel", true, false) as Label
	status_label = find_child("CrewStatusLabel", true, false) as Label
	o2_label = find_child("O2Label", true, false) as Label
	hunger_label = find_child("HungerLabel", true, false) as Label
	sleep_label = find_child("SleepLabel", true, false) as Label

	if name_label == null:
		push_error("CrewHudPanelUI: CrewNameLabel not found under %s" % name)
	if status_label == null:
		push_error("CrewHudPanelUI: CrewStatusLabel not found under %s" % name)
	if o2_label == null:
		push_error("CrewHudPanelUI: O2Label not found under %s" % name)
	if hunger_label == null:
		push_error("CrewHudPanelUI: HungerLabel not found under %s" % name)
	if sleep_label == null:
		push_error("CrewHudPanelUI: SleepLabel not found under %s" % name)

	_clear()


func set_crew(crew: CrewPawn) -> void:
	current_crew = crew
	_refresh()


func _process(_delta: float) -> void:
	if current_crew != null:
		_refresh()
	else:
		_clear()


func _refresh() -> void:
	if current_crew == null:
		_clear()
		return

	if name_label == null:
		return

	name_label.text = "%s (#%d)" % [
		current_crew.display_name,
		current_crew.crew_id,
	]

	var status_text := "Idle"
	if current_crew.status == CrewPawn.Status.MOVING:
		status_text = "Moving"
	elif current_crew.status == CrewPawn.Status.WORKING:
		status_text = "Working"
	elif current_crew.status == CrewPawn.Status.EATING:
		status_text = "Eating"
	elif current_crew.status == CrewPawn.Status.SLEEPING:
		status_text = "Sleeping"
	elif current_crew.status == CrewPawn.Status.RELAXING:
		status_text = "Relaxing"
	elif current_crew.status == CrewPawn.Status.DEAD:
		status_text = "Dead"

	if status_label != null:
		status_label.text = "Status: %s" % status_text

	if o2_label != null:
		o2_label.text = "O2: %.2f" % current_crew.needs["oxygen"]
	if hunger_label != null:
		hunger_label.text = "Hunger: %.2f" % current_crew.needs["hunger"]
	if sleep_label != null:
		sleep_label.text = "Sleep: %.2f" % current_crew.needs["sleep"]



func _clear() -> void:
	if name_label != null:
		name_label.text = "No crew selected"
	if status_label != null:
		status_label.text = ""
	if o2_label != null:
		o2_label.text = ""
	if hunger_label != null:
		hunger_label.text = ""
	if sleep_label != null:
		sleep_label.text = ""
