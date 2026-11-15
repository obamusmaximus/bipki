class_name GrappleSfx
extends Node
## Plays the grapple's sound effects. GrappleHook calls the play_* methods directly.
## Each sound gets its own player so that overlapping sounds (a launch's attach and whoosh) don't cut each other off.

var stats: GrappleStats

var _fire_player: AudioStreamPlayer
var _attach_player: AudioStreamPlayer
var _launch_player: AudioStreamPlayer
var _reel_player: AudioStreamPlayer
var _thwip_player: AudioStreamPlayer
var _crack_player: AudioStreamPlayer
var _slowmo_in_player: AudioStreamPlayer
var _slowmo_out_player: AudioStreamPlayer


func _ready() -> void:
	# Fire: a short downward twang from the hook gun.
	_fire_player = _make_player(Synth.make_sound(0.12, 1100.0, 350.0, 0.25, 0.6, 0.002, 3.0))
	# Attach: a low thump as the tip bites into the world.
	_attach_player = _make_player(Synth.make_sound(0.18, 140.0, 60.0, 0.35, 0.9, 0.002, 3.0))
	# Launch: a rising, noisy whoosh.
	_launch_player = _make_player(Synth.make_sound(0.45, 250.0, 900.0, 0.8, 0.5, 0.08, 1.5))
	# Reel: a looping mechanical whirr while the swing rope is being wound in.
	_reel_player = _make_player(Synth.make_loop(0.5, 240.0, 0.4, 0.3))
	# Thwip: a fast, sharp whip for the swing firing and releasing.
	_thwip_player = _make_player(Synth.make_sound(0.1, 1800.0, 250.0, 0.35, 0.7, 0.001, 2.5))
	# Crack: a sharp noisy snap, for a thrown enemy leaving the rope.
	_crack_player = _make_player(Synth.make_sound(0.22, 3200.0, 300.0, 0.9, 0.9, 0.0005, 4.0))
	# Bullet time in and out: a low sweep down as the world slows, and back up as it speeds up.
	_slowmo_in_player = _make_player(Synth.make_sound(0.4, 500.0, 70.0, 0.25, 0.6, 0.01, 1.5))
	_slowmo_out_player = _make_player(Synth.make_sound(0.3, 90.0, 600.0, 0.3, 0.5, 0.01, 1.8))


func setup(grapple_stats: GrappleStats) -> void:
	stats = grapple_stats
	stats.changed.connect(_apply_volume)
	_apply_volume()


func play_fire() -> void:
	_fire_player.play()


func play_attach() -> void:
	_attach_player.play()


func play_launch() -> void:
	_launch_player.play()


func play_thwip() -> void:
	_thwip_player.play()


## The throw's release. A harder throw is louder and a little higher pitched.
func play_crack(power: float) -> void:
	_crack_player.pitch_scale = lerpf(0.8, 1.3, power)
	_crack_player.volume_db = stats.volume_db + lerpf(-6.0, 3.0, power)
	_crack_player.play()


func play_slowmo_in() -> void:
	_slowmo_in_player.play()


func play_slowmo_out() -> void:
	_slowmo_out_player.play()


## Starts the reel loop while the rope is shortening, and stops it otherwise. Safe to call every frame.
func set_reeling(reeling: bool) -> void:
	if reeling:
		if not _reel_player.playing:
			_reel_player.play()
	else:
		_reel_player.stop()


func _apply_volume() -> void:
	for player: AudioStreamPlayer in [_fire_player, _attach_player, _launch_player, _reel_player, _thwip_player,
			_slowmo_in_player, _slowmo_out_player]:
		player.volume_db = stats.volume_db


func _make_player(stream: AudioStreamWAV) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	return player
