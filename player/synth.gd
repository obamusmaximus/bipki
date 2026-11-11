class_name Synth
extends RefCounted
## Builds short sound effects in code as AudioStreamWAV, so no audio files are needed.

const MIX_RATE: int = 22050


## One mono sound: a tone sweeping from start_hz to end_hz, mixed with white noise.
## noise_amount: 0 = pure tone, 1 = pure noise.
## attack: seconds to ramp up from silence. curve: decay exponent (higher = shorter tail).
static func make_sound(duration: float, start_hz: float, end_hz: float, noise_amount: float, volume: float, attack: float = 0.005, curve: float = 2.0) -> AudioStreamWAV:
	var count: int = int(duration * MIX_RATE)
	var attack_samples: float = maxf(attack * MIX_RATE, 1.0)
	var data := PackedByteArray()
	data.resize(count * 2)

	var phase: float = 0.0
	for i in count:
		var t: float = float(i) / count
		phase += TAU * lerpf(start_hz, end_hz, t) / MIX_RATE
		var env: float = minf(1.0, i / attack_samples) * pow(1.0 - t, curve)
		var tone: float = sin(phase)
		var noise: float = randf_range(-1.0, 1.0)
		var sample: float = lerpf(tone, noise, noise_amount) * env * volume
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream


## A seamlessly looping mono sound: a steady tone mixed with low-passed noise (a rushing hum).
## The tone uses a whole number of cycles per loop, and the ends fade briefly so the loop point doesn't click.
static func make_loop(duration: float, tone_hz: float, noise_amount: float, volume: float) -> AudioStreamWAV:
	var count: int = int(duration * MIX_RATE)
	var cycles: float = maxf(1.0, roundf(tone_hz * duration))
	var fade_samples: float = maxf(0.02 * MIX_RATE, 1.0)
	var data := PackedByteArray()
	data.resize(count * 2)

	var smoothed: float = 0.0
	for i in count:
		smoothed = lerpf(smoothed, randf_range(-1.0, 1.0), 0.15) # One-pole low-pass on the noise.
		var tone: float = sin(TAU * cycles * i / count)
		var edge: float = minf(1.0, minf(i / fade_samples, (count - i) / fade_samples))
		var sample: float = lerpf(tone, smoothed * 4.0, noise_amount) * edge * volume
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream
