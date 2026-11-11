# STATUS

Read at the start of every session. Update at the end. Keep it short. Mechanics are in the CLAUDE.md glossary and in script doc comments. Tuning values are `@export` vars on their scripts, so don't copy them here.

_Last updated: 2026-11-12 (player `Health`, HUD damage flash, `FlightGrid`, flying `Drone` with a beam attack)_

## Current state
- **Main scene:** `levels/city/city.tscn`, a seeded procedural city about 400 m across on a 1000 m grass ground, fogged at the edge. Built at runtime by `CityGenerator`. Headless-verified (no overlaps, same seed gives the same city). Street and skyline screenshots checked.
- **Look:** golden hour. Low warm sun (-14°), warm sky horizon and fog, ACES tonemap, glow, slight contrast and saturation lift. Checked by screenshot only.
- **Grapple, HUD, pause menu, effects, dynamic FOV:** all in. Headless-tested with screenshots. Not yet playtested by hand. RMB is launch only now: the pull (hold RMB) was removed as redundant with swing reel. Reeling now builds real momentum (`SwingRope._reel_momentum`: sideways speed scales by old/new rope length, and the player is pulled toward the hit point at `reel_speed`), kept after the reel stops or the hook detaches. Headless-checked only; likely strong, tune by playtest. Swing reel (Shift) plays a looping reel-in whirr while the rope is actually shortening (`GrappleSfx.set_reeling`, driven by `SwingRope.is_reeling`).
- **Edge detection:** `EdgeProbe` (static queries), `EdgeDetector` (signals `ledge_ahead`, `walls_beside`), `Mantle` (climbs 0.3-1.3 m ledges walked or jumped into, not while the hook is in use). Hook fire snaps a rooftop-face hit onto the roof rim; attach near a lip emits `attached_near_edge` (nothing listens yet). Swing rope correction now stops at walls. WASD steers a swing along the rope's tangent (`swing_steer_speed` 8 m/s, `swing_steer_acceleration` 15 m/s²); the rope length is unchanged. Swing rope shortening on descent is paced at `descent_speed` (6 m/s), so it no longer snaps in; shift reel is the fast one. Headless-tested (probes and mantle); not playtested.
- **Health:** `player/health.gd` (`Health` node on the player: `take_damage`, signals `damaged`, `health_changed`, `died`; nothing handles death yet). `hud/damage_flash.gd` shows a red edge vignette on `damaged`. Headless-tested; look not checked by eye.
- **Health bar and death:** `hud/health_bar.gd` (bottom left, above speed) and `hud/death_screen.gd`: on `Health.died` the tree pauses, a dark red "YOU DIED" veil with a Restart button shows (reloads the scene), and the pause menu's ESC is disabled (`Player._on_died`). Headless-tested; not seen.
- **Drone:** `enemy/`: `Drone` (CharacterBody3D, layer 3, mask 1) owns `DroneFlight`, `BeamAttack`, `BeamVisual`, `DroneSfx`. `DroneFlight` picks a goal on a ring just outside `standoff` (now 15 m) that sees the player, and flies there on an A* path that never enters the standoff sphere; inside the standoff it holds still (no backing away). `BeamAttack`: 7 s cooldown after each shot, then waits for line of sight, charges 1.5 s (rising whine), latches the player's chest position, 0.5 s aim delay (thin red warning line, lock blip), then fires a 1.8 m radius beam that stops at the first building and deals 35 damage to a `Health` it touches. Charge carries on if sight is lost. `levels/city/flight_grid.gd` is a 4x6x4 m voxel grid of open air with `AStar3D`, built from `CityPlan` boxes (about 0.5 s at load; `CityGenerator.flight_grid`, runtime only); `CityLevel` hands it to the drone. Headless-tested: paths never cross a building; timings 1.5 s / 0.5 s / 7 s; hit when still, miss when moved 6 m at lock; no charge behind a wall. Not seen or heard in play (placeholder sphere, synthesized sounds, orb and beam are first passes).
- `levels/level_one.tscn`: old test range (96 `Tower`s). Still loads.

## Current goals
1. **Make the grapple fun, snappy and responsive.** Tune by playtesting. Swing needs the most attention.
2. **Make it look and sound good.** Textures and sounds are first passes (sounds are synthesized in code).

## Structure
- `player/`: `Player` (movement and momentum), `GrappleHook` (IDLE / EXTENDING / ATTACHED; LAUNCH / SWING) with helpers `SwingRope`, `GroundProbe`, `LaunchAim`. Also `GrappleRope` (rope and tip), `GrappleSfx`, `Footsteps`, `Synth`, `ShakeCamera`, `WalkBob`, `DynamicFov`, `LandingWatcher`, `HeadLook`.
- `hud/`: `Hud` scene. `Crosshair`, `ModeLabel`, `ReelBar`, `SpeedReadout`. Reads `GrappleHook.probe_aim()` and its getters.
- `menus/`: `PauseMenu` (ESC), `GameSettings` (volume, sensitivity, fullscreen, saved to `user://settings.cfg`). No main menu yet.
- `effects/`: `EffectsDirector` wires `AttachBurst`, `LandingDust` and `SpeedStreaks`. All `CPUParticles3D`, built in code by `ParticleKit`.
- `levels/city/`: `CitySettings`, `CityLayout` (pure data, runs headless), `CityPlan`, `BuildingBuilder`, `CityGenerator` (@tool; press Regenerate in the editor).
- `world/`: `Tower`, `BuildingCatalog` (Kenney City Kit GLBs in `IMPORTS/`, 1 unit = 10 m), `roads/`, `batching/` (chunked `KitBatch`, `BoxColliders`), `ground/`.
- Input: `grapple` (RMB), `swing` (LMB), `reel` (Shift). Layers: 1 World, 2 Player, 3 Enemy, 4 Bullet.

## Known issues
- Drone: one drone only, no health or way to kill it yet. Death is a frozen screen with Restart only (no respawn point, no score).
- Swing clearance only checks the terrain under the hit point, not along the arc.
- Rope tip advances in `_physics_process`, so it can look steppy on high-refresh monitors.
- A launch aimed slightly down from the ground loses its speed at once (the launch state clears on the floor with `velocity.y <= 0`).
- Re-firing while a hook is active is ignored.
- Mouse capture on pause and resume can't be tested headless. Check by hand.
- Effects and lighting (streaks, wobble, dust, FOV, golden-hour look) are untuned first passes.
- Noise textures load async, so the first frame may show plain colour.
- City: roads are one 10 m tile wide, and density changes lot size only. No edge barrier on the ground.
- Typed `@export var x: Camera3D` loads as null from a `.tscn`. Verify any node export.
- New `class_name`s need `godot --headless --import` before headless runs can see them.
- GDScript 4.7: `Array[T]()` doesn't parse (declare a typed local first). A `const` can't hold `PackedVector3Array([...])`. Scalars passed to functions are copies, so return results.

## Next up
0. **Drone follow-ups:** playtest and tune the beam (timings, damage, visuals, sounds), let the player kill drones.
1. **Playtest the grapple in the city:** rooftops, swings between towers, the 10 m street gaps, launch arc, shake, momentum carry. Then tune. This is the main goal.
2. **Hit-stop on attach:** `Engine.time_scale` dips to about 0.05 for a moment, restored by a timer that ignores the scale.
3. **Remaining cheap visuals:** landing camera dip, building colour variety (MultiMesh tint), vignette and grain, hook trail.
4. **Ambient audio:** a synthesized city hum, with occasional wind or traffic. Wind during momentum flight.
5. **City detail:** sidewalk props (awnings, street lights, barriers), empty-lot fill, far LOD, ground edge barrier.
6. **Menus:** a main menu (Play, Quit) that loads the city. Style the pause menu.
7. **Code:** move sound parameters out of `_ready`. Ask before any Asset Library or addon use.

## Project layout
Feature folders: `hud/`, `menus/`, `effects/`, `player/`, `levels/`, `world/`. Git repo on `main`. The baseline commit `8f51d62` is from before the structure cleanup. `main.tscn` and the stray root `level_one.tscn` are gone.
