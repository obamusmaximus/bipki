class_name WallRun
extends Node
## Running along a wall. Instead of bouncing off or losing speed on a graze, a fast player who hits a wall
## at a shallow angle latches on and runs along it: gravity is mostly off, the speed is capped, the hook is
## released, and the double jump comes back. Jumping leaves the wall with a push away from it.
## A head-on hit latches too, as a slow slide down the wall: turning the camera along the wall within
## `wall_run_head_on_time` starts a run that way at the speed the player hit the wall with. Otherwise they
## let go and fall, and can't latch onto any wall again until they land. Child of Player; Player calls `try_start` after moving
## and `step` while `is_active()`.

## Emitted when the run starts. `side` is +1 with the wall on the player's right, -1 on the left, 0 for a
## head-on latch (emitted again with the side once the player turns along the wall).
signal started(side: float)
signal ended

const WORLD_MASK: int = 1 # Collision layer 1: World

var stats: PlayerStats

var _body: CharacterBody3D
var _active: bool = false
## Horizontal normal of the wall being run on, pointing out toward the player.
var _normal: Vector3 = Vector3.ZERO
var _side: float = 0.0
var _lost_time: float = 0.0
var _cooldown: float = 0.0
## Seconds a head-on latch has left to turn into a run. 0 when this is a normal run.
var _head_on_left: float = 0.0
## Horizontal speed the player hit the wall with head-on; a run started from the latch gets it back.
var _head_on_speed: float = 0.0
## Set when a head-on latch times out: no more latching until the player lands.
var _locked_out: bool = false
## Degrees of the outward look nudge still to apply, signed as the yaw rotation to apply.
var _nudge_left: float = 0.0


func setup(body: CharacterBody3D, player_stats: PlayerStats) -> void:
	_body = body
	stats = player_stats


func is_active() -> bool:
	return _active


func get_side() -> float:
	return _side


## True while latched after a head-on hit, before turning along the wall.
func is_head_on() -> bool:
	return _active and _head_on_left > 0.0


## Latches onto a wall the body has just slid along, if it was fast enough and the hit was a graze.
## `velocity_before` is the velocity before the move. `extra_normal` is another contact normal to
## consider (e.g. from the rope correction), or ZERO.
func try_start(velocity_before: Vector3, extra_normal: Vector3 = Vector3.ZERO) -> bool:
	if _active or _cooldown > 0.0 or _locked_out or _body.is_on_floor():
		return false
	var flat: Vector3 = Vector3(velocity_before.x, 0.0, velocity_before.z)
	if flat.length() < stats.wall_run_min_speed:
		return false
	var heading: Vector3 = flat.normalized()
	var normals: Array[Vector3] = []
	for i: int in _body.get_slide_collision_count():
		normals.append(_body.get_slide_collision(i).get_normal())
	if extra_normal != Vector3.ZERO:
		normals.append(extra_normal)
	var head_on: Vector3 = Vector3.ZERO
	for normal: Vector3 in normals:
		if absf(normal.y) > EdgeProbe.WALL_MAX_NORMAL_Y:
			continue
		var flat_normal: Vector3 = Vector3(normal.x, 0.0, normal.z).normalized()
		var into: float = -heading.dot(flat_normal)
		if into <= 0.0:
			continue
		# Moving toward the wall at a shallow angle: a graze, a run. A steeper hit is head-on.
		if rad_to_deg(asin(clampf(into, 0.0, 1.0))) > stats.wall_run_max_approach_degrees:
			head_on = flat_normal
			continue
		# Running forward takes a held forward key; an accidental run while flying backwards is fine.
		if _blocked_by_missing_key(heading):
			continue
		_begin(flat_normal, false)
		return true
	if head_on != Vector3.ZERO and stats.wall_run_head_on_enabled and not _blocked_by_missing_key(heading):
		_head_on_speed = minf(flat.length(), stats.wall_run_max_speed)
		_begin(head_on, true)
		return true
	return false


## True when travelling forward relative to the look without W held: no run (or head-on latch) then.
func _blocked_by_missing_key(heading: Vector3) -> bool:
	return heading.dot(-_body.global_basis.z) > cos(deg_to_rad(stats.wall_run_no_key_degrees)) \
			and not Input.is_action_pressed("move_forward")


## One physics frame of the run. Returns false once it has ended.
func step(delta: float) -> bool:
	if _head_on_left > 0.0:
		return _step_head_on(delta)
	_apply_nudge(delta)
	var velocity: Vector3 = _body.velocity.slide(_normal)
	var flat: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if flat.length() > stats.wall_run_max_speed:
		flat = flat.normalized() * stats.wall_run_max_speed
	velocity.x = flat.x
	velocity.z = flat.z
	velocity.y -= stats.gravity * stats.wall_run_gravity_scale * delta

	if Input.is_action_just_pressed("jump"):
		velocity += _normal * stats.wall_run_jump_away_speed
		velocity.y = maxf(velocity.y, 0.0) + stats.wall_run_jump_speed
		_body.velocity = velocity
		_end()
		return false

	# A small push into the wall keeps the contact alive so the body keeps reporting it.
	_body.velocity = velocity - _normal * stats.wall_run_stick_speed
	_body.move_and_slide()

	var touching: bool = false
	for i: int in _body.get_slide_collision_count():
		var normal: Vector3 = _body.get_slide_collision(i).get_normal()
		if absf(normal.y) <= EdgeProbe.WALL_MAX_NORMAL_Y:
			_normal = Vector3(normal.x, 0.0, normal.z).normalized()
			touching = true
	_lost_time = 0.0 if touching else _lost_time + delta
	var speed: float = Vector3(_body.velocity.x, 0.0, _body.velocity.z).length()
	if _body.is_on_floor() or _lost_time > stats.wall_run_lose_grace or speed < stats.wall_run_end_speed:
		_end()
		return false
	return true


## One physics frame of the head-on latch: a slow slide straight down the wall until the player turns the camera
## along it (the run starts that way) or the time runs out (they let go and fall). Returns false once it has ended.
func _step_head_on(delta: float) -> bool:
	var velocity: Vector3 = Vector3(0.0, _body.velocity.y - stats.gravity * stats.wall_run_head_on_gravity_scale * delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		velocity += _normal * stats.wall_run_jump_away_speed
		velocity.y = maxf(velocity.y, 0.0) + stats.wall_run_jump_speed
		_body.velocity = velocity
		_end()
		return false

	var look: Vector3 = -_body.global_basis.z
	look.y = 0.0
	var along: Vector3 = look.slide(_normal).normalized()
	# The angle between the look and the wall: 90 facing straight into it, 0 looking along it.
	var into_degrees: float = rad_to_deg(asin(clampf(-look.normalized().dot(_normal), -1.0, 1.0)))
	if into_degrees <= stats.wall_run_head_on_turn_degrees and not along.is_zero_approx() \
			and not _blocked_by_missing_key(along):
		_head_on_left = 0.0
		_body.velocity = along * maxf(_head_on_speed, stats.wall_run_end_speed)
		_side = 1.0 if (-_normal).dot(along.cross(Vector3.UP)) > 0.0 else -1.0
		started.emit(_side)
		return true

	_body.velocity = velocity - _normal * stats.wall_run_stick_speed
	_body.move_and_slide()
	_body.velocity.x = 0.0
	_body.velocity.z = 0.0
	_head_on_left -= delta
	_lost_time = 0.0 if _body.is_on_wall() else _lost_time + delta
	if _body.is_on_floor() or _lost_time > stats.wall_run_lose_grace:
		_end()
		return false
	if _head_on_left <= 0.0:
		_locked_out = true
		_end()
		return false
	return true


## Turns the body's yaw a little away from the wall over `wall_run_look_nudge_time` after a run starts.
func _apply_nudge(delta: float) -> void:
	if is_zero_approx(_nudge_left):
		return
	var rate: float = stats.wall_run_look_nudge_degrees / maxf(stats.wall_run_look_nudge_time, 0.001)
	var amount: float = minf(rate * delta, absf(_nudge_left)) * signf(_nudge_left)
	_body.rotate_y(deg_to_rad(amount))
	_nudge_left -= amount


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _body != null and _body.is_on_floor():
		_locked_out = false


func _begin(wall_normal: Vector3, head_on: bool) -> void:
	_active = true
	_normal = wall_normal
	# Falling speed doesn't carry into the run (upward speed does).
	_body.velocity.y = maxf(_body.velocity.y, 0.0)
	_lost_time = 0.0
	_head_on_left = stats.wall_run_head_on_time if head_on else 0.0
	if head_on:
		# Latched facing the wall: no sideways motion and no tilt until the player turns along it.
		_body.velocity = Vector3.ZERO
		_side = 0.0
	else:
		# The wall's side relative to where the player is facing, for the camera tilt.
		_side = 1.0 if (-_normal).dot(_body.global_basis.x) > 0.0 else -1.0
		# Turn the view outward: toward the wall's normal, away from the wall.
		var look: Vector3 = -_body.global_basis.z
		_nudge_left = signf(look.cross(_normal).y) * stats.wall_run_look_nudge_degrees
	started.emit(_side)


func _end() -> void:
	_active = false
	_nudge_left = 0.0
	_head_on_left = 0.0
	_side = 0.0
	_cooldown = stats.wall_run_cooldown
	ended.emit()
