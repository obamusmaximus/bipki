class_name LivesReadout
extends Control
## One pip per life the player has left, above the health bar. A spent life shows as an empty ring.

const PIP_RADIUS: float = 7.0
const PIP_GAP: float = 8.0
const FULL_COLOR: Color = Color(0.4, 0.85, 1.0, 0.95)
const SPENT_COLOR: Color = Color(1.0, 1.0, 1.0, 0.35)

var _left: int = 0
var _total: int = 0


func setup(lives: Lives) -> void:
	_left = lives.get_left()
	_total = _left
	custom_minimum_size = Vector2(_total * (PIP_RADIUS * 2.0 + PIP_GAP), PIP_RADIUS * 2.0 + 4.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	lives.changed.connect(_on_changed)
	queue_redraw()


func _on_changed(left: int) -> void:
	_left = left
	queue_redraw()


func _draw() -> void:
	for i: int in _total:
		var center := Vector2(PIP_RADIUS + i * (PIP_RADIUS * 2.0 + PIP_GAP), PIP_RADIUS + 2.0)
		if i < _left:
			draw_circle(center, PIP_RADIUS, FULL_COLOR)
		else:
			draw_arc(center, PIP_RADIUS - 1.0, 0.0, TAU, 20, SPENT_COLOR, 2.0, true)
