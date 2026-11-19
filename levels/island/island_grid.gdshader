shader_type spatial;
render_mode cull_back;
// The island's walkable top and cliffs: the arena's grid (grid.gdshaderinc) seen from outside and lit, so the
// moonlight and shadows fall on it. The island spans 0 to 100 m in x and z, so the scale bars land in its middle.

#include "res://levels/arena/grid.gdshaderinc"

varying vec3 world_pos;
varying vec3 face;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	face = abs(NORMAL);
}

void fragment() {
	ALBEDO = grid_colour(world_pos, face);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
