shader_type sky;
// The island's night sky: a deep navy gradient with a lighter band at the horizon, a moon disc with a soft halo
// along the first directional light (the Moon, so turning the light moves the moon), and sparse hashed stars.
// Every number is a uniform set by IslandLook from NightStats.

uniform vec4 zenith_color : source_color = vec4(0.015, 0.03, 0.09, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.1, 0.15, 0.28, 1.0);
uniform float horizon_band = 0.35;
uniform vec4 moon_disc_color : source_color = vec4(0.92, 0.95, 1.0, 1.0);
// Cosine of the disc's angular radius.
uniform float moon_disc_cos = 0.99966;
uniform float moon_halo = 0.25;
uniform float moon_halo_tightness = 60.0;
uniform float star_density = 0.04;
uniform float star_grid = 140.0;
uniform float star_size = 0.12;
uniform float star_brightness = 0.8;
uniform float star_fade = 0.15;

float hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

// 1 at a star's centre, fading to 0 at its edge. Stars sit at a jittered point in sky cells of size 1 / star_grid.
float stars(vec3 dir) {
	vec3 q = dir * star_grid;
	vec3 cell = floor(q);
	if (hash31(cell) > star_density) {
		return 0.0;
	}
	vec3 centre = cell + 0.25 + 0.5 * vec3(hash31(cell + 17.0), hash31(cell + 41.0), hash31(cell + 73.0));
	float d = length(q - centre);
	float twinkle = 0.6 + 0.4 * hash31(cell + 5.0);
	return (1.0 - smoothstep(star_size * 0.3, star_size, d)) * twinkle;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float up = max(dir.y, 0.0);
	vec3 colour = mix(horizon_color.rgb, zenith_color.rgb, smoothstep(0.0, max(horizon_band, 0.001), up));

	colour += vec3(star_brightness) * stars(dir) * smoothstep(0.0, max(star_fade, 0.001), up);

	if (LIGHT0_ENABLED) {
		float facing = dot(dir, LIGHT0_DIRECTION);
		colour += moon_disc_color.rgb * moon_halo * pow(max(facing, 0.0), moon_halo_tightness);
		float edge = (1.0 - moon_disc_cos) * 0.15;
		float disc = smoothstep(moon_disc_cos - edge, moon_disc_cos + edge, facing);
		colour = mix(colour, moon_disc_color.rgb, disc);
	}
	COLOR = colour;
}
