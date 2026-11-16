class_name StrikeGuidance
extends RefCounted
## Guides a launch at an enemy (an RMB tap on it) into the enemy, so the melee hit lands from any distance or height.
## `start` turns the launch velocity a normal launch would give into one with the same speed that, under the
## launch gravity, arcs into where the enemy will be (`strike_lead` of its motion is led). Each physics frame
## `steer` turns the velocity back onto that arc at up to `strike_turn_rate_degrees`, so a drone moving off or a
## small error is caught. Speed is never added: air steering and the soft speed limit still apply on top.
## The player can veer off: steering input more than `strike_veer_degrees` away from the enemy ends the guidance.
## It also ends once past the enemy, after `strike_max_time`, or when Player calls `stop` (landing, a hit, a swing).
## Owned by Player.

## Solver passes: each corrects the flight time toward the wanted speed.
const SOLVE_STEPS: int = 6

var stats: GrappleStats

var _gravity: BodyGravity
var _target: Enemy = null
var _time_left: float = 0.0


func _init(grapple_stats: GrappleStats, gravity: BodyGravity) -> void:
	stats = grapple_stats
	_gravity = gravity


func is_active() -> bool:
	return _target != null


## Starts a strike at `target` from `from` (the player's mid-body) at `speed`. Returns the launch velocity and
## sets the flight time `flight_time()` reports, so Player can keep the launch gravity on for the whole flight.
func start(target: Enemy, from: Vector3, speed: float) -> Vector3:
	_target = target
	_time_left = stats.strike_max_time
	return solve(from, target.get_center(), target.velocity * stats.strike_lead, speed, _launch_gravity())


## Seconds the solved arc takes to reach the target at `speed`.
func flight_time(from: Vector3, speed: float) -> float:
	if _target == null or speed <= 0.0:
		return 0.0
	return _solve_time(from, _target.get_center(), _target.velocity * stats.strike_lead, speed, _launch_gravity())


func stop() -> void:
	_target = null


## Turns `velocity` toward the arc into the target, keeping its speed. `from` is the player's mid-body,
## `input` the world-space steering direction (zero when there is none).
func steer(velocity: Vector3, from: Vector3, input: Vector3, delta: float) -> Vector3:
	if _target == null:
		return velocity
	_time_left -= delta
	if not is_instance_valid(_target) or not _target.is_hookable() or _time_left <= 0.0:
		stop()
		return velocity
	var to_target: Vector3 = _target.get_center() - from
	if velocity.dot(to_target) <= 0.0 or _veers_off(input, to_target):
		stop()
		return velocity
	var speed: float = velocity.length()
	if speed <= 0.0:
		return velocity
	var wanted: Vector3 = solve(from, _target.get_center(), _target.velocity * stats.strike_lead, speed,
			_launch_gravity())
	var angle: float = velocity.angle_to(wanted)
	var axis: Vector3 = velocity.cross(wanted)
	if angle <= 0.0 or axis.is_zero_approx():
		return velocity
	var limit: float = deg_to_rad(stats.strike_turn_rate_degrees) * delta
	return velocity.rotated(axis.normalized(), minf(angle, limit))


## The velocity of length `speed` from `from` that, falling at `gravity`, reaches the target `target` moving at
## `target_velocity` (low arc). Too far to reach at that speed, it aims as close as it can.
static func solve(from: Vector3, target: Vector3, target_velocity: Vector3, speed: float, gravity: float) -> Vector3:
	var time: float = _solve_time(from, target, target_velocity, speed, gravity)
	return _arc_velocity(from, target + target_velocity * time, time, gravity).normalized() * speed


static func _solve_time(from: Vector3, target: Vector3, target_velocity: Vector3, speed: float, gravity: float) -> float:
	var time: float = maxf(from.distance_to(target) / speed, 0.01)
	# Out of reach the correction would run away; the arc stays near the straight-line time.
	var longest: float = time * 4.0
	for i: int in SOLVE_STEPS:
		var needed: float = _arc_velocity(from, target + target_velocity * time, time, gravity).length()
		time = minf(time * needed / speed, longest)
	return time


## The velocity that covers `from` to `to` in `time` while falling at `gravity`.
static func _arc_velocity(from: Vector3, to: Vector3, time: float, gravity: float) -> Vector3:
	return (to - from) / time + Vector3.UP * 0.5 * gravity * time


func _veers_off(input: Vector3, to_target: Vector3) -> bool:
	var flat_input := Vector2(input.x, input.z)
	var flat_target := Vector2(to_target.x, to_target.z)
	if flat_input.is_zero_approx() or flat_target.is_zero_approx():
		return false
	return rad_to_deg(absf(flat_input.angle_to(flat_target))) > stats.strike_veer_degrees


## The strike flies under the launch gravity throughout (Player keeps it on for the flight time).
func _launch_gravity() -> float:
	return _gravity.stats.gravity * _gravity.stats.launch_gravity_scale
