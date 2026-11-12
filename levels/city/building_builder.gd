class_name BuildingBuilder
extends RefCounted
## Turns the building sites of a plan into batched meshes and box colliders.


static func build(parent: Node3D, plan: CityPlan, chunk_size: float) -> void:
	var batch := KitBatch.new(parent, chunk_size)
	var colliders := BoxColliders.new(parent, chunk_size)
	var metres: float = BuildingCatalog.METRES_PER_UNIT
	for site: CityPlan.Site in plan.sites:
		var box: AABB = BuildingCatalog.bounds(site.model)
		var turn := Basis(Vector3.UP, site.quarter_turns * PI * 0.5)
		var scale := Vector3(metres, metres * site.height_scale, metres)
		var size: Vector3 = Vector3(box.size.x, box.size.y * site.height_scale, box.size.z) * metres
		var centre: Vector3 = box.get_center()
		centre.y = box.position.y

		# Model space -> centre the footprint on the origin, scale, turn, then move to the lot.
		var placed := Transform3D(turn * Basis.from_scale(scale), site.position)
		batch.add_model(site.model, BuildingCatalog.parts(site.model), placed * Transform3D(Basis.IDENTITY, -centre))
		colliders.add(Transform3D(turn, site.position + Vector3.UP * size.y * 0.5), size)
	batch.flush("Building")
