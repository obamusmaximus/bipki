class_name GrappleSfx
extends Node
## Plays the grapple's sound effects. GrappleHook calls the play_* methods directly.
## Each sound gets its own player so that overlapping sounds (a launch's attach and whoosh) don't cut each other off.

@export var volume_db: float = -6.0

var _fire_player: AudioStreamPlayer
var _attach_player: AudioStreamPlayer
var _launch_player: AudioStreamPlayer
var _detach_player: AudioStreamPlayer
var _pull_player: AudioStreamPlayer
var _thwip_player: AudioStreamPlayer


func _ready() -> void:
	# Fire: a short downward twang from the hook gun.
	_fire_player = _make_player(Synth.make_sound(0.12, 1100.0, 350.0, 0.25, 0.6, 0.002, 3.0))
	# Attach: a low thump as the tip bites into the world.
	_attach_player = _make_player(Synth.make_sound(0.18, 140.0, 60.0, 0.35, 0.9, 0.002, 3.0))
	# Launch: a rising, noisy whoosh.
	_launch_player = _make_player(Synth.make_sound(0.45, 250.0, 900.0, 0.8, 0.5, 0.08, 1.5))
	# Detach: a short, bright tick.
	_detach_player = _make_player(Synth.make_sound(0.05, 1500.0, 1500.0, 0.1, 0.4, 0.001, 4.0))
	# Pull: a looping rushing hum while the player is being reeled in.
	_pull_player = _make_player(Synth.make_loop(1.0, 180.0, 0.7, 0.35))
	# Thwip: a fast, sharp whip for the swing firing and releasing.
	_thwip_player = _make_player(Synth.make_sound(0.1, 1800.0, 250.0, 0.35, 0.7, 0.001, 2.5))


func play_fire() -> void:
	_fire_player.play()


func play_attach() -> void:
	_attach_player.play()


func play_launch() -> void:
	_launch_player.play()


func play_detach() -> void:
	_detach_player.play()


func play_thwip() -> void:
	_thwip_player.play()


## Starts the pull hum. Safe to call while it is already playing.
func start_pull() -> void:
	if not _pull_player.playing:
		_pull_player.play()


func stop_pull() -> void:
	_pull_player.stop()


func _make_player(stream: AudioStreamWAV) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	return player
