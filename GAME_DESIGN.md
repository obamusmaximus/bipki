# GAME DESIGN (working outline)

**Optional reading.** Not needed at the start of a session; `CLAUDE.md` and `STATUS.md` are enough for coding work. Open this when discussing game design, level structure or progression. It records where a design discussion got to, so it holds decisions, leanings and open questions. Nothing here is final unless marked **Decided**. No tunable values belong here (name the parameter, the value lives in `tuning/`).

_Last updated: 2026-11-18_

## Vision
A first-person momentum game, a love letter to the Titanfall movement feel, built around a grappling hook (launch, swing, reel, wall run) and a combat model with no gun: enemies are thrown, punched at speed, or used as anchors. An alternate jetpack kit is being tried next to it (see "Loadouts", not settled). Visual target is a stylized look (see "Aesthetic plan"). The current dense city is a placeholder for tuning movement.

## Decided
- **Not an arena shooter.** No hard-locked sequence of arenas, no linear gauntlet.
- **Large, sprawling, vertical levels**, sized so the player's speed is readable against them. The current city is crossable in seconds and is only a tuning sandbox.
- **Open-order objectives.** The player chooses what to tackle and in what order. Combat is the focal point.
- **Levels are authored, not generated.** Objective placement, sightlines and boss arenas need hand placement. A generator may still fill in dressing around authored landmarks.
- **Stylized visuals**, not photoreal.

## Scale
Derive map size from a target end-to-end traversal time at full speed, not the other way round. The speed-limit parameters in `PlayerStats` are therefore also level-design constraints: raising top speed shrinks every map. Tall landmarks visible from far away give the player something to measure their speed against.

## Level structure (proposed)
**Core idea:** skipping is allowed but costly. Every objective changes the state of the map, so the order matters and nothing is locked.

| Objective type | Map-state change | Example |
|---|---|---|
| Threat removal | Removes a pressure from the whole level | Sniper nest down, rooftops safe to cross |
| Route unlock | Opens or shortens a path | Jammer killed, far district's anchors work again |
| Intel | Reveals information | Comms hub shows patrols and the boss |
| Safety net | Changes failure cost | Checkpoint, health station |
| Power | Adds a tool for this level | Loadout option |

**Skeleton of a level:**
- A main objective that is always reachable from the start but brutal without any levers pulled (heavy defence, escalating response).
- About 4-6 levers of different types, each with its own fight and payoff.
- 2-3 **insertion points**, each closest to a different lever and showing a different view of the map (Hitman-style). The insertion point is a soft bias on order, not a lock.
- A briefing that shows the levers in broad strokes. Information is what turns options into choices.

**Keeping the player from feeling omnipotent**, in order of reliance:
1. Enemies that tax movement (sniper emplacements punishing predictable lines, anti-air, things that punish standing still), designed as counters to a strategy.
2. Persistent pressure: an alert or reinforcement clock, so both dawdling and skipping cost something.
3. Dangerous objectives (boss, core) that demand build-up from the levers.

## Design principles to hold to
- **Three options rule:** at a decision point, show at least three viable approaches.
- **Guidance without hand-holding:** landmarks, sightlines and enemy silhouettes suggest an order; no waypoint markers.
- **Cheap failure:** retrying should put the player back in motion quickly, never on a long run-back.
- **Systems, not scripts:** enemy behaviour reacts to the player (alert propagation, regrouping), so the same level plays differently each time.
- **One core verb:** the grapple. New tools are sidegrades that interact with it, not stat boosts (stat changes would shift the feel being tuned). The jetpack experiment ("Loadouts") may change this.

## Loadouts (NOT SETTLED, an experiment)
We may build the game around two or more whole ability sets, or revert to the grapple alone. Mechanics: `docs/mechanics/loadouts.md`, `jet.md`.
- **Grapple kit:** one target at a time, movement is the combat (swing, launch at an enemy, throw).
- **Jetpack kit:** many targets at once (tracking), more firepower, and a fuel tank shared by thrust and weapons. Spending fuel on weapons leaves less for movement, and most enemies punish standing still, so the player plays around cover and wall run as well as flying. Levels must therefore work for a grounded player, a swinging one and a flying one. Hover and surge are the close-combat flow; the afterburner is travel between objectives and scouts nearby enemies; its weapon is the bombardment (`bombardment.md`).
- **Weapon rule:** no plain guns. Every weapon needs a mechanic of its own.
- **In level design:** the kit is one more way to approach a level, next to the insertion point and the order of objectives. Some areas may suit one kit better. How it is chosen (before a level, or at a "Power" lever) is open, as is a third kit.
- **Open:** whether kits are balanced to each other or each kit gets its own levels and enemy mix; whether the experiment survives playtesting.

## Death and respawn: rewind (leaning yes)
**Built (basic):** a fixed `rewind_seconds` window and `lives`, no checkpoints or calm snapshot yet. How it works is in `docs/mechanics/rewind.md`; this section stays the design.

**Idea:** dying sets the player back in time. They restart where they were about a minute earlier, with progress in that window reverted and killed enemies respawned. After 3 deaths it's game over and the level restarts. Checkpoints restore lives.

**Why it fits:** cheap failure, lets the player change approach (information carries over, the world doesn't), suits open order, and matches the game's existing time theme (bullet time). Precedent: Prince of Persia: The Sands of Time (rewind with limited charges), Hitman (limited saves).

**Problems to solve:**
- **Death spiral:** a fixed "one minute ago" may itself be a doomed moment (low health, surrounded). Prefer the latest snapshot that was calm (not in combat, healthy enough) within a maximum window, not a fixed time.
- **Lost progress:** a lever completed 30 s before death being undone feels harsh. Completing a lever should commit a hard anchor that a rewind can't cross. This is also the checkpoint.
- **Health economy:** rewinding restores old health, so the health model (still open) sets how forgiving this is.
- **Exploits:** deliberately dying to undo a mistake or reposition. Bounded by the life limit; may even be acceptable.
- **State capture:** needs a snapshot of the player (position, velocity, rope and hook state, double jump), every enemy (position, state, health, in-flight throws), objective state and alert level. Enemies that free themselves on death must be kept as respawnable records. Retrofitting this is costly; design enemies and objectives to be capturable from now on.
- **Lives vs checkpoints:** options are full refill at a checkpoint (stakes drop away), partial refill (e.g. one life), or game over returning to the previous checkpoint instead of the level start. Open.
- Presentation: a short reverse scrub (trail rewinds, colour drain) hides the restore and sells the fiction; the minimap trail could show where the rewind will land. Tunables would go in a new stats resource.

## Aesthetic plan (summary)
Direction first (palette, accent colour reserved for interactive things, shape language), then rendering foundation (Forward+ vs Compatibility decision early, lighting, a shared stylized shading model, speed visuals), then replace the placeholder building kit with an own modular one, then VFX/animation/ambient life, then district identity and final polish. Assets come last because they are the expensive, hardest-to-redo part. Check every look in motion at speed.

## Open questions
- **Health economy:** what restores health (kills, momentum, pickups, none)? Sets the rhythm of a fight.
- **Lives and checkpoints:** exact model (see rewind above); what a game over costs.
- **Mission vs sandbox:** is a level a one-off mission replayed for mastery, or a persistent world returned to?
- **Hard fail state:** can the player lose a mission outright, or only die and rewind?
- **Progression:** between levels, sidegrade unlocks (leaning) vs any stat growth.
- **Level length:** a 20-40 minute session was suggested, not decided.
- **Threat vocabulary:** a short list of enemy roles (zone denial, pursuit, heavy, boss) before building more variants.
- **Story / framing:** why one person is doing this; affects tone and briefing format. Not urgent.
- **Rewind window:** how far back, and how a calm snapshot is judged.

## Parked
- Mantle (see `STATUS.md`).
- Chunked world loading and far LOD for multi-kilometre levels (needed once levels outgrow the current city).
