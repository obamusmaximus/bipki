class_name Player
extends CharacterBody3D
## Ground and air movement for the first-person player. Mouse look lives in HeadLook,
## the grappling hook in GrappleHook.

## Tunable numbers (see the stats resources in tuning/). Edited live from the pause menu's tuning panel.
@export var stats: PlayerStats
@export var grapple_stats: GrappleStats
@export var feel: CameraFeel
@export var hud_stats: HudStats
@export var minimap_stats: MinimapStats
@export var arc_stats: TrajectoryArcStats

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
## True after a launch fires or a swing releases: velocity is preserved (no input override) until landing.
var _keeps_momentum: bool = false
## One double jump per airtime; restored on landing.
var _double_jump_ready: bool = true

@onready var _head: HeadLook = $Head
@onready var _grapple: GrappleHook = $GrappleHook
@onready var _camera: ShakeCamera = $Head/Camera3D
@onready var _walk_bob: WalkBob = $Head/Camera3D/WalkBob
@onready var _footsteps: Footsteps = $Footsteps
@onready var _fov: DynamicFov = $Head/Camera3D/DynamicFov
@onready var _landing: LandingWatcher = $LandingWatcher
@onready var _hud: Hud = $Hud
@onready var _effects: EffectsDirector = $Effects
@onready var _detector: EdgeDetector = $EdgeDetector
@onready var _wall_run: WallRun = $WallRun
@onready var _assist: AvoidanceAssist = $AvoidanceAssist
@onready var _predictor: TrajectoryPredictor = $TrajectoryPredictor
@onready var _lean: CameraLean = $Head/Camera3D/CameraLean
@onready var _health: Health = $Health
@onready var _pause_menu: PauseMenu = $PauseMenu

## Wall normals beside the body from the last frame, as [left, right]. ZERO means no wall.
var _walls: PackedVector3Array = PackedVector3Array([Vector3.ZERO, Vector3.ZERO])


func _ready() -> void:
	# Hand the tuning resources down first: later setup calls and the HUD read them.
	_health.setup(stats.max_health)
	_head.setup(feel)
	_camera.setup(feel)
	_walk_bob.setup(feel)
	_footsteps.setup(stats)
	_grapple.setup(grapple_stats)
	_pause_menu.setup(hud_stats)
	_grapple.camera = _camera
	_grapple.get_throw().setup(grapple_stats, _camera, _head, _fov)
	_grapple.thrown.connect(_on_grapple_thrown)
	_grapple.attached.connect(_on_grapple_attached)
	_grapple.detached.connect(_on_grapple_detached)
	_grapple.launched.connect(_on_grapple_launched)
	_detector.setup(self, stats)
	_detector.walls_beside.connect(_on_walls_beside)
	_predictor.setup(self, _grapple, stats, _camera)
	_assist.setup(self, _grapple, _predictor, stats)
	_wall_run.setup(self, stats)
	_wall_run.started.connect(_on_wall_run_started)
	_wall_run.ended.connect(_on_wall_run_ended)
	_lean.setup(self, feel)
	_fov.setup(self, feel)
	_landing.setup(self)
	_hud.setup(self, _grapple, _health, hud_stats, minimap_stats)
	_hud.setup_arc(_camera, _predictor, self, arc_stats)
	_hud.setup_throw(_grapple.get_throw(), _camera, arc_stats)
	_hud.setup_damage_numbers(_camera)
	_health.died.connect(_on_died)
	_effects.setup(self, _grapple, _landing, _camera)


## Tells the HUD minimap about the city. The level calls this once the city is built.
func show_city(boxes: Array[AABB]) -> void:
	_hud.set_city(boxes)


func _physics_process(delta: float) -> void:
	if is_on_floor():
		_double_jump_ready = true
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	if _wall_run.is_active():
		# The run keeps the double jump ready and plays footsteps (no walk bob).
		_double_jump_ready = true
		_walk_bob.set_walking(false)
		_footsteps.set_walking(true)
		_wall_run.step(delta)
		return

	if _grapple.is_swinging():
		# Plain airborne physics with no input: momentum is kept and the rope does the steering.
		velocity.y -= _gravity * delta
		# Don't carry velocity into a wall beside the body (the rope can push it there).
		for wall: Vector3 in _walls:
			if wall != Vector3.ZERO and velocity.dot(wall) < 0.0:
				velocity = velocity.slide(wall)
		_steer_swing(direction, delta)
		velocity += _assist.get_acceleration(direction) * delta
		velocity = SoftSpeedLimit.apply(velocity, delta, stats)
		var velocity_before: Vector3 = velocity
		move_and_slide()
		if _wall_run.try_start(velocity_before):
			_grapple.release()
			return
		var correction: SwingRope.Correction = _grapple.constrain_swing(velocity, delta)
		# The rope correction respects walls: it stops at a face instead of passing through it.
		var collision: KinematicCollision3D = move_and_collide(correction.offset)
		velocity = correction.velocity
		if collision:
			if _wall_run.try_start(velocity_before, collision.get_normal()):
				_grapple.release()
				return
			velocity = velocity.slide(collision.get_normal())
		_set_walking(false)
		return

	if _keeps_momentum:
		velocity.y -= _gravity * delta
		_try_double_jump(input_dir.x)
		# Air control only adds speed toward the input, so it steers without cutting the momentum.
		_air_control(direction, delta)
		velocity += _assist.get_acceleration(direction) * delta
		velocity = SoftSpeedLimit.apply(velocity, delta, stats)
		var velocity_before: Vector3 = velocity
		move_and_slide()
		if _wall_run.try_start(velocity_before):
			return
		if is_on_floor() and velocity.y <= 0.0:
			_keeps_momentum = false
		_set_walking(false)
		return

	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = stats.jump_speed
		velocity.x = direction.x * stats.move_speed
		velocity.z = direction.z * stats.move_speed
	else:
		velocity.y -= _gravity * delta
		_try_double_jump(input_dir.x)
		_air_control(direction, delta)
	if not is_on_floor():
		velocity += _assist.get_acceleration(direction) * delta
		velocity = SoftSpeedLimit.apply(velocity, delta, stats)
	var velocity_before: Vector3 = velocity
	move_and_slide()
	_wall_run.try_start(velocity_before)
	_set_walking(is_on_floor() and not direction.is_zero_approx())


## Jump press in the air: a double jump, once per airtime. Holding A or D adds a sideways push.
func _try_double_jump(side: float) -> void:
	if not _double_jump_ready or not Input.is_action_just_pressed("jump") or is_on_floor():
		return
	_double_jump_ready = false
	velocity.y = stats.jump_speed * stats.double_jump_factor
	if side != 0.0:
		velocity += transform.basis.x * side * stats.double_jump_sideways


## WASD steers a swing by pushing along the rope's tangent. That adds swing without
## stretching or shortening the rope, since the rope correction removes any push outward.
func _steer_swing(direction: Vector3, delta: float) -> void:
	if direction.is_zero_approx():
		return
	var rope: Vector3 = global_position - _grapple.get_swing_anchor()
	if rope.is_zero_approx():
		return
	var outward: Vector3 = rope.normalized()
	var tangent: Vector3 = direction - outward * direction.dot(outward)
	if tangent.is_zero_approx():
		return
	tangent = tangent.normalized()
	var along: float = velocity.dot(tangent)
	if along >= stats.swing_steer_speed:
		return
	velocity += tangent * minf(stats.swing_steer_acceleration * delta, stats.swing_steer_speed - along)


## In the air, WASD steers. With the turn rate on, a fast player's velocity is rotated toward the input at
## a maximum rate (same feel at any speed, no energy added). Otherwise, or when slow, WASD only adds speed
## in the input direction, up to air_speed, and never slows the player, so jump momentum is kept.
func _air_control(direction: Vector3, delta: float) -> void:
	if direction.is_zero_approx():
		return
	var horizontal := Vector2(velocity.x, velocity.z)
	if stats.air_turn_rate_enabled and horizontal.length() >= stats.air_turn_min_speed:
		var wanted := Vector2(direction.x, direction.z)
		var limit: float = deg_to_rad(stats.air_turn_rate_degrees) * delta
		horizontal = horizontal.rotated(clampf(horizontal.angle_to(wanted), -limit, limit))
		velocity.x = horizontal.x
		velocity.z = horizontal.y
		return
	var along: float = horizontal.dot(Vector2(direction.x, direction.z))
	if along >= stats.air_speed:
		return
	velocity += direction * minf(stats.air_acceleration * delta, stats.air_speed - along)


## Walk bob and footsteps both follow the same walking state.
func _set_walking(walking: bool) -> void:
	_walk_bob.set_walking(walking)
	_footsteps.set_walking(walking)


func _on_walls_beside(left: Vector3, right: Vector3) -> void:
	_walls = PackedVector3Array([left, right])


func _on_wall_run_started(side: float) -> void:
	_double_jump_ready = true
	_lean.set_wall_side(side)


## Leaving the wall keeps the momentum, like leaving a swing.
func _on_wall_run_ended() -> void:
	_keeps_momentum = true
	_lean.set_wall_side(0.0)


func _on_grapple_attached() -> void:
	_camera.shake(feel.grapple_shake)


func _on_grapple_detached() -> void:
	_keeps_momentum = true
	_camera.shake(feel.grapple_shake)


## The launch adds its boost on top of the momentum the player keeps.
func _on_grapple_launched(launch_velocity: Vector3) -> void:
	velocity = velocity * stats.momentum_carry + launch_velocity
	_keeps_momentum = true
	_fov.kick(feel.launch_fov_kick)


## A thrown enemy leaves the rope with a kick, harder for a harder throw.
func _on_grapple_thrown(_launch_velocity: Vector3, power: float) -> void:
	_camera.shake(feel.grapple_shake * lerpf(0.5, 1.0, power))


## The Hud's death screen freezes the game; ESC must not unpause it again.
func _on_died() -> void:
	_grapple.get_throw().cancel()
	_pause_menu.set_process_unhandled_input(false)
