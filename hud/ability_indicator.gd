class_name AbilityIndicator
extends Control
## One ability on the HUD: a grey rounded rectangle with the ability's letter that flashes orange when the ability
## is used, or stays orange while lit (an ability that is on). It can also show an orange outline running round it:
## shrinking (the throw's time left) or growing clockwise (a charge). Colours and sizes are in HudStats ("Abilities").
## It doesn't know which ability it is; its bar (AbilityBar, JetAbilityBar) tells it what to show.

var _stats: HudStats
var _letter: String = ""
var _box := StyleBoxFlat.new()
## Real time (ms) of the last use; the flash fades from there. Real time, so bullet time and hit-stop don't stretch it.
var _flash_started_ms: int = -1
## Share of the outline shown, 0 to 1. 0 hides it.
var _outline: float = 0.0
## The outline grows clockwise from the top middle, instead of shrinking toward it.
var _outline_grows: bool = false
## Orange for as long as the ability is on.
var _lit: bool = false


func setup(letter: String, hud_stats: HudStats) -> void:
	_letter = letter
	_stats = hud_stats
	_stats.changed.connect(_apply_stats)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.anti_aliasing = true
	_apply_stats()
	set_process(false)


## The ability was used: flash.
func flash() -> void:
	_flash_started_ms = Time.get_ticks_msec()
	set_process(true)


## Shows the outline over `share` of the way round (0 hides it): the last part of the way, which shrinks toward the
## top middle as the share drops, or with `grows` the first part, which grows clockwise from it.
func set_outline(share: float, grows: bool = false) -> void:
	if is_equal_approx(share, _outline) and grows == _outline_grows:
		return
	_outline = share
	_outline_grows = grows
	queue_redraw()


## On: orange until switched off.
func set_lit(lit: bool) -> void:
	if lit != _lit:
		_lit = lit
		queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()
	if _flash_amount() <= 0.0:
		set_process(false)


func _apply_stats() -> void:
	custom_minimum_size = _stats.ability_size
	_box.set_corner_radius_all(roundi(_stats.ability_corner_radius))
	queue_redraw()


func _flash_amount() -> float:
	if _flash_started_ms < 0:
		return 0.0
	var elapsed: float = (Time.get_ticks_msec() - _flash_started_ms) / 1000.0
	return clampf(1.0 - elapsed / maxf(_stats.ability_flash_seconds, 0.01), 0.0, 1.0)


func _draw() -> void:
	if _stats == null:
		return
	var rect := Rect2(Vector2.ZERO, size)
	var flash: float = _flash_amount()
	_box.bg_color = _stats.ability_color.lerp(_stats.ability_flash_color, 1.0 if _lit else flash * flash)
	draw_style_box(_box, rect)
	var font: Font = ThemeDB.fallback_font
	var font_size: int = _stats.ability_letter_size
	var baseline: float = (size.y + font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	draw_string(font, Vector2(0.0, baseline), _letter, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, _stats.ability_letter_color)
	if _outline > 0.001:
		var width: float = _stats.throw_outline_width
		# Drawn just outside the box, so it frames the indicator instead of covering it.
		var outer: Rect2 = rect.grow(width * 0.5)
		var radius: float = _stats.ability_corner_radius + width * 0.5
		var path: PackedVector2Array = RoundedRectPath.head(outer, radius, _outline) if _outline_grows \
				else RoundedRectPath.tail(outer, radius, _outline)
		if path.size() >= 2:
			draw_polyline(path, _stats.ability_flash_color, width, true)
