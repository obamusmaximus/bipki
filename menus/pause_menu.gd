class_name PauseMenu
extends CanvasLayer
## Pause menu: ESC pauses the game, shows the mouse and offers Resume, Options (volume, mouse
## sensitivity, fullscreen) and Quit. ESC again goes back, or resumes. It keeps running while the
## tree is paused (process mode "always") and owns the mouse capture state while open.

@onready var _main_panel: Control = %MainPanel
@onready var _options_panel: Control = %OptionsPanel
@onready var _resume_button: Button = %ResumeButton
@onready var _options_button: Button = %OptionsButton
@onready var _quit_button: Button = %QuitButton
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
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if not get_tree().paused:
		pause()
	elif _options_panel.visible:
		_show_options(false)
	else:
		resume()


func pause() -> void:
	get_tree().paused = true
	visible = true
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


func _on_volume_changed(value: float) -> void:
	GameSettings.master_volume = value
	GameSettings.apply()


func _on_sensitivity_changed(value: float) -> void:
	GameSettings.mouse_sensitivity_scale = value


func _on_fullscreen_toggled(pressed: bool) -> void:
	GameSettings.fullscreen = pressed
	GameSettings.apply()
