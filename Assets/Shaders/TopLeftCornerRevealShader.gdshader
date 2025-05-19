shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	if (UV.y > progress || UV.x > progress) {
		COLOR.a = 0.0;
	}
}