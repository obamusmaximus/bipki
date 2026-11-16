# Mechanic docs

One doc per load-bearing mechanic. Each holds what a fresh session needs to pick the mechanic up without the old conversation: the design intent, how the pieces connect, what is settled, what was tried and passed on, and the open problems.

| Doc | Covers |
|---|---|
| `grapple.md` | Fire, extend, attach, launch, swing, reel, rope, hit-stop, crosshair |
| `combat.md` | Enemy base, enemy lock, launch at an enemy (strike), melee, knockback, throw, bullet time, damage |
| `drones.md` | Drone flight, ring slots, seeking range, beam attack, attack coordinator |
| `movement.md` | Player gravity, momentum, air steering, soft speed limit, wall run, obstacle assist, trajectory, camera feel |
| `levels_and_hud.md` | Arena, city, spawner, HUD, minimap, menus, tuning panel |

## Keeping this doc
- **When a session starts work on a mechanic,** read its doc after `STATUS.md`, then the scripts it lists.
- **When the task ends** (the change lands, or the user closes the session), update the doc before closing:
  - Fix "How it works" so it matches the code.
  - Add one line to "Tried and passed on" for each approach that was built or seriously tried and then dropped: what it was, and why it was dropped. This is the part git can't recover, so it is the most important part.
  - Move anything decided from playtesting into "Settled".
  - Update "Known issues".
- **Keep it short.** It is reread by every session working on the mechanic. Don't write a diary of every iteration; git has the diffs. Don't copy tunable values (name the parameter). Drop entries that are no longer true.
- A new load-bearing mechanic gets its own doc and a row in the table above.
