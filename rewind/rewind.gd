class_name Rewind
extends Node
## Sets the level back `rewind_seconds` of game time: the player, the enemies and anything else that takes part.
## One per level, owned by the level, which calls `rewind()` when the player dies with a life left.
##
## It keeps a ring buffer of snapshots, one every `snapshot_interval`, and only as many as the rewind needs, so the
## memory is bounded whatever the level's size and the cost is one pass over the rewindable nodes per snapshot.
##
## Taking part: a node joins GROUP and has two methods.
##  - `rewind_capture() -> Dictionary`: its state now, as plain values (no node references; use rewind ids, see `find()`).
##  - `rewind_restore(state: Dictionary, rewind: Rewind) -> void`: puts that state back. Called after every node of the
##    snapshot exists again, so `rewind.find(id)` resolves any of them. No signals that mean "this happened" (a death,
##    a launch) should fire from it: a rewind is not an event in the world.
## A node that can be freed and made again (an enemy) also joins RECREATE_GROUP. If it is gone when its snapshot is
## restored, it is instanced again from its scene, under its old parent, with the properties of its optional
## `rewind_recipe() -> Dictionary` set first, and `recreated` lets the level wire it like a fresh spawn. One that did
## not exist yet in the snapshot is removed.

## A node that had been freed is back in the tree. The level wires it like a fresh spawn; its state is restored next.
signal recreated(node: Node)

const GROUP: StringName = &"rewindable"
const RECREATE_GROUP: StringName = &"rewind_recreate"
const ID_META: StringName = &"rewind_id"
const ORIGIN_META: StringName = &"rewind_origin"


## How to make a node again: its scene, where it hung, and properties to set before it enters the tree.
class Origin:
	var scene_path: String
	var parent_path: NodePath
	var recipe: Dictionary


@export var stats: RewindStats

var _snapshots: Array[RewindSnapshot] = []
## Game time (s). Set back on a rewind, so the timeline rewinds with the world.
var _clock: float = 0.0
var _since_capture: float = 0.0
var _next_id: int = 1
## True from `rewind()` until the restore has run at the end of the frame.
var _pending: bool = false
## Id to node while a restore runs, for `find()`.
var _live: Dictionary[int, Node] = {}
var _scenes: Dictionary[String, PackedScene] = {}


func _ready() -> void:
	# Last in the physics order, so a snapshot sees the frame's finished moves.
	process_physics_priority = 1000


func _physics_process(delta: float) -> void:
	if _pending:
		return
	_clock += delta
	_since_capture += delta
	if _snapshots.is_empty() or _since_capture >= stats.snapshot_interval:
		_capture()


## Sets the level back. Runs at the end of the frame, outside any node's physics step, so nodes can be freed and
## made safely. A second call before then is ignored.
func rewind() -> void:
	if _pending or _snapshots.is_empty():
		return
	_pending = true
	_restore.call_deferred()


## The node with rewind id `id` while a restore runs, or null.
func find(id: int) -> Node:
	return _live.get(id, null)


## Every rewindable node's state now. Ids are handed out first, so a state can name any other node.
func _capture() -> void:
	_since_capture = 0.0
	var nodes: Array[Node] = _rewindable_nodes()
	for node: Node in nodes:
		if not node.has_meta(ID_META):
			_assign_id(node)
	var snapshot := RewindSnapshot.new()
	snapshot.time = _clock
	for node: Node in nodes:
		var id: int = node.get_meta(ID_META)
		snapshot.states[id] = node.call(&"rewind_capture")
		if node.has_meta(ORIGIN_META):
			snapshot.origins[id] = node.get_meta(ORIGIN_META)
	_snapshots.append(snapshot)
	# Keep only one snapshot at least `rewind_seconds` old: the one a rewind now would use.
	while _snapshots.size() > 1 and _snapshots[1].time <= _clock - stats.rewind_seconds:
		_snapshots.pop_front()


func _rewindable_nodes() -> Array[Node]:
	var nodes: Array[Node] = []
	for node: Node in get_tree().get_nodes_in_group(GROUP):
		# A node freeing itself this frame (an enemy that just died) is already gone from the world.
		if not node.is_queued_for_deletion():
			nodes.append(node)
	return nodes


func _assign_id(node: Node) -> void:
	node.set_meta(ID_META, _next_id)
	_next_id += 1
	if node.is_in_group(RECREATE_GROUP) and not node.has_meta(ORIGIN_META):
		var origin := Origin.new()
		origin.scene_path = node.scene_file_path
		origin.parent_path = node.get_parent().get_path()
		origin.recipe = node.call(&"rewind_recipe") if node.has_method(&"rewind_recipe") else {}
		node.set_meta(ORIGIN_META, origin)


## The newest snapshot at least `rewind_seconds` old (or the oldest, early in the level). Newer ones are the undone
## future and are dropped; the clock goes back to the snapshot's time.
func _restore() -> void:
	_pending = false
	var snapshot: RewindSnapshot = _snapshots[0]
	_snapshots = [snapshot]
	_clock = snapshot.time
	_since_capture = 0.0

	_live.clear()
	var gone: Array[Node] = []
	for node: Node in _rewindable_nodes():
		var id: int = node.get_meta(ID_META, 0)
		if snapshot.states.has(id):
			_live[id] = node
		elif node.is_in_group(RECREATE_GROUP):
			gone.append(node) # Didn't exist then.
	# Last child first: taking a child off the end of its parent's list is cheap, from the middle it shifts the rest.
	gone.sort_custom(func(a: Node, b: Node) -> bool: return a.get_index() > b.get_index())
	for node: Node in gone:
		_remove(node)
	for id: int in snapshot.states:
		if not _live.has(id) and snapshot.origins.has(id):
			var made: Node = _recreate(id, snapshot.origins[id])
			if made != null:
				_live[id] = made
	for id: int in _live:
		_live[id].call(&"rewind_restore", snapshot.states[id], self)
	_live.clear()


## Out of the tree at once (so groups and searches stop seeing it this frame), then freed. No death: it never happened.
func _remove(node: Node) -> void:
	node.get_parent().remove_child(node)
	node.queue_free()


func _recreate(id: int, origin: Origin) -> Node:
	var parent: Node = get_node_or_null(origin.parent_path)
	if parent == null or origin.scene_path.is_empty():
		return null
	if not _scenes.has(origin.scene_path):
		_scenes[origin.scene_path] = load(origin.scene_path) as PackedScene
	var scene: PackedScene = _scenes[origin.scene_path]
	if scene == null:
		return null
	var node: Node = scene.instantiate()
	for property: StringName in origin.recipe:
		node.set(property, origin.recipe[property])
	node.set_meta(ID_META, id)
	node.set_meta(ORIGIN_META, origin)
	parent.add_child(node)
	recreated.emit(node)
	return node
