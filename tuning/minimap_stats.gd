class_name MinimapStats
extends Resource
## Tunable numbers for the HUD minimap: a 3D isometric wireframe of the city in the top-right corner, with
## the player as a glowing dot and a fading trail of where they have been. One .tres per preset
## (tuning/minimap_default.tres). The Player scene holds it in `minimap_stats`. The minimap also follows
## `HudStats.hud_scale`.

## The box the wireframe is fitted into at scale 1, before HUD scaling (px). The panel then shrinks to the wireframe.
const BASE_SIZE: Vector2 = Vector2(275.0, 228.0)

@export_group("Layout")
## Show the minimap.
@export var minimap_visible: bool = true
## Size of the minimap panel as a multiple of its base size. Width and height scale together.
@export_range(0.5, 2.0, 0.01) var minimap_scale: float = 1.0
## Gap between the panel and the top-right screen corner, on both edges (px).
@export var minimap_margin: float = 24.0
## Opacity of the map itself: the wireframe, the player and the trail (0 = invisible, 1 = solid). The background box is separate.
@export_range(0.0, 1.0, 0.01) var minimap_opacity: float = 0.7
## Colour of the box behind the map. Leave its alpha at 1 for an opaque box.
@export var background_color: Color = Color(0.27, 0.28, 0.30, 1.0)
## Corner rounding of the box behind the map (px).
@export var corner_radius: float = 12.0

@export_group("Projection")
## Camera tilt: 35.264 is a true isometric view, 90 looks straight down.
@export_range(10.0, 90.0, 0.5) var pitch_degrees: float = 35.264
## Rotation of the city about the vertical axis (degrees). 45 gives the classic isometric diamond.
@export_range(-180.0, 180.0, 1.0) var yaw_degrees: float = 45.0
## Space kept clear around the wireframe inside the panel, at its tightest side (px). The panel is sized to the
## wireframe plus this.
@export var view_padding: float = 12.0
## Where the wireframe's centre is taken to be. 0 = the middle of its bounding box (true centre), 1 = the centroid
## of its outline's area (visual centre: a tall corner of the city weighs less than its height suggests).
@export_range(0.0, 1.0, 0.01) var visual_centering: float = 1.0

@export_group("Wireframe")
## Colour of the building outlines.
@export var wire_color: Color = Color(0.45, 0.85, 1.0)
## Opacity of the building outlines, on top of the minimap opacity.
@export_range(0.0, 1.0, 0.01) var wire_alpha: float = 0.55
## Line thickness (px).
@export var wire_width: float = 1.0
## Draw the outline of the city's footprint on the ground.
@export var show_ground_outline: bool = true

@export_group("Player")
## Radius of the player dot (px).
@export var dot_radius: float = 3.5
## Colour of the player dot and its glow.
@export var dot_color: Color = Color(0.75, 1.0, 1.0)
## Radius of the soft glow around the dot (px).
@export var glow_radius: float = 14.0
## Strength of the glow (0 = none, 1 = bright).
@export_range(0.0, 1.0, 0.01) var glow_strength: float = 0.5
## Draw a thin line from the dot straight down to the ground, to read the player's height.
@export var show_drop_line: bool = true

@export_group("Trail")
## How long the trail lasts before it has faded away completely (seconds).
@export var trail_seconds: float = 3.0
## Thickness of the trail at its newest end (px).
@export var trail_width: float = 3.0
## Colour of the trail.
@export var trail_color: Color = Color(0.35, 0.9, 1.0)


@export_group("Enemies")
## Show enemies as dots.
@export var show_enemies: bool = true
## Colour of the enemy dots.
@export var enemy_dot_color: Color = Color(1.0, 0.3, 0.25)
## Radius of an enemy dot (px).
@export var enemy_dot_radius: float = 3.0


## The panel's size in px before HUD scaling: BASE_SIZE times minimap_scale.
func panel_size() -> Vector2:
	return BASE_SIZE * minimap_scale
