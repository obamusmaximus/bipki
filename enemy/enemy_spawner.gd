class_name EnemySpawner
extends Marker3D
## Keeps one enemy of `enemy_scene` alive at its own position: spawns it when the level loads and makes a new one
## `SpawnerStats.respawn_delay` seconds after it dies. Place several for several enemies; each runs on its own.
## It doesn't know what kind of enemy it makes. It reports each one with `spawned`, and the level gives it whatever
## it needs (a drone needs the flight grid and a target).

## Group every spawner is in, so a level can find them.
const GROUP: StringName = &"enemy_spawners"

## An enemy has just been added to the tree at the spawner's position.
signal spawned(enemy: Enemy)

@export var enemy_scene: PackedScene
@export var stats: SpawnerStats


func _ready() -> void:
	add_to_group(GROUP)
	# Deferred, so the level has connected to `spawned` before the first enemy appears.
	_spawn.call_deferred()


func _spawn() -> void:
	if enemy_scene == null or not is_inside_tree():
		return
	var enemy: Enemy = enemy_scene.instantiate() as Enemy
	if enemy == null:
		return
	get_parent().add_child(enemy)
	enemy.global_position = global_position
	enemy.died.connect(_on_enemy_died)
	spawned.emit(enemy)


func _on_enemy_died() -> void:
	# Real time (ignore_time_scale), so a death in bullet time doesn't stretch the delay.
	await get_tree().create_timer(stats.respawn_delay, true, false, true).timeout
	_spawn()
