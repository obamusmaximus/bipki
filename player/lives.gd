class_name Lives
extends RefCounted
## How many rewinds the player has left. A death with one left spends it and rewinds the level (see `Rewind`); a death
## with none left is game over. Owned by Player. Not part of a rewind: a life spent stays spent.

signal changed(left: int)

var _left: int = 0


func _init(count: int) -> void:
	_left = maxi(count, 0)


func get_left() -> int:
	return _left


## Spends one for a death. True if there was one to spend (the death is rewound), false if none were left (game over).
func spend() -> bool:
	if _left <= 0:
		return false
	_left -= 1
	changed.emit(_left)
	return true
