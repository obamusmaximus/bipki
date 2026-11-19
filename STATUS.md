# STATUS

Loaded into every session through `CLAUDE.md`, so keep it short: this is an index. Mechanic detail goes in `docs/mechanics/`, not here.

**Playtesting:** the user playtests thoroughly after every feature. If they don't mention a feature, it works as intended. Don't label things "not playtested".

_Last updated: 2026-11-19_

## Current state
| Mechanic | Doc (`docs/mechanics/`) | Where it stands |
|---|---|---|
| Grapple (launch, swing, reel, rope) | `grapple.md` | Launch, swing with reel momentum, rope retract, hit-stop, ground-launch lift, swing works on the ground, separate swing gravity before and after the low point of the arc, tunable `rope_color`. |
| Combat | `combat.md` | Enemy lock, guided launch at an enemy (`StrikeGuidance`), melee with knockback, bullet-time throw with release prediction, damage numbers. |
| Drones | `drones.md` | Ring slots, seeking range, attack coordinator, opening delay, random city drones, recovery flies back into open air. |
| Movement | `movement.md` | Player gravity, air turn-rate steering, air drag, soft speed limit, wall run (accelerates, compressor above the max) and head-on latch (jump launches straight back), bunnyhop (grace window after landing keeps speed on a jump), obstacle assist, trajectory arc, camera feel. |
| Rewind (death, lives) | `rewind.md` | Each death spends a life (`lives` = rewinds) and sets the player (back at full health), enemies and spawners back `rewind_seconds` (killed enemies remade, newer ones removed); a death with none left is game over. Played, not cut: time slows to a stop, the level plays back to the saved moment (easing in and out) under a screen effect, then time eases back up. Lives pips on the HUD. |
| Loadouts (ability sets) | `loadouts.md` | Player is the shared body; the grapple's parts are `GrappleLoadout` (picked by `Player.loadout_scene`), its HUD a `GrappleHud` module mounted into the Hud's slots. Grapple behaviour unchanged by the split. |
| Jetpack loadout | `jet.md` | The default loadout for now. Hover (tap Shift), surge (hold Shift with a movement key), afterburner after a forward surge (carries into hover), fuel gauge, H and S indicators, thrust sound. Tracking: scanner pyramid with a dwell pickup, afterburner scouting, blinking track markers with segmented health bars. Main weapon: the seeker shotgun (LMB, no cooldown), pellets dealt out to the tracks newest first, homing after a short delay, fading tracers. |
| Bombardment (jet weapon) | `bombardment.md` | Designed, not built: an afterburner-only salvo of homing missiles, one per tracked enemy, rising then diving, with ownerless retargeting at the terminal phase. |
| Island level (night, water) | `island.md` | Skeleton built (`levels/island/island.tscn`, run on its own): island box with the arena's grid lit (shared `grid.gdshaderinc`), a flat walkable sea, spawners, a flight grid reaching out over the water. Night lighting (`NightStats`): low moon with soft shadows, custom sky (gradient, moon disc, stars), sky ambient, horizon fog, warm lamps. Water v1 (`WaterStats`, Water tab): faceted summed sine waves calming away from the island, deep-to-shallow light in steps measured from flat water plus a stepped crest tint (the swell reads from above), glitter path toward every light (moon here, a sun or street lights elsewhere; lamps glitter in their own colour). Shore: foam band with a ragged churning edge, broken foam lines travelling in toward the cliffs, waves damped near the cliffs. Main scene. Next: the "later, not now" water passes in `island.md`, when wanted. |
| Levels, HUD, menus | `levels_and_hud.md` | Island is the main scene; arena and city still loadable. HUD in anchor groups (corners, edge midpoints, centre) with the edge groups bent by a helmet-visor shader; ability indicators (flash on use, lit while on, outline for time left or a charge; no ability text at the bottom); speedometer dial; minimap in a rounded box sized and visually centred on its wireframe; tuning panel with Level and Water tabs. |

## Current goals
1. **Make the core gameplay feel right:** iron out swing, launch, wall run and combat.
2. **Experiment (this branch):** the jetpack loadout (`jet.md`) and an open night island level to test it (`island.md`).
3. **Make it look and sound good.** Textures and sounds are first passes (sounds are synthesized in code).

## Cross-cutting known issues and gotchas
- **Anything with state that changes in play takes part in the rewind** (`rewind.md`): a new enemy type, objective or moving part implements capture and restore. Don't keep state in `await`s or timers.
- Typed `@export var x: Camera3D` loads as null from a `.tscn`. Verify any node export.
- GDScript 4.7: `Array[T]()` doesn't parse (declare a typed local first). A `const` can't hold `PackedVector3Array([...])`. Scalars passed to functions are copies, so return results.

## Next up
1. **This branch:** the island level (build order done through the shore; breaking waves, crest foam and refraction are "later, not now" in `island.md`), and the jetpack weapons: playtest the seeker shotgun, bombardment (build order in `bombardment.md`; the user directs weapon work step by step), micro weapons (undecided), a loadout picker.
2. **Core feel:** whatever the user's playtests turn up. Per-mechanic next steps are in each doc.
3. **Enemy variants** as extra `.tres` files.
4. **Cheap visuals:** landing camera dip, building colour variety (MultiMesh tint), vignette and grain, hook trail, a melee impact effect.
5. **Ambient audio:** synthesized city hum, wind during momentum flight.
6. **City detail:** sidewalk props, empty-lot fill, far LOD, ground edge barrier; make building visuals match their hitboxes (unblocks mantle).
7. **Menus:** main menu (Play, Quit). Style the pause menu.
8. **Code:** move sound parameters out of `_ready`.

## Layout and branches
- Feature folders: `player/`, `jet/` (the jetpack loadout and its HUD module), `enemy/`, `hud/`, `menus/`, `effects/`, `levels/arena/`, `levels/city/`, `levels/island/`, `world/`, `rewind/`, `tuning/`, `debug/` (dev-only tools: `debug/tuning/` builds the tuning panel from the stats resources; the playtest log, `docs/playtest_log.md`). Each mechanic doc lists its scripts. Headless test notes: `docs/testing.md`.
- Remote: GitHub `origin` (`obamusmaximus/bipki`). Work happens on feature branches off `main` (one topic per branch); finished branches are merged and deleted. Everything up to `loadout` is in `main`. The current branch is `jetpack-v2-and-island`.
