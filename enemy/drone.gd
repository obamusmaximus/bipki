class_name Drone
extends CharacterBody3D
## A flying enemy. DroneFlight decides where it goes; this body applies the velocity, collides with
## the world, and faces its target. It owns the beam attack and its visuals and sound.

@export var acceleration: float = 30.0
## How fast it turns to face the target (radians per second, roughly).
@export var turn_speed: float = 5.0

var _target: Node3D

@onready var _flight: DroneFlight = $Flight
@onready var _beam: BeamAttack = $BeamAttack
@onready var _visual: BeamVisual = $BeamVisual
@onready var _sfx: DroneSfx = $Sfx


## Snaps the drone to open air, then starts it chasing `target` through `grid`.
func setup(grid: FlightGrid, target: Node3D) -> void:
	_target = target
	global_position = grid.nearest_open_position(global_position)
	_flight.setup(grid, target)
	_beam.setup(self, target)
	_visual.setup(_beam, self)
	_sfx.setup(_beam)


func _physics_process(delta: float) -> void:
	var desired: Vector3 = _flight.desired_velocity(global_position, delta)
	velocity = velocity.move_toward(desired, acceleration * delta)
	move_and_slide()
	_face_target(delta)


func _face_target(delta: float) -> void:
	if _target == null:
		return
	var to_target: Vector3 = _target.global_position - global_position
	to_target.y = 0.0
	if to_target.is_zero_approx():
		return
	rotation.y = lerp_angle(rotation.y, atan2(-to_target.x, -to_target.z), clampf(turn_speed * delta, 0.0, 1.0))
