# STATUS

Read at the start of every session. Update at the end. Keep it short: this is an index. Each load-bearing mechanic has its own doc in `docs/mechanics/` (design intent, how it works, settled decisions, what was tried and passed on, known issues), and mechanic detail goes there, not here. All tunables live in the stats resources in `tuning/` (see CLAUDE.md) and the user changes them between prompts, so don't copy values here and don't be surprised by changed ones.

**Playtesting:** the user playtests thoroughly after every feature. If they don't mention a feature, it works as intended. Don't label things "not playtested".

_Last updated: 2026-11-16 (rope drawn at the right place in the arena and its colour tunable, speedometer shows horizontal speed, arena look and scale bar settled, drones no longer fire together; before that: mechanic detail moved out of STATUS into `docs/mechanics/`, guided launch at an enemy, enemy spawner)_

## Current state
| Mechanic | Doc | Where it stands |
|---|---|---|
| Grapple (launch, swing, reel, rope) | `grapple.md` | Launch, swing with reel momentum, rope retract, hit-stop, ground-launch lift, swing works on the ground. The rope's node transform is fixed (it was offset by the spawn point), and `rope_color` is tunable. |
| Combat | `combat.md` | Enemy lock, guided launch at an enemy (`StrikeGuidance`, uncommitted), melee with knockback, bullet-time throw with release prediction, damage numbers. |
| Drones | `drones.md` | Ring slots, seeking range, attack coordinator, opening delay, random city drones. A drone that regains control flies back into open air instead of snapping. A knocked-back enemy can be hooked, thrown or struck again (`combat.md`). |
| Movement | `movement.md` | Player gravity, air turn-rate steering, soft speed limit, wall run and head-on latch, obstacle assist, trajectory arc, camera feel. |
| Levels, HUD, menus | `levels_and_hud.md` | Arena is the main scene; city still loadable. Speedometer dial (horizontal speed), minimap with enemies, tuning panel with a Level tab. |

## Current goals
1. **Make the core gameplay feel right** (this branch): iron out swing, launch, wall run and combat.
2. **Make it look and sound good.** Textures and sounds are first passes (sounds are synthesized in code).

## Structure
- `tuning/`: the stats resources, one `*_default.tres` each. Owners (`Player`, `Drone`) hold them and pass them down via `setup()`. `CitySettings` separate. `menus/tuning/`: `TuningPanel`, `TuningFields` (reflect the resources; a new `@export` shows up with no panel changes).
- `player/`, `enemy/`, `hud/`, `menus/`, `effects/`, `levels/arena/`, `levels/city/`, `world/`. Each mechanic doc lists its scripts.
- Input: `grapple` (RMB), `swing` (LMB), `reel` (Shift). Layers: 1 World, 2 Player, 3 Enemy, 4 Bullet.

## Cross-cutting known issues and gotchas
- Death is a frozen screen with Restart only. Player respawn is open (see the rewind idea in `GAME_DESIGN.md`).
- Typed `@export var x: Camera3D` loads as null from a `.tscn`. Verify any node export.
- New `class_name`s need `godot --headless --import` before headless runs can see them.
- Headless or `--script` test harnesses: the player's death freezes the whole tree, so set a huge `Health` (`health.setup(1.0e9)`) in a test that gets shot. HitStop and BulletTime reset `Engine.time_scale` to 1, so re-set a sped-up scale every frame. `EnemyEffects.death` uses `get_tree().current_scene`, which is null when a script adds the level to `root`; the resulting "add_child on null" error is harmless. Run one level load per process when comparing several loads.
- GDScript 4.7: `Array[T]()` doesn't parse (declare a typed local first). A `const` can't hold `PackedVector3Array([...])`. Scalars passed to functions are copies, so return results.

## Next up
1. **Core feel (this branch):** whatever the user's playtests turn up. Per-mechanic next steps are in each doc.
2. **Enemy variants** as extra `.tres` files.
3. **Cheap visuals:** landing camera dip, building colour variety (MultiMesh tint), vignette and grain, hook trail, a melee impact effect.
4. **Ambient audio:** synthesized city hum, wind during momentum flight.
5. **City detail:** sidewalk props, empty-lot fill, far LOD, ground edge barrier; make building visuals match their hitboxes (unblocks mantle).
6. **Menus:** main menu (Play, Quit). Style the pause menu.
7. **Code:** move sound parameters out of `_ready`. Ask before any Asset Library or addon use.

## Project layout
Feature folders: `hud/`, `menus/`, `effects/`, `player/`, `enemy/`, `levels/`, `world/`, `tuning/`; mechanic docs in `docs/mechanics/`. Remote: GitHub `origin` (`obamusmaximus/bipki`). Work happens on feature branches off `main` (one topic per branch); finished branches are merged and deleted. Everything up to `core-v2` is in `main`. The current branch is `core-v3` (ironing out core gameplay feel, continued).
