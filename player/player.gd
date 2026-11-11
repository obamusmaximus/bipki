class_name Player
extends CharacterBody3D
## Ground and air movement for the first-person player. Mouse look lives in HeadLook,
## the grappling hook in GrappleHook.

@export var move_speed: float = 15.0
## Air control: WASD pushes the horizontal speed toward this value in the input direction.
@export var air_speed: float = 10.0
## How fast air control adds speed toward air_speed (m/s per second).
@export var air_acceleration: float = 30.0
## Jump velocity (m/s). Three times the old 1 m jump (about 4.4 m/s).
@export var jump_speed: float = 13.3
## Double jump velocity as a multiple of jump_speed.
@export var double_jump_factor: float = 1.2
## Sideways speed (m/s) a double jump adds while A or D is held.
@export var double_jump_sideways: float = 3.0
## Camera shake strength (0-1) when the grapple attaches or detaches.
@export var grapple_shake: float = 0.8
## Extra FOV (degrees) punched in when a launch fires.
@export var launch_fov_kick: float = 8.0
## WASD pushes the body along the swing rope's tangent at this acceleration (m/s per second).
@export var swing_steer_acceleration: float = 15.0
## Top speed (m/s) the swing steering adds along the tangent.
@export var swing_steer_speed: float = 8.0
## Share of the player's velocity kept when a launch begins. The rest is lost.
@export_range(0.0, 1.0) var momentum_carry: float = 0.4

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
## True after a launch fires or a swing releases: velocity is preserved (no input override) until landing.
var _keeps_momentum: bool = false
## One double jump per airtime; restored on landing.
var _double_jump_ready: bool = true

@onready var _grapple: GrappleHook = $GrappleHook
@onready var _camera: ShakeCamera = $Head/Camera3D
@onready var _walk_bob: WalkBob = $Head/Camera3D/WalkBob
@onready var _footsteps: Footsteps = $Footsteps
@onready var _fov: DynamicFov = $Head/Camera3D/DynamicFov
@onready var _landing: LandingWatcher = $LandingWatcher
@onready var _hud: Hud = $Hud
@onready var _effects: EffectsDirector = $Effects
@onready var _detector: EdgeDetector = $EdgeDetector
@onready var _mantle: Mantle = $Mantle
@onready var _health: Health = $Health
@onready var _pause_menu: PauseMenu = $PauseMenu

## Wall normals beside the body from the last frame, as [left, right]. ZERO means no wall.
var _walls: PackedVector3Array = PackedVector3Array([Vector3.ZERO, Vector3.ZERO])


func _ready() -> void:
	_grapple.camera = _camera
	_grapple.attached.connect(_on_grapple_attached)
	_grapple.detached.connect(_on_grapple_detached)
	_grapple.launched.connect(_on_grapple_launched)
	_detector.setup(self)
	_detector.ledge_ahead.connect(_on_ledge_ahead)
	_detector.walls_beside.connect(_on_walls_beside)
	_mantle.setup(self)
	_mantle.finished.connect(_on_mantle_finished)
	_fov.setup(self)
	_landing.setup(self)
	_hud.setup(self, _grapple, _health)
	_health.died.connect(_on_died)
	_effects.setup(self, _grapple, _landing, _camera)


func _physics_process(delta: float) -> void:
	if is_on_floor():
		_double_jump_ready = true
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	if _mantle.step(delta):
		_set_walking(false)
		return

	if _grapple.is_swinging():
		# Plain airborne physics with no input: momentum is kept and the rope does the steering.
		velocity.y -= _gravity * delta
		# Don't carry velocity into a wall beside the body (the rope can push it there).
		for wall: Vector3 in _walls:
			if wall != Vector3.ZERO and velocity.dot(wall) < 0.0:
				velocity = velocity.slide(wall)
		_steer_swing(direction, delta)
		move_and_slide()
		var correction: SwingRope.Correction = _grapple.constrain_swing(velocity, delta)
		# The rope correction respects walls: it stops at a face instead of passing through it.
		var collision: KinematicCollision3D = move_and_collide(correction.offset)
		velocity = correction.velocity
		if collision:
			velocity = velocity.slide(collision.get_normal())
		_set_walking(false)
		return

	if _keeps_momentum:
		velocity.y -= _gravity * delta
		_try_double_jump(input_dir.x)
		# Air control only adds speed toward the input, so it steers without cutting the momentum.
		_air_control(direction, delta)
		move_and_slide()
		if is_on_floor() and velocity.y <= 0.0:
			_keeps_momentum = false
		_set_walking(false)
		return

	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_speed
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.y -= _gravity * delta
		_try_double_jump(input_dir.x)
		_air_control(direction, delta)
	move_and_slide()
	_set_walking(is_on_floor() and not direction.is_zero_approx())


## Jump press in the air: a double jump, once per airtime. Holding A or D adds a sideways push.
func _try_double_jump(side: float) -> void:
	if not _double_jump_ready or not Input.is_action_just_pressed("jump") or is_on_floor():
		return
	_double_jump_ready = false
	velocity.y = jump_speed * double_jump_factor
	if side != 0.0:
		velocity += transform.basis.x * side * double_jump_sideways


## WASD steers a swing by pushing along the rope's tangent. That adds swing without
## stretching or shortening the rope, since the rope correction removes any push outward.
func _steer_swing(direction: Vector3, delta: float) -> void:
	if direction.is_zero_approx():
		return
	var rope: Vector3 = global_position - _grapple.get_hit_point()
	if rope.is_zero_approx():
		return
	var outward: Vector3 = rope.normalized()
	var tangent: Vector3 = direction - outward * direction.dot(outward)
	if tangent.is_zero_approx():
		return
	tangent = tangent.normalized()
	var along: float = velocity.dot(tangent)
	if along >= swing_steer_speed:
		return
	velocity += tangent * minf(swing_steer_acceleration * delta, swing_steer_speed - along)


## In the air, WASD only adds speed in the input direction, up to air_speed. It never slows the
## player, so the jump momentum and a double-jump push are kept.
func _air_control(direction: Vector3, delta: float) -> void:
	if direction.is_zero_approx():
		return
	var along: float = Vector2(velocity.x, velocity.z).dot(Vector2(direction.x, direction.z))
	if along >= air_speed:
		return
	velocity += direction * minf(air_acceleration * delta, air_speed - along)


## Walk bob and footsteps both follow the same walking state.
func _set_walking(walking: bool) -> void:
	_walk_bob.set_walking(walking)
	_footsteps.set_walking(walking)


## Walking or falling into a ledge starts a mantle, unless the hook is in use.
func _on_ledge_ahead(ledge: EdgeProbe.Ledge) -> void:
	if _grapple.get_state() != GrappleHook.State.IDLE:
		return
	_mantle.try_start(ledge, velocity)


func _on_walls_beside(left: Vector3, right: Vector3) -> void:
	_walls = PackedVector3Array([left, right])


func _on_mantle_finished() -> void:
	velocity = Vector3.ZERO


func _on_grapple_attached() -> void:
	_camera.shake(grapple_shake)


func _on_grapple_detached() -> void:
	_keeps_momentum = true
	_camera.shake(grapple_shake)


## The launch adds its boost on top of the momentum the player keeps.
func _on_grapple_launched(launch_velocity: Vector3) -> void:
	velocity = velocity * momentum_carry + launch_velocity
	_keeps_momentum = true
	_fov.kick(launch_fov_kick)


## The Hud's death screen freezes the game; ESC must not unpause it again.
func _on_died() -> void:
	_pause_menu.set_process_unhandled_input(false)
