shader_type canvas_item;

uniform float speed = 1.0;
uniform float width = 3.0;
uniform float depth = 0.1;
uniform int revs = 2;

void fragment() {
	vec2 uv = vec2(
		UV.x, 
		clamp(UV.y - abs(sin(TIME * speed + UV.x * width)) * depth, 0.0, 1.0)
	);
    COLOR = texture(TEXTURE, uv);
	//COLOR.g = 0.0;
	//COLOR.b = 0.0;
	//COLOR = vec4(1.0);
}
