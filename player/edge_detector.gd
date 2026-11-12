class_name EdgeDetector
extends Node3D
## Watches the player's surroundings every physics frame and reports with signals. Queries live in
## EdgeProbe. Set up by Player, which connects to the signals.

## A climbable ledge is ahead in the direction of movement.
signal ledge_ahead(ledge: EdgeProbe.Ledge)
## Wall normals on each side, as [left, right]. ZERO means no wall. Sent every frame.
signal walls_beside(left: Vector3, right: Vector3)

const WORLD_MASK: int = 1 # Collision layer 1: World

var stats: PlayerStats

var _body: CharacterBody3D


func setup(body: CharacterBody3D, player_stats: PlayerStats) -> void:
	_body = body
	stats = player_stats


func _physics_process(_delta: float) -> void:
	if _body == null:
		return
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var feet: Vector3 = _body.global_position
	var flat: Vector3 = Vector3(_body.velocity.x, 0.0, _body.velocity.z)

	if flat.length() >= stats.min_ledge_speed:
		var ledge: EdgeProbe.Ledge = EdgeProbe.find_ledge(space, feet, flat, stats.edge_reach, stats.edge_body_radius,
				stats.ledge_min_height, stats.ledge_max_height, WORLD_MASK)
		if ledge.found:
			ledge_ahead.emit(ledge)

	var side: Vector3 = flat.cross(Vector3.UP) if flat.length() >= stats.min_ledge_speed else _body.global_basis.x
	var walls: PackedVector3Array = EdgeProbe.walls_beside(space, feet, side, stats.edge_reach, stats.edge_body_radius, WORLD_MASK)
	walls_beside.emit(walls[0], walls[1])
