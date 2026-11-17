class_name HealthBar
extends Control
## Bar showing the player's health, with the number beside it. Turns red when low. The number sits inside the
## control's own rect (the last NUMBER_WIDTH px), so whatever comes next in a row doesn't overlap it.

const NUMBER_WIDTH: float = 52.0

@export var back_color: Color = Color(0.0, 0.0, 0.0, 0.45)
@export var fill_color: Color = Color(0.35, 0.85, 0.4, 0.9)
@export var low_color: Color = Color(1.0, 0.25, 0.2, 0.95)
## Below this share of full health the bar turns red.
@export_range(0.0, 1.0) var low_share: float = 0.3

var _current: float = 1.0
var _maximum: float = 1.0


func setup(health: Health) -> void:
	_current = health.get_current()
	_maximum = health.max_health
	health.health_changed.connect(_on_health_changed)
	queue_redraw()


func _on_health_changed(current: float, maximum: float) -> void:
	_current = current
	_maximum = maximum
	queue_redraw()


func _draw() -> void:
	var share: float = clampf(_current / maxf(_maximum, 0.001), 0.0, 1.0)
	var colour: Color = fill_color.lerp(low_color, clampf(inverse_lerp(low_share * 2.0, low_share, share), 0.0, 1.0))
	var bar_width: float = maxf(size.x - NUMBER_WIDTH, 0.0)
	draw_rect(Rect2(0.0, 0.0, bar_width, size.y), back_color)
	draw_rect(Rect2(0.0, 0.0, bar_width * share, size.y), colour)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(bar_width + 10.0, size.y), str(ceili(_current)), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color.WHITE)
