class_name SpawnerStats
extends Resource
## Tunable numbers for `EnemySpawner`. One .tres per preset (tuning/spawner_default.tres). Every spawner holds one in
## `stats`; spawners that share a .tres share its edits. The debug tuning panel edits these live.

@export_group("Respawn")
## Seconds after the spawner's enemy dies before it makes the next one. Real seconds: bullet time doesn't stretch it.
@export var respawn_delay: float = 3.0
