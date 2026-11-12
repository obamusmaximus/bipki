class_name CityPlan
extends RefCounted
## What `CityLayout` decided: the street grid and where each building goes. Plain data.

## One building on one lot.
class Site extends RefCounted:
	var position: Vector3
	var quarter_turns: int
	var model: int
	var height_scale: float

	## The building's solid box in world space (the same box the collider uses).
	func world_box() -> AABB:
		var box: AABB = BuildingCatalog.bounds(model)
		var size := Vector3(box.size.x, box.size.y * height_scale, box.size.z) * BuildingCatalog.METRES_PER_UNIT
		if quarter_turns % 2 != 0:
			size = Vector3(size.z, size.y, size.x)
		return AABB(position + Vector3(-size.x * 0.5, 0.0, -size.z * 0.5), size)

## Distance from one street to the next.
var pitch: float = 0.0
## Street centrelines. The same on both axes, so streets form a square grid.
var street_coords: PackedFloat32Array = PackedFloat32Array()
var sites: Array[Site] = []
