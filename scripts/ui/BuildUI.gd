extends Control
class_name BuildUI

## BuildUI: jednoduchý panel na výber budovy.
## Spodný riadok = kategórie (Foundation / Exterior / Interior / Objects)
## Horný riadok = konkrétne budovy podľa kategórie (foundation, extractor, solar, rooms, ...)

signal building_selected(building_id: String)

enum Category {
	FOUNDATION,
	EXTERIOR,
	INTERIOR,
	OBJECTS,
}

var _current_category: int = Category.FOUNDATION
var _all_buildings: Dictionary = {}

var _btn_foundation: Button
var _btn_exterior: Button
var _btn_interior: Button
var _btn_objects: Button

var _selection_scroll: ScrollContainer
var _selection_container: HBoxContainer
var _selected_building_button: Button = null


func _ready() -> void:
	# nájdeme nody podľa názvov v scene tree
	_btn_foundation = find_child("FoundationButton", true, false) as Button
	_btn_exterior   = find_child("ExteriorButton",   true, false) as Button
	_btn_interior   = find_child("InteriorButton",   true, false) as Button
	_btn_objects    = find_child("ObjectsButton",    true, false) as Button

	_selection_scroll    = find_child("SelectionScroll",    true, false) as ScrollContainer
	_selection_container = find_child("SelectionContainer", true, false) as HBoxContainer

	# bezpečnostná kontrola
	if not _btn_foundation or not _btn_exterior or not _btn_interior or not _btn_objects:
		push_error("[BuildUI] Chýbajú kategórie (Foundation/Exterior/Interior/Objects). Skontroluj názvy Buttonov.")
		hide()
		return

	if not _selection_scroll or not _selection_container:
		push_error("[BuildUI] Chýba SelectionScroll alebo SelectionContainer.")
		hide()
		return

	# toggle mód na kategóriach
	for b in [_btn_foundation, _btn_exterior, _btn_interior, _btn_objects]:
		b.toggle_mode = true

	# načítame všetky building definície
	_load_all_buildings()

	# pripojíme signály kategórií
	_btn_foundation.pressed.connect(func(): _on_category_pressed(Category.FOUNDATION))
	_btn_exterior.pressed.connect(func(): _on_category_pressed(Category.EXTERIOR))
	_btn_interior.pressed.connect(func(): _on_category_pressed(Category.INTERIOR))
	_btn_objects.pressed.connect(func(): _on_category_pressed(Category.OBJECTS))

	# default: Foundation
	_current_category = Category.FOUNDATION
	_update_category_buttons()
	_refresh_selection_buttons()


func _load_all_buildings() -> void:
	_all_buildings.clear()
	var ids := BuildingsCfg.get_all_ids()
	for id in ids:
		var cfg: Dictionary = BuildingsCfg.get_building(id)
		if cfg.is_empty():
			continue
		_all_buildings[id] = cfg


func _on_category_pressed(cat: int) -> void:
	# ak klikneš znova na rovnakú kategóriu, necháme ju zapnutú (žiadne toggle off)
	_current_category = cat
	_update_category_buttons()
	_refresh_selection_buttons()


func _update_category_buttons() -> void:
	_btn_foundation.button_pressed = (_current_category == Category.FOUNDATION)
	_btn_exterior.button_pressed   = (_current_category == Category.EXTERIOR)
	_btn_interior.button_pressed   = (_current_category == Category.INTERIOR)
	_btn_objects.button_pressed    = (_current_category == Category.OBJECTS)


func _refresh_selection_buttons() -> void:
	# zmaž staré tlačidlá
	for child in _selection_container.get_children():
		child.queue_free()

	_selection_scroll.visible = true

	var ids := _get_ids_for_category(_current_category)
	for building_id in ids:
		var cfg: Dictionary = _all_buildings.get(building_id, {})
		if cfg.is_empty():
			continue

		var btn := Button.new()
		btn.text = cfg.get("display_name", building_id)
		btn.focus_mode = Control.FOCUS_NONE
		btn.size_flags_horizontal = Control.SIZE_EXPAND
		btn.tooltip_text = building_id
		btn.toggle_mode = true  # aby sa dalo vizuálne vidieť výber

		btn.pressed.connect(_on_build_button_pressed.bind(building_id, btn))
		_selection_container.add_child(btn)

func _get_ids_for_category(cat: int) -> Array[String]:
	var result: Array[String] = []

	for id in _all_buildings.keys():
		var cfg: Dictionary = _all_buildings[id]
		var domain: String = cfg.get("domain", "")
		var category: String = cfg.get("category", "")
		var ui_group: String = cfg.get("ui_group", "")

		match cat:
			Category.FOUNDATION:
				# všetko, čo je foundation (napr. foundation_basic)
				if category == "foundation" or ui_group == "foundation":
					result.append(id)

			Category.EXTERIOR:
				# všetky exteriérové budovy – solar, battery, oxygen, ice_mine, bm_extractor, ...
				if domain == "exterior":
					result.append(id)

			Category.INTERIOR:
				# ROOM zóny – 0.0.63: room_quarters_basic, room_mess_hall_basic, room_airlock_basic
				if ui_group == "interior_rooms":
					result.append(id)

			Category.OBJECTS:
				# interiérové objekty – dvere, posteľ, stôl, atď.
				if ui_group == "interior_objects":
					result.append(id)

	result.sort()
	return result


func _on_build_button_pressed(building_id: String, btn: Button) -> void:
	# Zruš predchádzajúci výber
	if _selected_building_button != null and is_instance_valid(_selected_building_button):
		if _selected_building_button != btn:
			_selected_building_button.button_pressed = false

	_selected_building_button = btn
	building_selected.emit(building_id)

func clear_selection() -> void:
	if _selected_building_button != null and is_instance_valid(_selected_building_button):
		_selected_building_button.button_pressed = false
	_selected_building_button = null
