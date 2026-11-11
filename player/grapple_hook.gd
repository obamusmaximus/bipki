class_name GrappleHook
extends Node3D
## The grappling hook, fired from the camera crosshair. It has two inputs:
##  - Grapple (RMB, "grapple"): the hook flies to the hit point at extend_speed. What happens on
##    arrival depends on how long RMB is held.
##      - Hold past hold_threshold: PULL. Steady pull toward the point until RMB is released
##        or the player is within detach_distance.
##      - Quick click (released before hold_threshold): LAUNCH. A velocity boost toward a point
##        launch_height_offset above the hit point (so the player arcs over the target), then the hook detaches.
##        After attaching there is a launch_grace pause. Where the crosshair points when it ends
##        (left or right of the hit point) shifts the aim point sideways by up to launch_side_offset.
##  - Swing (LMB, "swing"): the hook flies at swing_extend_speed. On arrival the player hangs from
##    the hit point on a rope. The rope can shorten (hold jump to reel in) but never lengthen.
##    Momentum is not touched, so the player can steer by pivoting. Releasing LMB detaches.
## Place this node at mid-body: its position is the rope's start and the pull origin.

## Emitted when the hook tip reaches the hit point.
signal attached
## Emitted once when a launch connects. The player should add this velocity.
signal launched(launch_velocity: Vector3)
## Emitted when an attached hook ends: a pull finishing, a launch, or a swing released.
signal detached

enum State { IDLE, EXTENDING, ATTACHED }
enum Mode { UNDECIDED, PULL, LAUNCH, SWING }

@export var extend_speed: float = 90.0
@export var swing_extend_speed: float = 100.0
@export var pull_speed: float = 25.0
@export var launch_speed: float = 50.0
## A launch aims this many meters above the hit point.
@export var launch_height_offset: float = 6.0
## A launch aim point can shift sideways by up to this many meters, following the crosshair.
@export var launch_side_offset: float = 6.0
## Seconds between attaching and launching (the player's window to steer the sideways shift).
@export var launch_grace: float = 0.3
@export var detach_distance: float = 4.0
@export var max_distance: float = 10000.0
## Holding longer than this (seconds) turns a grapple press into a pull instead of a launch.
@export var hold_threshold: float = 0.2
## Hits within this height of the player's feet count as "the ground plane" and are rejected.
@export var ground_tolerance: float = 0.1
## Swing rope: how fast it shortens while jump is held, and the shortest it can get (metres).
@export var reel_speed: float = 8.0
@export var min_rope_length: float = 2.0
## World height of the ground, used to work out how much rope clears it during a swing.
@export var ground_height: float = 0.0
## A swing rope that is too long retracts so the player passes this far below the hit point's height above the ground.
@export var swing_ground_margin: float = 2.0
## The rope must be down to clearGround by the time the player is inside this horizontal radius (metres) of the point below the hit point.
@export var clear_ground_radius: float = 3.0

const WORLD_MASK: int = 1 # Collision layer 1: World

var _state: State = State.IDLE
var _mode: Mode = Mode.UNDECIDED
var _held_time: float = 0.0
var _hit_point: Vector3 = Vector3.ZERO
var _tip: Vector3 = Vector3.ZERO
var _flight_speed: float = 0.0
var _rope_length: float = 0.0
var _attached_time: float = 0.0
## Swing ground-clearance: the rope length the player should have when directly under the hit point.
var _clear_ground: float = 0.0
## Metres of rope retracted per metre the player descends below the hit point's height. Sized so
## the rope reaches clearGround at the edge of the clearance area (clear_ground_radius).
var _retract_rate: float = 0.0
var _last_y: float = 0.0

@onready var _camera: Camera3D = $"../Head/Camera3D"
@onready var _body: CharacterBody3D = get_parent() as CharacterBody3D
@onready var _rope: GrappleRope = $Rope
@onready var _sfx: GrappleSfx = $Sfx


func _physics_process(delta: float) -> void:
	if _state == State.IDLE:
		if Input.is_action_just_pressed("grapple"):
			_try_fire(false)
		elif Input.is_action_just_pressed("swing"):
			_try_fire(true)
		return

	_update_mode(delta)
	if _state == State.IDLE:
		return

	if _state == State.EXTENDING:
		_tip = _tip.move_toward(_hit_point, _flight_speed * delta)
		if _tip.is_equal_approx(_hit_point):
			_state = State.ATTACHED
			_sfx.play_attach()
			if _mode == Mode.PULL:
				_sfx.start_pull()
			if _mode == Mode.SWING:
				_start_swing()
			attached.emit()

	if _state == State.ATTACHED:
		if _mode == Mode.LAUNCH:
			_attached_time += delta
			if _attached_time >= launch_grace:
				_launch()
		elif _mode == Mode.PULL and global_position.distance_to(_hit_point) <= detach_distance:
			_end_pull()


func _process(_delta: float) -> void:
	if _state == State.EXTENDING:
		_rope.stretch_between(global_position, _tip)
	elif _state == State.ATTACHED:
		_rope.stretch_between(global_position, _hit_point)


## True only while the player should be actively pulled toward the hook point.
func is_pulling() -> bool:
	return _state == State.ATTACHED and _mode == Mode.PULL


## True while the player is hanging from a swing rope.
func is_swinging() -> bool:
	return _state == State.ATTACHED and _mode == Mode.SWING


## Velocity that pulls the player toward the hook point at a steady speed.
func get_pull_velocity() -> Vector3:
	return (_hit_point - global_position).normalized() * pull_speed


## Keeps the player inside the swing rope's length and returns the corrected velocity.
## Moves the body back onto the rope if it has gone past it, removes any velocity that
## points away from the hit point, and reels in while jump is held.
func apply_swing_constraint(body_velocity: Vector3, delta: float) -> Vector3:
	if Input.is_action_pressed("jump"):
		_rope_length = maxf(min_rope_length, _rope_length - reel_speed * delta)

	_retract_for_ground(global_position.y)

	var anchor: Vector3 = global_position
	var offset: Vector3 = anchor - _hit_point
	var distance: float = offset.length()
	if distance <= _rope_length:
		return body_velocity

	var outward: Vector3 = offset / distance
	_body.global_position += (_hit_point + outward * _rope_length) - anchor
	var outward_speed: float = body_velocity.dot(outward)
	if outward_speed > 0.0:
		body_velocity -= outward * outward_speed
	return body_velocity


## Fixes the rope length at attach and works out how fast to retract it for ground clearance.
func _start_swing() -> void:
	_rope_length = global_position.distance_to(_hit_point)
	_clear_ground = maxf(min_rope_length, _hit_point.y - ground_height - swing_ground_margin)
	# Depth below the hit point where a rope of clearGround length is exactly clear_ground_radius
	# away horizontally from the point beneath the hit point (edge of the clearance area).
	var finish_depth: float = sqrt(maxf(1.0, _clear_ground * _clear_ground - clear_ground_radius * clear_ground_radius))
	_retract_rate = maxf(0.0, _rope_length - _clear_ground) / finish_depth
	_last_y = global_position.y


## While the player drops below the hit point's height, shortens the rope in proportion to the
## descent, so it reaches _clear_ground just as the player enters the clearance area under the hit point.
func _retract_for_ground(y: float) -> void:
	var previous_depth: float = maxf(0.0, _hit_point.y - _last_y)
	var depth: float = maxf(0.0, _hit_point.y - y)
	_last_y = y
	var descended: float = maxf(0.0, depth - previous_depth)
	if descended > 0.0 and _rope_length > _clear_ground:
		_rope_length = maxf(_clear_ground, _rope_length - _retract_rate * descended)


func _update_mode(delta: float) -> void:
	if _mode == Mode.SWING:
		if not Input.is_action_pressed("swing"):
			_end_swing()
		return

	if Input.is_action_pressed("grapple"):
		_held_time += delta
		if _mode == Mode.UNDECIDED and _held_time >= hold_threshold:
			_mode = Mode.PULL
			if _state == State.ATTACHED:
				_sfx.start_pull() # Held past the threshold after connecting.
		return

	# Grapple button released.
	match _mode:
		Mode.UNDECIDED:
			_mode = Mode.LAUNCH # Quick click: launch once the hook connects.
		Mode.PULL:
			if _state == State.ATTACHED:
				_end_pull()
			else:
				_reset() # Cancelled mid-flight, never pulled.


func _try_fire(is_swing: bool) -> void:
	var origin: Vector3 = _camera.global_position
	var target: Vector3 = origin - _camera.global_basis.z * max_distance
	var query := PhysicsRayQueryParameters3D.create(origin, target, WORLD_MASK)
	query.exclude = [_body.get_rid()]

	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return

	var point: Vector3 = hit["position"]
	if absf(point.y - _body.global_position.y) <= ground_tolerance:
		return

	_hit_point = point
	_tip = global_position
	_held_time = 0.0
	_attached_time = 0.0
	_state = State.EXTENDING
	_rope.visible = true
	if is_swing:
		_mode = Mode.SWING
		_flight_speed = swing_extend_speed
		_sfx.play_thwip()
	else:
		_mode = Mode.UNDECIDED
		_flight_speed = extend_speed
		_sfx.play_fire()


func _launch() -> void:
	var aim_point: Vector3 = _hit_point + Vector3.UP * launch_height_offset + _launch_side_shift()
	var direction: Vector3 = (aim_point - global_position).normalized()
	_reset()
	_sfx.play_launch()
	launched.emit(direction * launch_speed)
	detached.emit()


## Sideways shift of the launch aim point. Measures how far left or right of the hit point the
## crosshair points (at the hit point's distance), clamped to launch_side_offset.
func _launch_side_shift() -> Vector3:
	var to_hit: Vector3 = _hit_point - global_position
	to_hit.y = 0.0
	if to_hit.is_zero_approx():
		return Vector3.ZERO
	var right: Vector3 = to_hit.normalized().cross(Vector3.UP)
	var look_point: Vector3 = _camera.global_position - _camera.global_basis.z * _camera.global_position.distance_to(_hit_point)
	var side: float = clampf((look_point - _hit_point).dot(right), -launch_side_offset, launch_side_offset)
	return right * side


func _end_pull() -> void:
	_reset()
	_sfx.play_detach()
	detached.emit()


## Releasing swing detaches. Released mid-flight, it just retracts (no shake, since it never attached).
func _end_swing() -> void:
	var was_attached: bool = _state == State.ATTACHED
	_reset()
	_sfx.play_thwip()
	if was_attached:
		detached.emit()


func _reset() -> void:
	_state = State.IDLE
	_mode = Mode.UNDECIDED
	_rope.visible = false
	_sfx.stop_pull()
