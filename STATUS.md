# STATUS

Read this at the start of every session. Update it at the end of every session.

_Last updated: 2026-11-11 (96 towers, launch grace + sideways aim, swing ground-clearance retraction)_

## Current state
Playable first-person test level (`level_one.tscn`): flat grass plane, 96 tower boxes (Tower1-4 are 14 m tall; Tower5-14 were randomly placed, 9-56 m tall; Tower15-24 were added next, 13-34 m tall; Tower25-48 were packed tighter, 9-40 m tall, at least 11 m from any other tower centre, which guarantees no footprint overlap; Tower49-96 were added the same way, 9-40 m tall, spread over the whole ±190 m ground), the player, a crosshair, walk bob, and a grappling hook with three functions: pull and launch (RMB) and swing (LMB). Grass and towers have procedural noise textures. The hook has synthesized sound effects (including a thwip and a looping pull hum), and the player has footsteps. All are untuned and not yet checked by eye or ear.

## Current goals
- **Polish the grapple until it feels fun, snappy and responsive.** This is the main focus. Tune the feel by playtesting, not by reasoning alone. The swing is new and needs the most attention.
- **Basic textures and sound.** First pass is in: noise textures, and all sounds are synthesized in code. Next is making them read well and adding more sounds.

## What exists
- `player/player.gd` (`Player`): ground movement and jump. Three momentum rules: a pull or launch keeps `momentum_carry` (0.4) of the velocity it starts with; `_keeps_momentum` preserves velocity after a detach until landing; and swing never touches velocity. While pulling, the velocity is the hook's pull velocity plus the carried part, and gravity is off. While swinging, the player gets gravity and no input, and the hook's rope constraint is applied after `move_and_slide`.
- `player/head_look.gd` (`HeadLook`): mouse look. Captures the mouse, ESC releases it.
- `player/grapple_hook.gd` (`GrappleHook`): a state machine (IDLE, EXTENDING, ATTACHED) and a mode (UNDECIDED, PULL, LAUNCH, SWING). RMB fires a pull or launch, LMB fires a swing. Owns the swing rope: `apply_swing_constraint()` keeps the body inside `_rope_length`, removes outward velocity, and reels in while jump is held. See the glossary in CLAUDE.md for the terms.
- `player/grapple_rope.gd` (`GrappleRope`): the rope visual, a thin cylinder stretched between two points. Grey, 50% alpha, unshaded.
- `player/grapple_sfx.gd` (`GrappleSfx`): child `Sfx` of `GrappleHook`. One `AudioStreamPlayer` per sound: fire, attach, launch, detach, thwip, and a looping pull hum (`start_pull()` / `stop_pull()`). `volume_db` is -6.
- `player/footsteps.gd` (`Footsteps`): child `Footsteps` of `Player`. Plays a step at `steps_per_second` (about every 0.257 s) while walking on the ground, with a random pitch of 0.85-1.15. `Player._set_walking()` drives it along with the walk bob.
- `player/synth.gd` (`Synth`): `make_sound()` builds a 16-bit mono `AudioStreamWAV` in code: a tone sweep mixed with noise, with attack and decay. `make_loop()` builds a seamless looping hum. No audio files in the project.
- `player/shake_camera.gd` (`ShakeCamera`): script on the player's `Camera3D`. `shake(amount)` adds trauma (0-1), which decays. It jitters frustum offset and roll only, so raycast aim is never affected. `Player` triggers it from the hook's `attached` and `detached` signals.
- `player/walk_bob.gd` (`WalkBob`): child of the Camera3D. Offsets the camera's local position with a subtle bob and sway while walking on the ground. `Player` calls `set_walking()`. Off during pull, momentum and mid-air.
- `player/crosshair.gd` (`Crosshair`): centered dot drawn in a `CanvasLayer` HUD inside `player.tscn`.
- Input: `project.godot` has the `swing` action (LMB, button 1), next to `grapple` (RMB).
- Textures: `level_one.tscn` has `NoiseTexture2D` materials. Grass is green noise, tiled 60x. Towers are brown noise with triplanar world UVs, so the texture doesn't stretch across the boxes.

## Grapple behavior (as built)
- On fire (RMB or LMB), the hit point is raycast instantly from the camera against layer 1 (World), with no distance limit. A miss, or a hit within 0.1 m of the player's feet height (ground plane), does nothing and draws nothing (and plays no sound). The other button is ignored while a hook is active.
- The hook tip then extends from mid-body (0.9 m up): at 90 m/s for RMB, at 100 m/s for LMB swing. Nothing pulls the player during flight.
- RMB mode is decided by how long it's held. Released before 0.2 s is a launch. Held past 0.2 s is a pull.
- Pull: steady 25 m/s toward the point, plus the 40% of momentum carried in. It ends on RMB release or when within 4 m, and the player keeps momentum.
- Launch: on connect, a `launch_grace` (0.3 s) window starts; the player moves normally. When it ends, velocity becomes 40% of the old velocity plus a 50 m/s boost toward the launch aim point, and the hook detaches. The aim point is 6 m above the hit point plus a sideways shift: how far left or right of the hit point the crosshair points (measured at the hit point's distance, perpendicular to the player-to-hit direction), clamped to ±`launch_side_offset` (6 m). It is read at launch time, so it is proportional, not just left/right.
- Swing: on connect, the rope length is fixed at the current distance to the hit point. The player keeps all their momentum and has no air control, so they steer by pivoting. Ground clearance: at attach, `clearGround` = hit height above `ground_height` (0) minus `swing_ground_margin` (2 m), min `min_rope_length`. As the player descends below the hit point's height, the rope retracts by `(L0 - clearGround) / clearGround` m per metre descended (never below clearGround, never lengthens). The rate is sized so the rope reaches clearGround where a rope of that length is `clear_ground_radius` (3 m) horizontally off the point below the hit point, i.e. at the edge of a 3 m-radius clearance area (depth sqrt(clearGround² - 9), min 1 m), not only directly underneath. The rope can shorten (hold jump to reel in at 8 m/s, down to 2 m) but never lengthen. Releasing LMB detaches and keeps momentum. Released mid-flight, it retracts without shake.
- Sounds: RMB fire plays a twang, attach a thump, launch a whoosh, and a pull detach a tick. Swing fire and swing release both play the thwip. A pull plays the looping hum from attach until it ends.
- Camera shake fires on attach and on detach, for all three functions. A launch does both at once, so it kicks harder than a pull or swing. `Player.grapple_shake` is 0.8.

## Tuning values
`GrappleHook`: `extend_speed` 90, `swing_extend_speed` 100, `pull_speed` 25, `launch_speed` 50, `launch_height_offset` 6, `launch_side_offset` 6, `launch_grace` 0.3, `ground_height` 0, `swing_ground_margin` 2, `clear_ground_radius` 3, `detach_distance` 4, `hold_threshold` 0.2, `ground_tolerance` 0.1, `reel_speed` 8, `min_rope_length` 2, `max_distance` 10000.
`Player`: `grapple_shake` 0.8, `momentum_carry` 0.4.
Other: `Footsteps.steps_per_second` 3.89 (1.75x the old 0.45 s interval; read it, or `get_step_interval()`, to sync a walking animation), `Footsteps.volume_db` -10, `GrappleSfx.volume_db` -6. Sound values are in `GrappleSfx._ready` and `Footsteps._ready`.

## Verified
Headless runs confirmed: the level and player scenes load with no errors, and the level has 96 towers. (The launch grace, sideways shift and swing retraction were added afterwards; they load cleanly but are untested by hand.) The `swing` action exists. Swing rope test: a body 12 m from its hit point with a 8 m rope is pulled back to 8 m, and its outward velocity is removed. Tangential and inward velocity survive. Launch test: velocity (10, 0, 0) plus a launch of (0, 0, 50) gives (4, 0, 50). Earlier checks still hold: sky shot does nothing, ground shot is rejected while standing, attach and detach signals fire (launch fires both), shake trauma is applied, pull starts only after the hook connects, and release ends the pull with momentum kept. The synthesized audio is non-silent, and `make_loop` gives a seamless 1 s loop. Not yet playtested by hand. The swing feel, the 40% carry, the shake strength, the 6 m launch arc, the sound levels, and the textures' look are all untuned guesses.

## Known issues / gotchas
- Typed `@export var x: Camera3D` came through null from the `.tscn`, so `GrappleHook` uses `@onready var _camera = $"../Head/Camera3D"` instead. Don't reintroduce a node export without verifying it loads.
- New `class_name`s need `godot --headless --import` (or opening the editor) before headless runs can see them.
- A pull has no manual escape other than releasing RMB. If a wall blocks the path the player slides along it and stays hooked while RMB is held.
- Swing ignores walls: the rope correction moves the body after `move_and_slide`, so a swing can clip through a tower corner. Swing also has no ground check, so a player who lands mid-swing stays on the rope.
- The rope tip advances in `_physics_process` (about 1.3 m per tick for RMB), so it may look steppy on high-refresh monitors.
- The launch momentum state clears as soon as the player is on the floor with `velocity.y <= 0`. A launch aimed slightly downward from the ground will lose its horizontal speed almost immediately.
- Collision layers are not named in `project.godot` yet. The player is still on the default layer 1 and the hook excludes it by RID.
- Re-launching, or re-firing while a hook is active, is ignored.
- Noise textures are generated asynchronously, so the first frame or two may show plain material colour.

## Ideas / next up
1. Playtest the grapple and swing by hand, and tune: speeds, the 40% carry, the reel rate, `hold_threshold`, launch arc, shake. This decides most of the "fun" goal.
2. Swing collisions: make the rope correction respect walls (e.g. a sweep or a `move_and_collide` on the position fix).
3. Rope feel: move the tip's advance into `_process` (or interpolate) so it stops looking steppy, and add a slight rope sag or wobble.
4. Hand-tune the sounds by ear, and add a low-volume wind during momentum flight.
5. Hit feedback at the hit point: a small particle puff or flash on attach.
6. Jump-to-release for a pull.
7. Air control during the momentum state.
8. Name the collision layers in `project.godot`, and move the player to layer 2.
9. Later: real texture and sound files, if the synthesized ones don't hold up. Any Asset Library or addon use needs a check with the user first (see CLAUDE.md).
