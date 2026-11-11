class_name EdgeDetector
extends Node3D
## Watches the player's surroundings every physics frame and reports with signals. Queries live in
## EdgeProbe. Set up by Player, which connects to the signals.

## A climbable ledge is ahead in the direction of movement.
signal ledge_ahead(ledge: EdgeProbe.Ledge)
## Wall normals on each side, as [left, right]. ZERO means no wall. Sent every frame.
signal walls_beside(left: Vector3, right: Vector3)

const WORLD_MASK: int = 1 # Collision layer 1: World

## How far past the body's surface the wall checks reach (metres).
@export var reach: float = 0.6
@export var ledge_min_height: float = 0.3
@export var ledge_max_height: float = 1.3
@export var body_radius: float = 0.4
## Below this horizontal speed (m/s) the body is not moving, so no ledge check.
@export var min_ledge_speed: float = 0.5

var _body: CharacterBody3D


func setup(body: CharacterBody3D) -> void:
	_body = body


func _physics_process(_delta: float) -> void:
	if _body == null:
		return
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var feet: Vector3 = _body.global_position
	var flat: Vector3 = Vector3(_body.velocity.x, 0.0, _body.velocity.z)

	if flat.length() >= min_ledge_speed:
		var ledge: EdgeProbe.Ledge = EdgeProbe.find_ledge(space, feet, flat, reach, body_radius,
				ledge_min_height, ledge_max_height, WORLD_MASK)
		if ledge.found:
			ledge_ahead.emit(ledge)

	var side: Vector3 = flat.cross(Vector3.UP) if flat.length() >= min_ledge_speed else _body.global_basis.x
	var walls: PackedVector3Array = EdgeProbe.walls_beside(space, feet, side, reach, body_radius, WORLD_MASK)
	walls_beside.emit(walls[0], walls[1])
