class_name DynamicFov
extends Node
## Widens the camera's field of view with speed, and punches it wider on a launch. Child of the
## Camera3D: the camera's own FOV is the resting value. Eases smoothly in both directions.

var feel: CameraFeel

var _body: CharacterBody3D
var _speed_extra: float = 0.0
var _kick_extra: float = 0.0

@onready var _camera: Camera3D = get_parent() as Camera3D
@onready var _base_fov: float = _camera.fov


func setup(body: CharacterBody3D, camera_feel: CameraFeel) -> void:
	_body = body
	feel = camera_feel


## A sudden extra FOV (degrees) that fades out, e.g. when a launch fires.
func kick(degrees: float) -> void:
	_kick_extra += degrees


func _process(delta: float) -> void:
	if _body == null:
		return
	var target: float = feel.fov_max_extra * clampf(inverse_lerp(feel.fov_start_speed, feel.fov_full_speed, _body.velocity.length()), 0.0, 1.0)
	_speed_extra = lerpf(_speed_extra, target, 1.0 - exp(-feel.fov_smoothing * delta))
	_kick_extra = lerpf(_kick_extra, 0.0, 1.0 - exp(-feel.fov_kick_decay * delta))
	_camera.fov = _base_fov + _speed_extra + _kick_extra
