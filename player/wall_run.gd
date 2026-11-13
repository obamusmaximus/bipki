class_name WallRun
extends Node
## Running along a wall. Instead of bouncing off or losing speed on a graze, a fast player who hits a wall
## at a shallow angle latches on and runs along it: gravity is mostly off, the speed is capped, the hook is
## released, and the double jump comes back. Jumping leaves the wall with a push away from it. Head-on hits
## are not wall runs: they just slide as before. Child of Player; Player calls `try_start` after moving and
## `step` while `is_active()`.

## Emitted when the run starts. `side` is +1 with the wall on the player's right, -1 on the left.
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
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func setup(body: CharacterBody3D, player_stats: PlayerStats) -> void:
	_body = body
	stats = player_stats


func is_active() -> bool:
	return _active


func get_side() -> float:
	return _side


## Latches onto a wall the body has just slid along, if it was fast enough and the hit was a graze.
## `velocity_before` is the velocity before the move. `extra_normal` is another contact normal to
## consider (e.g. from the rope correction), or ZERO.
func try_start(velocity_before: Vector3, extra_normal: Vector3 = Vector3.ZERO) -> bool:
	if _active or _cooldown > 0.0 or _body.is_on_floor():
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
	for normal: Vector3 in normals:
		if absf(normal.y) > EdgeProbe.WALL_MAX_NORMAL_Y:
			continue
		var flat_normal: Vector3 = Vector3(normal.x, 0.0, normal.z).normalized()
		var into: float = -heading.dot(flat_normal)
		# Moving toward the wall, but at a shallow angle (a graze, not head-on).
		if into <= 0.0 or rad_to_deg(asin(clampf(into, 0.0, 1.0))) > stats.wall_run_max_approach_degrees:
			continue
		_begin(flat_normal)
		return true
	return false


## One physics frame of the run. Returns false once it has ended.
func step(delta: float) -> bool:
	var velocity: Vector3 = _body.velocity.slide(_normal)
	var flat: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if flat.length() > stats.wall_run_max_speed:
		flat = flat.normalized() * stats.wall_run_max_speed
	velocity.x = flat.x
	velocity.z = flat.z
	velocity.y -= _gravity * stats.wall_run_gravity_scale * delta

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


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)


func _begin(wall_normal: Vector3) -> void:
	_active = true
	_normal = wall_normal
	# Falling speed doesn't carry into the run (upward speed does).
	_body.velocity.y = maxf(_body.velocity.y, 0.0)
	_lost_time = 0.0
	# The wall's side relative to where the player is facing, for the camera tilt.
	_side = 1.0 if (-_normal).dot(_body.global_basis.x) > 0.0 else -1.0
	started.emit(_side)


func _end() -> void:
	_active = false
	_side = 0.0
	_cooldown = stats.wall_run_cooldown
	ended.emit()
