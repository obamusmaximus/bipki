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
- **All tunable numbers live in stats resources in `tuning/`**, never as `@export`s on gameplay scripts: `PlayerStats` (body, gravity, air and swing steering, wall run, obstacle assist, trajectory prediction, edges, health, footsteps, melee), `GrappleStats` (launch, hit-stop, enemy hook, throw, rope retract, swing, rope look), `CameraFeel`, `EnemyStats` (health, thrown flight and impact damage, knockback, stun; the base of `DroneStats`), `DroneStats`, `AttackCoordinatorStats`, `SpawnerStats`, `ArenaStats`, `HudStats`, `MinimapStats` and `TrajectoryArcStats`, each with a `.tres` (`player_default.tres`, etc.). Add a new tunable as an `@export` in the right stats class, inside an `@export_group` (the group becomes a sub-label in the debug panel) and with a `##` doc comment (it becomes the tooltip). Owners hold the resource (`Player.stats`, `grapple_stats`, `feel`; `Drone.stats`) and hand it to their parts through `setup()`; parts read `stats.x`. A new enemy type extends `Enemy` and gets its own stats class (extending `EnemyStats`) and .tres, and a variant of an existing one is just another .tres. A new stats class needs listing in `TuningPanel.TABS` to show up in the debug panel. **The user tunes these live and saves the .tres files between sessions, so the .tres are the source of truth and values change between prompts. That is normal: don't be surprised by a changed value, don't "fix" or reset it, and don't revert it while editing nearby. Never write tunable values into CLAUDE.md, STATUS.md or the mechanic docs (name the parameter instead). Treat any number in the docs as possibly stale and read the .tres.** Parts that cache a value (sound volume, rope tip) listen to the resource's `changed` signal so live edits apply. `CitySettings` stays its own resource.
- **Use named input actions** (`move_forward`, `move_back`, `move_left`, `move_right`, `jump`, `grapple`, `swing`, `reel`) from the Input Map, never raw keys.
- **Movement and raycasts go in `_physics_process`**, not `_process`.
- **Collision layers:** 1 World, 2 Player, 3 Enemy, 4 Bullet. Use these when setting `collision_layer` and `collision_mask`. The names are set in `project.godot`; the player is on layer 2 and masks layer 1.
- Use `@onready var x: Type = $Path` for node references. Don't call `get_node` repeatedly.
- Follow the official GDScript style guide: `snake_case` for files, functions, and variables; `PascalCase` for classes and nodes.

## Session workflow
- **Read `STATUS.md` at the start of every session**, before doing anything else.
- **Working on a mechanic? Read its doc in `docs/mechanics/`** (the glossary below says which) before touching its scripts. Each doc holds the design intent, how it works, what's settled, what was tried and passed on, and open problems.
- **At the end of a task, update the mechanic's doc** (the rules are in `docs/mechanics/README.md`, above all one line per approach tried and dropped, with why). **Then update `STATUS.md`**, which stays a short index of current state, cross-cutting issues and next up. Mechanic detail goes in the mechanic doc, not in STATUS.
- Several sessions may work in this checkout at once, one per mechanic. Touch only your mechanic's doc, and re-read `STATUS.md` right before editing it.
- `GAME_DESIGN.md` is optional reading for design discussions.

## Glossary
Game-specific terms. Use them consistently in code, comments, and conversation. Each term is defined in full in the mechanic doc in brackets (all in `docs/mechanics/`).

**Grapple** [`grapple.md`]
- **Grapple:** the grappling hook as a whole: `GrappleHook` with launch (RMB, `grapple`), swing (LMB, `swing`) and reel (Shift, `reel`).
- **Fire:** pressing RMB or LMB. It raycasts the hit point instantly from the crosshair. A miss or a ground-plane hit fires nothing.
- **Hit point:** where the fire raycast hit. Fixed at fire time, never re-aimed (it follows a locked enemy).
- **Ground plane:** the plane the player stands on. The hook can't connect to it.
- **Extend:** the hook tip flying to the hit point. **Attach (connect):** the tip arriving; effects start now. **Detach:** the hook ending.
- **Launch:** the RMB function: a velocity toward the **launch aim point** (the hit point raised by `launch_height_offset`) on attach, then an immediate detach.
- **Swing:** the LMB function: hanging from the hit point on a rope that can only shorten. **Reel:** shortening it with Shift, which builds momentum.
- **Rope:** the visual line from the player's **mid-body** (0.9 m above the feet) to the tip. **Rope retract:** the rope springing back after a grapple ends.
- **Anchor push-out**, **swing from a moving anchor**, **reel momentum limit:** swing details.
- **Hit-stop:** a split-second time freeze on attach. **Shake:** the camera shake on attach and detach.
- **Crosshair / reticle:** the centred dot; its look shows what a fire would do. **Reel bar:** swing rope left.

**Combat** [`combat.md`]
- **Enemy:** the base class for everything hookable (states NORMAL, GRABBED, THROWN, STUNNED). `Drone` is the first.
- **Enemy lock (snap):** a fire locking onto an enemy near the crosshair.
- **Launch at an enemy (strike):** an RMB tap on an enemy, guided into it by `StrikeGuidance`, arming the melee hit.
- **Melee (body hit):** flying into an enemy fast (or after a strike) punches it. **Knockback:** the flight that sends the enemy on.
- **Throw:** RMB held on an enemy. **Bullet time:** the world slowing down. **Pull point / throw direction**, **draw and flick (throw power)**, **camera weight:** how a throw is aimed and powered.
- **Impact damage:** damage from a thrown enemy hitting a surface. **Release prediction:** the throw's orange preview line. **Damage numbers:** floating HUD numbers.

**Drones** [`drones.md`]
- **Seeking range:** the distance within which a drone chases and attacks.
- **Goal separation (ring slots):** drones spreading out around the player.
- **Attack coordinator:** attack tokens that space out every enemy's attacks.
- **Random drones:** extra city drones at random open points.

**Movement** [`movement.md`]
- **Player gravity:** `BodyGravity`, the player's own heavier gravity. **Momentum:** the velocity kept after a detach until landing.
- **Air steering:** WASD turning the velocity in the air. **Soft speed limit:** a cubic drag above `soft_speed_limit`.
- **Wall run:** latching onto a wall on a fast graze. **Head-on latch:** a head-on hit that slides, and turns into a run if the camera turns.
- **Obstacle assist:** steering clear of a predicted wall hit. **Trajectory prediction:** stepping the player's path forward. **Trajectory arc:** the HUD line drawn along it.
- **Camera lean**, **dynamic FOV**, **walk bob:** camera feel.

**Levels, HUD and menus** [`levels_and_hud.md`]
- **Arena:** the main scene, a 100 m hand-built testing box. **City:** the procedural tuning sandbox. **Enemy spawner:** keeps one enemy alive at a point.
- **HUD scale**, **speedometer**, **minimap**, **effects:** HUD and visuals.
- **Pause menu**, **tuning panel:** menus.

## Dependencies
- **Ask before adding any addon or plugin** (Asset Library, `addons/` folder, GDExtension). Prefer built-in engine features.

## Notes
- **Two levels share principles.** `levels/arena/` (the main scene, a hand-built testing box) and `levels/city/`. A change to how levels in general work (wiring, what they hand the player or enemies, conventions) goes into both. Level-specific geometry doesn't.
- Don't edit files in `.godot/`. It's generated cache.
