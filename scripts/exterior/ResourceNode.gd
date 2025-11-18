extends Node2D
class_name ResourceNode
# ResourceNode: fyzický uzol na mape, ktorý reprezentuje ložisko
# (napr. regolith). Vie, aký je typ, aký resource produkuje a
# aký má output za hodinu pri jednom extraktore.

@export var node_id: StringName = &"regolith_small"
@export var extractor_path: NodePath = NodePath("")

var _def: Dictionary = {}
var depleted: bool = false        # do budúcna, zatiaľ len flag
var has_extractor: bool = false   # či už je na tomto node postavený extractor


func _ready() -> void:
    _def = ResourceNodeCfg.get_def(node_id)
    if _def.is_empty():
        push_error("[ResourceNode] Unknown node_id: " + str(node_id))
        return

    add_to_group("resource_nodes")

    var output_per_hour: float = get_output_per_hour()
    var res_id: StringName = get_resource_id()
    var display_name: String = _def.get("display_name", str(node_id))

    print("[ResourceNode] ready id=", node_id,
        " name=", display_name,
        " resource=", res_id,
        " out/h=", output_per_hour)


# Vráti resource_id, ktorý node produkuje (napr. building_materials).
func get_resource_id() -> StringName:
    if _def.is_empty():
        return StringName()
    return StringName(_def.get("resource_id", StringName()))


# Vráti output za hodinu pre jeden extraktor na tomto node.
func get_output_per_hour() -> float:
    if _def.is_empty():
        return 0.0
    var base: float = float(_def.get("base_output_per_hour", 0.0))
    var rich: float = float(_def.get("richness", 1.0))
    return base * rich


# Do budúcna – ak budeme sledovať remaining_amount.
func has_remaining() -> bool:
    return not depleted
