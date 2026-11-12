class_name WalkBob
extends Node
## Subtle head bob while walking. Child of the Camera3D: offsets the camera's local position
## smoothly and eases back to rest when the player stops. The player calls set_walking().

var feel: CameraFeel

var _walking: bool = false
var _phase: float = 0.0
var _amount: float = 0.0

@onready var _camera: Camera3D = get_parent() as Camera3D
@onready var _rest_position: Vector3 = _camera.position


func setup(camera_feel: CameraFeel) -> void:
	feel = camera_feel


func set_walking(walking: bool) -> void:
	_walking = walking


func _process(delta: float) -> void:
	_amount = move_toward(_amount, 1.0 if _walking else 0.0, feel.bob_blend_speed * delta)
	if _walking:
		_phase += feel.bob_step_speed * delta
	elif is_zero_approx(_amount):
		_camera.position = _rest_position
		return

	var offset := Vector3(sin(_phase * 0.5) * feel.bob_sway, sin(_phase) * feel.bob_height, 0.0)
	_camera.position = _rest_position + offset * _amount
