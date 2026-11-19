class_name IslandLook
extends Node
## Applies the island's look live. The grid on its top and cliffs follows ArenaStats (the same reference grid as the
## arena). The night follows NightStats: the moon light's angle, colour and shadows, the sky shader, the ambient light
## from the sky, the depth fog in the horizon colour, and the warm lamps. Each is re-applied when its resource changes.

var _grid_stats: ArenaStats
var _grid_material: ShaderMaterial
var _night: NightStats
var _environment: Environment
var _sky_material: ShaderMaterial
var _moon: DirectionalLight3D
var _warm_lights: Array[OmniLight3D] = []


func setup(grid_stats: ArenaStats, grid_material: ShaderMaterial, night: NightStats, environment: Environment,
		moon: DirectionalLight3D, warm_lights: Array[OmniLight3D]) -> void:
	_grid_stats = grid_stats
	_grid_material = grid_material
	_night = night
	_environment = environment
	_sky_material = environment.sky.sky_material as ShaderMaterial
	_moon = moon
	_warm_lights = warm_lights
	_grid_stats.changed.connect(_apply_grid)
	_night.changed.connect(_apply_night)
	_apply_grid()
	_apply_night()


func _apply_grid() -> void:
	GridLook.apply(_grid_stats, _grid_material)


func _apply_night() -> void:
	_apply_moon()
	_apply_sky()
	_environment.ambient_light_energy = _night.ambient_energy
	_environment.fog_light_color = _night.horizon_color
	_environment.fog_depth_begin = _night.fog_begin
	_environment.fog_depth_end = maxf(_night.fog_end, _night.fog_begin + 1.0)
	_environment.fog_depth_curve = _night.fog_curve
	_environment.fog_density = _night.fog_amount
	_environment.fog_sky_affect = _night.fog_sky_affect
	for lamp: OmniLight3D in _warm_lights:
		lamp.light_color = _night.warm_color
		lamp.light_energy = _night.warm_energy
		lamp.omni_range = _night.warm_range


func _apply_moon() -> void:
	_moon.rotation = Vector3(-deg_to_rad(_night.moon_elevation), deg_to_rad(_night.moon_azimuth), 0.0)
	_moon.light_color = _night.moon_color
	_moon.light_energy = _night.moon_energy
	_moon.shadow_blur = _night.shadow_blur
	_moon.directional_shadow_max_distance = _night.shadow_distance


func _apply_sky() -> void:
	var values: Dictionary = {
		"zenith_color": _night.zenith_color,
		"horizon_color": _night.horizon_color,
		"horizon_band": _night.horizon_band,
		"moon_disc_color": _night.moon_disc_color,
		"moon_disc_cos": cos(deg_to_rad(_night.moon_disc_size * 0.5)),
		"moon_halo": _night.moon_halo,
		"moon_halo_tightness": _night.moon_halo_tightness,
		"star_density": _night.star_density,
		"star_grid": _night.star_grid,
		"star_size": _night.star_size,
		"star_brightness": _night.star_brightness,
		"star_fade": _night.star_fade,
	}
	for key: String in values:
		_sky_material.set_shader_parameter(key, values[key])
