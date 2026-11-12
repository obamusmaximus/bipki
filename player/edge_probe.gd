class_name EdgeProbe
extends RefCounted
## Physics queries for ledges, walls and rooftop rims. Pure functions with no state, so the
## player, the detector and the grapple can all use them. Heights are metres. `feet` is the
## player's feet (the CharacterBody3D origin).

const UP: Vector3 = Vector3.UP
## A surface whose normal's y is above this is a floor or slope, not a wall.
const WALL_MAX_NORMAL_Y: float = 0.5
## A surface whose normal's y is above this counts as a top (a ledge or a rooftop).
const TOP_MIN_NORMAL_Y: float = 0.7


## A climbable ledge found by `find_ledge`.
class Ledge:
	var found: bool = false
	## The top surface, where the feet would stand.
	var point: Vector3 = Vector3.ZERO
	## Metres from the feet up to the top.
	var height: float = 0.0
	## Normal of the face being climbed. It points out toward the player.
	var wall_normal: Vector3 = Vector3.ZERO


## Looks ahead along `direction` for a wall, then down from above it for a top between
## `min_height` and `max_height` above the feet.
static func find_ledge(space: PhysicsDirectSpaceState3D, feet: Vector3, direction: Vector3,
		reach: float, body_radius: float, min_height: float, max_height: float, mask: int) -> Ledge:
	var result := Ledge.new()
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if flat.is_zero_approx():
		return result
	flat = flat.normalized()

	var wall_origin: Vector3 = feet + UP * min_height * 0.5
	var wall_end: Vector3 = wall_origin + flat * (reach + body_radius)
	var wall_hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(wall_origin, wall_end, mask))
	if wall_hit.is_empty():
		return result
	var wall_normal: Vector3 = wall_hit["normal"]
	var wall_point: Vector3 = wall_hit["position"]
	if absf(wall_normal.y) > WALL_MAX_NORMAL_Y:
		return result

	# Drop a ray from just inside the face (on the top), from above the highest allowed top.
	var top_origin: Vector3 = Vector3(wall_point.x, feet.y + max_height + 0.2, wall_point.z) - wall_normal * 0.05
	var top_end: Vector3 = Vector3(top_origin.x, feet.y + min_height * 0.5, top_origin.z)
	var top_hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(top_origin, top_end, mask))
	if top_hit.is_empty():
		return result
	var top_point: Vector3 = top_hit["position"]
	var top_normal: Vector3 = top_hit["normal"]
	if top_normal.y < TOP_MIN_NORMAL_Y:
		return result
	var height: float = top_point.y - feet.y
	if height < min_height or height > max_height:
		return result

	result.found = true
	result.point = top_point
	result.height = height
	result.wall_normal = wall_normal
	return result


## Wall normals to the left and right of the body, as [left, right]. ZERO where there is no wall.
## `side` is the body's sideways axis (any horizontal vector along it).
static func walls_beside(space: PhysicsDirectSpaceState3D, feet: Vector3, side: Vector3,
		reach: float, body_radius: float, mask: int) -> PackedVector3Array:
	var normals := PackedVector3Array([Vector3.ZERO, Vector3.ZERO])
	var axis: Vector3 = Vector3(side.x, 0.0, side.z)
	if axis.is_zero_approx():
		return normals
	axis = axis.normalized()
	var origin: Vector3 = feet + UP * 0.9
	for k: int in 2:
		var dir: Vector3 = -axis if k == 0 else axis
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(origin, origin + dir * (body_radius + reach), mask))
		if hit.is_empty():
			continue
		var hit_normal: Vector3 = hit["normal"]
		if absf(hit_normal.y) <= WALL_MAX_NORMAL_Y:
			normals[k] = hit_normal
	return normals


## If `point` is on a vertical face with a rooftop within `probe_height` above it, returns the
## point moved onto that roof (`inset` in from the edge), with normal UP. Otherwise returns the
## point unchanged. Returns {"point": Vector3, "normal": Vector3}.
static func rim_snap(space: PhysicsDirectSpaceState3D, point: Vector3, normal: Vector3, mask: int,
		probe_height: float = 3.0, inset: float = 0.5) -> Dictionary:
	var result: Dictionary = {"point": point, "normal": normal}
	if normal.y > WALL_MAX_NORMAL_Y:
		return result
	var origin: Vector3 = point + UP * probe_height - normal * 0.15
	var end: Vector3 = Vector3(origin.x, point.y - 0.05, origin.z)
	var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(origin, end, mask))
	if hit.is_empty():
		return result
	var hit_normal: Vector3 = hit["normal"]
	if hit_normal.y < TOP_MIN_NORMAL_Y:
		return result
	var roof_point: Vector3 = hit["position"]
	result["point"] = roof_point - normal * inset
	result["normal"] = UP
	return result


## For a point on a top surface: the horizontal direction toward a drop (a lip or an edge), or
## ZERO if there is no edge nearby. Samples 8 points `radius` out and checks each for a drop of
## at least `drop` metres. An edge exists only when some directions drop and others don't.
static func lip_direction(space: PhysicsDirectSpaceState3D, point: Vector3, mask: int,
		radius: float = 0.6, drop: float = 0.8, depth: float = 4.0) -> Vector3:
	var open: Vector3 = Vector3.ZERO
	var drops: int = 0
	for k: int in 8:
		var angle: float = TAU * k / 8.0
		var dir: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		var origin: Vector3 = point + dir * radius + UP * 0.5
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(origin, origin + Vector3.DOWN * (0.5 + depth), mask))
		if hit.is_empty() or (hit["position"] as Vector3).y < point.y - drop:
			open += dir
			drops += 1
	if drops == 0 or drops == 8:
		return Vector3.ZERO
	return open.normalized()
