extends Control
class_name BuildUI
## BuildUI: spodná lišta s módmi (Build / Rooms / Utilities / Demolish).
## - nájde tlačidlá podľa mena
## - spojí ich do ButtonGroup
## - pri stlačení emituje signal tool_requested(tool_id).

signal tool_requested(tool_id: int)

enum ToolID { BUILD = 0, ROOMS = 1, UTIL = 2, DEMO = 3 }

var btn_build: Button
var btn_rooms: Button
var btn_utils: Button
var btn_demo:  Button
var group: ButtonGroup


## _ready():
## - vyhľadá tlačidlá
## - nastaví ButtonGroup
## - prepne defaultne na BUILD
func _ready() -> void:
	# nájdi tlačidlá podľa názvov (funguje aj keď sú hlbšie v hierarchii)
	btn_build = find_child("BtnBuild", true, false) as Button
	btn_rooms = find_child("BtnRooms", true, false) as Button
	btn_utils = find_child("BtnUtilities", true, false) as Button
	btn_demo  = find_child("BtnDemolish", true, false) as Button

	for b in [btn_build, btn_rooms, btn_utils, btn_demo]:
		if b == null:
			push_error("[BuildUI] Chýba tlačidlo (BtnBuild/BtnRooms/BtnUtilities/BtnDemolish). Skontroluj názvy.")

	group = ButtonGroup.new()
	var buttons: Array[Button] = []
	if btn_build: buttons.append(btn_build)
	if btn_rooms: buttons.append(btn_rooms)
	if btn_utils: buttons.append(btn_utils)
	if btn_demo:  buttons.append(btn_demo)

	for b in buttons:
		b.toggle_mode = true
		b.button_group = group
		b.pressed.connect(_on_button_pressed.bind(b))

	# predvolený režim: Build
	if btn_build:
		btn_build.button_pressed = true
		# Neemitujeme hneď tool_requested – BuildMode si môže default riešiť podľa potreby.


## _on_button_pressed(which):
## - zistí, ktoré tlačidlo je stlačené
## - emituje správny ToolID smerom do BuildMode
func _on_button_pressed(which: Button) -> void:
	if which == btn_build:
		emit_signal("tool_requested", ToolID.BUILD)
	elif which == btn_rooms:
		emit_signal("tool_requested", ToolID.ROOMS)
	elif which == btn_utils:
		emit_signal("tool_requested", ToolID.UTIL)
	elif which == btn_demo:
		emit_signal("tool_requested", ToolID.DEMO)
