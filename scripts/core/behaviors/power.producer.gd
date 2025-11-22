# res://scripts/core/behaviors/power_producer.gd
extends Node
## PowerProducer – komponent pre budovy, ktoré generujú energiu (napr. solárny panel).
## Čisto logická vrstva – žiadne UI, len čísla.

@export var production_per_hour: float = 5.0
# do budúcna: modifikátory (poškodenie, noc/deň, počasie, ...)

func _ready() -> void:
    # priradíme node do skupiny, aby ho EnergySystem vedel nájsť
    add_to_group("power_producers")


func get_production_per_hour() -> float:
    ## Vráti aktuálnu produkciu na 1 hernú hodinu.
    return max(production_per_hour, 0.0)
