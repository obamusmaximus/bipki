class_name HeadLook
extends Node3D
## Mouse look for a first-person player. Yaw rotates the parent body, pitch rotates this node.

var feel: CameraFeel
## Multiplies the mouse sensitivity. The throw lowers it while the player turns away from a held enemy.
var sensitivity_scale: float = 1.0

var _pitch_limit: float = deg_to_rad(89.0)
var _pitch: float = 0.0


func setup(camera_feel: CameraFeel) -> void:
	feel = camera_feel


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func get_pitch() -> float:
	return _pitch


## Puts the pitch back (a rewind). Yaw is the body's own rotation.
func set_pitch(pitch: float) -> void:
	_pitch = clampf(pitch, -_pitch_limit, _pitch_limit)
	rotation.x = _pitch


func _unhandled_input(event: InputEvent) -> void:
	# ESC is handled by the pause menu, which also releases and recaptures the mouse.
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		var body := get_parent() as Node3D
		var sensitivity: float = feel.mouse_sensitivity * GameSettings.mouse_sensitivity_scale * sensitivity_scale
		body.rotate_y(-motion.relative.x * sensitivity)
		_pitch = clampf(_pitch - motion.relative.y * sensitivity, -_pitch_limit, _pitch_limit)
		rotation.x = _pitch
