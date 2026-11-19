class_name GridLook
extends RefCounted
## Sets the grid shader's uniforms (grid.gdshaderinc) from ArenaStats. Shared by the arena (ArenaLook) and the
## island (IslandLook), so both grids follow the same tuning.


static func apply(stats: ArenaStats, material: ShaderMaterial) -> void:
	var values: Dictionary = {
		"wall_color": stats.wall_color,
		"noise_scale": stats.noise_scale,
		"noise_strength": stats.noise_strength,
		"grain_strength": stats.grain_strength,
		"corner_shade": stats.corner_shade,
		"corner_shade_range": stats.corner_shade_range,
		"bar_color": stats.bar_color,
		"major_spacing": stats.major_spacing,
		"minor_spacing": stats.minor_spacing,
		"major_width": stats.major_width,
		"minor_width": stats.minor_width,
		"central_width": stats.central_width,
		"notch_width": stats.notch_width,
		"notch_width_mid": stats.notch_width_mid,
		"notch_width_long": stats.notch_width_long,
		"notch_length": stats.notch_length,
		"notch_length_mid": stats.notch_length_mid,
		"notch_length_long": stats.notch_length_long,
		"notch_clear": stats.notch_clear,
		"clear_band": stats.clear_band,
	}
	for key: String in values:
		material.set_shader_parameter(key, values[key])
