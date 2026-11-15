class_name ThrowPreview
extends RefCounted
## Predicts where a thrown enemy goes: steps a sphere along a nearly straight line (with its small gravity),
## sweeping it against the world and against other enemies, and reports the first thing it hits and the
## speed it would hit at. HUD and throw read it every frame while a throw is being aimed.

## What a trace found. `points` always starts at the start position.
class Result:
	var points: PackedVector3Array = PackedVector3Array()
	var hit: bool = false
	var hit_point: Vector3 = Vector3.ZERO
	var hit_normal: Vector3 = Vector3.UP
	## Speed into the surface at the hit (m/s, along the normal).
	var hit_speed: float = 0.0
	## The enemy that would be hit, or null if it is the world.
	var hit_enemy: Enemy = null

const WORLD_MASK: int = 1 # Collision layer 1: World
const ENEMY_MASK: int = 4 # Collision layer 3: Enemy (bit value)

var _shape := SphereShape3D.new()
var _query := PhysicsShapeQueryParameters3D.new()


func _init() -> void:
	_query.shape = _shape
	_query.collision_mask = WORLD_MASK | ENEMY_MASK


## Traces a flight from `start` with `velocity`. `gravity` is the downward acceleration (m/s squared), `radius` the
## flying body's radius, and `exclude` bodies that don't count (the thrown enemy itself).
func trace(space: PhysicsDirectSpaceState3D, start: Vector3, velocity: Vector3, gravity: float,
		radius: float, exclude: Array[RID], step: float, seconds: float) -> Result:
	var result := Result.new()
	_shape.radius = radius
	_query.exclude = exclude
	var position: Vector3 = start
	var current: Vector3 = velocity
	result.points.append(position)
	step = maxf(step, 0.005)
	for i: int in int(ceilf(seconds / step)):
		current.y -= gravity * step
		var motion: Vector3 = current * step
		var contact: Dictionary = _sweep(space, position, motion)
		if not contact.is_empty():
			result.points.append(contact["point"])
			result.hit = true
			result.hit_point = contact["point"]
			result.hit_normal = contact["normal"]
			result.hit_speed = maxf(-current.dot(result.hit_normal), 0.0)
			result.hit_enemy = contact["enemy"]
			return result
		position += motion
		result.points.append(position)
	return result


## Sweeps the sphere from `from` along `motion`. Returns {point, normal, enemy} for a hit it is moving into, or {}.
func _sweep(space: PhysicsDirectSpaceState3D, from: Vector3, motion: Vector3) -> Dictionary:
	_query.transform = Transform3D(Basis.IDENTITY, from)
	_query.motion = motion
	var fractions: PackedFloat32Array = space.cast_motion(_query)
	if fractions.size() != 2 or fractions[1] >= 1.0:
		return {}
	var contact: Vector3 = from + motion * fractions[1]
	_query.transform = Transform3D(Basis.IDENTITY, contact)
	_query.motion = Vector3.ZERO
	var rest: Dictionary = space.get_rest_info(_query)
	var normal: Vector3 = (rest["normal"] as Vector3).normalized() if not rest.is_empty() else -motion.normalized()
	if normal.dot(motion.normalized()) >= -0.05:
		return {}
	var enemy: Enemy = null
	if not rest.is_empty():
		enemy = instance_from_id(rest["collider_id"]) as Enemy
	return {"point": contact, "normal": normal, "enemy": enemy}
