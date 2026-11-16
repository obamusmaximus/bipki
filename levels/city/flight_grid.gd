class_name FlightGrid
extends RefCounted
## A coarse 3D grid of the open air in the city, with A* over it. Built from the building boxes, so it
## needs no physics and runs headless. A cell is open only if it is entirely clear of every building
## inflated by `margin`, so a flyer whose radius is below `margin` can sit anywhere in an open cell.

var _origin: Vector3
var _cell: Vector3
var _dims: Vector3i
var _open: PackedByteArray = PackedByteArray()
var _astar := AStar3D.new()


## Grid for a city plan. cell_xz and cell_y are cell sizes in metres. Streets are about 12 m wide, so
## cell_xz must stay at or below (12 - 2 * margin) / 2 for a street to always contain an open cell.
static func from_plan(plan: CityPlan, cell_xz: float = 4.0, cell_y: float = 6.0, margin: float = 1.5, headroom: float = 20.0) -> FlightGrid:
	var boxes: Array[AABB] = []
	for site: CityPlan.Site in plan.sites:
		boxes.append(site.world_box())
	return from_boxes(boxes, cell_xz, cell_y, margin, headroom)


static func from_boxes(boxes: Array[AABB], cell_xz: float, cell_y: float, margin: float, headroom: float) -> FlightGrid:
	var grid := FlightGrid.new()
	grid._build(boxes, Vector3(cell_xz, cell_y, cell_xz), margin, headroom)
	return grid


func get_cell_count() -> int:
	return _open.size()


func get_open_count() -> int:
	return _astar.get_point_count()


func get_bounds() -> AABB:
	return AABB(_origin, Vector3(_dims) * _cell)


## True if `pos` is inside the grid and in an open cell.
func is_open_at(pos: Vector3) -> bool:
	var index: int = cell_index(pos)
	return index >= 0 and _open[index] == 1


## True if the straight line between the points stays in open cells.
func line_clear(from: Vector3, to: Vector3) -> bool:
	var length: float = from.distance_to(to)
	var steps: int = maxi(1, ceili(length / (minf(_cell.x, _cell.y) * 0.5)))
	for i: int in steps + 1:
		if not is_open_at(from.lerp(to, float(i) / steps)):
			return false
	return true


## Centre of the open cell nearest to `pos`, or `pos` itself if there is none within a few cells.
func nearest_open_position(pos: Vector3) -> Vector3:
	var index: int = _nearest_open(pos)
	return pos if index < 0 else _centre(index)


## Centre of a random open cell, or Vector3.INF if the grid has none.
func random_open_position(rng: RandomNumberGenerator) -> Vector3:
	var ids: PackedInt64Array = _astar.get_point_ids()
	if ids.is_empty():
		return Vector3.INF
	return _astar.get_point_position(ids[rng.randi_range(0, ids.size() - 1)])


## Path through open air from `from` to `to`, as waypoints (the cells nearest each end are used).
## Straightened wherever a clear line exists. Empty if there is no route.
## If `avoid_radius` is above zero, the route stays that far from `avoid_centre` (the start cell is exempt).
func find_path(from: Vector3, to: Vector3, avoid_centre: Vector3 = Vector3.ZERO, avoid_radius: float = 0.0) -> PackedVector3Array:
	var start: int = _nearest_open(from)
	var goal: int = _nearest_open(to)
	if start < 0 or goal < 0:
		return PackedVector3Array()
	var disabled: PackedInt32Array = PackedInt32Array()
	if avoid_radius > 0.0:
		disabled = _disable_sphere(avoid_centre, avoid_radius, start, goal)
	var path: PackedVector3Array = _astar.get_point_path(start, goal)
	for id: int in disabled:
		_astar.set_point_disabled(id, false)
	return _smooth(path, avoid_centre, avoid_radius)


## Cell index holding `pos`, or -1 outside the grid.
func cell_index(pos: Vector3) -> int:
	var c: Vector3i = _coords(pos)
	if not _inside(c):
		return -1
	return _flat(c)


func _build(boxes: Array[AABB], cell: Vector3, margin: float, headroom: float) -> void:
	_cell = cell
	var area := AABB(Vector3.ZERO, Vector3.ZERO)
	for i: int in boxes.size():
		area = boxes[i] if i == 0 else area.merge(boxes[i])
	var pad: float = 20.0
	_origin = Vector3(area.position.x - pad, 0.0, area.position.z - pad)
	var top: float = area.end.y + headroom
	var size := Vector3(area.size.x + pad * 2.0, top, area.size.z + pad * 2.0)
	_dims = Vector3i(ceili(size.x / cell.x), ceili(size.y / cell.y), ceili(size.z / cell.z))
	_open.resize(_dims.x * _dims.y * _dims.z)
	_open.fill(1)

	for box: AABB in boxes:
		_block(box.grow(margin))

	for y: int in _dims.y:
		for z: int in _dims.z:
			for x: int in _dims.x:
				var c := Vector3i(x, y, z)
				if _open[_flat(c)] == 1:
					_astar.add_point(_flat(c), _centre_of(c))
	for y: int in _dims.y:
		for z: int in _dims.z:
			for x: int in _dims.x:
				var c := Vector3i(x, y, z)
				if _open[_flat(c)] == 0:
					continue
				for step: Vector3i in [Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 0, 1)]:
					var n: Vector3i = c + step
					if _inside(n) and _open[_flat(n)] == 1:
						_astar.connect_points(_flat(c), _flat(n))


## Marks every cell the box overlaps at all as blocked.
func _block(box: AABB) -> void:
	var from_f: Vector3 = (box.position - _origin) / _cell
	var to_f: Vector3 = (box.end - _origin) / _cell
	var lo: Vector3i = Vector3i(floori(from_f.x), floori(from_f.y), floori(from_f.z)).max(Vector3i.ZERO)
	var hi := Vector3i(ceili(to_f.x) - 1, ceili(to_f.y) - 1, ceili(to_f.z) - 1).min(_dims - Vector3i.ONE)
	for y: int in range(lo.y, hi.y + 1):
		for z: int in range(lo.z, hi.z + 1):
			for x: int in range(lo.x, hi.x + 1):
				_open[_flat(Vector3i(x, y, z))] = 0


func _nearest_open(pos: Vector3, max_radius: int = 6) -> int:
	var origin: Vector3i = _coords(pos).clamp(Vector3i.ZERO, _dims - Vector3i.ONE)
	for r: int in max_radius + 1:
		var best: int = -1
		var best_dist: float = INF
		for dy: int in range(-r, r + 1):
			for dz: int in range(-r, r + 1):
				for dx: int in range(-r, r + 1):
					if maxi(maxi(absi(dx), absi(dy)), absi(dz)) != r:
						continue
					var c: Vector3i = origin + Vector3i(dx, dy, dz)
					if not _inside(c) or _open[_flat(c)] == 0:
						continue
					var dist: float = _centre_of(c).distance_squared_to(pos)
					if dist < best_dist:
						best_dist = dist
						best = _flat(c)
		if best >= 0:
			return best
	return -1


## Greedy straightening: from each kept point, jump to the farthest point with a clear line.
func _smooth(path: PackedVector3Array, avoid_centre: Vector3, avoid_radius: float) -> PackedVector3Array:
	if path.size() <= 2:
		return path
	var out := PackedVector3Array([path[0]])
	var i: int = 0
	var last: int = path.size() - 1
	while i < last:
		var j: int = last
		while j > i + 1 and not _straight_ok(path[i], path[j], avoid_centre, avoid_radius):
			j -= 1
		out.append(path[j])
		i = j
	return out


## A clear line that also keeps (almost) `avoid_radius` from `avoid_centre`.
func _straight_ok(a: Vector3, b: Vector3, avoid_centre: Vector3, avoid_radius: float) -> bool:
	if avoid_radius > 0.0:
		var near: Vector3 = Geometry3D.get_closest_point_to_segment(avoid_centre, a, b)
		if near.distance_to(avoid_centre) < avoid_radius - 1.0:
			return false
	return line_clear(a, b)


## Disables every open cell whose centre is within `radius` of `centre`, except `keep_a` and `keep_b`.
## Returns the cells it disabled so the caller can enable them again.
func _disable_sphere(centre: Vector3, radius: float, keep_a: int, keep_b: int) -> PackedInt32Array:
	var disabled := PackedInt32Array()
	var lo: Vector3i = _coords(centre - Vector3.ONE * radius).max(Vector3i.ZERO)
	var hi: Vector3i = _coords(centre + Vector3.ONE * radius).min(_dims - Vector3i.ONE)
	for y: int in range(lo.y, hi.y + 1):
		for z: int in range(lo.z, hi.z + 1):
			for x: int in range(lo.x, hi.x + 1):
				var c := Vector3i(x, y, z)
				var id: int = _flat(c)
				if _open[id] == 0 or id == keep_a or id == keep_b:
					continue
				if _centre_of(c).distance_squared_to(centre) < radius * radius:
					_astar.set_point_disabled(id, true)
					disabled.append(id)
	return disabled


func _coords(pos: Vector3) -> Vector3i:
	var f: Vector3 = (pos - _origin) / _cell
	return Vector3i(floori(f.x), floori(f.y), floori(f.z))


func _inside(c: Vector3i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.z >= 0 and c.x < _dims.x and c.y < _dims.y and c.z < _dims.z


func _flat(c: Vector3i) -> int:
	return c.x + _dims.x * (c.z + _dims.z * c.y)


func _centre_of(c: Vector3i) -> Vector3:
	return _origin + (Vector3(c) + Vector3(0.5, 0.5, 0.5)) * _cell


func _centre(index: int) -> Vector3:
	return _astar.get_point_position(index)
