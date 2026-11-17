class_name JetAbilityBar
extends HBoxContainer
## The jet's ability indicators right of the health bar, like the grapple's AbilityBar: hover (H), orange while on;
## surge (S), whose outline grows clockwise while the jet key is held toward a surge and which is orange while
## thrusting (surge or afterburner).

var _stats: HudStats
var _motor: JetMotor
var _hover: AbilityIndicator
var _surge: AbilityIndicator


func setup(motor: JetMotor, hud_stats: HudStats) -> void:
	_motor = motor
	_stats = hud_stats
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover = _add_indicator("H")
	_surge = _add_indicator("S")
	_stats.changed.connect(_apply_stats)
	_apply_stats()


func _process(_delta: float) -> void:
	if _motor == null:
		return
	_hover.set_lit(_motor.is_hovering())
	_surge.set_lit(_motor.get_thrust() != JetMotor.Thrust.OFF)
	_surge.set_outline(_motor.get_hold_ratio(), true)


func _add_indicator(letter: String) -> AbilityIndicator:
	var indicator := AbilityIndicator.new()
	add_child(indicator)
	indicator.setup(letter, _stats)
	return indicator


func _apply_stats() -> void:
	add_theme_constant_override("separation", roundi(_stats.ability_gap))
