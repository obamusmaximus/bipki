class_name GrappleHud
extends LoadoutHud
## The grapple loadout's HUD: the crosshair (centre), the reel bar (right edge), the swing, launch and throw
## indicators (next to the health bar), the mode label (bottom centre), the trajectory arc (under the visor) and the
## throw's readout (on top). See grapple.md, combat.md and levels_and_hud.md.

@onready var _crosshair: Crosshair = $Center/Crosshair
@onready var _reel_bar: ReelBar = $Right/ReelBar
@onready var _abilities: AbilityBar = $AbilityRow/Abilities
@onready var _mode_label: ModeLabel = $BottomCenter/ModeLabel
@onready var _arc: TrajectoryArc = $Underlay/TrajectoryArc
@onready var _throw_readout: ThrowReadout = $Overlay/ThrowReadout


## Called by GrappleLoadout after `Hud.mount`.
func setup(hook: GrappleHook, camera: Camera3D, predictor: TrajectoryPredictor, body: CharacterBody3D,
		arc_stats: TrajectoryArcStats, hud_stats: HudStats) -> void:
	_abilities.setup(hook, hud_stats)
	_crosshair.setup(hook)
	_mode_label.setup(hook)
	_reel_bar.setup(hook)
	_arc.setup(camera, predictor, body, arc_stats)
	# The throw's aiming gauges, and its release prediction on the trajectory arc.
	_throw_readout.setup(hook.get_throw(), camera, arc_stats, hud_stats)
	_arc.set_throw(hook.get_throw())
