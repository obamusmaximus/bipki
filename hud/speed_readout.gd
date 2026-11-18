class_name SpeedReadout
extends Control
## Speedometer beside the crosshair: a 180 degree gauge that fills toward the soft speed limit (PlayerStats
## `soft_speed_limit`, the speed the game levels off near), with the horizontal speed (X and Z only, not climbing or falling) in m/s in the middle. The last stretch of the
## dial is a red zone; the fill and the number shift from white to orange to red as the speed climbs into it.
## Full screen and centred like the crosshair, so it scales around the same point and keeps its distance from it.

## The dial starts at 6 o'clock and sweeps clockwise up the left side to 12 o'clock.
const START_ANGLE: float = deg_to_rad(90.0)
const SWEEP: float = deg_to_rad(180.0)
const TICKS: int = 5
const ARC_POINTS: int = 64

var _body: CharacterBody3D
var _player_stats: PlayerStats
var _stats: HudStats
## The speed the dial shows: the real speed eased toward, so the fill glides instead of jittering.
var _shown_speed: float = 0.0
var _drawn_ratio: float = -1.0
var _drawn_number: int = -1
## A short tag under the unit (a loadout's speed mode, e.g. the jet's "A/B"). Empty draws nothing.
var _tag: String = ""


func setup(body: CharacterBody3D, player_stats: PlayerStats, hud_stats: HudStats) -> void:
	_body = body
	_player_stats = player_stats
	_stats = hud_stats
	_stats.changed.connect(queue_redraw)


func _process(delta: float) -> void:
	if _body == null:
		return
	var speed: float = _horizontal_speed()
	# Real time like the rest of the HUD: bullet time scales the frame delta.
	var real_delta: float = delta / maxf(Engine.time_scale, 0.01)
	var follow: float = 1.0 if _stats.speedometer_smoothing <= 0.0 else 1.0 - exp(-_stats.speedometer_smoothing * real_delta)
	_shown_speed = lerpf(_shown_speed, speed, follow)
	var ratio: float = _ratio()
	var number: int = roundi(speed)
	if not is_equal_approx(ratio, _drawn_ratio) or number != _drawn_number:
		_drawn_ratio = ratio
		_drawn_number = number
		queue_redraw()


func _draw() -> void:
	if _body == null:
		return
	var s: HudStats = _stats
	var radius: float = s.speedometer_size * 0.5
	var center: Vector2 = size * 0.5 + Vector2(s.speedometer_offset_x, s.speedometer_offset_y)
	var width: float = maxf(radius * 0.16, 3.0)
	var arc_radius: float = radius - width * 0.5
	var ratio: float = _ratio()
	var tint: Color = _tint(ratio)

	draw_circle(center, radius + 2.0, s.speedometer_back_color)
	draw_arc(center, arc_radius, START_ANGLE, START_ANGLE + SWEEP, ARC_POINTS, s.speedometer_track_color, width, true)
	# The red zone, faint, so the player sees where the top of the dial is before they reach it.
	var warn: float = clampf(s.speedometer_warn_start, 0.0, 1.0)
	if warn < 1.0:
		draw_arc(center, arc_radius, START_ANGLE + SWEEP * warn, START_ANGLE + SWEEP, ARC_POINTS,
				Color(s.speedometer_max_color, 0.35), width, true)
	var filled: float = clampf(ratio, 0.0, 1.0)
	if filled > 0.002:
		draw_arc(center, arc_radius, START_ANGLE, START_ANGLE + SWEEP * filled, ARC_POINTS, tint, width, true)
		var tip: Vector2 = center + Vector2.from_angle(START_ANGLE + SWEEP * filled) * arc_radius
		draw_circle(tip, width * 0.8, Color(1.0, 1.0, 1.0, 0.95))
	for i: int in TICKS + 1:
		var direction: Vector2 = Vector2.from_angle(START_ANGLE + SWEEP * i / float(TICKS))
		draw_line(center + direction * (radius - width - 2.0), center + direction * (radius - width - 6.0),
				Color(1.0, 1.0, 1.0, 0.5), 1.5, true)

	var font: Font = ThemeDB.fallback_font
	var number_size: int = roundi(s.speedometer_size * 0.34)
	var unit_size: int = roundi(s.speedometer_size * 0.14)
	var number: String = str(roundi(_horizontal_speed()))
	var number_pos := Vector2(center.x - radius, center.y + number_size * 0.3)
	draw_string_outline(font, number_pos, number, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, number_size, 5, Color(0.0, 0.0, 0.0, 0.8))
	draw_string(font, number_pos, number, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, number_size, tint.lerp(Color.WHITE, 0.35))
	var unit_pos := Vector2(center.x - radius, center.y + number_size * 0.3 + unit_size + 3.0)
	draw_string_outline(font, unit_pos, "m/s", HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, unit_size, 3, Color(0.0, 0.0, 0.0, 0.8))
	draw_string(font, unit_pos, "m/s", HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, unit_size, Color(1.0, 1.0, 1.0, 0.7))
	if not _tag.is_empty():
		var tag_pos := Vector2(unit_pos.x, unit_pos.y + unit_size + 4.0)
		draw_string_outline(font, tag_pos, _tag, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, unit_size, 3, Color(0.0, 0.0, 0.0, 0.8))
		draw_string(font, tag_pos, _tag, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, unit_size, s.speedometer_warn_color)


func set_tag(text: String) -> void:
	if text != _tag:
		_tag = text
		queue_redraw()


## The speed along the ground plane (X and Z): climbing and falling don't count.
func _horizontal_speed() -> float:
	return Vector2(_body.velocity.x, _body.velocity.z).length()


## How far up the dial the eased speed is. 1 is the soft speed limit; it can go past 1 briefly.
func _ratio() -> float:
	return _shown_speed / maxf(_player_stats.soft_speed_limit, 1.0)


## White-blue at low speed, shifting to orange from `speedometer_warn_start`, and red at the top of the dial.
func _tint(ratio: float) -> Color:
	var warn: float = clampf(_stats.speedometer_warn_start, 0.0, 0.99)
	var amount: float = clampf(inverse_lerp(warn, 1.0, ratio), 0.0, 1.0)
	if amount < 0.5:
		return _stats.speedometer_color.lerp(_stats.speedometer_warn_color, amount * 2.0)
	return _stats.speedometer_warn_color.lerp(_stats.speedometer_max_color, (amount - 0.5) * 2.0)
