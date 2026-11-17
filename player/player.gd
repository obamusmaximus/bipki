class_name Player
extends CharacterBody3D
## Ground and air movement for the first-person player. Mouse look lives in HeadLook,
## the grappling hook in GrappleHook.

## Debug: a moment worth seeing in the playtest log (debug/playtest_log/), e.g. a launch or a wall run start.
signal playtest_event(event: StringName, data: Dictionary)

## Tunable numbers (see the stats resources in tuning/). Edited live from the pause menu's tuning panel.
@export var stats: PlayerStats
@export var grapple_stats: GrappleStats
@export var feel: CameraFeel
@export var hud_stats: HudStats
@export var minimap_stats: MinimapStats
@export var arc_stats: TrajectoryArcStats

## Extra seconds of launch gravity past a strike's planned flight time, so a late arrival doesn't drop suddenly.
const STRIKE_GRAVITY_MARGIN: float = 0.25

## The player's own gravity (PlayerStats "Gravity"), shared with the TrajectoryPredictor.
var _gravity: BodyGravity
## True after a launch fires or a swing releases: velocity is preserved (no input override) until landing.
var _keeps_momentum: bool = false
## Steers a launch at an enemy into it (see StrikeGuidance).
var _strike: StrikeGuidance
## One double jump per airtime; restored on landing.
var _double_jump_ready: bool = true
## True while rising from a jump or double jump, so releasing jump can cut it short.
var _jump_rising: bool = false
## True once the player has left the floor during the current swing. Landing after that ends the swing.
var _swing_airborne: bool = false

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
@onready var _melee: Melee = $Melee
@onready var _hit_stop: HitStop = $HitStop

## Wall normals beside the body from the last frame, as [left, right]. ZERO means no wall.
var _walls: PackedVector3Array = PackedVector3Array([Vector3.ZERO, Vector3.ZERO])
## Debug: this frame's velocity change split by cause, for the playtest log.
var _forces := VelocityLedger.new()


func _ready() -> void:
	add_to_group(&"playtest_probe")
	# Hand the tuning resources down first: later setup calls and the HUD read them.
	_gravity = BodyGravity.new(stats)
	_strike = StrikeGuidance.new(grapple_stats, _gravity)
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
	_grapple.launched_at_enemy.connect(_on_grapple_launched_at_enemy)
	_melee.setup(self, _camera, stats, grapple_stats)
	_melee.hit.connect(_on_melee_hit)
	_detector.setup(self, stats)
	_detector.walls_beside.connect(_on_walls_beside)
	_predictor.setup(self, _grapple, stats, _camera, _gravity)
	_assist.setup(self, _grapple, _predictor, stats)
	_wall_run.setup(self, stats)
	_wall_run.started.connect(_on_wall_run_started)
	_wall_run.ended.connect(_on_wall_run_ended)
	_lean.setup(self, feel)
	_fov.setup(self, feel)
	_landing.setup(self)
	_hud.setup(self, _grapple, _health, stats, hud_stats, minimap_stats)
	_hud.setup_arc(_camera, _predictor, self, arc_stats)
	_hud.setup_throw(_grapple.get_throw(), _camera, arc_stats)
	_hud.setup_damage_numbers(_camera)
	_health.died.connect(_on_died)
	_effects.setup(self, _grapple, _landing, _camera)


## Tells the HUD minimap about the city. The level calls this once the city is built.
func show_city(boxes: Array[AABB]) -> void:
	_hud.set_city(boxes)


func _physics_process(delta: float) -> void:
	_forces.begin(velocity)
	if is_on_floor():
		_double_jump_ready = true
		# A launch fired while standing still reports the floor this frame; it isn't a landing.
		if velocity.y <= 0.0:
			_gravity.end_launch()
	_gravity.tick(delta)
	_grapple.wall_normals = PackedVector3Array([_walls[0], _walls[1], _wall_run.get_normal() if _wall_run.is_active() else Vector3.ZERO])
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	if _wall_run.is_active():
		# The run keeps the double jump ready and plays footsteps (no walk bob). A head-on latch does neither.
		var running: bool = not _wall_run.is_head_on()
		if running:
			_double_jump_ready = true
		_walk_bob.set_walking(false)
		_footsteps.set_walking(running)
		_gravity.end_launch()
		_strike.stop()
		_jump_rising = false
		_wall_run.step(delta)
		_forces.mark(&"wall_run", velocity)
		return

	if _grapple.is_swinging():
		_gravity.end_launch()
		_strike.stop()
		_jump_rising = false
		# A swing and walking are exclusive: landing after having been in the air ends the swing, and the
		# frame is a walking one.
		var grounded: bool = is_on_floor() and velocity.y <= 0.0
		if not is_on_floor():
			_swing_airborne = true
		elif grounded and _swing_airborne:
			_grapple.release()
			_swing_airborne = false
			# The swing's speed doesn't carry into walking, which is hard capped: this is a walking frame.
			_keeps_momentum = false
			_ground_move(direction)
			_forces.mark(&"walk", velocity)
			move_and_slide()
			_forces.mark(&"collision", velocity)
			_set_walking(not direction.is_zero_approx())
			return
		# A swing started from the floor (never airborne yet): walk and jump as usual at walking pace, the rope
		# only stops the player going further than its length. Faster (a swing grazing the ground) keeps sliding.
		if grounded and Vector2(velocity.x, velocity.z).length() <= stats.move_speed \
				and not Input.is_action_pressed("reel"):
			_ground_move(direction)
		else:
			# Plain airborne physics with no input: momentum is kept and the rope does the steering.
			velocity.y -= _gravity.swing(velocity.y) * delta
			_forces.mark(&"gravity", velocity)
			# Don't carry velocity into a wall beside the body (the rope can push it there).
			for wall: Vector3 in _walls:
				if wall != Vector3.ZERO and velocity.dot(wall) < 0.0:
					velocity = velocity.slide(wall)
			_forces.mark(&"wall_slide", velocity)
			velocity = Steering.swing(velocity, direction, global_position, _grapple.get_swing_anchor(), delta, stats)
			_forces.mark(&"steering", velocity)
			velocity += _assist.get_acceleration(direction) * delta
			_forces.mark(&"assist", velocity)
			velocity = AirDrag.apply(velocity, delta, stats)
			_forces.mark(&"drag", velocity)
			velocity = SoftSpeedLimit.apply(velocity, delta, stats)
			_forces.mark(&"soft_limit", velocity)
		_forces.mark(&"walk", velocity)
		move_and_slide()
		_forces.mark(&"collision", velocity)
		var correction: SwingRope.Correction = _grapple.constrain_swing(velocity, is_on_floor(), delta)
		# The rope correction respects walls: it stops at a face instead of passing through it.
		var collision: KinematicCollision3D = move_and_collide(correction.offset)
		velocity = correction.velocity
		_forces.mark(&"rope", velocity)
		if collision:
			# A swing never wall runs: it just slides along the wall.
			velocity = velocity.slide(collision.get_normal())
			_forces.mark(&"collision", velocity)
		_set_walking(is_on_floor() and not direction.is_zero_approx())
		return

	if _keeps_momentum:
		velocity.y -= _gravity.air(velocity.y) * delta
		_forces.mark(&"gravity", velocity)
		_try_double_jump(input_dir.x)
		_cut_jump()
		_forces.mark(&"jump", velocity)
		# Air steering turns the velocity or adds speed toward the input, so it never cuts the momentum.
		velocity = Steering.air(velocity, direction, delta, stats)
		_forces.mark(&"steering", velocity)
		# A strike at an enemy flies into it on purpose, so the obstacle assist stays out of it.
		if _strike.is_active():
			velocity = _strike.steer(velocity, global_position + Vector3.UP * Melee.MID_BODY, direction, delta)
			_forces.mark(&"strike", velocity)
		else:
			velocity += _assist.get_acceleration(direction) * delta
			_forces.mark(&"assist", velocity)
		velocity = AirDrag.apply(velocity, delta, stats)
		_forces.mark(&"drag", velocity)
		velocity = SoftSpeedLimit.apply(velocity, delta, stats)
		_forces.mark(&"soft_limit", velocity)
		var velocity_before: Vector3 = velocity
		move_and_slide()
		_forces.mark(&"collision", velocity)
		if _wall_run.try_start(velocity_before):
			return
		if is_on_floor() and velocity.y <= 0.0:
			_keeps_momentum = false
			_strike.stop()
		_set_walking(false)
		return

	if is_on_floor():
		_ground_move(direction)
		_forces.mark(&"walk", velocity)
	else:
		velocity.y -= _gravity.air(velocity.y) * delta
		_forces.mark(&"gravity", velocity)
		_try_double_jump(input_dir.x)
		_cut_jump()
		_forces.mark(&"jump", velocity)
		velocity = Steering.air(velocity, direction, delta, stats)
		_forces.mark(&"steering", velocity)
	if not is_on_floor():
		velocity += _assist.get_acceleration(direction) * delta
		_forces.mark(&"assist", velocity)
		velocity = AirDrag.apply(velocity, delta, stats)
		_forces.mark(&"drag", velocity)
		velocity = SoftSpeedLimit.apply(velocity, delta, stats)
		_forces.mark(&"soft_limit", velocity)
	var velocity_before: Vector3 = velocity
	move_and_slide()
	_forces.mark(&"collision", velocity)
	_wall_run.try_start(velocity_before)
	_set_walking(is_on_floor() and not direction.is_zero_approx())


## On the floor: walk at move_speed in the input direction, and jump.
func _ground_move(direction: Vector3) -> void:
	if Input.is_action_just_pressed("jump"):
		velocity.y = stats.jump_speed
		_jump_rising = true
	velocity.x = direction.x * stats.move_speed
	velocity.z = direction.z * stats.move_speed


## Jump press in the air: a double jump, once per airtime. Holding A or D adds a sideways push.
func _try_double_jump(side: float) -> void:
	if not _double_jump_ready or not Input.is_action_just_pressed("jump") or is_on_floor():
		return
	_double_jump_ready = false
	velocity.y = stats.jump_speed * stats.double_jump_factor
	_jump_rising = true
	if side != 0.0:
		velocity += transform.basis.x * side * stats.double_jump_sideways


## Letting go of jump while still rising from a jump keeps only `jump_release_cut` of the upward speed.
func _cut_jump() -> void:
	if not _jump_rising:
		return
	if velocity.y <= 0.0:
		_jump_rising = false
	elif Input.is_action_just_released("jump"):
		velocity.y *= stats.jump_release_cut
		_jump_rising = false


## Walk bob and footsteps both follow the same walking state.
func _set_walking(walking: bool) -> void:
	_walk_bob.set_walking(walking)
	_footsteps.set_walking(walking)


func _on_walls_beside(left: Vector3, right: Vector3) -> void:
	_walls = PackedVector3Array([left, right])


func _on_wall_run_started(side: float) -> void:
	playtest_event.emit(&"wall_run_started", {"side": side, "head_on": _wall_run.is_head_on()})
	if not _wall_run.is_head_on():
		_double_jump_ready = true
	_lean.set_wall_side(side)


## Leaving the wall keeps the momentum, like leaving a swing.
func _on_wall_run_ended() -> void:
	playtest_event.emit(&"wall_run_ended", {})
	_keeps_momentum = true
	_lean.set_wall_side(0.0)


func _on_grapple_attached() -> void:
	playtest_event.emit(&"grapple_attached", {"hit_point": _grapple.get_hit_point()})
	if _grapple.get_mode() == GrappleHook.Mode.SWING:
		_swing_airborne = false
		# A swing and a wall run are exclusive. Letting go of the swing can latch a wall again at once.
		_wall_run.cancel(false)
	_camera.shake(feel.grapple_shake)
	if grapple_stats.hit_stop_enabled:
		_hit_stop.trigger(grapple_stats.hit_stop_scale, grapple_stats.hit_stop_time)


func _on_grapple_detached() -> void:
	playtest_event.emit(&"grapple_detached", {})
	_keeps_momentum = true
	_camera.shake(feel.grapple_shake)


## The launch adds its boost on top of the momentum the player keeps.
func _on_grapple_launched(launch_velocity: Vector3) -> void:
	playtest_event.emit(&"launched", {"launch_velocity": launch_velocity})
	_wall_run.cancel() # A launch sends the player flying; it isn't spent running along a wall.
	velocity = velocity * stats.momentum_carry + launch_velocity
	# Fired while standing, lift off the floor, or a launch aimed slightly down would stop dead on it.
	if is_on_floor() and velocity.y < stats.launch_ground_lift:
		velocity.y = stats.launch_ground_lift
	_start_launch_flight()


## Launched at an enemy: at the speed a launch straight at it would give (never faster), aimed by StrikeGuidance
## along an arc into it. The launch gravity lasts the whole flight, which the aim assumes. The body hit is armed.
func _on_grapple_launched_at_enemy(enemy: Enemy) -> void:
	playtest_event.emit(&"launched_at_enemy", {"enemy": enemy.name, "enemy_center": enemy.get_center()})
	_wall_run.cancel()
	var mid: Vector3 = global_position + Vector3.UP * Melee.MID_BODY
	var toward: Vector3 = (enemy.get_center() - mid).normalized()
	var speed: float = (velocity * stats.momentum_carry + toward * grapple_stats.launch_speed).length()
	velocity = _strike.start(enemy, mid, speed)
	_start_launch_flight(_strike.flight_time(mid, speed) + STRIKE_GRAVITY_MARGIN)
	_melee.arm()


## What every launch shares: momentum flight, lighter gravity for at least `gravity_time`, the FOV kick.
func _start_launch_flight(gravity_time: float = 0.0) -> void:
	_keeps_momentum = true
	_jump_rising = false
	_gravity.start_launch(gravity_time)
	_fov.kick(feel.launch_fov_kick)


## The punch stops the player nearly dead, so the enemy gets the momentum. The double jump comes back.
func _on_melee_hit(enemy: Enemy, impact_velocity: Vector3) -> void:
	playtest_event.emit(&"melee_hit", {"enemy": enemy.name, "impact_velocity": impact_velocity})
	_strike.stop()
	velocity *= stats.melee_momentum_keep
	_keeps_momentum = true
	_jump_rising = false
	_double_jump_ready = true
	_camera.shake(feel.grapple_shake)
	if _grapple.get_enemy() == enemy:
		_grapple.release()


## A thrown enemy leaves the rope with a kick, harder for a harder throw.
func _on_grapple_thrown(launch_velocity: Vector3, power: float) -> void:
	playtest_event.emit(&"thrown", {"launch_velocity": launch_velocity, "power": power})
	_camera.shake(feel.grapple_shake * lerpf(0.5, 1.0, power))


## The Hud's death screen freezes the game; ESC must not unpause it again.
func _on_died() -> void:
	playtest_event.emit(&"died", {})
	_grapple.get_throw().cancel()
	_pause_menu.set_process_unhandled_input(false)


## Debug: what the playtest log records about the player each physics frame (debug/playtest_log/).
func playtest_snapshot() -> Dictionary:
	var snapshot: Dictionary = {
		"pos": global_position,
		"vel": velocity,
		"speed": velocity.length(),
		"forces": _forces.parts,
	}
	snapshot["look"] = -_camera.global_basis.z
	snapshot["input"] = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	snapshot["jump_held"] = Input.is_action_pressed("jump")
	snapshot["reel_held"] = Input.is_action_pressed("reel")
	snapshot["on_floor"] = is_on_floor()
	snapshot["keeps_momentum"] = _keeps_momentum
	snapshot["double_jump_ready"] = _double_jump_ready
	snapshot["strike"] = _strike.is_active()
	if _wall_run.is_active():
		snapshot["wall_run"] = {"side": _wall_run.get_side(), "head_on": _wall_run.is_head_on()}
	if _grapple.get_state() != GrappleHook.State.IDLE:
		snapshot["grapple"] = {
			"state": GrappleHook.State.find_key(_grapple.get_state()),
			"mode": GrappleHook.Mode.find_key(_grapple.get_mode()),
			"anchor": _grapple.get_swing_anchor(),
			"rope_length": _grapple.get_rope_length(),
		}
	return snapshot
