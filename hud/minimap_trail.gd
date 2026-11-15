class_name MinimapTrail
extends RefCounted
## The player's recent path for the minimap: world positions with the time each was recorded. Old points
## are pruned once they pass the trail's lifetime, so the trail dissipates. Plain data, no nodes.

var positions: PackedVector3Array = PackedVector3Array()
var times: PackedFloat32Array = PackedFloat32Array()


## Records a point, unless it is within `min_distance` of the last one.
func add(position: Vector3, time: float, min_distance: float = 0.25) -> void:
	if not positions.is_empty() and positions[positions.size() - 1].distance_to(position) < min_distance:
		return
	positions.append(position)
	times.append(time)


## Drops points older than `lifetime` seconds.
func prune(now: float, lifetime: float) -> void:
	var keep_from: int = 0
	while keep_from < times.size() and now - times[keep_from] > lifetime:
		keep_from += 1
	if keep_from > 0:
		positions = positions.slice(keep_from)
		times = times.slice(keep_from)


func size() -> int:
	return positions.size()


func clear() -> void:
	positions.clear()
	times.clear()
