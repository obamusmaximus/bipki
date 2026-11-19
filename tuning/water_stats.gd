class_name WaterStats
extends Resource
## Tunable numbers for the island's faceted sea: the mesh, the waves, where they calm down, the shading and the moon
## glitter. One .tres per preset (tuning/water_default.tres). `IslandLevel` holds it, `WaterLook` applies it live.

@export_group("Mesh")
## Size of one quad of the water mesh (m). The facets are the look: bigger is chunkier and cheaper.
@export_range(1.0, 20.0, 0.5) var quad_size: float = 4.0

@export_group("Waves")
## Number of summed sine waves. Each next one is shorter, lower and turned a little.
@export_range(1, 6, 1) var wave_count: int = 4
## Height of the first, longest wave from its middle to its crest (m).
@export var wave_height: float = 0.6
## Length of the first wave (m).
@export var wavelength: float = 30.0
## Each next wave's length as a share of the one before.
@export_range(0.2, 0.95, 0.01) var wavelength_falloff: float = 0.6
## Each next wave's height as a share of the one before. Below `wavelength_falloff` the shorter waves are gentler
## ripples on the long swell, so the swell reads; equal to it, every wave is as steep as the first.
@export_range(0.05, 0.95, 0.01) var height_falloff: float = 0.4
## Compass direction the waves travel toward (degrees).
@export_range(-180.0, 180.0, 1.0) var wave_direction: float = 30.0
## How far the next waves turn away from the first, alternating sides (degrees).
@export_range(0.0, 90.0, 1.0) var direction_spread: float = 35.0
## Wave speed as a share of real deep-water speed for its length (1 = physical).
@export_range(0.0, 3.0, 0.01) var wave_speed: float = 1.0

@export_group("Calm")
## Distance from the island's cliffs where the waves start to calm down (m).
@export var calm_begin: float = 150.0
## Distance from the island's cliffs where the water is flat (m). Keeps the far water from shimmering.
@export var calm_end: float = 400.0
## How far out from the cliffs the waves are damped (m): they shrink toward the cliff, as if the shore broke them.
@export var shore_calm_reach: float = 25.0
## Share of the wave height left right at the cliffs (1 = no damping).
@export_range(0.0, 1.0, 0.01) var shore_calm_level: float = 0.35

@export_group("Shading")
## Colour of the water where no moonlight reaches it: facets turned away from the moon, and the island's shadow.
## The water never gets darker than this.
@export var deep_color: Color = Color(0.05, 0.11, 0.22)
## Colour the moonlight lifts the water toward, in steps, on facets turned to the moon.
@export var shallow_color: Color = Color(0.16, 0.3, 0.5)
## Number of brightness steps from deep to shallow (posterized), for the light and the crest tint.
@export_range(2, 6, 1) var ramp_steps: int = 3
## How strongly a facet's tilt toward or away from the light changes its step. Calm water sits in the middle step;
## higher makes gentler waves cross into the steps above and below, so the wave fronts show as stripes.
@export_range(0.0, 20.0, 0.1) var ramp_contrast: float = 3.0
## How much lighter the highest crests and darker the deepest troughs are, stepped per facet (0 = off). Shows the
## waves from any angle, also with the moon behind the camera.
@export_range(0.0, 1.0, 0.01) var crest_tint: float = 0.25
## Strength of the moonlight on the water.
@export_range(0.0, 3.0, 0.01) var light_strength: float = 1.0
## How faceted the water looks: 1 lights every triangle flat, 0 lights it smooth.
@export_range(0.0, 1.0, 0.01) var facet_amount: float = 1.0

@export_group("Shore foam")
## Colour of the foam along the cliffs.
@export var foam_color: Color = Color(0.75, 0.84, 0.95)
## How far the foam band reaches out from the cliffs at its widest (m).
@export var foam_width: float = 5.0
## How ragged the band's outer edge is: 0 is a straight band, 1 lets the noise eat it back to the cliff.
@export_range(0.0, 1.0, 0.01) var foam_raggedness: float = 0.6
## Size of the blobs in the ragged edge (m).
@export var foam_noise_scale: float = 3.0
## How fast the ragged edge drifts and churns (m per second).
@export var foam_speed: float = 0.6
## How much of the foam's colour shows even where no light reaches it (in the island's shadow), 0 to 1.
@export_range(0.0, 1.0, 0.01) var foam_glow: float = 0.35

@export_group("Shore bands")
## Lines of foam parallel to the cliffs travel in toward them and fade. Distance between two lines (m).
@export var band_spacing: float = 9.0
## How fast the lines travel toward the cliffs (m per second).
@export var band_speed: float = 1.2
## Thickness of a line at its widest (m).
@export var band_width: float = 0.9
## How far out the lines appear (m from the cliffs). They fade in there and thin out into the foam band.
@export var band_reach: float = 32.0
## How much of each line the noise breaks away: 0 is an unbroken line, 1 leaves none.
@export_range(0.0, 1.0, 0.01) var band_breakup: float = 0.45

@export_group("Glitter")
## Colour of the glitter path toward a directional light (the moon here, a sun elsewhere).
@export var glitter_color: Color = Color(0.85, 0.92, 1.0)
## Brightness of the glitter.
@export_range(0.0, 4.0, 0.01) var glitter_strength: float = 1.5
## How closely a facet must mirror the moon to glitter (closer to 1 is a narrower path).
@export_range(0.8, 1.0, 0.001) var glitter_threshold: float = 0.985
## Glitter toward lamps (omni and spot lights), in each lamp's own colour and scaled by its energy (0 = none).
## It fades with distance from the lamp like its light does, so it's higher than the directional glitter's strength.
@export_range(0.0, 30.0, 0.1) var lamp_glitter: float = 4.0
