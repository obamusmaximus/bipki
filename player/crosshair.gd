class_name Crosshair
extends Control
## Simple centered dot crosshair.

@export var radius: float = 2.5
@export var color: Color = Color(1.0, 1.0, 1.0, 0.9)
@export var outline_color: Color = Color(0.0, 0.0, 0.0, 0.6)


func _draw() -> void:
	var center: Vector2 = size * 0.5
	draw_circle(center, radius + 1.0, outline_color)
	draw_circle(center, radius, color)
