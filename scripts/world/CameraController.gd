# res://scripts/world/CameraController.gd
# CameraController: jednoduchá 2D kamera pre Luna-Link.
# - pan pomocou WASD (Input map: cam_left/right/up/down)
# - zoom cez wheel alebo Q/E (ak máš napojené)
# - rýchlosť panu sa škáluje podľa zoomu (bližšie = pomalší posun)

extends Camera2D
class_name CameraController

@export var pan_speed: float = 1200.0      # základná rýchlosť posunu (px/s) pri zoom=1.0
@export var zoom_step: float = 0.1         # krok zoomu pri jednom „ticku“
@export var zoom_min: float = 0.5          # minimálny zoom (bližšie)
@export var zoom_max: float = 2.5          # maximálny zoom (ďalej)


## _ready():
## - zapne _process a _unhandled_input pre kameru
func _ready() -> void:
	set_process_unhandled_input(true)
	set_process(true)


## _unhandled_input(event):
## - rieši len zoom z kolieska myši (wheel up/down)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_apply_zoom(-zoom_step)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_apply_zoom(zoom_step)


## _process(delta):
## - pan kamery podľa Input axis (cam_left/right, cam_up/down)
## - rýchlosť škáluje podľa aktuálneho zoomu (pri väčšom priblížení sa pohybuje jemnejšie)
func _process(delta: float) -> void:
	var x: float = Input.get_axis("cam_left", "cam_right")
	var y: float = Input.get_axis("cam_up", "cam_down")
	var dir: Vector2 = Vector2(x, y)
	if dir != Vector2.ZERO:
		var zoom_factor: float = max(0.001, zoom.x)  # nezasiahne do Node2D.scale
		position += dir.normalized() * (pan_speed * delta) / zoom_factor


## _apply_zoom(step):
## - clamped zoom v rozsahu [zoom_min, zoom_max]
## - zoom je vždy rovnaký v oboch osiach
func _apply_zoom(step: float) -> void:
	var target_zoom: float = clampf(zoom.x + step, zoom_min, zoom_max)
	zoom = Vector2(target_zoom, target_zoom)
