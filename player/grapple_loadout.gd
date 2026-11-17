class_name GrappleLoadout
extends Loadout
## The grapple loadout: launch, swing and reel (GrappleHook), the launch at an enemy (StrikeGuidance), the body hit
## (Melee), the throw, hit-stop and the flight helpers built on the hook (TrajectoryPredictor, AvoidanceAssist).
## Its HUD is GrappleHud. Detail in docs/mechanics/grapple.md and combat.md.

## Extra seconds of launch gravity past a strike's planned flight time, so a late arrival doesn't drop suddenly.
const STRIKE_GRAVITY_MARGIN: float = 0.25
const HUD_SCENE: PackedScene = preload("res://hud/grapple_hud.tscn")

## Tunable numbers (see the stats resources in tuning/). Edited live from the pause menu's tuning panel.
@export var grapple_stats: GrappleStats
@export var arc_stats: TrajectoryArcStats

var _body: Player
var _stats: PlayerStats
var _feel: CameraFeel
var _camera: ShakeCamera
var _wall_run: WallRun
## Steers a launch at an enemy into it.
var _strike: StrikeGuidance
var _swing: SwingStep

@onready var _grapple: GrappleHook = $GrappleHook
@onready var _assist: AvoidanceAssist = $AvoidanceAssist
@onready var _predictor: TrajectoryPredictor = $TrajectoryPredictor
@onready var _melee: Melee = $Melee
@onready var _hit_stop: HitStop = $HitStop


## The hand holds nothing yet: the rope starts at mid-body (GrappleHook), not at a muzzle.
func setup(body: Player, camera: ShakeCamera, head: HeadLook, fov: DynamicFov, gravity: BodyGravity,
		wall_run: WallRun, _hand: Node3D) -> void:
	_body = body
	_stats = body.stats
	_feel = body.feel
	_camera = camera
	_wall_run = wall_run
	_strike = StrikeGuidance.new(grapple_stats, gravity)
	_grapple.setup(grapple_stats)
	_grapple.camera = camera
	_grapple.get_throw().setup(grapple_stats, camera, head, fov)
	_grapple.thrown.connect(_on_thrown)
	_grapple.attached.connect(_on_attached)
	_grapple.detached.connect(_on_detached)
	_grapple.launched.connect(_on_launched)
	_grapple.launched_at_enemy.connect(_on_launched_at_enemy)
	_melee.setup(body, camera, _stats, grapple_stats)
	_melee.hit.connect(_on_melee_hit)
	_predictor.setup(body, _grapple, _stats, camera, gravity)
	_assist.setup(body, _grapple, _predictor, _stats)
	_swing = SwingStep.new(body, _grapple, _assist, gravity, _stats)


func setup_hud(hud: Hud) -> void:
	var module: GrappleHud = HUD_SCENE.instantiate() as GrappleHud
	hud.mount(module)
	module.setup(_grapple, _camera, _predictor, _body, arc_stats, hud.stats)


func begin_frame() -> void:
	var walls: PackedVector3Array = _body.get_walls()
	_grapple.wall_normals = PackedVector3Array([walls[0], walls[1],
			_wall_run.get_normal() if _wall_run.is_active() else Vector3.ZERO])


func move(delta: float, direction: Vector3) -> bool:
	if not _grapple.is_swinging():
		return false
	_strike.stop()
	_swing.step(delta, direction)
	return true


## A launch at an enemy is steered into it; any other flight gets the obstacle assist. A strike only runs in
## momentum flight, so outside it this is always the assist.
func steer_flight(direction: Vector3, delta: float) -> void:
	if _strike.is_active():
		_body.velocity = _strike.steer(_body.velocity, _body.global_position + Vector3.UP * Melee.MID_BODY, direction,
				delta)
		_body.mark_force(&"strike")
	else:
		_body.velocity += _assist.get_acceleration(direction) * delta
		_body.mark_force(&"assist")


func stop_flight_guidance() -> void:
	_strike.stop()


## Firing the hook and the body hit (a dead body coasting into an enemy doesn't punch it).
func set_active(enabled: bool) -> void:
	_melee.set_physics_process(enabled)
	_grapple.set_physics_process(enabled)


func go_down() -> void:
	_grapple.abort()
	_strike.stop()
	_melee.reset()


func game_over() -> void:
	_grapple.get_throw().cancel()


## Nothing is saved: the buttons that held a swing or a throw are rarely still held after a death, so the player
## comes back with the hook put away.
func rewind_restore(_state: Dictionary) -> void:
	_grapple.abort()
	_strike.stop()
	_melee.reset()
	_swing.reset()


func add_playtest_fields(snapshot: Dictionary) -> void:
	snapshot["reel_held"] = Input.is_action_pressed("reel")
	snapshot["strike"] = _strike.is_active()
	if _grapple.get_state() != GrappleHook.State.IDLE:
		snapshot["grapple"] = {
			"state": GrappleHook.State.find_key(_grapple.get_state()),
			"mode": GrappleHook.Mode.find_key(_grapple.get_mode()),
			"anchor": _grapple.get_swing_anchor(),
			"rope_length": _grapple.get_rope_length(),
		}


func _on_attached() -> void:
	playtest_event.emit(&"grapple_attached", {"hit_point": _grapple.get_hit_point()})
	if _grapple.get_mode() == GrappleHook.Mode.SWING:
		_swing.reset()
		# A swing and a wall run are exclusive. Letting go of the swing can latch a wall again at once.
		_wall_run.cancel(false)
	_camera.shake(_feel.grapple_shake)
	if grapple_stats.hit_stop_enabled:
		_hit_stop.trigger(grapple_stats.hit_stop_scale, grapple_stats.hit_stop_time)
	AttachBurst.spawn(get_tree().current_scene, _grapple.get_hit_point(), _grapple.get_hit_normal())


func _on_detached() -> void:
	playtest_event.emit(&"grapple_detached", {})
	_body.keep_momentum()
	_camera.shake(_feel.grapple_shake)


## The launch adds its boost on top of the momentum the player keeps.
func _on_launched(launch_velocity: Vector3) -> void:
	playtest_event.emit(&"launched", {"launch_velocity": launch_velocity})
	_wall_run.cancel() # A launch sends the player flying; it isn't spent running along a wall.
	_body.velocity = _body.velocity * _stats.momentum_carry + launch_velocity
	# Fired while standing, lift off the floor, or a launch aimed slightly down would stop dead on it.
	if _body.is_on_floor() and _body.velocity.y < _stats.launch_ground_lift:
		_body.velocity.y = _stats.launch_ground_lift
	_body.start_launch_flight()


## Launched at an enemy: at the speed a launch straight at it would give (never faster), aimed by StrikeGuidance
## along an arc into it. The launch gravity lasts the whole flight, which the aim assumes. The body hit is armed.
func _on_launched_at_enemy(enemy: Enemy) -> void:
	playtest_event.emit(&"launched_at_enemy", {"enemy": enemy.name, "enemy_center": enemy.get_center()})
	_wall_run.cancel()
	var mid: Vector3 = _body.global_position + Vector3.UP * Melee.MID_BODY
	var toward: Vector3 = (enemy.get_center() - mid).normalized()
	var speed: float = (_body.velocity * _stats.momentum_carry + toward * grapple_stats.launch_speed).length()
	_body.velocity = _strike.start(enemy, mid, speed)
	_body.start_launch_flight(_strike.flight_time(mid, speed) + STRIKE_GRAVITY_MARGIN)
	_melee.arm()


## The punch stops the player nearly dead, so the enemy gets the momentum. The double jump comes back.
func _on_melee_hit(enemy: Enemy, impact_velocity: Vector3) -> void:
	playtest_event.emit(&"melee_hit", {"enemy": enemy.name, "impact_velocity": impact_velocity})
	_strike.stop()
	_body.velocity *= _stats.melee_momentum_keep
	_body.keep_momentum()
	_body.stop_jump_rise()
	_body.refill_double_jump()
	_camera.shake(_feel.grapple_shake)
	if _grapple.get_enemy() == enemy:
		_grapple.release()


## A thrown enemy leaves the rope with a kick, harder for a harder throw.
func _on_thrown(launch_velocity: Vector3, power: float) -> void:
	playtest_event.emit(&"thrown", {"launch_velocity": launch_velocity, "power": power})
	_camera.shake(_feel.grapple_shake * lerpf(0.5, 1.0, power))
