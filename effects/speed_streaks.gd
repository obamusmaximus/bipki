class_name SpeedStreaks
extends CPUParticles3D
## Thin streaks of air that sweep past the camera when the player moves fast (launches,
## swings, long falls). They fade in between start_speed and full_speed. Visual only.

@export var start_speed: float = 20.0
@export var full_speed: float = 45.0
@export var max_alpha: float = 0.35
## How far ahead of the camera, along the velocity, the streaks appear (metres).
@export var spawn_ahead: float = 7.0
@export var spawn_radius: float = 9.0

var _body: CharacterBody3D
var _camera: Camera3D
var _material: StandardMaterial3D


func setup(body: CharacterBody3D, camera: Camera3D) -> void:
	_body = body
	_camera = camera


func _ready() -> void:
	top_level = true
	local_coords = false
	emitting = false
	amount = 70
	lifetime = 0.55
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	emission_shape = EMISSION_SHAPE_SPHERE_SURFACE
	emission_sphere_radius = spawn_radius
	spread = 6.0
	initial_velocity_min = 4.0
	initial_velocity_max = 9.0
	gravity = Vector3.ZERO
	particle_flag_align_y = true # Each streak lies along its own direction of travel.

	var streak := BoxMesh.new()
	streak.size = Vector3(0.02, 1.6, 0.02)
	_material = ParticleKit.make_material(Color(1.0, 1.0, 1.0, 0.0))
	streak.material = _material
	mesh = streak


func _process(_delta: float) -> void:
	if _body == null or _camera == null:
		return
	var speed: float = _body.velocity.length()
	var intensity: float = clampf(inverse_lerp(start_speed, full_speed, speed), 0.0, 1.0)
	emitting = intensity > 0.0
	_material.albedo_color.a = max_alpha * intensity
	if intensity > 0.0:
		var heading: Vector3 = _body.velocity / speed
		global_position = _camera.global_position + heading * spawn_ahead
		direction = -heading # Streaks drift backward, so they rush past faster than the player moves.
