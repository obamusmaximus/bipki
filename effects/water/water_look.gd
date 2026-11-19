class_name WaterLook
extends Node
## Applies WaterStats to the water: the mesh's quad size (re-subdividing its PlaneMesh) and the uniforms of
## water.gdshader, again whenever the resource changes, so the tuning panel edits the sea live. The level hands it the
## island's box, which the shader measures the distance to (calm water away from it, the foam band at its cliffs).

var _stats: WaterStats
var _mesh_instance: MeshInstance3D
var _mesh: PlaneMesh
var _material: ShaderMaterial


func setup(stats: WaterStats, mesh_instance: MeshInstance3D, island: AABB) -> void:
	_stats = stats
	_mesh_instance = mesh_instance
	_mesh = mesh_instance.mesh as PlaneMesh
	_material = mesh_instance.material_override as ShaderMaterial
	_material.set_shader_parameter("island_rect",
			Vector4(island.position.x, island.position.z, island.end.x, island.end.z))
	_stats.changed.connect(_apply)
	_apply()


func _apply() -> void:
	_apply_mesh()
	var values: Dictionary = {
		"wave_count": _stats.wave_count,
		"wave_height": _stats.wave_height,
		"wavelength": _stats.wavelength,
		"wavelength_falloff": _stats.wavelength_falloff,
		"height_falloff": _stats.height_falloff,
		"wave_direction": deg_to_rad(_stats.wave_direction),
		"direction_spread": deg_to_rad(_stats.direction_spread),
		"wave_speed": _stats.wave_speed,
		"calm_begin": _stats.calm_begin,
		"calm_end": _stats.calm_end,
		"shore_calm_reach": _stats.shore_calm_reach,
		"shore_calm_level": _stats.shore_calm_level,
		"deep_color": _stats.deep_color,
		"shallow_color": _stats.shallow_color,
		"ramp_steps": _stats.ramp_steps,
		"ramp_contrast": _stats.ramp_contrast,
		"crest_tint": _stats.crest_tint,
		"light_strength": _stats.light_strength,
		"facet_amount": _stats.facet_amount,
		"foam_color": _stats.foam_color,
		"foam_width": _stats.foam_width,
		"foam_raggedness": _stats.foam_raggedness,
		"foam_noise_scale": _stats.foam_noise_scale,
		"foam_speed": _stats.foam_speed,
		"foam_glow": _stats.foam_glow,
		"band_spacing": _stats.band_spacing,
		"band_speed": _stats.band_speed,
		"band_width": _stats.band_width,
		"band_reach": _stats.band_reach,
		"band_breakup": _stats.band_breakup,
		"glitter_color": _stats.glitter_color,
		"glitter_strength": _stats.glitter_strength,
		"glitter_threshold": _stats.glitter_threshold,
		"lamp_glitter": _stats.lamp_glitter,
	}
	for key: String in values:
		_material.set_shader_parameter(key, values[key])


## Subdivides the plane into quads of about `quad_size`, and grows the cull box by the highest crest, since the
## shader lifts the vertices above the flat mesh.
func _apply_mesh() -> void:
	var width: int = maxi(0, ceili(_mesh.size.x / maxf(_stats.quad_size, 0.5)) - 1)
	var depth: int = maxi(0, ceili(_mesh.size.y / maxf(_stats.quad_size, 0.5)) - 1)
	if _mesh.subdivide_width != width:
		_mesh.subdivide_width = width
	if _mesh.subdivide_depth != depth:
		_mesh.subdivide_depth = depth
	var crest: float = _stats.wave_height / maxf(1.0 - _stats.height_falloff, 0.05)
	_mesh_instance.extra_cull_margin = crest + 1.0
