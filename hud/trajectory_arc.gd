class_name TrajectoryArc
extends Control
## A faint arc on the HUD showing where the player is headed (from TrajectoryPredictor): the swing path while
## on the rope, a plain flight path in the air. It fades toward its far end, and is hidden where it passes
## behind a building. Not drawn on the ground. Full-screen
## and not scaled with the HUD, since it follows points in the 3D view.

var stats: TrajectoryArcStats

var _camera: Camera3D
var _predictor: TrajectoryPredictor
var _body: CharacterBody3D


func setup(camera: Camera3D, predictor: TrajectoryPredictor, body: CharacterBody3D, arc_stats: TrajectoryArcStats) -> void:
	_camera = camera
	_predictor = predictor
	_body = body
	stats = arc_stats
	stats.changed.connect(queue_redraw)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if stats == null or _predictor == null or not stats.arc_visible:
		return
	var points: PackedVector3Array = _predictor.points
	if points.size() < 2 or _body.velocity.length() < stats.arc_min_speed:
		return
	var seen: PackedByteArray = _predictor.points_visible
	var count: int = points.size() - 1
	for i: int in count:
		if stats.arc_hide_behind_buildings and (seen[i] == 0 or seen[i + 1] == 0):
			continue
		if _camera.is_position_behind(points[i]) or _camera.is_position_behind(points[i + 1]):
			continue
		var fade: float = pow(1.0 - float(i) / float(count), stats.arc_fade_power)
		draw_line(_camera.unproject_position(points[i]), _camera.unproject_position(points[i + 1]),
				Color(stats.arc_color, stats.arc_opacity * fade), stats.arc_width, true)
