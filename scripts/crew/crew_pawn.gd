extends CharacterBody2D
class_name CrewPawn

enum Status { IDLE, MOVING, WORKING, EATING, SLEEPING, RELAXING, DEAD }

@export var display_name: StringName = &"Colonist"
@export var home_building_id: StringName = &""
@export var work_building_id: StringName = &""

# Rýchlosti – iné v interiéri a exteriéri
@export var speed_exterior: float = 80.0
@export var speed_interior: float = 60.0
@export var is_interior: bool = false

# Idle správanie okolo vlastnej pozície
@export var idle_enabled: bool = true
@export var idle_radius: float = 32.0
@export var idle_min_interval: float = 2.0
@export var idle_max_interval: float = 5.0

# Debug vizuály
@export var show_world_label: bool = false
@export var show_move_line: bool = true

var crew_id: int = -1
var status: Status = Status.IDLE

var needs := {
	"oxygen": 1.0,
	"hunger": 0.0,
	"sleep": 0.0,
}

@onready var debug_label: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D
@onready var move_line: Line2D = $MoveLine

# ---- MOVE COMMAND API ----
var has_move_target: bool = false
var move_target: Vector2 = Vector2.ZERO

# Idle timer
var _idle_timer: float = 0.0
var _next_idle_time: float = 0.0

# --- Anti-stuck pre pohyb ---
var _stuck_timer: float = 0.0
var _last_dist_to_target: float = 0.0

@export var stuck_timeout: float = 1.0            # po koľkých sekundách bez progresu dropneme target
@export var stuck_distance_epsilon: float = 1.0   # minimálna zmena vzdialenosti, aby to rátalo ako progres

func _ready() -> void:
	crew_id = Crew_Registry.register_crew(self)
	randomize()
	_reset_idle_timer()

	if debug_label != null:
		debug_label.visible = show_world_label

	if move_line != null:
		move_line.visible = false

	_update_debug_label()


func _exit_tree() -> void:
	if crew_id != -1:
		Crew_Registry.unregister_crew(crew_id)


func command_move_to(world_pos: Vector2) -> void:
	if status == Status.DEAD:
		return

	move_target = world_pos
	has_move_target = true
	status = Status.MOVING


func clear_move_command() -> void:
	has_move_target = false
	velocity = Vector2.ZERO

	if status != Status.DEAD:
		status = Status.IDLE


func _physics_process(delta: float) -> void:
	# 1) PAUZA alebo DEAD – stojíme
	if Clock.time_scale <= 0.0 or status == Status.DEAD:
		velocity = Vector2.ZERO
		_update_move_line()
		move_and_slide()
		return

	if has_move_target:
		var to_target: Vector2 = move_target - global_position
		var dist: float = to_target.length()

		if dist < 2.0:
			# cieľ dosiahnutý
			clear_move_command()
			_stuck_timer = 0.0
			_last_dist_to_target = 0.0
		else:
			# --- anti-stuck logika ---
			if _last_dist_to_target <= 0.0:
				# prvé meranie
				_last_dist_to_target = dist
				_stuck_timer = 0.0
			else:
				if absf(dist - _last_dist_to_target) < stuck_distance_epsilon:
					# prakticky žiadny progres → rátame čas
					_stuck_timer += delta
				else:
					# pohli sme sa → reset timeru a update referenčnej vzdialenosti
					_stuck_timer = 0.0
					_last_dist_to_target = dist

				if _stuck_timer >= stuck_timeout:
					if DebugFlags.MASTER_DEBUG and DebugFlags.DEBUG_CREW_IDLE:
						print("Crew #", crew_id, " stuck on move, clearing target")
					clear_move_command()
					_stuck_timer = 0.0
					_last_dist_to_target = 0.0

			if has_move_target:
				var dir: Vector2 = to_target.normalized()

				var base_speed: float
				if is_interior:
					base_speed = speed_interior
				else:
					base_speed = speed_exterior

				var speed_scale: float = Clock.time_scale
				velocity = dir * (base_speed * speed_scale)
			else:
				velocity = Vector2.ZERO

		_update_move_line()
	else:
		velocity = Vector2.ZERO
		_update_move_line()

	move_and_slide()





func _process(delta: float) -> void:
	# pauza – nič nerobíme
	if Clock.time_scale <= 0.0:
		return

	if status != Status.DEAD and idle_enabled and not has_move_target:
		_update_idle(delta * Clock.time_scale)

	if DebugFlags.MASTER_DEBUG and DebugFlags.DEBUG_CREW:
		_update_debug_label()

func _update_idle(delta: float) -> void:
	_idle_timer += delta
	if _idle_timer >= _next_idle_time:
		_pick_new_idle_target()


func _pick_new_idle_target() -> void:
	_idle_timer = 0.0
	_next_idle_time = randf_range(idle_min_interval, idle_max_interval)

	var attempts: int = 0
	var max_attempts: int = 6

	while attempts < max_attempts:
		attempts += 1

		var angle: float = randf() * TAU
		var radius: float = randf() * idle_radius
		var offset: Vector2 = Vector2(cos(angle), sin(angle)) * radius
		var target: Vector2 = global_position + offset

		if _is_point_walkable(target):
			command_move_to(target)
			if DebugFlags.MASTER_DEBUG and DebugFlags.DEBUG_CREW_IDLE:
				print("Crew #", crew_id, " idle move to ", target, " (attempt ", attempts, ")")
			return

	# nenašli sme voľné miesto → ostávame stáť
	if DebugFlags.MASTER_DEBUG and DebugFlags.DEBUG_CREW_IDLE:
		print("Crew #", crew_id, " idle: no free spot found, stay put")

func _is_point_walkable(target: Vector2) -> bool:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = target
	params.collide_with_bodies = true
	params.collide_with_areas = true
	params.exclude = [self]

	var results: Array = space_state.intersect_point(params, 8)
	if results.is_empty():
		return true

	for hit in results:
		var collider: Object = hit["collider"]
		if collider == null:
			continue
		# v budúcnosti môžeme filtrovať: čo je wall, čo je podlaha atď.
		return false

	return true

func _reset_idle_timer() -> void:
	_idle_timer = 0.0
	_next_idle_time = randf_range(idle_min_interval, idle_max_interval)


func _update_move_line() -> void:
	if move_line == null:
		return

	if has_move_target and show_move_line and status != Status.DEAD:
		move_line.visible = true
		var local_target := to_local(move_target)
		move_line.points = PackedVector2Array([Vector2.ZERO, local_target])
	else:
		move_line.visible = false


func set_selected(selected: bool) -> void:
	if sprite == null:
		return

	sprite.modulate = Color(1, 1, 0.6) if selected else Color(1, 1, 1)


func _update_debug_label() -> void:
	if debug_label == null or not debug_label.visible:
		return

	var status_text := "Idle"
	if status == Status.MOVING:
		status_text = "Moving"
	elif status == Status.WORKING:
		status_text = "Working"
	elif status == Status.EATING:
		status_text = "Eating"
	elif status == Status.SLEEPING:
		status_text = "Sleeping"
	elif status == Status.RELAXING:
		status_text = "Relaxing"
	elif status == Status.DEAD:
		status_text = "Dead"

	debug_label.text = "%s (#%d)\nStatus: %s\nO2: %.2f  H: %.2f  S: %.2f" % [
		display_name,
		crew_id,
		status_text,
		needs["oxygen"],
		needs["hunger"],
		needs["sleep"],
	]
