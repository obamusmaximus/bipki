class_name Bunnyhop
extends RefCounted
## Grace window after landing with more than walking speed. While it is open the player keeps the horizontal
## speed instead of being set to `move_speed`, and a jump (pressed a little before landing counts too) leaves the
## ground with that speed. Let it run out and the landing sets walking speed as usual. Owned by Player.

var _stats: PlayerStats
## Seconds of grace left. Above zero means the window is open.
var _window_left: float = 0.0
## Seconds a jump press stays remembered, so one just before landing still hops.
var _buffer_left: float = 0.0


func _init(stats: PlayerStats) -> void:
	_stats = stats


## Once per physics frame, before movement. Remembers jump presses and closes the window when the feet leave the floor.
func tick(delta: float, on_floor: bool) -> void:
	_window_left = maxf(_window_left - delta, 0.0)
	_buffer_left = maxf(_buffer_left - delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		_buffer_left = _stats.bunnyhop_buffer_time
	if not on_floor:
		_window_left = 0.0


## Call on the frame the player lands. Opens the window if the landing is faster than walking speed.
func land(velocity: Vector3) -> void:
	if not _stats.bunnyhop_enabled:
		return
	if Vector2(velocity.x, velocity.z).length() > _stats.move_speed:
		_window_left = _stats.bunnyhop_window


## Seconds of grace left, for a rewind snapshot.
func get_window_left() -> float:
	return _window_left


## Puts the window back as a snapshot had it (a rewind). A remembered jump press is input, not state: it's dropped.
func restore(window_left: float) -> void:
	_window_left = maxf(window_left, 0.0)
	_buffer_left = 0.0


func is_open() -> bool:
	return _window_left > 0.0


## True if a jump was pressed now or just before landing. Only meaningful while the window is open.
func wants_hop() -> bool:
	return _buffer_left > 0.0


## Closes the window and returns the velocity to leave the ground with: the excess over walking speed is
## scaled by `bunnyhop_speed_keep`, so a chain of hops bleeds a little each time.
func hop(velocity: Vector3) -> Vector3:
	_window_left = 0.0
	_buffer_left = 0.0
	var horizontal := Vector2(velocity.x, velocity.z)
	var speed: float = horizontal.length()
	if speed > _stats.move_speed:
		horizontal *= (_stats.move_speed + (speed - _stats.move_speed) * _stats.bunnyhop_speed_keep) / speed
	return Vector3(horizontal.x, _stats.jump_speed, horizontal.y)
