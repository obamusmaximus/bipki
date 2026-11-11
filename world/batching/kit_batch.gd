class_name KitBatch
extends RefCounted
## Draws the parts of many kit models with few nodes. Every copy of each part is collected
## first; then each part is drawn as one MultiMeshInstance3D per chunk of the ground, so the
## engine can skip whole chunks that are off screen.

var _parent: Node3D
var _chunk_size: float
var _transforms: Dictionary = {}  ## Vector2i(model, part) -> Array[Transform3D]
var _meshes: Dictionary = {}  ## Vector2i(model, part) -> Mesh


func _init(parent: Node3D, chunk_size: float) -> void:
	_parent = parent
	_chunk_size = chunk_size


## Chunk coordinates of the ground cell that contains `point`.
static func chunk_of(point: Vector3, chunk_size: float) -> Vector2i:
	return Vector2i(floori(point.x / chunk_size), floori(point.z / chunk_size))


## Adds one copy of a model. `parts` are its meshes; `root` places the model in the world.
func add_model(model: int, parts: Array[MeshPart], root: Transform3D) -> void:
	for part: int in parts.size():
		var key := Vector2i(model, part)
		if not _transforms.has(key):
			var fresh: Array[Transform3D] = []
			_transforms[key] = fresh
			_meshes[key] = parts[part].mesh
		var list: Array[Transform3D] = _transforms[key]
		list.append(root * parts[part].local_transform)


## Creates the MultiMeshInstance3D nodes. Call once, after every copy has been added.
func flush(label: String) -> void:
	for key: Vector2i in _transforms.keys():
		var by_chunk: Dictionary = {}
		var all: Array[Transform3D] = _transforms[key]
		for xf: Transform3D in all:
			var chunk: Vector2i = chunk_of(xf.origin, _chunk_size)
			if not by_chunk.has(chunk):
				var fresh: Array[Transform3D] = []
				by_chunk[chunk] = fresh
			var list: Array[Transform3D] = by_chunk[chunk]
			list.append(xf)
		for chunk: Vector2i in by_chunk.keys():
			var node_name: String = "%s_%d_%d_%d_%d" % [label, key.x, key.y, chunk.x, chunk.y]
			var chunk_list: Array[Transform3D] = by_chunk[chunk]
			_add_multimesh(node_name, _meshes[key], chunk_list)


func _add_multimesh(node_name: String, mesh: Mesh, list: Array[Transform3D]) -> void:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = list.size()
	for i: int in list.size():
		multi.set_instance_transform(i, list[i])
	var node := MultiMeshInstance3D.new()
	node.name = node_name
	node.multimesh = multi
	_parent.add_child(node)
