shader_type canvas_item;
render_mode unshaded;

uniform float progress : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float start_y_position : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float end_y_position : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform vec3 unshaded_colour = vec3(1, 1, 1);
uniform vec3 shaded_colour = vec3(0.5, 0.5, 0.5);

void fragment() {
	UV.y >= start_y_position || UV.y <= end_y_position ?
		COLOR.a = 0.0 :
		COLOR.a = COLOR.a;
	UV.y <= start_y_position + ((end_y_position - start_y_position) * progress) ? COLOR.rgb = shaded_colour : COLOR.rgb = unshaded_colour;
}