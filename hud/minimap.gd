class_name Minimap
extends Control
## HUD minimap: a 3D isometric wireframe of the city with the player as a glowing dot and a trail that fades
## over a few seconds. The wireframe is drawn once (MinimapWire); this node draws the moving parts each frame.
## Sits in the top-right corner. Hud scales it with the rest of the HUD. Tuning is in MinimapStats.

## Edges of a box as pairs of AABB.get_endpoint() indices.
const BOX_EDGES: Array[Vector2i] = [
	Vector2i(0, 1), Vector2i(2, 3), Vector2i(4, 5), Vector2i(6, 7),
	Vector2i(0, 2), Vector2i(1, 3), Vector2i(4, 6), Vector2i(5, 7),
	Vector2i(0, 4), Vector2i(1, 5), Vector2i(2, 6), Vector2i(3, 7),
]

var stats: MinimapStats

var _body: Node3D
var _boxes: Array[AABB] = []
var _projection := MinimapProjection.new()
var _trail := MinimapTrail.new()
var _clock: float = 0.0

@onready var _background: ColorRect = $Background
@onready var _wire: MinimapWire = $Wire


func setup(body: Node3D, minimap_stats: MinimapStats) -> void:
	_body = body
	stats = minimap_stats
	stats.changed.connect(_on_stats_changed)
	_apply_layout()
	_rebuild()


## Gives the minimap the city's building boxes (world space). Called once the city exists.
func set_city(boxes: Array[AABB]) -> void:
	_boxes = boxes
	_rebuild()


func _process(delta: float) -> void:
	if stats == null or _body == null:
		return
	_clock += delta
	_trail.add(_body.global_position, _clock)
	_trail.prune(_clock, stats.trail_seconds)
	queue_redraw()


func _draw() -> void:
	if stats == null or _body == null or _boxes.is_empty():
		return
	_draw_trail()
	_draw_player()


func _on_stats_changed() -> void:
	_apply_layout()
	_rebuild()


## Anchors the panel to the top-right corner at the tuned size and margin, and sets the colours.
func _apply_layout() -> void:
	visible = stats.minimap_visible
	# The opacity applies to the map only (this node's own drawing and the wireframe), not to the background box.
	self_modulate.a = stats.minimap_opacity
	_wire.self_modulate.a = stats.minimap_opacity
	_background.color = stats.background_color
	var size: Vector2 = stats.panel_size()
	offset_left = -(stats.minimap_margin + size.x)
	offset_right = -stats.minimap_margin
	offset_top = stats.minimap_margin
	offset_bottom = stats.minimap_margin + size.y


## Refits the projection to the city and rebuilds the wireframe lines.
func _rebuild() -> void:
	if stats == null or _boxes.is_empty():
		return
	var bounds: AABB = _city_bounds()
	_projection.setup(bounds, stats.panel_size(), stats.pitch_degrees, stats.yaw_degrees, stats.view_padding)
	var lines := PackedVector2Array()
	for box: AABB in _boxes:
		for edge: Vector2i in BOX_EDGES:
			lines.append(_projection.project(box.get_endpoint(edge.x)))
			lines.append(_projection.project(box.get_endpoint(edge.y)))
	if stats.show_ground_outline:
		var corners: Array[Vector3] = [
			bounds.position, bounds.position + Vector3(bounds.size.x, 0.0, 0.0),
			bounds.position + Vector3(bounds.size.x, 0.0, bounds.size.z), bounds.position + Vector3(0.0, 0.0, bounds.size.z),
		]
		for i: int in 4:
			lines.append(_projection.project(Vector3(corners[i].x, 0.0, corners[i].z)))
			lines.append(_projection.project(Vector3(corners[(i + 1) % 4].x, 0.0, corners[(i + 1) % 4].z)))
	_wire.set_lines(lines, Color(stats.wire_color, stats.wire_alpha), stats.wire_width)
	queue_redraw()


## The box the view is fitted to: all the buildings, from the ground up to the tallest roof plus headroom.
func _city_bounds() -> AABB:
	var bounds: AABB = _boxes[0]
	for box: AABB in _boxes:
		bounds = bounds.merge(box)
	bounds.position.y = 0.0
	bounds.size.y = bounds.end.y + stats.view_headroom
	return bounds


func _draw_trail() -> void:
	var count: int = _trail.size()
	for i: int in range(1, count):
		var life: float = clampf(1.0 - (_clock - _trail.times[i]) / maxf(stats.trail_seconds, 0.01), 0.0, 1.0)
		if life <= 0.0:
			continue
		var from: Vector2 = _projection.project(_trail.positions[i - 1])
		var to: Vector2 = _projection.project(_trail.positions[i])
		var width: float = stats.trail_width * (0.35 + 0.65 * life)
		draw_line(from, to, Color(stats.trail_color, 0.22 * life * stats.glow_strength * 2.0), width * 3.0, true)
		draw_line(from, to, Color(stats.trail_color, life), width, true)


func _draw_player() -> void:
	var world: Vector3 = _body.global_position
	var dot: Vector2 = _projection.project(world)
	if stats.show_drop_line:
		var ground: Vector2 = _projection.project(Vector3(world.x, 0.0, world.z))
		draw_line(dot, ground, Color(stats.dot_color, 0.35), 1.0, true)
		draw_circle(ground, 1.8, Color(stats.dot_color, 0.4))
	var glow: float = stats.glow_strength
	draw_circle(dot, stats.glow_radius, Color(stats.dot_color, 0.10 * glow))
	draw_circle(dot, stats.glow_radius * 0.65, Color(stats.dot_color, 0.18 * glow))
	draw_circle(dot, stats.dot_radius * 1.9, Color(stats.dot_color, 0.45 * glow + 0.1))
	draw_circle(dot, stats.dot_radius, Color(stats.dot_color.lightened(0.5), 1.0))
