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

@export_group("Playback")
## Real seconds time takes to slow from its speed at the death to a standstill (the world keeps moving meanwhile).
@export_range(0.0, 3.0, 0.05) var slow_seconds: float = 0.6
## Real seconds the trip back to the saved moment takes. It starts slow, speeds up and slows again on arrival.
@export_range(0.1, 6.0, 0.05) var reverse_seconds: float = 1.8
## Shape of the trip back's speed. 1 is a constant speed; higher spends longer near both ends and rushes the middle.
@export_range(1.0, 5.0, 0.1) var reverse_ease: float = 2.5
## Real seconds time takes to speed back up to normal after arriving. The player has control meanwhile.
@export_range(0.0, 3.0, 0.05) var resume_seconds: float = 0.5
## Strength of the screen effect (colour drain, colour split, scanlines) at its peak. 0 turns it off.
@export_range(0.0, 1.0, 0.05) var screen_strength: float = 1.0
## Volume of the rushing sound during the trip back.
@export_range(-40.0, 6.0, 0.5) var sound_volume_db: float = -8.0
