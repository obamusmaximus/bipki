class_name JetMotor
extends Node
## The jetpack (see docs/mechanics/jet.md). A tap of the jet key toggles HOVER: low gravity in the air and WASD strafing
## at a set speed. Holding it with a movement key SURGEs: a flat boost along the keys relative to the look, which turns
## into the AFTERBURNER after a while of forward-only surging. Thrust burns fuel. Owned by JetLoadout, which calls
## `tick` at the start of each frame and `move` in Player's movement slot; the motor moves the body itself then.

## Hover was switched on or off.
signal hover_changed(on: bool)
## The thrust changed (a `Thrust` value).
signal thrust_changed(thrust: int)

enum Thrust { OFF, SURGE, AFTERBURNER }

var stats: JetStats

var _body: Player
var _player_stats: PlayerStats
var _camera: Camera3D
var _gravity: BodyGravity
var _wall_run: WallRun

var _hovering: bool = false
var _thrust: Thrust = Thrust.OFF
## Seconds of thrust left in the tank.
var _fuel: float = 0.0
## Seconds before the tank starts refilling.
var _refill_wait: float = 0.0
## The jet key is down, and has been for `_held_time` seconds.
var _held: bool = false
var _held_time: float = 0.0
## This press became a hold: letting go doesn't toggle hover.
var _hold_used: bool = false
## The tank ran dry during this press: no more thrust until the key is pressed again.
var _dry: bool = false
## Seconds of forward-only surging, toward the afterburner.
var _forward_time: float = 0.0
## The surge started this frame: `move` sets its speed outright.
var _fresh: bool = false
## Afterburner momentum still carried: hover doesn't brake it down to its strafe speed.
var _carry: bool = false
var _active: bool = true


func setup(body: Player, camera: Camera3D, gravity: BodyGravity, wall_run: WallRun, jet_stats: JetStats) -> void:
	_body = body
	_player_stats = body.stats
	_camera = camera
	_gravity = gravity
	_wall_run = wall_run
	stats = jet_stats
	_fuel = stats.fuel_seconds
	_wall_run.started.connect(_on_wall_run_started.unbind(1))


func is_hovering() -> bool:
	return _hovering


func get_thrust() -> Thrust:
	return _thrust


## True while the afterburner burns: the loadout's other abilities are locked out.
func is_afterburning() -> bool:
	return _thrust == Thrust.AFTERBURNER


## How far a held jet key is toward starting a surge, 0 to 1 (1 once it has been held long enough, until it surges).
## 0 when the key isn't held, while thrusting, and after the tank ran dry.
func get_hold_ratio() -> float:
	if not _held or _dry or _thrust != Thrust.OFF:
		return 0.0
	return clampf(_held_time / maxf(stats.surge_hold_time, 0.01), 0.0, 1.0)


## Share of the tank left, 0 to 1.
func get_fuel_ratio() -> float:
	return clampf(_fuel / maxf(stats.fuel_seconds, 0.01), 0.0, 1.0)


## Start of each live physics frame: reads the jet key, starts and ends thrust, burns and refills fuel.
func tick(delta: float) -> void:
	if not _active:
		return
	if Input.is_action_just_pressed("jet"):
		_held = true
		_held_time = 0.0
		_hold_used = false
		_dry = false
	if _held and not Input.is_action_pressed("jet"):
		_held = false
		if not _hold_used:
			_set_hover(not _hovering)
		_set_thrust(Thrust.OFF)
	if _held:
		_held_time += delta
		if _held_time >= stats.surge_hold_time:
			_hold_used = true
			_update_thrust(delta)
	_refill(delta)
	if _body.is_on_floor() and _body.velocity.y <= 0.0:
		_carry = false


## The motor's movement for this frame: thrust anywhere, hover in the air. Returns false to let Player move the body.
func move(delta: float, direction: Vector3) -> bool:
	if _thrust != Thrust.OFF:
		_step_thrust(delta)
		return true
	if _hovering and not _body.is_on_floor():
		_step_hover(delta, direction)
		return true
	return false


## Input off (dead, waiting for the rewind): thrust stops, and the key must be pressed again afterwards.
func set_active(enabled: bool) -> void:
	_active = enabled
	if not enabled:
		_held = false
		_set_thrust(Thrust.OFF, false)


func rewind_capture() -> Dictionary:
	return {
		&"hovering": _hovering,
		&"fuel": _fuel,
		&"refill_wait": _refill_wait,
		&"carry": _carry,
	}


## Thrust isn't saved: the key is rarely still held after a death, so the player comes back coasting.
func rewind_restore(state: Dictionary) -> void:
	_held = false
	_forward_time = 0.0
	_set_thrust(Thrust.OFF, false)
	_set_hover(state[&"hovering"], false)
	_fuel = state[&"fuel"]
	_refill_wait = state[&"refill_wait"]
	_carry = state[&"carry"]


## Held past the surge time: thrust along the keys while there is fuel, nothing without a movement key.
func _update_thrust(delta: float) -> void:
	var direction: Vector3 = _thrust_direction()
	if direction.is_zero_approx() or _dry:
		_forward_time = 0.0
		_set_thrust(Thrust.OFF)
		return
	if _thrust == Thrust.OFF:
		_fresh = true
		_set_thrust(Thrust.SURGE)
		_wall_run.cancel() # A surge takes the body off the wall.
	if _thrust == Thrust.SURGE:
		var forward_only: bool = Input.is_action_pressed("move_forward") and not Input.is_action_pressed("move_back")
		_forward_time = _forward_time + delta if forward_only else 0.0
		if _forward_time >= stats.afterburner_delay:
			_set_thrust(Thrust.AFTERBURNER)
	_fuel -= delta
	if _fuel <= 0.0:
		_fuel = 0.0
		_dry = true
		_set_thrust(Thrust.OFF)


## The movement keys turned into a direction relative to the look, pitch included: W flies where the camera points.
func _thrust_direction() -> Vector3:
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input.is_zero_approx():
		return Vector3.ZERO
	return (_camera.global_basis * Vector3(input.x, 0.0, input.y)).normalized()


## Surge holds `surge_speed` along the keys. The afterburner accelerates toward `afterburner_speed`, against a drag
## that grows with the square of the speed, so it levels off there softly. Both turn with the look; no gravity.
func _step_thrust(delta: float) -> void:
	var body: Player = _body
	_gravity.end_launch()
	body.stop_jump_rise()
	var direction: Vector3 = _thrust_direction()
	if _thrust == Thrust.SURGE:
		var target: Vector3 = direction * stats.surge_speed
		if _fresh:
			body.velocity = target
		else:
			body.velocity = body.velocity.move_toward(target, stats.surge_steer_accel * delta)
		body.mark_force(&"surge")
	else:
		var speed: float = body.velocity.length()
		var top: float = maxf(stats.afterburner_speed, 1.0)
		speed += stats.afterburner_accel * (1.0 - (speed / top) * (speed / top)) * delta
		body.velocity = body.velocity.move_toward(direction * speed, stats.surge_steer_accel * delta)
		body.mark_force(&"afterburner")
	_fresh = false
	body.move_and_slide()
	body.mark_force(&"collision")
	body.set_walking(false)


## Low gravity, the vertical speed settling, and WASD driving the horizontal speed toward `hover_strafe_speed`
## (braking any faster momentum down to it), unless afterburner momentum is still being carried: then it flies on as
## momentum flight until it has slowed to the strafe speed. Can latch a wall run like any flight.
func _step_hover(delta: float, direction: Vector3) -> void:
	var body: Player = _body
	_gravity.end_launch()
	body.stop_jump_rise()
	var velocity: Vector3 = body.velocity
	velocity.y -= _gravity.air(velocity.y) * stats.hover_gravity_scale * delta
	velocity.y /= 1.0 + stats.hover_vertical_damping * delta
	body.velocity = velocity
	body.mark_force(&"gravity")
	var flat := Vector2(velocity.x, velocity.z)
	if _carry and flat.length() > stats.hover_strafe_speed:
		body.velocity = Steering.air(body.velocity, direction, delta, _player_stats)
		body.mark_force(&"steering")
		body.velocity = AirDrag.apply(body.velocity, delta, _player_stats)
		body.mark_force(&"drag")
		body.velocity = SoftSpeedLimit.apply(body.velocity, delta, _player_stats)
		body.mark_force(&"soft_limit")
	else:
		_carry = false
		flat = flat.move_toward(Vector2(direction.x, direction.z) * stats.hover_strafe_speed,
				stats.hover_strafe_accel * delta)
		body.velocity.x = flat.x
		body.velocity.z = flat.y
		body.mark_force(&"hover")
	var velocity_before: Vector3 = body.velocity
	body.move_and_slide()
	body.mark_force(&"collision")
	_wall_run.try_start(velocity_before)
	body.set_walking(false)


func _refill(delta: float) -> void:
	if _thrust != Thrust.OFF:
		return
	if _refill_wait > 0.0:
		_refill_wait -= delta
		return
	_fuel = minf(_fuel + stats.fuel_seconds / maxf(stats.fuel_refill_time, 0.01) * delta, stats.fuel_seconds)


## A wall run always switches hover off: leaving the wall is momentum flight, and a tap switches hover back on.
func _on_wall_run_started() -> void:
	_set_hover(false)


## Hover off in the air keeps the momentum (Player's momentum flight takes over).
func _set_hover(on: bool, report: bool = true) -> void:
	if on == _hovering:
		return
	_hovering = on
	if not on and not _body.is_on_floor():
		_body.keep_momentum()
	if report:
		hover_changed.emit(on)


## Thrust ending hands the body back: momentum flight with hover off, the hover with it on (which brakes a surge's
## speed, but not the afterburner's). `hand_back` false is for a death or a rewind, where nothing is carried on.
func _set_thrust(thrust: Thrust, hand_back: bool = true) -> void:
	if thrust == _thrust:
		return
	var old: Thrust = _thrust
	_thrust = thrust
	if thrust == Thrust.OFF:
		_forward_time = 0.0
		_refill_wait = stats.fuel_refill_delay
		if hand_back:
			if old == Thrust.AFTERBURNER:
				_carry = true
			if not _hovering:
				_body.keep_momentum()
	thrust_changed.emit(thrust)
