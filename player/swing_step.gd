class_name SwingStep
extends RefCounted
## Moves the player through one physics frame of a swing (see docs/mechanics/grapple.md, "Swing and the ground").
## A swing and walking are exclusive: landing after having been in the air ends the swing, and that frame is a
## walking one. A swing started from the floor walks and jumps at walking pace until the player first leaves it.
## Owned by GrappleLoadout, which calls `step` while the hook swings.

var _body: Player
var _grapple: GrappleHook
var _assist: AvoidanceAssist
var _gravity: BodyGravity
var _stats: PlayerStats
## True once the player has left the floor during the current swing. Landing after that ends the swing.
var _airborne: bool = false


func _init(body: Player, grapple: GrappleHook, assist: AvoidanceAssist, gravity: BodyGravity, stats: PlayerStats) -> void:
	_body = body
	_grapple = grapple
	_assist = assist
	_gravity = gravity
	_stats = stats


## A new swing (or a rewind): it hasn't left the floor yet.
func reset() -> void:
	_airborne = false


func step(delta: float, direction: Vector3) -> void:
	var body: Player = _body
	_gravity.end_launch()
	body.stop_jump_rise()
	var grounded: bool = body.is_on_floor() and body.velocity.y <= 0.0
	if not body.is_on_floor():
		_airborne = true
	elif grounded and _airborne:
		_grapple.release()
		_airborne = false
		# The swing's speed doesn't carry into walking, which is hard capped: this is a walking frame.
		body.land_into_walk(direction)
		body.mark_force(&"walk")
		body.move_and_slide()
		body.mark_force(&"collision")
		body.set_walking(not direction.is_zero_approx())
		return
	# A swing started from the floor (never airborne yet): walk and jump as usual at walking pace, the rope only stops
	# the player going further than its length. Faster (a swing grazing the ground) keeps sliding.
	if grounded and Vector2(body.velocity.x, body.velocity.z).length() <= _stats.move_speed \
			and not Input.is_action_pressed("reel"):
		body.ground_move(direction)
	else:
		_fly(delta, direction)
	body.mark_force(&"walk")
	body.move_and_slide()
	body.mark_force(&"collision")
	var correction: SwingRope.Correction = _grapple.constrain_swing(body.velocity, body.is_on_floor(), delta)
	# The rope correction respects walls: it stops at a face instead of passing through it.
	var collision: KinematicCollision3D = body.move_and_collide(correction.offset)
	body.velocity = correction.velocity
	body.mark_force(&"rope")
	if collision:
		# A swing never wall runs: it just slides along the wall.
		body.velocity = body.velocity.slide(collision.get_normal())
		body.mark_force(&"collision")
	body.set_walking(body.is_on_floor() and not direction.is_zero_approx())


## Plain airborne physics with no input: momentum is kept and the rope does the steering.
func _fly(delta: float, direction: Vector3) -> void:
	var body: Player = _body
	body.velocity.y -= _gravity.swing(body.velocity.y) * delta
	body.mark_force(&"gravity")
	# Don't carry velocity into a wall beside the body (the rope can push it there).
	for wall: Vector3 in body.get_walls():
		if wall != Vector3.ZERO and body.velocity.dot(wall) < 0.0:
			body.velocity = body.velocity.slide(wall)
	body.mark_force(&"wall_slide")
	body.velocity = Steering.swing(body.velocity, direction, body.global_position, _grapple.get_swing_anchor(), delta,
			_stats)
	body.mark_force(&"steering")
	body.velocity += _assist.get_acceleration(direction) * delta
	body.mark_force(&"assist")
	body.velocity = AirDrag.apply(body.velocity, delta, _stats)
	body.mark_force(&"drag")
	body.velocity = SoftSpeedLimit.apply(body.velocity, delta, _stats)
	body.mark_force(&"soft_limit")
