# res://scripts/core/behaviors/power_consumer.gd
extends Node
## PowerConsumer – komponent pre budovy, ktoré energiu spotrebúvajú.

signal power_state_changed(is_powered: bool)

@export var consumption_per_hour: float = 2.0
## do budúcna na priority (napr. vypínať menej dôležité budovy ako prvé)
@export var critical: bool = true  

var is_powered: bool = false:
    set(value):
        if is_powered == value:
            return
        is_powered = value
        power_state_changed.emit(is_powered)

func _ready() -> void:
    add_to_group("power_consumers")


func get_consumption_per_hour() -> float:
    ## Vráti spotrebu na 1 hernú hodinu, bez ohľadu na to, či je práve powered.
    return max(consumption_per_hour, 0.0)


func set_powered(powered: bool) -> void:
    ## Helper – ak nechceš siahať na property priamo.
    is_powered = powered
