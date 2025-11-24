extends Node

## Jednoduchý debug/test script.
## NIE JE POTREBNÝ pre normálny gameplay – node môžeš mať v samostatnej
## Štandardne ho pripojíš na world.tscn.

func _ready() -> void:
    # Demo test ResourceManageru
    ResourceManager.set_amount(ResourceManager.RESOURCE_ENERGY, 50.0)
    ResourceManager.add_amount(ResourceManager.RESOURCE_WATER, 10.0)

    # Štartovacie suroviny na testovanie stavby:
    ResourceManager.add_amount(&"building_materials", 500.0)
    ResourceManager.add_amount(&"equipment", 100.0)

    # prípadne aj trochu vody/energie, ak chceš testovať survival veci:
    ResourceManager.set_amount(&"water", 50.0)
    ResourceManager.set_amount(&"food", 20.0)
