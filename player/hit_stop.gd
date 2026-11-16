class_name HitStop
extends Node
## A split-second freeze: drops `Engine.time_scale` very low and restores it after a short real-time wait.
## It stays out of the way of bullet time: it does nothing while the game is already slowed, and only
## restores the scale if nothing else has changed it in the meantime.

var _scale: float = 1.0
var _active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Freezes to `time_scale` for `real_seconds`.
func trigger(time_scale: float, real_seconds: float) -> void:
	if _active or Engine.time_scale < 1.0 or real_seconds <= 0.0:
		return
	_active = true
	_scale = time_scale
	Engine.time_scale = time_scale
	# A timer that ignores the time scale, so the freeze lasts real time.
	get_tree().create_timer(real_seconds, true, false, true).timeout.connect(_restore)


func _restore() -> void:
	if not _active:
		return
	_active = false
	if is_equal_approx(Engine.time_scale, _scale):
		Engine.time_scale = 1.0


func _exit_tree() -> void:
	_restore()
