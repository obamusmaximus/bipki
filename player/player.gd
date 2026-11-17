class_name Player
extends CharacterBody3D
## The first-person player's body: ground and air movement, momentum flight, wall run, health, lives and the
## rewind. Mouse look lives in HeadLook. The abilities are a swappable Loadout child (the grapple is GrappleLoadout),
## which Player calls at fixed points of its frame and which moves the body through the loadout API below.

## Debug: a moment worth seeing in the playtest log (debug/playtest_log/), e.g. a launch or a wall run start.
signal playtest_event(event: StringName, data: Dictionary)
## The player died and spent a life. The level rewinds (see `Rewind`). With nothing connected, a death is game over.
signal rewind_requested

## Tunable numbers (see the stats resources in tuning/). Edited live from the pause menu's tuning panel.
@export var stats: PlayerStats
@export var feel: CameraFeel
@export var hud_stats: HudStats
@export var minimap_stats: MinimapStats
## The ability set to play with, made a child on ready (see Loadout).
@export var loadout_scene: PackedScene

## The player's own gravity (PlayerStats "Gravity"), shared with the TrajectoryPredictor.
var _gravity: BodyGravity
## Grace window after a fast landing that lets a jump keep the speed (see Bunnyhop).
var _bunnyhop: Bunnyhop
## True after a launch fires or a swing releases: velocity is preserved (no input override) until landing.
var _keeps_momentum: bool = false
## One double jump per airtime; restored on landing.
var _double_jump_ready: bool = true
## True while rising from a jump or double jump, so releasing jump can cut it short.
var _jump_rising: bool = false
var _loadout: Loadout

@onready var _head: HeadLook = $Head
@onready var _camera: ShakeCamera = $Head/Camera3D
@onready var _walk_bob: WalkBob = $Head/Camera3D/WalkBob
@onready var _footsteps: Footsteps = $Footsteps
@onready var _fov: DynamicFov = $Head/Camera3D/DynamicFov
@onready var _landing: LandingWatcher = $LandingWatcher
@onready var _hud: Hud = $Hud
@onready var _effects: EffectsDirector = $Effects
@onready var _detector: EdgeDetector = $EdgeDetector
@onready var _wall_run: WallRun = $WallRun
@onready var _lean: CameraLean = $Head/Camera3D/CameraLean
@onready var _health: Health = $Health
@onready var _pause_menu: PauseMenu = $PauseMenu

## Wall normals beside the body from the last frame, as [left, right]. ZERO means no wall.
var _walls: PackedVector3Array = PackedVector3Array([Vector3.ZERO, Vector3.ZERO])
## Debug: this frame's velocity change split by cause, for the playtest log.
var _forces := VelocityLedger.new()
var _lives: Lives
## True from a death that rewinds until the restore: the body coasts with no input while time slows to a stop.
var _downed: bool = false


func _ready() -> void:
	add_to_group(&"playtest_probe")
	add_to_group(Rewind.GROUP)
	_lives = Lives.new(stats.lives)
	# Hand the tuning resources down first: later setup calls and the HUD read them.
	_gravity = BodyGravity.new(stats)
	_bunnyhop = Bunnyhop.new(stats)
	_health.setup(stats.max_health)
	_head.setup(feel)
	_camera.setup(feel)
	_walk_bob.setup(feel)
	_footsteps.setup(stats)
	_pause_menu.setup(hud_stats)
	_detector.setup(self, stats)
	_detector.walls_beside.connect(_on_walls_beside)
	_wall_run.setup(self, stats)
	_wall_run.started.connect(_on_wall_run_started)
	_wall_run.ended.connect(_on_wall_run_ended)
	_lean.setup(self, feel)
	_fov.setup(self, feel)
	_landing.setup(self)
	# Right after the head, so the loadout's parts (the hook) tick before the body's other parts.
	_loadout = loadout_scene.instantiate() as Loadout
	add_child(_loadout)
	move_child(_loadout, _head.get_index() + 1)
	_loadout.playtest_event.connect(playtest_event.emit)
	_loadout.setup(self, _camera, _head, _fov, _gravity, _wall_run)
	_hud.setup(self, _health, stats, hud_stats, minimap_stats)
	_loadout.setup_hud(_hud)
	_hud.setup_damage_numbers(_camera)
	_hud.setup_lives(_lives)
	_health.died.connect(_on_died)
	_effects.setup(self, _landing, _camera)


## Tells the HUD minimap about the city. The level calls this once the city is built.
func show_city(boxes: Array[AABB]) -> void:
	_hud.set_city(boxes)


func _physics_process(delta: float) -> void:
	_forces.begin(velocity)
	if _downed:
		_coast(delta)
		return
	if is_on_floor():
		_double_jump_ready = true
		# A launch fired while standing still reports the floor this frame; it isn't a landing.
		if velocity.y <= 0.0:
			_gravity.end_launch()
	_gravity.tick(delta)
	_bunnyhop.tick(delta, is_on_floor())
	_loadout.begin_frame()
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
		_loadout.stop_flight_guidance()
		_jump_rising = false
		_wall_run.step(delta)
		_forces.mark(&"wall_run", velocity)
		return

	# The loadout's own movement state (the grapple's swing) takes the frame.
	if _loadout.move(delta, direction):
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
		_loadout.steer_flight(direction, delta)
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
			_loadout.stop_flight_guidance()
			_bunnyhop.land(velocity)
		set_walking(false)
		return

	if is_on_floor():
		_ground_step(direction)
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
		_loadout.steer_flight(direction, delta)
		velocity = AirDrag.apply(velocity, delta, stats)
		_forces.mark(&"drag", velocity)
		velocity = SoftSpeedLimit.apply(velocity, delta, stats)
		_forces.mark(&"soft_limit", velocity)
	var velocity_before: Vector3 = velocity
	move_and_slide()
	_forces.mark(&"collision", velocity)
	_wall_run.try_start(velocity_before)
	set_walking(is_on_floor() and not direction.is_zero_approx() and not _bunnyhop.is_open())


# Loadout API: what a Loadout may do to the body, besides setting `velocity` and moving it. `ground_move` and
# `set_walking` below are part of it too.

## What every launch shares: momentum flight, lighter gravity for at least `gravity_time`, the FOV kick.
func start_launch_flight(gravity_time: float = 0.0) -> void:
	_keeps_momentum = true
	_jump_rising = false
	_gravity.start_launch(gravity_time)
	_fov.kick(feel.launch_fov_kick)


## Momentum flight from here (a detach, a body hit): input stops overriding the velocity until landing.
func keep_momentum() -> void:
	_keeps_momentum = true


## A releasing jump no longer cuts the upward speed.
func stop_jump_rise() -> void:
	_jump_rising = false


func refill_double_jump() -> void:
	_double_jump_ready = true


## Landing out of the loadout's own movement: the frame is a walking one (or opens the bunnyhop window).
func land_into_walk(direction: Vector3) -> void:
	_keeps_momentum = false
	_bunnyhop.land(velocity)
	_ground_step(direction)


## Wall normals beside the body from the last frame, as [left, right]. ZERO means no wall.
func get_walls() -> PackedVector3Array:
	return _walls


## Debug: files the velocity change since the last mark under `cause` in the playtest log's force ledger.
func mark_force(cause: StringName) -> void:
	_forces.mark(cause, velocity)


## Dead, waiting for the rewind: falls and keeps its momentum with no input, so the slow-down shows the body carrying on.
func _coast(delta: float) -> void:
	if is_on_floor():
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		velocity.y -= _gravity.air(velocity.y) * delta
		velocity = AirDrag.apply(velocity, delta, stats)
	move_and_slide()
	_forces.mark(&"coast", velocity)


## On the floor: inside the bunnyhop window the speed is kept and a jump hops with it, otherwise walk as usual.
func _ground_step(direction: Vector3) -> void:
	if not _bunnyhop.is_open():
		ground_move(direction)
		return
	velocity.y = 0.0
	if _bunnyhop.wants_hop():
		velocity = _bunnyhop.hop(velocity)
		_keeps_momentum = true
		_jump_rising = true
		playtest_event.emit(&"bunnyhop", {"velocity": velocity})


## On the floor: walk at move_speed in the input direction, and jump.
func ground_move(direction: Vector3) -> void:
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
func set_walking(walking: bool) -> void:
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


## A death spends a life and the level rewinds. With none left to spend it is game over: the Hud's death screen freezes
## the game, and ESC must not unpause it again.
func _on_died() -> void:
	var rewinding: bool = _lives.spend() and not rewind_requested.get_connections().is_empty()
	playtest_event.emit(&"died", {"lives_left": _lives.get_left(), "rewinding": rewinding})
	if rewinding:
		_go_down()
		rewind_requested.emit()
		return
	_loadout.game_over()
	_pause_menu.set_process_unhandled_input(false)
	_hud.show_death_screen()


## A death that rewinds: the hook goes away, input and the body hit stop until the restore (`_set_active` brings them back).
func _go_down() -> void:
	_downed = true
	_loadout.go_down()
	_wall_run.cancel(false)
	set_walking(false)
	_set_active(false)


## Mouse look, the loadout's input and parts, and the pause menu.
func _set_active(enabled: bool) -> void:
	_head.set_process_unhandled_input(enabled)
	_loadout.set_active(enabled)
	_pause_menu.set_process_unhandled_input(enabled)


## The player's part of a rewind snapshot (see `Rewind`). Lives are not in it.
func rewind_capture() -> Dictionary:
	return {
		&"transform": global_transform,
		&"pitch": _head.get_pitch(),
		&"velocity": velocity,
		&"keeps_momentum": _keeps_momentum,
		&"double_jump_ready": _double_jump_ready,
		&"jump_rising": _jump_rising,
		&"launch_gravity_left": _gravity.get_launch_left(),
		&"bunnyhop_window_left": _bunnyhop.get_window_left(),
		&"health": _health.get_current(),
		&"wall_run": _wall_run.rewind_capture(),
		&"loadout": _loadout.rewind_capture(),
	}


func rewind_restore(state: Dictionary, _rewind: Rewind) -> void:
	# Loadout first: putting the hook away would otherwise set the momentum flag through `detached`.
	_loadout.rewind_restore(state[&"loadout"])
	_landing.reset()
	global_transform = state[&"transform"]
	_head.set_pitch(state[&"pitch"])
	velocity = state[&"velocity"]
	_keeps_momentum = state[&"keeps_momentum"]
	_double_jump_ready = state[&"double_jump_ready"]
	_jump_rising = state[&"jump_rising"]
	_gravity.restore_launch(state[&"launch_gravity_left"])
	_bunnyhop.restore(state[&"bunnyhop_window_left"])
	_health.restore(state[&"health"])
	_wall_run.rewind_restore(state[&"wall_run"])
	_lean.set_wall_side(_wall_run.get_side() if _wall_run.is_active() else 0.0)
	_downed = false
	_set_active(true)
	playtest_event.emit(&"rewound", {"lives_left": _lives.get_left()})


## Where the playback of a rewind has the player between two snapshots: the body and the look's pitch.
func rewind_pose(from: Dictionary, to: Dictionary, weight: float, span: float) -> void:
	global_transform = RewindScrub.transform_between(from, to, weight, span)
	_head.set_pitch(lerpf(from[&"pitch"], to[&"pitch"], weight))


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
	snapshot["on_floor"] = is_on_floor()
	snapshot["keeps_momentum"] = _keeps_momentum
	snapshot["double_jump_ready"] = _double_jump_ready
	if _wall_run.is_active():
		snapshot["wall_run"] = {"side": _wall_run.get_side(), "head_on": _wall_run.is_head_on()}
	_loadout.add_playtest_fields(snapshot)
	return snapshot
