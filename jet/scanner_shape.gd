class_name ScannerShape
extends RefCounted
## The jet scanner's shape on screen: a rectangle `scanner_share` of the screen in the middle, its edges bowed by
## `frame_edge_curve` (each edge a parabola through the two corners). Seen from the camera it is a pyramid in front of
## the view, scaled with the FOV. Tracking asks `contains`, the HUD frame draws `outline`: one shape for both, so the
## frame shows the scanner exactly. Plain math, in screen pixels with the origin at the screen centre.

const EDGE_POINTS: int = 24


## Half the width and height of the rectangle through the corners.
static func half_extents(screen_size: Vector2, stats: TrackingStats) -> Vector2:
	return screen_size * stats.scanner_share * 0.5


## True if `offset` (pixels from the screen centre) is inside the shape.
static func contains(offset: Vector2, screen_size: Vector2, stats: TrackingStats) -> bool:
	var half: Vector2 = half_extents(screen_size, stats)
	if half.x <= 0.0 or half.y <= 0.0:
		return false
	var bow: float = _bow(half, stats)
	var across_x: float = clampf(offset.x / half.x, -1.0, 1.0)
	var across_y: float = clampf(offset.y / half.y, -1.0, 1.0)
	return absf(offset.x) <= half.x + bow * (1.0 - across_y * across_y) \
			and absf(offset.y) <= half.y + bow * (1.0 - across_x * across_x)


## The closed outline, clockwise from the top-left corner, around `center`.
static func outline(center: Vector2, screen_size: Vector2, stats: TrackingStats) -> PackedVector2Array:
	var half: Vector2 = half_extents(screen_size, stats)
	var bow: float = _bow(half, stats)
	var points := PackedVector2Array()
	for i: int in EDGE_POINTS: # Top, left to right.
		var t: float = lerpf(-1.0, 1.0, float(i) / EDGE_POINTS)
		points.append(center + Vector2(t * half.x, -(half.y + bow * (1.0 - t * t))))
	for i: int in EDGE_POINTS: # Right, top to bottom.
		var t: float = lerpf(-1.0, 1.0, float(i) / EDGE_POINTS)
		points.append(center + Vector2(half.x + bow * (1.0 - t * t), t * half.y))
	for i: int in EDGE_POINTS: # Bottom, right to left.
		var t: float = lerpf(1.0, -1.0, float(i) / EDGE_POINTS)
		points.append(center + Vector2(t * half.x, half.y + bow * (1.0 - t * t)))
	for i: int in EDGE_POINTS: # Left, bottom to top.
		var t: float = lerpf(1.0, -1.0, float(i) / EDGE_POINTS)
		points.append(center + Vector2(-(half.x + bow * (1.0 - t * t)), t * half.y))
	points.append(points[0])
	return points


## How far the middle of each edge bows out (px): a share of the frame's height, so both pairs of edges bow alike.
static func _bow(half: Vector2, stats: TrackingStats) -> float:
	return stats.frame_edge_curve * half.y * 2.0
