class_name Loadout
extends Node3D
## One set of abilities the player plays with, swapped as a whole (GrappleLoadout; see docs/mechanics/loadouts.md).
## Player keeps what every loadout shares (walking, jumping, momentum flight, wall run, health, lives, the camera)
## and calls into its loadout at fixed points of its physics frame. The loadout moves the body through Player's
## loadout API and reports with signals. Its HUD is a LoadoutHud mounted into the Hud's anchor groups.
## Child of Player, made from `Player.loadout_scene`. Every method here is a no-op default.

## Debug: a moment worth seeing in the playtest log. Player re-emits it as its own `playtest_event`.
@warning_ignore("unused_signal")
signal playtest_event(event: StringName, data: Dictionary)


## Called once by Player after its own parts are set up, with the shared parts the loadout may use.
func setup(_body: Player, _camera: ShakeCamera, _head: HeadLook, _fov: DynamicFov, _gravity: BodyGravity,
		_wall_run: WallRun) -> void:
	pass


## Builds the loadout's HUD module, mounts it into `hud` and sets it up.
func setup_hud(_hud: Hud) -> void:
	pass


## Start of each live physics frame, before anything moves.
func begin_frame() -> void:
	pass


## A movement state of the loadout's own (a swing). Moves the body for this frame and returns true, or returns false
## to let Player move it. Not called during a wall run.
func move(_delta: float, _direction: Vector3) -> bool:
	return false


## Steering help in the air, on top of Player's air steering (obstacle assist, a guided launch). Changes the body's
## velocity directly and marks it in the force ledger.
func steer_flight(_direction: Vector3, _delta: float) -> void:
	pass


## The flight ended on a wall run or a landing: stop any guidance.
func stop_flight_guidance() -> void:
	pass


## Input and the per-frame parts on or off (off while dead and waiting for the rewind).
func set_active(_enabled: bool) -> void:
	pass


## A death that rewinds: put everything away until the restore.
func go_down() -> void:
	pass


## The last life is gone.
func game_over() -> void:
	pass


## The loadout's part of the player's rewind snapshot (see `Rewind`).
func rewind_capture() -> Dictionary:
	return {}


func rewind_restore(_state: Dictionary) -> void:
	pass


## Debug: adds the loadout's fields to the player's playtest snapshot (debug/playtest_log/).
func add_playtest_fields(_snapshot: Dictionary) -> void:
	pass
