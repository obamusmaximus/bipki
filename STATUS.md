# STATUS

Read at the start of every session. Update at the end. Keep it short. Mechanics are in the CLAUDE.md glossary and in script doc comments. All player, grapple and camera-feel tunables live in `GameTuning` (`tuning/game_tuning.tres`), so don't copy values here.

_Last updated: 2026-11-12 (tunables split into stats resources (`tuning/`) with a debug tuning panel in the pause menu; cleanup: removed test range and Tower, stripped pack previews; player `Health`, HUD damage flash, `FlightGrid`, flying `Drone` with a beam attack)_

## Current state
- **Main scene:** `levels/city/city.tscn`, a seeded procedural city about 400 m across on a 1000 m grass ground, fogged at the edge. Built at runtime by `CityGenerator`. Headless-verified (no overlaps, same seed gives the same city). Street and skyline screenshots checked.
- **Look:** golden hour. Low warm sun (-14°), warm sky horizon and fog, ACES tonemap, glow, slight contrast and saturation lift. Checked by screenshot only.
- **Grapple, HUD, pause menu, effects, dynamic FOV:** all in. Headless-tested with screenshots. Not yet playtested by hand. RMB is launch only now: the pull (hold RMB) was removed as redundant with swing reel. Reeling now builds real momentum (`SwingRope._reel_momentum`: sideways speed scales by old/new rope length, and the player is pulled toward the hit point at `reel_speed`), kept after the reel stops or the hook detaches. Headless-checked only; likely strong, tune by playtest. Swing reel (Shift) plays a looping reel-in whirr while the rope is actually shortening (`GrappleSfx.set_reeling`, driven by `SwingRope.is_reeling`).
- **Edge detection:** `EdgeProbe` (static queries), `EdgeDetector` (signals `ledge_ahead`, `walls_beside`; nothing listens to `ledge_ahead` now that mantle is gone). Hook fire snaps a rooftop-face hit onto the roof rim; attach near a lip emits `attached_near_edge` (nothing listens yet). Swing rope correction stops at walls. WASD steers a swing along the rope's tangent (`swing_steer_speed`, `swing_steer_acceleration`); the rope length is unchanged. Swing rope shortening on descent is paced at `descent_speed`; shift reel is the fast one. Headless-tested; not playtested.
- **Health:** `player/health.gd` (`Health` node on the player: `take_damage`, signals `damaged`, `health_changed`, `died`; nothing handles death yet). `hud/damage_flash.gd` shows a red edge vignette on `damaged`. Headless-tested; look not checked by eye.
- **Health bar and death:** `hud/health_bar.gd` (bottom left, above speed) and `hud/death_screen.gd`: on `Health.died` the tree pauses, a dark red "YOU DIED" veil with a Restart button shows (reloads the scene), and the pause menu's ESC is disabled (`Player._on_died`). Headless-tested; not seen.
- **Drone:** `enemy/`: `Drone` (CharacterBody3D, layer 3, mask 1) owns `DroneFlight`, `BeamAttack`, `BeamVisual`, `DroneSfx`. `DroneFlight` picks a goal on a ring just outside `standoff` that sees the player, and flies there on an A* path that never enters the standoff sphere; inside the standoff it holds still (no backing away). `BeamAttack`: `cooldown` after each shot, then waits for line of sight, charges for `charge_time` (rising whine), latches the player's chest position, waits `aim_delay` (thin red warning line, lock blip), then fires a `beam_radius` beam that stops at the first building and deals `damage` to a `Health` it touches. Charge carries on if sight is lost. `levels/city/flight_grid.gd` is a 4x6x4 m voxel grid of open air with `AStar3D`, built from `CityPlan` boxes (about 0.5 s at load; `CityGenerator.flight_grid`, runtime only); `CityLevel` hands it to the drone. Headless-tested: paths never cross a building; charge, aim and cooldown timings follow the tuned values; hit when still, miss when moved far enough at lock; no charge behind a wall. Not seen or heard in play (placeholder sphere, synthesized sounds, orb and beam are first passes).

- **Swing smoothness (playtested once by the user; assist then made firmer):** `WallRun` (graze a wall fast and you run along it), `AvoidanceAssist` (predicted-hit steering and roof-lip lift, driven by `TrajectoryPredictor`), turn-rate air steering (toggle `air_turn_rate_enabled`), swing anchor push-out on wall hooks (toggle `anchor_push_out_enabled`), `CameraLean`, and the faint `TrajectoryArc` HUD line. All tuned in the debug panel (Player, Camera, Grapple, HUD tabs). Headless: with the assist on, flying along a building edge (even 2 m inside it) stays at least 2.5 m away and keeps its speed; wall run latches on a graze, resets falling speed, caps speed, jumps off, and doesn't trigger head-on. The HUD arc is blue and hides behind buildings; the minimap has an opaque grey box.

## Current goals
1. **Make the grapple fun, snappy and responsive.** Tune by playtesting. Swing needs the most attention.
2. **Make it look and sound good.** Textures and sounds are first passes (sounds are synthesized in code).

- **Minimap:** `hud/minimap*.gd`, top-right: isometric wireframe of `CityGenerator.building_boxes` (131 buildings in the seeded city), glowing player dot, fading 3D trail. Follows `hud_scale`; tuned in the HUD tab (`MinimapStats`: one `minimap_scale` for size, one `minimap_margin` for both edges). Checked by screenshot and headless unit tests (trail pruning, projection fit); not seen in play. The drone is not shown on it yet. HUD bottom-left is speed above, health bar below.

## Structure
- `tuning/`: `PlayerStats`, `GrappleStats`, `CameraFeel`, `DroneStats`, `HudStats`, `MinimapStats` (typed Resources, one .tres each: `*_default.tres`). Owners (`Player`, `Drone`) hold them and pass them to their parts via `setup()`. Replaces the earlier single `GameTuning`. `CitySettings` stays separate.
- `menus/tuning/`: `TuningPanel` (debug panel opened from the pause menu, debug builds only; tabs Player/Camera/Grapple/Drone/HUD, sub-label per `@export_group`, live edit, Save tab to .tres, Reset tab) and `TuningFields` (builds controls from a resource's property list, so a new `@export` shows up with no panel changes). Camera feel has its own tab until it is simplified into `GameSettings`. `HudStats.hud_scale` is on the same tab and scales the HUD and the menus (menus on mouse release). The HUD's bottom corners are `VBoxContainer`s (`BottomLeft`, `BottomCenter`) scaled as a group; the reel bar fades instead of hiding so it keeps its slot.
- `player/`: `Player` (movement and momentum), `GrappleHook` (IDLE / EXTENDING / ATTACHED; LAUNCH / SWING) with helpers `SwingRope`, `GroundProbe`, `LaunchAim`. Also `GrappleRope` (rope and tip), `GrappleSfx`, `Footsteps`, `Synth`, `ShakeCamera`, `WalkBob`, `DynamicFov`, `LandingWatcher`, `HeadLook`.
- `hud/`: `Hud` scene. `Crosshair`, `ModeLabel`, `ReelBar`, `SpeedReadout`. Reads `GrappleHook.probe_aim()` and its getters.
- `menus/`: `PauseMenu` (ESC), `GameSettings` (volume, sensitivity, fullscreen, saved to `user://settings.cfg`). No main menu yet.
- `effects/`: `EffectsDirector` wires `AttachBurst`, `LandingDust` and `SpeedStreaks`. All `CPUParticles3D`, built in code by `ParticleKit`.
- `levels/city/`: `CitySettings`, `CityLayout` (pure data, runs headless), `CityPlan`, `BuildingBuilder`, `CityGenerator` (@tool; press Regenerate in the editor).
- `world/`: `BuildingCatalog` (Kenney City Kit GLBs in `IMPORTS/`, 1 unit = 10 m; the space-kit and space-station-kit packs there are kept for later, unused; previews, samples and isometric renders were stripped), `roads/`, `batching/` (chunked `KitBatch`, `BoxColliders`), `ground/`.
- Input: `grapple` (RMB), `swing` (LMB), `reel` (Shift). Layers: 1 World, 2 Player, 3 Enemy, 4 Bullet.

## Todo / parked
- **Mantle (removed, didn't work):** climbing a ledge walked or jumped into. The old version (a `Mantle` component with try_start/step, driven by `EdgeDetector.ledge_ahead`) is in git history before the commit that removed it. Rework idea: the assist's roof-lip lift may cover most of it; a proper mantle can reuse `EdgeProbe.find_ledge` and `ledge_ahead`.
- **Smoother swing rope:** replace the hard position correction in `SwingRope.constrain` with a soft constraint to remove small snaps (explained to the user, not built).
- **Soft speed limit:** considered, not built (see discussion: prefer drag above a threshold over a hard cap, and clamp the reel momentum gain first).
- **Drone on the minimap:** not shown yet.

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
0. **Tuning:** simplify camera feel into a few intensity settings in `GameSettings` once tuned; add enemy variants as extra `.tres` files. The panel pauses the game (it lives in the pause menu), so tune, resume, test.
0. **Drone follow-ups:** playtest and tune the beam (timings, damage, visuals, sounds), let the player kill drones.
1. **Playtest the grapple in the city:** rooftops, swings between towers, the 10 m street gaps, launch arc, shake, momentum carry. Then tune. This is the main goal.
2. **Hit-stop on attach:** `Engine.time_scale` dips to about 0.05 for a moment, restored by a timer that ignores the scale.
3. **Remaining cheap visuals:** landing camera dip, building colour variety (MultiMesh tint), vignette and grain, hook trail.
4. **Ambient audio:** a synthesized city hum, with occasional wind or traffic. Wind during momentum flight.
5. **City detail:** sidewalk props (awnings, street lights, barriers), empty-lot fill, far LOD, ground edge barrier.
6. **Menus:** a main menu (Play, Quit) that loads the city. Style the pause menu.
7. **Code:** move sound parameters out of `_ready`. Ask before any Asset Library or addon use.

## Project layout
Feature folders: `hud/`, `menus/`, `effects/`, `player/`, `levels/`, `world/`. Git repo on `main`. The baseline commit `8f51d62` is from before the structure cleanup. `main.tscn`, `level_one.tscn` (old test range) and `Tower` are gone.
