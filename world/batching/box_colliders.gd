class_name BoxColliders
extends RefCounted
## Static box colliders on world layer 1, grouped into one StaticBody3D per chunk of the ground.
## Fewer bodies than one per box keeps the node count down in a dense city.

var _parent: Node3D
var _chunk_size: float
var _bodies: Dictionary = {}  ## Vector2i chunk -> StaticBody3D


func _init(parent: Node3D, chunk_size: float) -> void:
	_parent = parent
	_chunk_size = chunk_size


## Adds a box of `size` centred on the origin of `xf`, rotated by its basis.
func add(xf: Transform3D, size: Vector3) -> void:
	var chunk: Vector2i = KitBatch.chunk_of(xf.origin, _chunk_size)
	if not _bodies.has(chunk):
		var body := StaticBody3D.new()
		body.name = "Colliders_%d_%d" % [chunk.x, chunk.y]
		body.collision_layer = 1
		_parent.add_child(body)
		_bodies[chunk] = body
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.transform = xf
	(_bodies[chunk] as StaticBody3D).add_child(shape)
