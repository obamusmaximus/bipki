class_name Pellets
extends Node3D
## The seeker shotgun's pellets in flight (see docs/mechanics/jet.md). Each flies straight for `homing_delay`, then
## turns toward its enemy at up to `turn_rate`. When its enemy is inside its turning circle it brakes into the turn
## (`_steer`), then speeds back up to `speed`. One whose enemy is gone flies straight on. A pellet
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
	if pellet.age >= stats.homing_delay and is_instance_valid(pellet.target) and not pellet.target.health.is_dead():
		pellet.velocity = _steer(pellet.velocity.normalized(), speed, pellet.target.get_center() - pellet.position, delta)
	else:
		pellet.velocity = pellet.velocity.normalized() * speed
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


## Turns `direction` toward the enemy at up to `turn_rate` and returns the new velocity. The arc that reaches a point
## `d` away and `angle` off the nose has radius d / (2 sin angle), so flying it at `speed` takes a turn rate of
## 2 speed sin(angle) / d. Where that is more than `turn_rate` the pellet would circle the enemy forever, so it slows
## to the speed that makes the arc. An enemy behind (past 90 degrees) asks for the tightest turn.
func _steer(direction: Vector3, speed: float, to_target: Vector3, delta: float) -> Vector3:
	var distance: float = to_target.length()
	if distance < 0.0001:
		return direction * speed
	var wanted: Vector3 = to_target / distance
	var angle: float = direction.angle_to(wanted)
	var axis: Vector3 = direction.cross(wanted)
	if angle < 0.0001 or axis.is_zero_approx():
		return direction * speed
	var max_turn: float = deg_to_rad(stats.turn_rate)
	var bend: float = sin(angle) if angle < PI * 0.5 else 1.0
	var arc_speed: float = max_turn * distance / (2.0 * bend)
	speed = clampf(minf(speed, arc_speed), stats.speed * stats.min_speed_share, stats.speed)
	return direction.rotated(axis.normalized(), minf(angle, max_turn * delta)) * speed


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
