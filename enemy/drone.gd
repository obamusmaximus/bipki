class_name Drone
extends CharacterBody3D
## A flying enemy. DroneFlight decides where it goes; this body applies the velocity, collides with
## the world, and faces its target. It owns the beam attack and its visuals and sound.

## Tunable numbers for this kind of drone. Assign another DroneStats .tres for a different variant.
@export var stats: DroneStats

var _target: Node3D

@onready var _flight: DroneFlight = $Flight
@onready var _beam: BeamAttack = $BeamAttack
@onready var _visual: BeamVisual = $BeamVisual
@onready var _sfx: DroneSfx = $Sfx


## Snaps the drone to open air, then starts it chasing `target` through `grid`.
func setup(grid: FlightGrid, target: Node3D) -> void:
	_target = target
	global_position = grid.nearest_open_position(global_position)
	_flight.setup(grid, target, stats)
	_beam.setup(self, target, stats)
	_visual.setup(_beam, self, stats)
	_sfx.setup(_beam, stats)


func _physics_process(delta: float) -> void:
	var desired: Vector3 = _flight.desired_velocity(global_position, delta)
	velocity = velocity.move_toward(desired, stats.acceleration * delta)
	move_and_slide()
	_face_target(delta)


func _face_target(delta: float) -> void:
	if _target == null:
		return
	var to_target: Vector3 = _target.global_position - global_position
	to_target.y = 0.0
	if to_target.is_zero_approx():
		return
	rotation.y = lerp_angle(rotation.y, atan2(-to_target.x, -to_target.z), clampf(stats.turn_speed * delta, 0.0, 1.0))
