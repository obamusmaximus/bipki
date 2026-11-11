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
- **Use named input actions** (`move_forward`, `move_back`, `move_left`, `move_right`, `jump`, `grapple`, `swing`) from the Input Map, never raw keys.
- **Movement and raycasts go in `_physics_process`**, not `_process`.
- **Collision layers:** 1 World, 2 Player, 3 Enemy, 4 Bullet. Use these when setting `collision_layer` and `collision_mask`. The names aren't yet in `project.godot`.
- Use `@onready var x: Type = $Path` for node references. Don't call `get_node` repeatedly.
- Follow the official GDScript style guide: `snake_case` for files, functions, and variables; `PascalCase` for classes and nodes.

## Session workflow
- **Read `STATUS.md` at the start of every session**, before doing anything else.
- **Update `STATUS.md` at the end of every session** (current state, what exists, known issues, next up) so the next session can pick up where we left off.

## Glossary
Game-specific terms. Use them consistently in code, comments, and conversation.
- **Grapple:** the grappling hook as a whole: the `GrappleHook` node and its three functions below (pull and launch on RMB, swing on LMB).
- **Fire:** pressing RMB (grapple) or LMB (swing). The hit point is raycast instantly from the crosshair at this moment (layer 1 World, no distance limit). A miss, or a hit on the ground plane, fires nothing and draws nothing.
- **Hit point:** the world position the fire raycast hit. It is fixed at fire time and never re-aimed.
- **Ground plane:** the plane the player is standing on (hit height within `ground_tolerance` of the player's feet). The hook can't connect to it.
- **Rope:** the thin, semi-transparent grey line from the player's mid-body to the hook tip (or hit point). Visual only (`GrappleRope`).
- **Extend:** the hook tip flying from the player to the hit point at `extend_speed` (90 m/s). The player isn't affected during this.
- **Attach (connect):** the tip reaching the hit point. Pull and launch effects begin only now.
- **Pull:** the hold mechanic. Hold RMB past `hold_threshold`. After attach, the player is pulled at a steady `pull_speed` (25 m/s) until RMB is released or the player is within `detach_distance` (4 m).
- **Launch:** the click mechanic. Release RMB before `hold_threshold`. On attach, the player gets a `launch_speed` (50 m/s) velocity added toward the **launch aim point**, on top of the momentum they carry (`momentum_carry`, 40%), and the hook detaches immediately.
- **Swing:** the third function, on LMB (`swing` action). The hook extends at `swing_extend_speed` (100 m/s). On attach the player hangs from the hit point on a rope. The rope length is fixed at attach and can only shorten (hold jump to reel in, down to `min_rope_length`). Momentum isn't touched and there's no air control, so the player steers by pivoting. Releasing LMB detaches.
- **Launch aim point:** the hit point raised by `launch_height_offset` (6 m), so the player arcs over the target instead of colliding with it.
- **Detach:** the hook ending. After a pull detaches, or after a launch, the player keeps momentum.
- **Momentum:** the player's velocity preserved after a detach. Input doesn't override horizontal velocity, and gravity applies, until the player lands (`Player._keeps_momentum`). A pull or launch keeps `momentum_carry` (40%) of the player's velocity when it starts. A swing keeps all of it.
- **Mid-body:** the rope's origin, 0.9 m above the player's feet (below the camera so it doesn't block vision).
- **Shake:** the brief camera shake (`ShakeCamera`) on attach and on detach. A launch triggers both, so it kicks harder. Swing does the same.
- **Walk bob:** the subtle camera bob while walking on the ground (`WalkBob`). Separate from shake.
- **Crosshair:** the centered dot HUD (`Crosshair`) marking where the fire raycast aims.

## Dependencies
- **Ask before adding any addon or plugin** (Asset Library, `addons/` folder, GDExtension). Prefer built-in engine features.

## Notes
- Don't edit files in `.godot/`. It's generated cache.
