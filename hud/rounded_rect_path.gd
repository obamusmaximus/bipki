class_name RoundedRectPath
extends RefCounted
## Points along the outline of a rounded rectangle, clockwise from the middle of its top edge. Plain math, no nodes.

const CORNER_POINTS: int = 8


## The whole outline as a closed polyline (the last point repeats the first).
static func outline(rect: Rect2, radius: float) -> PackedVector2Array:
	var r: float = clampf(radius, 0.0, minf(rect.size.x, rect.size.y) * 0.5)
	var points := PackedVector2Array()
	var top_mid := Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y)
	points.append(top_mid)
	# Corner centres clockwise from top-right; each arc sweeps a quarter turn (screen y points down, so + is clockwise).
	var centres: Array[Vector2] = [
		Vector2(rect.end.x - r, rect.position.y + r),
		Vector2(rect.end.x - r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.position.y + r),
	]
	for i: int in 4:
		var start: float = -PI * 0.5 + i * PI * 0.5
		for j: int in CORNER_POINTS + 1:
			points.append(centres[i] + Vector2.from_angle(start + PI * 0.5 * j / CORNER_POINTS) * r)
	points.append(top_mid)
	return points


## The last `share` (0-1) of the outline: as the share drops, its tail travels clockwise toward the top middle.
static func tail(rect: Rect2, radius: float, share: float) -> PackedVector2Array:
	var points: PackedVector2Array = outline(rect, radius)
	var lengths := PackedFloat32Array([0.0])
	for i: int in range(1, points.size()):
		lengths.append(lengths[i - 1] + points[i - 1].distance_to(points[i]))
	var cut: float = lengths[lengths.size() - 1] * (1.0 - clampf(share, 0.0, 1.0))
	var result := PackedVector2Array()
	for i: int in range(1, points.size()):
		if lengths[i] < cut:
			continue
		if result.is_empty():
			var t: float = inverse_lerp(lengths[i - 1], lengths[i], cut) if lengths[i] > lengths[i - 1] else 0.0
			result.append(points[i - 1].lerp(points[i], t))
		result.append(points[i])
	return result
