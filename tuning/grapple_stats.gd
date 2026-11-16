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
## Fire raycast range for the swing (m).
@export var max_distance: float = 10000.0
## Fire range for the grapple (RMB): launch and throw (m). The swing uses max_distance.
@export var launch_range: float = 30.0
## Hits within this height of the player's feet count as "the ground plane" and are rejected.
@export var ground_tolerance: float = 0.1

@export_group("Launch at an enemy")
## How much of the enemy's motion a launch at it leads (0 aims where it is, 1 where it will be on arrival).
@export_range(0.0, 1.0, 0.01) var strike_lead: float = 1.0
## How fast the flight is turned back onto the arc into the enemy (degrees per second). 0 is only the aimed launch.
@export var strike_turn_rate_degrees: float = 120.0
## Steering more than this many degrees away from the enemy (seen from above) lets the player veer off: guidance ends.
@export_range(0.0, 180.0, 1.0) var strike_veer_degrees: float = 60.0
## Guidance gives up after this many seconds (game time).
@export var strike_max_time: float = 2.0

@export_group("Hit-stop")
## Freeze the game for a split second when the hook attaches, to sell the bite.
@export var hit_stop_enabled: bool = true
## Time scale during the hit-stop (0.05 = nearly frozen).
@export_range(0.01, 1.0, 0.01) var hit_stop_scale: float = 0.05
## How long the hit-stop lasts (real seconds).
@export var hit_stop_time: float = 0.05

@export_group("Enemy hook")
## The grapple locks onto an enemy whose centre is within this angle of the crosshair (degrees), on top of the angle the enemy's own size covers.
@export var enemy_snap_degrees: float = 4.0
## Holding RMB this long (s) from the moment of firing, with the hook on an enemy, turns the grapple into a throw. Letting go sooner launches the player at the enemy.
@export var throw_hold_time: float = 0.2
## Give up on an enemy the tip can't catch after this many seconds in flight.
@export var enemy_chase_time: float = 1.0

@export_group("Throw: bullet time")
## Longest a throw lasts (real seconds). Letting go of RMB ends it sooner and throws.
@export var throw_duration: float = 1.0
## How slow the world runs during a throw (1 = normal).
@export_range(0.02, 1.0, 0.01) var bullet_time_scale: float = 0.12
## Real seconds to slow down into, and to speed back up out of, bullet time.
@export var bullet_time_ease: float = 0.12
## Audio playback speed at full bullet time (1 = normal).
@export_range(0.1, 1.0, 0.01) var bullet_time_audio_speed: float = 0.6
## Extra FOV (degrees) punched in as bullet time starts.
@export var bullet_time_fov_kick: float = 10.0

@export_group("Throw: aim and power")
## How far ahead of the player the rope is pulled (m). The enemy flies from where it hangs toward the point this far along your look direction, so a small reach means you must stand on the line between the enemy and the target, and a large one sends it about where you look.
@export var throw_reach: float = 8.0
## The pull point sits this far to the right of the camera (m), so a thrown enemy passes beside your head.
@export var throw_hand_offset: float = 1.5
## Throw speed with no draw and no flick (m/s).
@export var throw_min_speed: float = 25.0
## Throw speed at full power (m/s).
@export var throw_max_speed: float = 70.0
## How much turning away from the enemy counts toward power (0 = 0 degrees, 1 = facing directly away). Relative to the flick weight.
@export var throw_draw_weight: float = 1.0
## How much the camera's turn speed just before release counts toward power. Relative to the draw weight.
@export var throw_flick_weight: float = 1.0
## Camera turn speed that counts as a full flick (radians per second).
@export var throw_flick_full_speed: float = 10.0
## The flick is the fastest camera turn within this many seconds before release.
@export var throw_flick_window: float = 0.3
## Releasing while facing the enemy within this angle (degrees) just lets it go, without a throw.
@export var throw_min_draw_degrees: float = 35.0
## Mouse sensitivity at full draw, as a fraction of normal. Turning away from the enemy gets heavier, like the rope under tension. 1 turns it off.
@export_range(0.05, 1.0, 0.01) var throw_weight_min_sensitivity: float = 0.5
## A throw bends toward another enemy lying within this angle of its path (degrees). 0 turns it off.
@export var throw_assist_degrees: float = 6.0
## How much of the way the throw bends toward that enemy (0-1).
@export_range(0.0, 1.0, 0.01) var throw_assist_strength: float = 0.8
## How far ahead the release prediction looks (s).
@export var throw_preview_seconds: float = 2.0
## Time step of the release prediction (s).
@export var throw_preview_step: float = 0.04

@export_group("Rope retract")
## How hard the loose end of the rope is pulled back to the hand after a release (springs per second squared).
@export var rope_retract_stiffness: float = 700.0
## How fast the retracting end's motion dies out (per second). Lower means a springier rope.
@export var rope_retract_damping: float = 11.0
## The rope shortens at most this fast (m/s), so the slack whips about on the way in.
@export var rope_retract_speed: float = 90.0
## Sideways kick given to the rope as it lets go (m/s).
@export var rope_retract_whip: float = 9.0
## Sag of the slack rope while retracting (m/s squared).
@export var rope_retract_gravity: float = 12.0
## The retract is cut off after this long (s).
@export var rope_retract_max_time: float = 0.8

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
## How much of the reel's momentum gain is kept (1 = all of it, 0 = reeling adds no sideways speed). The reel-in speed itself isn't affected.
@export_range(0.0, 1.0, 0.01) var reel_momentum_gain: float = 1.0
## Reeling stops adding sideways swing speed once it reaches this (m/s). Speed already above it is kept, not cut. The reel-in speed itself isn't affected.
@export var reel_momentum_speed_cap: float = 45.0
## When the hook lands on a vertical wall, hang from a point pushed out from the wall instead, so the swing arcs away from the building. Off: hang from the exact hit point.
@export var anchor_push_out_enabled: bool = true
## How far out from the wall that anchor sits (m).
@export var anchor_push_out: float = 2.0

@export_group("Rope look")
## Rope thickness in metres.
@export var rope_width: float = 0.03
## Rope colour and opacity. The default is a translucent grey, which is faint against a light background; make it darker and more opaque there.
@export var rope_color: Color = Color(0.6, 0.6, 0.6, 0.5)
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
