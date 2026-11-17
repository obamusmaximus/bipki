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


## A punchy metallic "ka-ching": a short noisy knock ("ka"), then after `delay` seconds a bright ring of
## inharmonic partials above `ring_hz` that dies away ("ching"). The higher partials fade faster, like struck metal.
static func make_clang(duration: float, ring_hz: float, delay: float, volume: float) -> AudioStreamWAV:
	var ratios: PackedFloat32Array = PackedFloat32Array([1.0, 1.51, 2.76, 4.07, 5.40])
	var gains: PackedFloat32Array = PackedFloat32Array([0.5, 0.35, 0.3, 0.18, 0.12])
	var count: int = int(duration * MIX_RATE)
	var delay_samples: int = int(delay * MIX_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)

	var smoothed: float = 0.0
	for i in count:
		var t: float = float(i) / MIX_RATE
		# Ka: a sharp knock of band-limited noise over a low thump, gone in a few hundredths of a second.
		smoothed = lerpf(smoothed, randf_range(-1.0, 1.0), 0.5)
		var knock: float = (smoothed * 1.4 + sin(TAU * 140.0 * t) * 0.8) * exp(-t * 90.0)
		# Ching: the ring starts after the knock, with a tiny attack so it doesn't click.
		var ring: float = 0.0
		if i >= delay_samples:
			var rt: float = float(i - delay_samples) / MIX_RATE
			var attack: float = minf(rt / 0.002, 1.0)
			for p: int in ratios.size():
				var hz: float = ring_hz * ratios[p]
				ring += sin(TAU * hz * rt) * gains[p] * exp(-rt * (5.0 + 4.0 * p))
			ring *= attack
		var sample: float = (knock + ring) * volume
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream


## A seamlessly looping mono rumble for engines and rockets: a bass tone (`bass_hz`, plus its octave at half strength)
## under deep low-passed noise, its loudness wobbling slowly so it churns instead of droning. `noise_amount`: 0 = pure
## bass tone, 1 = pure rumbling noise. Peaks are normalised to `volume`, so it never clips.
static func make_rumble(duration: float, bass_hz: float, noise_amount: float, volume: float) -> AudioStreamWAV:
	var count: int = int(duration * MIX_RATE)
	var cycles: float = maxf(1.0, roundf(bass_hz * duration))
	var fade_samples: float = maxf(0.02 * MIX_RATE, 1.0)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var deep: float = 0.0
	var wobble: float = 0.0
	var peak: float = 0.0001
	for i in count:
		deep = lerpf(deep, randf_range(-1.0, 1.0), 0.02) # Heavy one-pole low-pass: only the low end is left.
		wobble = lerpf(wobble, randf_range(-1.0, 1.0), 0.0005)
		var phase: float = TAU * cycles * i / count
		var tone: float = sin(phase) + 0.5 * sin(phase * 2.0)
		var edge: float = minf(1.0, minf(i / fade_samples, (count - i) / fade_samples))
		var sample: float = lerpf(tone, deep * 8.0, noise_amount) * (1.0 + 0.6 * wobble * 8.0) * edge
		samples[i] = sample
		peak = maxf(peak, absf(sample))
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		data.encode_s16(i * 2, int(clampf(samples[i] / peak * volume, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream
