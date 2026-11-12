class_name PlayerStats
extends Resource
## Tunable numbers for the player's body: movement, swing steering, mantle, edge detection, footstep audio and health.
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

@export_group("Mantle")
## Seconds for the whole climb.
@export var mantle_duration: float = 0.2
## Share of the climb spent rising before moving forward onto the top.
@export_range(0.1, 0.9) var mantle_rise_share: float = 0.45
## Speed (m/s) toward the face needed to start a climb.
@export var mantle_min_speed_into_wall: float = 0.5
## How far in from the top edge the feet land (m). Must clear the body's radius (0.4 m).
@export var mantle_land_inset: float = 0.5

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
