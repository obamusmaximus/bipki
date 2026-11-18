# Playtest log (debug tool)

Read this before reading a playtest log or changing what it records. **Read logs only when the user asks.**

**Scripts:** `debug/playtest_log/playtest_log.gd` (autoload `PlaytestLog`: buffer, L key, saving), `velocity_ledger.gd` (`VelocityLedger`), `playtest_log_writer.gd` (`PlaytestLogWriter`), `saved_toast.gd`. The player's side: `Player.playtest_snapshot()`, `Player.playtest_event`, `_forces` marks in `Player._physics_process`. Tunables: `PlaytestLogStats` (tuning panel, Debug tab).

## How it works
- `PlaytestLog` keeps the last `buffer_seconds` (real time, so bullet time doesn't stretch it) of physics frames. `save_playtest_log` (L) writes them to `playtest_logs/<date>_<time>.jsonl` plus a screenshot `.png` of that moment. The folder is gitignored and has a `.gdignore` so the editor doesn't import it. Exported builds write to `user://playtest_logs/`. L works while paused and on the death screen.
- **Probes:** any node in the group `playtest_probe` with `playtest_snapshot() -> Dictionary` is sampled every physics frame, after all other nodes (`process_physics_priority`). Its data goes under the node's name in snake_case (`player`). A probe's `playtest_event(event, data)` signal adds event lines. The recorder knows nothing about gameplay; to log another system, make it a probe.
- **Forces:** `VelocityLedger` splits each frame's velocity change by cause. `Player` calls `begin()` at the start of the frame and `mark(part)` after each step (its loadout marks through `Player.mark_force`) that changes velocity (`gravity`, `jump`, `steering`, `assist`, `strike`, `soft_limit`, `wall_slide`, `walk`, `collision`, `rope`, `wall_run`). Anything that changed velocity between frames (launch impulses, melee, knockback) is `events`. The parts sum exactly to the frame's velocity change (checked headless). New velocity code in `Player` or a loadout needs a `mark` after it, or its change is filed under the next mark.

## Reading a log
- Line 1 is a header (`frames`, `physics_hz`, `saved_at`). Then lines in time order: `type: "frame"` (`f`, `t` real seconds, `game_t`, `dt`, `time_scale`, one object per probe) and `type: "event"` (`event`, `f` = the last frame before it, plus its data). Vectors are `[x, y, z]`, y is up.
- `forces` values are velocity changes in m/s for that frame, not accelerations: divide by `dt` for m/s². A part missing from a frame changed nothing.
- `time_scale` below 1 is bullet time or hit-stop, so `dt` shrinks with it.
- Start from the end of the file (the moment L was pressed) and from the user's description, then look for jumps in `speed` and which force caused them.
