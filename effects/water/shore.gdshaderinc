// Distance to the island and what depends on it. The island is a rectangle, so the distance comes from a box
// distance function on `island_rect` (min x, min z, max x, max z), set by WaterLook from the island's collision box.
// No depth texture is needed. Anything else standing in the water (a rock) gets nothing unless it's added here.

uniform vec4 island_rect = vec4(0.0, 0.0, 100.0, 100.0);
uniform float calm_begin = 150.0;
uniform float calm_end = 400.0;
uniform float foam_width = 5.0;
uniform float shore_calm_reach = 25.0;
uniform float shore_calm_level = 0.35;

// Signed distance (m) from world point `p` (x, z) to the island's edge: negative inside.
float island_distance(vec2 p) {
	vec2 centre = (island_rect.xy + island_rect.zw) * 0.5;
	vec2 half_size = (island_rect.zw - island_rect.xy) * 0.5;
	vec2 q = abs(p - centre) - half_size;
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0);
}

// The share of the wave height at `distance_m` from the cliffs: falling to 0 (flat water) between `calm_begin` and
// `calm_end`, so the far water doesn't shimmer, and damped to `shore_calm_level` within `shore_calm_reach` of the
// cliffs, as if the shore broke the waves.
float wave_scale(float distance_m) {
	float far_calm = 1.0 - smoothstep(calm_begin, max(calm_end, calm_begin + 0.01), distance_m);
	float shore_calm = mix(shore_calm_level, 1.0, smoothstep(0.0, max(shore_calm_reach, 0.01), distance_m));
	return far_calm * shore_calm;
}

// The shore factor: 1 at the cliffs, falling straight to 0 at `foam_width` out (m). What the foam is cut from.
float shore_factor(float distance_m) {
	return 1.0 - clamp(distance_m / max(foam_width, 0.01), 0.0, 1.0);
}
