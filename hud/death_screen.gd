class_name DeathScreen
extends Control
## Shown when the player dies: the game freezes behind a dark red veil, and a Restart button reloads the
## level. It keeps running while the tree is paused (process mode "always").

var _restart_button: Button


func setup(health: Health) -> void:
	health.died.connect(_on_died)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var veil := ColorRect.new()
	veil.color = Color(0.25, 0.0, 0.0, 0.6)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.add_theme_constant_override("separation", 24)
	add_child(column)

	var title := Label.new()
	title.text = "YOU DIED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	title.add_theme_constant_override("outline_size", 8)
	column.add_child(title)

	_restart_button = Button.new()
	_restart_button.text = "Restart"
	_restart_button.custom_minimum_size = Vector2(200.0, 48.0)
	_restart_button.pressed.connect(_restart)
	column.add_child(_restart_button)


func _on_died() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_restart_button.grab_focus()


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
