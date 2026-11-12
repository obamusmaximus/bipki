class_name Hud
extends CanvasLayer
## The first-person HUD: crosshair, grapple mode, rope reel bar, speed, health bar, damage flash and death screen. Each element has its own
## script; this node only hands them what they read.

@onready var _crosshair: Crosshair = $Crosshair
@onready var _bottom_center: VBoxContainer = $BottomCenter
@onready var _bottom_left: VBoxContainer = $BottomLeft
@onready var _mode_label: ModeLabel = $BottomCenter/ModeLabel
@onready var _reel_bar: ReelBar = $BottomCenter/ReelBar
@onready var _speed: SpeedReadout = $BottomLeft/SpeedReadout
@onready var _damage_flash: DamageFlash = $DamageFlash
@onready var _health_bar: HealthBar = $BottomLeft/HealthBar
@onready var _death_screen: DeathScreen = $DeathScreen

var stats: HudStats


func setup(body: CharacterBody3D, hook: GrappleHook, health: Health, hud_stats: HudStats) -> void:
	stats = hud_stats
	stats.changed.connect(_apply_scale)
	_apply_scale()
	_damage_flash.setup(health)
	_health_bar.setup(health)
	_death_screen.setup(health, stats)
	_crosshair.setup(hook)
	_mode_label.setup(hook)
	_reel_bar.setup(hook)
	_speed.setup(body)


## Scales the on-screen elements around the anchor they hug (bottom-left, bottom-centre, centre). Elements that
## share a corner sit in one container, so scaling keeps them stacked instead of overlapping.
## The damage flash is a full-screen overlay and is left alone; the death screen scales its own content.
func _apply_scale() -> void:
	var anchors: Dictionary = {
		_crosshair: Vector2(0.5, 0.5),
		_bottom_center: Vector2(0.5, 1.0),
		_bottom_left: Vector2(0.0, 1.0),
	}
	for element: Control in anchors:
		element.pivot_offset_ratio = anchors[element]
		element.scale = Vector2.ONE * stats.hud_scale
