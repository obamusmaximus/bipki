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
- **All tunable numbers live in stats resources in `tuning/`**, never as `@export`s on gameplay scripts: `PlayerStats` (body, mantle, edges, health, footsteps), `GrappleStats`, `CameraFeel` and `DroneStats`, each with a `.tres` (`player_default.tres`, etc.). Add a new tunable as an `@export` in the right stats class, inside an `@export_group` (the group becomes a sub-label in the debug panel) and with a `##` doc comment (it becomes the tooltip). Owners hold the resource (`Player.stats`, `grapple_stats`, `feel`; `Drone.stats`) and hand it to their parts through `setup()`; parts read `stats.x`. A new enemy type gets its own stats class and .tres, and a variant of an existing one is just another .tres. A new stats class needs listing in `TuningPanel.TABS` to show up in the debug panel. **The user tunes these live and saves the .tres files between sessions, so the .tres are the source of truth and values change between prompts. That is normal: don't be surprised by a changed value, don't "fix" or reset it, and don't revert it while editing nearby. Never write tunable values into CLAUDE.md or STATUS.md (name the parameter instead). Treat any number in the docs as possibly stale and read the .tres.** Parts that cache a value (sound volume, rope tip) listen to the resource's `changed` signal so live edits apply. `CitySettings` stays its own resource.
- **Use named input actions** (`move_forward`, `move_back`, `move_left`, `move_right`, `jump`, `grapple`, `swing`, `reel`) from the Input Map, never raw keys.
- **Movement and raycasts go in `_physics_process`**, not `_process`.
- **Collision layers:** 1 World, 2 Player, 3 Enemy, 4 Bullet. Use these when setting `collision_layer` and `collision_mask`. The names are set in `project.godot`; the player is on layer 2 and masks layer 1.
- Use `@onready var x: Type = $Path` for node references. Don't call `get_node` repeatedly.
- Follow the official GDScript style guide: `snake_case` for files, functions, and variables; `PascalCase` for classes and nodes.

## Session workflow
- **Read `STATUS.md` at the start of every session**, before doing anything else.
- **Update `STATUS.md` at the end of every session** (current state, what exists, known issues, next up) so the next session can pick up where we left off.

## Glossary
Game-specific terms. Use them consistently in code, comments, and conversation.
- **Grapple:** the grappling hook as a whole: the `GrappleHook` node and its three functions below (launch on RMB, swing on LMB).
- **Fire:** pressing RMB (grapple) or LMB (swing). The hit point is raycast instantly from the crosshair at this moment (layer 1 World, no distance limit). A miss, or a hit on the ground plane, fires nothing and draws nothing.
- **Hit point:** the world position the fire raycast hit. It is fixed at fire time and never re-aimed.
- **Ground plane:** the plane the player is standing on (hit height within `ground_tolerance` of the player's feet). The hook can't connect to it.
- **Rope:** the thin, semi-transparent grey line from the player's mid-body to the hook tip (or hit point). Visual only (`GrappleRope`).
- **Extend:** the hook tip flying from the player to the hit point at `extend_speed` (the same for all functions). The player isn't affected during this.
- **Attach (connect):** the tip reaching the hit point. Launch and swing effects begin only now.
- **Launch:** the RMB function. Holding RMB makes no difference. After attach (and `launch_grace`), the player gets a `launch_speed` velocity added toward the **launch aim point**, on top of the momentum they carry (`momentum_carry`), and the hook detaches immediately.
- **Swing:** the third function, on LMB (`swing` action). The hook extends at `extend_speed`. On attach the player hangs from the hit point on a rope. The rope length is fixed at attach and can only shorten: hold **Reel** (`reel` action, Shift) to reel in at `reel_speed`. Reeling down to `min_rope_length` detaches the hook. A reel-in whirr plays while the rope is actually shortening. While the rope is taut, reeling builds real momentum (`SwingRope._reel_momentum`): the sideways speed scales by old/new rope length and the player is pulled toward the hit point at the reel speed, and this carries on after the reel stops or the hook detaches. Apart from reeling, momentum isn't touched; WASD steers along the rope's tangent. Releasing LMB detaches.
- **Launch aim point:** the hit point raised by `launch_height_offset`, so the player arcs over the target instead of colliding with it.
- **Detach:** the hook ending. After a launch, the player keeps momentum.
- **Momentum:** the player's velocity preserved after a detach. Input doesn't override horizontal velocity, and gravity applies, until the player lands (`Player._keeps_momentum`). A launch keeps `momentum_carry` of the player's velocity when it starts. A swing keeps all of it.
- **Mid-body:** the rope's origin, 0.9 m above the player's feet (below the camera so it doesn't block vision).
- **Shake:** the brief camera shake (`ShakeCamera`) on attach and on detach. A launch triggers both, so it kicks harder. Swing does the same.
- **Walk bob:** the subtle camera bob while walking on the ground (`WalkBob`). Separate from shake.
- **Crosshair / reticle:** the centered HUD dot marking where the fire raycast aims. Its look shows what a fire would do (ring = connects, red = ground plane, faint = nothing).
- **Reel bar:** the HUD bar of swing rope left, with a mark at `min_rope_length`. Only shown while swinging.
- **Effects:** the attach burst (at the hit point), landing dust (at the feet on a hard landing), and speed streaks (past the camera at speed). Built in `effects/`.
- **HUD scale:** `HudStats.hud_scale`, scales the HUD (crosshair, mode label and reel bar as one group, health bar and speed readout as another, so they stay stacked) and the menus (pause menu, tuning panel, death screen). HUD elements follow it live; menus apply it when the mouse is released, so a dragged slider doesn't resize under the pointer. New HUD elements go inside one of the two bottom containers in `hud.tscn`, never loose.
- **Dynamic FOV:** the view widens with speed, with a short kick on launch.
- **Pause menu:** ESC menu with Resume, Options, Tuning (debug builds only) and Quit. It owns mouse capture.
- **Tuning panel:** the debug panel behind the pause menu's Tuning button (`TuningPanel`, built by reflecting the stats resources in `tuning/`). Tabs Player, Camera (camera feel and HUD), Grapple and Drone, a sub-label per `@export_group`. Edits apply live; Save writes the tab's .tres, Reset reloads it.

## Dependencies
- **Ask before adding any addon or plugin** (Asset Library, `addons/` folder, GDExtension). Prefer built-in engine features.

## Notes
- Don't edit files in `.godot/`. It's generated cache.
