# res://scripts/world/CameraController.gd
# Ovláda pan (W/A/S/D) a zoom (wheel alebo Q/E cez Input Map), rýchlosť škáluje podľa zoomu.

extends Camera2D

@export var pan_speed: float = 1200.0      # základná rýchlosť posunu (px/s)
@export var zoom_step: float = 0.1         # krok zoomu
@export var zoom_min: float = 0.5          # minimálny zoom (bližšie)
@export var zoom_max: float = 2.5          # maximálny zoom (ďalej)

# Inicializuje spracovanie vstupov a procesu kamery.
func _ready() -> void:
	set_process_unhandled_input(true)
	set_process(true)

# Spracuje zoom z kolieska myši (UP/DOWN).
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_apply_zoom(-zoom_step)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_apply_zoom(zoom_step)

# Posúva kameru podľa WASD; čím viac priblížené, tým pomalší posun (škálovanie podľa zoomu).
func _process(delta: float) -> void:
	var x: float = Input.get_axis("cam_left", "cam_right")
	var y: float = Input.get_axis("cam_up", "cam_down")
	var dir: Vector2 = Vector2(x, y)
	if dir != Vector2.ZERO:
		var zoom_factor: float = max(0.001, zoom.x)  # nezasahuje do Node2D.scale
		position += dir.normalized() * (pan_speed * delta) / zoom_factor

# Aplikuje clamped zoom na kameru.
func _apply_zoom(step: float) -> void:
	var target_zoom: float = clampf(zoom.x + step, zoom_min, zoom_max) # clampf = bez Variant
	zoom = Vector2(target_zoom, target_zoom)
