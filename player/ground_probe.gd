class_name GroundProbe
extends RefCounted
## Finds the terrain height under a point by casting rays straight down over a disc around it.

const RING_SAMPLES: int = 8
## Rays start this far off the surface that was hit, so they don't begin inside it.
const SURFACE_LIFT: float = 0.1


## Highest terrain y found under `point` within `radius` metres horizontally, or NAN if there is none.
## `normal` is the surface normal at `point`. Rays that start inside a solid (e.g. beside a tower wall
## the point is on) pass through it, so a wall hit resolves to the ground at its foot.
static func find_ground_height(space: PhysicsDirectSpaceState3D, point: Vector3, normal: Vector3,
		radius: float, mask: int, max_depth: float) -> float:
	var base: Vector3 = point + normal * SURFACE_LIFT
	var highest: float = NAN
	for i: int in RING_SAMPLES + 1:
		var offset: Vector3 = Vector3.ZERO
		if i < RING_SAMPLES: # The last sample is the centre.
			var angle: float = TAU * float(i) / float(RING_SAMPLES)
			offset = Vector3(cos(angle), 0.0, sin(angle)) * radius
		var from: Vector3 = base + offset
		var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * max_depth, mask)
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			continue
		var y: float = (hit["position"] as Vector3).y
		if is_nan(highest) or y > highest:
			highest = y
	return highest
