class_name WalkBob
extends Node
## Subtle head bob while walking. Child of the Camera3D: offsets the camera's local position
## smoothly and eases back to rest when the player stops. The player calls set_walking().

@export var bob_height: float = 0.03
@export var sway: float = 0.02
## Phase speed in radians per second (about two footsteps per second at walking pace).
@export var step_speed: float = 12.0
@export var blend_speed: float = 8.0

var _walking: bool = false
var _phase: float = 0.0
var _amount: float = 0.0

@onready var _camera: Camera3D = get_parent() as Camera3D
@onready var _rest_position: Vector3 = _camera.position


func set_walking(walking: bool) -> void:
	_walking = walking


func _process(delta: float) -> void:
	_amount = move_toward(_amount, 1.0 if _walking else 0.0, blend_speed * delta)
	if _walking:
		_phase += step_speed * delta
	elif is_zero_approx(_amount):
		_camera.position = _rest_position
		return

	var offset := Vector3(sin(_phase * 0.5) * sway, sin(_phase) * bob_height, 0.0)
	_camera.position = _rest_position + offset * _amount
