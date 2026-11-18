class_name TrackingStats
extends Resource
## Tunable numbers for the jet's tracking: the scanner (the pyramid in front of the view that picks enemies up), the
## afterburner's scouting, how long tracks last, and how the scanner frame and track markers look on the HUD (see
## docs/mechanics/jet.md). One .tres per preset (tuning/tracking_default.tres). JetLoadout holds it.

@export_group("Scanner")
## Size of the scanner as a share of the screen (and so of the view's FOV), on both axes. The HUD frame shows it.
@export_range(0.05, 1.0, 0.01) var scanner_share: float = 0.4
## How far the scanner reaches (m).
@export var scanner_range: float = 150.0
## Seconds an enemy must stay in the scanner (and in sight) to be picked up.
@export var scanner_pickup_time: float = 1.5
## Seconds a track lasts. Being in the scanner again refreshes it.
@export var track_time: float = 5.0
## Most enemies the scanner holds at once. Scouting isn't limited by it.
@export var max_tracks: int = 5

@export_group("Scouting")
## While the afterburner burns, every enemy in sight within this distance in any direction is tracked at once (m).
@export var scout_range: float = 50.0
## Seconds a track from scouting lasts.
@export var scout_track_time: float = 8.0

@export_group("Scanner frame")
## Colour of the scanner frame.
@export var frame_color: Color = Color(0.35, 0.7, 1.0, 0.55)
## Line width of the scanner frame (px).
@export var frame_width: float = 1.5
## How far each edge of the frame (and of the scanner) bows out at its middle, as a share of the frame's height.
## Negative bows in; 0 is a straight rectangle. The corners stay put.
@export_range(-0.3, 0.3, 0.005) var frame_edge_curve: float = 0.04

@export_group("Track markers")
## Colour of the rectangle around a tracked enemy.
@export var marker_color: Color = Color(1.0, 0.25, 0.2, 0.9)
## Line width of a track marker (px).
@export var marker_width: float = 1.5
## Size of a track marker around the enemy, in world metres (it shrinks with distance).
@export var marker_world_size: float = 2.0
## Smallest a track marker gets on screen (px).
@export var marker_min_px: float = 14.0
## A marker blinks for this many seconds before its track runs out.
@export var marker_blink_time: float = 1.5
## Blinks per second.
@export var marker_blink_rate: float = 4.0
