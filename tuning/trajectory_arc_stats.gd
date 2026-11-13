class_name TrajectoryArcStats
extends Resource
## Tunable numbers for the HUD trajectory arc: a faint line showing where the player is headed. One .tres per
## preset (tuning/trajectory_arc_default.tres). The Player scene holds it in `arc_stats`. How far ahead it
## looks is `PlayerStats.prediction_seconds`.

@export_group("Arc")
## Show the arc.
@export var arc_visible: bool = true
## Opacity at the start of the arc (it fades toward the far end).
@export_range(0.0, 1.0, 0.01) var arc_opacity: float = 0.22
## Line thickness (px).
@export var arc_width: float = 2.0
## Line colour.
@export var arc_color: Color = Color(0.35, 0.6, 1.0)
## How quickly the arc fades toward its far end (1 = linearly, higher = fades sooner).
@export var arc_fade_power: float = 1.0
## Hide the parts of the arc that pass behind buildings, as seen from the camera.
@export var arc_hide_behind_buildings: bool = true
## The arc is hidden below this speed (m/s), so hanging still doesn't draw a short stub.
@export var arc_min_speed: float = 3.0
