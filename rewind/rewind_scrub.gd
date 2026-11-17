class_name RewindScrub
extends RefCounted
## Poses the level at any time inside the snapshots while a rewind plays back: each node in two neighbouring snapshots
## gets `rewind_pose(from, to, weight, span)`, and a node that can be freed or spawned is shown only while it existed.
## Nothing is simulated: the tree is paused and this only moves things. `Rewind` makes it and restores for real after.
##
## Taking part: a rewindable node that moves implements `rewind_pose`. `transform_between` does the usual case from the
## `transform` and `velocity` a capture holds. A node without it holds still during the playback.

var _snapshots: Array[RewindSnapshot]
var _live: Dictionary[int, Node]
## Game time each node first and last appears in the snapshots.
var _first: Dictionary[int, float] = {}
var _last: Dictionary[int, float] = {}
## Index of the older snapshot of the pair the last pose used. Searching starts from it (the playhead only moves back).
var _cursor: int = 0


## `snapshots` oldest first; `live` every node any of them holds, by rewind id (remade ones included).
func _init(snapshots: Array[RewindSnapshot], live: Dictionary[int, Node]) -> void:
	_snapshots = snapshots
	_live = live
	_cursor = maxi(_snapshots.size() - 2, 0)
	for snapshot: RewindSnapshot in _snapshots:
		for id: int in snapshot.states:
			if not _first.has(id):
				_first[id] = snapshot.time
			_last[id] = snapshot.time


## Poses everything at game time `time` (between the oldest and newest snapshot).
func pose_at(time: float) -> void:
	if _snapshots.is_empty():
		return
	_seek(time)
	var a: RewindSnapshot = _snapshots[_cursor]
	var b: RewindSnapshot = _snapshots[mini(_cursor + 1, _snapshots.size() - 1)]
	var span: float = b.time - a.time
	var weight: float = clampf((time - a.time) / span, 0.0, 1.0) if span > 0.0 else 0.0
	for id: int in _live:
		var node: Node = _live[id]
		if not is_instance_valid(node):
			continue
		var there: bool = time >= _first[id] - 0.0001 and time <= _last[id] + 0.0001
		if node.is_in_group(Rewind.RECREATE_GROUP) and node is Node3D:
			(node as Node3D).visible = there
		if not there or not node.has_method(&"rewind_pose"):
			continue
		var from: Dictionary = a.states.get(id, b.states.get(id, {}))
		var to: Dictionary = b.states.get(id, from)
		if from.is_empty():
			continue
		node.call(&"rewind_pose", from, to, weight if a.states.has(id) and b.states.has(id) else 0.0, span)


## Shows everything the playback hid. Called before the real restore.
func finish() -> void:
	for id: int in _live:
		var node: Node = _live[id]
		if is_instance_valid(node) and node is Node3D:
			(node as Node3D).visible = true


func _seek(time: float) -> void:
	while _cursor > 0 and _snapshots[_cursor].time > time:
		_cursor -= 1
	while _cursor < _snapshots.size() - 2 and _snapshots[_cursor + 1].time < time:
		_cursor += 1


## The transform between two captured states holding `transform` and `velocity`. The position follows a curve that
## leaves and arrives with the captured velocities (a cubic Hermite), so a swing between two snapshots stays an arc
## rather than a straight cut. Each velocity is capped against the straight distance, so a stop against a wall
## between snapshots doesn't bulge the path. Rotation turns evenly.
static func transform_between(from: Dictionary, to: Dictionary, weight: float, span: float) -> Transform3D:
	var a: Transform3D = from[&"transform"]
	var b: Transform3D = to[&"transform"]
	if weight <= 0.0:
		return a
	var chord: float = a.origin.distance_to(b.origin)
	var tangent_a: Vector3 = (from.get(&"velocity", Vector3.ZERO) as Vector3) * span
	var tangent_b: Vector3 = (to.get(&"velocity", Vector3.ZERO) as Vector3) * span
	tangent_a = tangent_a.limit_length(chord * 2.0)
	tangent_b = tangent_b.limit_length(chord * 2.0)
	var t: float = weight
	var t2: float = t * t
	var t3: float = t2 * t
	var origin: Vector3 = a.origin * (2.0 * t3 - 3.0 * t2 + 1.0) + tangent_a * (t3 - 2.0 * t2 + t) \
			+ b.origin * (-2.0 * t3 + 3.0 * t2) + tangent_b * (t3 - t2)
	var rotation: Quaternion = a.basis.get_rotation_quaternion().slerp(b.basis.get_rotation_quaternion(), t)
	return Transform3D(Basis(rotation).scaled(a.basis.get_scale()), origin)
