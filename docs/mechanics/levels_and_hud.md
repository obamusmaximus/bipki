# Levels, HUD and menus

Read this before working on levels, the HUD or the menus. Update it at the end of the task (see `docs/mechanics/README.md`). Name tunables, never their values.

**Scripts:** `levels/arena/` (`ArenaLevel`, `ArenaLook`, `ArenaScale`, `grid.gdshader`), `levels/city/` (`CityLevel`, `CityGenerator`, `CityLayout`, `CityPlan`, `BuildingBuilder`, `FlightGrid`), `world/`, `enemy/enemy_spawner.gd`, `hud/`, `menus/`, `effects/`. Tunables: `ArenaStats` and `SpawnerStats` (Level tab), `HudStats`, `MinimapStats`, `TrajectoryArcStats` (HUD tab), `CitySettings` (its own resource).

## Levels
- **Two levels share principles.** `levels/arena/` is the main scene, a hand-built testing box. `levels/city/` is a seeded procedural city about 400 m across on a 1000 m grass ground, fogged at the edge, built at runtime by `CityGenerator`, with a golden-hour look. A change to how levels in general work (wiring, what they hand the player or enemies, conventions) goes into both. Level-specific geometry doesn't. Both levels have an `AttackCoordinator`.
- **Arena:** `levels/arena/arena.tscn`, a 100 m white box (fine two-octave procedural noise, unlit, no glow) with black grid bars on all six surfaces (`grid.gdshader`: bold every `major_spacing`, thin every `minor_spacing`), and a 5 m orange pillar from floor to ceiling for swinging. The world origin is a bottom corner of the box, so the room runs from 0 to 100 m on every axis. The two central bars of each surface (at 50 m) are scale bars: a notch every metre, bigger every thin-bar step and biggest every bold-bar step, with a number label at every metre in the same three sizes (`ArenaScale`, instanced font-outline digits). Within `clear_band` of a central bar the crossing grid bars are left out. It's hand-built; nothing is generated. The room mesh (`Room/Grid`) must sit at exactly (50, 50, 50): the shader and the labels both work in world space from the 0 and 100 m planes, and a drag offset there hides the labels on the floor and the two walls at 0 m. `ArenaLevel` wires it (flight grid for drones, minimap boxes read from the collision shapes), and `ArenaLook` applies `ArenaStats` live. Near the crossing of the two bars a few labels would collide, so the notches within `notch_clear` of the centre are left out, the vertical bar's labels just above the crossing are left out, and its centre label moves to the free quarter below and right (`ArenaScale._build`). Ambient light and a directional light light only the actors and the pillar. There are two `EnemySpawner`s with drones. `corner_shade` (a fake ambient-occlusion darkening toward the edges) exists but is 0 by default.
- **Enemy spawner:** `EnemySpawner` (a `Marker3D`) keeps one enemy of its `enemy_scene` alive at its position and makes the next one `SpawnerStats.respawn_delay` real seconds after it dies (a countdown field, so a rewind restores it). It reports each one with `spawned`, and the level hands drones the flight grid and the player. It's reusable in any level. The game itself doesn't respawn enemies in normal levels, so this is for testing and later authored spawns.
- **Direction:** levels will be authored, not generated (`GAME_DESIGN.md`). The city is a tuning sandbox.

## HUD
- **HUD scale:** `HudStats.hud_scale` scales the HUD (the crosshair and speedometer around the screen centre; the mode label and reel bar as one group and the health bar as another, so they stay stacked; and the minimap) and the menus (pause menu, tuning panel, death screen). HUD elements follow it live. Menus apply it when the mouse is released, so a dragged slider doesn't resize under the pointer. New HUD elements go inside one of the two bottom containers in `hud.tscn`, never loose.
- **Speedometer:** `SpeedReadout`, the dial right of the crosshair (`HudStats` group "Speedometer"). It's a 180 degree gauge (from 6 o'clock up the left side to 12) that fills toward `soft_speed_limit`, with the horizontal speed (X and Z only) in m/s in the middle. The last stretch is a red zone, and the fill and number go white-blue, orange, then red as the speed enters it. It's full screen and centred like the crosshair, so it scales around the same point.
- **Minimap:** the top-right panel (`Minimap`). It's a 3D isometric wireframe of the building boxes (handed over by the level through `Player.show_city`), with the player as a glowing dot with a drop line to the ground, enemies as red dots with drop lines, and a glowing trail of the last few seconds that fades out (`MinimapTrail`). The projection is in `MinimapProjection`. It sits on an opaque grey box (`background_color`); `minimap_opacity` fades only the map, not the box.
- **Effects:** the attach burst (at the hit point), landing dust (at the feet on a hard landing) and speed streaks (past the camera at speed), built in `effects/` and wired by `EffectsDirector`.
- The crosshair, reel bar, throw readout and damage numbers are described with their mechanics (`grapple.md`, `combat.md`).

## Menus
- **Pause menu:** the ESC menu with Resume, Options, Tuning (debug builds only) and Quit. It owns mouse capture.
- **Tuning panel:** the debug panel behind the pause menu's Tuning button (`TuningPanel`, built by reflecting the stats resources in `tuning/`). Tabs are Player, Camera (camera feel and HUD scale), Grapple, Drone, HUD (minimap and trajectory arc) and Level, with a sub-label per `@export_group`. Edits apply live; Save writes the tab's `.tres` and Reset reloads it. A new stats class needs listing in `TuningPanel.TABS`.
- **Death screen:** a frozen screen with Restart only, shown when the last life is gone (`rewind.md`).

## Tried and passed on
- **Speed label:** a text label bottom left, replaced by the speedometer dial.
- **270 degree dial:** the first speedometer was a 270 degree gauge, replaced by the 180 degree one (6 o'clock up the left side to 12).
- **3D speed on the dial:** it first showed the length of the whole velocity, so climbing and falling counted. It now shows the horizontal speed only.
- **Black neon arena:** a black box with cyan neon grid lines and a glowing magenta pillar, with a strong glow. Dropped for a white box with black bars; the glow was later switched off (the `Environment` glow cost about 3 ms per frame on an M1 at 3212x1595; the `glow_*` tuning values now do nothing unless `glow_enabled` is turned back on in `arena.tscn`).
- **Off-white concrete walls:** a noise-textured concrete look. Dropped for plain white with a very fine noise.
- **Edge darkening (`corner_shade`):** the walls darkened toward the edges where surfaces meet. The user didn't like the shadows along the edges, so it defaults to off.
- **One `Label3D` per scale-bar number:** fine for labels every 5 m (about 200 nodes), too many for a label every metre (about 1,200). Replaced by instanced `TextMesh` digits, one mesh per digit 0 to 9, ten draw calls and no textures.
- **Scale-bar labels every 5 m only:** replaced by a label at every metre in three sizes (every metre, every thin-bar step, every bold-bar step).
- **Tuning overlay without pausing, tuning presets:** not wanted.

## Known issues
- The speedometer shows the horizontal speed, but the dial's top is `soft_speed_limit`, which acts on the full 3D speed (see `movement.md`). A long vertical fall reads near zero on the dial while the limit is acting on it.
- Noise textures load async, so the first frame may show plain colour.
- City: roads are one 10 m tile wide; there's no edge barrier on the ground; building visuals don't match their hitboxes exactly (this blocks the mantle).
- Next: a main menu (Play, Quit) and a styled pause menu; building colour variety, vignette and grain; city props, empty-lot fill, far LOD.

## Performance notes
- The arena room fills the whole screen, so `grid.gdshader` runs on every pixel: keep it cheap (notch loop is skipped away from the central bars, two noise octaves). Window is 2560x1440 (`project.godot`). On an M1, bench avg frame went from 12.2 ms (3212x1595, glow on, 3 octaves) to 5.6 ms (1440p, glow off, trimmed shader).
