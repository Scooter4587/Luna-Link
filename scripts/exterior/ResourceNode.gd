extends Node2D
class_name ResourceNode
## ResourceNode
## - Fyzický uzol na mape, ktorý reprezentuje ložisko (regolith, ice, He-3...).
## - Konfigurácia ide primárne cez ResourceNodeCfg (node_id).
## - Vie:
##   - aký resource produkuje (get_resource_id)
##   - koľko/hodinu pri jednom extraktore (get_output_per_hour)
##   - vrátiť dictionary pre GameState.get_hourly_production (get_hourly_output).

@export var node_id: StringName = &"regolith_small"
@export var extractor_path: NodePath = NodePath("")

## Tieto dve exportované premenné slúžia hlavne na náhľad v Inspectore.
## Reálna logika používa ResourceNodeCfg → get_resource_id()/get_output_per_hour().
@export var resource_id: StringName = &"building_materials"
@export var output_per_hour: float = 5.0

var _def: Dictionary = {}
var depleted: bool = false        ## do budúcna (limitované ložiská)
var has_extractor: bool = false   ## či už je na tomto node extractor (alebo rozostavaný)


func _ready() -> void:
	## Načíta definíciu z ResourceNodeCfg podľa node_id a pridá sa do groupy resource_nodes.
	_def = ResourceNodeCfg.get_def(node_id)
	if _def.is_empty():
		push_error("[ResourceNode] Unknown node_id: " + str(node_id))
		return

	add_to_group("resource_nodes")

	# Zosúladíme exportované polia s konfiguráciou, nech v Inspectore vidíš reálne hodnoty.
	resource_id = get_resource_id()
	output_per_hour = get_output_per_hour()

	var display_name: String = _def.get("display_name", str(node_id))

	if DebugFlags.MASTER_DEBUG and DebugFlags.DEBUG_BM_EXTRACTOR_LOGS:
		print("[ResourceNode] ready id=", node_id,
			" name=", display_name,
			" resource=", resource_id,
			" out/h=", output_per_hour)


func get_resource_id() -> StringName:
	## Resource id, ktorý node produkuje (napr. &"building_materials").
	if _def.is_empty():
		return StringName()
	return StringName(_def.get("resource_id", StringName()))


func get_output_per_hour() -> float:
	## Output za hodinu pre jeden extraktor na tomto node.
	if _def.is_empty():
		return 0.0
	var base: float = float(_def.get("base_output_per_hour", 0.0))
	var rich: float = float(_def.get("richness", 1.0))
	return base * rich


func has_remaining() -> bool:
	## Do budúcna – keď pridáme remaining_amount, bude to reálna logika.
	return not depleted


func get_hourly_output() -> Dictionary:
	## Používa GameState.get_hourly_production():
	## - vráti { resource_id: output_per_hour } alebo {} ak je node neaktívny.
	var res: StringName = get_resource_id()
	var amt: float = get_output_per_hour()

	if res == StringName() or amt <= 0.0 or depleted:
		return {}

	return {
		res: amt
	}
