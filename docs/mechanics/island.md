# Island level (night, water) — PLANNED, NOT BUILT

Read this before building the island level. It holds the agreed plan; once a step is built, rewrite that part to describe the code (see `docs/mechanics/README.md`). Name tunables, never their values.

**Scripts (planned):** `levels/island/` (`island.tscn`, `IslandLevel`, `IslandLook`), `effects/water/` (`water.gdshader` and its `.gdshaderinc` modules, `WaterLook`), `levels/arena/grid.gdshaderinc` (grid math shared with the arena). Tunables (planned): `NightStats` (Level tab), `WaterStats` (new tab or Level tab).
**Related:** level wiring and the arena grid in `levels_and_hud.md`; the jetpack it tests in `jet.md`.

## Intent
A second, open test level for the jetpack kit: long sight lines and room for the afterburner, scouting and later bombardment, and a first pass at a cohesive lo-fi look (moonlit night, faceted water). Lo-fi, never realism. Renderer stays GL Compatibility (below).

## Layout (decided)
- **Island:** a rectangular box, 100 m across, its top a walkable surface using the same reference grid as the arena. Place it at x and z 0 to 100 m so the grid's world-space 50 m scale bars land in the middle with no shader change. Top at y = 20.
- **Sea level:** y = 0, 20 m below the top. The cliff sides are 20 m tall walls (wall run, grapple).
- **Water:** stretches 500 m out from the island on every side (a square about 1100 m across), nothing beyond. Purely decoration: no underwater state, no swimming. Its only collision is a flat surface: a `StaticBody3D` box on World (layer 1), sized to the water. The player can land and walk on it.
- **Night:** lit as moonlight (below).

## Build order
1. **Skeleton (`levels/island/`).** Island box with collision on World, the water collision, player spawn, `EnemySpawner`s, an `AttackCoordinator`, a flight grid (island plus a margin over the water, so fights can move out to sea), minimap boxes read from the collision shapes: the same wiring the arena and city hand the player and enemies (`levels_and_hud.md`). Loadable the same way the city is.
   - **Grid:** `grid.gdshader` is `unshaded, cull_front` (seen from inside the arena box) with `ROOM` and `CENTRE` constants, so unshaded it would ignore the moonlight. Move the grid math into `grid.gdshaderinc`; the arena keeps an unshaded inside-box wrapper, the island gets a lit `cull_back` wrapper writing the pattern into `ALBEDO`. Check the arena looks identical afterwards. `ArenaScale` labels on the top face only.
2. **Night lighting** (before the water, whose look depends on it). Tunables in `NightStats`, applied live by `IslandLook` (mirroring `ArenaLook`).
   - **Moon:** a `DirectionalLight3D`, low (roughly 25–35° up), cool blue-white, low energy, soft shadows. Long low shadows across the grid sell moonlight more than darkness does.
   - **Sky:** a custom sky shader: deep navy gradient, a lighter band at the horizon, a moon disc along the light's direction, sparse hashed stars.
   - **Ambient** from the sky and low, so shadows read blue, not black.
   - **Fog:** depth fog in the horizon colour, so the water's edge dissolves instead of cutting off.
   - **Warm accents:** two or three small warm `OmniLight3D`s on the island (say, at the spawners); the warm and cool contrast is what reads as moonlight. Compatibility limits lights per mesh, so keep it to a few.
   - **Readability:** night means blue and readable, not dark. Check drones, track markers and the HUD against the sky in this step.
   - **Glow:** costly in the arena (about 3 ms per frame on an M1, `levels_and_hud.md`); a moon bloom is optional and measured first.
3. **Water v1 (`effects/water/`).** Tunables in `WaterStats`, applied by `WaterLook`.
   - **Mesh:** a coarse subdivided plane, quads a few metres across: the facets are the look, and the vertex count stays small at 1100 m.
   - **Waves:** a few summed directional sine waves with analytic height and slope, so normals are exact and facets light crisply.
   - **Shading:** a posterized two- or three-step ramp, deep to shallow. The centrepiece is a **moon glitter path**: a hard-edged specular stripe toward the moon, broken by the facets. The moon direction comes in as a uniform from the moon light, so moving the moon moves the path.
   - **Distance:** waves fade out away from the island so the far water stays calm and doesn't shimmer.
4. **Shore interaction.** The island is a rectangle, so the shader gets the exact distance to it from a box distance function on a uniform (island rect). This needs no depth texture, which avoids the one Compatibility risk. v1: a noisy foam band at the cliffs. Later: foam bands moving toward the shore and fading, and wave height damping near the island. Limit: anything added later (a rock) gets no foam unless it's added to the distance function.
5. **Later, not now:** breaking waves, foaming crests, screen-texture refraction. The module split below makes each one a new function, not a rewrite.
6. **Docs:** rewrite this doc to describe what was built; add the STATUS row and glossary terms as they become real.

## Water shader structure (for iteration)
```
effects/water/
  water.gdshader        # vertex() and fragment() only call the modules
  waves.gdshaderinc     # wave height and normal
  shore.gdshaderinc     # distance to the island, shore factor
  foam.gdshaderinc      # foam mask from crest height and shore factor
  shading.gdshaderinc   # ramp, posterize, moon glitter
```
- One job per file: breaking waves would touch `waves` and `foam` only.
- Wave height and shore factor are computed in `vertex()` and passed to `fragment()` as varyings, so foam and colour reuse them.
- Every number is a uniform fed from `WaterStats`, tuned live and saved to the `.tres` like everything else.

## Decided
- **Renderer: stay on GL Compatibility.** Lo-fi looks are shader work (posterize, flat shading, displacement, noise), which both renderers run; Forward+ adds realism features (SSR, SSAO, SDFGI, volumetric fog). Compatibility is cheaper on weak GPUs and the only one with a web export. A later switch costs little code but re-opens a tuned look (lighting, shadows, glow and transparency differ), so if a wanted feature turns out Forward+-only, switch then, before much art is tuned. Keep shaders free of Forward+-only features until then.
- **Waves aren't in the rewind:** cosmetic and stateless (driven by time), they keep moving during a rewind.

## Open questions
- Moon bloom (glow cost) and whether a full-screen posterize or outline pass joins the look later.
- Island top details beyond the grid (cover for a grounded player, `jet.md` weapon rules) once the skeleton plays.
