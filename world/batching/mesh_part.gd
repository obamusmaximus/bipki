class_name MeshPart
extends RefCounted
## One mesh of an imported kit model, with its transform relative to the model's root.
## Kit models are made of several meshes, so each one is batched on its own.

static var _cache: Dictionary = {}

var mesh: Mesh
var local_transform: Transform3D


func _init(new_mesh: Mesh, new_transform: Transform3D) -> void:
	mesh = new_mesh
	local_transform = new_transform


## The meshes of the scene at `path`, read once and cached.
static func from_scene(path: String) -> Array[MeshPart]:
	if not _cache.has(path):
		var root := (load(path) as PackedScene).instantiate() as Node3D
		var parts: Array[MeshPart] = []
		_collect(root, Transform3D.IDENTITY, parts)
		root.free()
		_cache[path] = parts
	return _cache[path]


## Box that holds all the parts, in model space.
static func bounds(parts: Array[MeshPart]) -> AABB:
	var box := AABB()
	var first: bool = true
	for part: MeshPart in parts:
		var part_box: AABB = part.local_transform * part.mesh.get_aabb()
		box = part_box if first else box.merge(part_box)
		first = false
	return box


static func _collect(node: Node, xf: Transform3D, out: Array[MeshPart]) -> void:
	if node is MeshInstance3D:
		out.append(MeshPart.new((node as MeshInstance3D).mesh, xf))
	for child: Node in node.get_children():
		if child is Node3D:
			_collect(child, xf * (child as Node3D).transform, out)
