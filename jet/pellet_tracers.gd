class_name PelletTracers
extends MeshInstance3D
## Draws the seeker shotgun's tracers: each pellet's recent path (Pellets keeps it) as a thin ribbon turned to the
## camera, `tracer_width` and `tracer_color` at the newest point, narrowing and fading to nothing over `tracer_time`.
## Rebuilt each time Pellets ticks. Lives under Pellets, in world space.

var _mesh := ImmediateMesh.new()


func _ready() -> void:
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	material_override = material


func draw_trails(pellets: Array, clock: float, stats: SeekerShotgunStats) -> void:
	_mesh.clear_surfaces()
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null or pellets.is_empty():
		return
	var eye: Vector3 = camera.global_position
	var begun: bool = false
	for pellet: Pellets.Pellet in pellets:
		var points: PackedVector3Array = pellet.trail
		for i: int in range(1, points.size()):
			var a: Vector3 = points[i - 1]
			var b: Vector3 = points[i]
			if a.is_equal_approx(b):
				continue
			if not begun:
				_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
				begun = true
			var fade_a: float = _fade(clock - pellet.trail_times[i - 1], stats.tracer_time)
			var fade_b: float = _fade(clock - pellet.trail_times[i], stats.tracer_time)
			var side: Vector3 = (b - a).cross(eye - b).normalized()
			_quad(a, b, side * stats.tracer_width * 0.5 * fade_a, side * stats.tracer_width * 0.5 * fade_b,
					_tint(stats.tracer_color, fade_a), _tint(stats.tracer_color, fade_b))
	if begun:
		_mesh.surface_end()


## 1 for a point passed just now, falling to 0 at `life` seconds old.
func _fade(age: float, life: float) -> float:
	return clampf(1.0 - age / maxf(life, 0.0001), 0.0, 1.0)


func _tint(color: Color, fade: float) -> Color:
	return Color(color.r, color.g, color.b, color.a * fade)


func _quad(a: Vector3, b: Vector3, half_a: Vector3, half_b: Vector3, color_a: Color, color_b: Color) -> void:
	for corner: Array in [[a - half_a, color_a], [a + half_a, color_a], [b + half_b, color_b],
			[a - half_a, color_a], [b + half_b, color_b], [b - half_b, color_b]]:
		_mesh.surface_set_color(corner[1])
		_mesh.surface_add_vertex(corner[0])
