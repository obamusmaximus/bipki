class_name PlayerStats
extends Resource
## Tunable numbers for the player's body: movement, swing steering, edge detection, footstep audio and health.
## One .tres per preset (tuning/player_default.tres). The Player scene holds it in `stats` and hands it to its components.
## The debug tuning panel (pause menu) edits these live and can save them back to the .tres.

@export_group("Movement")
## Ground speed (m/s).
@export var move_speed: float = 15.0
## Air control: WASD pushes the horizontal speed toward this value in the input direction (m/s).
@export var air_speed: float = 10.0
## How fast air control adds speed toward air_speed (m/s per second).
@export var air_acceleration: float = 30.0
## Jump velocity (m/s). Jump height is jump_speed squared / (2 * gravity).
@export var jump_speed: float = 10.5
## Double jump velocity as a multiple of jump_speed.
@export var double_jump_factor: float = 1.0
## Releasing jump while still rising from a jump keeps only this share of the upward speed (a tap is a hop,
## a hold is the full jump). 1 = no cut. Wall jumps and launches aren't cut.
@export_range(0.0, 1.0, 0.01) var jump_release_cut: float = 0.5
## Sideways speed (m/s) a double jump adds while A or D is held.
@export var double_jump_sideways: float = 3.0
## Share of the player's velocity kept when a launch begins. The rest is lost.
@export_range(0.0, 1.0) var momentum_carry: float = 0.4
## A launch fired while standing gets at least this upward speed (m/s), so a launch aimed slightly down
## leaves the ground instead of losing its speed on the floor at once.
@export var launch_ground_lift: float = 4.0

@export_group("Gravity")
## The player's gravity (m/s squared). Only the player: enemies and thrown things keep the project's 9.8.
## Higher makes jumps shorter and falls quicker, so the player stays down among the buildings.
@export var gravity: float = 25.0
## Gravity multiplier while falling (vertical speed below zero). Above 1 gives a quick drop after the apex.
@export_range(1.0, 3.0, 0.05) var fall_gravity_scale: float = 1.3
## Share of gravity on a swing rope while falling toward the low point of the arc. Higher builds speed faster
## (and more speed at the bottom).
@export_range(0.0, 2.0, 0.01) var swing_gravity_scale_falling: float = 0.4
## Share of gravity on a swing rope while rising past the low point. Higher slows the swing sooner and lower
## carries it higher. Below the falling share each swing climbs higher than it started; above it each one dies down.
@export_range(0.0, 2.0, 0.01) var swing_gravity_scale_rising: float = 0.4
## Share of gravity for launch_gravity_time after a launch, so a launch still reaches its aim point.
@export_range(0.0, 2.0, 0.01) var launch_gravity_scale: float = 0.4
## Seconds of launch_gravity_scale after a launch, then full gravity (ends early on landing, a swing or a wall run).
@export var launch_gravity_time: float = 1.0

@export_group("Swing steering")
## WASD pushes the body along the swing rope's tangent at this acceleration (m/s per second).
@export var swing_steer_acceleration: float = 15.0
## Top speed (m/s) the swing steering adds along the tangent.
@export var swing_steer_speed: float = 8.0
## Steer a swing by turning the velocity along the rope toward the input at a maximum turn rate, like air
## steering: same feel at any speed, no energy added. Off: the older push along the tangent (the two values above).
@export var swing_turn_rate_enabled: bool = false
## Maximum turn rate while swinging (degrees per second).
@export var swing_turn_rate_degrees: float = 120.0
## Below this speed (m/s) the older tangent push is used, so a hanging start can still get going.
@export var swing_turn_min_speed: float = 6.0

@export_group("Edge detection")
## How far past the body's surface the wall checks reach (m).
@export var edge_reach: float = 0.6
## Lowest ledge that can be climbed (m).
@export var ledge_min_height: float = 0.3
## Highest ledge that can be climbed (m).
@export var ledge_max_height: float = 1.3
## Body radius used by the edge probes (m).
@export var edge_body_radius: float = 0.4
## Below this horizontal speed (m/s) the body is not moving, so no ledge check.
@export var min_ledge_speed: float = 0.5

@export_group("Audio")
## Footstep volume (dB).
@export var footsteps_volume_db: float = -10.0
## Steps per second while walking (1.75x the old 1 / 0.45 s). Walk bob and footsteps share it.
@export var steps_per_second: float = 1.75 / 0.45

@export_group("Health")
## Player hit points. Read once at startup (needs a restart).
@export var max_health: float = 100.0

@export_group("Air steering")
## Steer in the air by turning the velocity toward the input at a maximum turn rate, so steering feels the same
## at any speed and never adds energy. Off: the older way, adding sideways speed with a fixed acceleration.
@export var air_turn_rate_enabled: bool = true
## Maximum turn rate in the air (degrees per second).
@export var air_turn_rate_degrees: float = 120.0
## Below this horizontal speed (m/s) the older acceleration is used, so a standing start can still move.
@export var air_turn_min_speed: float = 6.0

@export_group("Air drag")
## Fraction of speed lost per second while airborne or swinging, on at any speed (below the soft limit too). 0 = off. Keeps flight from feeling static.
@export_range(0.0, 0.5, 0.005) var air_drag: float = 0.05

@export_group("Wall run")
## Horizontal speed (m/s) needed to latch onto a wall.
@export var wall_run_min_speed: float = 12.0
## The run ends when the speed drops below this (m/s).
@export var wall_run_end_speed: float = 6.0
## The compressor brings the run's horizontal speed down to this (m/s), starting wall_run_compress_delay into the run. A head-on latch also keeps at most this.
@export var wall_run_max_speed: float = 50.0
## Seconds into a run before the compressor starts slowing a run that is faster than wall_run_max_speed.
@export var wall_run_compress_delay: float = 0.75
## How fast (m/s per second) the compressor slows a run that is above wall_run_max_speed.
@export var wall_run_compress_rate: float = 5.0
## Acceleration (m/s per second) along the wall while the run is slower than wall_run_accel_max_speed.
@export var wall_run_accel: float = 8.0
## The run accelerates only up to this speed (m/s). A run that starts faster keeps its momentum, with no extra speed.
@export var wall_run_accel_max_speed: float = 42.0
## Largest angle (degrees) between the travel direction and the wall for a hit to count as a graze. Steeper hits are head-on and just slide.
@export_range(5.0, 89.0, 1.0) var wall_run_max_approach_degrees: float = 50.0
## Share of gravity that still applies while wall running.
@export_range(0.0, 1.0, 0.01) var wall_run_gravity_scale: float = 0.04
## Speed pressed into the wall to keep touching it (m/s).
@export var wall_run_stick_speed: float = 3.0
## A wall isn't latched while rising faster than this (m/s). A wall run never runs up the wall: it starts with no upward speed, so a fast climb (a launch) just slides past instead.
@export var wall_run_max_rise_speed: float = 12.0
## Seconds without touching the wall before the run ends.
@export var wall_run_lose_grace: float = 0.12
## Upward speed of a jump off the wall (m/s).
@export var wall_run_jump_speed: float = 11.0
## Speed away from the wall of a jump off it (m/s).
@export var wall_run_jump_away_speed: float = 8.0
## Seconds after a run ends before another can start.
@export var wall_run_cooldown: float = 0.35
## Head-on hits latch onto the wall: the player slides slowly down it, and turning the camera along the wall
## within wall_run_head_on_time starts a wall run that way. Otherwise they let go and fall, and can't latch
## onto a wall again until they land.
@export var wall_run_head_on_enabled: bool = true
## Seconds the head-on latch lasts before the player lets go.
@export var wall_run_head_on_time: float = 1.0
## Speed (m/s) straight back off the wall when jumping from a head-on latch. The player faces the wall, so this is directly backward. The upward speed is jump_speed, as on the ground.
@export var wall_run_head_on_jump_speed: float = 14.0
## Share of gravity while latched head-on (a slow slide down the wall).
@export_range(0.0, 1.0, 0.01) var wall_run_head_on_gravity_scale: float = 0.08
## Turning the look this close to parallel with the wall (degrees) starts the run.
@export_range(0.0, 89.0, 1.0) var wall_run_head_on_turn_degrees: float = 35.0
## A run needs W held unless the travel direction is more than this many degrees from the look (90 = sideways counts as forward, 180 = only exactly backwards is exempt).
@export_range(90.0, 180.0, 1.0) var wall_run_no_key_degrees: float = 120.0
## How far (degrees) the view turns away from the wall when a run starts, so the crosshair isn't left on the wall's edge.
@export_range(0.0, 60.0, 1.0) var wall_run_look_nudge_degrees: float = 20.0
## Seconds that turn takes.
@export var wall_run_look_nudge_time: float = 0.15

@export_group("Trajectory prediction")
## How far ahead the predicted path looks (seconds). Drives the HUD arc and the obstacle assist.
@export var prediction_seconds: float = 1.5
## Time step of the prediction (seconds). Smaller is smoother but costs more.
@export var prediction_step: float = 0.06
## Radius of the sphere swept along the predicted path to find hits (m). A little over the body radius.
@export var prediction_probe_radius: float = 0.45

@export_group("Obstacle assist")
## How strongly the player is steered away from buildings (0 = off, 1 = full).
@export_range(0.0, 2.0, 0.05) var assist_strength: float = 1.0
## Only a predicted hit sooner than this (seconds) is acted on. Capped by prediction_seconds.
@export var assist_lookahead: float = 0.9
## Once a collision with a wall is predicted, the assist steers until the path passes at least this far from it (m). A bigger margin steers further to the side. Walls the player is merely passing or wall running along don't trigger it.
@export var assist_clearance: float = 4.0
## No assist below this speed (m/s).
@export var assist_min_speed: float = 12.0
## Strongest sideways push (m/s per second). The push is sized to clear the wall in the time left, up to this limit, so a high value is a firm snap.
@export var assist_max_accel: float = 90.0
## A predicted hit within this distance (m) of the hook's attach point is ignored: swinging up to that face is deliberate.
@export var assist_anchor_radius: float = 6.0
## Lift over a roof edge instead of steering sideways when one is within reach (0 = off).
@export_range(0.0, 2.0, 0.05) var assist_lift_strength: float = 0.6
## A roof edge counts as within reach if it is at most this high above the predicted hit (m).
@export var assist_lift_height: float = 3.0
## How much the assist backs off when the player already steers the same way (0 = ignores input, 1 = stops completely).
@export_range(0.0, 1.0, 0.05) var assist_input_yield: float = 0.6

@export_group("Speed limit")
## Soft speed limit: above the limit a drag grows quickly with speed, so speed levels off near it instead of stopping dead. Off: no limit.
@export var soft_speed_limit_enabled: bool = true
## The speed (m/s) the drag levels the player off near. It is approximate: the drag does nothing below it, and
## strong forces (a long fall, a reel) can push a little past it.
@export_range(20.0, 200.0, 1.0) var soft_speed_limit: float = 60.0
## How hard the drag pulls back (m/s per second at 1.25x the limit is about this value). Higher holds the limit tighter.
@export var soft_speed_limit_strength: float = 40.0

@export_group("Melee")
## A hit needs at least this speed (m/s), unless the player was launched at an enemy (RMB tap), which always hits.
@export var melee_min_speed: float = 30.0
## After a launch at an enemy, the hit stays armed this long (s) or until landing.
@export var melee_armed_time: float = 2.0
## Radius of the hit sphere in front of the player (m). Generous on purpose; the enemy's own radius is added.
@export var melee_hit_radius: float = 1.6
## How far in front of mid-body (along the look direction) the hit sphere sits (m).
@export var melee_reach: float = 1.2
## An enemy must be within this angle (degrees) of the look direction to be hit, so nothing behind is.
@export_range(10.0, 120.0, 1.0) var melee_front_degrees: float = 75.0
## Damage as a share of the enemy's max health.
@export_range(0.0, 1.0, 0.01) var melee_damage_fraction: float = 0.5
## The enemy is knocked back with the player's velocity times this.
@export var melee_knockback_scale: float = 1.0
## Share of the player's velocity kept after the hit.
@export_range(0.0, 1.0, 0.01) var melee_momentum_keep: float = 0.1
## Slow motion after a hit (real seconds). Uses the throw's bullet time scale, ease and audio.
@export var melee_slowmo_time: float = 0.5
## Seconds after a hit before the next can land.
@export var melee_cooldown: float = 0.3
## Volume of the hit sound (dB).
@export var melee_volume_db: float = -3.0
