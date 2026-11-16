class_name Melee
extends Node
## The body hit: flying into an enemy punches it. It lands when the player is fast enough (`melee_min_speed`),
## or at any speed after a launch at an enemy (Player calls `arm`). The hit sphere sits in front of the player
## along the look direction and is swept between frames, so a fast pass doesn't skip through an enemy.
## On a hit: a metallic ka-ching, a short slow-motion (the throw's bullet time), half the enemy's health
## (`melee_damage_fraction`) and the player's momentum handed to the enemy as a knockback.
## Signals up: Player reacts to `hit` with the player-side effects (keep a share of the speed, double jump back).

## Emitted on a hit, after the enemy took its damage and knockback. `impact_velocity` is the player's velocity at the hit.
signal hit(enemy: Enemy, impact_velocity: Vector3)

## Mid-body above the feet (m), where the hit sphere starts from.
const MID_BODY: float = 0.9

var stats: PlayerStats
var grapple_stats: GrappleStats

var _body: CharacterBody3D
var _camera: Camera3D
var _armed_left: float = 0.0
var _cooldown: float = 0.0
var _last_center: Vector3 = Vector3.ZERO
var _has_last: bool = false
var _bullet: BulletTime
var _sound: AudioStreamPlayer


func _ready() -> void:
	_bullet = BulletTime.new()
	add_child(_bullet)
	_sound = AudioStreamPlayer.new()
	_sound.stream = Synth.make_clang(0.7, 1850.0, 0.035, 0.9)
	add_child(_sound)


func setup(body: CharacterBody3D, camera: Camera3D, player_stats: PlayerStats, hook_stats: GrappleStats) -> void:
	_body = body
	_camera = camera
	stats = player_stats
	grapple_stats = hook_stats
	stats.changed.connect(_apply_volume)
	_apply_volume()


## The player was launched at an enemy: the next contact hits whatever the speed, until landing or time-out.
func arm() -> void:
	_armed_left = stats.melee_armed_time


func is_armed() -> bool:
	return _armed_left > 0.0


func _physics_process(delta: float) -> void:
	if _body == null:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	_armed_left = maxf(_armed_left - delta, 0.0)
	if _body.is_on_floor():
		_armed_left = 0.0
	var forward: Vector3 = -_camera.global_basis.z
	var mid: Vector3 = _body.global_position + Vector3.UP * MID_BODY
	var center: Vector3 = mid + forward * stats.melee_reach
	var from: Vector3 = _last_center if _has_last else center
	_last_center = center
	_has_last = true
	if _cooldown > 0.0:
		return
	var velocity: Vector3 = _body.velocity
	if not is_armed() and velocity.length() < stats.melee_min_speed:
		return
	var target: Enemy = _find_target(from, center, mid, forward, velocity)
	if target != null:
		_strike(target, velocity)


## The enemy the hit sphere touched this frame, or null. It must be in front, and the player moving toward it.
func _find_target(from: Vector3, to: Vector3, mid: Vector3, forward: Vector3, velocity: Vector3) -> Enemy:
	var best: Enemy = null
	var best_distance: float = INF
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy: Enemy = node as Enemy
		if enemy == null or not enemy.is_hookable():
			continue
		var center: Vector3 = enemy.get_center()
		var to_enemy: Vector3 = center - mid
		if velocity.dot(to_enemy) <= 0.0 or rad_to_deg(forward.angle_to(to_enemy)) > stats.melee_front_degrees:
			continue
		var closest: Vector3 = Geometry3D.get_closest_point_to_segment(center, from, to)
		var distance: float = closest.distance_to(center)
		if distance <= stats.melee_hit_radius + enemy.stats.body_radius and distance < best_distance:
			best = enemy
			best_distance = distance
	return best


func _strike(enemy: Enemy, velocity: Vector3) -> void:
	_cooldown = stats.melee_cooldown
	_armed_left = 0.0
	_sound.play()
	_slow_down()
	enemy.health.take_damage(enemy.stats.max_health * stats.melee_damage_fraction)
	if not enemy.health.is_dead():
		enemy.knock_back(velocity * stats.melee_knockback_scale)
	hit.emit(enemy, velocity)


## The throw's bullet time, held for `melee_slowmo_time` real seconds. Skipped if the game is already slowed.
func _slow_down() -> void:
	if stats.melee_slowmo_time <= 0.0 or Engine.time_scale < 1.0:
		return
	_bullet.enter(grapple_stats.bullet_time_scale, grapple_stats.bullet_time_ease, grapple_stats.bullet_time_audio_speed)
	get_tree().create_timer(stats.melee_slowmo_time, true, false, true).timeout.connect(_end_slow_down)


func _end_slow_down() -> void:
	if _bullet.is_engaged():
		_bullet.exit(grapple_stats.bullet_time_ease)


func _apply_volume() -> void:
	_sound.volume_db = stats.melee_volume_db
