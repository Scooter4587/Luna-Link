extends Node

## Jednoduchý debug/test script.
## NIE JE POTREBNÝ pre normálny gameplay.
## Štandardne ho môžeš mať pripojený na World.tscn – keď je
## DebugFlags.MASTER_DEBUG a DEBUG_STARTING_RESOURCES = true,
## pridá štartovacie resources.

func _is_debug_enabled() -> bool:
	return DebugFlags.MASTER_DEBUG and DebugFlags.DEBUG_STARTING_RESOURCES


func _ready() -> void:
	if not _is_debug_enabled():
		# Debug režim vypnutý → tento node nepotrebujeme.
		queue_free()
		return

	# Demo test ResourceManageru
	ResourceManager.set_amount(ResourceManager.RESOURCE_ENERGY, 50.0)
	ResourceManager.add_amount(ResourceManager.RESOURCE_WATER, 10.0)

	# Štartovacie suroviny na testovanie stavby:
	ResourceManager.add_amount(&"building_materials", 500.0)
	ResourceManager.add_amount(&"equipment", 100.0)

	# prípadne aj trochu vody/energie, ak chceš testovať survival veci:
	ResourceManager.set_amount(&"water", 50.0)
	ResourceManager.set_amount(&"food", 20.0)

	print("[DebugUI] Applied starting debug resources (DebugFlags.DEBUG_STARTING_RESOURCES).")
