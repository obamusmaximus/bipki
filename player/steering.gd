class_name Steering
extends RefCounted
## WASD steering in the air and on a swing rope. Pure functions: each takes the velocity and returns the new one.
## With the turn rate on, a fast player's velocity is turned toward the input at a maximum rate (same feel at any
## speed, no energy added). Otherwise, or when slow, WASD adds speed toward the input up to a cap.


## In the air. Without the turn rate (or when slow), WASD only adds speed in the input direction up to
## `air_speed` and never slows the player, so jump momentum is kept.
static func air(velocity: Vector3, direction: Vector3, delta: float, stats: PlayerStats) -> Vector3:
	if direction.is_zero_approx():
		return velocity
	var horizontal := Vector2(velocity.x, velocity.z)
	if stats.air_turn_rate_enabled and horizontal.length() >= stats.air_turn_min_speed:
		var wanted := Vector2(direction.x, direction.z)
		var limit: float = deg_to_rad(stats.air_turn_rate_degrees) * delta
		horizontal = horizontal.rotated(clampf(horizontal.angle_to(wanted), -limit, limit))
		return Vector3(horizontal.x, velocity.y, horizontal.y)
	var along: float = horizontal.dot(Vector2(direction.x, direction.z))
	if along >= stats.air_speed:
		return velocity
	return velocity + direction * minf(stats.air_acceleration * delta, stats.air_speed - along)


## On a swing rope from `anchor`. Only the motion along the rope's tangent is steered, so the rope length is
## untouched. Without the turn rate (or when slow), WASD pushes along the tangent up to `swing_steer_speed`.
static func swing(velocity: Vector3, direction: Vector3, position: Vector3, anchor: Vector3, delta: float,
		stats: PlayerStats) -> Vector3:
	if direction.is_zero_approx():
		return velocity
	var rope: Vector3 = position - anchor
	if rope.is_zero_approx():
		return velocity
	var outward: Vector3 = rope.normalized()
	var tangent: Vector3 = direction - outward * direction.dot(outward)
	if tangent.is_zero_approx():
		return velocity
	tangent = tangent.normalized()
	var sideways: Vector3 = velocity - outward * velocity.dot(outward)
	if stats.swing_turn_rate_enabled and sideways.length() >= stats.swing_turn_min_speed:
		# Turn about the rope, which keeps the motion on the rope's sphere.
		var limit: float = deg_to_rad(stats.swing_turn_rate_degrees) * delta
		var angle: float = sideways.signed_angle_to(tangent, outward)
		return velocity - sideways + sideways.rotated(outward, clampf(angle, -limit, limit))
	var along: float = velocity.dot(tangent)
	if along >= stats.swing_steer_speed:
		return velocity
	return velocity + tangent * minf(stats.swing_steer_acceleration * delta, stats.swing_steer_speed - along)
