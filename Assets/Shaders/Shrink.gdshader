shader_type canvas_item;
render_mode unshaded;

uniform float scale : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float texture_size = 1.0;

void vertex() {
	VERTEX *= scale;
	VERTEX += (texture_size * 2.0) * (1.0 - scale);
}
