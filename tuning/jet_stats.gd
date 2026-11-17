class_name JetStats
extends Resource
## Tunable numbers for the jetpack loadout's motor: hover, surge, afterburner, fuel and sound (see
## docs/mechanics/jet.md). One .tres per preset (tuning/jet_default.tres). JetLoadout holds it and hands it to JetMotor.

@export_group("Input")
## Holding the jet key at least this long (seconds) with a movement key starts a surge. A shorter press toggles hover.
@export_range(0.05, 2.0, 0.01) var surge_hold_time: float = 0.5

@export_group("Hover")
## Share of the player's air gravity while hovering in the air.
@export_range(0.0, 1.0, 0.01) var hover_gravity_scale: float = 0.2
## Horizontal speed WASD drives the player toward while hovering (m/s). Momentum doesn't carry into a hover, except
## the afterburner's.
@export var hover_strafe_speed: float = 20.0
## How fast the hover reaches the strafe speed, or brakes down to it (m/s per second).
@export var hover_strafe_accel: float = 40.0
## Share of the vertical speed lost per second while hovering, so a fall or a jump settles instead of floating far.
@export_range(0.0, 10.0, 0.05) var hover_vertical_damping: float = 1.0

@export_group("Surge")
## Speed a surge sets at once, in the direction of the movement keys relative to the look (m/s).
@export var surge_speed: float = 50.0
## How fast a surge's velocity follows the look and the keys (m/s per second). High is a near-instant turn.
@export var surge_steer_accel: float = 120.0
## FOV kick when a surge starts and when the afterburner lights (degrees).
@export var surge_fov_kick: float = 6.0

@export_group("Afterburner")
## Seconds of surging with only forward held (W, not S) before the afterburner lights.
@export var afterburner_delay: float = 2.0
## Speed the afterburner levels off at: a drag balances its thrust there (m/s).
@export var afterburner_speed: float = 70.0
## Thrust of the afterburner (m/s per second). Higher reaches afterburner_speed sooner.
@export var afterburner_accel: float = 20.0

@export_group("Fuel")
## Seconds of thrust (surge or afterburner) a full tank holds.
@export var fuel_seconds: float = 30.0
## Seconds after thrust ends before the tank starts refilling.
@export var fuel_refill_delay: float = 1.0
## Seconds an empty tank takes to refill.
@export var fuel_refill_time: float = 10.0

@export_group("Sound")
## Volume of the jet's sounds (dB). The thrust and the hover hum play quieter than this (below).
@export_range(-40.0, 6.0, 0.5) var volume_db: float = -8.0
## How much quieter the thrust's roar and ignition are than volume_db (dB).
@export_range(0.0, 40.0, 0.5) var thrust_quieter_db: float = 10.0
## How much louder the thrust's bass rumble and ignition thump are than its roar (dB). Negative is quieter.
@export_range(-20.0, 20.0, 0.5) var thrust_bass_db: float = 4.0
## How much quieter the hover hum is than volume_db (dB).
@export_range(0.0, 40.0, 0.5) var hover_hum_quieter_db: float = 14.0
