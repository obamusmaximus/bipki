class_name ShakeCamera
extends Camera3D
## Camera with a short, decaying shake. Call shake() to add trauma (0-1); the effect scales
## with trauma squared so small values stay subtle. Uses frustum offset and roll only,
## so the camera's position and aim direction (used for raycasts) are never changed.
## CameraLean also sets a steady roll (set_roll) and a constant low shake (set_idle_shake) through here.

var feel: CameraFeel

var _trauma: float = 0.0
## Steady roll in radians, set by CameraLean. The shake roll is added on top.
var _roll: float = 0.0
## The shake never fades below this (0-1), e.g. during a wall run.
var _idle_shake: float = 0.0


func setup(camera_feel: CameraFeel) -> void:
	feel = camera_feel


func shake(amount: float) -> void:
	_trauma = minf(1.0, _trauma + amount)


func set_roll(radians: float) -> void:
	_roll = radians


func set_idle_shake(level: float) -> void:
	_idle_shake = level


func _process(delta: float) -> void:
	if feel == null:
		return
	_trauma = maxf(maxf(_trauma - feel.shake_decay * delta, 0.0), _idle_shake)
	var intensity: float = _trauma * _trauma
	h_offset = randf_range(-1.0, 1.0) * feel.shake_max_offset * intensity
	v_offset = randf_range(-1.0, 1.0) * feel.shake_max_offset * intensity
	rotation.z = _roll + deg_to_rad(randf_range(-1.0, 1.0) * feel.shake_max_roll_degrees * intensity)
