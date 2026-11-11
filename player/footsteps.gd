class_name Footsteps
extends Node
## Plays a footstep sound at a steady interval while the player walks on the ground.
## Player calls set_walking() each physics frame. Steps are synthesized in code (see Synth).

## Steps per second while walking (1.75x the old 1 / 0.45 s). A walking animation should read this
## so its footfalls stay in sync with the sound.
@export var steps_per_second: float = 1.75 / 0.45
@export var volume_db: float = -10.0

var _walking: bool = false
var _timer: float = 0.0
var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.stream = Synth.make_sound(0.09, 110.0, 60.0, 0.9, 0.7, 0.002, 4.0)
	_player.volume_db = volume_db
	add_child(_player)


## Seconds between steps while walking.
func get_step_interval() -> float:
	return 1.0 / steps_per_second


func set_walking(walking: bool) -> void:
	_walking = walking


func _physics_process(delta: float) -> void:
	if not _walking:
		_timer = 0.0 # The next walk starts with a step straight away.
		return

	_timer -= delta
	if _timer <= 0.0:
		_player.pitch_scale = randf_range(0.85, 1.15) # Vary each step a little so they don't sound identical.
		_player.play()
		_timer = get_step_interval()
