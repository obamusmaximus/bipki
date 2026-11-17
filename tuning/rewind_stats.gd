class_name RewindStats
extends Resource
## Tunable numbers for `Rewind`, which sets the level back in time when the player dies with a life left.
## One .tres per preset (tuning/rewind_default.tres). The debug tuning panel edits it live (Level tab).
## The number of lives is the player's own (`PlayerStats` "Health").

@export_group("Rewind")
## How far back (s of game time) a death sets the player, the enemies and the level.
@export var rewind_seconds: float = 5.0
## Seconds of game time between snapshots. A rewind lands up to this much further back than `rewind_seconds`.
## Smaller is more exact; each snapshot costs one pass over every rewindable node, and the buffer holds
## `rewind_seconds / snapshot_interval` of them.
@export_range(0.02, 1.0, 0.01) var snapshot_interval: float = 0.25
