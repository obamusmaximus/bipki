class_name TrackMarkers
extends Control
## Thin red rectangles around the enemies the jet tracks (Tracking), sized in world metres so they shrink with
## distance. A marker blinks during the last `marker_blink_time` of its track. Enemies behind the camera get none.
## Full screen and unscaled (in the Hud's Underlay), because it projects world points. Look in TrackingStats.

var _tracking: Tracking
var _camera: Camera3D
var _stats: TrackingStats


func setup(tracking: Tracking, camera: Camera3D, tracking_stats: TrackingStats) -> void:
	_tracking = tracking
	_camera = camera
	_stats = tracking_stats


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _tracking == null:
		return
	var focal: float = size.y * 0.5 / tan(deg_to_rad(_camera.fov) * 0.5)
	var forward: Vector3 = -_camera.global_basis.z
	for enemy: Enemy in _tracking.get_targets():
		var center: Vector3 = enemy.get_center()
		if _camera.is_position_behind(center):
			continue
		var left: float = _tracking.get_time_left(enemy)
		if left < _stats.marker_blink_time and fmod(left * _stats.marker_blink_rate, 1.0) < 0.5:
			continue # The off half of a blink.
		var depth: float = maxf(forward.dot(center - _camera.global_position), 0.01)
		var side: float = maxf(_stats.marker_world_size * focal / depth, _stats.marker_min_px)
		var rect := Rect2(_camera.unproject_position(center) - Vector2.ONE * side * 0.5, Vector2.ONE * side)
		draw_rect(rect, _stats.marker_color, false, _stats.marker_width, true)
