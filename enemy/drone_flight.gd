class_name DroneFlight
extends Node
## Decides where a flying enemy goes. It picks a goal on a ring around the target, just outside the
## standoff distance and with a clear line to the target, flies there by an A* path that never enters
## the standoff sphere. It only returns a desired velocity; the Drone applies it.

## The drone never approaches closer than this to the target on its own (metres). It does not back
## away if the target comes closer.
@export var standoff: float = 15.0
@export var speed: float = 16.0
## Deceleration used to slow down on arrival. Keep it below the Drone's acceleration.
@export var approach_decel: float = 20.0
## Goals sit on rings this far outside the standoff distance (metres), nearest ring first.
@export var ring_margins: PackedFloat32Array = PackedFloat32Array([3.0, 7.0])
## Heights above the target's chest tried for goals (metres). Each must be below the ring radius.
@export var goal_heights: PackedFloat32Array = PackedFloat32Array([0.0, 8.0, 16.0, 24.0])
## A goal is kept while the target stays between standoff + goal_keep_min and standoff + goal_keep_max away.
@export var goal_keep_min: float = 1.0
@export var goal_keep_max: float = 14.0
@export var repath_interval: float = 0.4
## A waypoint counts as reached within this distance.
@export var waypoint_reach: float = 3.0

const RING_ANGLES: int = 16
## The last stretch of the line to the target is not checked: the target may stand inside a building's margin.
const SIGHT_TAIL: float = 3.0

var _grid: FlightGrid
var _target: Node3D
var _goal: Vector3 = Vector3.INF
var _path: PackedVector3Array = PackedVector3Array()
var _next: int = 0
var _repath_in: float = 0.0
var _holding: bool = false


func setup(grid: FlightGrid, target: Node3D) -> void:
	_grid = grid
	_target = target


## True while parked at its goal.
func is_holding() -> bool:
	return _holding


func desired_velocity(pos: Vector3, delta: float) -> Vector3:
	if _grid == null or _target == null:
		return Vector3.ZERO
	var target_pos: Vector3 = _target.global_position + Vector3.UP * 0.9
	if pos.distance_to(target_pos) < standoff:
		# Too close (the target walked up to it): it doesn't advance, and it doesn't back away either.
		_holding = true
		return Vector3.ZERO

	_repath_in -= delta
	if _repath_in <= 0.0:
		_repath_in = repath_interval
		if not _goal_still_good(target_pos):
			_goal = _pick_goal(pos, target_pos)
		_path = _grid.find_path(pos, _goal, target_pos, standoff) if _goal != Vector3.INF else PackedVector3Array()
		_next = 0
	return _follow_path(pos)


func _follow_path(pos: Vector3) -> Vector3:
	_holding = _goal != Vector3.INF and pos.distance_to(_goal) < waypoint_reach
	if _holding or _path.is_empty():
		return Vector3.ZERO
	while _next < _path.size() and pos.distance_to(_path[_next]) < waypoint_reach:
		_next += 1
	# Cut corners: head for the next waypoint along if the air between is clear.
	if _next + 1 < _path.size() and _grid.line_clear(pos, _path[_next + 1]):
		_next += 1
	if _next >= _path.size():
		return Vector3.ZERO
	var to_goal: float = pos.distance_to(_goal)
	var slow: float = minf(speed, sqrt(2.0 * approach_decel * maxf(to_goal - 1.0, 0.0)))
	return pos.direction_to(_path[_next]) * slow


func _goal_still_good(target_pos: Vector3) -> bool:
	if _goal == Vector3.INF:
		return false
	var dist: float = _goal.distance_to(target_pos)
	return dist >= standoff + goal_keep_min and dist <= standoff + goal_keep_max and _can_see(_goal, target_pos)


## The open spot on a ring around the target that sees it and is nearest to the drone. If none sees it,
## the nearest open ring spot, so the drone still closes in.
func _pick_goal(pos: Vector3, target_pos: Vector3) -> Vector3:
	var best_seen: Vector3 = Vector3.INF
	var best_seen_dist: float = INF
	var best_any: Vector3 = Vector3.INF
	var best_any_dist: float = INF
	for margin: float in ring_margins:
		for height: float in goal_heights:
			for i: int in RING_ANGLES:
				var angle: float = TAU * i / RING_ANGLES
				var radius: float = standoff + margin
				if height >= radius:
					continue
				# Stay on a sphere of `radius`, so a higher goal sits nearer in the plan view.
				var flat: float = sqrt(radius * radius - height * height)
				var raw: Vector3 = target_pos + Vector3(cos(angle) * flat, height, sin(angle) * flat)
				var spot: Vector3 = _grid.nearest_open_position(raw)
				if not _grid.is_open_at(spot) or spot.distance_to(target_pos) < standoff + goal_keep_min:
					continue
				var dist: float = pos.distance_to(spot)
				if dist < best_any_dist:
					best_any_dist = dist
					best_any = spot
				if dist < best_seen_dist and _can_see(spot, target_pos):
					best_seen_dist = dist
					best_seen = spot
	return best_seen if best_seen != Vector3.INF else best_any


func _can_see(from: Vector3, target_pos: Vector3) -> bool:
	var length: float = from.distance_to(target_pos)
	if length <= SIGHT_TAIL:
		return true
	return _grid.line_clear(from, from.move_toward(target_pos, length - SIGHT_TAIL))


