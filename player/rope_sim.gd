class_name RopeSim
extends RefCounted
## A small loose-rope simulation, for the grapple rope's retract. A chain of points pinned to the hand at one
## end; the other end is pulled back to the hand by an underdamped spring while the rope's usable length
## shrinks at a limited speed. The extra length goes slack and whips about, then settles at the hand. Visual only.

var points: PackedVector3Array = PackedVector3Array()
## Seconds the sim has run.
var age: float = 0.0

var _velocities: PackedVector3Array = PackedVector3Array()
var _predicted: PackedVector3Array = PackedVector3Array()
## The rope's current usable length (m). It shrinks toward the distance between the ends.
var _length: float = 0.0
var _count: int = 0


## Lays the rope straight from `hand` to `end` with `segments` segments and gives it a sideways kick of `whip` m/s,
## strongest in the middle.
func begin(hand: Vector3, end: Vector3, segments: int, whip: float) -> void:
	_count = maxi(segments, 2)
	points.resize(_count + 1)
	_velocities.resize(_count + 1)
	_predicted.resize(_count + 1)
	_length = hand.distance_to(end)
	age = 0.0
	var along: Vector3 = (end - hand).normalized() if not hand.is_equal_approx(end) else Vector3.FORWARD
	var helper: Vector3 = Vector3.RIGHT if absf(along.y) > 0.99 else Vector3.UP
	var side: Vector3 = along.cross(helper).normalized()
	var kick: Vector3 = side.rotated(along, randf() * TAU) * whip
	for i: int in _count + 1:
		var t: float = float(i) / float(_count)
		points[i] = hand.lerp(end, t)
		_velocities[i] = kick * sin(PI * t)


## Moves the rope on by `dt` seconds with its start at `hand`.
func step(dt: float, hand: Vector3, stiffness: float, damping: float, shrink_speed: float, gravity: float) -> void:
	age += dt
	var last: int = _count
	points[0] = hand
	_velocities[0] = Vector3.ZERO
	# The loose end is a damped spring toward the hand.
	_velocities[last] += ((hand - points[last]) * stiffness - _velocities[last] * damping) * dt
	for i: int in range(1, last):
		_velocities[i] += Vector3.DOWN * gravity * dt
		_velocities[i] *= exp(-1.5 * dt)
	for i: int in range(1, last + 1):
		_predicted[i] = points[i] + _velocities[i] * dt
	_predicted[0] = hand
	# The usable length shrinks toward the span between the ends, but only so fast.
	_length = move_toward(_length, maxf(points[last].distance_to(hand), 0.5), shrink_speed * dt)
	var rest: float = _length / float(_count)
	for _iteration: int in 6:
		for i: int in last:
			var offset: Vector3 = _predicted[i + 1] - _predicted[i]
			var distance: float = offset.length()
			if distance <= rest or distance < 0.0001:
				continue
			var correction: Vector3 = offset * ((distance - rest) / distance)
			if i == 0:
				_predicted[i + 1] -= correction
			else:
				_predicted[i] += correction * 0.5
				_predicted[i + 1] -= correction * 0.5
	for i: int in range(1, last + 1):
		_velocities[i] = (_predicted[i] - points[i]) / dt
		points[i] = _predicted[i]


## The loose end's position and speed, for deciding when the rope has settled.
func get_end() -> Vector3:
	return points[_count]


func get_end_speed() -> float:
	return _velocities[_count].length()
