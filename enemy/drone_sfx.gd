class_name DroneSfx
extends Node3D
## The drone's sounds, made in code and played from the drone's position: a rising charge whine, a
## blip when the aim locks, and the beam's zap.

var stats: DroneStats

var _charge: AudioStreamPlayer3D
var _lock: AudioStreamPlayer3D
var _zap: AudioStreamPlayer3D
## The charge time the charge whine was built for. The whine is rebuilt when the stats change it.
var _built_charge_time: float = 0.0


func setup(beam: BeamAttack, drone_stats: DroneStats) -> void:
	stats = drone_stats
	_charge = _make_player(_make_charge_sound())
	# Lock: a short high blip so the player knows the aim is set.
	_lock = _make_player(Synth.make_sound(0.15, 1400.0, 1400.0, 0.0, 0.5, 0.002, 2.0))
	# Zap: a fast downward sweep with plenty of noise.
	_zap = _make_player(Synth.make_sound(0.5, 2200.0, 70.0, 0.55, 0.9, 0.002, 2.0))
	stats.changed.connect(_on_stats_changed)
	beam.charge_started.connect(func() -> void: _charge.play())
	beam.aim_started.connect(func(_latched: Vector3) -> void: _lock.play())
	beam.fired.connect(func(_from: Vector3, _to: Vector3, _hit: bool) -> void: _zap.play())


## Charge: a tone sweeping up over the charge time, getting louder as it goes.
func _make_charge_sound() -> AudioStreamWAV:
	_built_charge_time = stats.charge_time
	return Synth.make_sound(_built_charge_time, 180.0, 1600.0, 0.15, 0.6, 1.3, 0.05)


func _on_stats_changed() -> void:
	if not is_equal_approx(_built_charge_time, stats.charge_time):
		_charge.stream = _make_charge_sound()
	for player: AudioStreamPlayer3D in [_charge, _lock, _zap]:
		player.volume_db = stats.volume_db
		player.max_distance = stats.max_distance


func _make_player(stream: AudioStreamWAV) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = stats.volume_db
	player.unit_size = 25.0
	player.max_distance = stats.max_distance
	add_child(player)
	return player
