class_name Hud
extends CanvasLayer
## The first-person HUD. Each element has its own script; this node only hands them what they read and lays out
## the groups.
## Layout: every element lives in one anchor group. The centre group (crosshair, speedometer) and the full-screen
## overlays that track the world (trajectory arc, throw readout, damage numbers, damage flash) sit on this layer
## directly. The edge groups (TopLeft, TopCenter, Right, BottomLeft, BottomCenter, BottomRight and the top-right
## Minimap) sit in Visor's viewport, which a shader bends like the inside of a helmet visor (visor.gdshader).

@onready var _crosshair: Crosshair = $Crosshair
@onready var _speed: SpeedReadout = $SpeedReadout
@onready var _visor: SubViewportContainer = $Visor
@onready var _top_left: Control = $Visor/Viewport/TopLeft
@onready var _top_center: Control = $Visor/Viewport/TopCenter
@onready var _right: Control = $Visor/Viewport/Right
@onready var _bottom_left: VBoxContainer = $Visor/Viewport/BottomLeft
@onready var _bottom_center: Control = $Visor/Viewport/BottomCenter
@onready var _bottom_right: Control = $Visor/Viewport/BottomRight
@onready var _mode_label: ModeLabel = $Visor/Viewport/BottomCenter/ModeLabel
@onready var _reel_bar: ReelBar = $Visor/Viewport/Right/ReelBar
@onready var _health_bar: HealthBar = $Visor/Viewport/BottomLeft/Row/HealthBar
@onready var _abilities: AbilityBar = $Visor/Viewport/BottomLeft/Row/Abilities
@onready var _minimap: Minimap = $Visor/Viewport/Minimap
@onready var _damage_flash: DamageFlash = $DamageFlash
@onready var _death_screen: DeathScreen = $DeathScreen
@onready var _arc: TrajectoryArc = $TrajectoryArc

var stats: HudStats


func setup(body: CharacterBody3D, hook: GrappleHook, health: Health, player_stats: PlayerStats, hud_stats: HudStats, minimap_stats: MinimapStats) -> void:
	stats = hud_stats
	_minimap.setup(body, minimap_stats)
	stats.changed.connect(_apply_layout)
	_apply_layout()
	_damage_flash.setup(health)
	_health_bar.setup(health)
	_abilities.setup(hook, hud_stats)
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


## Places each group `edge_margin` in from the screen edges it hugs, scales it around that anchor point (so a
## group's elements stay stacked instead of overlapping) and sets the visor's curve. The minimap keeps its own
## margin (MinimapStats). The damage flash is a full-screen overlay and is left alone; the death screen scales its
## own content.
func _apply_layout() -> void:
	var anchors: Dictionary = {
		_crosshair: Vector2(0.5, 0.5),
		_speed: Vector2(0.5, 0.5),
		_top_left: Vector2(0.0, 0.0),
		_top_center: Vector2(0.5, 0.0),
		_right: Vector2(1.0, 0.5),
		_bottom_left: Vector2(0.0, 1.0),
		_bottom_center: Vector2(0.5, 1.0),
		_bottom_right: Vector2(1.0, 1.0),
		_minimap: Vector2(1.0, 0.0),
	}
	for element: Control in anchors:
		var anchor: Vector2 = anchors[element]
		element.pivot_offset_ratio = anchor
		element.scale = Vector2.ONE * stats.hud_scale
		if element == _crosshair or element == _speed or element == _minimap:
			continue # Full-screen centre elements, and the minimap's own margin.
		# 0 at a left/top anchor gives +margin, 1 gives -margin, the middle gives 0.
		var inset: Vector2 = (Vector2.ONE - anchor * 2.0) * stats.edge_margin
		element.offset_left = inset.x
		element.offset_right = inset.x
		element.offset_top = inset.y
		element.offset_bottom = inset.y
	var visor: ShaderMaterial = _visor.material as ShaderMaterial
	visor.set_shader_parameter("curve_x", deg_to_rad(stats.visor_curve_x))
	visor.set_shader_parameter("curve_y", deg_to_rad(stats.visor_curve_y))
