class_name DynamicFov
extends Node
## Widens the camera's field of view with speed, and punches it wider on a launch. Child of the
## Camera3D: the camera's own FOV is the resting value. Eases smoothly in both directions.

## Extra FOV (degrees) at full_speed.
@export var max_extra_fov: float = 14.0
## Speed (m/s) where the widening starts and where it is complete.
@export var start_speed: float = 18.0
@export var full_speed: float = 45.0
## How fast the FOV follows speed, and how fast a kick fades (per second).
@export var smoothing: float = 6.0
@export var kick_decay: float = 5.0

var _body: CharacterBody3D
var _speed_extra: float = 0.0
var _kick_extra: float = 0.0

@onready var _camera: Camera3D = get_parent() as Camera3D
@onready var _base_fov: float = _camera.fov


func setup(body: CharacterBody3D) -> void:
	_body = body


## A sudden extra FOV (degrees) that fades out, e.g. when a launch fires.
func kick(degrees: float) -> void:
	_kick_extra += degrees


func _process(delta: float) -> void:
	if _body == null:
		return
	var target: float = max_extra_fov * clampf(inverse_lerp(start_speed, full_speed, _body.velocity.length()), 0.0, 1.0)
	_speed_extra = lerpf(_speed_extra, target, 1.0 - exp(-smoothing * delta))
	_kick_extra = lerpf(_kick_extra, 0.0, 1.0 - exp(-kick_decay * delta))
	_camera.fov = _base_fov + _speed_extra + _kick_extra
