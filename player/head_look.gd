class_name HeadLook
extends Node3D
## Mouse look for a first-person player. Yaw rotates the parent body, pitch rotates this node.

@export var mouse_sensitivity: float = 0.002

var _pitch_limit: float = deg_to_rad(89.0)
var _pitch: float = 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		var body := get_parent() as Node3D
		body.rotate_y(-motion.relative.x * mouse_sensitivity)
		_pitch = clampf(_pitch - motion.relative.y * mouse_sensitivity, -_pitch_limit, _pitch_limit)
		rotation.x = _pitch
