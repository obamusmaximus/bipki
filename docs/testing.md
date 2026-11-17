# Headless testing

Read before writing a headless or `--script` test harness. Add a line here when a harness trips on something new.

- New `class_name`s need `godot --headless --import` before headless runs can see them.
- A player death rewinds the level while lives last. The rewind plays out over a few real seconds (`RewindSequence`, pausing the tree in the middle), so wait on `process_frame` until `Rewind._sequence.is_running()` is false before checking the result, and the last one freezes the whole tree. Set a huge `Health` (`health.setup(1.0e9)`) in a test that gets shot.
- `HitStop` and `BulletTime` reset `Engine.time_scale` to 1, so re-set a sped-up scale every frame.
- `EnemyEffects.death` uses `get_tree().current_scene`, which is null when a script adds the level to `root`. The resulting "add_child on null" error is harmless.
- Run one level load per process when comparing several loads.
- For a deterministic run (comparing a trace before and after a refactor), pass `--fixed-fps 60` and switch off the real-time slow-mo in memory (`GrappleStats.hit_stop_enabled`, `PlayerStats.melee_slowmo_time`); without it the physics step count follows wall time. Don't use it for anything timed in real seconds (bullet time, the rewind sequence): those barely advance at that pace.
