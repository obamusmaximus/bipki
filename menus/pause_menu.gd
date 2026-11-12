class_name PauseMenu
extends CanvasLayer
## Pause menu: ESC pauses the game, shows the mouse and offers Resume, Options (volume, mouse
## sensitivity, fullscreen), the debug Tuning panel (debug builds only) and Quit. ESC again goes back, or resumes. It keeps running while the
## tree is paused (process mode "always") and owns the mouse capture state while open.

@onready var _center: Control = %Center
@onready var _main_panel: Control = %MainPanel
@onready var _options_panel: Control = %OptionsPanel
@onready var _resume_button: Button = %ResumeButton
@onready var _options_button: Button = %OptionsButton
@onready var _quit_button: Button = %QuitButton
@onready var _tuning_button: Button = %TuningButton
@onready var _tuning_panel: TuningPanel = %TuningPanel
@onready var _back_button: Button = %BackButton
@onready var _volume_slider: HSlider = %VolumeSlider
@onready var _sensitivity_slider: HSlider = %SensitivitySlider
@onready var _fullscreen_check: CheckButton = %FullscreenCheck


func _ready() -> void:
	GameSettings.load_and_apply()
	_volume_slider.value = GameSettings.master_volume
	_sensitivity_slider.value = GameSettings.mouse_sensitivity_scale
	_fullscreen_check.button_pressed = GameSettings.fullscreen
	_volume_slider.value_changed.connect(_on_volume_changed)
	_sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_resume_button.pressed.connect(resume)
	_options_button.pressed.connect(_show_options.bind(true))
	_back_button.pressed.connect(_show_options.bind(false))
	_quit_button.pressed.connect(get_tree().quit)
	_tuning_button.visible = OS.is_debug_build()
	_tuning_button.pressed.connect(_show_tuning.bind(true))
	_tuning_panel.back_pressed.connect(_show_tuning.bind(false))
	visible = false


var _stats: HudStats
## A scale change arrived while the mouse was held (dragging a slider). It is applied on release.
var _scale_pending: bool = false


## Called by Player with the HUD stats. The menus follow `hud_scale`.
func setup(hud_stats: HudStats) -> void:
	_stats = hud_stats
	_stats.changed.connect(_on_hud_stats_changed)
	_apply_scale()


func _input(event: InputEvent) -> void:
	if _scale_pending and event is InputEventMouseButton and not event.pressed:
		_apply_scale.call_deferred() # After the control under the pointer has handled the release.


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if not get_tree().paused:
		pause()
	elif _options_panel.visible:
		_show_options(false)
	elif _tuning_panel.visible:
		_show_tuning(false)
	else:
		resume()


func pause() -> void:
	get_tree().paused = true
	visible = true
	_tuning_panel.visible = false
	_show_options(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func resume() -> void:
	GameSettings.save()
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _show_options(show_options: bool) -> void:
	_options_panel.visible = show_options
	_main_panel.visible = not show_options
	if show_options:
		_volume_slider.grab_focus()
	else:
		GameSettings.save()
		_resume_button.grab_focus()


func _show_tuning(show_tuning: bool) -> void:
	_tuning_panel.visible = show_tuning
	_main_panel.visible = not show_tuning
	if show_tuning:
		_tuning_panel.open()
	else:
		_tuning_button.grab_focus()


## Rescales the menus now, or once the mouse is released if it is held (so a dragged slider doesn't change
## size under the pointer).
func _on_hud_stats_changed() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_scale_pending = true
	else:
		_apply_scale()


func _apply_scale() -> void:
	_scale_pending = false
	_center.pivot_offset_ratio = Vector2(0.5, 0.5)
	_center.scale = Vector2.ONE * _stats.hud_scale
	_tuning_panel.fit_to_screen()


func _on_volume_changed(value: float) -> void:
	GameSettings.master_volume = value
	GameSettings.apply()


func _on_sensitivity_changed(value: float) -> void:
	GameSettings.mouse_sensitivity_scale = value


func _on_fullscreen_toggled(pressed: bool) -> void:
	GameSettings.fullscreen = pressed
	GameSettings.apply()
