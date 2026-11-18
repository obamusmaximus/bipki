# Bombardment (jetpack's afterburner weapon) - DESIGNED, NOT BUILT

Read this before building the bombardment or any weapon of the jetpack loadout. Update it when the build lands (see `docs/mechanics/README.md`): rewrite it as "how it works" and add a Scripts line. Name tunables, never their values. Names below marked (planned) are proposals for `BombardmentStats`.

**Related:** the loadout, its tracking and its afterburner are in `jet.md`; how a weapon plugs in is in `loadouts.md`; `Enemy.take_hit` (not yet written) and the rewind in `combat.md` and `rewind.md`.

## Intent
The jetpack kit is about handling many targets at once. Hover and surge are its micro combat flow; the afterburner is its travel between objectives, and it scouts (tracks) every enemy near. Bombardment is the afterburner's weapon: an initiation tool when the player flies into a fight, or a way to whittle down a clump of enemies between sorties out of cover. It is the only weapon usable while the afterburner burns, and usable only then (the other abilities are locked out in the afterburner, `JetLoadout.abilities_locked()`).

## The ability
- **Trigger:** a fire input (key not chosen yet), only while the afterburner burns, and only when off cooldown (`cooldown`, planned). With no enemy tracked it does nothing and costs nothing.
- **Launch:** one homing missile per enemy tracked at that moment, each assigned to its enemy (its owner). They fly straight up a set distance (`ascent_height`, planned), then descend fast and home in.
- **Terminal phase:** halfway into the descent (`terminal_share`, planned, of the descent) each missile commits. Before it, a missile follows its owner loosely.
- **Ownerless missiles:** if a missile's owner has died or its track has expired, the missile is ownerless. At the terminal phase it acquires an enemy that is tracked now and has no missile on it. If there is none, it attacks an enemy another missile already holds. If nothing is tracked, it has no target.
- **Why this shape:** the missile count is set by what is tracked at launch, so one tracked heavy enemy gets one missile, never the whole salvo. Piling on can happen only when the player has killed or lost the other targets, which is their own work. The designed tech: lock extra weak enemies and kill them yourself before the missiles go terminal, so the missiles take the rest.
- **Cooldown:** shown as an ability indicator with an outline for time left, like the grapple's. Never text (`levels_and_hud.md`).

## Parts it needs
- `Enemy.take_hit(damage, point, push)`: the first damage path that isn't an impact. Missiles call it; later weapons reuse it.
- A missile scene on the Bullet layer (4), masking World and Enemy.
- A shared homing step (`jet/homing.gd`, planned) for the steering.
- Rewind (`rewind.md`): in-flight missiles are state, so they are recreated on a restore and removed if they were fired after the snapshot, like enemies. The cooldown is saved with the loadout. No timers or `await`s: a missile keeps its phase and its times as numbers.
- A loadout rule change: weapons check `abilities_locked()`; bombardment checks `is_afterburning()` instead.

## Build order (when the user starts it)
The user wants to direct the weapon build closely: propose each step, settle its open questions with them, and build only that step.
1. `Enemy.take_hit(damage, point, push)` (touches `combat.md`), with a headless test.
2. Settle fire input, cover and the salvo cap (open questions below).
3. Missile scene and `jet/homing.gd`: ascent to `ascent_height`, descent, terminal phase at `terminal_share`, a hit calls `take_hit`.
4. Launcher in `JetLoadout`: one missile per tracked enemy at launch, owners assigned, `cooldown`, the afterburner-only rule.
5. Ownerless retargeting: a new track first, else an already-owned target.
6. Rewind for in-flight missiles and the cooldown.
7. HUD indicator (outline for the cooldown, no text), then sound and a hit effect.

## Open questions
- **Fire input:** the afterburner holds Shift and W, so the key must suit that hand position. Left mouse is the obvious one, shared with the grapple's `swing` (the two loadouts never run together).
- **Missile count over `max_tracks`:** scouting isn't limited by `max_tracks`, so more than that can be tracked at launch. Cap the salvo or not?
- **Cover:** a missile rises straight up, so a roof overhead blocks it, and a descent can hit a building. Options: the ascent and descent collide with World (cover protects enemies, and the player must open sight lines); or the missile ignores World until its terminal phase. Leaning toward collision, since cover is meant to matter, but a launch under a roof then needs a rule (refuse, or end the ascent at the roof).
- **Spread of the fallback:** when several missiles are ownerless and no free target exists, send them evenly across the held targets or all to the nearest?
- **Timing:** ascent and descent times against `track_time` and `scout_track_time`: a track should not usually expire in flight unless the player lets it. Tune in play.
- **Damage and splash:** per-missile damage and an area effect (a clump is the stated target) are open. Missiles never hurt the player.
- **Fuel:** the other weapons will draw on the fuel tank (`jet.md`); whether bombardment also costs fuel is open (its limit today is the cooldown and the afterburner).
- **Indicator:** how it reads while off cooldown but not in the afterburner (dimmed, outline empty).
- **No target at the terminal phase:** the missile fizzles or detonates harmlessly where it is.
