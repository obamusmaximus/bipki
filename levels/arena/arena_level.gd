class_name ArenaLevel
extends Node3D
## The testing arena: a 100 m white box with black grid and scale bars on all six surfaces and a 5 m pillar from floor to
## ceiling. The world origin is a bottom corner of the box, so the room runs 0 to 100 m on every axis. Hand-built. Enemies come from the `EnemySpawner` nodes placed in the scene;
## this script hands each drone the flight grid and the player (a drone a rewind remade too), gives the HUD minimap the
## solid boxes, applies the look, and rewinds the level when the player dies with a life left.
## The boxes are read from the collision shapes under Room and Pillar, so the scene stays the one source of geometry.

## Flight grid cell sizes and the margin kept from solids (m).
const GRID_CELL_XZ: float = 4.0
const GRID_CELL_Y: float = 6.0
const GRID_MARGIN: float = 1.5

@export var stats: ArenaStats

var flight_grid: FlightGrid

@onready var _player: Player = $Player
@onready var _look: ArenaLook = $Look
@onready var _coordinator: AttackCoordinator = $AttackCoordinator
@onready var _rewind: Rewind = $Rewind
@onready var _scale: ArenaScale = $Scale
@onready var _light: DirectionalLight3D = $Light
@onready var _grid_mesh: MeshInstance3D = $Room/Grid
@onready var _pillar_mesh: MeshInstance3D = $Pillar/Mesh
@onready var _world_environment: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	_look.setup(stats, _grid_mesh.material_override as ShaderMaterial,
			_pillar_mesh.material_override as StandardMaterial3D, _world_environment.environment, _light)
	_scale.setup(stats)
	var boxes: Array[AABB] = _solid_boxes()
	flight_grid = FlightGrid.from_boxes(boxes, GRID_CELL_XZ, GRID_CELL_Y, GRID_MARGIN, 0.0)
	for node: Node in get_tree().get_nodes_in_group(EnemySpawner.GROUP):
		(node as EnemySpawner).spawned.connect(_on_enemy_spawned)
	_player.show_city(boxes)
	_player.rewind_requested.connect(_rewind.rewind)
	_rewind.recreated.connect(_on_rewind_recreated)


func _on_rewind_recreated(node: Node) -> void:
	var enemy: Enemy = node as Enemy
	if enemy != null:
		_on_enemy_spawned(enemy)


func _on_enemy_spawned(enemy: Enemy) -> void:
	var drone: Drone = enemy as Drone
	if drone != null:
		drone.setup(flight_grid, _player, _coordinator)


## World-space boxes of every box collision shape under the room and the pillar.
func _solid_boxes() -> Array[AABB]:
	var boxes: Array[AABB] = []
	for body: Node in [$Room, $Pillar]:
		for child: Node in body.get_children():
			var shape_node: CollisionShape3D = child as CollisionShape3D
			if shape_node == null or not shape_node.shape is BoxShape3D:
				continue
			var size: Vector3 = (shape_node.shape as BoxShape3D).size
			boxes.append(AABB(shape_node.global_position - size * 0.5, size))
	return boxes
