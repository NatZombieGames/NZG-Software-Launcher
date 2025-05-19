shader_type canvas_item;

// Taken from https://godotshaders.com/shader/rotate-texture/ but changed it to take a constant rotation.

uniform float rot : hint_range(0.0, 1.0, 0.01) = 1.0;

vec2 rotate(vec2 uv, vec2 pivot, float angle) {
	uv -= pivot;
	uv = uv * mat2(vec2(sin(angle), -cos(angle)), vec2(cos(angle), sin(angle)));
	uv += pivot;
	return uv;
}

void fragment() {
	COLOR = texture(TEXTURE, rotate(UV, vec2(0.5), 6.3 * rot));
}