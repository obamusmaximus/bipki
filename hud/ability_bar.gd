class_name AbilityBar
extends HBoxContainer
## The row of ability indicators right of the health bar: swing (S), launch (L) and throw (T). Each flashes when its
## ability is used; the throw's also shows its bullet time running out as an outline travelling clockwise.
## No cooldowns yet, so nothing else is shown.

var _stats: HudStats
var _hook: GrappleHook
var _throw: EnemyThrow
var _swing: AbilityIndicator
var _launch: AbilityIndicator
var _throw_indicator: AbilityIndicator


func setup(hook: GrappleHook, hud_stats: HudStats) -> void:
	_hook = hook
	_throw = hook.get_throw()
	_stats = hud_stats
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_swing = _add_indicator("S")
	_launch = _add_indicator("L")
	_throw_indicator = _add_indicator("T")
	_stats.changed.connect(_apply_stats)
	_apply_stats()
	_hook.attached.connect(_on_attached)
	_hook.launched.connect(_launch.flash.unbind(1))
	_hook.launched_at_enemy.connect(_launch.flash.unbind(1))
	_throw.started.connect(_throw_indicator.flash)


func _process(_delta: float) -> void:
	if _throw == null:
		return
	_throw_indicator.set_outline(1.0 - _throw.get_time_fraction() if _throw.is_active() else 0.0)


func _add_indicator(letter: String) -> AbilityIndicator:
	var indicator := AbilityIndicator.new()
	add_child(indicator)
	indicator.setup(letter, _stats)
	return indicator


func _apply_stats() -> void:
	add_theme_constant_override("separation", roundi(_stats.ability_gap))


## A swing is used when its rope connects. (A launch counts when it fires the player off, below.)
func _on_attached() -> void:
	if _hook.get_mode() == GrappleHook.Mode.SWING:
		_swing.flash()
