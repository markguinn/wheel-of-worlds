shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D top : source_color;
uniform sampler2D bottom : source_color;
uniform sampler2D left : source_color;
uniform sampler2D right : source_color;
uniform sampler2D pattern : source_color;
uniform vec4 target : source_color;

void fragment() {
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	if (c.a > 0.0001) {
		c.rgb /= c.a;
	}
	//if (distance(c, target) < 0.05) {
		//c = textureLod(pattern, SCREEN_UV, 0.0);
	//}
	COLOR *= c;
}
