class_name FuelGauge
extends Control
## Upright bar on the right edge of the screen showing the jetpack's fuel, like the grapple's reel bar: it drains
## downward while thrusting and refills after. Reddens when low. Shown while the tank isn't full.

@export var back_color: Color = Color(0.0, 0.0, 0.0, 0.45)
@export var fill_color: Color = Color(1.0, 0.8, 0.45, 0.85)
@export var low_color: Color = Color(1.0, 0.35, 0.3, 0.9)
## Below this share of the tank the fill turns toward low_color.
@export_range(0.0, 1.0, 0.01) var low_share: float = 0.25

var _motor: JetMotor
var _drawn_ratio: float = -1.0


func setup(motor: JetMotor) -> void:
	_motor = motor
	modulate.a = 0.0


func _process(_delta: float) -> void:
	if _motor == null:
		return
	var ratio: float = _motor.get_fuel_ratio()
	var shown: bool = ratio < 0.999 or _motor.get_thrust() != JetMotor.Thrust.OFF
	modulate.a = 1.0 if shown else 0.0 # Faded, not hidden, so it keeps its place in the layout.
	if not is_equal_approx(ratio, _drawn_ratio):
		_drawn_ratio = ratio
		queue_redraw()


func _draw() -> void:
	if _motor == null:
		return
	var ratio: float = _motor.get_fuel_ratio()
	var low: float = clampf(inverse_lerp(low_share, 0.0, ratio), 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, size), back_color)
	draw_rect(Rect2(0.0, size.y * (1.0 - ratio), size.x, size.y * ratio), fill_color.lerp(low_color, low))
