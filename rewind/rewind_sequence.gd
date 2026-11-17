class_name RewindSequence
extends Node
## The timing of a rewind, all in real time: time slows from the death to a standstill (`slow_seconds`), the tree
## pauses and the trip back plays (`reverse_seconds`, slow at both ends, fastest in the middle), then the tree runs again
## and time speeds back up to normal (`resume_seconds`). It owns `Engine.time_scale` while it runs, the screen effect
## and the rushing sound. It knows nothing about snapshots: `Rewind` (its parent) listens and does the posing.
## Runs while the tree is paused, and after everything else each frame, so its time scale wins over a bullet time
## still easing out.

## Time stands still and the tree is paused: the trip back begins.
signal stopped
## How far the trip back has got: 0 at the death, 1 at the saved moment. Every frame of the trip back.
signal progressed(weight: float)
## At the saved moment. The tree runs again right after this.
signal arrived

enum Phase { IDLE, SLOWING, REVERSING, RESUMING }

## The slowest time scale while time is stopped or starting again (0 would freeze bodies mid-step).
const MIN_SCALE: float = 0.02
## The rushing sound's pitch at standstill and at the fastest point of the trip back.
const PITCH_SLOW: float = 0.5
const PITCH_FAST: float = 2.2

static var _rush_sound: AudioStreamWAV

var stats: RewindStats

var _phase: Phase = Phase.IDLE
var _elapsed: float = 0.0
var _start_scale: float = 1.0
var _last_usec: int = 0
var _screen: RewindScreen
var _sound: AudioStreamPlayer


func setup(rewind_stats: RewindStats) -> void:
	stats = rewind_stats


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1000
	_screen = RewindScreen.new()
	add_child(_screen)
	if _rush_sound == null:
		_rush_sound = Synth.make_loop(1.0, 70.0, 0.75, 0.6)
	_sound = AudioStreamPlayer.new()
	_sound.stream = _rush_sound
	add_child(_sound)


func is_running() -> bool:
	return _phase != Phase.IDLE


## Starts from the death: time slows from where it is now (a bullet time may have it slow already).
func play() -> void:
	_start_scale = clampf(Engine.time_scale, MIN_SCALE, 1.0)
	_last_usec = Time.get_ticks_usec()
	_enter(Phase.SLOWING)


func _process(_delta: float) -> void:
	if _phase == Phase.IDLE:
		return
	var now: int = Time.get_ticks_usec()
	_elapsed += minf(float(now - _last_usec) / 1.0e6, 0.1)
	_last_usec = now
	match _phase:
		Phase.SLOWING:
			var u: float = _progress(stats.slow_seconds)
			var scale: float = lerpf(_start_scale, MIN_SCALE, smoothstep(0.0, 1.0, u))
			Engine.time_scale = scale
			AudioServer.playback_speed_scale = maxf(scale, 0.3)
			_screen.set_strength(u * stats.screen_strength)
			if u >= 1.0:
				Engine.time_scale = 1.0
				AudioServer.playback_speed_scale = 1.0
				get_tree().paused = true
				_enter(Phase.REVERSING)
				_sound.volume_db = stats.sound_volume_db
				_sound.pitch_scale = PITCH_SLOW
				_sound.play()
				stopped.emit()
		Phase.REVERSING:
			var u: float = _progress(stats.reverse_seconds)
			progressed.emit(_ease(u))
			_screen.set_strength(stats.screen_strength)
			_sound.pitch_scale = lerpf(PITCH_SLOW, PITCH_FAST, _speed(u))
			if u >= 1.0:
				_sound.stop()
				arrived.emit()
				get_tree().paused = false
				Engine.time_scale = MIN_SCALE
				_enter(Phase.RESUMING)
		Phase.RESUMING:
			var u: float = _progress(stats.resume_seconds)
			Engine.time_scale = lerpf(MIN_SCALE, 1.0, smoothstep(0.0, 1.0, u))
			_screen.set_strength((1.0 - u) * stats.screen_strength)
			if u >= 1.0:
				_stop()


func _exit_tree() -> void:
	if _phase != Phase.IDLE:
		_stop()
		get_tree().paused = false


func _enter(phase: Phase) -> void:
	_phase = phase
	_elapsed = 0.0


## 0 to 1 through the current phase. A phase of no length is over at once.
func _progress(seconds: float) -> float:
	return clampf(_elapsed / seconds, 0.0, 1.0) if seconds > 0.0 else 1.0


## The trip back's position for 0 to 1 of its time: an ease in and out shaped by `reverse_ease`.
func _ease(u: float) -> float:
	var p: float = maxf(stats.reverse_ease, 1.0)
	if u < 0.5:
		return 0.5 * pow(2.0 * u, p)
	return 1.0 - 0.5 * pow(2.0 - 2.0 * u, p)


## The trip back's speed at `u`, 0 at a standstill and 1 at its fastest (the middle).
func _speed(u: float) -> float:
	return pow(1.0 - absf(2.0 * u - 1.0), maxf(stats.reverse_ease, 1.0) - 1.0)


func _stop() -> void:
	_phase = Phase.IDLE
	Engine.time_scale = 1.0
	AudioServer.playback_speed_scale = 1.0
	_screen.set_strength(0.0)
	_sound.stop()
