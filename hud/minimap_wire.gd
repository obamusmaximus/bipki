class_name MinimapWire
extends Control
## The minimap's static layer: the city's wireframe lines, drawn from a list built once by Minimap.

var _lines: PackedVector2Array = PackedVector2Array()
var _color: Color = Color.WHITE
var _width: float = 1.0


func set_lines(lines: PackedVector2Array, color: Color, width: float) -> void:
	_lines = lines
	_color = color
	_width = width
	queue_redraw()


func _draw() -> void:
	if not _lines.is_empty():
		draw_multiline(_lines, _color, _width)
