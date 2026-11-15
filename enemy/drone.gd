class_name Drone
extends Enemy
## A flying enemy. DroneFlight decides where it goes; this body applies the velocity, collides with
## the world, and faces its target. It owns the beam attack and its visuals and sound. When the grapple
## takes hold of it the beam is cancelled and stays off until the drone has recovered.
## Its tuning is the DroneStats in `stats` (an EnemyStats with the drone's own groups on top).

var _drone_stats: DroneStats
var _target: Node3D
var _grid: FlightGrid

@onready var _flight: DroneFlight = $Flight
@onready var _beam: BeamAttack = $BeamAttack
@onready var _visual: BeamVisual = $BeamVisual
@onready var _sfx: DroneSfx = $Sfx


func _ready() -> void:
	super()
	_drone_stats = stats as DroneStats


## Snaps the drone to open air, then starts it chasing `target` through `grid`.
func setup(grid: FlightGrid, target: Node3D) -> void:
	_grid = grid
	_target = target
	global_position = grid.nearest_open_position(global_position)
	_flight.setup(grid, target, _drone_stats)
	_beam.setup(self, target, _drone_stats)
	_visual.setup(_beam, self, _drone_stats)
	_sfx.setup(_beam, _drone_stats)


func _ai_step(delta: float) -> void:
	var desired: Vector3 = _flight.desired_velocity(global_position, delta)
	velocity = velocity.move_toward(desired, _drone_stats.acceleration * delta)
	move_and_slide()
	_face_target(delta)


func _on_state_changed() -> void:
	if _beam == null:
		return
	var working: bool = state == State.NORMAL
	_beam.set_active(working)
	if not working:
		_beam.cancel()


func _on_recovered() -> void:
	if _grid != null:
		global_position = _grid.nearest_open_position(global_position)


func _face_target(delta: float) -> void:
	if _target == null:
		return
	var to_target: Vector3 = _target.global_position - global_position
	to_target.y = 0.0
	if to_target.is_zero_approx():
		return
	rotation.y = lerp_angle(rotation.y, atan2(-to_target.x, -to_target.z), clampf(_drone_stats.turn_speed * delta, 0.0, 1.0))
