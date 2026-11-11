class_name DamageFlash
extends TextureRect
## A red vignette that flashes at the screen edges when the player takes damage, then fades out.

## Opacity of the flash for a hit worth `full_flash_damage` or more.
@export_range(0.0, 1.0) var max_alpha: float = 0.85
## Damage that gives the strongest flash. Smaller hits flash less.
@export var full_flash_damage: float = 30.0
## Seconds for the flash to fade away.
@export var fade_time: float = 0.6

var _alpha: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	stretch_mode = TextureRect.STRETCH_SCALE
	texture = _make_vignette()
	modulate.a = 0.0


func setup(health: Health) -> void:
	health.damaged.connect(_on_damaged)


func _process(delta: float) -> void:
	if _alpha <= 0.0:
		return
	_alpha = maxf(_alpha - max_alpha / fade_time * delta, 0.0)
	modulate.a = _alpha


func _on_damaged(amount: float) -> void:
	_alpha = maxf(_alpha, max_alpha * clampf(amount / full_flash_damage, 0.3, 1.0))
	modulate.a = _alpha


## Transparent in the middle, red toward the edges.
func _make_vignette() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([Color(0.8, 0.0, 0.0, 0.0), Color(0.8, 0.0, 0.0, 0.25), Color(0.8, 0.0, 0.0, 1.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	return tex
