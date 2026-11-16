class_name AttackCoordinatorStats
extends Resource
## Tunable numbers for `AttackCoordinator`, which spaces out the attacks of all the enemies in a level.
## One .tres per preset (tuning/attack_coordinator_default.tres). The debug tuning panel edits it live (Drone tab).

@export_group("Spacing")
## Most enemies that may be charging or aiming a shot at the same time. The others wait their turn.
@export var max_attackers: int = 2
## Least time (s) between one enemy starting a charge and the next one starting theirs, so shots never land together
## and the player can tell them apart. Counted in game time, so bullet time stretches it like everything else.
@export var min_gap: float = 1.5
