class_name Hud
extends CanvasLayer
## The first-person HUD: crosshair, grapple mode, rope reel bar, speed, health bar, lives, damage flash
## and death screen. Each element has its own
## script; this node only hands them what they read.

@onready var _crosshair: Crosshair = $Crosshair
@onready var _bottom_center: VBoxContainer = $BottomCenter
@onready var _bottom_left: VBoxContainer = $BottomLeft
@onready var _mode_label: ModeLabel = $BottomCenter/ModeLabel
@onready var _reel_bar: ReelBar = $BottomCenter/ReelBar
@onready var _speed: SpeedReadout = $SpeedReadout
@onready var _damage_flash: DamageFlash = $DamageFlash
@onready var _health_bar: HealthBar = $BottomLeft/HealthBar
@onready var _death_screen: DeathScreen = $DeathScreen
@onready var _minimap: Minimap = $Minimap
@onready var _arc: TrajectoryArc = $TrajectoryArc

var stats: HudStats


func setup(body: CharacterBody3D, hook: GrappleHook, health: Health, player_stats: PlayerStats, hud_stats: HudStats, minimap_stats: MinimapStats) -> void:
	stats = hud_stats
	_minimap.setup(body, minimap_stats)
	stats.changed.connect(_apply_scale)
	_apply_scale()
	_damage_flash.setup(health)
	_health_bar.setup(health)
	_death_screen.setup(stats)
	_crosshair.setup(hook)
	_mode_label.setup(hook)
	_reel_bar.setup(hook)
	_speed.setup(body, player_stats, hud_stats)


## Gives the trajectory arc what it needs. A separate call from setup() because the predictor is set up later.
func setup_arc(camera: Camera3D, predictor: TrajectoryPredictor, body: CharacterBody3D, arc_stats: TrajectoryArcStats) -> void:
	_arc.setup(camera, predictor, body, arc_stats)


## Gives the throw's HUD what it reads: the aiming gauges, and the release prediction on the trajectory arc.
func setup_throw(throw: EnemyThrow, camera: Camera3D, arc_stats: TrajectoryArcStats) -> void:
	var readout := ThrowReadout.new()
	add_child(readout)
	readout.setup(throw, camera, arc_stats, stats)
	_arc.set_throw(throw)


## Floating damage numbers over enemies. They project from world points, so like the arc they are full screen.
func setup_damage_numbers(camera: Camera3D) -> void:
	var numbers := DamageNumbers.new()
	add_child(numbers)
	numbers.setup(camera, stats)


## Pips for the lives left, above the health bar.
func setup_lives(lives: Lives) -> void:
	var readout := LivesReadout.new()
	_bottom_left.add_child(readout)
	_bottom_left.move_child(readout, 0)
	readout.setup(lives)


## The last life is gone: freeze the game behind the death screen.
func show_death_screen() -> void:
	_death_screen.open()


## Gives the minimap the city's building boxes once the level has built the city.
func set_city(boxes: Array[AABB]) -> void:
	_minimap.set_city(boxes)


## Scales the on-screen elements around the anchor they hug (bottom-left, bottom-centre, top-right, centre). Elements that
## share a corner sit in one container, so scaling keeps them stacked instead of overlapping.
## The damage flash is a full-screen overlay and is left alone; the death screen scales its own content.
func _apply_scale() -> void:
	var anchors: Dictionary = {
		_crosshair: Vector2(0.5, 0.5),
		_speed: Vector2(0.5, 0.5),
		_bottom_center: Vector2(0.5, 1.0),
		_bottom_left: Vector2(0.0, 1.0),
		_minimap: Vector2(1.0, 0.0),
	}
	for element: Control in anchors:
		element.pivot_offset_ratio = anchors[element]
		element.scale = Vector2.ONE * stats.hud_scale
