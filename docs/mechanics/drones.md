# Drones (flight, group behaviour, beam attack)

Read this before working on drone or enemy AI. Update it at the end of the task (see `docs/mechanics/README.md`). Name tunables, never their values.

**Scripts:** `enemy/drone.gd` (`Drone`, extends `Enemy`), `drone_flight.gd`, `beam_attack.gd`, `beam_visual.gd`, `drone_sfx.gd`, `attack_coordinator.gd`, `enemy_spawner.gd`, `levels/city/flight_grid.gd`. Tunables: `DroneStats` (extends `EnemyStats`), `AttackCoordinatorStats`, `SpawnerStats`, all in the Drone or Level tab.
**Related:** what happens when a drone is hooked, thrown or punched is in `combat.md`.

## Intent
Enemies should tax movement: they punish standing still and predictable lines, and they surround the player rather than queueing up in front (`GAME_DESIGN.md`, "Keeping the player from feeling omnipotent"). Attacks must be readable: never two shots landing together.

## How it works
- **Flight:** `DroneFlight` picks a goal on a ring around the player, just outside the standoff distance and with a clear line to the player. It flies there along an A* path over `FlightGrid` (the open air, built from building boxes, no physics). `Drone` applies the velocity, collides and faces the target.
- **Seeking range:** a drone only chases the player and starts a beam charge within `seek_range` (plain distance; walls don't block it). Beyond it the drone hovers where it is and claims nothing.
- **Goal separation (ring slots):** each drone's goal is a claimed slot (group `drone_flights`). Other drones pick goals at least `goal_separation_degrees` away as seen from the player. With no room left, a drone picks the spot farthest from the other goals. Of two crowding drones only the later one moves. Routes keep `PATH_CLEARANCE` outside the standoff sphere.
- **Beam attack:** `BeamAttack` runs a timed cycle: cooldown, then a wait for a clear line within `seek_range`, then a charge, a latched aim with a grace period, and the beam. `BeamVisual` and `DroneSfx` draw and sound it.
- **Attack coordinator:** `AttackCoordinator` (one per level, handed to each drone through `Drone.setup`) hands out attack tokens. An enemy asks before starting a charge (`BeamAttack` asks last, after range and line of sight) and gives the token back when its attack ends. The coordinator refuses while `max_attackers` are attacking, or while less than `min_gap` has passed since the last attack started. On top of that, each drone waits `opening_delay` plus a random share of its `cooldown` before its first charge, so nothing fires as a level loads or a drone spawns.
- **Returning to open air:** `FlightGrid` cells are coarse and keep a margin from buildings, so a punched or thrown drone can come to rest outside open air. `Drone._ai_step` then flies it to the nearest open cell (slowing on arrival) instead of the flight's own velocity. Nothing teleports on recovery.
- **Random drones:** `CityLevel.random_drones` extra drones are placed at random open cells (`FlightGrid.random_open_position`) on load, different every run, not near the player. This is level content set on the City node, not a tunable.
- **Enemy spawner:** see `levels_and_hud.md`.

## Tried and passed on
- **Independent random first shots:** drones fired together because each first shot came from an independent random point in the cooldown (some within 0.3 s of load), and the fixed cooldown then kept them in step. Replaced by the coordinator plus `opening_delay`. Verified headless over ten runs: the first charge never came before 3.4 s, and shots were always at least `min_gap` apart.
- **Unclaimed goals:** drones bunched up and flew side by side. Replaced by ring slots.
- **Snapping to the cell centre on recovery:** `Drone._on_recovered` moved the drone to `FlightGrid.nearest_open_position`, a jump of a few metres whenever it came to rest off the cell centre. Replaced by flying back into open air. Headless: a drone 2 m outside open air returned with steps of at most 0.06 m a frame.
- **Routes hugging the standoff sphere:** a drone rounding the player grazed the sphere and stopped. Fixed with `PATH_CLEARANCE`.

## Known issues
- A drone that leaves `seek_range` mid-charge still finishes that shot.
- A drone already inside the standoff distance holds there whatever its slot.
- A drone knocked deep into a building's margin takes a moment to fly out, and its beam can still fire meanwhile (only its movement was changed).
- Next: a short list of enemy roles (zone denial, pursuit, heavy, boss) before building more variants (`GAME_DESIGN.md`, open questions).
