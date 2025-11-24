extends Control

## -------------------------------------------------------
## RightPanelUI
##
## Úloha:
## - Zobrazuje základné "survival" resource hodnoty:
##   energia, voda, kyslík, jedlo.
## - Číta priamo z ResourceManageru.
## -------------------------------------------------------

@onready var lbl_energy: Label = $MarginContainer/SurvivalStats/Lbl_Energy
@onready var lbl_water: Label = $MarginContainer/SurvivalStats/Lbl_Water
@onready var lbl_oxygen: Label = $MarginContainer/SurvivalStats/Lbl_Oxygen
@onready var lbl_food: Label = $MarginContainer/SurvivalStats/Lbl_Food


func _ready() -> void:
	## Pri štarte:
	## - napojíme sa na signál ResourceManageru
	## - inicializujeme všetky texty podľa aktuálnych hodnôt
	if not ResourceManager.resource_changed.is_connected(_on_resource_changed):
		ResourceManager.resource_changed.connect(_on_resource_changed)

	_refresh_all_survival_stats()


func _refresh_all_survival_stats() -> void:
	## Prečíta všetky dôležité resource z ResourceManageru
	## a prepíše texty v labeloch.

	var energy: float = ResourceManager.get_amount(ResourceManager.RESOURCE_ENERGY)
	lbl_energy.text = "⚡ " + str(round(energy))

	var water: float = ResourceManager.get_amount(ResourceManager.RESOURCE_WATER)
	lbl_water.text = "💧 " + str(round(water))

	var oxy: float = ResourceManager.get_amount(ResourceManager.RESOURCE_OXYGEN)
	lbl_oxygen.text = "O₂ " + str(round(oxy))

	var food: float = ResourceManager.get_amount(ResourceManager.RESOURCE_FOOD)
	lbl_food.text = "🍽 " + str(round(food))


func _on_resource_changed(resource_id: StringName, new_amount: float) -> void:
	## Callback zo strany ResourceManageru.
	## Aktualizuje len ten label, ktorého sa zmena týka.
	match resource_id:
		ResourceManager.RESOURCE_ENERGY:
			lbl_energy.text = "⚡ " + str(round(new_amount))
		ResourceManager.RESOURCE_WATER:
			lbl_water.text = "💧 " + str(round(new_amount))
		ResourceManager.RESOURCE_OXYGEN:
			lbl_oxygen.text = "O₂ " + str(round(new_amount))
		ResourceManager.RESOURCE_FOOD:
			lbl_food.text = "🍽 " + str(round(new_amount))
		_:
			pass
