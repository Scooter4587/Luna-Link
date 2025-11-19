extends RefCounted
class_name ResourceCfg
## ResourceCfg:
## Dátová definícia všetkých globálnych zdrojov pre top bar.
## - nerieši logiku, iba názvy, kategórie, popisy a poradie v UI.

# Skupiny pre UI (ľavá časť, stred, pravá časť).
enum ResourceCategory {
	BASE_BUILD,
	SPECIAL,
	CREW_NEEDS,
}

# Typ správania sa resource (ako ho budeme používať v logike).
enum ResourceType {
	STOCK,      # klasický skladovaný resource (water, food, building_materials...)
	STATUS,     # ukazovatele 0..100 (happiness, stress)
	PROGRESS,   # kumulatívne / progresové hodnoty (earth_energy, innovations)
}

# Poradie v UI – Base Build blok (zľava).
const ORDER_BASE_BUILD: Array[StringName] = [
	&"building_materials",
	&"equipment",
	&"helium_raw",
	&"helium3_refined",
]

# Poradie v UI – Special blok (stred).
const ORDER_SPECIAL: Array[StringName] = [
	&"innovations",
	&"earth_energy",
]

# Poradie v UI – Crew Needs blok (vpravo).
const ORDER_CREW_NEEDS: Array[StringName] = [
	&"water",
	&"food",
	&"happiness",
	&"stress",
]

# Hlavný zoznam všetkých resource definícií.
# Kľúč = interný id (StringName), hodnota = Dictionary s parametrami.
const RESOURCES: Dictionary = {
	# --- BASE BUILD ----------------------------------------------------------
	&"building_materials": {
		"display_name": "Building Materials",
		"category": ResourceCategory.BASE_BUILD,
		"type": ResourceType.STOCK,
		"icon": "",
		"tooltip": "Universal construction material for lunar structures.",
		"can_go_negative": false,
		"initial": 2000.0,
	},

	&"equipment": {
		"display_name": "Equipment",
		"category": ResourceCategory.BASE_BUILD,
		"type": ResourceType.STOCK,
		"icon": "",
		"tooltip": "Tools, furniture and maintenance hardware for colony facilities.",
		"can_go_negative": false,
		"initial": 100.0,
	},

	&"helium_raw": {
		"display_name": "Raw Helium Ore",
		"category": ResourceCategory.BASE_BUILD,
		"type": ResourceType.STOCK,
		"icon": "",
		"tooltip": "Lunar regolith enriched with Helium-3, freshly mined.",
		"can_go_negative": false,
	},

	&"helium3_refined": {
		"display_name": "Refined Helium-3",
		"category": ResourceCategory.BASE_BUILD,
		"type": ResourceType.STOCK,
		"icon": "",
		"tooltip": "Processed Helium-3, ready to be shipped back to Earth.",
		"can_go_negative": false,
	},

	# --- SPECIAL (STRED) -----------------------------------------------------
	&"innovations": {
		"display_name": "Innovations",
		"category": ResourceCategory.SPECIAL,
		"type": ResourceType.PROGRESS,
		"icon": "",
		"tooltip": "Abstract research and engineering progress used to unlock new tech.",
		"can_go_negative": false,
	},

	&"earth_energy": {
		"display_name": "Energy for Earth",
		"category": ResourceCategory.SPECIAL,
		"type": ResourceType.PROGRESS,
		"icon": "",
		"tooltip": "Total fusion energy delivered back to Earth from this lunar project.",
		"can_go_negative": false,
	},

	# --- CREW NEEDS ----------------------------------------------------------
	&"water": {
		"display_name": "Water",
		"category": ResourceCategory.CREW_NEEDS,
		"type": ResourceType.STOCK,
		"icon": "",
		"tooltip": "Potable and technical water used by the crew and infrastructure.",
		"can_go_negative": false,
	},

	&"food": {
		"display_name": "Food",
		"category": ResourceCategory.CREW_NEEDS,
		"type": ResourceType.STOCK,
		"icon": "",
		"tooltip": "Nutrition supply for all personnel on the Moon.",
		"can_go_negative": false,
	},

	&"happiness": {
		"display_name": "Happiness",
		"category": ResourceCategory.CREW_NEEDS,
		"type": ResourceType.STATUS,
		"icon": "",
		"tooltip": "Overall morale and satisfaction level of the crew.",
		"can_go_negative": false,
		"min_value": 0.0,
		"max_value": 100.0,
	},

	&"stress": {
		"display_name": "Stress",
		"category": ResourceCategory.CREW_NEEDS,
		"type": ResourceType.STATUS,
		"icon": "",
		"tooltip": "Accumulated psychological pressure; too high means trouble.",
		"can_go_negative": false,
		"min_value": 0.0,
		"max_value": 100.0,
	},
}

## Vráti definíciu resource podľa id (alebo prázdny Dictionary, ak neexistuje).
static func get_def(id: StringName) -> Dictionary:
	return RESOURCES.get(id, {})

## Vráti zoznam všetkých id (ako Array[StringName]).
static func get_all_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in RESOURCES.keys():
		out.append(id as StringName)
	return out

## Vráti, či má daný resource typ STATUS (0..100 ukazovatele).
static func is_status(id: StringName) -> bool:
	var def: Dictionary = get_def(id)
	if def.is_empty():
		return false
	return def.get("type", -1) == ResourceType.STATUS

## Zistí kategóriu daného resource (alebo -1, ak nie je nájdený).
static func get_category(id: StringName) -> int:
	var def: Dictionary = get_def(id)
	return int(def.get("category", -1))

## Vráti UI poradie pre jednotlivé skupiny.
static func get_ui_order_for_category(category: int) -> Array[StringName]:
	match category:
		ResourceCategory.BASE_BUILD:
			return ORDER_BASE_BUILD
		ResourceCategory.SPECIAL:
			return ORDER_SPECIAL
		ResourceCategory.CREW_NEEDS:
			return ORDER_CREW_NEEDS
		_:
			return []
