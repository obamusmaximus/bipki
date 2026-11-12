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
## Place this node at mid-body: its position is the rope's start.

## Emitted when the hook tip reaches the hit point.
signal attached
## Emitted once when a launch connects. The player should add this velocity.
signal launched(launch_velocity: Vector3)
## Emitted when an attached hook ends: a launch, or a swing released.
signal detached
## Emitted on attach when the hook is on a lip or an edge. The argument is the horizontal
## direction toward the open side.
signal attached_near_edge(lip_direction: Vector3)

enum State { IDLE, EXTENDING, ATTACHED }
enum Mode { NONE, LAUNCH, SWING }
## What the crosshair points at: nothing in reach, a valid hook target, or the ground plane (rejected).
enum Aim { NONE, VALID, GROUND }

## Tunable numbers. Set by Player through setup().
var stats: GrappleStats

## Set by Player: the camera the fire raycast and launch aim come from.
var camera: Camera3D

const WORLD_MASK: int = 1 # Collision layer 1: World

var _state: State = State.IDLE
var _mode: Mode = Mode.NONE
var _hit_point: Vector3 = Vector3.ZERO
var _tip: Vector3 = Vector3.ZERO
var _flight_speed: float = 0.0
var _hit_normal: Vector3 = Vector3.UP
var _attached_time: float = 0.0
var _swing: SwingRope
## Set when the hit is on a lip or an edge: the open direction. ZERO otherwise.
var _lip: Vector3 = Vector3.ZERO

@onready var _rope: GrappleRope = $Rope
@onready var _sfx: GrappleSfx = $Sfx


func _physics_process(delta: float) -> void:
	if _state == State.IDLE:
		if Input.is_action_just_pressed("grapple"):
			_try_fire(false)
		elif Input.is_action_just_pressed("swing"):
			_try_fire(true)
		return

	if _mode == Mode.SWING and not Input.is_action_pressed("swing"):
		_end_swing()
		return

	if _state == State.EXTENDING:
		_tip = _tip.move_toward(_hit_point, _flight_speed * delta)
		if _tip.is_equal_approx(_hit_point):
			_state = State.ATTACHED
			_sfx.play_attach()
			if _mode == Mode.SWING:
				_start_swing()
			if _lip != Vector3.ZERO:
				attached_near_edge.emit(_lip)
			attached.emit()

	if _state == State.ATTACHED and _mode == Mode.LAUNCH:
		_attached_time += delta
		if _attached_time >= stats.launch_grace:
			_launch()


func _process(_delta: float) -> void:
	if _state == State.EXTENDING:
		_rope.stretch_between(global_position, _tip, true)
	elif _state == State.ATTACHED:
		_rope.stretch_between(global_position, _hit_point)


## True while the player hangs from a swing rope.
## Called once by Player with the grapple's tuning, which is handed on to the rope and the sounds.
func setup(grapple_stats: GrappleStats) -> void:
	stats = grapple_stats
	_rope.setup(stats)
	_sfx.setup(stats)


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


## Current swing rope length, or 0 when not swinging.
func get_rope_length() -> float:
	return _swing.length if is_swinging() else 0.0


## The swing rope's length at attach, or 0 when not swinging.
func get_rope_start_length() -> float:
	return _swing.start_length if is_swinging() else 0.0


## What a fire would do right now. Runs the same raycast as firing, so call it from _physics_process.
func probe_aim() -> Aim:
	if camera == null:
		return Aim.NONE
	var hit: Dictionary = _cast_aim()
	if hit.is_empty():
		return Aim.NONE
	return Aim.GROUND if _is_ground(hit["position"]) else Aim.VALID


## What the player must apply to stay on the swing rope (see SwingRope.Correction). Reel (Shift) shortens it.
func constrain_swing(body_velocity: Vector3, delta: float) -> SwingRope.Correction:
	var correction: SwingRope.Correction = _swing.constrain(global_position, body_velocity, Input.is_action_pressed("reel"), delta)
	_sfx.set_reeling(_swing.is_reeling)
	if _swing.fully_reeled:
		_end_swing()
	return correction


## Creates the swing rope, fixing its length at the current distance to the hit point.
func _start_swing() -> void:
	var ground_height: float = GroundProbe.find_ground_height(get_world_3d().direct_space_state,
			_hit_point, _hit_normal, stats.clear_ground_radius, WORLD_MASK, stats.max_distance)
	_swing = SwingRope.new()
	_swing.min_length = stats.min_rope_length
	_swing.reel_speed = stats.reel_speed
	_swing.descent_speed = stats.descent_speed
	_swing.start(global_position, _hit_point, ground_height, stats.swing_ground_margin, stats.clear_ground_radius)


## The raycast from the crosshair against the world. Empty if it hits nothing.
func _cast_aim() -> Dictionary:
	var origin: Vector3 = camera.global_position
	var target: Vector3 = origin - camera.global_basis.z * stats.max_distance
	var query := PhysicsRayQueryParameters3D.create(origin, target, WORLD_MASK)
	return get_world_3d().direct_space_state.intersect_ray(query)


## True if the point is on the ground plane the player stands on (the hook can't connect there).
func _is_ground(point: Vector3) -> bool:
	var feet_y: float = global_position.y - position.y # This node sits at mid-body.
	return absf(point.y - feet_y) <= stats.ground_tolerance


func _try_fire(is_swing: bool) -> void:
	var hit: Dictionary = _cast_aim()
	if hit.is_empty():
		return

	var point: Vector3 = hit["position"]
	if _is_ground(point):
		return

	# A hit on a face just below a rooftop is moved onto the roof, so the hook grabs the rim.
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var rim: Dictionary = EdgeProbe.rim_snap(space, point, hit["normal"], WORLD_MASK)
	point = rim["point"]
	var normal: Vector3 = rim["normal"]
	_lip = EdgeProbe.lip_direction(space, point, WORLD_MASK) if normal.y > EdgeProbe.TOP_MIN_NORMAL_Y else Vector3.ZERO

	_hit_point = point
	_hit_normal = normal
	_flight_speed = stats.extend_speed
	_tip = global_position
	_attached_time = 0.0
	_state = State.EXTENDING
	_rope.visible = true
	if is_swing:
		_mode = Mode.SWING
		_sfx.play_thwip()
	else:
		_mode = Mode.LAUNCH
		_sfx.play_fire()


func _launch() -> void:
	var aim_point: Vector3 = LaunchAim.aim_point(global_position, _hit_point, camera.global_position,
			-camera.global_basis.z, stats.launch_height_offset, stats.launch_side_offset)
	var direction: Vector3 = (aim_point - global_position).normalized()
	_reset()
	_sfx.play_launch()
	launched.emit(direction * stats.launch_speed)
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
	_mode = Mode.NONE
	_rope.visible = false
	_sfx.set_reeling(false)
