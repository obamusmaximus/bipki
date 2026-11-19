# Island level (night, water)

Read this before working on the island level. Steps 1 (skeleton), 2 (night lighting), 3 (water v1) and 4 (shore: foam band, shore bands, shore calm) are built and described under **Built**; the rest of the build order is the agreed plan. Once a step is built, rewrite that part to describe the code (see `docs/mechanics/README.md`). Name tunables, never their values.

**Scripts:** `levels/island/` (`island.tscn`, `IslandLevel`, `IslandLook`, `island_grid.gdshader`, `night_sky.gdshader`), shared with the arena: `levels/arena/grid.gdshaderinc` (grid math), `GridLook` (grid uniforms from `ArenaStats`), `ArenaScale` (labels), `FlightGrid`. `effects/water/` (`water.gdshader`, `waves.gdshaderinc`, `shore.gdshaderinc`, `foam.gdshaderinc`, `shading.gdshaderinc`, `WaterLook`). Tunables: `NightStats` (Level tab), `WaterStats` (Water tab; `water_default.tres` in use, `water_first_pass.tres` a preset, below); the grid reads `ArenaStats` (Level tab, shared with the arena).
**Related:** level wiring and the arena grid in `levels_and_hud.md`; the jetpack it tests in `jet.md`.

## Intent
A second, open test level for the jetpack kit: long sight lines and room for the afterburner, scouting and later bombardment, and a first pass at a cohesive lo-fi look (moonlit night, faceted water). Lo-fi, never realism. Renderer stays GL Compatibility (below).

## Layout (decided)
- **Island:** a rectangular box, 100 m across, its top a walkable surface using the same reference grid as the arena. Place it at x and z 0 to 100 m so the grid's world-space 50 m scale bars land in the middle with no shader change. Top at y = 20.
- **Sea level:** y = 0, 20 m below the top. The cliff sides are 20 m tall walls (wall run, grapple).
- **Water:** stretches 500 m out from the island on every side (a square about 1100 m across), nothing beyond. Purely decoration: no underwater state, no swimming. Its only collision is a flat surface: a `StaticBody3D` box on World (layer 1), sized to the water. The player can land and walk on it.
- **Night:** lit as moonlight (below).

## Built
### Step 1: skeleton
- **Scene:** `levels/island/island.tscn`, the main scene (the arena and city are still loadable on their own). `IslandLevel` wires it the way `ArenaLevel` does: spawners report drones, each drone (and any a rewind remakes) gets the flight grid, the player and the `AttackCoordinator`, the player's death requests the `Rewind`.
- **Island:** `Island` (a `StaticBody3D` on World) with one box mesh and one box collision shape, 100 m by 20 m by 100 m, spanning 0 to 100 m in x and z with its top at `IslandLevel.ISLAND_TOP`. Its sides are the cliffs (wall run, grapple).
- **Water:** `Water` (a `StaticBody3D` on World) with a box collision whose top is at y = 0, about 1100 m across, and its mesh (`Water/Mesh`, step 3). The collision stays flat whatever the waves do. The player can land and walk on it.
- **Grid:** the grid math lives in `levels/arena/grid.gdshaderinc` as `grid_colour(world_pos, face)`. `grid.gdshader` (the arena, `unshaded, cull_front`) and `island_grid.gdshader` (lit, `cull_back`, writes the pattern into `ALBEDO`, fully rough, no specular) are thin wrappers around it. Both grids take their uniforms from `ArenaStats` through `GridLook.apply` (called by `ArenaLook` and `IslandLook`), so tuning the arena's grid tunes the island's too. The include keeps the arena's `ROOM` and `CENTRE` constants, which is why the island sits at 0 to 100 m: its scale bars land in the middle, and the cliffs get grid bars and a notched vertical bar of their own.
- **Labels:** `ArenaScale.setup(stats, floor_only, floor_height)` puts the scale-bar numbers on the island's top only, raised to `ISLAND_TOP`.
- **Flight grid:** built from the island box plus the water box cut down to the island and `FLIGHT_REACH` on every side, with `FlightGrid.from_boxes`' `pad` at 0, so the grid ends exactly there and the water blocks the air just above the sea (as the arena's floor does). It reaches `FLIGHT_HEADROOM` above the island's top.
- **Minimap:** shows the island's box only (the water isn't handed over), so a player far out to sea is pinned to the box's edge.
- **Spawners:** two over the island and one over the sea (`SpawnerSea`), all drones.

### Step 2: night lighting
All of it follows `NightStats`, applied live by `IslandLook` (it also applies the grid from `ArenaStats`, through `GridLook`).
- **Moon:** the `Moon` `DirectionalLight3D` with shadows. `IslandLook` turns it from `moon_elevation` and `moon_azimuth` (the node's rotation is overwritten, so turn it in the tuning panel, not the editor) and sets its colour, energy, `shadow_blur` and `shadow_distance`.
- **Sky:** `night_sky.gdshader` on the environment's `Sky`: a gradient from `horizon_color` up to `zenith_color` over `horizon_band`, sparse hashed stars (`star_density`, `star_grid`, `star_size`, `star_brightness`, fading out toward the horizon below `star_fade`), and a moon disc with a soft halo along `LIGHT0_DIRECTION`, so the disc always sits where the moonlight comes from. Below the horizon the sky stays horizon colour. It doesn't use `TIME`, so it's static.
- **Ambient:** from the sky (`ambient_energy`), so shadows read blue, not black. Reflections come from the background (the sky) by default; the grid is fully rough, so they barely show.
- **Fog:** depth fog (`fog_mode` depth) in `horizon_color`, from `fog_begin` to `fog_end` with `fog_curve` and `fog_amount`; `fog_sky_affect` leaves the sky clear by default. The sea fades into the horizon band instead of cutting off at its edge.
- **Warm lamps:** the `OmniLight3D`s under `WarmLights` (one below each island spawner, one at the cliff edge facing `SpawnerSea`), no shadows, with `warm_color`, `warm_energy` and `warm_range`. `IslandLevel` hands `IslandLook` every `OmniLight3D` child, so a lamp is added by placing one there. Keep it to a few (Compatibility's per-mesh light limit).
- **Readability (checked in renders):** the HUD panels and the track markers (red outlines drawn on screen) read well on the navy. Drones are the weak spot: their dark grey body is low contrast against the night sky and they read mostly by their glowing red eye. A fix (a lighter drone body, a rim or emissive trim) belongs to `drones.md`; not done.
- **Glow:** not added (moon bloom stays an open question below).

### Step 3: water v1
All of it follows `WaterStats` (Water tab), applied live by `WaterLook`, which `IslandLevel` hands the water mesh and the island's box.
- **Mesh:** `Water/Mesh` is a `PlaneMesh` the size of the water collision. `WaterLook` subdivides it into quads of about `quad_size` and grows its cull margin by the highest possible crest, since the shader lifts vertices above the flat mesh.
- **Shader:** `water.gdshader` only calls the modules (structure below). Waves are a sum of `wave_count` directional sine waves with analytic height and slope (`waves.gdshaderinc`): the first is `wavelength` long and `wave_height` high, travelling toward `wave_direction`; each next one is `wavelength_falloff` as long, `height_falloff` as high and turned `direction_spread` further, alternating sides (a height falloff below the length falloff makes the short waves gentler ripples on the long swell, so the swell reads); each moves at deep-water speed for its length times `wave_speed`. `TIME` drives them, so they keep moving during a rewind.
- **Calm:** the wave height is scaled down from 1 to 0 between `calm_begin` and `calm_end` metres from the island's cliffs (`shore.gdshaderinc`'s box distance to `island_rect`), so the far water is flat and doesn't shimmer.
- **Facets:** `fragment()` takes each triangle's own normal from screen-space derivatives and blends it with the smooth analytic normal by `facet_amount` (1 is fully faceted).
- **Shading** (`shading.gdshaderinc`): `deep_color` is emitted as a floor, so facets turned away from the moon and the island's shadow stay deep blue, never black (the night's ambient light alone is far too dim on a dark surface). The light adds `shallow_color` on top in `ramp_steps` hard steps, scaled by `light_strength`. The steps are measured from how flat water is lit, not from N dot L itself: calm water sits in the middle step at any moon height, and `ramp_contrast` sets how far a facet must tilt toward or away from the light to change step, so the two sides of each wave fall in different steps and the swell shows as stripes from any angle. On top, `crest_tint` makes each facet lighter or darker in the same number of steps by its height (one height per triangle, a `flat` varying), so crests and troughs show even with the moon behind the camera. The lighting happens in a custom `light()`, so the lamps light the water in steps too, and the moon's shadows fall on it.
- **Glitter** (the moon glitter here): in `light()`, for every light: a facet whose mirror reflection of the light comes within `glitter_threshold` of the eye glitters, hard-edged, and the facets break it into a path toward that light. A directional light glitters in `glitter_color` times `glitter_strength`; a lamp (omni or spot) in its own light colour and energy times `glitter_strength` and `lamp_glitter`, fading with distance like its light (`glitter_tint`). It reads each light's own direction, so there's no moon uniform: turning the moon (`NightStats`) moves the path.
- **Lighting is level-agnostic:** nothing in the water names a light. Every light that reaches it, of any kind, gets the stepped light (measured from how that light hits flat water), its shadows and its own glitter path. So a sun in a day level, or street lights, work with the same shader and a different `WaterStats` `.tres`. What is island-specific is the shore: one box (`island_rect`), handed over by the level through `WaterLook.setup`.
- **Preset `water_first_pass.tres`:** the first look of the water, before the steps were measured from flat water. It sets `ramp_contrast` to 1, `crest_tint` to 0 and `height_falloff` equal to `wavelength_falloff`, which reproduces it exactly while `NightStats.moon_elevation` is 30 (only then does flat water face the moon at 0.5, where the two step formulas agree). To use it, point `IslandLevel.water_stats` at it in the inspector; the tuning panel lists it under its own header, but edits there only show while it's in use. If `wavelength_falloff` is retuned in the default, match `height_falloff` to it in the preset.
- **Not measured:** the frame cost of the sea (about 76,000 vertices at the default quad size).

### Step 4: shore
- **Shore factor** (`shore_factor` in `shore.gdshaderinc`): 1 at the cliffs, falling straight to 0 at `foam_width` out, from the box distance to `island_rect`. `fragment()` measures the distance per pixel (exact, so the band's corners stay round), not through a varying.
- **Foam** (`foam.gdshaderinc`): the shore factor cut hard (anti-aliased) against two octaves of value noise that drift different ways at `foam_speed`, with blobs `foam_noise_scale` across. `foam_raggedness` sets how far the noise eats the band's outer edge back; the water right at the cliff is always foam. The foam replaces the water colour (`foam_color`), is lit in the same steps, and keeps `foam_glow` of its colour as a floor, so it still shows in the island's shadow. It's computed from world position and `TIME`, so it isn't in the rewind (like the waves).
- **Look:** the edge is smooth noise blobs, softer than the faceted water around it. A stepped or faceted foam edge is a possible later pass.
- **Shore bands** (`foam_bands`): broken lines of foam at constant distance from the cliffs (so they round the corners), `band_spacing` apart, travelling in at `band_speed`. They fade in from `band_reach` out and thin out into the foam band; `band_width` is their widest thickness, and `band_breakup` cuts them against a noise into dashes. The foam is the larger of the band and the lines. They're regular enough to read as contour rings around the island at the defaults.
- **Shore calm** (`wave_scale`): within `shore_calm_reach` of the cliffs the wave height shrinks to `shore_calm_level` of itself at the cliff, on top of the far calm.
- **Limit:** anything added later (a rock) gets no foam and no calm unless it's added to the distance function.


## Build order
1. **Skeleton:** built (above).
2. **Night lighting:** built (above). Long low shadows across the grid sell moonlight more than darkness does; night means blue and readable, not dark.
3. **Water v1:** built (above).
4. **Shore interaction.** The island is a rectangle, so the shader gets the exact distance to it from a box distance function on a uniform (`island_rect`, in `shore.gdshaderinc`). This needs no depth texture, which avoids the one Compatibility risk. Built (above): a noisy foam band at the cliffs, foam bands moving toward the shore and fading, and wave height damping near the island.
5. **Later, not now:** breaking waves, foaming crests, screen-texture refraction. The module split below makes each one a new function, not a rewrite.
6. **Docs:** rewrite this doc to describe what was built; add the STATUS row and glossary terms as they become real.

## Water shader structure (for iteration)
```
effects/water/
  water.gdshader        # vertex(), fragment() and light() only call the modules
  waves.gdshaderinc     # wave height and slope
  shore.gdshaderinc     # distance to the island, calm factor, shore factor
  foam.gdshaderinc      # foam mask from the shore factor (crest height later)
  shading.gdshaderinc   # deep floor, posterized ramp, moon glitter
```
- One job per file: breaking waves would touch `waves` and `foam` only.
- Wave height (`wave_height_at`, for crest foam later) is computed in `vertex()` and passed to `fragment()` as a varying. The shore distance is measured again per pixel in `fragment()`: a varying would cut the band's corners across 4 m triangles.
- Every number is a uniform fed from `WaterStats`, tuned live and saved to the `.tres` like everything else.

## Tried and passed on
- **Glitter from directional lights only:** lamps lit the water but never glittered, so a street light in another level would have had no reflection. Now every light glitters.
- **Lamp glitter in the lamp's pure hue:** normalising the lamp colour dropped its energy, leaving only the distance falloff, so the glitter was too faint to see. It now uses the full light colour.
- **Steps from N dot L itself:** the first ramp cut the absolute light facing into steps. Under a low moon calm water all sat in one step and only the steepest facets crossed into another, so from above the sea read as a light blue plane sprinkled with polygons; the waves only showed in the glitter path. Replaced by steps measured from flat water (`ramp_contrast`) and the crest tint.
- **Every wave as steep as the first** (height scaled by the length falloff): the short waves tilted facets as much as the swell and turned it into a noisy mosaic. Replaced by a separate `height_falloff`.

## Decided
- **Renderer: stay on GL Compatibility.** Lo-fi looks are shader work (posterize, flat shading, displacement, noise), which both renderers run; Forward+ adds realism features (SSR, SSAO, SDFGI, volumetric fog). Compatibility is cheaper on weak GPUs and the only one with a web export. A later switch costs little code but re-opens a tuned look (lighting, shadows, glow and transparency differ), so if a wanted feature turns out Forward+-only, switch then, before much art is tuned. Keep shaders free of Forward+-only features until then.
- **Waves aren't in the rewind:** cosmetic and stateless (driven by time), they keep moving during a rewind.

## Open questions
- Drone readability at night (above): a drone-side fix in `drones.md`, if playtests find them hard to see.
- Moon bloom (glow cost about 3 ms per frame on an M1 in the arena, `levels_and_hud.md`; measure first) and whether a full-screen posterize or outline pass joins the look later.
- Island top details beyond the grid (cover for a grounded player, `jet.md` weapon rules) once the skeleton plays.
