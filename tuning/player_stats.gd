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
## Jump velocity (m/s). Three times the old 1 m jump (about 4.4 m/s).
@export var jump_speed: float = 13.3
## Double jump velocity as a multiple of jump_speed.
@export var double_jump_factor: float = 1.2
## Sideways speed (m/s) a double jump adds while A or D is held.
@export var double_jump_sideways: float = 3.0
## Share of the player's velocity kept when a launch begins. The rest is lost.
@export_range(0.0, 1.0) var momentum_carry: float = 0.4

@export_group("Swing steering")
## WASD pushes the body along the swing rope's tangent at this acceleration (m/s per second).
@export var swing_steer_acceleration: float = 15.0
## Top speed (m/s) the swing steering adds along the tangent.
@export var swing_steer_speed: float = 8.0

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

@export_group("Wall run")
## Horizontal speed (m/s) needed to latch onto a wall.
@export var wall_run_min_speed: float = 12.0
## The run ends when the speed drops below this (m/s).
@export var wall_run_end_speed: float = 6.0
## The speed is limited to this while wall running (m/s).
@export var wall_run_max_speed: float = 50.0
## Largest angle (degrees) between the travel direction and the wall for a hit to count as a graze. Steeper hits are head-on and just slide.
@export_range(5.0, 89.0, 1.0) var wall_run_max_approach_degrees: float = 50.0
## Share of gravity that still applies while wall running.
@export_range(0.0, 1.0, 0.01) var wall_run_gravity_scale: float = 0.1
## Speed pressed into the wall to keep touching it (m/s).
@export var wall_run_stick_speed: float = 3.0
## Seconds without touching the wall before the run ends.
@export var wall_run_lose_grace: float = 0.12
## Upward speed of a jump off the wall (m/s).
@export var wall_run_jump_speed: float = 11.0
## Speed away from the wall of a jump off it (m/s).
@export var wall_run_jump_away_speed: float = 8.0
## Seconds after a run ends before another can start.
@export var wall_run_cooldown: float = 0.35

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
## The assist keeps the player at least this far from a wall on either side (m).
@export var assist_clearance: float = 2.5
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
