class_name BodyGravity
extends RefCounted
## The player's own gravity (PlayerStats "Gravity" group). Heavier than the project default so jumps are short and
## the player drops back into the streets quickly, heavier still while falling, and with its own share on a swing
## rope and for a moment after a launch (so launches keep their reach). Enemies and thrown things keep the project
## gravity. Owned by Player; TrajectoryPredictor asks the same object so the HUD arc matches the real flight.

var stats: PlayerStats

## Seconds of launch-flight gravity left (game time, so bullet time stretches it like the flight itself).
var _launch_left: float = 0.0


func _init(player_stats: PlayerStats) -> void:
	stats = player_stats


## A launch just fired: lighter gravity for `launch_gravity_time`, or for `at_least` seconds if longer
## (a launch at an enemy keeps it for its whole flight, which its aim assumes).
func start_launch(at_least: float = 0.0) -> void:
	_launch_left = maxf(stats.launch_gravity_time, at_least)


## Landing, a swing or a wall run ends the launch flight early.
func end_launch() -> void:
	_launch_left = 0.0


## Seconds of launch gravity left, for a rewind snapshot.
func get_launch_left() -> float:
	return _launch_left


## Puts the launch gravity back as a snapshot had it (a rewind).
func restore_launch(left: float) -> void:
	_launch_left = maxf(left, 0.0)


func tick(delta: float) -> void:
	_launch_left = maxf(_launch_left - delta, 0.0)


## Downward acceleration (m/s squared) in free flight with vertical speed `velocity_y`, `ahead` seconds from now.
func air(velocity_y: float, ahead: float = 0.0) -> float:
	if _launch_left - ahead > 0.0:
		return stats.gravity * stats.launch_gravity_scale
	if velocity_y < 0.0:
		return stats.gravity * stats.fall_gravity_scale
	return stats.gravity


## Downward acceleration (m/s squared) while hanging from the swing rope with vertical speed `velocity_y`.
## The low point of the arc splits a swing: falling toward it gravity speeds the swing up, rising past it
## gravity slows it down, and each half has its own share.
func swing(velocity_y: float) -> float:
	if velocity_y > 0.0:
		return stats.gravity * stats.swing_gravity_scale_rising
	return stats.gravity * stats.swing_gravity_scale_falling
