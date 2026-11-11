class_name GrappleRope
extends MeshInstance3D
## Visual for the grapple line, plus a glowing hook tip. The line is two crossed ribbons along a
## curve between two points, so it can sag while the tip is in flight and wobble after attach.
## Visual only: nothing here affects physics or aim.

## Rope thickness in metres.
@export var width: float = 0.03
## Ribbon segments along the rope. More is smoother.
@export var segments: int = 14
## Sag of the rope while the tip is in flight, in metres per metre of rope length.
@export var flight_sag: float = 0.03
## Size of the wobble right after attach, in metres per metre of rope length (long ropes are capped).
@export var wobble_amount: float = 0.03
## How fast the wobble dies out (per second).
@export var wobble_decay: float = 4.0
## Wobble speed in radians per second.
@export var wobble_frequency: float = 18.0
## Number of waves along the rope.
@export var wobble_waves: float = 2.0
@export var tip_radius: float = 0.12
@export var tip_color: Color = Color(1.0, 0.75, 0.3)

## Ropes longer than this don't get a proportionally bigger wobble.
const MAX_CURVE_LENGTH: float = 40.0

var _ribbons := ImmediateMesh.new()
var _tip: MeshInstance3D
var _wobble: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	top_level = true
	visible = false
	mesh = _ribbons
	_tip = _make_tip()
	add_child(_tip)


## Starts a decaying wobble, for when the hook bites in.
func kick() -> void:
	_wobble = 1.0


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
	var amplitude: float = wobble_amount * curve_length * _wobble

	var points := PackedVector3Array()
	for i: int in range(segments + 1):
		var t: float = float(i) / float(segments)
		var envelope: float = sin(PI * t) # Zero at both ends, so the rope stays attached.
		var point: Vector3 = from + offset * t
		if flying:
			point.y -= flight_sag * curve_length * envelope
		var phase: float = t * wobble_waves * TAU - _time * wobble_frequency
		point += (side * cos(phase) + other * sin(phase)) * amplitude * envelope
		points.append(point)

	_ribbons.clear_surfaces()
	_add_ribbon(points, side)
	_add_ribbon(points, other)
	_tip.global_position = to


func _process(delta: float) -> void:
	_time += delta
	_wobble *= exp(-wobble_decay * delta)
	if _tip.visible:
		_tip.scale = Vector3.ONE * (1.0 + 0.15 * sin(_time * 20.0))


## One flat ribbon along the points, `axis` being the direction it is wide in.
func _add_ribbon(points: PackedVector3Array, axis: Vector3) -> void:
	var half: Vector3 = axis * (width * 0.5)
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
	tip.mesh = _make_sphere(tip_radius, Color(tip_color.lightened(0.4), 1.0), true)

	var halo := MeshInstance3D.new()
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.mesh = _make_sphere(tip_radius * 2.4, Color(tip_color, 0.25), false)
	tip.add_child(halo)
	return tip


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
		material.emission = tip_color
	sphere.material = material
	return sphere
