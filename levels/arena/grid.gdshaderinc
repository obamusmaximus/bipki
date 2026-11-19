// Grid math shared by the arena's inside-box shader (grid.gdshader) and the island's lit top (island_grid.gdshader).
// White walls with a very fine noise and black grid bars, computed from the world position, so bars stay straight and
// a constant width on any surface. The world origin is a corner of the 100 m grid area (ROOM), and the central scale
// bars sit at CENTRE on every axis. Parameters are set by GridLook from ArenaStats.
//
// Bars: bold every `major_spacing`, thin every `minor_spacing`. The two central bars of each surface (at 50 m) are
// scale bars: thicker, with a notch across them every metre, bigger at every `minor_spacing` and biggest at every
// `major_spacing`. Within `clear_band` metres of a central bar the grid bars crossing it and the thin bars beside it
// are left out, which makes a clear strip for the notches and the number labels (ArenaScale).

const float ROOM = 100.0;
const float CENTRE = 50.0;

uniform vec4 wall_color : source_color = vec4(0.97, 0.97, 0.96, 1.0);
uniform float noise_scale = 0.15;
uniform float noise_strength = 0.03;
uniform float grain_strength = 0.015;
uniform float corner_shade = 0.21;
uniform float corner_shade_range = 7.2;

uniform vec4 bar_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float major_spacing = 10.0;
uniform float minor_spacing = 5.0;
uniform float major_width = 0.15;
uniform float minor_width = 0.06;
uniform float central_width = 0.29;
uniform float notch_width = 0.06;
uniform float notch_width_mid = 0.08;
uniform float notch_width_long = 0.13;
uniform float notch_length = 0.51;
uniform float notch_length_mid = 1.0;
uniform float notch_length_long = 1.6;
uniform float notch_clear = 3.5;
uniform float clear_band = 4.9;

float hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float value_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float x00 = mix(hash31(i), hash31(i + vec3(1.0, 0.0, 0.0)), f.x);
	float x10 = mix(hash31(i + vec3(0.0, 1.0, 0.0)), hash31(i + vec3(1.0, 1.0, 0.0)), f.x);
	float x01 = mix(hash31(i + vec3(0.0, 0.0, 1.0)), hash31(i + vec3(1.0, 0.0, 1.0)), f.x);
	float x11 = mix(hash31(i + vec3(0.0, 1.0, 1.0)), hash31(i + vec3(1.0, 1.0, 1.0)), f.x);
	return mix(mix(x00, x10, f.y), mix(x01, x11, f.y), f.z);
}

// Fades a noise octave out once its cells get smaller than a pixel, so it doesn't shimmer at a distance.
float octave_fade(float cell, float metres_per_pixel) {
	return 1.0 - smoothstep(cell * 0.25, cell * 0.75, metres_per_pixel);
}

// 1 on a bar, 0 off it, anti-aliased. `d` is the distance to the bar's centre, `fw` the metres per pixel.
float coverage(float d, float fw, float width) {
	float half_width = max(width * 0.5, fw * 0.5);
	return clamp((half_width - d) / fw + 0.5, 0.0, 1.0);
}

// The wall colour with the grid and scale bars at world position `p`, on a surface whose normal is `face` (abs value).
vec3 grid_colour(vec3 p, vec3 face) {
	vec3 fw = max(fwidth(p), vec3(0.0001));
	float pixel = max(fw.x, max(fw.y, fw.z));
	vec3 along = 1.0 - step(0.5, face); // 1 on the two axes that lie in this surface

	// Wall texture: two octaves of value noise and a fine grain.
	float cell = max(noise_scale, 0.01);
	float f1 = octave_fade(cell, pixel);
	float f2 = octave_fade(cell / 2.7, pixel);
	float n = 0.6 * value_noise(p / cell) + 0.4 * f2 * value_noise(p / (cell / 2.7));
	n = n / (0.6 + 0.4 * f2);
	float grain = hash31(floor(p * 40.0)) * (1.0 - smoothstep(0.01, 0.05, pixel));
	vec3 colour = wall_color.rgb * (1.0 + noise_strength * (n - 0.5) * 2.0 * f1 + grain_strength * (grain - 0.5) * 2.0);

	// Darker toward the edges where surfaces meet, a cheap stand-in for ambient occlusion.
	float edge_distance = 1.0e6;
	for (int i = 0; i < 3; i++) {
		if (along[i] > 0.5) {
			edge_distance = min(edge_distance, min(p[i], ROOM - p[i]));
		}
	}
	colour *= 1.0 - corner_shade * (1.0 - smoothstep(0.0, max(corner_shade_range, 0.01), edge_distance));

	// Bars.
	float bars = 0.0;
	for (int i = 0; i < 3; i++) {
		if (along[i] < 0.5) {
			continue;
		}
		float minor_d = abs(p[i] - minor_spacing * round(p[i] / minor_spacing));
		float major_d = abs(p[i] - major_spacing * round(p[i] / major_spacing));
		float minor_bar = coverage(minor_d, fw[i], minor_width);
		// The thin bars beside a central bar are left out.
		if (abs(abs(p[i] - CENTRE) - clear_band) < minor_spacing * 0.25) {
			minor_bar = 0.0;
		}
		// Inside the strip of a central bar the crossing bars are left out; the notches take over there.
		float in_strip = 0.0;
		for (int j = 0; j < 3; j++) {
			if (j != i && along[j] > 0.5) {
				in_strip = max(in_strip, 1.0 - step(clear_band, abs(p[j] - CENTRE)));
			}
		}
		bars = max(bars, (1.0 - in_strip) * max(minor_bar, coverage(major_d, fw[i], major_width)));
		// A central bar (the line at 50 m on this axis) runs along the other in-surface axis.
		bars = max(bars, coverage(abs(p[i] - CENTRE), fw[i], central_width));

		// Notches across the central bar that runs along axis j: every metre, bigger every minor step, biggest
		// every major step. Left out right at the crossing, to leave room for its labels.
		// Only pixels within reach of the central bar can be on a notch, so everything else skips the loop.
		if (abs(p[i] - CENTRE) > notch_length_long + fw[i]) {
			continue;
		}
		for (int j = 0; j < 3; j++) {
			if (j == i || along[j] < 0.5) {
				continue;
			}
			// The bar along j sits at p[i] == CENTRE; its notches are at whole metres of p[j].
			float at = round(p[j]);
			if (at < 0.5 || at > ROOM - 0.5 || abs(at - CENTRE) < notch_clear) {
				continue;
			}
			bool is_major = abs(at - major_spacing * round(at / major_spacing)) < 0.01;
			bool is_mid = abs(at - minor_spacing * round(at / minor_spacing)) < 0.01;
			float length = is_major ? notch_length_long : (is_mid ? notch_length_mid : notch_length);
			float width = is_major ? notch_width_long : (is_mid ? notch_width_mid : notch_width);
			float across = clamp((length - abs(p[i] - CENTRE)) / fw[i] + 0.5, 0.0, 1.0);
			bars = max(bars, across * coverage(abs(p[j] - at), fw[j], width));
		}
	}

	return mix(colour, bar_color.rgb, bars * bar_color.a);
}
