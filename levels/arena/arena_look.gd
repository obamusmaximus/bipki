class_name ArenaLook
extends Node
## Applies ArenaStats to the arena's wall shader, pillar material, ambient light and directional light, and again
## whenever the resource changes, so the tuning panel edits the look live. (The number labels follow in ArenaScale.)

var _stats: ArenaStats
var _grid_material: ShaderMaterial
var _pillar_material: StandardMaterial3D
var _environment: Environment
var _light: DirectionalLight3D


func setup(stats: ArenaStats, grid_material: ShaderMaterial, pillar_material: StandardMaterial3D,
		environment: Environment, light: DirectionalLight3D) -> void:
	_stats = stats
	_grid_material = grid_material
	_pillar_material = pillar_material
	_environment = environment
	_light = light
	_stats.changed.connect(_apply)
	_apply()


func _apply() -> void:
	var shader_values: Dictionary = {
		"wall_color": _stats.wall_color,
		"noise_scale": _stats.noise_scale,
		"noise_strength": _stats.noise_strength,
		"grain_strength": _stats.grain_strength,
		"corner_shade": _stats.corner_shade,
		"corner_shade_range": _stats.corner_shade_range,
		"bar_color": _stats.bar_color,
		"major_spacing": _stats.major_spacing,
		"minor_spacing": _stats.minor_spacing,
		"major_width": _stats.major_width,
		"minor_width": _stats.minor_width,
		"central_width": _stats.central_width,
		"notch_width": _stats.notch_width,
		"notch_width_mid": _stats.notch_width_mid,
		"notch_width_long": _stats.notch_width_long,
		"notch_length": _stats.notch_length,
		"notch_length_mid": _stats.notch_length_mid,
		"notch_length_long": _stats.notch_length_long,
		"notch_clear": _stats.notch_clear,
		"clear_band": _stats.clear_band,
	}
	for key: String in shader_values:
		_grid_material.set_shader_parameter(key, shader_values[key])
	_pillar_material.albedo_color = _stats.pillar_color
	_environment.glow_intensity = _stats.glow_intensity
	_environment.glow_bloom = _stats.glow_bloom
	_environment.glow_hdr_threshold = _stats.glow_hdr_threshold
	_environment.ambient_light_color = _stats.ambient_color
	_environment.ambient_light_energy = _stats.ambient_energy
	_light.light_energy = _stats.light_energy
