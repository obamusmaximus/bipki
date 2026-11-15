class_name GrappleRope
extends MeshInstance3D
## Visual for the grapple line, plus a glowing hook tip. The line is two crossed ribbons along a
## curve between two points, so it can sag while the tip is in flight and wobble after attach.
## Visual only: nothing here affects physics or aim.

var stats: GrappleStats

## Ropes longer than this don't get a proportionally bigger wobble.
const MAX_CURVE_LENGTH: float = 40.0

var _ribbons := ImmediateMesh.new()
var _tip: MeshInstance3D
var _wobble: float = 0.0
var _time: float = 0.0
## While the rope retracts after a release, a loose-rope sim draws it instead of the formula.
var _sim: RopeSim
var _hand: Vector3 = Vector3.ZERO


func _ready() -> void:
	top_level = true
	visible = false
	mesh = _ribbons


## Called once by GrappleHook. Builds the hook tip from the stats and rebuilds it when they change.
func setup(grapple_stats: GrappleStats) -> void:
	stats = grapple_stats
	_tip = _make_tip()
	add_child(_tip)
	_apply_tip_look()
	stats.changed.connect(_apply_tip_look)


## Starts a decaying wobble, for when the hook bites in.
func kick() -> void:
	_wobble = 1.0


## Lets go of the rope's end: it springs back to the hand with the slack whipping about, then hides itself.
## Call set_hand() each frame while it runs.
func retract(hand: Vector3, end: Vector3) -> void:
	_sim = RopeSim.new()
	_sim.begin(hand, end, stats.rope_segments, stats.rope_retract_whip)
	_hand = hand
	visible = true


## Stops a retract at once (a new fire takes the rope over) and hides the rope.
func stop_retract() -> void:
	_sim = null
	visible = false


## The hand position the retracting rope is pinned to. Called every frame by GrappleHook.
func set_hand(hand: Vector3) -> void:
	_hand = hand


func is_retracting() -> bool:
	return _sim != null


## Draws the rope from `from` to `to`. Pass `flying` while the tip is still in flight to sag the rope.
func stretch_between(from: Vector3, to: Vector3, flying: bool = false) -> void:
	var offset: Vector3 = to - from
	var length: float = offset.length()
	if length < 0.001:
		return

	var along: Vector3 = offset / length
	var helper: Vector3 = Vector3.RIGHT if absf(along.y) > 0.99 else Vector3.UP
	var side: Vector3 = along.cross(helper).normalized()
	var other: Vector3 = along.cross(side)
	var curve_length: float = minf(length, MAX_CURVE_LENGTH)
	var amplitude: float = stats.rope_wobble_amount * curve_length * _wobble

	var points := PackedVector3Array()
	for i: int in range(stats.rope_segments + 1):
		var t: float = float(i) / float(stats.rope_segments)
		var envelope: float = sin(PI * t) # Zero at both ends, so the rope stays attached.
		var point: Vector3 = from + offset * t
		if flying:
			point.y -= stats.rope_flight_sag * curve_length * envelope
		var phase: float = t * stats.rope_wobble_waves * TAU - _time * stats.rope_wobble_frequency
		point += (side * cos(phase) + other * sin(phase)) * amplitude * envelope
		points.append(point)

	_ribbons.clear_surfaces()
	_add_ribbon(points, side)
	_add_ribbon(points, other)
	_tip.global_position = to


func _process(delta: float) -> void:
	if stats == null:
		return
	if _sim != null:
		_step_retract(delta)
	_time += delta
	_wobble *= exp(-stats.rope_wobble_decay * delta)
	if _tip.visible:
		_tip.scale = Vector3.ONE * (1.0 + 0.15 * sin(_time * 20.0))


## Runs the retract sim on real time (so it stays lively in bullet time) and draws it. Ends when it has settled.
func _step_retract(delta: float) -> void:
	var real_delta: float = minf(delta / maxf(Engine.time_scale, 0.001), 0.05)
	_sim.step(real_delta, _hand, stats.rope_retract_stiffness, stats.rope_retract_damping,
			stats.rope_retract_speed, stats.rope_retract_gravity)
	var settled: bool = _sim.get_end().distance_to(_hand) < 0.6 and _sim.get_end_speed() < 6.0
	if settled or _sim.age >= stats.rope_retract_max_time:
		stop_retract()
		return
	_draw_loose(_sim.points)


## Draws a rope that bends anywhere: two crossed ribbons whose axes follow the line at each point.
func _draw_loose(points: PackedVector3Array) -> void:
	var count: int = points.size()
	var firsts := PackedVector3Array()
	var seconds := PackedVector3Array()
	for i: int in count:
		var tangent: Vector3 = points[mini(i + 1, count - 1)] - points[maxi(i - 1, 0)]
		if tangent.is_zero_approx():
			tangent = Vector3.FORWARD
		tangent = tangent.normalized()
		var helper: Vector3 = Vector3.RIGHT if absf(tangent.y) > 0.99 else Vector3.UP
		var first: Vector3 = tangent.cross(helper).normalized()
		firsts.append(first)
		seconds.append(tangent.cross(first))
	_ribbons.clear_surfaces()
	_add_ribbon_axes(points, firsts)
	_add_ribbon_axes(points, seconds)
	_tip.global_position = points[count - 1]


func _add_ribbon_axes(points: PackedVector3Array, axes: PackedVector3Array) -> void:
	var half_width: float = stats.rope_width * 0.5
	_ribbons.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i: int in points.size():
		_ribbons.surface_add_vertex(points[i] - axes[i] * half_width)
		_ribbons.surface_add_vertex(points[i] + axes[i] * half_width)
	_ribbons.surface_end()


## One flat ribbon along the points, `axis` being the direction it is wide in.
func _add_ribbon(points: PackedVector3Array, axis: Vector3) -> void:
	var half: Vector3 = axis * (stats.rope_width * 0.5)
	_ribbons.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for point: Vector3 in points:
		_ribbons.surface_add_vertex(point - half)
		_ribbons.surface_add_vertex(point + half)
	_ribbons.surface_end()


## A bright core with a larger, faint halo around it.
func _make_tip() -> MeshInstance3D:
	var tip := MeshInstance3D.new()
	tip.top_level = true
	tip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var halo := MeshInstance3D.new()
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tip.add_child(halo)
	return tip


## Sizes and colours the tip core and its halo from the stats.
func _apply_tip_look() -> void:
	_tip.mesh = _make_sphere(stats.tip_radius, Color(stats.tip_color.lightened(0.4), 1.0), true)
	(_tip.get_child(0) as MeshInstance3D).mesh = _make_sphere(stats.tip_radius * 2.4, Color(stats.tip_color, 0.25), false)


func _make_sphere(radius: float, color: Color, emissive: bool) -> SphereMesh:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 12
	sphere.rings = 6
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emissive:
		material.emission_enabled = true
		material.emission = stats.tip_color
	sphere.material = material
	return sphere
