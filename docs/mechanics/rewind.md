# Rewind (death, lives, state capture)

Read this before working on death, lives, or anything that must survive a rewind (a new enemy type, an objective, a moving part). Update it at the end of the task (see `docs/mechanics/README.md`). Name tunables, never their values.

**Scripts:** `rewind/rewind.gd` (`Rewind`: snapshots, restore, remaking freed nodes), `rewind/rewind_snapshot.gd`, `player/lives.gd`, `hud/lives_readout.gd`, `hud/rewind_flash.gd`, `hud/death_screen.gd`. The capture and restore methods live on each taking part: `Player`, `WallRun`, `Enemy` (`Drone`, `BeamAttack`), `EnemySpawner`. Tunables: `RewindStats` (Level tab), `PlayerStats.lives` ("Health").
**Related:** the design behind it (calm snapshots, checkpoints, lost progress) is in `GAME_DESIGN.md` under "Death and respawn".

## Intent
Cheap failure that keeps the player in motion. A death sets the player, the enemies and the level back `rewind_seconds`; what the player learned carries over, the world doesn't. Each death spends a life (`lives` is the number of rewinds); a death with none left is game over (the frozen death screen with Restart).

## How it works
- **Flow:** `Health.died` → `Player._on_died` spends a life (`Lives`, a `RefCounted` the player owns). If there was one to spend, the player emits `rewind_requested`; the level connects it to `Rewind.rewind()`. With none to spend, or with nothing connected (a scene without a `Rewind`), the player calls `Hud.show_death_screen()`, which pauses the tree. Lives are never rewound.
- **Snapshots:** `Rewind` (one per level, a node in each level scene beside `AttackCoordinator`) runs last in the physics order and, every `snapshot_interval` of game time, asks every node in group `rewindable` for `rewind_capture()`. It keeps only the snapshots a rewind could still need: everything newer than `rewind_seconds`, plus the one just older. Memory is therefore bounded, and the cost is one pass over the rewindable nodes per snapshot.
- **Restore:** `rewind()` defers to the end of the frame, so nodes are never freed or made inside another node's physics step. It takes the oldest snapshot it holds (the newest one at least `rewind_seconds` old, or the level start early on) and drops the newer ones. Its own clock goes back to that snapshot's time, so the timeline rewinds with the world. Then:
  1. A node in group `rewind_recreate` that wasn't in the snapshot (spawned since) is removed: out of the tree at once, then freed. It doesn't die, so there's no death effect or `died` signal.
  2. A node in the snapshot that is gone (killed since) is instanced again from its scene, under its old parent. The properties of its `rewind_recipe()` are set first (an enemy keeps its stats `.tres`, so a variant stays itself). `Rewind.recreated` lets the level wire it like a fresh spawn (`drone.setup(...)`).
  3. Every node in the snapshot gets `rewind_restore(state, rewind)`. All nodes exist by then, so a state can name another node by its rewind id and resolve it with `rewind.find(id)` (the spawner does this for its enemy).
- **Rewind ids:** each rewindable node gets an int id (node meta `rewind_id`) the first time it is captured; a remade node gets its old id back. States hold plain values only, never node references.
- **Taking part (a new enemy type, an objective, a moving platform):** join `Rewind.GROUP` and implement `rewind_capture() -> Dictionary` and `rewind_restore(state, rewind)`. Join `Rewind.RECREATE_GROUP` too if it can be freed or spawned at runtime. Restore must not emit "this happened" signals (a death, a launch); a rewind is not an event in the world. An `Enemy` subclass only adds `_capture_ai` / `_restore_ai`. State kept in an `await` or a `SceneTreeTimer` can't be captured, so time things with a field counted down in `_physics_process` (as `EnemySpawner` does).
- **Player:** position, yaw (the body transform), pitch, velocity, the momentum, double-jump and jump-cut flags, launch gravity left, the bunnyhop window, health and the whole wall run. The hook is not restored: the player comes back with it put away (`GrappleHook.abort()`, no signals or retract), because the button that held a swing or a throw is rarely still held after a death. A throw in progress ends and its bullet time eases out (`EnemyThrow.abort()`). Melee and the landing watcher forget their last frame, so the jump in position isn't read as a hit or a landing.
- **Enemies:** transform, velocity, state, flight and stun timers, knockback, health, and the drone's beam cycle (the attack coordinator's token is claimed or released to match). One held by a throw in the snapshot comes back stunned, as if let go, since the throw isn't restored. The drone's flight replans from where it is.
- **Spawner:** its enemy (by rewind id) and the respawn countdown (real seconds, a field rather than a timer).
- **HUD:** pips for the lives left above the health bar (`LivesReadout`), and a short "REWIND" flash (`RewindFlash`, real time) when a rewind lands.
- **Cost** (headless, the arena with added drones): a snapshot of 600 drones takes about 3 ms, restoring them in place about 2 ms, and remaking a killed drone about 0.2 ms. Drone sounds are built once and shared (`DroneSfx` statics), which also made every spawn cheaper.

## Settled (don't re-open without a reason from playtesting)
- **Game time, not real time.** The window and the snapshot clock run on game time, so bullet time stretches them like the world they record.
- **Fixed window.** A death goes back `rewind_seconds`, even if that moment was a bad one (low health, surrounded). The calm-snapshot idea in `GAME_DESIGN.md` is not built.

## Tried and passed on
- **The level recording each enemy's spawn data itself:** passed over for one protocol on the nodes, so any new kind of moving part takes part by joining a group, and the rewind doesn't need to know what it is restoring.

## Known issues and parked
- Effects in flight (particles, a fired beam's flash, sounds) aren't rewound; they play out.
- Removing many nodes at once grows faster than linear (about 36 ms for 600 spawned since the snapshot), likely Godot's group bookkeeping. Only matters if hundreds of enemies appear within one window.
- Next: checkpoints that refill lives and anchor the rewind (`GAME_DESIGN.md`), objective and alert state taking part once they exist, a reverse-scrub presentation instead of the flash.
