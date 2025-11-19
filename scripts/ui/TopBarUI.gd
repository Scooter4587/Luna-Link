extends Control
class_name TopBarUI
# TopBarUI: horný panel podobný Stellaris UI.
# Zobrazuje:
# - zľava: Base Build resources
# - v strede: Special (innovations, energy for Earth)
# - sprava: Crew needs
# - úplne vpravo: čas a ovládanie rýchlosti (pause, 1x, 2x, 4x)

# --- UI referencie: Base Build ------------------------------------------------
@onready var lbl_building_materials: Label = $Panel/RootHBox/BaseBuildGroup/Lbl_BuildingMaterials
@onready var lbl_equipment: Label = $Panel/RootHBox/BaseBuildGroup/Lbl_Equipment
@onready var lbl_helium_raw: Label = $Panel/RootHBox/BaseBuildGroup/Lbl_HeliumRaw
@onready var lbl_helium3_refined: Label = $Panel/RootHBox/BaseBuildGroup/Lbl_Helium3Refined

# --- UI referencie: Special ---------------------------------------------------
@onready var lbl_innovations: Label = $Panel/RootHBox/SpecialGroup/Lbl_Innovations
@onready var lbl_earth_energy: Label = $Panel/RootHBox/SpecialGroup/Lbl_EarthEnergy

# --- UI referencie: Crew Needs -----------------------------------------------
@onready var lbl_water: Label = $Panel/RootHBox/CrewNeedsGroup/Lbl_Water
@onready var lbl_food: Label = $Panel/RootHBox/CrewNeedsGroup/Lbl_Food
@onready var lbl_happiness: Label = $Panel/RootHBox/CrewNeedsGroup/Lbl_Happiness
@onready var lbl_stress: Label = $Panel/RootHBox/CrewNeedsGroup/Lbl_Stress

# --- UI referencie: Time and speed -------------------------------------------
@onready var lbl_time: Label = $Panel/RootHBox/TimeGroup/Lbl_Time
@onready var lbl_date: Label = $Panel/RootHBox/TimeGroup/Lbl_Date
@onready var btn_pause: Button = $Panel/RootHBox/TimeGroup/Btn_Pause
@onready var btn_1x: Button = $Panel/RootHBox/TimeGroup/Btn_1x
@onready var btn_2x: Button = $Panel/RootHBox/TimeGroup/Btn_2x
@onready var btn_4x: Button = $Panel/RootHBox/TimeGroup/Btn_4x

const REAL_SECONDS_PER_GAME_HOUR: float = 2.0   # príklad
const HOURS_PER_DAY: int = 24
const DAYS_PER_MONTH: int = 30
const MONTH_NAMES: Array[String] = [
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December"
]
const SPEEDS := {
	"pause": 0.0,
	"x1": 1.0,
	"x2": 2.0,
	"x4": 4.0,
}

# Mapovanie resource id -> konkrétny Label v top bare.
var _resource_labels: Dictionary = {}

# Kratšie skratky pre zobrazenie v top bare.
var _resource_short_names: Dictionary = {
	&"building_materials": "BM",
	&"equipment": "EQ",
	&"helium_raw": "Raw He",
	&"helium3_refined": "He-3",
	&"innovations": "Innov",
	&"earth_energy": "EarthE",
	&"water": "Water",
	&"food": "Food",
	&"happiness": "Happy",
	&"stress": "Stress",
}


func _ready() -> void:
	_init_resource_label_map()
	_connect_signals()
	_refresh_all_resources()
	_refresh_clock_labels()
	_highlight_speed_button(Clock.get_time_speed_key())


# Nastaví slovník id -> Label podľa ResourceCfg.
func _init_resource_label_map() -> void:
	_resource_labels.clear()

	_resource_labels[&"building_materials"] = lbl_building_materials
	_resource_labels[&"equipment"] = lbl_equipment
	_resource_labels[&"helium_raw"] = lbl_helium_raw
	_resource_labels[&"helium3_refined"] = lbl_helium3_refined

	_resource_labels[&"innovations"] = lbl_innovations
	_resource_labels[&"earth_energy"] = lbl_earth_energy

	_resource_labels[&"water"] = lbl_water
	_resource_labels[&"food"] = lbl_food
	_resource_labels[&"happiness"] = lbl_happiness
	_resource_labels[&"stress"] = lbl_stress


# Pripojí sa na signály z GameState a GameClock a na tlačidlá rýchlosti.
func _connect_signals() -> void:
	# Resource zmeny
	State.resource_changed.connect(_on_resource_changed)

	# Čas – stačí nám minute_changed na update UI
	Clock.minute_changed.connect(_on_clock_minute_changed)

	# Časové rýchlosti
	btn_pause.pressed.connect(func() -> void:
		Clock.set_time_speed("pause")
		_highlight_speed_button("pause")
	)
	btn_1x.pressed.connect(func() -> void:
		Clock.set_time_speed("x1")
		_highlight_speed_button("x1")
	)
	btn_2x.pressed.connect(func() -> void:
		Clock.set_time_speed("x2")
		_highlight_speed_button("x2")
	)
	btn_4x.pressed.connect(func() -> void:
		Clock.set_time_speed("x4")
		_highlight_speed_button("x4")
	)


# -- Resource UI ---------------------------------------------------------------

# Aktualizuje všetky resource labely podľa aktuálneho stavu v GameState.
func _refresh_all_resources() -> void:
	for id in _resource_labels.keys():
		var value: float = State.get_resource(id)
		_update_resource_label(id as StringName, value)


# Handler na signál State.resource_changed.
func _on_resource_changed(id: StringName, new_value: float, _delta: float) -> void:
	_update_resource_label(id, new_value)


# Nastaví text labelu pre daný resource id.
func _update_resource_label(id: StringName, value: float) -> void:
	if not _resource_labels.has(id):
		# Resource existuje v GameState, ale nemá UI slot (napr. neskôr).
		return

	var label: Label = _resource_labels[id]
	var def: Dictionary = ResourceCfg.get_def(id)

	# Krátky názov do textu (BM, EQ...), dlhý názov do tooltipu.
	var short_name: String = _resource_short_names.get(id, def.get("display_name", str(id)))
	var full_name: String = def.get("display_name", str(id))
	var type_int: int = int(def.get("type", -1))

	var text: String = ""

	match type_int:
		ResourceCfg.ResourceType.STATUS:
			# Napr. Happiness / Stress 0..100
			var int_val: int = int(round(value))
			text = "%s: %d%%" % [short_name, int_val]

		_:
			# STOCK / PROGRESS – zobrazíme celé číslo
			var int_val2: int = int(round(value))
			text = "%s: %d" % [short_name, int_val2]

			# Špeciálny case: Building Materials – ukáž aj hourly delta
			if id == &"building_materials":
				var hourly: float = State.get_hourly_delta_for(&"building_materials")
				if abs(hourly) > 0.01:
					var sign_str := "+" if hourly > 0.0 else ""
					var hourly_int: int = int(round(hourly))
					text += " (%s%d/h)" % [sign_str, hourly_int]
	label.text = text

	# Tooltip – plný názov + základný popis z ResourceCfg.
	var tooltip: String = full_name
	var desc: String = def.get("tooltip", "")
	if desc != "":
		tooltip += "\n" + desc
	label.tooltip_text = tooltip


# -- Clock UI ------------------------------------------------------------------

# Handler na signál Clock.minute_changed – aktualizuje zobrazenie času a dátumu.
func _on_clock_minute_changed(_year: int, _month_index: int, _day: int, _hour: int, _minute: int) -> void:
	_refresh_clock_labels()


# Aktualizuje text času a dátumu z GameClock.
func _refresh_clock_labels() -> void:
	lbl_time.text = Clock.get_formatted_time()
	lbl_date.text = Clock.get_formatted_date()


# -- Rýchlosť času – vizuál tlačidiel -----------------------------------------

# Jednoduché zvýraznenie aktívneho tlačidla – ostatné odšedíme (disabled=false/true).
func _highlight_speed_button(active_key: String) -> void:
	btn_pause.disabled = false
	btn_1x.disabled = false
	btn_2x.disabled = false
	btn_4x.disabled = false

	match active_key:
		"pause":
			btn_pause.disabled = true
		"x1":
			btn_1x.disabled = true
		"x2":
			btn_2x.disabled = true
		"x4":
			btn_4x.disabled = true
		_:
			pass
