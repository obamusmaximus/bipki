class_name RewindFlash
extends Control
## A short full-screen flash with "REWIND" when a death sets the level back. Fades in real time, so bullet time
## or a hit-stop doesn't hold it on screen.

const SHOW_TIME: float = 0.7
const TINT: Color = Color(0.35, 0.75, 1.0, 0.35)

var _left: float = 0.0
var _label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_label = Label.new()
	_label.text = "REWIND"
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 64)
	_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.7))
	_label.add_theme_constant_override("outline_size", 8)
	add_child(_label)


func play() -> void:
	_left = SHOW_TIME
	visible = true
	queue_redraw()


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left -= minf(delta / maxf(Engine.time_scale, 0.001), 0.1)
	if _left <= 0.0:
		visible = false
		return
	modulate.a = clampf(_left / SHOW_TIME, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), TINT)
