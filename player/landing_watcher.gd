class_name LandingWatcher
extends Node
## Reports when the player touches the ground after being airborne, with how hard it hit.
## Child of Player. It runs after the player moves, so it uses the vertical speed from the previous tick
## (the player's own is already zeroed by the landing).

## Emitted on touching down. `impact_speed` is the downward speed in m/s (positive).
signal landed(impact_speed: float)

var _body: CharacterBody3D
var _was_on_floor: bool = true
var _last_vertical_speed: float = 0.0


func setup(body: CharacterBody3D) -> void:
	_body = body


## Forgets the last frame (a rewind moved the body), so the jump in position doesn't count as a landing.
func reset() -> void:
	_was_on_floor = true
	_last_vertical_speed = 0.0


func _physics_process(_delta: float) -> void:
	if _body == null:
		return
	var on_floor: bool = _body.is_on_floor()
	if on_floor and not _was_on_floor and _last_vertical_speed < 0.0:
		landed.emit(-_last_vertical_speed)
	_was_on_floor = on_floor
	_last_vertical_speed = _body.velocity.y
