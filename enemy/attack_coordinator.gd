class_name AttackCoordinator
extends Node
## Spaces out the attacks of every enemy in a level with attack tokens, so they don't all fire together. An enemy
## asks `request()` before it starts an attack and calls `release()` when the attack ends (fired, cancelled or
## freed). A request is refused while `max_attackers` are already attacking, or while less than `min_gap` has passed
## since the last attack started. A refused enemy simply asks again on its next tick, so each keeps its place in the
## rhythm: the gap holds in every cycle, not just the first.
## One per level, handed to each enemy by the level through `setup()`. Enemies given none are unlimited.

@export var stats: AttackCoordinatorStats

var _attackers: Array[Node] = []
## Game time (s), counted like the enemies' own timers so bullet time slows both alike.
var _clock: float = 0.0
var _last_start: float = -1.0e9


func _physics_process(delta: float) -> void:
	_clock += delta


## True if `attacker` may start an attack now. A granted request holds a token until `release()`.
func request(attacker: Node) -> bool:
	if _attackers.has(attacker):
		return true
	_drop_freed()
	if _attackers.size() >= stats.max_attackers:
		return false
	if _clock - _last_start < stats.min_gap:
		return false
	_attackers.append(attacker)
	_last_start = _clock
	return true


## Gives the token back. Safe to call when the attacker holds none.
func release(attacker: Node) -> void:
	_attackers.erase(attacker)


func _drop_freed() -> void:
	for i: int in range(_attackers.size() - 1, -1, -1):
		if not is_instance_valid(_attackers[i]):
			_attackers.remove_at(i)
