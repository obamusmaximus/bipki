class_name EnemySpawner
extends Marker3D
## Keeps one enemy of `enemy_scene` alive at its own position: spawns it when the level loads and makes a new one
## `SpawnerStats.respawn_delay` seconds after it dies. Place several for several enemies; each runs on its own.
## It doesn't know what kind of enemy it makes. It reports each one with `spawned`, and the level gives it whatever
## it needs (a drone needs the flight grid and a target).
## It takes part in a rewind (see `Rewind`): its enemy (by rewind id) and the respawn countdown go back too.

## Group every spawner is in, so a level can find them.
const GROUP: StringName = &"enemy_spawners"

## An enemy has just been added to the tree at the spawner's position.
signal spawned(enemy: Enemy)

@export var enemy_scene: PackedScene
@export var stats: SpawnerStats

var _enemy: Enemy
## Real seconds until the next spawn, or negative when none is due.
var _respawn_left: float = -1.0


func _ready() -> void:
	add_to_group(GROUP)
	add_to_group(Rewind.GROUP)
	# Deferred, so the level has connected to `spawned` before the first enemy appears.
	_spawn.call_deferred()


func _physics_process(delta: float) -> void:
	if _respawn_left < 0.0:
		return
	# Real time, so a death in bullet time doesn't stretch the delay.
	_respawn_left -= delta / maxf(Engine.time_scale, 0.001)
	if _respawn_left <= 0.0:
		_respawn_left = -1.0
		_spawn()


func rewind_capture() -> Dictionary:
	var enemy_id: int = _enemy.get_meta(Rewind.ID_META, 0) if is_instance_valid(_enemy) else 0
	return {&"enemy": enemy_id, &"respawn_left": _respawn_left}


## The enemy in the snapshot is back (restored or remade by the rewind); its death is watched again.
func rewind_restore(saved: Dictionary, rewind: Rewind) -> void:
	_watch(rewind.find(saved[&"enemy"]) as Enemy)
	_respawn_left = saved[&"respawn_left"]


func _spawn() -> void:
	if enemy_scene == null or not is_inside_tree():
		return
	var enemy: Enemy = enemy_scene.instantiate() as Enemy
	if enemy == null:
		return
	get_parent().add_child(enemy)
	enemy.global_position = global_position
	_watch(enemy)
	spawned.emit(enemy)


func _watch(enemy: Enemy) -> void:
	if is_instance_valid(_enemy) and _enemy != enemy and _enemy.died.is_connected(_on_enemy_died):
		_enemy.died.disconnect(_on_enemy_died)
	_enemy = enemy
	if _enemy != null and not _enemy.died.is_connected(_on_enemy_died):
		_enemy.died.connect(_on_enemy_died)


func _on_enemy_died() -> void:
	_enemy = null
	_respawn_left = stats.respawn_delay
