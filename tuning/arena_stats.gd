class_name ArenaStats
extends Resource
## Tunable numbers for the look of the testing arena: the white wall texture, the black grid and scale bars, the pillar and the light.
## One .tres per preset (tuning/arena_default.tres). `ArenaLevel` holds it, `ArenaLook` and `ArenaScale` apply it live.

@export_group("Walls")
## Base colour of the walls, floor and ceiling.
@export var wall_color: Color = Color(0.97, 0.97, 0.96)
## Size of the biggest speckles in the noise (m). Small is a very fine texture.
@export var noise_scale: float = 0.15
## How strongly the noise varies the brightness (0 = flat).
@export_range(0.0, 0.5, 0.005) var noise_strength: float = 0.03
## How strongly the fine grain varies the brightness (0 = none).
@export_range(0.0, 0.3, 0.005) var grain_strength: float = 0.02
## How much darker the surfaces get toward the edges where they meet, a cheap stand-in for ambient occlusion (0 = off).
@export_range(0.0, 1.0, 0.01) var corner_shade: float = 0.0
## How far from an edge the darkening reaches (m).
@export var corner_shade_range: float = 14.0

@export_group("Grid")
## Distance between the bold bars (m). Also the step of the biggest notches and labels on the scale bars.
@export var major_spacing: float = 10.0
## Distance between the thin bars (m). Also the step of the medium notches and labels on the scale bars.
@export var minor_spacing: float = 5.0
## Colour of all the bars, the scale bars and the labels' notches.
@export var bar_color: Color = Color(0.0, 0.0, 0.0)
## Width of the bold bars (m). A bar never gets thinner than a pixel, whatever the distance.
@export var major_width: float = 0.14
## Width of the thin bars (m).
@export var minor_width: float = 0.06

@export_group("Scale bar")
## Width of the central bars at 50 m that carry the scale (m).
@export var central_width: float = 0.3
## Width of a notch every metre (m).
@export var notch_width: float = 0.05
## Width of a notch at every thin-bar step (m), slightly bigger.
@export var notch_width_mid: float = 0.09
## Width of a notch at every bold-bar step (m), the biggest.
@export var notch_width_long: float = 0.14
## Half-length of a notch every metre (m).
@export var notch_length: float = 0.5
## Half-length of a notch at every thin-bar step (m).
@export var notch_length_mid: float = 1.0
## Half-length of a notch at every bold-bar step (m).
@export var notch_length_long: float = 1.6
## Notches this close (m) to the centre are left out, to make room for the labels where the two bars cross.
@export var notch_clear: float = 3.5
## Within this distance (m) of a central bar the grid bars crossing it and the thin bars beside it are left out, to leave room for the notches and labels.
@export var clear_band: float = 5.0
## Height of the number labels every metre (m, the font's em size).
@export var label_size: float = 0.55
## Height of the labels at every thin-bar step (m).
@export var label_size_mid: float = 1.4
## Height of the labels at every bold-bar step (m).
@export var label_size_long: float = 2.4
## Colour of the number labels.
@export var label_color: Color = Color(0.0, 0.0, 0.0)

@export_group("Glow")
## Strength of the glow. Keep it low: the white room is bright everywhere, so a strong glow just hazes the screen.
@export_range(0.0, 1.0, 0.01) var glow_intensity: float = 0.25
## How much the glow spreads into a soft bloom.
@export_range(0.0, 1.0, 0.01) var glow_bloom: float = 0.05
## Brightness above which a surface starts to glow. The room is just under 1, so a lower value makes all of it glow.
@export var glow_hdr_threshold: float = 0.9

@export_group("Pillar")
## Colour of the pillar.
@export var pillar_color: Color = Color(1.0, 0.42, 0.08)

@export_group("Lighting")
## Colour of the ambient light on the enemies, the pillar and the player's hands. The room itself is unlit.
@export var ambient_color: Color = Color(1.0, 1.0, 1.0)
## Strength of the ambient light.
@export var ambient_energy: float = 0.9
## Strength of the directional light that gives the pillar and the enemies some form.
@export var light_energy: float = 0.6
