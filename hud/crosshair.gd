class_name Crosshair
extends Control
## Centered dot crosshair that shows what a fire would do: a ring when the hook can connect,
## red when the crosshair is on the ground plane (rejected), faint when it points at nothing.

@export var radius: float = 2.5
@export var outline_color: Color = Color(0.0, 0.0, 0.0, 0.6)
@export var valid_color: Color = Color(1.0, 1.0, 1.0, 0.95)
@export var none_color: Color = Color(1.0, 1.0, 1.0, 0.45)
@export var ground_color: Color = Color(1.0, 0.35, 0.3, 0.85)
@export var ring_radius: float = 11.0
@export var enemy_color: Color = Color(1.0, 0.55, 0.15, 1.0)
@export var far_ring_color: Color = Color(1.0, 1.0, 1.0, 0.3)

var _hook: GrappleHook
var _aim: GrappleHook.Aim = GrappleHook.Aim.NONE


func setup(hook: GrappleHook) -> void:
	_hook = hook


func _physics_process(_delta: float) -> void:
	if _hook == null:
		return
	var aim: GrappleHook.Aim = _hook.probe_aim()
	if aim != _aim:
		_aim = aim
		queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var color: Color = _aim_color()
	draw_circle(center, radius + 1.0, outline_color)
	draw_circle(center, radius, color)
	match _aim:
		GrappleHook.Aim.VALID:
			draw_arc(center, ring_radius, 0.0, TAU, 32, Color(color, 0.55), 1.5, true)
		GrappleHook.Aim.SWING_ONLY:
			# Only the swing reaches this far: a fainter, smaller ring.
			draw_arc(center, ring_radius * 0.8, 0.0, TAU, 32, far_ring_color, 1.5, true)
		GrappleHook.Aim.ENEMY:
			# Locked on: a ring with four ticks.
			draw_arc(center, ring_radius, 0.0, TAU, 32, Color(color, 0.8), 2.0, true)
			for i: int in 4:
				var direction: Vector2 = Vector2.from_angle(i * TAU / 4.0 + PI / 4.0)
				draw_line(center + direction * (ring_radius + 2.0), center + direction * (ring_radius + 7.0), color, 2.0, true)


func _aim_color() -> Color:
	match _aim:
		GrappleHook.Aim.VALID:
			return valid_color
		GrappleHook.Aim.GROUND:
			return ground_color
		GrappleHook.Aim.ENEMY:
			return enemy_color
	return none_color
