class_name SoftSpeedLimit
extends RefCounted
## A soft speed limit for flying and swinging. Below the limit nothing happens. Above it, drag opposes the velocity
## and grows with the cube of how far past the limit the speed is, so speed levels off near the limit rather than
## being clamped. The drag is strong enough that a fall or a reel can only push a little past it. Plain math.

## How fast the drag ramps up with speed above the limit.
const SHARPNESS: float = 3.0
## The drag at 1.25 times the limit is about `strength` times this.
const REFERENCE_RATIO: float = 1.25


## `velocity` after one frame of drag. Never slows the player below the limit in a single step.
static func apply(velocity: Vector3, delta: float, stats: PlayerStats) -> Vector3:
	if not stats.soft_speed_limit_enabled:
		return velocity
	var speed: float = velocity.length()
	var limit: float = maxf(stats.soft_speed_limit, 1.0)
	if speed <= limit:
		return velocity
	var scale: float = stats.soft_speed_limit_strength / (pow(REFERENCE_RATIO, SHARPNESS) - 1.0)
	var drag: float = scale * (pow(speed / limit, SHARPNESS) - 1.0)
	var slowed: float = maxf(speed - drag * delta, limit)
	return velocity * (slowed / speed)
