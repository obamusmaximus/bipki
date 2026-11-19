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
	GridLook.apply(_stats, _grid_material)
	_pillar_material.albedo_color = _stats.pillar_color
	_environment.glow_intensity = _stats.glow_intensity
	_environment.glow_bloom = _stats.glow_bloom
	_environment.glow_hdr_threshold = _stats.glow_hdr_threshold
	_environment.ambient_light_color = _stats.ambient_color
	_environment.ambient_light_energy = _stats.ambient_energy
	_light.light_energy = _stats.light_energy
