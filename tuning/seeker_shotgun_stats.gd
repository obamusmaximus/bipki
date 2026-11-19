class_name SeekerShotgunStats
extends Resource
## Tunable numbers for the jet's seeker shotgun: a spread of pellets that each home in on one of the tracked enemies
## (see docs/mechanics/jet.md). One .tres per preset (tuning/seeker_shotgun_default.tres). JetLoadout holds it.

@export_group("Pellets")
## Pellets per shot. They are dealt out to the tracked enemies newest pickup first, round and round.
@export var pellet_count: int = 8
## Damage one pellet deals.
@export var damage: float = 25.0
## Pellet speed (m/s).
@export var speed: float = 120.0
## Half-angle of the cone the pellets leave in (degrees).
@export var spread_degrees: float = 4.0
## Radius a pellet hits with (m).
@export var pellet_radius: float = 0.25
## Seconds a pellet flies before it is gone.
@export var lifetime: float = 2.0
## Where the pellets leave from, relative to the camera (m; x right, y up, -z forward).
@export var muzzle_offset: Vector3 = Vector3(0.25, -0.2, -0.5)
## The pellets are aimed at what the crosshair points at within this distance (m), or at that distance.
@export var aim_range: float = 300.0

@export_group("Homing")
## Seconds a pellet flies straight before it starts turning toward its enemy.
@export var homing_delay: float = 0.2
## How fast a homing pellet turns toward its enemy (degrees per second).
@export var turn_rate: float = 540.0
## A pellet that can't make the turn onto its enemy at its speed (the enemy is inside its turning circle) brakes just
## enough to make it, down to this share of `speed` at the least.
@export_range(0.01, 1.0, 0.01) var min_speed_share: float = 0.1
## How fast a braked pellet speeds back up to `speed` (m/s per second).
@export var speed_recovery: float = 300.0

@export_group("Tracers")
## Seconds a point of a tracer lasts: the tracer is the pellet's path over this long, fading toward its tail.
@export var tracer_time: float = 0.12
## Width of a tracer at the pellet (m). It narrows toward the tail.
@export var tracer_width: float = 0.06
## Colour of a tracer at the pellet.
@export var tracer_color: Color = Color(1.0, 0.85, 0.5, 1.0)

@export_group("Sound")
## Volume of the shot (dB). Read at startup and when edited.
@export var shot_db: float = -6.0
