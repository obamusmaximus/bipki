class_name DroneSfx
extends Node3D
## The drone's sounds, made in code and played from the drone's position: a rising charge whine, a
## blip when the aim locks, and the beam's zap.

@export var volume_db: float = 0.0
@export var max_distance: float = 300.0

var _charge: AudioStreamPlayer3D
var _lock: AudioStreamPlayer3D
var _zap: AudioStreamPlayer3D


func setup(beam: BeamAttack) -> void:
	beam.charge_started.connect(_charge.play)
	beam.aim_started.connect(func(_latched: Vector3) -> void: _lock.play())
	beam.fired.connect(func(_from: Vector3, _to: Vector3, _hit: bool) -> void: _zap.play())


func _ready() -> void:
	# Charge: a tone sweeping up over the 1.5 s charge, getting louder as it goes.
	_charge = _make_player(Synth.make_sound(1.5, 180.0, 1600.0, 0.15, 0.6, 1.3, 0.05))
	# Lock: a short high blip so the player knows the aim is set.
	_lock = _make_player(Synth.make_sound(0.15, 1400.0, 1400.0, 0.0, 0.5, 0.002, 2.0))
	# Zap: a fast downward sweep with plenty of noise.
	_zap = _make_player(Synth.make_sound(0.5, 2200.0, 70.0, 0.55, 0.9, 0.002, 2.0))


func _make_player(stream: AudioStreamWAV) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.unit_size = 25.0
	player.max_distance = max_distance
	add_child(player)
	return player
