class_name AvoidanceAssist
extends Node
## Steers the player away from buildings so they pass at least `assist_clearance` from a wall on either side.
## Reads TrajectoryPredictor's first predicted wall within that clearance and returns a sideways acceleration
## sized to get the player clear of it in the time left (a = 2 * distance / time^2, capped by assist_max_accel),
## so it is a firm nudge, not a drift. It never reacts to roofs (landing on one is wanted), nor to the surface
## right where the hook is attached (swinging up to that face is deliberate), and it stays out of the way while the
## player steers into the surface on purpose. If a roof edge is within reach it lifts the player over it instead
## of sideways. Child of Player.

const WORLD_MASK: int = 1 # Collision layer 1: World

var stats: PlayerStats

var _body: CharacterBody3D
var _grapple: GrappleHook
var _predictor: TrajectoryPredictor


func setup(body: CharacterBody3D, grapple: GrappleHook, predictor: TrajectoryPredictor, player_stats: PlayerStats) -> void:
	_body = body
	_grapple = grapple
	_predictor = predictor
	stats = player_stats


## The acceleration (m/s per second) to add this frame. `input_direction` is the player's WASD direction
## in world space, so the assist can back off when the player is already steering clear.
func get_acceleration(input_direction: Vector3) -> Vector3:
	if stats.assist_strength <= 0.0 or not _predictor.has_assist_hit():
		return Vector3.ZERO
	var velocity: Vector3 = _body.velocity
	var look: float = minf(stats.assist_lookahead, stats.prediction_seconds)
	var time_left: float = _predictor.assist_hit_time
	if velocity.length() < stats.assist_min_speed or time_left > look:
		return Vector3.ZERO
	# Close to the hook's own attach point: swinging up to that face is deliberate.
	if _grapple.is_swinging() and _predictor.assist_hit_point.distance_to(_grapple.get_hit_point()) < stats.assist_anchor_radius:
		return Vector3.ZERO

	var normal: Vector3 = _predictor.assist_hit_normal
	var heading: Vector3 = Vector3(velocity.x, 0.0, velocity.z).normalized()
	var flat_normal: Vector3 = Vector3(normal.x, 0.0, normal.z)
	var lateral: Vector3 = flat_normal - heading * flat_normal.dot(heading)
	if lateral.length() < 0.2:
		lateral = _free_side(heading)
	lateral = lateral.normalized()
	# Steering into the surface on purpose (to wall run along it, say): leave the player to it.
	if input_direction.dot(lateral) < -0.3:
		return Vector3.ZERO

	# Moving sideways by the clearance within the time left needs a = 2d / t^2.
	var needed: float = 2.0 * stats.assist_clearance / maxf(time_left * time_left, 0.0025)
	var push: float = minf(needed, stats.assist_max_accel) * stats.assist_strength
	var accel: Vector3 = lateral * push
	if stats.assist_lift_strength > 0.0 and _roof_edge_within_reach():
		accel *= 0.4
		accel += Vector3.UP * push * stats.assist_lift_strength
	# The more the player steers the same way, the less the assist adds.
	var agreement: float = clampf(input_direction.dot(lateral), 0.0, 1.0)
	return accel * (1.0 - stats.assist_input_yield * agreement)


## For a head-on approach there is no obvious side: pick the one with more open space ahead.
func _free_side(heading: Vector3) -> Vector3:
	var right: Vector3 = heading.cross(Vector3.UP).normalized()
	var space: PhysicsDirectSpaceState3D = _body.get_world_3d().direct_space_state
	var origin: Vector3 = _body.global_position + Vector3.UP * TrajectoryPredictor.MID_BODY
	var reach: float = maxf(_body.velocity.length() * stats.assist_lookahead, 4.0)
	var best: Vector3 = right
	var best_free: float = -1.0
	for side: float in [1.0, -1.0]:
		var from: Vector3 = origin + right * side * stats.assist_clearance
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + heading * reach, WORLD_MASK))
		var free: float = reach if hit.is_empty() else from.distance_to(hit["position"])
		if free > best_free:
			best_free = free
			best = right * side
	return best


## True if the wall about to be passed has a roof edge no more than `assist_lift_height` above the hit.
func _roof_edge_within_reach() -> bool:
	var space: PhysicsDirectSpaceState3D = _body.get_world_3d().direct_space_state
	# The hit is where the clearance cylinder touches, `assist_clearance` out from the wall: step back into the wall.
	var inside: Vector3 = _predictor.assist_hit_point - _predictor.assist_hit_normal * (stats.assist_clearance + 0.5)
	var from: Vector3 = inside + Vector3.UP * stats.assist_lift_height
	var query := PhysicsRayQueryParameters3D.create(from, inside + Vector3.DOWN * 0.5, WORLD_MASK)
	var hit: Dictionary = space.intersect_ray(query)
	return not hit.is_empty() and (hit["normal"] as Vector3).y > EdgeProbe.TOP_MIN_NORMAL_Y
