extends Control
class_name RightPanelUI

## -------------------------------------------------------
## RightPanelUI
##
## Úloha:
## - Zobrazuje základné "survival" resource hodnoty:
##   energia, voda, kyslík, jedlo.
## - Číta priamo z GameState (autoload State).
## - Resource id musia existovať v ResourceCfg.
## -------------------------------------------------------

const RES_ENERGY: StringName = &"energy"
const RES_WATER: StringName = &"water"
const RES_OXYGEN: StringName = &"oxygen_units"
const RES_FOOD: StringName   = &"food"

@onready var lbl_energy: Label = $MarginContainer/SurvivalStats/Lbl_Energy
@onready var lbl_water: Label = $MarginContainer/SurvivalStats/Lbl_Water
@onready var lbl_oxygen: Label = $MarginContainer/SurvivalStats/Lbl_Oxygen
@onready var lbl_food: Label = $MarginContainer/SurvivalStats/Lbl_Food


func _ready() -> void:
	## Pri štarte:
	## - napojíme sa na signál State.resource_changed
	## - inicializujeme texty podľa aktuálnych hodnôt
	if not State.resource_changed.is_connected(_on_resource_changed):
		State.resource_changed.connect(_on_resource_changed)

	_refresh_all_survival_stats()


func _refresh_all_survival_stats() -> void:
	## Prečíta všetky dôležité resource z GameState
	## a prepíše texty v labeloch.

	var energy: float = State.get_resource(RES_ENERGY)
	lbl_energy.text = "⚡ " + str(int(round(energy)))

	var water: float = State.get_resource(RES_WATER)
	lbl_water.text = "💧 " + str(int(round(water)))

	var oxy: float = State.get_resource(RES_OXYGEN)
	lbl_oxygen.text = "O₂ " + str(int(round(oxy)))

	var food: float = State.get_resource(RES_FOOD)
	lbl_food.text = "🍽 " + str(int(round(food)))


func _on_resource_changed(resource_id: StringName, new_amount: float, _delta: float) -> void:
	## Callback zo strany GameState.
	## Aktualizuje len ten label, ktorého sa zmena týka.
	match resource_id:
		RES_ENERGY:
			lbl_energy.text = "⚡ " + str(int(round(new_amount)))
		RES_WATER:
			lbl_water.text = "💧 " + str(int(round(new_amount)))
		RES_OXYGEN:
			lbl_oxygen.text = "O₂ " + str(int(round(new_amount)))
		RES_FOOD:
			lbl_food.text = "🍽 " + str(int(round(new_amount)))
		_:
			pass
