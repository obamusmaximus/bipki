class_name Pellets
extends Node3D
## The seeker shotgun's pellets in flight (see docs/mechanics/jet.md). Each flies straight for `homing_delay`, then
## turns toward its enemy at up to `turn_rate`. Once its enemy is inside its turning circle (out of reach) it gives up
## and flies straight on; with `brake_into_turns` it slows into the turn instead, then speeds back up to `speed`. One
## whose enemy is gone flies straight on too. A pellet
## that touches the world stops; one that touches an enemy deals `damage` and stops. Each keeps its recent path for its
## tracer (PelletTracers, its child), which fades out after the pellet stops. Game time. Top level, in world space.

const HIT_MASK: int = 1 | 4 # World, Enemy


class Pellet:
	var position: Vector3
	var velocity: Vector3
	var target: Enemy
	var age: float = 0.0
	var flying: bool = true
	## The tracer: recent positions, and the clock time each was passed.
	var trail: PackedVector3Array = PackedVector3Array()
	var trail_times: PackedFloat32Array = PackedFloat32Array()


var stats: SeekerShotgunStats

var _pellets: Array[Pellet] = []
## Game seconds since the start, for the tracers' ages.
var _clock: float = 0.0
var _shape := SphereShape3D.new()

@onready var _tracers: PelletTracers = $Tracers


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY


func setup(shotgun_stats: SeekerShotgunStats) -> void:
	stats = shotgun_stats


func spawn(from: Vector3, velocity: Vector3, target: Enemy) -> void:
	var pellet := Pellet.new()
	pellet.position = from
	pellet.velocity = velocity
	pellet.target = target
	pellet.trail.append(from)
	pellet.trail_times.append(_clock)
	_pellets.append(pellet)


func clear() -> void:
	_pellets.clear()
	_tracers.draw_trails(_pellets, _clock, stats)


func tick(delta: float) -> void:
	_clock += delta
	_shape.radius = stats.pellet_radius
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	for pellet: Pellet in _pellets:
		if pellet.flying:
			_fly(pellet, delta, space)
		_trim_trail(pellet)
	_pellets = _pellets.filter(func(p: Pellet) -> bool: return p.flying or p.trail.size() > 1)
	_tracers.draw_trails(_pellets, _clock, stats)


func _fly(pellet: Pellet, delta: float, space: PhysicsDirectSpaceState3D) -> void:
	pellet.age += delta
	var speed: float = minf(pellet.velocity.length() + stats.speed_recovery * delta, stats.speed)
	var direction: Vector3 = pellet.velocity.normalized()
	if pellet.age >= stats.homing_delay and is_instance_valid(pellet.target) and not pellet.target.health.is_dead():
		direction = _steer(pellet, direction, speed, delta)
		if stats.brake_into_turns and pellet.target != null:
			speed = clampf(minf(speed, _arc_speed(direction, pellet.target.get_center() - pellet.position)),
					stats.speed * stats.min_speed_share, stats.speed)
	pellet.velocity = direction * speed
	var motion: Vector3 = pellet.velocity * delta
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _shape
	query.collision_mask = HIT_MASK
	query.transform = Transform3D(Basis.IDENTITY, pellet.position)
	query.motion = motion
	var fractions: PackedFloat32Array = space.cast_motion(query)
	if fractions[1] >= 1.0:
		pellet.position += motion
	else:
		pellet.position += motion * fractions[1]
		_hit(pellet, space, query)
	if pellet.age >= stats.lifetime:
		pellet.flying = false
	pellet.trail.append(pellet.position)
	pellet.trail_times.append(_clock)


## Turns `direction` toward the pellet's enemy at up to `turn_rate` and returns it. Without `brake_into_turns`, a
## pellet that can no longer reach its enemy at its speed (`_arc_speed`) gives up: it drops the enemy and flies straight
## on until `lifetime`, like a seeker out of fuel.
func _steer(pellet: Pellet, direction: Vector3, speed: float, delta: float) -> Vector3:
	var to_target: Vector3 = pellet.target.get_center() - pellet.position
	if not stats.brake_into_turns and _arc_speed(direction, to_target) < speed:
		pellet.target = null
		return direction
	var angle: float = direction.angle_to(to_target)
	var axis: Vector3 = direction.cross(to_target)
	if angle < 0.0001 or axis.is_zero_approx():
		return direction
	return direction.rotated(axis.normalized(), minf(angle, deg_to_rad(stats.turn_rate) * delta))


## The fastest a pellet heading along `direction` can fly and still turn onto a point `to_target` away. The arc that
## reaches a point `d` away and `angle` off the nose has radius d / (2 sin angle), and flying it at turn_rate takes
## that radius times turn_rate. Past 90 degrees the point needs the tightest turn, so it counts as 90. Faster than this,
## the pellet would circle the point forever.
func _arc_speed(direction: Vector3, to_target: Vector3) -> float:
	var distance: float = to_target.length()
	var angle: float = direction.angle_to(to_target)
	if distance < 0.0001 or angle < 0.0001:
		return INF
	var bend: float = sin(angle) if angle < PI * 0.5 else 1.0
	return deg_to_rad(stats.turn_rate) * distance / (2.0 * bend)


func _hit(pellet: Pellet, space: PhysicsDirectSpaceState3D, query: PhysicsShapeQueryParameters3D) -> void:
	pellet.flying = false
	query.transform = Transform3D(Basis.IDENTITY, pellet.position)
	query.motion = Vector3.ZERO
	var info: Dictionary = space.get_rest_info(query)
	if info.is_empty():
		return
	var enemy: Enemy = instance_from_id(info.collider_id) as Enemy
	if enemy != null:
		enemy.health.take_damage(stats.damage)


## Drops the tracer points older than `tracer_time`, keeping at least the pellet's own point.
func _trim_trail(pellet: Pellet) -> void:
	var cut: int = 0
	while cut < pellet.trail.size() - 1 and _clock - pellet.trail_times[cut] > stats.tracer_time:
		cut += 1
	if cut > 0:
		pellet.trail = pellet.trail.slice(cut)
		pellet.trail_times = pellet.trail_times.slice(cut)
