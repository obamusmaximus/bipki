class_name Hud
extends CanvasLayer
## The first-person HUD shell: what every loadout shares (health, lives, speedometer, minimap, damage flash and
## numbers, the death screen). The loadout's own elements come in a LoadoutHud module, mounted into the slots
## (`mount`). Each element has its own script; this node only hands them what they read and lays out the groups.
## Layout: every element lives in one anchor group. The centre group (`Center`: crosshair, speedometer) and the
## full-screen overlays that track the world sit on this layer directly, `Underlay` below the visor (trajectory arc)
## and `Overlay` on top (throw readout, damage numbers). The edge groups (TopLeft, TopCenter, Right, BottomLeft,
## BottomCenter, BottomRight and the top-right Minimap) sit in Visor's viewport, which a shader bends like the inside
## of a helmet visor (visor.gdshader).

## Slot name (a LoadoutHud holder's name) to the group's path. `AbilityRow` is the row right of the health bar.
const SLOTS: Dictionary = {
	&"Underlay": ^"Underlay",
	&"Center": ^"Center",
	&"Overlay": ^"Overlay",
	&"TopLeft": ^"Visor/Viewport/TopLeft",
	&"TopCenter": ^"Visor/Viewport/TopCenter",
	&"Right": ^"Visor/Viewport/Right",
	&"BottomLeft": ^"Visor/Viewport/BottomLeft",
	&"AbilityRow": ^"Visor/Viewport/BottomLeft/Row",
	&"BottomCenter": ^"Visor/Viewport/BottomCenter",
	&"BottomRight": ^"Visor/Viewport/BottomRight",
}

@onready var _center: Control = $Center
@onready var _overlay: Control = $Overlay
@onready var _speed: SpeedReadout = $Center/SpeedReadout
@onready var _visor: SubViewportContainer = $Visor
@onready var _top_left: Control = $Visor/Viewport/TopLeft
@onready var _top_center: Control = $Visor/Viewport/TopCenter
@onready var _right: Control = $Visor/Viewport/Right
@onready var _bottom_left: VBoxContainer = $Visor/Viewport/BottomLeft
@onready var _bottom_center: Control = $Visor/Viewport/BottomCenter
@onready var _bottom_right: Control = $Visor/Viewport/BottomRight
@onready var _health_bar: HealthBar = $Visor/Viewport/BottomLeft/Row/HealthBar
@onready var _minimap: Minimap = $Visor/Viewport/Minimap
@onready var _damage_flash: DamageFlash = $DamageFlash
@onready var _death_screen: DeathScreen = $DeathScreen

var stats: HudStats


func setup(body: CharacterBody3D, health: Health, player_stats: PlayerStats, hud_stats: HudStats, minimap_stats: MinimapStats) -> void:
	stats = hud_stats
	_minimap.setup(body, minimap_stats)
	stats.changed.connect(_apply_layout)
	_apply_layout()
	_damage_flash.setup(health)
	_health_bar.setup(health)
	_death_screen.setup(stats)
	_speed.setup(body, player_stats, hud_stats)


## Mounts a loadout's HUD module: adds it (resolving its `@onready` references), then moves each holder's elements
## into the slot of the holder's name, after anything already there. The module sets its elements up afterwards.
func mount(module: LoadoutHud) -> void:
	add_child(module)
	for holder: Node in module.get_children():
		if not SLOTS.has(holder.name):
			push_error("LoadoutHud holder '%s' names no Hud slot" % holder.name)
			continue
		var slot: Node = get_node(SLOTS[holder.name])
		for element: Node in holder.get_children():
			element.reparent(slot, false)
			module.adopt(element)
		holder.queue_free()


## Floating damage numbers over enemies. They project from world points, so like the arc they are full screen.
func setup_damage_numbers(camera: Camera3D) -> void:
	var numbers := DamageNumbers.new()
	_overlay.add_child(numbers)
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
		_center: Vector2(0.5, 0.5),
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
		if element == _center or element == _minimap:
			continue # The full-screen centre group, and the minimap's own margin.
		# 0 at a left/top anchor gives +margin, 1 gives -margin, the middle gives 0.
		var inset: Vector2 = (Vector2.ONE - anchor * 2.0) * stats.edge_margin
		element.offset_left = inset.x
		element.offset_right = inset.x
		element.offset_top = inset.y
		element.offset_bottom = inset.y
	var visor: ShaderMaterial = _visor.material as ShaderMaterial
	visor.set_shader_parameter("curve_x", deg_to_rad(stats.visor_curve_x))
	visor.set_shader_parameter("curve_y", deg_to_rad(stats.visor_curve_y))
