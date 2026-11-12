class_name Footsteps
extends Node
## Plays a footstep sound at a steady interval while the player walks on the ground.
## Player calls set_walking() each physics frame. Steps are synthesized in code (see Synth).

var stats: PlayerStats

var _walking: bool = false
var _timer: float = 0.0
var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.stream = Synth.make_sound(0.09, 110.0, 60.0, 0.9, 0.7, 0.002, 4.0)
	add_child(_player)


func setup(player_stats: PlayerStats) -> void:
	stats = player_stats
	stats.changed.connect(_apply_volume)
	_apply_volume()


func _apply_volume() -> void:
	_player.volume_db = stats.footsteps_volume_db


## Seconds between steps while walking.
func get_step_interval() -> float:
	return 1.0 / stats.steps_per_second


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
