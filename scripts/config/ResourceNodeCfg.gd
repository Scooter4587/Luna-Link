extends Object
class_name ResourceNodeCfg
# ResourceNodeCfg: definície typov resource node-ov na povrchu
# (regolith, ice, He-3...). Zatiaľ máme len jeden typ: regolith_small.

const NODES: Dictionary = {
    &"regolith_small": {
        "display_name": "Regolith Deposit",
        "resource_id": &"building_materials",   # čo z node-u lezie
        "base_output_per_hour": 5.0,           # základná produkcia na extraktor
        "richness": 1.0,                       # multiplikátor bohatosti
        "max_amount": 1000.0,                  # zatiaľ nepoužívame, do budúcna
    },
}


static func get_def(id: Variant) -> Dictionary:
    var key: StringName = StringName(id)
    if not NODES.has(key):
        return {}
    return NODES[key]
