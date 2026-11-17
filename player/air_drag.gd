class_name AirDrag
extends RefCounted
## A small general drag on the player's whole velocity while airborne or swinging. It is on at any speed, unlike the
## soft speed limit, which only acts above its limit, so flight slowly bleeds speed instead of holding it. Plain math.


## `velocity` after one frame of drag: a fixed share of the speed lost per second (`PlayerStats.air_drag`).
static func apply(velocity: Vector3, delta: float, stats: PlayerStats) -> Vector3:
	if stats.air_drag <= 0.0:
		return velocity
	return velocity / (1.0 + stats.air_drag * delta)
