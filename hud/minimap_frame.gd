class_name MinimapFrame
extends RefCounted
## Sizes the minimap panel around its projected wireframe so the wireframe looks centred. The bounding box's middle
## is the true centre, but an isometric city is lopsided (one tall corner, a long thin side), so the eye reads its
## centre at the centroid of its outline's area instead. The panel is grown around that point until the wireframe
## fits with `padding` at its tightest side. Plain math, no nodes.

## The panel's size (px).
var size: Vector2 = Vector2.ZERO
## How far to move the wireframe so its centre lands in the middle of the panel (px).
var shift: Vector2 = Vector2.ZERO


## `points` are the wireframe's projected points. `visual_centering` blends the bounding-box middle (0) with the
## area centroid (1).
static func fit(points: PackedVector2Array, padding: float, visual_centering: float) -> MinimapFrame:
	var frame := MinimapFrame.new()
	if points.is_empty():
		return frame
	var low: Vector2 = points[0]
	var high: Vector2 = points[0]
	for point: Vector2 in points:
		low = low.min(point)
		high = high.max(point)
	var middle: Vector2 = (low + high) * 0.5
	var centre: Vector2 = middle.lerp(_area_centroid(Geometry2D.convex_hull(points), middle), clampf(visual_centering, 0.0, 1.0))
	var half: Vector2 = (centre - low).max(high - centre) + Vector2.ONE * padding
	frame.size = half * 2.0
	frame.shift = half - centre
	return frame


## Centroid of a polygon's area (shoelace formula). `fallback` if the polygon has no area.
static func _area_centroid(polygon: PackedVector2Array, fallback: Vector2) -> Vector2:
	var area: float = 0.0
	var sum := Vector2.ZERO
	for i: int in polygon.size():
		var a: Vector2 = polygon[i]
		var b: Vector2 = polygon[(i + 1) % polygon.size()]
		var cross: float = a.cross(b)
		area += cross
		sum += (a + b) * cross
	if absf(area) < 0.001:
		return fallback
	return sum / (3.0 * area)
