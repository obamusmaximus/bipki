class_name BeamAttack
extends Node
## The drone's beam: a timed cycle. After `cooldown` (the first one starts after `opening_delay` plus a random
## share of the cooldown) it waits for a clear line to the target within `seek_range` and for the level's
## AttackCoordinator to allow it (so drones don't fire together), charges,
## then latches the target's position and aims at it (even if the target has since moved out of sight),
## and after the aim delay fires. The aim delay is the player's grace period to get out of the line.
## It reports each step with signals; BeamVisual and DroneSfx listen.

signal charge_started
signal aim_started(latched: Vector3)
## `from` and `to` are the beam's ends: it stops at the first building. `hit_target` is true if it hurt the target.
signal fired(from: Vector3, to: Vector3, hit_target: bool)
## Emitted when a charge or aim is cut short (the drone was grabbed).
signal cancelled

enum State { COOLDOWN, READY, CHARGING, AIMING }

var stats: DroneStats

const WORLD_LAYER: int = 1  ## Collision layer 1 (World) as a mask bit.
## Heights above the target's feet that count as the body when checking a hit.
const BODY_HEIGHTS: PackedFloat32Array = [0.4, 0.9, 1.4]
const BODY_RADIUS: float = 0.4

var _origin: Node3D
var _coordinator: AttackCoordinator
var _target: Node3D
var _target_health: Health
var _state: State = State.COOLDOWN
var _timer: float = 0.0
var _latched: Vector3 = Vector3.ZERO
var _active: bool = true


## `coordinator` spaces this beam out from the level's other attackers; null means no limit.
func setup(origin: Node3D, target: Node3D, drone_stats: DroneStats, coordinator: AttackCoordinator = null) -> void:
	stats = drone_stats
	_origin = origin
	_target = target
	_coordinator = coordinator
	_target_health = target.get_node_or_null("Health") as Health
	# Nothing fires as the level or the drone appears, and drones that appear together start at different points.
	_timer = stats.opening_delay + stats.cooldown * randf()


## Switches the cycle on or off. While off, no timer runs and nothing fires.
func set_active(active: bool) -> void:
	_active = active


## Drops whatever the beam was doing (a charge, a locked aim) and starts the cooldown over.
func cancel() -> void:
	if _state == State.CHARGING or _state == State.AIMING:
		cancelled.emit()
	_state = State.COOLDOWN
	_timer = stats.cooldown
	_release_token()


## The cycle's state for a rewind snapshot (part of the drone's).
func rewind_capture() -> Dictionary:
	return {&"state": _state, &"timer": _timer, &"latched": _latched, &"active": _active}


## Puts the cycle back. A charge or aim in progress is cut off (`cancelled`, so the charge sound stops), and the
## attack token is taken or given back to match the restored step.
func rewind_restore(saved: Dictionary) -> void:
	if _state == State.CHARGING or _state == State.AIMING:
		cancelled.emit()
	_state = saved[&"state"]
	_timer = saved[&"timer"]
	_latched = saved[&"latched"]
	_active = saved[&"active"]
	if _coordinator == null:
		return
	if _state == State.CHARGING or _state == State.AIMING:
		_coordinator.claim(self)
	else:
		_coordinator.release(self)


## A freed drone gives its attack token back.
func _exit_tree() -> void:
	_release_token()


func get_state() -> State:
	return _state


## 0 at the start of the charge, 1 at its end. Zero when not charging.
func get_charge_fraction() -> float:
	if _state != State.CHARGING:
		return 0.0
	return 1.0 - _timer / stats.charge_time


## Where the beam would end if fired now: along the line to the latched point, stopped by the first building.
func get_aim_end() -> Vector3:
	var from: Vector3 = _origin.global_position
	var dir: Vector3 = from.direction_to(_latched)
	var far: Vector3 = from + dir * stats.beam_range
	var hit: Dictionary = _raycast(from, far)
	return far if hit.is_empty() else hit["position"]


func _physics_process(delta: float) -> void:
	if _origin == null or _target == null or not _active:
		return
	match _state:
		State.COOLDOWN:
			_timer -= delta
			if _timer <= 0.0:
				_state = State.READY
		State.READY:
			if _in_seek_range() and _has_line_of_sight() and _may_attack():
				_state = State.CHARGING
				_timer = stats.charge_time
				charge_started.emit()
		State.CHARGING:
			_timer -= delta
			if _timer <= 0.0:
				_latched = _target_point()
				_state = State.AIMING
				_timer = stats.aim_delay
				aim_started.emit(_latched)
		State.AIMING:
			_timer -= delta
			if _timer <= 0.0:
				_fire()
				_state = State.COOLDOWN
				_timer = stats.cooldown
				_release_token()


## True if the level lets this beam start an attack now (always, with no coordinator). Asked last, so a token
## isn't spent on a drone that couldn't have fired anyway.
func _may_attack() -> bool:
	return _coordinator == null or _coordinator.request(self)


func _release_token() -> void:
	if _coordinator != null:
		_coordinator.release(self)


func _fire() -> void:
	var from: Vector3 = _origin.global_position
	var to: Vector3 = get_aim_end()
	var hit: bool = _beam_hits_target(from, to)
	if hit:
		if _target_health != null:
			_target_health.take_damage(stats.damage)
	fired.emit(from, to, hit)


## True if the target's body is within the beam's thickness of the segment from -> to.
func _beam_hits_target(from: Vector3, to: Vector3) -> bool:
	for height: float in BODY_HEIGHTS:
		var point: Vector3 = _target.global_position + Vector3.UP * height
		var nearest: Vector3 = Geometry3D.get_closest_point_to_segment(point, from, to)
		if nearest.distance_to(point) <= stats.beam_radius + BODY_RADIUS:
			return true
	return false


func _target_point() -> Vector3:
	return _target.global_position + Vector3.UP * 0.9


func _in_seek_range() -> bool:
	return _origin.global_position.distance_to(_target_point()) <= stats.seek_range


func _has_line_of_sight() -> bool:
	return _raycast(_origin.global_position, _target_point()).is_empty()


func _raycast(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, WORLD_LAYER)
	return _origin.get_world_3d().direct_space_state.intersect_ray(query)
