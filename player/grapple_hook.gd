class_name GrappleHook
extends Node3D
## The grappling hook, fired from the camera crosshair. It has two inputs:
##  - Grapple (RMB, "grapple"): the hook flies to the hit point at extend_speed. On arrival the
##    player is launched toward a point launch_height_offset above the hit point (so the player arcs
##    over the target), then the hook detaches. Holding RMB makes no difference.
##    After attaching there is a launch_grace pause. Where the crosshair points when it ends
##    (left or right of the hit point) shifts the aim point sideways by up to launch_side_offset.
##  - Swing (LMB, "swing"): the hook flies at extend_speed. On arrival the player hangs from
##    the hit point on a rope. The rope can shorten (hold reel/Shift to reel in, and reeling it all
##    the way to min_rope_length detaches) but never lengthen.
##    Momentum is not touched, so the player can steer by pivoting. Releasing LMB detaches.
## Both can also take hold of an enemy: the aim locks on to one near the crosshair, and the tip homes on it as it moves.
##  - On an enemy, RMB tapped launches the player at it. RMB held for throw_hold_time turns it into a throw
##    (EnemyThrow: bullet time, turn and release to send the enemy flying).
##  - On an enemy, swing hangs the player from it. The enemy is dragged a little by the rope.
## RMB reaches launch_range; the swing reaches max_distance.
## Place this node at mid-body: its position is the rope's start.

## Emitted when the hook tip reaches the hit point.
signal attached
## Emitted once when a launch connects. The player should add this velocity.
signal launched(launch_velocity: Vector3)
## Emitted instead of `launched` when the launch is at an enemy (RMB tapped on it). Player aims that launch itself.
signal launched_at_enemy(enemy: Enemy)
## Emitted when an attached hook ends: a launch, or a swing released.
signal detached
## Emitted on attach when the hook is on a lip or an edge. The argument is the horizontal
## direction toward the open side.
signal attached_near_edge(lip_direction: Vector3)
## Emitted when a held enemy is released into flight. `power` is 0-1.
signal thrown(launch_velocity: Vector3, power: float)

enum State { IDLE, EXTENDING, ATTACHED }
enum Mode { NONE, LAUNCH, SWING, THROW }
## What the crosshair points at: nothing in reach, a valid hook target, the ground plane (rejected), an enemy
## the grapple would lock onto, or a spot only the swing reaches (past the grapple's range).
enum Aim { NONE, VALID, GROUND, ENEMY, SWING_ONLY }

## Tunable numbers. Set by Player through setup().
var stats: GrappleStats

## Set by Player: the camera the fire raycast and launch aim come from.
var camera: Camera3D

const WORLD_MASK: int = 1 # Collision layer 1: World
const ENEMY_MASK: int = 4 # Collision layer 3: Enemy (bit value)

var _state: State = State.IDLE
var _mode: Mode = Mode.NONE
var _hit_point: Vector3 = Vector3.ZERO
var _tip: Vector3 = Vector3.ZERO
var _flight_speed: float = 0.0
var _hit_normal: Vector3 = Vector3.UP
var _attached_time: float = 0.0
var _swing: SwingRope
## The point the swing rope hangs from. The hit point, or pushed out from a wall by the tuned distance.
var _swing_anchor: Vector3 = Vector3.ZERO
## Set when the hit is on a lip or an edge: the open direction. ZERO otherwise.
var _lip: Vector3 = Vector3.ZERO
## The enemy the hook is on, or null when it is on the world.
var _enemy: Enemy
## Seconds RMB has been held since firing.
var _held_time: float = 0.0
## Seconds the tip has been chasing an enemy.
var _chase_time: float = 0.0

## Normals of walls the player is running on or beside, set by Player every frame. A launch can't target those walls.
var wall_normals: PackedVector3Array = PackedVector3Array()

@onready var _rope: GrappleRope = $Rope
@onready var _sfx: GrappleSfx = $Sfx
@onready var _throw: EnemyThrow = $Throw


func _physics_process(delta: float) -> void:
	if _state == State.IDLE:
		if Input.is_action_just_pressed("grapple"):
			_try_fire(false)
		elif Input.is_action_just_pressed("swing"):
			_try_fire(true)
		return

	if _enemy != null and not _follow_enemy():
		# The enemy is gone (or can't be held any more). Let go, keeping the momentum like any detach.
		var was_attached: bool = _state == State.ATTACHED
		_reset(true)
		if was_attached:
			detached.emit()
		return

	if Input.is_action_pressed("grapple"):
		_held_time += delta

	if _mode == Mode.SWING and not Input.is_action_pressed("swing"):
		_end_swing()
		return
	if _mode == Mode.THROW:
		return # EnemyThrow owns the grapple until it ends.

	if _state == State.EXTENDING:
		_chase_time += delta
		_tip = _tip.move_toward(_hit_point, _flight_speed * delta)
		if _enemy != null and _chase_time > stats.enemy_chase_time:
			_reset(true)
			return
		if _tip.is_equal_approx(_hit_point):
			_state = State.ATTACHED
			_sfx.play_attach()
			if _mode == Mode.SWING:
				_start_swing()
			if _lip != Vector3.ZERO:
				attached_near_edge.emit(_lip)
			attached.emit()

	if _state == State.ATTACHED and _mode == Mode.LAUNCH:
		if _enemy != null:
			_decide_enemy_launch()
			return
		_attached_time += delta
		if _attached_time >= stats.launch_grace:
			_launch()


func _process(_delta: float) -> void:
	if _state == State.EXTENDING:
		_rope.stretch_between(global_position, _tip, true)
	elif _state == State.ATTACHED:
		_rope.stretch_between(global_position, _hit_point)
	else:
		_rope.set_hand(global_position)


## Called once by Player with the grapple's tuning, which is handed on to the rope and the sounds.
func setup(grapple_stats: GrappleStats) -> void:
	stats = grapple_stats
	_rope.setup(stats)
	_sfx.setup(stats)
	_throw.started.connect(_sfx.play_slowmo_in)
	_throw.released.connect(_on_throw_released)
	_throw.ended.connect(_on_throw_ended)


## The throw part, which Player hands the camera and head to.
func get_throw() -> EnemyThrow:
	return _throw


## True while the player hangs from a swing rope.
func is_swinging() -> bool:
	return _state == State.ATTACHED and _mode == Mode.SWING


func get_state() -> State:
	return _state


func get_mode() -> Mode:
	return _mode


func get_hit_point() -> Vector3:
	return _hit_point


func get_hit_normal() -> Vector3:
	return _hit_normal


## The point a swing physically hangs from (see `_swing_anchor`). The hit point when not swinging.
func get_swing_anchor() -> Vector3:
	return _swing_anchor if is_swinging() else _hit_point


## Lets go of the hook whatever it is doing: a swing detaches, a throw is called off, a hook in flight retracts.
func release() -> void:
	if _state == State.IDLE:
		return
	if _mode == Mode.SWING:
		_end_swing()
	elif _mode == Mode.THROW:
		_throw.cancel()
	else:
		_reset(true)


## Current swing rope length, or 0 when not swinging.
func get_rope_length() -> float:
	return _swing.length if is_swinging() else 0.0


## The swing rope's length at attach, or 0 when not swinging.
func get_rope_start_length() -> float:
	return _swing.start_length if is_swinging() else 0.0


## The enemy the hook is on (flying to, swinging from, or throwing), or null.
func get_enemy() -> Enemy:
	return _enemy


## What a fire would do right now. Runs the same raycast as firing, so call it from _physics_process.
func probe_aim() -> Aim:
	if camera == null:
		return Aim.NONE
	if _find_enemy(stats.launch_range) != null:
		return Aim.ENEMY
	var hit: Dictionary = _cast_aim(stats.max_distance)
	if hit.is_empty():
		return Aim.NONE
	if hit["collider"] is Enemy:
		return Aim.SWING_ONLY
	if _is_ground(hit["position"]):
		return Aim.GROUND
	if _is_on_player_wall(hit["position"]):
		return Aim.SWING_ONLY
	return Aim.VALID if camera.global_position.distance_to(hit["position"]) <= stats.launch_range else Aim.SWING_ONLY


## What the player must apply to stay on the swing rope (see SwingRope.Correction). Reel (Shift) shortens it.
## `grounded`: the player stands on the floor (no ground-clearance retraction then).
func constrain_swing(body_velocity: Vector3, grounded: bool, delta: float) -> SwingRope.Correction:
	# Read each frame, so live tuning applies at once.
	_swing.reel_gain = stats.reel_momentum_gain
	_swing.reel_speed_cap = stats.reel_momentum_speed_cap
	if _enemy != null:
		_swing_anchor = _hit_point
		_swing.move_anchor(_swing_anchor, _enemy.velocity)
	var correction: SwingRope.Correction = _swing.constrain(global_position, body_velocity, Input.is_action_pressed("reel"), grounded, delta)
	if _enemy != null:
		# The rope pulls both ways: the enemy gets the speed the player gave up along the rope, shared out by its mass.
		var outward: Vector3 = (global_position - _hit_point).normalized()
		var given_up: float = (body_velocity - correction.velocity).dot(outward)
		if given_up > 0.0:
			_enemy.add_pull(outward * given_up)
	_sfx.set_reeling(_swing.is_reeling)
	if _swing.fully_reeled:
		_end_swing()
	return correction


## Creates the swing rope, fixing its length at the current distance to the hit point.
func _start_swing() -> void:
	_swing = SwingRope.new()
	_swing.min_length = stats.min_rope_length
	_swing.reel_speed = stats.reel_speed
	_swing.descent_speed = stats.descent_speed
	_swing_anchor = _hit_point
	var ground_height: float = NAN
	if _enemy == null:
		ground_height = GroundProbe.find_ground_height(get_world_3d().direct_space_state,
				_hit_point, _hit_normal, stats.clear_ground_radius, WORLD_MASK, stats.max_distance)
		if stats.anchor_push_out_enabled and absf(_hit_normal.y) < EdgeProbe.WALL_MAX_NORMAL_Y:
			_swing_anchor = _hit_point + _hit_normal * stats.anchor_push_out
	_swing.start(global_position, _swing_anchor, ground_height, stats.swing_ground_margin, stats.clear_ground_radius)


## The raycast from the crosshair against the world and the enemies, out to `reach`. Empty if it hits nothing.
func _cast_aim(reach: float) -> Dictionary:
	var origin: Vector3 = camera.global_position
	var target: Vector3 = origin - camera.global_basis.z * reach
	var query := PhysicsRayQueryParameters3D.create(origin, target, WORLD_MASK | ENEMY_MASK)
	return get_world_3d().direct_space_state.intersect_ray(query)


## The enemy a fire would take hold of within `reach`: one the crosshair ray hits, or else the one nearest the
## crosshair within the snap angle, if nothing blocks the way to it. Null if none.
func _find_enemy(reach: float) -> Enemy:
	var hit: Dictionary = _cast_aim(reach)
	if not hit.is_empty() and hit["collider"] is Enemy:
		var direct: Enemy = hit["collider"]
		return direct if direct.is_hookable() else null
	var origin: Vector3 = camera.global_position
	var forward: Vector3 = -camera.global_basis.z
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var best: Enemy = null
	var best_angle: float = INF
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy: Enemy = node as Enemy
		if enemy == null or not enemy.is_hookable():
			continue
		var to_enemy: Vector3 = enemy.get_center() - origin
		var distance: float = to_enemy.length()
		if distance > reach or distance < 0.1:
			continue
		var angle: float = forward.angle_to(to_enemy)
		var allowed: float = deg_to_rad(stats.enemy_snap_degrees) + asin(minf(enemy.stats.body_radius / distance, 1.0))
		if angle > allowed or angle >= best_angle:
			continue
		var blocked: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(origin, enemy.get_center(), WORLD_MASK))
		if blocked.is_empty():
			best = enemy
			best_angle = angle
	return best


## True if the point is on the ground plane the player stands on (the hook can't connect there).
func _is_ground(point: Vector3) -> bool:
	var feet_y: float = global_position.y - position.y # This node sits at mid-body.
	return absf(point.y - feet_y) <= stats.ground_tolerance


## True if the point lies on the plane of a wall the player is running on or beside (a launch at it is invalid).
func _is_on_player_wall(point: Vector3) -> bool:
	for normal: Vector3 in wall_normals:
		if normal != Vector3.ZERO and absf((point - global_position).dot(normal)) <= stats.wall_tolerance:
			return true
	return false


func _try_fire(is_swing: bool) -> void:
	_rope.stop_retract()
	var reach: float = stats.max_distance if is_swing else stats.launch_range
	var enemy: Enemy = _find_enemy(reach)
	if enemy != null:
		_fire_at_enemy(enemy, is_swing)
		return

	var hit: Dictionary = _cast_aim(reach)
	if hit.is_empty() or hit["collider"] is Enemy:
		return

	var point: Vector3 = hit["position"]
	if _is_ground(point) or (not is_swing and _is_on_player_wall(point)):
		return

	# A hit on a face just below a rooftop is moved onto the roof, so the hook grabs the rim.
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var rim: Dictionary = EdgeProbe.rim_snap(space, point, hit["normal"], WORLD_MASK)
	point = rim["point"]
	var normal: Vector3 = rim["normal"]
	_lip = EdgeProbe.lip_direction(space, point, WORLD_MASK) if normal.y > EdgeProbe.TOP_MIN_NORMAL_Y else Vector3.ZERO

	_enemy = null
	_begin_flight(point, normal, is_swing)


## Starts the hook flying at `enemy`. Its hit point follows the enemy.
func _fire_at_enemy(enemy: Enemy, is_swing: bool) -> void:
	_enemy = enemy
	_lip = Vector3.ZERO
	var point: Vector3 = enemy.get_center()
	_begin_flight(point, (global_position - point).normalized(), is_swing)


func _begin_flight(point: Vector3, normal: Vector3, is_swing: bool) -> void:
	_hit_point = point
	_hit_normal = normal
	_flight_speed = stats.extend_speed
	_tip = global_position
	_attached_time = 0.0
	_held_time = 0.0
	_chase_time = 0.0
	_state = State.EXTENDING
	_rope.visible = true
	if is_swing:
		_mode = Mode.SWING
		_sfx.play_thwip()
	else:
		_mode = Mode.LAUNCH
		_sfx.play_fire()


## Keeps the hit point on the enemy. False if the enemy is gone or can no longer be held.
func _follow_enemy() -> bool:
	if not is_instance_valid(_enemy):
		_enemy = null
		return false
	if _mode != Mode.THROW and not _enemy.is_hookable():
		return false
	_hit_point = _enemy.get_center()
	_hit_normal = (global_position - _hit_point).normalized()
	return true


## The hook is on an enemy and the fire button decides: let go and you are launched at it, hold on and it is a throw.
func _decide_enemy_launch() -> void:
	if not Input.is_action_pressed("grapple"):
		_launch()
	elif _held_time >= stats.throw_hold_time:
		_mode = Mode.THROW
		_throw.start(_enemy)


## On the world, the player gets `launch_speed` toward the launch aim point. On an enemy, Player's StrikeGuidance
## aims the launch into the enemy instead, so only `launched_at_enemy` is emitted.
func _launch() -> void:
	var target: Enemy = _enemy
	var aim_point: Vector3 = _hit_point
	if target == null:
		aim_point = LaunchAim.aim_point(global_position, _hit_point, camera.global_position,
				-camera.global_basis.z, stats.launch_height_offset, stats.launch_side_offset)
	var direction: Vector3 = (aim_point - global_position).normalized()
	_reset(true)
	_sfx.play_launch()
	if target != null:
		launched_at_enemy.emit(target)
	else:
		launched.emit(direction * stats.launch_speed)
	detached.emit()


## Releasing swing detaches. Released mid-flight, it just retracts (no shake, since it never attached).
func _end_swing() -> void:
	var was_attached: bool = _state == State.ATTACHED
	_reset(true)
	_sfx.play_thwip()
	if was_attached:
		detached.emit()


func _on_throw_released(launch_velocity: Vector3, power: float) -> void:
	_sfx.play_crack(power)
	thrown.emit(launch_velocity, power)


## The throw is over, thrown or not: the rope springs back and the player carries on with the momentum they had.
func _on_throw_ended() -> void:
	if _mode != Mode.THROW:
		return
	_sfx.play_slowmo_out()
	_reset(true)
	detached.emit()


## Puts the hook away. With `retract` the rope springs back to the hand instead of vanishing.
func _reset(retract: bool = false) -> void:
	var end: Vector3 = _tip if _state == State.EXTENDING else _hit_point
	var had_rope: bool = _state != State.IDLE
	_state = State.IDLE
	_mode = Mode.NONE
	_enemy = null
	if retract and had_rope:
		_rope.retract(global_position, end)
	else:
		_rope.stop_retract()
	_sfx.set_reeling(false)
