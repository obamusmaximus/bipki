class_name CityLevel
extends Node3D
## The city level: once the city is built, hands the flying enemy the city's open-air grid, and the HUD minimap the building boxes.

@onready var _generator: CityGenerator = $CityGenerator
@onready var _player: Player = $Player
@onready var _drone: Drone = $Drone


func _ready() -> void:
	_drone.setup(_generator.flight_grid, _player)
	_player.show_city(_generator.building_boxes)
