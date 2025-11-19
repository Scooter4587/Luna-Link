extends Object
class_name ResourceNodeCfg
## ResourceNodeCfg:
## Definície typov surface resource node-ov (regolith, ice, He-3...).
## Každý ResourceNode si podľa id načíta svoju definíciu odtiaľto.

const NODES: Dictionary = {
	&"regolith_small": {
		"display_name": "Regolith Deposit",
		"resource_id": &"building_materials", # čo z node-u lezie
		"base_output_per_hour": 5.0,          # základná produkcia na extraktor
		"richness": 1.0,                      # multiplikátor bohatosti
		"max_amount": 1000.0,                 # zatiaľ nepoužívané, do budúcna
	},
}

## Vráti definíciu node typu podľa id (alebo prázdny Dictionary, ak neexistuje).
static func get_def(id: Variant) -> Dictionary:
	var key: StringName = StringName(id)
	if not NODES.has(key):
		return {}
	return NODES[key]
