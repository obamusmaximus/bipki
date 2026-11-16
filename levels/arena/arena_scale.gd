class_name ArenaScale
extends Node3D
## The number labels of the arena's scale bars. On each of the six surfaces the two central bars (at 50 m, drawn by
## grid.gdshader) read 1 to 99 m, a label at every metre: small at every metre, bigger at every thin-bar step (5 m)
## and biggest at every bold-bar step (10 m). Along the horizontal bar the number sits above and just right of its
## notch, along the vertical bar to the left and above it. The numbers are world coordinates, and the world origin is
## a bottom corner of the room, so every bar reads 0 to 100 from that corner.
##
## The digits are real font outlines (TextMesh), one instanced mesh per digit 0 to 9, so the thousand-odd digits cost
## ten draw calls and no textures. Near the crossing of the two bars a few labels would collide, so they are left out
## or moved to the free quarter (see _build).

const ROOM: float = 100.0
const FONT_SIZE: int = 64
## Labels float this far off the surface so they don't z-fight with it (m).
const SURFACE_OFFSET: float = 0.05
## Width of one digit cell as a share of the label size.
const DIGIT_ADVANCE: float = 0.6
## Gaps between a notch and its label, sideways and in height (m).
const GAP_X: float = 0.08
const GAP_Y: float = 0.12
## Gap between a vertical bar's notch and the label above it (m).
const GAP_B: float = 0.06
## Where the centre label of the horizontal bar starts, clear of the vertical bar (m).
const CENTRE_START: float = 0.3
## Where the top of the centre label of the vertical bar sits below the horizontal bar (m).
const CENTRE_DROP: float = 0.4

var _stats: ArenaStats
var _material: StandardMaterial3D
var _digit_meshes: Array[TextMesh] = []
var _digit_instances: Array[MultiMeshInstance3D] = []


func setup(stats: ArenaStats) -> void:
	_stats = stats
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for digit: int in 10:
		var mesh := TextMesh.new()
		mesh.text = str(digit)
		mesh.font_size = FONT_SIZE
		mesh.pixel_size = 1.0 / FONT_SIZE # one em is one metre; instances scale it to the label size
		mesh.depth = 0.0
		mesh.curve_step = 1.0
		mesh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_digit_meshes.append(mesh)
		var instance := MultiMeshInstance3D.new()
		instance.material_override = _material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)
		_digit_instances.append(instance)
	_stats.changed.connect(_build)
	_build()


func _build() -> void:
	_material.albedo_color = _stats.label_color
	var transforms: Array = []
	for digit: int in 10:
		var list: Array[Transform3D] = []
		transforms.append(list)
	var sizes: Array[float] = [_stats.label_size, _stats.label_size_mid, _stats.label_size_long]
	var lengths: Array[float] = [_stats.notch_length, _stats.notch_length_mid, _stats.notch_length_long]
	var cap: float = _digit_meshes[0].get_aabb().size.y
	# How far from the vertical bar the widest small label reaches. Bigger labels sit beyond it, so they never touch.
	var small_reach: float = lengths[0] + GAP_X + 2.0 * DIGIT_ADVANCE * sizes[0] + 0.1
	var centre: Vector3 = Vector3.ONE * (ROOM * 0.5)
	for face: Basis in _face_bases():
		var normal: Vector3 = face.z
		var origin: Vector3 = centre - normal * (ROOM * 0.5) + normal * SURFACE_OFFSET
		# The number rises along the world axis, which may run against the local direction, so the sign of the axis
		# component (+1 or -1) is applied to get the notch's local position.
		var sign_a: float = face.x.x + face.x.y + face.x.z
		var sign_b: float = face.y.x + face.y.y + face.y.z
		for value: int in range(1, int(ROOM)):
			var offset: float = value - ROOM * 0.5
			var tier: int = _tier(value)
			var size: float = sizes[tier]
			var text: String = str(value)
			var width: float = text.length() * DIGIT_ADVANCE * size
			var a_notch: float = offset * sign_a
			var b_notch: float = offset * sign_b
			var at_centre: bool = is_zero_approx(offset)
			# Horizontal bar: label above it, just right of the notch (the centre one clear of the vertical bar).
			_place(transforms, face, origin, text, size, CENTRE_START if at_centre else a_notch + GAP_X, lengths[tier] + GAP_Y)
			# Vertical bar: label left of it, just above the notch. The centre one goes to the free quarter below and
			# right of the crossing, and the few just above it would run into the horizontal bar's labels: left out.
			if at_centre:
				_place(transforms, face, origin, text, size, lengths[tier] + GAP_X, -CENTRE_DROP - cap * size)
			elif b_notch > 0.0 and b_notch < _stats.notch_clear:
				continue
			else:
				var reach: float = lengths[tier] + GAP_X if tier == 0 else maxf(lengths[tier] + GAP_X, small_reach)
				_place(transforms, face, origin, text, size, -reach - width, b_notch + GAP_B)
	for digit: int in 10:
		var list: Array = transforms[digit]
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = _digit_meshes[digit]
		multi.instance_count = list.size()
		for i: int in list.size():
			multi.set_instance_transform(i, list[i])
		_digit_instances[digit].multimesh = multi


## Adds the digits of `text` to the lists: left edge at `start_a` along the reading direction, bottoms at `bottom_b`
## above the surface's central line, `size` metres tall. Each glyph is centred in its cell by its own outline.
func _place(transforms: Array, face: Basis, origin: Vector3, text: String, size: float, start_a: float, bottom_b: float) -> void:
	var advance: float = DIGIT_ADVANCE * size
	var scaled: Basis = face.scaled_local(Vector3.ONE * size)
	for k: int in text.length():
		var digit: int = text.unicode_at(k) - 48
		var box: AABB = _digit_meshes[digit].get_aabb()
		var a: float = start_a + (k + 0.5) * advance - (box.position.x + box.size.x * 0.5) * size
		var b: float = bottom_b - box.position.y * size
		(transforms[digit] as Array).append(Transform3D(scaled, origin + face.x * a + face.y * b))


## 0 for a plain metre, 1 for a thin-bar step, 2 for a bold-bar step.
func _tier(value: int) -> int:
	var major: int = maxi(roundi(_stats.major_spacing), 1)
	var minor: int = maxi(roundi(_stats.minor_spacing), 1)
	if value % major == 0:
		return 2
	if value % minor == 0:
		return 1
	return 0


## One basis per surface: x is the reading direction, y is up, z is the inward normal (the way the text faces).
func _face_bases() -> Array[Basis]:
	return [
		Basis(Vector3.RIGHT, Vector3.FORWARD, Vector3.UP),       # floor
		Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN),        # ceiling
		Basis(Vector3.FORWARD, Vector3.UP, Vector3.RIGHT),       # wall at x = 0
		Basis(Vector3.BACK, Vector3.UP, Vector3.LEFT),           # wall at x = 100
		Basis(Vector3.RIGHT, Vector3.UP, Vector3.BACK),          # wall at z = 0
		Basis(Vector3.LEFT, Vector3.UP, Vector3.FORWARD),        # wall at z = 100
	]
