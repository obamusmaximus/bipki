shader_type spatial;
render_mode unshaded, cull_front;
// The inside of the arena box (seen from within, unlit). The grid itself is in grid.gdshaderinc.

#include "res://levels/arena/grid.gdshaderinc"

varying vec3 world_pos;
varying vec3 face;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	face = abs(NORMAL);
}

void fragment() {
	ALBEDO = grid_colour(world_pos, face);
}
