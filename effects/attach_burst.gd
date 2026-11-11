class_name AttachBurst
extends Node3D
## A burst of sparks and dust where the hook bites in. Spawn it with AttachBurst.spawn(); it frees itself.

const LIFETIME: float = 0.6

@export var spark_color: Color = Color(1.0, 0.8, 0.35)
@export var dust_color: Color = Color(0.85, 0.85, 0.8, 0.4)


## Creates a burst at `point` throwing particles out along `normal` (the hit surface's normal).
static func spawn(parent: Node, point: Vector3, normal: Vector3) -> void:
	var burst := AttachBurst.new()
	parent.add_child(burst)
	burst.global_position = point
	burst._emit(normal)


func _emit(normal: Vector3) -> void:
	var sparks: CPUParticles3D = ParticleKit.make_burst(16, LIFETIME * 0.8, ParticleKit.make_sphere(0.035, spark_color))
	sparks.direction = normal
	sparks.spread = 55.0
	sparks.initial_velocity_min = 4.0
	sparks.initial_velocity_max = 10.0
	sparks.gravity = Vector3(0.0, -14.0, 0.0)
	sparks.scale_amount_curve = ParticleKit.make_scale_curve(1.0, 0.1)
	add_child(sparks)
	sparks.emitting = true

	var dust: CPUParticles3D = ParticleKit.make_burst(7, LIFETIME, ParticleKit.make_sphere(0.3, dust_color))
	dust.color_ramp = ParticleKit.make_fade(Color.WHITE)
	dust.direction = normal
	dust.spread = 70.0
	dust.initial_velocity_min = 1.0
	dust.initial_velocity_max = 3.0
	dust.damping_min = 3.0
	dust.damping_max = 5.0
	dust.gravity = Vector3.ZERO
	dust.scale_amount_curve = ParticleKit.make_scale_curve(0.4, 1.4)
	add_child(dust)
	dust.emitting = true

	get_tree().create_timer(LIFETIME + 0.3).timeout.connect(queue_free)
