class_name GrappleRope
extends MeshInstance3D
## Visual for the grapple line. Uses a unit-height cylinder stretched between two points.


func _ready() -> void:
	top_level = true
	visible = false


func stretch_between(from: Vector3, to: Vector3) -> void:
	var offset: Vector3 = to - from
	var length: float = offset.length()
	if length < 0.001:
		return

	var up: Vector3 = offset / length
	var helper: Vector3 = Vector3.RIGHT if absf(up.y) > 0.99 else Vector3.UP
	var x_axis: Vector3 = up.cross(helper).normalized()
	var z_axis: Vector3 = x_axis.cross(up)
	var basis_scaled: Basis = Basis(x_axis, up, z_axis).scaled_local(Vector3(1.0, length, 1.0))
	global_transform = Transform3D(basis_scaled, from + offset * 0.5)
