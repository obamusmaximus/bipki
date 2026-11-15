class_name DamageNumbers
extends Control
## Floating damage numbers over enemies. Each hit an enemy takes spawns a number at the world point it
## happened, which rises and fades on screen (bigger for harder hits, red for the killing blow). It listens
## to every enemy's `damaged` signal, including ones that appear later, so nothing needs to register them.
## Full screen and real time (so the numbers stay readable in bullet time); text size follows the HUD scale.

const MAX_NUMBERS: int = 32
## Seconds a new number takes to settle from its pop size.
const POP_TIME: float = 0.12
const POP_EXTRA: float = 0.4
## Sideways scatter of a number's start (px, before HUD scale), so simultaneous hits don't overlap.
const SCATTER: float = 28.0
## World height added above the hit point so the number starts over the enemy.
const LIFT: float = 1.2

## One floating number.
class Pop:
	var world: Vector3
	var text: String
	var size: float
	var color: Color
	var drift: float
	var age: float = 0.0

var stats: HudStats

var _camera: Camera3D
var _pops: Array[Pop] = []


func setup(camera: Camera3D, hud_stats: HudStats) -> void:
	_camera = camera
	stats = hud_stats
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		_watch(node)
	get_tree().node_added.connect(_watch)


func _watch(node: Node) -> void:
	var enemy: Enemy = node as Enemy
	if enemy != null and not enemy.damaged.is_connected(_on_damaged):
		enemy.damaged.connect(_on_damaged)


func _on_damaged(amount: float, point: Vector3, killed: bool) -> void:
	if not stats.damage_numbers_enabled or amount < 0.5:
		return
	var pop := Pop.new()
	pop.world = point + Vector3.UP * LIFT
	pop.text = str(roundi(amount))
	pop.size = lerpf(stats.damage_number_size, stats.damage_number_big_size,
			clampf(amount / maxf(stats.damage_number_big_at, 0.01), 0.0, 1.0))
	pop.color = stats.damage_number_kill_color if killed else stats.damage_number_color
	pop.drift = randf_range(-SCATTER, SCATTER)
	_pops.append(pop)
	if _pops.size() > MAX_NUMBERS:
		_pops.pop_front()


func _process(delta: float) -> void:
	if _pops.is_empty():
		return
	# Real time: bullet time scales the delta down.
	var real_delta: float = delta / maxf(Engine.time_scale, 0.001)
	for pop: Pop in _pops:
		pop.age += real_delta
	_pops = _pops.filter(func(pop: Pop) -> bool: return pop.age < stats.damage_number_lifetime)
	queue_redraw()


func _draw() -> void:
	if _camera == null:
		return
	var font: Font = ThemeDB.fallback_font
	var ui_scale: float = stats.hud_scale
	for pop: Pop in _pops:
		if _camera.is_position_behind(pop.world):
			continue
		var fraction: float = pop.age / maxf(stats.damage_number_lifetime, 0.01)
		var settle: float = 1.0 + POP_EXTRA * maxf(1.0 - pop.age / POP_TIME, 0.0)
		var font_size: int = maxi(roundi(pop.size * ui_scale * settle), 1)
		var anchor: Vector2 = _camera.unproject_position(pop.world)
		anchor += Vector2(pop.drift * ui_scale, -stats.damage_number_rise * ui_scale * pop.age)
		var width: float = font.get_string_size(pop.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var position: Vector2 = anchor - Vector2(width * 0.5, 0.0)
		# Fully visible for the first half, then fades out.
		var alpha: float = 1.0 - smoothstep(0.5, 1.0, fraction)
		draw_string_outline(font, position, pop.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5,
				Color(0.0, 0.0, 0.0, 0.8 * alpha))
		draw_string(font, position, pop.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(pop.color, alpha))
