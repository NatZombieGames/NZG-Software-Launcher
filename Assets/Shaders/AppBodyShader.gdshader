shader_type canvas_item;

uniform sampler2D icon;
uniform float scroll_progress : hint_range(0.0, 1.0, 0.0005) = 0.0;

void fragment() {
	vec4 icon_texture = texture(icon, vec2(UV.x, UV.y + scroll_progress));
	COLOR = icon_texture;
	//icon_texture.r *= 0.25;
	//icon_texture.g *= 0.25;
	//icon_texture.b *= 0.25;
	//COLOR = mix(icon_texture, vec4(0, 0, 0, 0), scroll_progress);
}
