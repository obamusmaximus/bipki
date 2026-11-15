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
var _throw: EnemyThrow


func setup(camera: Camera3D, predictor: TrajectoryPredictor, body: CharacterBody3D, arc_stats: TrajectoryArcStats) -> void:
	_camera = camera
	_predictor = predictor
	_body = body
	stats = arc_stats
	stats.changed.connect(queue_redraw)


## Also draws the release prediction of `throw` while it is being aimed.
func set_throw(throw: EnemyThrow) -> void:
	_throw = throw


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_draw_throw()
	_draw_player_arc()


## Where a thrown enemy would go if released now: a line to its first hit, a marker there, and the damage it would do.
func _draw_throw() -> void:
	if stats == null or _throw == null or not _throw.is_active() or _throw.is_limp or not is_instance_valid(_throw.enemy):
		return
	var flight: ThrowPreview.Result = _throw.preview
	var points: PackedVector3Array = flight.points
	var count: int = points.size() - 1
	for i: int in count:
		if _camera.is_position_behind(points[i]) or _camera.is_position_behind(points[i + 1]):
			continue
		var fade: float = 1.0 - 0.5 * float(i) / float(maxi(count, 1))
		draw_line(_camera.unproject_position(points[i]), _camera.unproject_position(points[i + 1]),
				Color(stats.throw_color, stats.throw_opacity * fade), stats.throw_width, true)
	if not flight.hit or _camera.is_position_behind(flight.hit_point):
		return
	var marker: Vector2 = _camera.unproject_position(flight.hit_point)
	var victim: Enemy = flight.hit_enemy if flight.hit_enemy != null else _throw.enemy
	var damage: float = victim.damage_for_impact(flight.hit_speed)
	if flight.hit_enemy != null:
		damage *= _throw.enemy.stats.collision_damage_scale
	var color: Color = Color(stats.throw_color, 1.0)
	draw_arc(marker, stats.throw_marker_radius, 0.0, TAU, 32, color, 2.0, true)
	draw_circle(marker, 3.0, color)
	var label: String = "KILL" if damage >= victim.health.get_current() else str(roundi(damage))
	draw_string(ThemeDB.fallback_font, marker + Vector2(stats.throw_marker_radius + 6.0, 6.0), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 20, color)


func _draw_player_arc() -> void:
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
