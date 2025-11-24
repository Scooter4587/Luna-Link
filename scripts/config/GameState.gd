extends Node
class_name GameState
## GameState:
## Drží runtime hodnoty všetkých globálnych zdrojov (top bar) podľa ResourceCfg
## a poskytuje API na pridávanie, míňanie a sledovanie zmien cez signal resource_changed.
##
## Dôležité:
## - GameState je "source of truth" pre globálne resourcy.
## - Všetky zmeny automaticky zrkadlí do ResourceManageru, aby
##   ProductionHourly / staršie systémy videli rovnaké hodnoty.

signal resource_changed(id: StringName, new_value: float, delta: float)

# Aktuálne hodnoty zdrojov: { id: value }
var resources: Dictionary = {}

## Inicializácia GameState – načítanie default hodnôt z ResourceCfg.
func _ready() -> void:
	_init_resources()
	# Debug log pôvodného systému
	print("[GameState] ready, resources initialized: ", resources)

	# Sync všetkých GameState resources do ResourceManageru.
	# Kľúčom sú StringName (&"…"), takže ResourceManager ich bez problémov preberie.
	_sync_resources_to_resource_manager()

## Skopíruje všetky hodnoty z GameState.resources do ResourceManageru.
## - Zatiaľ je to len "mirror".
## - Neskôr spravíme opačný smer, ak by sme prešli na ResourceManager ako hlavný zdroj pravdy.
func _sync_resources_to_resource_manager() -> void:
	for resource_id in resources.keys():
		var amount: float = resources[resource_id]
		ResourceManager.set_amount(resource_id, amount)

# -- Inicializácia ------------------------------------------------------------

## Vynuluje a znova naplní všetky resource podľa ResourceCfg.RESOURCES.
func _init_resources() -> void:
	resources.clear()

	for id in ResourceCfg.RESOURCES.keys():
		var def: Dictionary = ResourceCfg.RESOURCES[id]
		var initial_val: float = 0.0
		if def.has("initial"):
			initial_val = float(def["initial"])
		resources[id] = initial_val

	# Špeciálne defaulty pre status resource – ak nie sú v definícii.
	if resources.has(&"happiness") and resources[&"happiness"] <= 0.0:
		resources[&"happiness"] = 50.0
	if resources.has(&"stress") and resources[&"stress"] <= 0.0:
		resources[&"stress"] = 50.0

# -- Verejné API: čítanie -----------------------------------------------------

## Vráti aktuálnu hodnotu resource (float). Ak neexistuje, vráti 0.0.
func get_resource(id: Variant) -> float:
	var key: StringName = StringName(id)
	if not resources.has(key):
		return 0.0
	return float(resources[key])

## Bezpečná kontrola, či resource existuje v konfigurácii.
func has_resource(id: Variant) -> bool:
	var key: StringName = StringName(id)
	return not ResourceCfg.get_def(key).is_empty()

# -- Verejné API: zapisovanie -------------------------------------------------

## Nastaví resource na presnú hodnotu (clamp + signál + mirror do ResourceManager).
func set_resource(id: Variant, value: float) -> void:
	var key: StringName = StringName(id)
	if not has_resource(key):
		push_warning("[GameState] set_resource: unknown id: " + str(key))
		return

	var old_value: float = get_resource(key)
	var new_value: float = _apply_clamp(key, value)

	if is_equal_approx(old_value, new_value):
		return

	resources[key] = new_value

	# Mirror do ResourceManager – aby všetky systémy videli rovnakú hodnotu.
	ResourceManager.set_amount(key, new_value)

	emit_signal("resource_changed", key, new_value, new_value - old_value)

## Pridá alebo uberie hodnotu (amount môže byť záporné).
## Uplatní clamp + mirror do ResourceManager.
func add_resource(id: Variant, amount: float) -> void:
	if amount == 0.0:
		return

	var key: StringName = StringName(id)
	if not has_resource(key):
		push_warning("[GameState] add_resource: unknown id: " + str(key))
		return

	var old_value: float = get_resource(key)
	var def: Dictionary = ResourceCfg.get_def(key)

	var new_value: float = old_value + amount

	var can_go_negative: bool = bool(def.get("can_go_negative", false))
	if not can_go_negative and new_value < 0.0:
		new_value = 0.0

	new_value = _apply_clamp(key, new_value)

	if is_equal_approx(old_value, new_value):
		return

	resources[key] = new_value

	# Mirror do ResourceManager.
	ResourceManager.set_amount(key, new_value)

	emit_signal("resource_changed", key, new_value, new_value - old_value)

## Vráti, či si môžeme dovoliť minúť dané množstvo daného resource.
func can_spend(id: Variant, amount: float) -> bool:
	if amount <= 0.0:
		return true

	var key: StringName = StringName(id)
	if not has_resource(key):
		return false

	var def: Dictionary = ResourceCfg.get_def(key)
	var current: float = get_resource(key)

	var can_go_negative: bool = bool(def.get("can_go_negative", false))
	if can_go_negative:
		return true

	return current >= amount

## Pokúsi sa minúť dané množstvo. Vráti true ak sa podarilo.
func spend_resource(id: Variant, amount: float) -> bool:
	if amount <= 0.0:
		return true

	if not can_spend(id, amount):
		return false

	add_resource(id, -amount)
	return true

# -- Vnútorné pomocné funkcie -------------------------------------------------

## Aplikuje min/max clamp podľa definície v ResourceCfg (pre STATUS typy).
func _apply_clamp(id: StringName, value: float) -> float:
	var def: Dictionary = ResourceCfg.get_def(id)
	if def.is_empty():
		return value

	if def.get("type", -1) == ResourceCfg.ResourceType.STATUS:
		var min_v: float = float(def.get("min_value", 0.0))
		var max_v: float = float(def.get("max_value", 100.0))
		return clamp(value, min_v, max_v)

	return value

## Overí, či máme dosť každého resource na zaplatenie cost slovníka.
func can_afford(cost: Dictionary) -> bool:
	for id in cost.keys():
		var need: float = float(cost[id])
		if get_resource(id) < need:
			return false
	return true

## Odpíše zdroje podľa cost slovníka (bez kontroly stavu).
func apply_cost(cost: Dictionary) -> void:
	for id in cost.keys():
		var need: float = float(cost[id])
		add_resource(id, -need)

## Skúsi odpísať zdroje podľa cost; vráti true/false podľa úspechu.
func try_spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	apply_cost(cost)
	return true

## Spočíta hodinovú produkciu všetkých BM extractorov:
## prejde group "bm_extractors", z každého vytiahne linked ResourceNode
## a jeho get_hourly_output(), všetko zráta do jedného Dictionary.
func get_hourly_production() -> Dictionary:
	var totals: Dictionary = {}

	var extractors: Array[Node] = get_tree().get_nodes_in_group("bm_extractors")

	for node: Node in extractors:
		if not node.has_method("get_linked_node"):
			continue

		var linked: Node = node.get_linked_node()
		if linked == null:
			continue
		if not linked.has_method("get_hourly_output"):
			continue

		var out_dict: Dictionary = linked.get_hourly_output()
		for key in out_dict.keys():
			var res_id: StringName = key as StringName
			var value: float = float(out_dict[res_id])
			var prev: float = float(totals.get(res_id, 0.0))
			totals[res_id] = prev + value

	return totals

## Vráti hodinový delta pre konkrétny resource (napr. building_materials).
func get_hourly_delta_for(resource_id: StringName) -> float:
	var totals: Dictionary = get_hourly_production()
	return float(totals.get(resource_id, 0.0))
