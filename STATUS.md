# STATUS

Loaded into every session through `CLAUDE.md`, so keep it short: this is an index. Mechanic detail goes in `docs/mechanics/`, not here.

**Playtesting:** the user playtests thoroughly after every feature. If they don't mention a feature, it works as intended. Don't label things "not playtested".

_Last updated: 2026-11-17_

## Current state
| Mechanic | Doc (`docs/mechanics/`) | Where it stands |
|---|---|---|
| Grapple (launch, swing, reel, rope) | `grapple.md` | Launch, swing with reel momentum, rope retract, hit-stop, ground-launch lift, swing works on the ground, tunable `rope_color`. |
| Combat | `combat.md` | Enemy lock, guided launch at an enemy (`StrikeGuidance`), melee with knockback, bullet-time throw with release prediction, damage numbers. |
| Drones | `drones.md` | Ring slots, seeking range, attack coordinator, opening delay, random city drones, recovery flies back into open air. |
| Movement | `movement.md` | Player gravity, air turn-rate steering, soft speed limit, wall run and head-on latch, obstacle assist, trajectory arc, camera feel. |
| Levels, HUD, menus | `levels_and_hud.md` | Arena is the main scene; city still loadable. Speedometer dial (horizontal speed), minimap with enemies, tuning panel with a Level tab. |

## Current goals
1. **Make the core gameplay feel right** (this branch): iron out swing, launch, wall run and combat.
2. **Make it look and sound good.** Textures and sounds are first passes (sounds are synthesized in code).

## Cross-cutting known issues and gotchas
- Death is a frozen screen with Restart only. Player respawn is open (see the rewind idea in `GAME_DESIGN.md`).
- Typed `@export var x: Camera3D` loads as null from a `.tscn`. Verify any node export.
- GDScript 4.7: `Array[T]()` doesn't parse (declare a typed local first). A `const` can't hold `PackedVector3Array([...])`. Scalars passed to functions are copies, so return results.

## Next up
1. **Core feel (this branch):** whatever the user's playtests turn up. Per-mechanic next steps are in each doc.
2. **Enemy variants** as extra `.tres` files.
3. **Cheap visuals:** landing camera dip, building colour variety (MultiMesh tint), vignette and grain, hook trail, a melee impact effect.
4. **Ambient audio:** synthesized city hum, wind during momentum flight.
5. **City detail:** sidewalk props, empty-lot fill, far LOD, ground edge barrier; make building visuals match their hitboxes (unblocks mantle).
6. **Menus:** main menu (Play, Quit). Style the pause menu.
7. **Code:** move sound parameters out of `_ready`.

## Layout and branches
- Feature folders: `player/`, `enemy/`, `hud/`, `menus/`, `effects/`, `levels/arena/`, `levels/city/`, `world/`, `tuning/`, `debug/` (dev-only tools: `debug/tuning/` builds the tuning panel from the stats resources; the playtest log, `docs/playtest_log.md`). Each mechanic doc lists its scripts. Headless test notes: `docs/testing.md`.
- Remote: GitHub `origin` (`obamusmaximus/bipki`). Work happens on feature branches off `main` (one topic per branch); finished branches are merged and deleted. Everything up to `core-v3` is in `main`. The current branch is `core-v4` (core gameplay feel, continued).
