class_name RoadBuilder
extends RefCounted
## Lays the street grid out of Roads-kit tiles. Each crossing gets one tile. Each stretch between
## two crossings gets a row of straight tiles, stretched a few percent so they meet exactly.
## Every road cell also gets a box collider, so the player stands on the road surface.

const TILE: float = BuildingCatalog.METRES_PER_UNIT


static func build(parent: Node3D, plan: CityPlan, chunk_size: float) -> void:
	var batch := KitBatch.new(parent, chunk_size)
	var colliders := BoxColliders.new(parent, chunk_size)
	var coords: PackedFloat32Array = plan.street_coords
	var last: int = coords.size() - 1
	var height: float = MeshPart.bounds(RoadTiles.parts(0)).size.y * TILE

	for i: int in coords.size():
		for j: int in coords.size():
			var open: int = 0
			if i > 0:
				open |= RoadTiles.WEST
			if i < last:
				open |= RoadTiles.EAST
			if j > 0:
				open |= RoadTiles.NORTH
			if j < last:
				open |= RoadTiles.SOUTH
			var centre := Vector3(coords[i], 0.0, coords[j])
			_place_tile(batch, open, centre, Vector3.ONE)
			_collide(colliders, centre, Vector3(TILE, height, TILE))

	for i: int in last:
		for j: int in coords.size():
			_segment(batch, colliders, Vector3(coords[i], 0.0, coords[j]), Vector3(coords[i + 1], 0.0, coords[j]), height)
	for j: int in last:
		for i: int in coords.size():
			_segment(batch, colliders, Vector3(coords[i], 0.0, coords[j]), Vector3(coords[i], 0.0, coords[j + 1]), height)

	batch.flush("Road")


## Fills the stretch from crossing centre `a` to crossing centre `b` with straight tiles.
static func _segment(batch: KitBatch, colliders: BoxColliders, a: Vector3, b: Vector3, height: float) -> void:
	var along: Vector3 = (b - a).normalized()
	var on_x: bool = absf(along.x) > 0.5
	var span: float = a.distance_to(b) - TILE
	var count: int = maxi(1, roundi(span / TILE))
	var length: float = span / count
	var stretch: float = length / TILE
	var open: int = (RoadTiles.WEST | RoadTiles.EAST) if on_x else (RoadTiles.NORTH | RoadTiles.SOUTH)
	var stretch_vec := Vector3(stretch, 1.0, 1.0) if on_x else Vector3(1.0, 1.0, stretch)

	var start: Vector3 = a + along * (TILE * 0.5)
	for k: int in count:
		_place_tile(batch, open, start + along * (length * (k + 0.5)), stretch_vec)

	var size := Vector3(span, height, TILE) if on_x else Vector3(TILE, height, span)
	_collide(colliders, (a + b) * 0.5, size)


## A box from the ground up to the road surface. `centre` is on the ground.
static func _collide(colliders: BoxColliders, centre: Vector3, size: Vector3) -> void:
	colliders.add(Transform3D(Basis.IDENTITY, centre + Vector3.UP * size.y * 0.5), size)


## Places one tile. `stretch` is a multiplier on the tile's own size (1 = one tile).
static func _place_tile(batch: KitBatch, open: int, centre: Vector3, stretch: Vector3) -> void:
	var found: Vector2i = RoadTiles.find(open)
	if found.x < 0:
		push_warning("No road tile opens sides %d" % open)
		return
	var scale := Vector3(TILE * stretch.x, TILE * stretch.y, TILE * stretch.z)
	var root := Transform3D(Basis.from_scale(scale) * Basis(Vector3.UP, found.y * PI * 0.5), centre)
	batch.add_model(found.x, RoadTiles.parts(found.x), root)
