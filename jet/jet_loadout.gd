class_name JetLoadout
extends Loadout
## The jetpack loadout: hover and surge with the afterburner (JetMotor), with its sounds (JetSfx), and tracking
## (Tracking: the enemies the weapons aim at), and the seeker shotgun (SeekerShotgun). Its HUD is JetHud. Weapons
## check `abilities_locked` (the afterburner locks them out). Detail in docs/mechanics/jet.md.

const HUD_SCENE: PackedScene = preload("res://jet/hud/jet_hud.tscn")

## Tunable numbers (see the stats resources in tuning/). Edited live from the pause menu's tuning panel.
@export var jet_stats: JetStats
@export var tracking_stats: TrackingStats
@export var seeker_shotgun_stats: SeekerShotgunStats

var _body: Player
var _fov: DynamicFov
var _camera: Camera3D

@onready var _motor: JetMotor = $JetMotor
@onready var _sfx: JetSfx = $JetSfx
@onready var _tracking: Tracking = $Tracking
@onready var _shotgun: SeekerShotgun = $SeekerShotgun


func setup(body: Player, camera: ShakeCamera, _head: HeadLook, fov: DynamicFov, gravity: BodyGravity,
		wall_run: WallRun, _hand: Node3D) -> void:
	_body = body
	_fov = fov
	_camera = camera
	_motor.setup(body, camera, gravity, wall_run, jet_stats)
	_tracking.setup(camera, _motor, tracking_stats)
	_tracking.tracks_changed.connect(_on_tracks_changed)
	_shotgun.setup(camera, _tracking, seeker_shotgun_stats)
	_shotgun.fired.connect(_on_shotgun_fired)
	_motor.hover_changed.connect(_on_hover_changed)
	_motor.thrust_changed.connect(_on_thrust_changed)
	_sfx.setup(jet_stats)


func setup_hud(hud: Hud) -> void:
	var module: JetHud = HUD_SCENE.instantiate() as JetHud
	hud.mount(module)
	module.setup(_motor, _tracking, _camera, hud, hud.stats)


## True while the afterburner burns: the loadout's other abilities (the weapons) don't fire.
func abilities_locked() -> bool:
	return _motor.is_afterburning()


func begin_frame() -> void:
	var delta: float = get_physics_process_delta_time()
	_motor.tick(delta)
	_tracking.tick(delta)
	_shotgun.tick(delta, not abilities_locked())
	_sfx.update(_motor.is_hovering() and not _body.is_on_floor(), _motor.get_thrust())


func move(delta: float, direction: Vector3) -> bool:
	return _motor.move(delta, direction)


func set_active(enabled: bool) -> void:
	_motor.set_active(enabled)
	_tracking.set_active(enabled)
	_shotgun.set_active(enabled)


func go_down() -> void:
	_motor.set_active(false)
	_tracking.set_active(false)
	_tracking.clear()
	_shotgun.set_active(false)
	_shotgun.clear()
	_sfx.stop_all()


func game_over() -> void:
	_sfx.stop_all()


func rewind_capture() -> Dictionary:
	return _motor.rewind_capture()


func rewind_restore(state: Dictionary) -> void:
	_motor.rewind_restore(state)
	_tracking.rewind_restore()
	_shotgun.clear()


func add_playtest_fields(snapshot: Dictionary) -> void:
	snapshot["jet"] = {
		"hover": _motor.is_hovering(),
		"thrust": JetMotor.Thrust.find_key(_motor.get_thrust()),
		"fuel": _motor.get_fuel_ratio(),
		"tracks": _tracking.get_targets().size(),
	}


func _on_tracks_changed(targets: Array[Enemy]) -> void:
	var names: PackedStringArray = PackedStringArray()
	for enemy: Enemy in targets:
		names.append(enemy.name)
	playtest_event.emit(&"tracks", {"targets": names})


func _on_shotgun_fired(targets: Array[Enemy]) -> void:
	var names: PackedStringArray = PackedStringArray()
	for enemy: Enemy in targets:
		names.append(enemy.name if enemy != null else "-")
	playtest_event.emit(&"shot", {"pellets": names})


func _on_hover_changed(on: bool) -> void:
	playtest_event.emit(&"hover", {"on": on})


func _on_thrust_changed(thrust: int) -> void:
	playtest_event.emit(&"thrust", {"thrust": JetMotor.Thrust.find_key(thrust), "velocity": _body.velocity})
	if thrust == JetMotor.Thrust.SURGE or thrust == JetMotor.Thrust.AFTERBURNER:
		_fov.kick(jet_stats.surge_fov_kick)
	if thrust == JetMotor.Thrust.SURGE:
		_sfx.play_ignite()
