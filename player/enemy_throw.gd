class_name EnemyThrow
extends Node
## The throw: the grapple has hooked an enemy and RMB is held. The world drops into bullet time, the enemy
## hangs where it is, and the player turns to aim. Letting go of RMB (or the time running out) throws it.
##  - Direction: the enemy flies from where it hangs toward a pull point `throw_reach` ahead of you along
##    your look direction (a little to the right, so it passes your head). A rope only pulls toward the
##    hand, so a far enemy can only be sent back past you; stand on the line between it and the target.
##  - Power: turning away from the enemy (draw) and how fast the camera is turning at release (flick).
##  - Feel: the camera gets heavier to turn as the draw grows. A throw that is aimed near another enemy bends
##    toward it a little.
## Everything it works out each frame is public, for the HUD's release prediction and gauges.
## Reports with signals; GrappleHook (the rope) and Player (the camera) listen.

## The throw started: bullet time begins.
signal started
## The enemy was thrown. `power` is 0-1.
signal released(launch_velocity: Vector3, power: float)
## The throw is over, however it ended.
signal ended

const WORLD_MASK: int = 1 # Collision layer 1: World
const MIN_REAL_DELTA: float = 0.005
## How fast the camera weight follows the draw (per second).
const WEIGHT_SMOOTHING: float = 12.0

var stats: GrappleStats
var enemy: Enemy
## 0 facing the enemy, 1 facing directly away.
var draw: float = 0.0
## 0-1 from the camera's recent turn speed.
var flick: float = 0.0
## 0-1, the mix of draw and flick.
var power: float = 0.0
## What the enemy would fly with if released now. Zero when facing it (a let-go).
var launch_velocity: Vector3 = Vector3.ZERO
## True while facing the enemy too closely: releasing just lets it go.
var is_limp: bool = true
## The predicted flight if released now. Empty while limp.
var preview: ThrowPreview.Result = ThrowPreview.Result.new()

var _active: bool = false
var _elapsed: float = 0.0
var _camera: Camera3D
var _head: HeadLook
var _fov: DynamicFov
var _bullet: BulletTime
var _tracer := ThrowPreview.new()
var _last_look: Vector3 = Vector3.FORWARD
## (real time, turn speed) samples of the last `throw_flick_window` seconds.
var _turns: Array[Vector2] = []
var _weight: float = 1.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	_bullet = BulletTime.new()
	add_child(_bullet)


func setup(grapple_stats: GrappleStats, camera: Camera3D, head: HeadLook, fov: DynamicFov) -> void:
	stats = grapple_stats
	_camera = camera
	_head = head
	_fov = fov


func is_active() -> bool:
	return _active


## Fraction of the throw's time already used, 0 to 1.
func get_time_fraction() -> float:
	return clampf(_elapsed / maxf(stats.throw_duration, 0.01), 0.0, 1.0) if _active else 0.0


## Grabs `target` and starts bullet time.
func start(target: Enemy) -> void:
	enemy = target
	_active = true
	_elapsed = 0.0
	_turns.clear()
	_weight = 1.0
	_last_look = -_camera.global_basis.z
	draw = 0.0
	flick = 0.0
	power = 0.0
	is_limp = true
	preview = ThrowPreview.Result.new()
	enemy.grab()
	_bullet.enter(stats.bullet_time_scale, stats.bullet_time_ease, stats.bullet_time_audio_speed)
	_fov.kick(stats.bullet_time_fov_kick)
	started.emit()


## Ends the throw without throwing (the enemy died, the player did). The enemy is dropped if still held.
func cancel() -> void:
	if not _active:
		return
	if is_instance_valid(enemy) and enemy.state == Enemy.State.GRABBED:
		enemy.drop()
	_finish()


## Ends the throw and bullet time without touching the enemy (a rewind puts the enemy back itself).
func abort() -> void:
	if _active:
		_finish()


func _physics_process(delta: float) -> void:
	if not _active:
		return
	if not is_instance_valid(enemy) or enemy.state != Enemy.State.GRABBED:
		_finish()
		return
	# Bullet time shrinks the physics step, so real time is the step divided by the time scale.
	var real_delta: float = maxf(delta / maxf(Engine.time_scale, 0.001), MIN_REAL_DELTA)
	_elapsed += real_delta
	_read_flick(real_delta)
	_aim()
	_weigh_camera(real_delta)
	if not Input.is_action_pressed("grapple") or _elapsed >= stats.throw_duration:
		_release()


func _exit_tree() -> void:
	if _active and _head != null:
		_head.sensitivity_scale = 1.0


## The camera's fastest recent turn, as a 0-1 flick.
func _read_flick(real_delta: float) -> void:
	var look: Vector3 = -_camera.global_basis.z
	_turns.append(Vector2(_elapsed, _last_look.angle_to(look) / real_delta))
	_last_look = look
	while not _turns.is_empty() and _elapsed - _turns[0].x > stats.throw_flick_window:
		_turns.pop_front()
	var fastest: float = 0.0
	for sample: Vector2 in _turns:
		fastest = maxf(fastest, sample.y)
	flick = clampf(fastest / maxf(stats.throw_flick_full_speed, 0.01), 0.0, 1.0)


## Works out draw, power, the throw velocity and the release prediction from where the player looks.
func _aim() -> void:
	var camera_position: Vector3 = _camera.global_position
	var look: Vector3 = -_camera.global_basis.z
	var center: Vector3 = enemy.get_center()
	var angle: float = look.angle_to((center - camera_position).normalized())
	draw = clampf(angle / PI, 0.0, 1.0)
	var draw_weight: float = maxf(stats.throw_draw_weight, 0.0)
	var flick_weight: float = maxf(stats.throw_flick_weight, 0.0)
	var total: float = draw_weight + flick_weight
	power = (draw_weight * draw + flick_weight * flick) / total if total > 0.0 else draw
	is_limp = angle < deg_to_rad(stats.throw_min_draw_degrees)

	var pull_point: Vector3 = camera_position + _camera.global_basis.x * stats.throw_hand_offset + look * stats.throw_reach
	var direction: Vector3 = (pull_point - center).normalized()
	direction = _bend_toward_enemies(center, direction)
	launch_velocity = Vector3.ZERO if is_limp else direction * lerpf(stats.throw_min_speed, stats.throw_max_speed, power)
	if is_limp:
		preview = ThrowPreview.Result.new()
		return
	var exclude: Array[RID] = [enemy.get_rid()]
	preview = _tracer.trace(enemy.get_world_3d().direct_space_state, center, launch_velocity,
			_gravity * enemy.stats.thrown_gravity_scale, enemy.stats.body_radius, exclude,
			stats.throw_preview_step, stats.throw_preview_seconds)


## Bends `direction` toward the nearest other enemy lying within the assist angle of it, if the way to it is clear.
func _bend_toward_enemies(center: Vector3, direction: Vector3) -> Vector3:
	var limit: float = deg_to_rad(stats.throw_assist_degrees)
	if limit <= 0.0 or stats.throw_assist_strength <= 0.0:
		return direction
	var best: Vector3 = Vector3.ZERO
	var best_angle: float = limit
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var other: Enemy = node as Enemy
		if other == null or other == enemy or other.health.is_dead():
			continue
		var to_other: Vector3 = other.get_center() - center
		if to_other.length() < 1.0:
			continue
		var angle: float = direction.angle_to(to_other)
		if angle < best_angle and _line_clear(center, other.get_center()):
			best_angle = angle
			best = to_other.normalized()
	if best == Vector3.ZERO:
		return direction
	# Full pull when nearly on target, fading out toward the edge of the cone.
	var fade: float = 1.0 - smoothstep(0.5, 1.0, best_angle / limit)
	return direction.slerp(best, stats.throw_assist_strength * fade)


func _line_clear(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to, WORLD_MASK)
	return enemy.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## Turning away from the enemy gets heavier, like the rope under tension.
func _weigh_camera(real_delta: float) -> void:
	var wanted: float = lerpf(1.0, stats.throw_weight_min_sensitivity, draw)
	_weight = lerpf(_weight, wanted, 1.0 - exp(-WEIGHT_SMOOTHING * real_delta))
	_head.sensitivity_scale = _weight


func _release() -> void:
	var thrown_velocity: Vector3 = launch_velocity
	var thrown_power: float = power
	var limp: bool = is_limp
	if limp:
		enemy.drop()
	else:
		enemy.throw(thrown_velocity)
	_finish()
	if not limp:
		released.emit(thrown_velocity, thrown_power)


func _finish() -> void:
	_active = false
	_head.sensitivity_scale = 1.0
	_bullet.exit(stats.bullet_time_ease)
	ended.emit()
