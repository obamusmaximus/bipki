class_name Hud
extends CanvasLayer
## The first-person HUD: crosshair, grapple mode, rope reel bar, speed, health bar, damage flash and death screen. Each element has its own
## script; this node only hands them what they read.

@onready var _crosshair: Crosshair = $Crosshair
@onready var _mode_label: ModeLabel = $ModeLabel
@onready var _reel_bar: ReelBar = $ReelBar
@onready var _speed: SpeedReadout = $SpeedReadout
@onready var _damage_flash: DamageFlash = $DamageFlash
@onready var _health_bar: HealthBar = $HealthBar
@onready var _death_screen: DeathScreen = $DeathScreen


func setup(body: CharacterBody3D, hook: GrappleHook, health: Health) -> void:
	_damage_flash.setup(health)
	_health_bar.setup(health)
	_death_screen.setup(health)
	_crosshair.setup(hook)
	_mode_label.setup(hook)
	_reel_bar.setup(hook)
	_speed.setup(body)
