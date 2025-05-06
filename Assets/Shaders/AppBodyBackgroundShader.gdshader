shader_type canvas_item;

uniform float scroll_progress : hint_range(0.0, 1.0, 0.005) = 0.0;

void fragment() {
	COLOR = texture(TEXTURE, vec2(UV.x, UV.y + (scroll_progress / 2.0)));
	COLOR *= 0.9 - scroll_progress;
	UV.y >= 1.0 - (scroll_progress / 2.0) ? COLOR = vec4(0) : COLOR = COLOR;
}
