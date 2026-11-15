class_name DroneStats
extends EnemyStats
## Tunable numbers for one kind of flying drone: flight, beam attack, visuals and sound.
## Extends EnemyStats (health, being thrown). One .tres per drone type or preset (tuning/drone_default.tres). The Drone scene holds it in `stats` and hands it to its parts.
## Make a new enemy variant by saving another .tres and assigning it to that drone's `stats`.

@export_group("Flight")
## How fast the drone speeds up toward its desired velocity (m/s per second).
@export var acceleration: float = 30.0
## How fast it turns to face the target (radians per second, roughly).
@export var turn_speed: float = 5.0
## The drone never approaches closer than this to the target on its own (m). It does not back away if the target comes closer.
@export var standoff: float = 15.0
## Top flight speed (m/s).
@export var speed: float = 16.0
## Deceleration used to slow down on arrival (m/s per second). Keep it below acceleration.
@export var approach_decel: float = 20.0
## Goals sit on rings this far outside the standoff distance (m), nearest ring first.
@export var ring_margins: PackedFloat32Array = PackedFloat32Array([3.0, 7.0])
## Heights above the target's chest tried for goals (m). Each must be below the ring radius.
@export var goal_heights: PackedFloat32Array = PackedFloat32Array([0.0, 8.0, 16.0, 24.0])
## A goal is kept while the target stays between standoff + goal_keep_min and standoff + goal_keep_max away (m).
@export var goal_keep_min: float = 1.0
## See goal_keep_min (m).
@export var goal_keep_max: float = 14.0
## Seconds between path recalculations.
@export var repath_interval: float = 0.4
## A path waypoint counts as reached within this distance (m).
@export var waypoint_reach: float = 3.0

@export_group("Beam")
## Seconds from one shot to the next charge becoming possible (the reload).
@export var cooldown: float = 7.0
## Seconds the drone charges before locking its aim. The charge whine is built to this length at startup.
@export var charge_time: float = 1.5
## Seconds between the aim locking and the shot (the player's dodge window).
@export var aim_delay: float = 0.5
## Damage dealt to a Health the beam touches.
@export var damage: float = 35.0
## Beam thickness (radius, m).
@export var beam_radius: float = 1.8
## Beam range (m).
@export var beam_range: float = 400.0

@export_group("Visuals")
## Charge orb size at full charge (m).
@export var charge_orb_size: float = 0.7
## Radius of the thin red warning line while the aim is locked (m).
@export var warning_radius: float = 0.05
## Seconds the fired beam stays visible while it fades.
@export var fire_fade_time: float = 0.3

@export_group("Audio")
## Drone sound volume (dB). Read at startup.
@export var volume_db: float = 0.0
## Distance beyond which the drone is silent (m). Read at startup.
@export var max_distance: float = 300.0
