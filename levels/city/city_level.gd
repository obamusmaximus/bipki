class_name CityLevel
extends Node3D
## The city level: once the city is built, adds `random_drones` drones at random open spots, hands every
## flying enemy the city's open-air grid (a drone a rewind remade too), and the HUD minimap the building boxes, and
## rewinds the level when the player dies with a life left.

## A random drone never starts nearer than this to the player (m).
const MIN_SPAWN_DISTANCE: float = 60.0
const SPAWN_TRIES: int = 30

## Drones added at random points of the city when the level loads, on top of the ones placed in the scene.
@export var random_drones: int = 0
@export var drone_scene: PackedScene

@onready var _generator: CityGenerator = $CityGenerator
@onready var _player: Player = $Player
@onready var _coordinator: AttackCoordinator = $AttackCoordinator
@onready var _rewind: Rewind = $Rewind


func _ready() -> void:
	_spawn_random_drones()
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		_wire_enemy(node)
	_player.show_city(_generator.building_boxes)
	_player.rewind_requested.connect(_rewind.rewind)
	_rewind.recreated.connect(_wire_enemy)


func _wire_enemy(node: Node) -> void:
	var drone: Drone = node as Drone
	if drone != null:
		drone.setup(_generator.flight_grid, _player, _coordinator)


func _spawn_random_drones() -> void:
	if drone_scene == null or _generator.flight_grid == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i: int in random_drones:
		var spot: Vector3 = _random_spot(rng)
		if spot == Vector3.INF:
			continue
		var drone: Drone = drone_scene.instantiate() as Drone
		add_child(drone)
		drone.global_position = spot


## A random open spot away from the player, or Vector3.INF if the grid has no open air.
func _random_spot(rng: RandomNumberGenerator) -> Vector3:
	var spot: Vector3 = Vector3.INF
	for i: int in SPAWN_TRIES:
		spot = _generator.flight_grid.random_open_position(rng)
		if spot == Vector3.INF or spot.distance_to(_player.global_position) >= MIN_SPAWN_DISTANCE:
			break
	return spot
