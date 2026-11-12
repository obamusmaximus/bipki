class_name GrappleStats
extends Resource
## Tunable numbers for the grappling hook: launch, swing and reel, rope look and sound.
## One .tres per preset (tuning/grapple_default.tres). The Player scene holds it in `grapple_stats` and hands it to GrappleHook.

@export_group("Launch")
## Speed of the hook tip, for both functions (m/s).
@export var extend_speed: float = 150.0
## Speed added toward the launch aim point (m/s).
@export var launch_speed: float = 25.0
## A launch aims this many meters above the hit point.
@export var launch_height_offset: float = 6.0
## A launch aim point can shift sideways by up to this many meters, following the crosshair.
@export var launch_side_offset: float = 6.0
## Seconds between attaching and launching (the player's window to steer the sideways shift).
@export var launch_grace: float = 0.3
## Fire raycast range (m).
@export var max_distance: float = 10000.0
## Hits within this height of the player's feet count as "the ground plane" and are rejected.
@export var ground_tolerance: float = 0.1

@export_group("Swing")
## How fast the rope shortens while reel (Shift) is held (m/s).
@export var reel_speed: float = 25.0
## Fastest the rope shortens by itself while the player drops below the hit point (m/s).
@export var descent_speed: float = 6.0
## Shortest rope (m). Reeling down to this detaches the hook.
@export var min_rope_length: float = 4.0
## A swing rope that is too long retracts so the player passes this far above the terrain under the hit point (m).
@export var swing_ground_margin: float = 2.0
## The rope must be clear of the ground by the time the player is inside this horizontal radius (m) of the point below the hit point.
@export var clear_ground_radius: float = 3.0

@export_group("Rope look")
## Rope thickness in metres.
@export var rope_width: float = 0.03
## Ribbon segments along the rope. More is smoother.
@export var rope_segments: int = 14
## Sag of the rope while the tip is in flight, in metres per metre of rope length.
@export var rope_flight_sag: float = 0.03
## Size of the wobble right after attach, in metres per metre of rope length (long ropes are capped).
@export var rope_wobble_amount: float = 0.03
## How fast the wobble dies out (per second).
@export var rope_wobble_decay: float = 4.0
## Wobble speed in radians per second.
@export var rope_wobble_frequency: float = 18.0
## Number of waves along the rope.
@export var rope_wobble_waves: float = 2.0
## Hook tip radius (m).
@export var tip_radius: float = 0.12
## Hook tip colour.
@export var tip_color: Color = Color(1.0, 0.75, 0.3)

@export_group("Audio")
## Grapple sound volume (dB).
@export var volume_db: float = -6.0
