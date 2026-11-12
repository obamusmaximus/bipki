class_name ParticleKit
extends RefCounted
## Small helpers for building the particle effects in code: materials, fades and size curves.


## Unshaded, alpha-blended material that takes the particle's own colour (so a color_ramp can fade it).
static func make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.albedo_color = color
	return material


## A gradient from `color` to the same colour fully transparent.
static func make_fade(color: Color) -> Gradient:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([color, Color(color, 0.0)])
	return gradient


## A size curve from `start` to `end` (multiples of the particle's scale) over its life.
static func make_scale_curve(start: float, end: float) -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, start))
	curve.add_point(Vector2(1.0, end))
	return curve


## A one-shot burst: all particles at once, no shadows, freed by the caller.
static func make_burst(amount: int, lifetime: float, mesh: Mesh) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = amount
	particles.lifetime = lifetime
	particles.mesh = mesh
	particles.local_coords = false
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles


static func make_sphere(radius: float, color: Color) -> SphereMesh:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	sphere.material = make_material(color)
	return sphere
