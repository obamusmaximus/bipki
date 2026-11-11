class_name Mantle
extends Node
## Climbs the player onto a ledge they walk or fall into. Player decides when to start (see
## `try_start`). Then this moves the body in a short, smooth path: up in front of the face, then
## forward onto the top. Emits `finished` when done. Player waits while `step` returns true.

signal finished

## Seconds for the whole climb.
@export var duration: float = 0.2
## Share of the climb spent rising before moving forward onto the top.
@export_range(0.1, 0.9) var rise_share: float = 0.45
## Speed (m/s) toward the face needed to start a climb.
@export var min_speed_into_wall: float = 0.5
## How far in from the top edge the feet land (metres). Must clear the body's radius (0.4 m).
@export var land_inset: float = 0.5

var _body: CharacterBody3D
var _start: Vector3 = Vector3.ZERO
var _rise_to: Vector3 = Vector3.ZERO
var _land: Vector3 = Vector3.ZERO
var _time: float = 0.0
var _active: bool = false


func setup(body: CharacterBody3D) -> void:
	_body = body


func is_active() -> bool:
	return _active


## Starts a climb if the body is moving into the face. Returns true if a climb started.
func try_start(ledge: EdgeProbe.Ledge, body_velocity: Vector3) -> bool:
	if _active or _body == null or not ledge.found:
		return false
	var flat: Vector3 = Vector3(body_velocity.x, 0.0, body_velocity.z)
	if flat.dot(ledge.wall_normal) > -min_speed_into_wall:
		return false
	_start = _body.global_position
	_rise_to = Vector3(_start.x, ledge.point.y, _start.z)
	_land = ledge.point - ledge.wall_normal * land_inset
	_land.y = ledge.point.y
	_time = 0.0
	_active = true
	return true


## Moves the body along the climb. Returns true on every frame of the climb, including the last.
func step(delta: float) -> bool:
	if not _active:
		return false
	_time += delta
	var t: float = clampf(_time / duration, 0.0, 1.0)
	if t < rise_share:
		_body.global_position = _start.lerp(_rise_to, smoothstep(0.0, 1.0, t / rise_share))
	else:
		var u: float = (t - rise_share) / (1.0 - rise_share)
		_body.global_position = _rise_to.lerp(_land, smoothstep(0.0, 1.0, u))
	if t >= 1.0:
		_active = false
		finished.emit()
		return true
	return true
