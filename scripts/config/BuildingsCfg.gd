extends Node
class_name BuildingsCfg

## Data-driven konfigurácia všetkých building typov v hre.
##
## Kľúče v definícii jednej budovy:
## - id: String                    # interný identifikátor
## - display_name: String          # text do UI
## - domain: String                # "exterior" | "interior"
## - footprint_type: String        # "fixed" | "rect_drag" | "path"
## - anchor_type: String           # "free" | "on_resource_node" | "on_foundation" | "inside_room" ...
## - size_cells: Vector2i          # základný tile footprint (môže byť 1x1 pre rect_drag)
## - pivot_cell: Vector2i          # ukotvenie v rámci footprintu
## - placement_rules: Array[String]# mená pravidiel, ktoré rieši PlacementService
## - time_mode: String             # napr. "game_hours" (napojené na GameClock)
## - build_time: float             # základný čas výstavby
## - cost: Dictionary              # resource_id -> množstvo
## - behaviors: Array[Dictionary]  # zoznam behavior modulov (type + config)

const BUILDINGS: Dictionary = {
    "foundation_basic": {
        "id": "foundation_basic",
        "display_name": "Basic Foundation",
        "domain": "exterior",
        "footprint_type": "rect_drag",
        "anchor_type": "free",
        "size_cells": Vector2i(1, 1),
        "pivot_cell": Vector2i(0, 0),
        "placement_rules": [
            "FreeArea",
        ],
        "time_mode": "game_hours",
        "build_time": 1.0,
        "cost": {
            # TODO: doplniť reálne resource cost v 0.0.42+
        },
        "behaviors": [
            # TODO: foundation zatiaľ bez špeciálneho správania
        ],
    },

    "bm_extractor": {
        "id": "bm_extractor",
        "display_name": "BM Extractor",
        "domain": "exterior",
        "footprint_type": "fixed",
        "anchor_type": "on_resource_node",
        "size_cells": Vector2i(2, 2),  # placeholder, upresníme neskôr
        "pivot_cell": Vector2i(0, 1),  # placeholder, podľa grafiky
        "placement_rules": [
            "FreeArea",
            "OnResourceNode",
            "NoExtractorPresent",
        ],
        "time_mode": "game_hours",
        "build_time": 4.0,  # placeholder
        "cost": {
            # TODO: doplniť reálne resource cost v 0.0.42+
        },
        "behaviors": [
            # TODO: doplniť v 0.0.45 (ProductionHourly, PowerConsumer)
        ],
    },

    "solar_panel": {
        "id": "solar_panel",
        "display_name": "Solar Panel",
        "domain": "exterior",
        "footprint_type": "fixed",
        "anchor_type": "free", # neskôr možno "on_foundation"
        "size_cells": Vector2i(2, 1),  # placeholder
        "pivot_cell": Vector2i(0, 0),  # placeholder
        "placement_rules": [
            "FreeArea",
        ],
        "time_mode": "game_hours",
        "build_time": 2.0,  # placeholder
        "cost": {
            # TODO
        },
        "behaviors": [
            # TODO: PowerProducer v 0.0.45+
        ],
    },

    "power_cable": {
        "id": "power_cable",
        "display_name": "Power Cable",
        "domain": "exterior",
        "footprint_type": "path",
        "anchor_type": "free",
        "size_cells": Vector2i(1, 1),
        "pivot_cell": Vector2i(0, 0),
        "placement_rules": [
            "FreeArea",
        ],
        "time_mode": "game_hours",
        "build_time": 0.1,  # veľmi rýchla výstavba, placeholder
        "cost": {
            # TODO
        },
        "behaviors": [
            # TODO: PowerLink / network behavior v 0.0.5+
        ],
    },

    "room_basic": {
        "id": "room_basic",
        "display_name": "Basic Room",
        "domain": "interior",
        "footprint_type": "rect_drag",
        "anchor_type": "on_foundation",
        "size_cells": Vector2i(1, 1),  # unit tile pre rect_drag
        "pivot_cell": Vector2i(0, 0),
        "placement_rules": [
            "OnFoundation",
            "FreeArea",
        ],
        "time_mode": "game_hours",
        "build_time": 3.0,  # placeholder
        "cost": {
            # TODO
        },
        "behaviors": [
            # TODO: room-level behavior (life support, comfort, ...)
        ],
    },
}


static func get_building(id: String) -> Dictionary:
    ## Vráti konfiguráciu budovy podľa id.
    ## Ak id neexistuje, vráti prázdny Dictionary.
    return BUILDINGS.get(id, {})


static func get_all_ids() -> PackedStringArray:
    ## Vráti zoznam všetkých definovaných building id.
    var ids: PackedStringArray = []
    for key in BUILDINGS.keys():
        ids.append(str(key))
    return ids
