shader_type canvas_item;
// The rewind's look (see rewind_screen.gd). `strength` 0 leaves the picture alone, 1 is the full effect.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	// Rolling bands nudge rows sideways, like a tape being wound back.
	uv.x += sin(uv.y * 38.0 + TIME * 24.0) * 0.0025 * strength;
	float split = 0.007 * strength;
	vec3 color = vec3(
		texture(screen_texture, uv + vec2(split, 0.0)).r,
		texture(screen_texture, uv).g,
		texture(screen_texture, uv - vec2(split, 0.0)).b);
	float grey = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(color, vec3(0.55, 0.8, 1.0) * grey * 1.15, strength * 0.85);
	color *= 1.0 - strength * 0.12 * (0.5 + 0.5 * sin(SCREEN_UV.y * 900.0 - TIME * 40.0));
	vec2 from_centre = SCREEN_UV - 0.5;
	color *= 1.0 - strength * 1.2 * dot(from_centre, from_centre);
	COLOR = vec4(color, 1.0);
}
