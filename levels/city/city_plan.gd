class_name CityPlan
extends RefCounted
## What `CityLayout` decided: the street grid and where each building goes. Plain data.

## One building on one lot.
class Site extends RefCounted:
	var position: Vector3
	var quarter_turns: int
	var model: int
	var height_scale: float

## Distance from one street to the next.
var pitch: float = 0.0
## Street centrelines. The same on both axes, so streets form a square grid.
var street_coords: PackedFloat32Array = PackedFloat32Array()
var sites: Array[Site] = []
