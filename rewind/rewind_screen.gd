class_name RewindScreen
extends CanvasLayer
## The rewind's screen effect over everything but the pause menu: the colour drains to a cold tint, the colour channels
## split, scanlines roll and the edges darken. `RewindSequence` sets its strength each frame; 0 hides it.

const LAYER: int = 50

var _rect: ColorRect
var _material: ShaderMaterial


func _ready() -> void:
	layer = LAYER
	_material = ShaderMaterial.new()
	_material.shader = preload("res://rewind/rewind_screen.gdshader")
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _material
	add_child(_rect)
	set_strength(0.0)


func set_strength(strength: float) -> void:
	visible = strength > 0.0
	_material.set_shader_parameter(&"strength", strength)
