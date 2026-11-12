class_name Health
extends Node
## Hit points for whatever owns this node. Attackers find it as a child named "Health" on the body they hit
## and call take_damage(). It reports upward with signals and does nothing else (no death handling yet).

signal damaged(amount: float)
signal health_changed(current: float, maximum: float)
signal died

var max_health: float = 100.0

var _current: float = 0.0


## Sets the maximum and fills health. Called once by the owner with its tuned value.
func setup(max_hp: float) -> void:
	max_health = max_hp
	_current = max_hp


func take_damage(amount: float) -> void:
	if amount <= 0.0 or is_dead():
		return
	_current = maxf(_current - amount, 0.0)
	damaged.emit(amount)
	health_changed.emit(_current, max_health)
	if is_dead():
		died.emit()


func get_current() -> float:
	return _current


func is_dead() -> bool:
	return _current <= 0.0
