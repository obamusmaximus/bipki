class_name ThrowReadout
extends Control
## The throw's HUD while it is being aimed: a ring around the crosshair that fills with the throw's power, a thin
## ring that runs down with the time left, and a marker on the held enemy (an arrow at the screen edge when it is
## out of view, as it is whenever the player has turned away to draw). The release prediction is drawn by
## TrajectoryArc. Full screen; the rings follow the HUD scale.

const EDGE_MARGIN: float = 48.0
const RING_POINTS: int = 48

var _throw: EnemyThrow
var _camera: Camera3D
var _arc_stats: TrajectoryArcStats
var _hud_stats: HudStats
## Set after drawing, so one more redraw clears the rings when the throw ends.
var _redraw_needed: bool = true


func setup(throw: EnemyThrow, camera: Camera3D, arc_stats: TrajectoryArcStats, hud_stats: HudStats) -> void:
	_throw = throw
	_camera = camera
	_arc_stats = arc_stats
	_hud_stats = hud_stats
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if _throw != null and _throw.is_active():
		queue_redraw()
	elif _redraw_needed:
		_redraw_needed = false
		queue_redraw()


func _draw() -> void:
	if _throw == null or not _throw.is_active() or not is_instance_valid(_throw.enemy):
		return
	_redraw_needed = true
	var scale_factor: float = _hud_stats.hud_scale
	var center: Vector2 = size * 0.5
	var radius: float = _arc_stats.throw_gauge_radius * scale_factor
	var width: float = _arc_stats.throw_gauge_width * scale_factor
	var color: Color = Color(0.6, 0.6, 0.6, 0.8) if _throw.is_limp else _arc_stats.throw_color.lerp(Color(1.0, 0.2, 0.1), _throw.power)

	draw_arc(center, radius, 0.0, TAU, RING_POINTS, Color(1.0, 1.0, 1.0, 0.15), width, true)
	if _throw.power > 0.005:
		draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * _throw.power, RING_POINTS, color, width, true)
	var left: float = 1.0 - _throw.get_time_fraction()
	if left > 0.005:
		draw_arc(center, radius + width * 1.8, -PI * 0.5, -PI * 0.5 + TAU * left, RING_POINTS,
				Color(0.5, 0.85, 1.0, 0.8), width * 0.5, true)
	_draw_enemy_marker(center, color, scale_factor)


func _draw_enemy_marker(center: Vector2, color: Color, scale_factor: float) -> void:
	var position: Vector3 = _throw.enemy.get_center()
	var behind: bool = _camera.is_position_behind(position)
	var point: Vector2 = _camera.unproject_position(position)
	var margin: float = minf(EDGE_MARGIN, minf(size.x, size.y) * 0.25)
	var inner: Rect2 = Rect2(Vector2.ZERO, size).grow(-margin)
	if not behind and inner.has_point(point):
		draw_arc(point, 22.0 * scale_factor, 0.0, TAU, 32, color, 2.0 * scale_factor, true)
		return
	var direction: Vector2 = point - center
	if behind:
		direction = -direction
	direction = direction.normalized() if direction.length() > 1.0 else Vector2.DOWN
	var half: Vector2 = size * 0.5 - Vector2.ONE * margin
	var reach: float = minf(half.x / maxf(absf(direction.x), 0.001), half.y / maxf(absf(direction.y), 0.001))
	var tip: Vector2 = center + direction * reach
	var side: Vector2 = direction.orthogonal()
	var length: float = 22.0 * scale_factor
	var triangle := PackedVector2Array([tip, tip - direction * length + side * length * 0.6, tip - direction * length - side * length * 0.6])
	draw_colored_polygon(triangle, color)
