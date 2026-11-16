class_name SwingRope
extends RefCounted
## The rope a player hangs from while swinging. Its length is fixed at attach and can only shorten:
## by reeling in, or by retracting for ground clearance. It never moves the player itself:
## constrain() returns the correction to apply.

## What the player must do to stay on the rope: move by `offset`, and use `velocity`.
class Correction:
	var offset: Vector3 = Vector3.ZERO
	var velocity: Vector3 = Vector3.ZERO

var length: float = 0.0
## The length at attach, for showing how much rope is left.
var start_length: float = 0.0
var min_length: float = 2.0
var reel_speed: float = 8.0
## Share of the reel's sideways speed gain that is kept (see GrappleStats.reel_momentum_gain).
var reel_gain: float = 1.0
## Reeling adds no sideways speed beyond this (see GrappleStats.reel_momentum_speed_cap).
var reel_speed_cap: float = 1.0e9
## Fastest the rope shortens while the player descends below the hit point (m/s). Slower than
## reeling, so a drop never snaps the rope in.
var descent_speed: float = 6.0
## True when reeling has taken the rope to min_length; the hook should detach.
var fully_reeled: bool = false
## True while reeling is actually shortening the rope (not at min_length). Drives the reel sound.
var is_reeling: bool = false

## How fast the anchor itself is moving (an enemy). The rope holds the player relative to it.
var anchor_velocity: Vector3 = Vector3.ZERO

var _hit_point: Vector3 = Vector3.ZERO
## The rope length the player should have once inside the clearance area under the hit point.
var _clear_length: float = 0.0
## Metres of rope retracted per metre the player descends below the hit point's height.
var _retract_rate: float = 0.0
var _last_y: float = 0.0
## Rope owed to the descent that hasn't been taken up yet. Paced at descent_speed.
var _pending_retract: float = 0.0


## `ground_height` is the terrain y under the hit point, or NAN if there is none (no retraction).
## `margin` is how far below the hit point's height above the ground the rope should end up, and
## `radius` the horizontal radius of the clearance area. The rope should reach its clear length
## at the edge of that area, so the retraction is paced to finish by then, over whatever descent is left.
func start(anchor: Vector3, hit_point: Vector3, ground_height: float, margin: float, radius: float) -> void:
	_hit_point = hit_point
	length = anchor.distance_to(hit_point)
	start_length = length
	_last_y = anchor.y
	_retract_rate = 0.0
	_pending_retract = 0.0
	if is_nan(ground_height):
		return
	_clear_length = maxf(min_length, hit_point.y - ground_height - margin)
	# Depth below the hit point where a rope of the clear length is `radius` away horizontally
	# from the point beneath the hit point (the edge of the clearance area).
	var finish_depth: float = sqrt(maxf(1.0, _clear_length * _clear_length - radius * radius))
	# Attaching below the hit point leaves less descent to spread the retraction over. Already past the edge
	# depth, it is spread over what is left down to the bottom of the clear arc. Attaching at or below that
	# (standing on the ground, far away) leaves nothing to clear, so the rope never retracts.
	var start_depth: float = maxf(0.0, hit_point.y - anchor.y)
	if start_depth >= _clear_length:
		return
	var descent_left: float = maxf(finish_depth, _clear_length) - start_depth
	_retract_rate = maxf(0.0, length - _clear_length) / maxf(1.0, descent_left)


## Moves the anchor (the rope hangs from an enemy). `velocity` is the anchor's own velocity.
func move_anchor(point: Vector3, velocity: Vector3) -> void:
	_hit_point = point
	anchor_velocity = velocity


## `grounded`: the player stands on the floor. The floor holds them up, so the rope doesn't retract for
## ground clearance then (and any retraction still owed from the fall is dropped).
func constrain(anchor: Vector3, velocity: Vector3, reeling: bool, grounded: bool, delta: float) -> Correction:
	is_reeling = reeling and length > min_length
	var length_before: float = length
	if is_reeling:
		length = maxf(min_length, length - reel_speed * delta)
	fully_reeled = reeling and length <= min_length
	_retract_for_descent(anchor.y, grounded)
	# Only the descent is held to the clearance length. Reeling may go on down to min_length.
	if _pending_retract > 0.0:
		var taken: float = minf(_pending_retract, descent_speed * delta)
		_pending_retract -= taken
		length = maxf(_clear_length, length - taken)

	# The rope holds the player relative to the anchor, which may itself be moving.
	var relative: Vector3 = velocity - anchor_velocity
	var correction := Correction.new()
	correction.velocity = velocity
	var offset: Vector3 = anchor - _hit_point
	var distance: float = offset.length()
	if distance < 0.001:
		return correction
	var outward: Vector3 = offset / distance
	# Reeling in while the rope is taut turns the shortening into real momentum, so it carries on
	# after the reel stops or the hook detaches.
	if is_reeling and distance >= length_before - 0.5:
		correction.velocity = _reel_momentum(relative, outward, length_before, length) + anchor_velocity
	if distance <= length:
		return correction

	correction.offset = outward * length - offset
	var outward_speed: float = (correction.velocity - anchor_velocity).dot(outward)
	if outward_speed > 0.0:
		correction.velocity -= outward * outward_speed
	return correction


## Shortening the rope speeds the swing up like a skater pulling in their arms (the sideways speed
## grows by old length / new length), and the player is also pulled toward the hit point at reel speed.
## Both stay in the velocity, so they carry on after the reel stops or the hook detaches.
func _reel_momentum(velocity: Vector3, outward: Vector3, length_before: float, length_after: float) -> Vector3:
	var radial: float = velocity.dot(outward)
	var sideways: Vector3 = velocity - outward * radial
	var before: float = sideways.length()
	var gain: float = 1.0 + (length_before / maxf(length_after, 0.001) - 1.0) * reel_gain
	# The gain stops at the cap. Speed already past the cap is left alone, not cut.
	var after: float = minf(before * gain, maxf(before, reel_speed_cap))
	if before > 0.001:
		sideways *= after / before
	radial = minf(radial, -reel_speed)
	return sideways + outward * radial


## While the player drops below the hit point's height, shortens the rope in proportion to the descent.
func _retract_for_descent(y: float, grounded: bool) -> void:
	if grounded:
		_last_y = y
		_pending_retract = 0.0
		return
	var previous_depth: float = maxf(0.0, _hit_point.y - _last_y)
	var depth: float = maxf(0.0, _hit_point.y - y)
	_last_y = y
	var descended: float = maxf(0.0, depth - previous_depth)
	if descended > 0.0 and _retract_rate > 0.0 and length > _clear_length:
		_pending_retract = minf(_pending_retract + _retract_rate * descended, maxf(0.0, length - _clear_length))
