class_name CityLevel
extends Node3D
## The city level: once the city is built, hands every flying enemy the city's open-air grid, and the HUD minimap the building boxes.

@onready var _generator: CityGenerator = $CityGenerator
@onready var _player: Player = $Player


func _ready() -> void:
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var drone: Drone = node as Drone
		if drone != null:
			drone.setup(_generator.flight_grid, _player)
	_player.show_city(_generator.building_boxes)
