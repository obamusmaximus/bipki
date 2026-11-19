class_name NightStats
extends Resource
## Tunable numbers for the island's moonlit night: the moon light, the sky, the ambient light, the fog and the warm
## accent lights. One .tres per preset (tuning/night_default.tres). `IslandLevel` holds it, `IslandLook` applies it live.

@export_group("Moon")
## Height of the moon above the horizon (degrees). Low gives long shadows across the grid.
@export_range(5.0, 85.0, 0.5) var moon_elevation: float = 30.0
## Compass direction the moonlight comes from (degrees, turning the light about the vertical).
@export_range(-180.0, 180.0, 1.0) var moon_azimuth: float = 45.0
## Colour of the moonlight. Cool blue-white.
@export var moon_color: Color = Color(0.72, 0.82, 1.0)
## Strength of the moonlight.
@export var moon_energy: float = 0.8
## How soft the shadow edges are (shadow blur).
@export_range(0.0, 6.0, 0.1) var shadow_blur: float = 1.5
## How far from the camera shadows are drawn (m). Shorter is sharper.
@export var shadow_distance: float = 250.0

@export_group("Sky")
## Colour of the sky straight up.
@export var zenith_color: Color = Color(0.015, 0.03, 0.09)
## Colour of the lighter band at the horizon. The fog takes this colour too, so the water's edge melts into it.
@export var horizon_color: Color = Color(0.1, 0.15, 0.28)
## How high the horizon band reaches before the sky turns zenith colour (0 = horizon, 1 = straight up).
@export_range(0.01, 1.0, 0.01) var horizon_band: float = 0.35
## Size of the moon disc (degrees across). It sits along the moonlight, so turning the light moves it.
@export_range(0.2, 15.0, 0.1) var moon_disc_size: float = 3.0
## Colour of the moon disc.
@export var moon_disc_color: Color = Color(0.92, 0.95, 1.0)
## Strength of the soft halo around the moon (0 = none).
@export_range(0.0, 1.0, 0.01) var moon_halo: float = 0.25
## How wide the halo spreads (bigger is tighter).
@export var moon_halo_tightness: float = 60.0
## Share of sky cells that hold a star (0 = none). Keep it sparse.
@export_range(0.0, 0.2, 0.001) var star_density: float = 0.04
## Cells per unit of the sky direction: more is smaller, more numerous stars.
@export var star_grid: float = 140.0
## Size of a star inside its cell (0 to 0.5).
@export_range(0.02, 0.5, 0.01) var star_size: float = 0.12
## Brightness of the stars.
@export_range(0.0, 2.0, 0.01) var star_brightness: float = 0.8
## Stars fade out toward the horizon below this height (0 = horizon, 1 = straight up).
@export_range(0.0, 1.0, 0.01) var star_fade: float = 0.15

@export_group("Ambient")
## Strength of the ambient light taken from the sky, so shadows read blue, not black.
@export var ambient_energy: float = 0.6

@export_group("Fog")
## Distance where the fog starts (m).
@export var fog_begin: float = 120.0
## Distance where the fog is full (m). Around the water's edge, so it dissolves instead of cutting off.
@export var fog_end: float = 600.0
## How the fog builds between begin and end (1 = linear, more is a later rise).
@export var fog_curve: float = 1.0
## How thick the fog gets at full (0 to 1).
@export_range(0.0, 1.0, 0.01) var fog_amount: float = 1.0
## How much the fog covers the sky (0 = not at all).
@export_range(0.0, 1.0, 0.01) var fog_sky_affect: float = 0.0

@export_group("Warm lights")
## Colour of the small lamps on the island. The warm against the cool moon is what reads as moonlight.
@export var warm_color: Color = Color(1.0, 0.6, 0.28)
## Strength of the lamps.
@export var warm_energy: float = 2.0
## Reach of the lamps (m).
@export var warm_range: float = 16.0
