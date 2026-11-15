class_name BulletTime
extends Node
## Slows the whole world down and brings it back, by scaling game time (`Engine.time_scale`). Godot keeps ticking
## physics at the normal rate and scales the step, so slow motion is smooth, not a few choppy ticks a second.
## (Anything timing itself in real seconds divides its physics delta by the time scale.) The mouse look, which
## reads input events, and the HUD stay real time. The slow-down eases in and out. Audio slows and muffles with it.
## Restores everything when freed.

var _engaged: bool = false
var _target: float = 1.0
var _current: float = 1.0
## The slowest scale of this bullet time, to measure how deep into it we are.
var _depth_scale: float = 1.0
var _ease_seconds: float = 0.12
var _audio_speed: float = 1.0
var _lowpass: AudioEffectLowPassFilter
var _last_usec: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_engaged() -> bool:
	return _engaged


## Starts slowing to `time_scale`, taking `ease_seconds` of real time. `audio_speed` is the audio playback speed at the bottom.
func enter(time_scale: float, ease_seconds: float, audio_speed: float) -> void:
	if not _engaged:
		_engaged = true
		_current = 1.0
		_last_usec = Time.get_ticks_usec()
		_lowpass = AudioEffectLowPassFilter.new()
		AudioServer.add_bus_effect(0, _lowpass)
	_target = time_scale
	_depth_scale = time_scale
	_ease_seconds = maxf(ease_seconds, 0.01)
	_audio_speed = audio_speed


## Starts returning to normal speed. Everything is restored once the ease finishes.
func exit(ease_seconds: float) -> void:
	_target = 1.0
	_ease_seconds = maxf(ease_seconds, 0.01)


func _process(_delta: float) -> void:
	if not _engaged:
		return
	var now: int = Time.get_ticks_usec()
	var real_delta: float = minf(float(now - _last_usec) / 1.0e6, 0.1)
	_last_usec = now
	var rate: float = maxf(1.0 - _depth_scale, 0.01) / _ease_seconds
	_current = move_toward(_current, _target, rate * real_delta)
	_apply()
	if _current >= 1.0 and _target >= 1.0:
		_restore()


func _exit_tree() -> void:
	if _engaged:
		_restore()


func _apply() -> void:
	Engine.time_scale = _current
	var depth: float = clampf((1.0 - _current) / maxf(1.0 - _depth_scale, 0.01), 0.0, 1.0)
	AudioServer.playback_speed_scale = lerpf(1.0, _audio_speed, depth)
	_lowpass.cutoff_hz = lerpf(20000.0, 1400.0, depth)


func _restore() -> void:
	_engaged = false
	_current = 1.0
	Engine.time_scale = 1.0
	AudioServer.playback_speed_scale = 1.0
	for i: int in AudioServer.get_bus_effect_count(0):
		if AudioServer.get_bus_effect(0, i) == _lowpass:
			AudioServer.remove_bus_effect(0, i)
			break
