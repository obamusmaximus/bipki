class_name HeadLook
extends Node3D
## Mouse look for a first-person player. Yaw rotates the parent body, pitch rotates this node.

## Radians per pixel at the default setting. The player's sensitivity option (GameSettings) scales it.
@export var mouse_sensitivity: float = 0.002

var _pitch_limit: float = deg_to_rad(89.0)
var _pitch: float = 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	# ESC is handled by the pause menu, which also releases and recaptures the mouse.
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		var body := get_parent() as Node3D
		var sensitivity: float = mouse_sensitivity * GameSettings.mouse_sensitivity_scale
		body.rotate_y(-motion.relative.x * sensitivity)
		_pitch = clampf(_pitch - motion.relative.y * sensitivity, -_pitch_limit, _pitch_limit)
		rotation.x = _pitch
