class_name Player
extends CharacterBody3D
## Basic ground movement for the first-person player. Mouse look lives in HeadLook,
## the grappling hook in GrappleHook.

@export var move_speed: float = 5.0
@export var jump_height: float = 1.0
## Camera shake strength (0-1) when the grapple attaches or detaches.
@export var grapple_shake: float = 0.8
## Share of the player's velocity kept when a launch or a pull begins. The rest is lost.
@export_range(0.0, 1.0) var momentum_carry: float = 0.4

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _jump_velocity: float = sqrt(2.0 * _gravity * jump_height)
## True after a grapple pull ends, a launch fires or a swing releases: velocity is preserved (no input override) until landing.
var _keeps_momentum: bool = false
## Carried velocity added on top of the pull velocity for the length of a pull.
var _pull_carry: Vector3 = Vector3.ZERO

@onready var _grapple: GrappleHook = $GrappleHook
@onready var _camera: ShakeCamera = $Head/Camera3D
@onready var _walk_bob: WalkBob = $Head/Camera3D/WalkBob
@onready var _footsteps: Footsteps = $Footsteps


func _ready() -> void:
	_grapple.attached.connect(_on_grapple_attached)
	_grapple.detached.connect(_on_grapple_detached)
	_grapple.launched.connect(_on_grapple_launched)


func _physics_process(delta: float) -> void:
	if _grapple.is_swinging():
		# Plain airborne physics with no input: momentum is kept and the rope does the steering.
		velocity.y -= _gravity * delta
		move_and_slide()
		velocity = _grapple.apply_swing_constraint(velocity, delta)
		_set_walking(false)
		return

	if _grapple.is_pulling():
		velocity = _grapple.get_pull_velocity() + _pull_carry
		move_and_slide()
		_set_walking(false)
		return

	if _keeps_momentum:
		velocity.y -= _gravity * delta
		move_and_slide()
		if is_on_floor() and velocity.y <= 0.0:
			_keeps_momentum = false
		_set_walking(false)
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = _jump_velocity

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	move_and_slide()
	_set_walking(is_on_floor() and not direction.is_zero_approx())


## Walk bob and footsteps both follow the same walking state.
func _set_walking(walking: bool) -> void:
	_walk_bob.set_walking(walking)
	_footsteps.set_walking(walking)


func _on_grapple_attached() -> void:
	_pull_carry = velocity * momentum_carry if _grapple.is_pulling() else Vector3.ZERO
	_camera.shake(grapple_shake)


func _on_grapple_detached() -> void:
	_pull_carry = Vector3.ZERO
	_keeps_momentum = true
	_camera.shake(grapple_shake)


## The launch adds its boost on top of the momentum the player keeps.
func _on_grapple_launched(launch_velocity: Vector3) -> void:
	velocity = velocity * momentum_carry + launch_velocity
	_keeps_momentum = true
