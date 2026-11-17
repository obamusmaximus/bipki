# Grapple (launch, swing, reel, rope)

Read this before working on the grapple. Update it at the end of the task (see `docs/mechanics/README.md`). Name tunables, never their values.

**Scripts:** `player/grapple_hook.gd` (`GrappleHook`, owner of the three functions), `swing_rope.gd`, `launch_aim.gd`, `ground_probe.gd`, `grapple_rope.gd`, `rope_sim.gd`, `grapple_sfx.gd`, `hit_stop.gd`, `shake_camera.gd`, `steering.gd` (swing steering), `hud/crosshair.gd`, `hud/reel_bar.gd`, `hud/mode_label.gd`. Tunables: `GrappleStats` (Grapple tab), plus `swing_gravity_scale` and `launch_gravity_*` in `PlayerStats`.
**Related:** a launch at an enemy and the throw are in `combat.md`. Momentum, gravity, steering in flight and the obstacle assist are in `movement.md`.

## Intent
The grapple is the game's one core verb. New tools should be sidegrades that interact with it, not stat boosts (`GAME_DESIGN.md`). A launch should feel like a slingshot and a swing like real pendulum physics. The player keeps their momentum and their control.

## How it works
- **Grapple:** the `GrappleHook` node and its functions: launch on RMB (`grapple`), swing on LMB (`swing`), reel on Shift (`reel`).
- **Fire:** pressing RMB or LMB. The hit point is raycast instantly from the crosshair at that moment, against layers 1 World and 3 Enemy. The grapple (RMB) reaches `launch_range` and the swing `max_distance`. A miss, or a hit on the ground plane, fires nothing and draws nothing.
- **Hit point:** the world position the fire raycast hit. It is fixed at fire time and never re-aimed, unless it locks onto an enemy, in which case it follows the enemy (see `combat.md`).
- **Ground plane:** the plane the player is standing on (a hit height within `ground_tolerance` of the player's feet). The hook can't connect to it.
- **Wall plane:** the plane of a wall the player is wall running on or standing beside (`wall_tolerance`, fed from Player as `GrappleHook.wall_normals`). A launch can't target it (a swing can); the crosshair shows swing-only there.
- **Extend:** the hook tip flies from the player to the hit point at `extend_speed`, the same for all functions. The player isn't affected while it flies.
- **Attach (connect):** the tip reaching the hit point. Launch and swing effects begin only now.
- **Hit-stop:** `HitStop` drops `Engine.time_scale` to `hit_stop_scale` for `hit_stop_time` real seconds on attach. It is skipped while bullet time is on.
- **Shake:** a brief camera shake (`ShakeCamera`) on attach and on detach. A launch triggers both, so it kicks harder. A swing does the same.
- **Launch (RMB):** holding RMB makes no difference on the world (on an enemy it becomes a throw). After attach (and `launch_grace`), the player gets a `launch_speed` velocity added toward the **launch aim point** (the hit point raised by `launch_height_offset`, plus a sideways shift from `LaunchAim`, so the player arcs over the target instead of hitting it). The launch keeps `momentum_carry` of the velocity the player already has, and the hook detaches immediately. A launch fired while standing gets at least `launch_ground_lift` of upward speed, so one aimed slightly down doesn't die on the floor. For the first `launch_gravity_time` the player falls at `launch_gravity_scale` of their gravity. A launch at an enemy is aimed differently: `GrappleHook` emits only `launched_at_enemy` and Player's `StrikeGuidance` sets the velocity (see `combat.md`).
- **Swing (LMB):** on attach the player hangs from the hit point. The rope length is fixed at attach and can only shorten. Releasing LMB detaches. WASD steers along the rope's tangent (`swing_steer_*`). Gravity on the rope is `swing_gravity_scale` of the player's.
- **Reel:** hold Shift to reel in at `reel_speed`. Reeling down to `min_rope_length` detaches. A whirr plays while the rope is actually shortening. While the rope is taut, reeling builds real momentum (`SwingRope._reel_momentum`): the sideways speed scales by the old/new rope length, and the player is pulled toward the hit point at the reel speed. This carries on after the reel stops or the hook detaches. The gain is scaled by `reel_momentum_gain` and stops at `reel_momentum_speed_cap`. The reel-in speed itself is not limited. Apart from reeling, the swing doesn't touch momentum.
- **Swing and the ground:** a swing started while standing can walk and jump at walking pace (not reeling) with the rope only limiting distance, until the player first leaves the floor. After that, landing on the floor detaches the swing (walking and swinging are exclusive; see `movement.md` ground rules). Moving faster than walking pace on the floor before ever leaving it (a graze) still slides. The ground-clearance retraction (`SwingRope._retract_for_descent`) is off while grounded and drops any retraction still owed. An attach from at or below the bottom of the clear arc never retracts.
- **Anchor push-out:** a swing hook that lands on a vertical wall hangs from a point `anchor_push_out` metres out from the wall (`anchor_push_out_enabled`), so the arc bows away from the building. The rope is still drawn to the real hit point.
- **Swing from a moving anchor:** a swing on an enemy keeps the hit point on the enemy. `SwingRope` holds the player relative to the anchor's velocity. The enemy is pulled by the speed the player gives up along the rope, divided by its `mass`.
- **Swing and wall run:** exclusive. A swing never wall runs (it slides along walls), attaching one ends a wall run, and a launch ends one too.
- **Detach:** the hook ending. The player keeps their momentum (see `movement.md`).
- **Rope:** a thin line from the player's **mid-body** (0.9 m above the feet, below the camera so it doesn't block the view) to the hook tip or hit point. Its colour and opacity are `rope_color`. It is visual only (`GrappleRope`, drawn in world coordinates, so its node transform must stay the identity).
- **Rope retract:** after any grapple ends, `RopeSim` springs the loose end back to the hand with the slack whipping about (`rope_retract_*`), then hides it.
- **Crosshair:** the centred dot marks where the fire raycast aims. Its look shows what a fire would do: a ring means it connects, red means the ground plane, faint means nothing. With an enemy lock it shows a ring with four ticks.
- **Reel bar:** the HUD bar of swing rope left, with a mark at `min_rope_length`. Only shown while swinging.

## Settled (don't re-open without a reason from playtesting)
- RMB is launch only. Holding it on the world does nothing.
- The hit point is fixed at fire time.
- Swing steering is the tangent push. It feels like real swinging.
- The swing keeps all of the player's momentum; a launch keeps `momentum_carry` of it.

## Tried and passed on
- **RMB hold pull** (reel toward the hit point on RMB): removed. The swing reel on Shift already covered it.
- **Turn-rate swing steering** (`swing_turn_rate_enabled`): built and tried, then switched off by default. The tangent push feels like real swinging. The code stays behind the toggle.
- **Ground-clearance retraction while grounded:** it made floor jitter reel the player in. It is now off on the ground.
- **Rope node transform:** `GrappleRope` must reset its transform to the identity after turning on `top_level`. Otherwise the whole rope is offset by the player's spawn point. That only looks right when the spawn is the world origin, and in the arena it drew the rope outside the room.

## Known issues and parked
- The default `rope_color` (a translucent grey) is faint against the arena's white walls. Darken it and raise its opacity there (Grapple tab); the default is unchanged so the city keeps its look.
- The swing rope constraint snaps (`SwingRope.constrain`). A soft constraint is parked.
- Re-firing while a hook is active: parked.
- The rope tip is steppy on high-refresh displays: parked for the animation pass.
- Swing clearance only checks the terrain under the hit point, not along the arc.
- Swing on an enemy: the trajectory arc and the obstacle assist treat the anchor as fixed. The two-body pull is a share-out by mass.
- Reel-in speed limit: left to the user's tuning.
