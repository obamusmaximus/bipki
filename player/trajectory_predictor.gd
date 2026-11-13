class_name TrajectoryPredictor
extends Node
## Predicts where the player will be over the next second or so if nothing changes: along the rope while
## swinging, a plain arc while flying. Each physics frame it rebuilds `points` (mid-body positions) and
## reports two kinds of hit along that path:
##  - the first hit of the body itself (`hit_*`), where the HUD arc ends, and
##  - the first wall that comes within the assist's clearance (`assist_hit_*`): the path is swept with a wide
##    upright cylinder, so anything closer than `assist_clearance` to either side counts. AvoidanceAssist steers by it.
## It also records which points the camera can see, so the arc can hide where it passes behind a building.
## Child of Player.

const WORLD_MASK: int = 1 # Collision layer 1: World
## The path is traced at this height above the feet (the same mid-body the rope starts from).
const MID_BODY: float = 0.9
## Height of the clearance cylinder (m). Short, so the ground and low roofs don't count as walls.
const CLEARANCE_HEIGHT: float = 1.2
## A point counts as hidden if a building stands this far or more in front of it, seen from the camera (m).
const OCCLUSION_TOLERANCE: float = 0.4

## Mid-body positions, starting at the current one. Empty on the ground (nothing to predict).
var points: PackedVector3Array = PackedVector3Array()
## 1 where the camera can see the point of the same index, 0 where a building is in the way.
var points_visible: PackedByteArray = PackedByteArray()
## Seconds until the body itself hits the world, or -1 if it doesn't within the prediction time.
var hit_time: float = -1.0
var hit_point: Vector3 = Vector3.ZERO
## Surface normal at the hit, pointing out toward the player.
var hit_normal: Vector3 = Vector3.ZERO
## Same for the first wall inside the clearance distance (see above), or -1 if none.
var assist_hit_time: float = -1.0
var assist_hit_point: Vector3 = Vector3.ZERO
var assist_hit_normal: Vector3 = Vector3.ZERO

var stats: PlayerStats

var _body: CharacterBody3D
var _grapple: GrappleHook
var _camera: Camera3D
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _body_shape := SphereShape3D.new()
var _clearance_shape := CylinderShape3D.new()
var _body_query := PhysicsShapeQueryParameters3D.new()
var _clearance_query := PhysicsShapeQueryParameters3D.new()


func setup(body: CharacterBody3D, grapple: GrappleHook, player_stats: PlayerStats, camera: Camera3D) -> void:
	_body = body
	_grapple = grapple
	stats = player_stats
	_camera = camera
	_body_query.shape = _body_shape
	_body_query.collision_mask = WORLD_MASK
	_clearance_query.shape = _clearance_shape
	_clearance_query.collision_mask = WORLD_MASK


func has_hit() -> bool:
	return hit_time >= 0.0


func has_assist_hit() -> bool:
	return assist_hit_time >= 0.0


func _physics_process(_delta: float) -> void:
	points.clear()
	points_visible.clear()
	hit_time = -1.0
	assist_hit_time = -1.0
	if _body == null:
		return
	var swinging: bool = _grapple.is_swinging()
	if _body.is_on_floor() and not swinging:
		return
	_simulate(swinging)
	_mark_visible()


## Steps the player forward in time. While swinging the rope holds the player at its length, which also
## turns the outward speed into sideways swing (the position change becomes the new velocity).
func _simulate(swinging: bool) -> void:
	var space: PhysicsDirectSpaceState3D = _body.get_world_3d().direct_space_state
	var position: Vector3 = _body.global_position + Vector3.UP * MID_BODY
	var velocity: Vector3 = _body.velocity
	var anchor: Vector3 = _grapple.get_swing_anchor()
	var length: float = _grapple.get_rope_length()
	var step: float = maxf(stats.prediction_step, 0.01)
	_body_shape.radius = stats.prediction_probe_radius
	_clearance_shape.radius = stats.assist_clearance
	_clearance_shape.height = CLEARANCE_HEIGHT
	var check_clearance: bool = stats.assist_strength > 0.0
	points.append(position)
	for i: int in int(ceilf(stats.prediction_seconds / step)):
		velocity.y -= _gravity * step
		var next: Vector3 = position + velocity * step
		if swinging:
			var offset: Vector3 = next - anchor
			var distance: float = offset.length()
			if distance > length and distance > 0.001:
				next = anchor + offset / distance * length
			velocity = (next - position) / step
		var motion: Vector3 = next - position

		if check_clearance and assist_hit_time < 0.0:
			var wide: Dictionary = _sweep(space, _clearance_query, position, motion)
			# Walls only: a roof or the ground inside the clearance is not something to steer around.
			if not wide.is_empty() and (wide["normal"] as Vector3).y <= EdgeProbe.TOP_MIN_NORMAL_Y:
				assist_hit_time = (float(i) + float(wide["fraction"])) * step
				assist_hit_point = wide["point"]
				assist_hit_normal = wide["normal"]

		var tight: Dictionary = _sweep(space, _body_query, position, motion)
		if not tight.is_empty():
			points.append(tight["point"])
			hit_time = (float(i) + float(tight["fraction"])) * step
			hit_point = tight["point"]
			hit_normal = tight["normal"]
			return
		position = next
		points.append(position)


## Sweeps `query`'s shape from `from` along `motion`. Returns {fraction, point, normal} for a hit the shape is
## moving into, or an empty dictionary. Sliding along or away from a surface is not a hit.
func _sweep(space: PhysicsDirectSpaceState3D, query: PhysicsShapeQueryParameters3D, from: Vector3, motion: Vector3) -> Dictionary:
	query.transform = Transform3D(Basis.IDENTITY, from)
	query.motion = motion
	var fractions: PackedFloat32Array = space.cast_motion(query)
	if fractions.size() != 2 or fractions[1] >= 1.0:
		return {}
	var contact: Vector3 = from + motion * fractions[1]
	query.transform = Transform3D(Basis.IDENTITY, contact)
	query.motion = Vector3.ZERO
	var rest: Dictionary = space.get_rest_info(query)
	var normal: Vector3 = (rest["normal"] as Vector3).normalized() if not rest.is_empty() else -motion.normalized()
	if normal.dot(motion.normalized()) >= -0.05:
		return {}
	return {"fraction": fractions[1], "point": contact, "normal": normal}


## Marks which points the camera can see, so a path that curves behind a building can be hidden.
func _mark_visible() -> void:
	var space: PhysicsDirectSpaceState3D = _body.get_world_3d().direct_space_state
	var eye: Vector3 = _camera.global_position
	points_visible.resize(points.size())
	for i: int in points.size():
		var distance: float = eye.distance_to(points[i])
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(eye, points[i], WORLD_MASK))
		var blocked: bool = not hit.is_empty() and eye.distance_to(hit["position"]) < distance - OCCLUSION_TOLERANCE
		points_visible[i] = 0 if blocked else 1
