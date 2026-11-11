class_name LaunchAim
extends RefCounted
## Works out where a launch aims: above the hit point, shifted sideways by where the crosshair points.


## The aim point is the hit point raised by `height_offset`, plus a sideways shift. The shift is how far
## left or right of the hit point the crosshair points (at the hit point's distance, perpendicular to the
## player-to-hit direction), clamped to `side_offset`.
static func aim_point(player_position: Vector3, hit_point: Vector3, camera_position: Vector3,
		camera_forward: Vector3, height_offset: float, side_offset: float) -> Vector3:
	var aim: Vector3 = hit_point + Vector3.UP * height_offset
	var to_hit: Vector3 = hit_point - player_position
	to_hit.y = 0.0
	if to_hit.is_zero_approx():
		return aim
	var right: Vector3 = to_hit.normalized().cross(Vector3.UP)
	var look_point: Vector3 = camera_position + camera_forward * camera_position.distance_to(hit_point)
	var side: float = clampf((look_point - hit_point).dot(right), -side_offset, side_offset)
	return aim + right * side
