class_name JetSfx
extends Node
## The jetpack's sounds, synthesized like the grapple's (Synth): a faint hum while hovering in the air; while thrusting
## a rushing roar over a bass rumble (both pitched up for the afterburner); and an ignition whoosh with a low thump when
## a surge starts. JetLoadout drives it. Levels are in JetStats ("Sound").

var stats: JetStats

var _hum_player: AudioStreamPlayer
var _thrust_player: AudioStreamPlayer
var _ignite_player: AudioStreamPlayer
var _bass_player: AudioStreamPlayer
var _thump_player: AudioStreamPlayer


func _ready() -> void:
	# Hum: a low, soft rumble, mostly filtered noise.
	_hum_player = _make_player(Synth.make_loop(1.0, 70.0, 0.75, 0.35))
	# Thrust: a rough roar (kept low, it clips above this), with a bass rumble under it for the rocket's weight.
	_thrust_player = _make_player(Synth.make_loop(0.5, 110.0, 0.9, 0.3))
	_bass_player = _make_player(Synth.make_rumble(1.0, 42.0, 0.55, 0.9))
	# Ignition: a short rising whoosh over a low thump.
	_ignite_player = _make_player(Synth.make_sound(0.35, 180.0, 700.0, 0.85, 0.5, 0.01, 2.0))
	_thump_player = _make_player(Synth.make_sound(0.5, 95.0, 38.0, 0.15, 0.9, 0.004, 2.5))


func setup(jet_stats: JetStats) -> void:
	stats = jet_stats
	stats.changed.connect(_apply_volume)
	_apply_volume()


## The loops follow the motor's state. Safe to call every frame.
func update(humming: bool, thrust: JetMotor.Thrust) -> void:
	_set_looping(_hum_player, humming and thrust == JetMotor.Thrust.OFF)
	var thrusting: bool = thrust != JetMotor.Thrust.OFF
	_set_looping(_thrust_player, thrusting)
	_set_looping(_bass_player, thrusting)
	var pitch: float = 1.3 if thrust == JetMotor.Thrust.AFTERBURNER else 1.0
	_thrust_player.pitch_scale = pitch
	_bass_player.pitch_scale = lerpf(1.0, pitch, 0.5) # The bass rises less, so it stays heavy.


func play_ignite() -> void:
	_ignite_player.play()
	_thump_player.play()


func stop_all() -> void:
	for player: AudioStreamPlayer in [_hum_player, _thrust_player, _bass_player, _ignite_player, _thump_player]:
		player.stop()


func _set_looping(player: AudioStreamPlayer, on: bool) -> void:
	if on and not player.playing:
		player.play()
	elif not on and player.playing:
		player.stop()


func _apply_volume() -> void:
	var thrust_db: float = stats.volume_db - stats.thrust_quieter_db
	_thrust_player.volume_db = thrust_db
	_ignite_player.volume_db = thrust_db
	_bass_player.volume_db = thrust_db + stats.thrust_bass_db
	_thump_player.volume_db = thrust_db + stats.thrust_bass_db
	_hum_player.volume_db = stats.volume_db - stats.hover_hum_quieter_db


func _make_player(stream: AudioStreamWAV) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	return player
