class_name BeamAttack
extends Node
## The drone's beam: a timed cycle. After `cooldown` it waits for a clear line to the target, charges,
## then latches the target's position and aims at it (even if the target has since moved out of sight),
## and after the aim delay fires. The aim delay is the player's grace period to get out of the line.
## It reports each step with signals; BeamVisual and DroneSfx listen.

signal charge_started
signal aim_started(latched: Vector3)
## `from` and `to` are the beam's ends: it stops at the first building. `hit_target` is true if it hurt the target.
signal fired(from: Vector3, to: Vector3, hit_target: bool)

enum State { COOLDOWN, READY, CHARGING, AIMING }

## Seconds from one shot to the next charge becoming possible.
@export var cooldown: float = 7.0
@export var charge_time: float = 1.5
## Seconds between the aim locking and the shot.
@export var aim_delay: float = 0.5
@export var damage: float = 35.0
## Beam thickness (radius, metres).
@export var beam_radius: float = 1.8
@export var beam_range: float = 400.0

const WORLD_LAYER: int = 1  ## Collision layer 1 (World) as a mask bit.
## Heights above the target's feet that count as the body when checking a hit.
const BODY_HEIGHTS: PackedFloat32Array = [0.4, 0.9, 1.4]
const BODY_RADIUS: float = 0.4

var _origin: Node3D
var _target: Node3D
var _target_health: Health
var _state: State = State.COOLDOWN
var _timer: float = 0.0
var _latched: Vector3 = Vector3.ZERO


func setup(origin: Node3D, target: Node3D) -> void:
	_origin = origin
	_target = target
	_target_health = target.get_node_or_null("Health") as Health
	_timer = cooldown


func get_state() -> State:
	return _state


## 0 at the start of the charge, 1 at its end. Zero when not charging.
func get_charge_fraction() -> float:
	if _state != State.CHARGING:
		return 0.0
	return 1.0 - _timer / charge_time


## Where the beam would end if fired now: along the line to the latched point, stopped by the first building.
func get_aim_end() -> Vector3:
	var from: Vector3 = _origin.global_position
	var dir: Vector3 = from.direction_to(_latched)
	var far: Vector3 = from + dir * beam_range
	var hit: Dictionary = _raycast(from, far)
	return far if hit.is_empty() else hit["position"]


func _physics_process(delta: float) -> void:
	if _origin == null or _target == null:
		return
	match _state:
		State.COOLDOWN:
			_timer -= delta
			if _timer <= 0.0:
				_state = State.READY
		State.READY:
			if _has_line_of_sight():
				_state = State.CHARGING
				_timer = charge_time
				charge_started.emit()
		State.CHARGING:
			_timer -= delta
			if _timer <= 0.0:
				_latched = _target_point()
				_state = State.AIMING
				_timer = aim_delay
				aim_started.emit(_latched)
		State.AIMING:
			_timer -= delta
			if _timer <= 0.0:
				_fire()
				_state = State.COOLDOWN
				_timer = cooldown


func _fire() -> void:
	var from: Vector3 = _origin.global_position
	var to: Vector3 = get_aim_end()
	var hit: bool = _beam_hits_target(from, to)
	if hit:
		if _target_health != null:
			_target_health.take_damage(damage)
	fired.emit(from, to, hit)


## True if the target's body is within the beam's thickness of the segment from -> to.
func _beam_hits_target(from: Vector3, to: Vector3) -> bool:
	for height: float in BODY_HEIGHTS:
		var point: Vector3 = _target.global_position + Vector3.UP * height
		var nearest: Vector3 = Geometry3D.get_closest_point_to_segment(point, from, to)
		if nearest.distance_to(point) <= beam_radius + BODY_RADIUS:
			return true
	return false


func _target_point() -> Vector3:
	return _target.global_position + Vector3.UP * 0.9


func _has_line_of_sight() -> bool:
	return _raycast(_origin.global_position, _target_point()).is_empty()


func _raycast(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, WORLD_LAYER)
	return _origin.get_world_3d().direct_space_state.intersect_ray(query)
