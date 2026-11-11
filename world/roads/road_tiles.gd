class_name RoadTiles
extends RefCounted
## Chooses the Roads-kit tile for a set of open sides. Each piece's base orientation was read
## from its geometry: road-straight opens west and east, road-bend west and south,
## road-intersection west, east and south, road-end east, road-crossroad all four.

const DIR: String = "res://IMPORTS/kenney_city-kit-roads/Models/GLB format/"
const WEST: int = 1
const EAST: int = 2
const NORTH: int = 4
const SOUTH: int = 8

## Unit direction for each side, by bit position: 0 west, 1 east, 2 north, 3 south.
const DIRECTIONS: Array[Vector3] = [
	Vector3(-1.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), Vector3(0.0, 0.0, -1.0), Vector3(0.0, 0.0, 1.0),
]
const PIECE_NAMES: PackedStringArray = [
	"road-straight", "road-crossroad", "road-intersection", "road-end", "road-bend",
]
## Open sides of each piece at zero rotation, in the same order as PIECE_NAMES.
const PIECE_OPEN: PackedInt32Array = [
	WEST | EAST, WEST | EAST | NORTH | SOUTH, WEST | EAST | SOUTH, EAST, WEST | SOUTH,
]


## Meshes of a piece, in model space.
static func parts(piece: int) -> Array[MeshPart]:
	return MeshPart.from_scene(DIR + PIECE_NAMES[piece] + ".glb")


## Returns (piece index, quarter turns around Y) that opens exactly the sides in `open_sides`,
## or (-1, -1) if no piece does.
static func find(open_sides: int) -> Vector2i:
	for piece: int in PIECE_NAMES.size():
		for turns: int in 4:
			if _rotate_sides(PIECE_OPEN[piece], turns) == open_sides:
				return Vector2i(piece, turns)
	return Vector2i(-1, -1)


static func _rotate_sides(sides: int, turns: int) -> int:
	var result: int = 0
	var turn := Basis(Vector3.UP, turns * PI * 0.5)
	for bit: int in 4:
		if sides & (1 << bit):
			result |= _side_bit(turn * DIRECTIONS[bit])
	return result


static func _side_bit(direction: Vector3) -> int:
	var rounded: Vector3 = direction.round()
	for bit: int in 4:
		if DIRECTIONS[bit].is_equal_approx(rounded):
			return 1 << bit
	return 0
