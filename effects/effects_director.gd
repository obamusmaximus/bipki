class_name EffectsDirector
extends Node
## Wires the player's shared visual effects to the events that trigger them: dust when the player lands, and speed
## streaks while moving fast. A loadout wires its own (the grapple's attach burst). Visual only. Child of Player.

## Landings softer than this (m/s of downward speed) raise no dust.
@export var min_landing_speed: float = 7.0
## Landing speed (m/s) at which the dust reaches full strength.
@export var full_landing_speed: float = 30.0

var _body: CharacterBody3D


func setup(body: CharacterBody3D, landing: LandingWatcher, camera: Camera3D) -> void:
	_body = body
	landing.landed.connect(_on_landed)
	var streaks := SpeedStreaks.new()
	add_child(streaks)
	streaks.setup(body, camera)


func _on_landed(impact_speed: float) -> void:
	if impact_speed < min_landing_speed:
		return
	var strength: float = inverse_lerp(min_landing_speed, full_landing_speed, impact_speed)
	LandingDust.spawn(get_tree().current_scene, _body.global_position, strength)
