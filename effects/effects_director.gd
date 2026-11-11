class_name EffectsDirector
extends Node
## Wires the player's visual effects to the events that trigger them: an attach burst when the hook
## bites in, dust when the player lands, and speed streaks while moving fast. Visual only. Child of Player.

## Landings softer than this (m/s of downward speed) raise no dust.
@export var min_landing_speed: float = 7.0
## Landing speed (m/s) at which the dust reaches full strength.
@export var full_landing_speed: float = 30.0

var _body: CharacterBody3D
var _hook: GrappleHook


func setup(body: CharacterBody3D, hook: GrappleHook, landing: LandingWatcher, camera: Camera3D) -> void:
	_body = body
	_hook = hook
	hook.attached.connect(_on_attached)
	landing.landed.connect(_on_landed)
	var streaks := SpeedStreaks.new()
	add_child(streaks)
	streaks.setup(body, camera)


func _on_attached() -> void:
	AttachBurst.spawn(get_tree().current_scene, _hook.get_hit_point(), _hook.get_hit_normal())


func _on_landed(impact_speed: float) -> void:
	if impact_speed < min_landing_speed:
		return
	var strength: float = inverse_lerp(min_landing_speed, full_landing_speed, impact_speed)
	LandingDust.spawn(get_tree().current_scene, _body.global_position, strength)
