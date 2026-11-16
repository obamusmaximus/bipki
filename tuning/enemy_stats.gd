class_name EnemyStats
extends Resource
## Tunable numbers every enemy type shares: health, how a thrown enemy flies and takes damage, and how
## it recovers. A concrete enemy's stats class (DroneStats, ...) extends this and adds its own groups.

@export_group("Health")
## Hit points.
@export var max_health: float = 60.0
## Mass relative to the player (1 = same). A swing rope pulls an enemy by the speed the player gives up,
## divided by this, so a heavier enemy is dragged less.
@export var mass: float = 3.0

@export_group("Thrown")
## Collision radius while flying thrown (m), also used to predict the throw.
@export var body_radius: float = 1.0
## Impact speed into a surface (m/s, the part of the speed along the surface normal) below which a thrown
## enemy takes no damage.
@export var impact_threshold: float = 8.0
## Damage per m/s of impact speed above the threshold.
@export var damage_per_speed: float = 2.0
## Damage a thrown enemy deals to another enemy it hits, as a multiple of what the same impact does to itself.
@export var collision_damage_scale: float = 1.0
## Gravity while thrown, as a fraction of normal. Low means a nearly straight, easy to aim flight.
@export_range(0.0, 1.0, 0.01) var thrown_gravity_scale: float = 0.1
## A thrown enemy that hits nothing for this long (s) gives up and falls.
@export var max_flight_time: float = 6.0
## Share of its speed an enemy keeps, reflected, when it bounces off a surface after an impact.
@export_range(0.0, 1.0, 0.01) var bounce: float = 0.25

@export_group("Knockback")
## A melee hit sends the enemy flying with the player's momentum. If it hits nothing within this distance (m),
## it regains control at once. If it hits a surface it takes impact damage like a throw.
@export var knockback_max_distance: float = 65.0

@export_group("Recovery")
## Seconds an enemy that survived a throw stays stunned (it falls, and can be hooked and thrown again) before it
## flies again.
@export var stun_time: float = 2.5
