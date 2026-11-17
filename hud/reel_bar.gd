class_name ReelBar
extends Control
## Upright bar on the right edge of the screen showing how much swing rope is left; it drains downward as you
## reel. The mark is where reeling detaches the hook. Only shown while swinging.

@export var back_color: Color = Color(0.0, 0.0, 0.0, 0.45)
@export var fill_color: Color = Color(1.0, 1.0, 1.0, 0.85)
@export var low_color: Color = Color(1.0, 0.35, 0.3, 0.9)
@export var mark_color: Color = Color(1.0, 0.75, 0.3, 1.0)

var _hook: GrappleHook


func setup(hook: GrappleHook) -> void:
	_hook = hook
	modulate.a = 0.0


func _process(_delta: float) -> void:
	if _hook == null:
		return
	var swinging: bool = _hook.is_swinging()
	modulate.a = 1.0 if swinging else 0.0 # Faded, not hidden, so it keeps its place in the layout.
	if swinging:
		queue_redraw()


func _draw() -> void:
	if _hook == null:
		return
	var start_length: float = _hook.get_rope_start_length()
	if start_length <= 0.0:
		return
	var ratio: float = clampf(_hook.get_rope_length() / start_length, 0.0, 1.0)
	var mark: float = clampf(_hook.stats.min_rope_length / start_length, 0.0, 1.0)
	var low: float = clampf(inverse_lerp(mark + 0.25, mark, ratio), 0.0, 1.0) # Reddens near the detach mark.
	draw_rect(Rect2(Vector2.ZERO, size), back_color)
	draw_rect(Rect2(0.0, size.y * (1.0 - ratio), size.x, size.y * ratio), fill_color.lerp(low_color, low))
	var mark_y: float = size.y * (1.0 - mark)
	draw_line(Vector2(-2.0, mark_y), Vector2(size.x + 2.0, mark_y), mark_color, 2.0)
