class_name Hud
extends CanvasLayer
## The first-person HUD: crosshair, grapple mode, rope reel bar and speed. Each element has its own
## script; this node only hands them what they read.

@onready var _crosshair: Crosshair = $Crosshair
@onready var _mode_label: ModeLabel = $ModeLabel
@onready var _reel_bar: ReelBar = $ReelBar
@onready var _speed: SpeedReadout = $SpeedReadout


func setup(body: CharacterBody3D, hook: GrappleHook) -> void:
	_crosshair.setup(hook)
	_mode_label.setup(hook)
	_reel_bar.setup(hook)
	_speed.setup(body)
