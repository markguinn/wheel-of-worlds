shader_type canvas_item;
render_mode world_vertex_coords;  // Defers the model-view transformation until after the vertex shader code runs
varying vec2 world_pos;  // Use vec3 instead for 3d shaders

uniform vec4 target : source_color;
uniform vec4 base_color : source_color;
uniform sampler2D patterns[8] : source_color;
uniform float offsets[8];
uniform float scales[8];
uniform float opacities[8];
uniform float margin = 500.0;
uniform float pattern_size = 2048.0;
uniform float overall_scale = 0.3;

void vertex() {
    world_pos = VERTEX;
	//VERTEX += vec2(cos(TIME)*100.0, sin(TIME)*100.0);
}

vec4 get_sample(sampler2D tex, float offset, float _scale) {
	float scale = _scale * overall_scale;
	float size = pattern_size;
	float mg = margin;
	float m = mg / size;
	float m2 = m + m;
	float m3 = 1.0 - m;
	float m4 = 1.0 - m2;
	vec2 tp = vec2(
		(mod((world_pos.x + offset) / scale, size - mg - mg) + mg) / size,
		(mod((world_pos.y + offset) / scale, size - mg - mg) + mg) / size
	);
	vec4 c = textureLod(tex, tp, 0.0);
	// TODO: can we do this with step or smoothstep? is it even faster?
	if (tp.x < m2) {
		float mx = (tp.x - m) / m;
		vec4 c2 = textureLod(tex, vec2(m4 + tp.x, tp.y), 0.0);
		//vec4 c2 = vec4(1.0, 0., 0., 1.);// textureLod(tex, vec2(1.0 - tp.x, tp.y), 0.0);
		c = mix(c2, c, mx);
	}
	if (tp.y > m4) {
		float mx = (m3 - tp.y) / m;
		vec4 c2 = textureLod(tex, vec2(tp.x, tp.y - m4), 0.0);
		//vec4 c2 = vec4(1.0, 0., 0., 1.);// textureLod(tex, vec2(1.0 - tp.x, tp.y), 0.0);
		c = mix(c2, c, mx);
	}
	//if (tp.y < m2) {
		//float mx = (tp.y - m) / m;
		//vec4 c2 = textureLod(tex, vec2(tp.x, m4 + tp.y), 0.0);
		////vec4 c2 = vec4(1.0, 0., 0., 1.);// textureLod(tex, vec2(1.0 - tp.x, tp.y), 0.0);
		//c = mix(c2, c, mx);
	//}
	return c; 
}

vec4 add_layer(vec4 c, sampler2D tex, float offset, float scale, float opacity) {
	vec4 c2 = get_sample(tex, offset, scale);
	return mix(c, vec4(c2.rgb, 1.0), c2.a * opacity);
}

void fragment() {
	//vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	//COLOR = (COLOR + c) / 2.0;
	//vec4 up = texture(TEXTURE, UV - vec2(0.0, 0.001));
	if (distance(COLOR, target) < 0.05) {
		COLOR = base_color;
		for (int i = 0; i < 8; i++) {
			COLOR = add_layer(COLOR, patterns[i], offsets[i], scales[i], opacities[i]);
		}
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
