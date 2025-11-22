extends Node
## test_placement.gd
## Jednoduchý debug/test script pre PlacementService + GhostService.
## NIE JE POTREBNÝ pre normálny gameplay – node môžeš mať v samostatnej
## test scéne alebo úplne vypnutý.

func _ready() -> void:
	# Demo test ResourceManageru
	ResourceManager.set_amount(ResourceManager.RESOURCE_WATER, 100.0)
	ResourceManager.add_amount(ResourceManager.RESOURCE_WATER, -30.0)

	var has_enough: bool = ResourceManager.can_consume(ResourceManager.RESOURCE_WATER, 50.0)
	print("Has enough water for 50? ", has_enough)

	if has_enough:
		ResourceManager.consume(ResourceManager.RESOURCE_WATER, 50.0)

	print("Water after consume: ", ResourceManager.get_amount(ResourceManager.RESOURCE_WATER))

