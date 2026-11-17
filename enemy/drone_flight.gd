class_name DroneFlight
extends Node
## Decides where a flying enemy goes. It picks a goal on a ring around the target, just outside the
## standoff distance and with a clear line to the target, flies there by an A* path that never enters
## the standoff sphere. It only returns a desired velocity; the Drone applies it.
## Flyers spread out: a goal counts as claimed, and another flyer won't pick a spot within
## `goal_separation_degrees` of it (as seen from the target), so they surround the target instead of
## bunching up. Beyond `seek_range` of the target (walls don't matter) it does nothing and claims nothing.

var stats: DroneStats

const RING_ANGLES: int = 16
## The last stretch of the line to the target is not checked: the target may stand inside a building's margin.
const SIGHT_TAIL: float = 3.0
## Routes keep this much further out than the standoff distance (m), so a flyer rounding the target
## doesn't graze the standoff sphere and stop there.
const PATH_CLEARANCE: float = 2.0
## Every DroneFlight is in this group, so each can see the goals the others have claimed.
const GROUP: StringName = &"drone_flights"

var _grid: FlightGrid
var _target: Node3D
var _goal: Vector3 = Vector3.INF
var _path: PackedVector3Array = PackedVector3Array()
var _next: int = 0
var _repath_in: float = 0.0
var _holding: bool = false


func _enter_tree() -> void:
	add_to_group(GROUP)


func setup(grid: FlightGrid, target: Node3D, drone_stats: DroneStats) -> void:
	stats = drone_stats
	_grid = grid
	_target = target


## Drops the goal and path, so the next tick plans from where the drone is (a rewind moved it).
func reset() -> void:
	_stand_down()


## True while parked at its goal.
func is_holding() -> bool:
	return _holding


## The spot this flyer is heading for or parked at, or Vector3.INF if it has none.
func get_goal() -> Vector3:
	return _goal


func desired_velocity(pos: Vector3, delta: float) -> Vector3:
	if _grid == null or _target == null:
		return Vector3.ZERO
	var target_pos: Vector3 = _target.global_position + Vector3.UP * 0.9
	if pos.distance_to(target_pos) > stats.seek_range:
		_stand_down()
		return Vector3.ZERO
	if pos.distance_to(target_pos) < stats.standoff:
		# Too close (the target walked up to it): it doesn't advance, and it doesn't back away either.
		_holding = true
		return Vector3.ZERO

	_repath_in -= delta
	if _repath_in <= 0.0:
		_repath_in = stats.repath_interval
		var claimed: PackedVector3Array = _claimed_goals()
		if not _goal_still_good(target_pos, claimed):
			_goal = _pick_goal(pos, target_pos, claimed)
		_path = _grid.find_path(pos, _goal, target_pos, stats.standoff + PATH_CLEARANCE) if _goal != Vector3.INF else PackedVector3Array()
		_next = 0
	return _follow_path(pos, target_pos)


func _follow_path(pos: Vector3, target_pos: Vector3) -> Vector3:
	_holding = _goal != Vector3.INF and pos.distance_to(_goal) < stats.waypoint_reach
	if _holding or _path.is_empty():
		return Vector3.ZERO
	while _next < _path.size() and pos.distance_to(_path[_next]) < stats.waypoint_reach:
		_next += 1
	# Cut corners: head for the next waypoint along if the air between is clear and stays out of the standoff sphere.
	if _next + 1 < _path.size() and _keeps_standoff(pos, _path[_next + 1], target_pos) and _grid.line_clear(pos, _path[_next + 1]):
		_next += 1
	if _next >= _path.size():
		return Vector3.ZERO
	var to_goal: float = pos.distance_to(_goal)
	var slow: float = minf(stats.speed, sqrt(2.0 * stats.approach_decel * maxf(to_goal - 1.0, 0.0)))
	return pos.direction_to(_path[_next]) * slow


## True if the straight line from `from` to `to` stays clear of the standoff sphere around the target.
func _keeps_standoff(from: Vector3, to: Vector3, target_pos: Vector3) -> bool:
	var near: Vector3 = Geometry3D.get_closest_point_to_segment(target_pos, from, to)
	return near.distance_to(target_pos) >= stats.standoff + PATH_CLEARANCE - 1.0


## Out of seeking range: forget the goal (which frees its claim) and the path.
func _stand_down() -> void:
	_goal = Vector3.INF
	_path = PackedVector3Array()
	_holding = false
	_repath_in = 0.0


func _goal_still_good(target_pos: Vector3, claimed: PackedVector3Array) -> bool:
	if _goal == Vector3.INF:
		return false
	var dist: float = _goal.distance_to(target_pos)
	if dist < stats.standoff + stats.goal_keep_min or dist > stats.standoff + stats.goal_keep_max:
		return false
	return _can_see(_goal, target_pos) and _separation(_goal, target_pos, claimed) >= deg_to_rad(stats.goal_separation_degrees)


## The goals of the other flyers that this one gives way to. Of two flyers whose goals crowd each other
## only the later one (by instance id) moves, so they don't both jump at once.
func _claimed_goals() -> PackedVector3Array:
	var claimed := PackedVector3Array()
	for node: Node in get_tree().get_nodes_in_group(GROUP):
		var other: DroneFlight = node as DroneFlight
		if other == null or other == self or other.get_instance_id() > get_instance_id():
			continue
		if other.get_goal() != Vector3.INF:
			claimed.append(other.get_goal())
	return claimed


## The angle (radians, seen from the target) between `spot` and the nearest claimed goal. INF if there is none.
func _separation(spot: Vector3, target_pos: Vector3, claimed: PackedVector3Array) -> float:
	var nearest: float = INF
	var to_spot: Vector3 = spot - target_pos
	for other: Vector3 in claimed:
		nearest = minf(nearest, to_spot.angle_to(other - target_pos))
	return nearest


## The open spot on a ring around the target that sees it, is clear of the other flyers' goals and is
## nearest to the drone. If every such spot is taken, the one that sees the target and is farthest from the
## other goals; if none sees it, the nearest open ring spot, so the drone still closes in.
func _pick_goal(pos: Vector3, target_pos: Vector3, claimed: PackedVector3Array) -> Vector3:
	var best_free: Vector3 = Vector3.INF
	var best_free_dist: float = INF
	var min_angle: float = deg_to_rad(stats.goal_separation_degrees)
	var best_seen: Vector3 = Vector3.INF
	var best_seen_angle: float = -1.0
	var best_any: Vector3 = Vector3.INF
	var best_any_dist: float = INF
	for margin: float in stats.ring_margins:
		for height: float in stats.goal_heights:
			for i: int in RING_ANGLES:
				var angle: float = TAU * i / RING_ANGLES
				var radius: float = stats.standoff + margin
				if height >= radius:
					continue
				# Stay on a sphere of `radius`, so a higher goal sits nearer in the plan view.
				var flat: float = sqrt(radius * radius - height * height)
				var raw: Vector3 = target_pos + Vector3(cos(angle) * flat, height, sin(angle) * flat)
				var spot: Vector3 = _grid.nearest_open_position(raw)
				if not _grid.is_open_at(spot) or spot.distance_to(target_pos) < stats.standoff + stats.goal_keep_min:
					continue
				var dist: float = pos.distance_to(spot)
				if dist < best_any_dist:
					best_any_dist = dist
					best_any = spot
				if not _can_see(spot, target_pos):
					continue
				var angle_free: float = _separation(spot, target_pos, claimed)
				if angle_free >= min_angle:
					if dist < best_free_dist:
						best_free_dist = dist
						best_free = spot
				elif angle_free > best_seen_angle:
					best_seen_angle = angle_free
					best_seen = spot
	if best_free != Vector3.INF:
		return best_free
	return best_seen if best_seen != Vector3.INF else best_any


func _can_see(from: Vector3, target_pos: Vector3) -> bool:
	var length: float = from.distance_to(target_pos)
	if length <= SIGHT_TAIL:
		return true
	return _grid.line_clear(from, from.move_toward(target_pos, length - SIGHT_TAIL))
