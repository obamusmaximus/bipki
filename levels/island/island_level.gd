class_name IslandLevel
extends Node3D
## The island test level for the jetpack: a 100 m box island, its top at ISLAND_TOP, standing in a flat sea at y = 0
## that stretches 500 m out on every side. The island spans 0 to 100 m in x and z, so the arena's grid and scale bars
## sit on its top unchanged. Enemies come from the `EnemySpawner` nodes; this script hands each drone the flight grid
## and the player (a drone a rewind remade too), gives the HUD minimap the island's boxes, applies the look, and
## rewinds the level when the player dies with a life left. The night is lit by `IslandLook` from `night_stats`, the sea by `WaterLook` from `water_stats`.
## The boxes are read from the collision shapes under Island, so the scene stays the one source of geometry.

const ISLAND_TOP: float = 20.0
## Flight grid cell sizes and the margin kept from solids (m).
const GRID_CELL_XZ: float = 4.0
const GRID_CELL_Y: float = 6.0
const GRID_MARGIN: float = 1.5
## How far past the island's edges the flight grid reaches over the water, so fights can move out to sea (m).
const FLIGHT_REACH: float = 60.0
## Open air the flight grid keeps above the island's top (m).
const FLIGHT_HEADROOM: float = 60.0

## The grid's look, shared with the arena.
@export var grid_stats: ArenaStats
## The moonlit night: moon, sky, ambient, fog and warm lamps.
@export var night_stats: NightStats
## The faceted sea: mesh, waves, calm, shading, moon glitter.
@export var water_stats: WaterStats

var flight_grid: FlightGrid

@onready var _player: Player = $Player
@onready var _look: IslandLook = $Look
@onready var _coordinator: AttackCoordinator = $AttackCoordinator
@onready var _rewind: Rewind = $Rewind
@onready var _scale: ArenaScale = $Scale
@onready var _island: StaticBody3D = $Island
@onready var _island_mesh: MeshInstance3D = $Island/Mesh
@onready var _water_shape: CollisionShape3D = $Water/CollisionShape3D
@onready var _water_mesh: MeshInstance3D = $Water/Mesh
@onready var _water_look: WaterLook = $WaterLook
@onready var _world_environment: WorldEnvironment = $WorldEnvironment
@onready var _moon: DirectionalLight3D = $Moon
@onready var _warm_lights: Node3D = $WarmLights


func _ready() -> void:
	var lamps: Array[OmniLight3D] = []
	for child: Node in _warm_lights.get_children():
		if child is OmniLight3D:
			lamps.append(child as OmniLight3D)
	_look.setup(grid_stats, _island_mesh.material_override as ShaderMaterial, night_stats,
			_world_environment.environment, _moon, lamps)
	_scale.setup(grid_stats, true, ISLAND_TOP)
	var island_boxes: Array[AABB] = _box_shapes(_island)
	_water_look.setup(water_stats, _water_mesh, _merged(island_boxes))
	var flight_boxes: Array[AABB] = island_boxes.duplicate()
	flight_boxes.append(_flight_water(island_boxes))
	flight_grid = FlightGrid.from_boxes(flight_boxes, GRID_CELL_XZ, GRID_CELL_Y, GRID_MARGIN, FLIGHT_HEADROOM, 0.0)
	for node: Node in get_tree().get_nodes_in_group(EnemySpawner.GROUP):
		(node as EnemySpawner).spawned.connect(_on_enemy_spawned)
	_player.show_city(island_boxes)
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


## The water's collision box cut down to the island plus FLIGHT_REACH. The flight grid spans exactly this footprint,
## and the water in it blocks the air just above the sea, as the floor does in the arena.
func _flight_water(island_boxes: Array[AABB]) -> AABB:
	var water: AABB = _shape_box(_water_shape)
	var island: AABB = _merged(island_boxes)
	var low := Vector3(island.position.x - FLIGHT_REACH, water.position.y, island.position.z - FLIGHT_REACH)
	var high := Vector3(island.end.x + FLIGHT_REACH, water.end.y, island.end.z + FLIGHT_REACH)
	return AABB(low, high - low).intersection(water)


func _merged(boxes: Array[AABB]) -> AABB:
	var merged: AABB = boxes[0]
	for box: AABB in boxes:
		merged = merged.merge(box)
	return merged


## World-space boxes of every box collision shape under `body`.
func _box_shapes(body: Node) -> Array[AABB]:
	var boxes: Array[AABB] = []
	for child: Node in body.get_children():
		var shape_node: CollisionShape3D = child as CollisionShape3D
		if shape_node != null and shape_node.shape is BoxShape3D:
			boxes.append(_shape_box(shape_node))
	return boxes


func _shape_box(shape_node: CollisionShape3D) -> AABB:
	var size: Vector3 = (shape_node.shape as BoxShape3D).size
	return AABB(shape_node.global_position - size * 0.5, size)
