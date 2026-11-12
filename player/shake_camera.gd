class_name ShakeCamera
extends Camera3D
## Camera with a short, decaying shake. Call shake() to add trauma (0-1); the effect scales
## with trauma squared so small values stay subtle. Uses frustum offset and roll only,
## so the camera's position and aim direction (used for raycasts) are never changed.

var feel: CameraFeel

var _trauma: float = 0.0


func setup(camera_feel: CameraFeel) -> void:
	feel = camera_feel


func shake(amount: float) -> void:
	_trauma = minf(1.0, _trauma + amount)


func _process(delta: float) -> void:
	if _trauma <= 0.0:
		return

	_trauma = maxf(0.0, _trauma - feel.shake_decay * delta)
	var intensity: float = _trauma * _trauma
	h_offset = randf_range(-1.0, 1.0) * feel.shake_max_offset * intensity
	v_offset = randf_range(-1.0, 1.0) * feel.shake_max_offset * intensity
	rotation.z = deg_to_rad(randf_range(-1.0, 1.0) * feel.shake_max_roll_degrees * intensity)
