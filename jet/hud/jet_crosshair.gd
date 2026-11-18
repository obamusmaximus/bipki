class_name JetCrosshair
extends Control
## The jet loadout's crosshair: a small ring with a dot, in the middle of the screen. Full screen like the Hud's
## centre group, so it scales about the same point. Placeholder until the weapons give it something to show.

@export var color: Color = Color(1.0, 1.0, 1.0, 0.8)
@export var radius: float = 7.0


func _draw() -> void:
	var center: Vector2 = size * 0.5
	draw_arc(center, radius, 0.0, TAU, 32, Color(0.0, 0.0, 0.0, 0.5), 3.5, true)
	draw_arc(center, radius, 0.0, TAU, 32, color, 1.5, true)
	draw_circle(center, 1.5, color)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
