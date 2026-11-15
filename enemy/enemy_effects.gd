class_name EnemyEffects
extends RefCounted
## Burst and sound effects for enemies being hit and destroyed. Placeholder looks and synthesized sounds,
## spawned into the scene and freed on their own.

const IMPACT_FULL_SPEED: float = 60.0

static var _impact_sound: AudioStreamWAV
static var _death_sound: AudioStreamWAV


## A spark burst and a crunch where a thrown enemy hit a surface. `strength` is the impact speed in m/s.
static func impact(scene: Node, point: Vector3, normal: Vector3, speed: float) -> void:
	if scene == null or speed < 2.0:
		return
	AttachBurst.spawn(scene, point, normal)
	if _impact_sound == null:
		_impact_sound = Synth.make_sound(0.3, 220.0, 50.0, 0.6, 0.9, 0.001, 2.5)
	_play_at(scene, point, _impact_sound, lerpf(-12.0, 2.0, clampf(speed / IMPACT_FULL_SPEED, 0.0, 1.0)))


## A bigger burst and a boom where an enemy was destroyed.
static func death(scene: Node, point: Vector3) -> void:
	if scene == null:
		return
	for direction: Vector3 in [Vector3.UP, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		AttachBurst.spawn(scene, point, direction)
	if _death_sound == null:
		_death_sound = Synth.make_sound(0.7, 160.0, 35.0, 0.7, 1.0, 0.001, 2.0)
	_play_at(scene, point, _death_sound, 4.0)


static func _play_at(scene: Node, point: Vector3, stream: AudioStreamWAV, volume_db: float) -> void:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.max_distance = 300.0
	player.finished.connect(player.queue_free)
	scene.add_child(player)
	player.global_position = point
	player.play()
