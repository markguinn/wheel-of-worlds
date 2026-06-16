shader_type canvas_item;

uniform float speed = 1.0;
uniform float width = 3.0;
uniform float depth = 0.1;
uniform int revs = 2;
uniform vec4 tint : source_color = vec4(1.0);
uniform float fade_start = 1.0;
uniform float fade_end = 1.0;

void fragment() {
	vec2 uv = vec2(
		UV.x, 
		UV.y - abs(sin(TIME * speed + UV.x * width)) * depth
	);
	if (uv.y >= 0.0) {
    	COLOR = texture(TEXTURE, uv) * tint;
		COLOR.a *= (1.0 - smoothstep(fade_start, fade_end, uv.y));
	} else {
		COLOR = vec4(1.0, 1.0, 1.0, 0.0);
	}
	//COLOR.g = 0.0;
	//COLOR.b = 0.0;
	//COLOR = vec4(1.0);
}
