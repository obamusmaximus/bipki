class_name LandingDust
extends Node3D
## A ring of dust kicked up where the player lands. Spawn it with LandingDust.spawn(); it frees itself.

const LIFETIME: float = 0.7

@export var dust_color: Color = Color(0.8, 0.78, 0.7, 0.45)


## `strength` is 0-1: a gentle landing puffs a little, a hard one throws a wide ring.
static func spawn(parent: Node, feet: Vector3, strength: float) -> void:
	var dust := LandingDust.new()
	parent.add_child(dust)
	dust.global_position = feet
	dust._emit(clampf(strength, 0.0, 1.0))


func _emit(strength: float) -> void:
	var puffs: CPUParticles3D = ParticleKit.make_burst(8 + roundi(8.0 * strength), LIFETIME,
			ParticleKit.make_sphere(0.28, dust_color))
	puffs.color_ramp = ParticleKit.make_fade(Color.WHITE)
	puffs.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	puffs.emission_ring_axis = Vector3.UP
	puffs.emission_ring_radius = 0.55
	puffs.emission_ring_inner_radius = 0.3
	puffs.emission_ring_height = 0.05
	puffs.direction = Vector3.UP
	puffs.spread = 180.0
	puffs.flatness = 0.85
	puffs.initial_velocity_min = 1.0 + 1.5 * strength
	puffs.initial_velocity_max = 2.5 + 3.5 * strength
	puffs.damping_min = 3.0
	puffs.damping_max = 5.0
	puffs.gravity = Vector3.ZERO
	puffs.scale_amount_curve = ParticleKit.make_scale_curve(0.5, 1.5)
	add_child(puffs)
	puffs.emitting = true

	get_tree().create_timer(LIFETIME + 0.3).timeout.connect(queue_free)
