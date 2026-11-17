class_name Enemy
extends CharacterBody3D
## Base for everything the player can hook, pull on and throw. It owns the states an enemy goes through
## when the grapple takes hold of it, and the physics of a thrown enemy: a thrown enemy flies on a nearly
## straight line, and when it hits a surface it takes damage in proportion to the speed it hit at (the part
## of its velocity into the surface). A subclass supplies its own behaviour in `_ai_step` and reacts to
## state changes in `_on_state_changed`.
## It takes part in a rewind (see `Rewind`): a subclass adds its own parts in `_capture_ai` and `_restore_ai`.
## Signals up: the grapple and the HUD listen; nothing here knows about the player.

## Emitted when a thrown enemy hits something. `speed` is the impact speed along the surface normal.
signal impacted(speed: float, point: Vector3)
signal state_changed(new_state: State)
## Emitted when the enemy takes damage. `point` is where (its centre), `killed` is true for the hit that destroys it.
signal damaged(amount: float, point: Vector3, killed: bool)
## Emitted once, just before the enemy is freed.
signal died

## NORMAL: the enemy's own behaviour. GRABBED: held by the throw, not moving. THROWN: flying free.
## STUNNED: survived a throw and is falling, hookable, until `stun_time` runs out.
enum State { NORMAL, GRABBED, THROWN, STUNNED }

const GROUP: StringName = &"enemies"

## Tunable numbers. A subclass narrows the type (DroneStats).
@export var stats: EnemyStats

var state: State = State.NORMAL

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _flight_time: float = 0.0
var _stun_left: float = 0.0
## True while flying from a melee hit (a knockback) rather than a throw.
var _knocked: bool = false
## Distance a knockback may still fly before the enemy regains control (m).
var _knock_left: float = 0.0

@onready var health: Health = $Health


## Joins the group on entering the tree, which is before any node's `_ready`, so the HUD and the level
## find every enemy that is in the scene from the start.
func _enter_tree() -> void:
	add_to_group(GROUP)
	add_to_group(Rewind.GROUP)
	add_to_group(Rewind.RECREATE_GROUP)


func _ready() -> void:
	health.setup(stats.max_health)
	health.died.connect(_die)
	health.damaged.connect(_on_damaged)


func _physics_process(delta: float) -> void:
	match state:
		State.NORMAL:
			_ai_step(delta)
		State.THROWN:
			_fly(delta)
		State.STUNNED:
			_stunned_step(delta)


## The point the hook attaches to and aims at.
func get_center() -> Vector3:
	return global_position


## True if the grapple can take hold of this enemy: not already held, not dead, and not mid-throw. An enemy
## flying from a melee knockback still counts (it has not regained control), so it can be hooked, thrown or hit again.
func is_hookable() -> bool:
	if health.is_dead():
		return false
	return state == State.NORMAL or state == State.STUNNED or (state == State.THROWN and _knocked)


## Damage an impact at `speed` (m/s along the surface normal) would do to this enemy.
func damage_for_impact(speed: float) -> float:
	return maxf(speed - stats.impact_threshold, 0.0) * stats.damage_per_speed


## The throw takes hold: the enemy stops and hangs where it is.
func grab() -> void:
	velocity = Vector3.ZERO
	_knocked = false
	_set_state(State.GRABBED)


## The throw lets go without throwing it: it is stunned and falls.
func drop() -> void:
	_stun()


## Releases the enemy into free flight with `launch_velocity`.
func throw(launch_velocity: Vector3) -> void:
	velocity = launch_velocity
	_flight_time = 0.0
	_knocked = false
	_set_state(State.THROWN)


## A melee hit: the enemy flies with `launch_velocity` like a thrown one, and a surface it hits does impact
## damage the same way. If it flies `knockback_max_distance` without hitting anything it regains control at once.
func knock_back(launch_velocity: Vector3) -> void:
	velocity = launch_velocity
	_flight_time = 0.0
	_knocked = true
	_knock_left = stats.knockback_max_distance
	_set_state(State.THROWN)


## A swing rope pulling on the enemy: `velocity_change` is the player's lost speed, shared out by mass.
func add_pull(velocity_change: Vector3) -> void:
	if state == State.NORMAL or state == State.STUNNED:
		velocity += velocity_change / maxf(stats.mass, 0.01)


## Another thrown enemy hit this one at `speed`. It takes the damage and is knocked along `push`.
func take_collision(speed: float, point: Vector3, push: Vector3) -> void:
	health.take_damage(damage_for_impact(speed))
	if health.is_dead():
		return
	velocity += push
	EnemyEffects.impact(get_tree().current_scene, point, -push.normalized(), speed)


## What a rewind sets on a remade enemy before it enters the tree: a variant placed with other stats stays itself.
func rewind_recipe() -> Dictionary:
	return {&"stats": stats}


func rewind_capture() -> Dictionary:
	return {
		&"transform": global_transform,
		&"velocity": velocity,
		&"state": state,
		&"flight_time": _flight_time,
		&"stun_left": _stun_left,
		&"knocked": _knocked,
		&"knock_left": _knock_left,
		&"health": health.get_current(),
		&"ai": _capture_ai(),
	}


## Held by a throw in the snapshot: the throw isn't rewound (the player comes back with the hook put away), so the
## enemy comes back dropped, as if let go.
func rewind_restore(saved: Dictionary, _rewind: Rewind) -> void:
	global_transform = saved[&"transform"]
	velocity = saved[&"velocity"]
	_flight_time = saved[&"flight_time"]
	_stun_left = saved[&"stun_left"]
	_knocked = saved[&"knocked"]
	_knock_left = saved[&"knock_left"]
	health.restore(saved[&"health"])
	var restored: State = saved[&"state"]
	if restored == State.GRABBED:
		restored = State.STUNNED
		_stun_left = stats.stun_time
	state = restored
	_on_state_changed()
	state_changed.emit(state)
	_restore_ai(saved[&"ai"])


## Where the playback of a rewind has the enemy between two snapshots.
func rewind_pose(from: Dictionary, to: Dictionary, weight: float, span: float) -> void:
	global_transform = RewindScrub.transform_between(from, to, weight, span)


## The enemy type's own state for a rewind snapshot (plain values only).
func _capture_ai() -> Dictionary:
	return {}


## Puts `_capture_ai`'s state back. Runs after the base state and `_on_state_changed`.
func _restore_ai(_saved: Dictionary) -> void:
	pass


## NORMAL state behaviour, called each physics frame. Overridden by each enemy type.
func _ai_step(_delta: float) -> void:
	pass


## Called whenever the state changes, after `state` is updated. Overridden by each enemy type.
func _on_state_changed() -> void:
	pass


## Called when a stun ends. The enemy type puts itself somewhere it can work from again.
func _on_recovered() -> void:
	pass


func _set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	_on_state_changed()
	state_changed.emit(state)


func _stun() -> void:
	_stun_left = stats.stun_time
	_set_state(State.STUNNED)


func _fly(delta: float) -> void:
	_flight_time += delta
	velocity.y -= _gravity * stats.thrown_gravity_scale * delta
	var start: Vector3 = global_position
	var collision: KinematicCollision3D = move_and_collide(velocity * delta)
	if collision != null:
		_knocked = false
		_on_thrown_hit(collision)
	elif _knocked:
		_knock_left -= global_position.distance_to(start)
		if _knock_left <= 0.0:
			_recover()
	elif _flight_time >= stats.max_flight_time:
		_stun()


func _on_thrown_hit(collision: KinematicCollision3D) -> void:
	var normal: Vector3 = collision.get_normal()
	var point: Vector3 = collision.get_position()
	var speed: float = maxf(-velocity.dot(normal), 0.0)
	impacted.emit(speed, point)
	var other: Enemy = collision.get_collider() as Enemy
	if other != null:
		other.take_collision(speed * stats.collision_damage_scale, point, velocity * 0.5)
	EnemyEffects.impact(get_tree().current_scene, point, normal, speed)
	health.take_damage(damage_for_impact(speed))
	if health.is_dead():
		return
	velocity = velocity.bounce(normal) * stats.bounce
	_stun()


func _stunned_step(delta: float) -> void:
	_stun_left -= delta
	velocity.y -= _gravity * delta
	var collision: KinematicCollision3D = move_and_collide(velocity * delta)
	if collision != null:
		velocity = velocity.slide(collision.get_normal()) * 0.9
	if _stun_left <= 0.0:
		_recover()


## Back to its own behaviour, from a stun or the end of a knockback.
func _recover() -> void:
	_knocked = false
	velocity = Vector3.ZERO
	_on_recovered()
	_set_state(State.NORMAL)


func _on_damaged(amount: float) -> void:
	damaged.emit(amount, get_center(), health.is_dead())


func _die() -> void:
	died.emit()
	EnemyEffects.death(get_tree().current_scene, global_position)
	queue_free()
