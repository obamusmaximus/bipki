# STATUS

Read at the start of every session. Update at the end. Keep it short. Mechanics are in the CLAUDE.md glossary and in script doc comments. All tunables live in the stats resources in `tuning/` (see CLAUDE.md) and the user changes them between prompts, so don't copy values here and don't be surprised by changed ones.

**Playtesting:** the user playtests thoroughly after every feature. If they don't mention a feature, it works as intended. Don't label things "not playtested".

_Last updated: 2026-11-16 (branch `core-v2`: swing rope no longer reels itself in on the ground, player weight (own gravity, fall gravity, jump cut), melee body hit with knockback, head-on wall latch (camera turn to run), hit-stop on attach, ground-launch lift; swing turn rate tried and switched off, enemies on the minimap; drones spread out around the player, seeking range, staggered beams, random drone spawns)_

## Current state
- **Main scene:** `levels/city/city.tscn`, a seeded procedural city about 400 m across on a 1000 m grass ground, fogged at the edge. Built at runtime by `CityGenerator`. Golden-hour look.
- **Grapple:** launch (RMB), swing (LMB) with reel (Shift) and reel momentum, rope retract spring, hit-stop on attach (`HitStop`, `hit_stop_*` in GrappleStats; skipped while bullet time is on). Swing steering is the tangent push (`swing_steer_*`); a turn-rate version exists behind `swing_turn_rate_enabled` but is off by default because the push feels like real swinging. Air steering is in the same helper (`Steering.air`). A launch fired while standing gets at least `launch_ground_lift` upward speed, so one aimed slightly down no longer dies on the floor.
- **Player weight:** the player has its own gravity (`BodyGravity`, PlayerStats "Gravity" group), heavier than the project's, with `fall_gravity_scale` after the apex and `jump_release_cut` for short hops. The swing (`swing_gravity_scale`) and the first `launch_gravity_time` of a launch (`launch_gravity_scale`) use a share of it, set so swings and launch reach stayed about as before; raise them for heavier swings and shorter launches. Wall run gravity scales were lowered so the absolute wall-run sink is unchanged. Jump and double jump were lowered to roughly a building-floor hop each. Enemies and thrown things keep project gravity. `TrajectoryPredictor` uses the same `BodyGravity`.
- **Swing on the ground:** standing on the floor at walking pace while hooked (not reeling), the player walks and jumps normally and the rope only limits distance; faster (a swing grazing the ground) still slides. The ground-clearance retraction (`SwingRope._retract_for_descent`) is off while grounded and drops any retraction still owed, and an attach from at or below the clear arc's bottom (standing far away) never retracts. Before, floor jitter made it reel the player in.
- **Swing v2:** `WallRun`, `AvoidanceAssist`, `TrajectoryPredictor`, `CameraLean`, `TrajectoryArc`, `SoftSpeedLimit`, anchor push-out.
- **Wall run head-on latch:** a head-on hit latches (`wall_run_head_on_*`): no sideways motion, a slow slide down at `wall_run_head_on_gravity_scale` of gravity, no footsteps, double jump not refilled. Turning the camera to within `wall_run_head_on_turn_degrees` of the wall's line within `wall_run_head_on_time` starts a normal run that way at the speed the wall was hit with. Otherwise the player lets go, falls at normal gravity and can't latch onto any wall until landing. Jump during the latch is a normal wall jump.
- **Combat:** `Enemy` base (NORMAL / GRABBED / THROWN / STUNNED), `Drone`, enemy hook lock, throw with bullet time, release prediction, damage numbers.
- **Drone group behaviour:** drones no longer bunch up. Each `DroneFlight` claims its goal (group `drone_flights`) and others pick ring spots at least `goal_separation_degrees` away as seen from the player; with no room, the spot farthest from the other goals. Of two crowding drones only the later one moves. Routes keep `PATH_CLEARANCE` outside the standoff sphere (a drone rounding the player used to graze it and stop). A drone only chases and starts a charge within `seek_range` (through walls); beyond it, it hovers and claims nothing. Each beam starts at a random point of its `cooldown`; they are allowed to drift back into step. `CityLevel.random_drones` (set on the City node) adds drones at random open cells (`FlightGrid.random_open_position`), different every run, not near the player. Headless-tested.
- **Melee (body hit):** `player/melee.gd` (`Melee`, child of Player). A hit sphere in front of the player along the look direction (`melee_reach`, `melee_hit_radius` plus the enemy's radius, within `melee_front_degrees`), swept between frames. Lands at `melee_min_speed` or above, or at any speed while armed by a launch at an enemy (RMB tap; armed until landing or `melee_armed_time`). On a hit: synthesized ka-ching (`Synth.make_clang`), the throw's bullet time for `melee_slowmo_time` real seconds, `melee_damage_fraction` of max health, and `Enemy.knock_back` with the player's velocity. The player keeps `melee_momentum_keep` of their speed and gets the double jump back; a swing on that enemy is released. Knockback flight uses the throw physics: a surface hit does impact damage and stuns; after `knockback_max_distance` (EnemyStats) with no hit the enemy regains control at once. Headless-tested.
- **Minimap:** city wireframe, player dot and trail, and now enemies as red dots with drop lines (`MinimapStats` "Enemies" group).
- **Health, death screen, pause menu, tuning panel, effects, dynamic FOV:** in.

## Current goals
1. **Make the core gameplay feel right** (this branch): iron out swing, launch, wall run and combat.
2. **Make it look and sound good.** Textures and sounds are first passes (sounds are synthesized in code).

## Structure
- `tuning/`: `PlayerStats`, `GrappleStats`, `CameraFeel`, `EnemyStats` (base of `DroneStats`), `DroneStats`, `HudStats`, `MinimapStats`, `TrajectoryArcStats`, one `*_default.tres` each. Owners (`Player`, `Drone`) hold them and pass them down via `setup()`. `CitySettings` separate.
- `menus/tuning/`: `TuningPanel`, `TuningFields` (reflects the stats resources; a new `@export` shows up with no panel changes).
- `player/`: `Player` (movement, momentum, wiring), `BodyGravity`, `GrappleHook` (+ `SwingRope`, `GroundProbe`, `LaunchAim`, `EnemyThrow`, `ThrowPreview`, `BulletTime`, `GrappleRope`, `RopeSim`, `GrappleSfx`), `Steering`, `Melee`, `HitStop`, `WallRun`, `AvoidanceAssist`, `TrajectoryPredictor`, `CameraLean`, `SoftSpeedLimit`, `Health`, `Footsteps`, `Synth`, `ShakeCamera`, `WalkBob`, `DynamicFov`, `LandingWatcher`, `HeadLook`, `EdgeDetector`, `EdgeProbe`.
- `enemy/`: `Enemy`, `Drone` (`DroneFlight`, `BeamAttack`, `BeamVisual`, `DroneSfx`), `EnemyEffects`.
- `hud/`: `Hud`, `Crosshair`, `ModeLabel`, `ReelBar`, `SpeedReadout`, `HealthBar`, `DamageFlash`, `DeathScreen`, `DamageNumbers`, `ThrowReadout`, `TrajectoryArc`, `Minimap` (+ `MinimapWire`, `MinimapProjection`, `MinimapTrail`).
- `menus/`: `PauseMenu`, `GameSettings`. `effects/`: `EffectsDirector`, `AttachBurst`, `LandingDust`, `SpeedStreaks`. `levels/city/`: city generation and `FlightGrid`. `world/`: building kit, roads, batching, ground.
- Input: `grapple` (RMB), `swing` (LMB), `reel` (Shift). Layers: 1 World, 2 Player, 3 Enemy, 4 Bullet. The player doesn't collide with enemies physically; `Melee` does its own overlap test.

## Todo / parked
- **Mantle (long term):** waits until building visuals match their hitboxes. The old version is in git history before the commit that removed it; `EdgeProbe.find_ledge` and `EdgeDetector.ledge_ahead` (probing each frame, unused) are there to reuse.
- **Fine for now, revisit later:** soft swing rope constraint (`SwingRope.constrain` snaps), re-firing while a hook is active, steppy rope tip on high refresh (animation pass later), respawn (player and enemies).
- **Not wanted:** tuning overlay without pausing; tuning presets. Camera feel simplification is the user's own job.
- **Reel-in speed limit and soft speed limit ceiling:** left to the user's tuning.

## Known issues
- Melee slow-mo and the throw's bullet time are separate `BulletTime` instances; starting a throw inside the half-second melee slow-mo can make the two fight over `Engine.time_scale` for a moment.
- Swing on an enemy: the trajectory arc and obstacle assist treat the anchor as fixed; the two-body pull is a share-out by mass.
- Swing clearance only checks the terrain under the hit point, not along the arc.
- Death is a frozen screen with Restart only. Killed drones don't respawn.
- A drone that leaves `seek_range` mid-charge still finishes that shot. A drone already inside the standoff distance still holds there whatever its slot.
- Noise textures load async, so the first frame may show plain colour.
- City: roads are one 10 m tile wide; no edge barrier on the ground; building visuals don't match their hitboxes exactly.
- Typed `@export var x: Camera3D` loads as null from a `.tscn`. Verify any node export.
- New `class_name`s need `godot --headless --import` before headless runs can see them.
- GDScript 4.7: `Array[T]()` doesn't parse (declare a typed local first). A `const` can't hold `PackedVector3Array([...])`. Scalars passed to functions are copies, so return results.

## Next up
1. **Core feel (this branch):** whatever the user's playtests of player weight, melee, the head-on latch and hit-stop turn up.
2. **Enemy variants** as extra `.tres` files.
3. **Remaining cheap visuals:** landing camera dip, building colour variety (MultiMesh tint), vignette and grain, hook trail, a melee impact effect.
4. **Ambient audio:** synthesized city hum, wind during momentum flight.
5. **City detail:** sidewalk props, empty-lot fill, far LOD, ground edge barrier; make building visuals match their hitboxes (unblocks mantle).
6. **Menus:** main menu (Play, Quit). Style the pause menu.
7. **Code:** move sound parameters out of `_ready`. Ask before any Asset Library or addon use.

## Project layout
Feature folders: `hud/`, `menus/`, `effects/`, `player/`, `enemy/`, `levels/`, `world/`, `tuning/`. Git repo with no remote; work happens on feature branches off `main` (one topic per branch). `swinging-v2-and-combat-v1` is merged into `main`; the current branch is `core-v2` (ironing out core gameplay feel).
