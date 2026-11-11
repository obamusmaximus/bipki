class_name BeamVisual
extends Node3D
## Draws the drone's beam attack: a growing orb while it charges, a thin warning line while the aim is
## locked, and a bright beam for a moment when it fires. Everything is built in code.

@export var charge_orb_size: float = 0.7
@export var warning_radius: float = 0.05
## Seconds the fired beam stays visible while it fades.
@export var fire_fade_time: float = 0.3

var _beam: BeamAttack
var _drone: Node3D
var _orb: MeshInstance3D
var _warning: MeshInstance3D
var _blast: MeshInstance3D
var _blast_from: Vector3
var _blast_to: Vector3
var _blast_left: float = 0.0


func setup(beam: BeamAttack, drone: Node3D) -> void:
	_beam = beam
	_drone = drone
	_beam.fired.connect(_on_fired)


func _ready() -> void:
	top_level = true  # Everything below is placed in world space.
	_orb = _make_mesh(SphereMesh.new(), Color(1.0, 0.45, 0.1, 0.9))
	_warning = _make_mesh(_unit_cylinder(), Color(1.0, 0.1, 0.05, 0.55))
	_blast = _make_mesh(_unit_cylinder(), Color(1.0, 0.85, 0.6, 1.0))


func _process(delta: float) -> void:
	if _beam == null:
		return
	var state: BeamAttack.State = _beam.get_state()
	_orb.visible = state == BeamAttack.State.CHARGING
	if _orb.visible:
		var size: float = charge_orb_size * maxf(_beam.get_charge_fraction(), 0.05)
		_orb.global_position = _drone.global_position - _drone.global_basis.z * 1.1
		_orb.scale = Vector3.ONE * size
	_warning.visible = state == BeamAttack.State.AIMING
	if _warning.visible:
		var pulse: float = 1.0 + 0.5 * sin(Time.get_ticks_msec() * 0.03)
		_place_beam(_warning, _drone.global_position, _beam.get_aim_end(), warning_radius * pulse)
	_blast_left = maxf(_blast_left - delta, 0.0)
	_blast.visible = _blast_left > 0.0
	if _blast.visible:
		var fade: float = _blast_left / fire_fade_time
		_place_beam(_blast, _blast_from, _blast_to, _beam.beam_radius * fade)


func _on_fired(from: Vector3, to: Vector3, _hit_target: bool) -> void:
	_blast_from = from
	_blast_to = to
	_blast_left = fire_fade_time


## Stretches a unit cylinder (height 1, radius 1, along Y) between two points.
func _place_beam(node: MeshInstance3D, from: Vector3, to: Vector3, radius: float) -> void:
	var length: float = from.distance_to(to)
	if length < 0.01:
		node.visible = false
		return
	var dir: Vector3 = (to - from) / length
	var rotation: Basis = Basis(Vector3.RIGHT, PI) if dir.dot(Vector3.UP) < -0.999 else Basis(Quaternion(Vector3.UP, dir))
	node.global_transform = Transform3D(rotation * Basis.from_scale(Vector3(radius, length, radius)), (from + to) * 0.5)


func _unit_cylinder() -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.0
	mesh.height = 1.0
	mesh.radial_segments = 8
	mesh.rings = 1
	return mesh


func _make_mesh(mesh: Mesh, colour: Color) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = colour
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.visible = false
	add_child(node)
	return node
