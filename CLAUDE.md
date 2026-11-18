# CLAUDE.md

## Project
- **Engine:** Godot 4 (project is on 4.7, GL Compatibility renderer). Use Godot 4 APIs only. Don't use Godot 3 patterns such as `KinematicBody`, `yield`, or `export var`.
- **Language:** GDScript only.
- **Genre:** First-person 3D game.

## Code conventions
- **Use typed GDScript everywhere.** Give types to variables, parameters, return values, and `@export`s (e.g. `var speed: float = 5.0`, `func jump() -> void:`). Use `:=` when the type is obvious.
- **Keep scripts small and focused.** Each script should have one responsibility. Split growing logic into child nodes or components. Don't build large "god" scripts.
- Use `class_name` for reusable scripts.
- Prefer signals over hard references between unrelated nodes.
- **Signals up, direct calls down:** a node reports events upward with signals, and calls its own children directly.
- **One scene per object**, and **group files by feature** (e.g. `player/` holds the player's scene and scripts).
- **All tunable numbers live in stats resources in `tuning/`** (one class per owner, each with a `*_default.tres`), never as `@export`s on gameplay scripts. Add a tunable as an `@export` in the right class, inside an `@export_group` (it becomes a sub-label in the debug panel) and with a `##` doc comment (it becomes the tooltip). Owners hold the resource and hand it to their parts through `setup()`; parts read `stats.x`. Parts that cache a value listen to the resource's `changed` signal so live edits apply. A new stats class needs listing in `TuningPanel.TABS`. A new enemy type extends `Enemy` with its own stats class extending `EnemyStats`; a variant is just another `.tres`. `CitySettings` stays its own resource.
- **The `.tres` files are the source of truth.** The user tunes live and saves them between sessions, so values change between prompts. That is normal: don't be surprised by a changed value, don't "fix", reset or revert it. Never write tunable values into the docs (name the parameter), and treat any number in a doc as possibly stale.
- **Use named input actions** (`move_forward`, `move_back`, `move_left`, `move_right`, `jump`, `grapple`, `swing`, `reel`, `jet`) from the Input Map, never raw keys.
- **Movement and raycasts go in `_physics_process`**, not `_process`.
- **Collision layers:** 1 World, 2 Player, 3 Enemy, 4 Bullet. Use these when setting `collision_layer` and `collision_mask`. The names are set in `project.godot`; the player is on layer 2 and masks layer 1.
- Use `@onready var x: Type = $Path` for node references. Don't call `get_node` repeatedly.
- Follow the official GDScript style guide: `snake_case` for files, functions, and variables; `PascalCase` for classes and nodes.

## Session workflow
- **`STATUS.md` is imported at the end of this file**, so it is already loaded at the start of every session.
- **Working on a mechanic? Read its doc in `docs/mechanics/`** (the glossary below says which) before touching its scripts, and read only the scripts it lists unless the task needs more.
- **Writing a headless test?** Read `docs/testing.md` first.
- **At the end of a task, update the mechanic's doc, then `STATUS.md`.** Follow the documenting principles in `docs/mechanics/README.md`.
- Several sessions may work in this checkout at once, one per mechanic. Touch only your mechanic's doc, and re-read `STATUS.md` right before editing it.
- `GAME_DESIGN.md` is optional reading for design discussions.
- **Playtest logs** (`playtest_logs/`, saved in game with L): read them only when the user asks, and read `docs/playtest_log.md` first.

## Glossary
Game-specific terms. Use them consistently in code, comments and conversation. Each is defined in the mechanic doc in brackets (all in `docs/mechanics/`).

- **[`grapple.md`]** grapple, fire, hit point, ground plane, extend, attach (connect), detach, launch, launch aim point, swing, reel, rope, mid-body, rope retract, anchor push-out, swing from a moving anchor, hit-stop, shake, crosshair (reticle), reel bar
- **[`combat.md`]** enemy, enemy lock (snap), launch at an enemy (strike), melee (body hit), knockback, throw, bullet time, pull point, draw and flick (throw power), camera weight, impact damage, release prediction, damage numbers
- **[`drones.md`]** seeking range, goal separation (ring slots), attack coordinator, random drones
- **[`movement.md`]** player gravity, momentum, air steering, soft speed limit, wall run, head-on latch, obstacle assist, trajectory prediction, trajectory arc, camera lean, dynamic FOV, walk bob
- **[`rewind.md`]** rewind, snapshot, rewindable (rewind id), recreate, lives, game over
- **[`loadouts.md`]** loadout, loadout API, hand (socket), HUD module, slot
- **[`jet.md`]** jetpack, jet key, hover, surge, afterburner (A/B), fuel, afterburner carry, tracking (track), scanner, scanner frame, scouting, track marker
- **[`bombardment.md`]** bombardment, salvo, owner, ownerless missile, terminal phase (designed, not built)
- **[`island.md`]** island, moon glitter, shore factor (planned, not built)
- **[`levels_and_hud.md`]** arena, city, enemy spawner, HUD scale, speedometer, minimap, effects, pause menu, tuning panel

- **Dev-only tools live in `debug/`** (one subfolder per tool) and their scripts start their doc comment with "Debug:". Gameplay must never depend on them; they hook in through groups and signals.

## Dependencies
- **Ask before adding any addon or plugin** (Asset Library, `addons/` folder, GDExtension). Prefer built-in engine features.

## Notes
- **Two levels share principles.** `levels/arena/` (the main scene, a hand-built testing box) and `levels/city/`. A change to how levels in general work (wiring, what they hand the player or enemies, conventions) goes into both. Level-specific geometry doesn't.
- Don't edit files in `.godot/`. It's generated cache.

@STATUS.md
