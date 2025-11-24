extends Node

## Jednoduchý debug/test script.
## NIE JE POTREBNÝ pre normálny gameplay – node môžeš mať v samostatnej
## Štandardne ho pripojíš na world.tscn.

func _ready() -> void:
    # Demo test ResourceManageru
    ResourceManager.set_amount(ResourceManager.RESOURCE_ENERGY, 50.0)
    ResourceManager.add_amount(ResourceManager.RESOURCE_WATER, 10.0)
