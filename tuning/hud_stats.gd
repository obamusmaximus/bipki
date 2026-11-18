class_name HudStats
extends Resource
## Tunable numbers for the HUD and menus. One .tres per preset (tuning/hud_default.tres). The Player scene holds it in
## `hud_stats` and hands it to the Hud. Likely to move into GameSettings once the size feels right.

@export_group("Scale")
## Size of the on-screen HUD (every group: the centre, the corners, the edges and the minimap) and of the menus
## (pause menu, tuning panel, death screen). 1 = normal. Menus rescale when the mouse is released, so a slider
## doesn't move under the pointer while it is dragged.
@export_range(0.5, 3.0, 0.05) var hud_scale: float = 1.0

@export_group("Layout")
## Gap between the HUD groups (corners, edge midpoints) and the screen edges (px, after HUD scale).
@export var edge_margin: float = 24.0

@export_group("Visor")
## How far the HUD wraps around the view from side to side, like the inside of a helmet visor (degrees; 0 = flat).
## The edge groups bend and their outer sides grow; the crosshair and speedometer at the centre stay flat.
@export_range(0.0, 60.0, 0.5) var visor_curve_x: float = 24.0
## The same wrap from top to bottom (degrees; 0 = flat).
@export_range(0.0, 60.0, 0.5) var visor_curve_y: float = 14.0

@export_group("Abilities")
## Size of each ability indicator right of the health bar (px, before HUD scale).
@export var ability_size: Vector2 = Vector2(40.0, 40.0)
## Corner rounding of an ability indicator (px, before HUD scale).
@export var ability_corner_radius: float = 8.0
## Gap between the ability indicators (px, before HUD scale).
@export var ability_gap: float = 8.0
## Colour of an ability indicator at rest.
@export var ability_color: Color = Color(0.32, 0.33, 0.36, 0.75)
## Colour an ability indicator flashes when the ability is used, and of the throw's time-left outline.
@export var ability_flash_color: Color = Color(1.0, 0.58, 0.15, 1.0)
## How long the flash takes to fade (real seconds).
@export var ability_flash_seconds: float = 0.35
## Colour of the letter on an ability indicator.
@export var ability_letter_color: Color = Color(1.0, 1.0, 1.0, 0.9)
## Text size of the letter on an ability indicator (px, before HUD scale).
@export var ability_letter_size: int = 18
## Thickness of the outline that runs round an ability indicator: the throw's bullet time left, the surge's charge (px, before HUD scale).
@export var throw_outline_width: float = 3.0

@export_group("Speedometer")
## Diameter of the speed dial beside the crosshair (px, before HUD scale).
@export var speedometer_size: float = 96.0
## How far right of the crosshair the dial's centre sits (px, before HUD scale).
@export var speedometer_offset_x: float = 110.0
## How far below the crosshair the dial's centre sits (px, before HUD scale). Negative is above.
@export var speedometer_offset_y: float = 0.0
## Share of the dial (1 = the player's soft speed limit) where the colour starts turning toward the warning colour and the red zone begins.
@export_range(0.0, 0.99, 0.01) var speedometer_warn_start: float = 0.7
## How quickly the dial follows the real speed (per second). 0 = instantly.
@export var speedometer_smoothing: float = 14.0
## Fill colour at low speed.
@export var speedometer_color: Color = Color(0.75, 0.9, 1.0, 0.95)
## Fill colour partway into the red zone.
@export var speedometer_warn_color: Color = Color(1.0, 0.7, 0.2, 1.0)
## Fill colour at the top of the dial.
@export var speedometer_max_color: Color = Color(1.0, 0.25, 0.2, 1.0)
## Colour of the empty dial track.
@export var speedometer_track_color: Color = Color(1.0, 1.0, 1.0, 0.18)
## Colour of the disc behind the dial.
@export var speedometer_back_color: Color = Color(0.0, 0.0, 0.0, 0.4)

@export_group("Damage numbers")
## Show a floating number where an enemy takes damage.
@export var damage_numbers_enabled: bool = true
## Text size of a small hit (px, before HUD scale).
@export var damage_number_size: float = 22.0
## A hit this big (damage) is drawn at full big size; smaller hits scale between the two.
@export var damage_number_big_at: float = 60.0
## Text size of a big hit (px, before HUD scale).
@export var damage_number_big_size: float = 40.0
## How long a number stays (real seconds).
@export var damage_number_lifetime: float = 1.1
## How fast a number rises on screen (px per second, before HUD scale).
@export var damage_number_rise: float = 70.0
## Colour of a hit that doesn't kill.
@export var damage_number_color: Color = Color(1.0, 0.85, 0.35)
## Colour of the hit that kills.
@export var damage_number_kill_color: Color = Color(1.0, 0.25, 0.2)
