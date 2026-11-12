class_name HudStats
extends Resource
## Tunable numbers for the HUD and menus. One .tres per preset (tuning/hud_default.tres). The Player scene holds it in
## `hud_stats` and hands it to the Hud. Likely to move into GameSettings once the size feels right.

@export_group("Scale")
## Size of the on-screen HUD (crosshair, mode label, reel bar, speed readout, health bar) and of the menus
## (pause menu, tuning panel, death screen). 1 = normal. Menus rescale when the mouse is released, so a slider
## doesn't move under the pointer while it is dragged.
@export_range(0.5, 3.0, 0.05) var hud_scale: float = 1.0
