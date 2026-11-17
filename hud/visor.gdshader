// The helmet-visor look for the HUD's edge groups. The flat HUD is treated as painted on the inside of a curved
// visor (wrapping `curve_x` radians to each side and `curve_y` up and down) and seen through a pinhole at the eye.
// Away from the middle it stretches outward, and a panel's outer side grows taller than its inner side, so corner
// panels look turned toward the player. The screen corners stay put, so nothing anchored to an edge leaves the screen.
//
// Forward map, flat HUD (u, v in -1..1) to screen (x, y in -1..1):
//   x = tan(u * ax) / tan(ax) * cos(ay) / cos(v * ay)
//   y = tan(v * ay) / tan(ay) * cos(ax) / cos(u * ax)
// The shader needs the inverse (which HUD pixel lands here?), found by a few rounds of fixed-point iteration.
// The viewport texture holds premultiplied colour (it is drawn over a transparent clear), hence blend_premul_alpha.
shader_type canvas_item;
render_mode blend_premul_alpha;

uniform float curve_x = 0.0;
uniform float curve_y = 0.0;

const int ROUNDS = 4;
const float FLAT = 0.0001;

// HUD coordinate along one axis for screen coordinate `s`, given the other axis's cosine factor `other`.
float unwarp(float s, float curve, float other) {
	if (curve < FLAT) {
		return s * other;
	}
	return atan(s * tan(curve) * other) / curve;
}

void fragment() {
	vec2 screen = UV * 2.0 - 1.0;
	vec2 hud = screen;
	float cos_x = cos(curve_x);
	float cos_y = cos(curve_y);
	for (int i = 0; i < ROUNDS; i++) {
		float u = unwarp(screen.x, curve_x, cos(hud.y * curve_y) / cos_y);
		float v = unwarp(screen.y, curve_y, cos(hud.x * curve_x) / cos_x);
		hud = vec2(u, v);
	}
	vec2 source = hud * 0.5 + 0.5;
	if (any(lessThan(source, vec2(0.0))) || any(greaterThan(source, vec2(1.0)))) {
		COLOR = vec4(0.0);
	} else {
		COLOR = texture(TEXTURE, source);
	}
}
