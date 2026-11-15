class_name CameraLean
extends Node
## Rolls the camera: it leans into sideways movement, and tilts away from the wall during a wall run (with a
## slight steady shake). It only works out the roll and hands it to the ShakeCamera. Child of the Camera3D.

var feel: CameraFeel

var _body: CharacterBody3D
var _wall_side: float = 0.0
var _roll: float = 0.0

@onready var _camera: ShakeCamera = get_parent() as ShakeCamera


func setup(body: CharacterBody3D, camera_feel: CameraFeel) -> void:
	_body = body
	feel = camera_feel


## +1 when running on a wall to the right, -1 to the left, 0 when not wall running.
func set_wall_side(side: float) -> void:
	_wall_side = side


func _process(delta: float) -> void:
	if feel == null or _body == null:
		return
	var target: float = 0.0
	if feel.lean_enabled:
		var sideways: float = _body.velocity.dot(_body.global_basis.x)
		# Positive z raises the camera's right side, so leaning right is a negative roll.
		target -= deg_to_rad(feel.lean_degrees) * clampf(sideways / maxf(feel.lean_reference_speed, 0.1), -1.0, 1.0)
	# The tilt leans away from the wall: wall on the right rolls left.
	target += _wall_side * deg_to_rad(feel.wall_run_roll_degrees)
	_roll = lerpf(_roll, target, 1.0 - exp(-feel.lean_smoothing * delta))
	_camera.set_roll(_roll)
	_camera.set_idle_shake(feel.wall_run_shake if _wall_side != 0.0 else 0.0)
