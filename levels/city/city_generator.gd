@tool
class_name CityGenerator
extends Node3D
## Builds the city under this node from `settings`. The generated nodes are not saved with the
## scene: the level keeps the settings, and the city is rebuilt when the level loads. In the
## editor, press Regenerate after changing a setting.

## Ground is split into square chunks this wide (metres), so the engine can skip off-screen ones.
const CHUNK_SIZE: float = 100.0

@export var settings: CitySettings = CitySettings.new()
@export_tool_button("Regenerate") var _regenerate_button: Callable = regenerate

## The open air of the generated city, for flying enemies. Built at runtime only (not in the editor).
var flight_grid: FlightGrid


func _ready() -> void:
	if not Engine.is_editor_hint():
		regenerate()


func regenerate() -> void:
	if settings == null:
		return
	for child: Node in get_children():
		child.free()
	var plan: CityPlan = CityLayout.build(settings)

	var roads := Node3D.new()
	roads.name = "Roads"
	add_child(roads)
	RoadBuilder.build(roads, plan, CHUNK_SIZE)

	var buildings := Node3D.new()
	buildings.name = "Buildings"
	add_child(buildings)
	BuildingBuilder.build(buildings, plan, CHUNK_SIZE)
	if not Engine.is_editor_hint():
		flight_grid = FlightGrid.from_plan(plan)
