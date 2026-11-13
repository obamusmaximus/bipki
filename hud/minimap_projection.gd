class_name MinimapProjection
extends RefCounted
## Fixed isometric projection from world space to minimap pixels, fitted so a world box fills a view.
## Yaw turns the city about the vertical axis, pitch tilts it toward the viewer. Plain math, no nodes.

var _yaw_cos: float = 1.0
var _yaw_sin: float = 0.0
var _pitch_cos: float = 1.0
var _pitch_sin: float = 0.0
var _scale: float = 1.0
var _offset: Vector2 = Vector2.ZERO


## Sets the angles and fits `bounds` (a world-space box) into a view of `view_size` pixels, leaving `padding` free.
func setup(bounds: AABB, view_size: Vector2, pitch_degrees: float, yaw_degrees: float, padding: float) -> void:
	_yaw_cos = cos(deg_to_rad(yaw_degrees))
	_yaw_sin = sin(deg_to_rad(yaw_degrees))
	_pitch_cos = cos(deg_to_rad(pitch_degrees))
	_pitch_sin = sin(deg_to_rad(pitch_degrees))
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for i: int in 8:
		var corner: Vector2 = _raw(bounds.get_endpoint(i))
		low = low.min(corner)
		high = high.max(corner)
	var room: Vector2 = (view_size - Vector2.ONE * padding * 2.0).max(Vector2.ONE)
	var extent: Vector2 = (high - low).max(Vector2(0.001, 0.001))
	_scale = minf(room.x / extent.x, room.y / extent.y)
	_offset = view_size * 0.5 - (low + high) * 0.5 * _scale


## Pixel position of a world point inside the view.
func project(point: Vector3) -> Vector2:
	return _raw(point) * _scale + _offset


## Pixels per metre along the ground axes (before the pitch foreshortening).
func get_scale() -> float:
	return _scale


func _raw(point: Vector3) -> Vector2:
	var across: float = point.x * _yaw_cos - point.z * _yaw_sin
	var depth: float = point.x * _yaw_sin + point.z * _yaw_cos
	return Vector2(across, depth * _pitch_sin - point.y * _pitch_cos)
