shader_type canvas_item;
render_mode world_vertex_coords, unshaded;  // Defers the model-view transformation until after the vertex shader code runs
varying vec2 world_pos;  // Use vec3 instead for 3d shaders

uniform vec4 target : source_color;
uniform vec4 base_color : source_color;
uniform sampler2D patterns[2] : source_color;
uniform float offsets[8];
uniform float scales[8];
uniform float opacities[8];
uniform float margin = 500.0;
uniform float pattern_size = 2048.0;
uniform float overall_scale = 0.3;
uniform float edge_size = 100.0;
uniform vec2 real_screen_size;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform sampler2D[4] edges : source_color;
uniform vec2[4] dirs;

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

vec4 add_edges(vec4 c, vec2 suv, vec2 tps) {
	int min_dir = -1;
	float min_len = 100000.0;
	vec2 min_uv;
	
	float mult = 3.0;
	
	for (int di = 0; di < 4; di++) {
		float st = length(tps * dirs[di]);
		float es = edge_size * length(tps * dirs[di]) * mult;
		float edge_len = es * 2.0;
		for (float i = es; i > 0.0; i -= st) {
			vec4 test_point = textureLod(screen_texture, suv + dirs[di] * i, 0.0);
			if (test_point.a > 0.001) {
				edge_len = i;
				break;
			}
		}
		if (edge_len < es && edge_len < min_len) {
			min_len = edge_len;
			min_dir = di;
			min_uv = dirs[di] * (edge_len / es);
		}
	}
	if (min_dir >= 0) {
		float tw = 1000.0;
		vec2 dir = dirs[min_dir];
		if (min_uv.x == 0.0) {
			min_uv.x = mod(world_pos.x * mult, tw) / tw;
			min_uv.y = min_uv.y < 0.0 ? abs(min_uv.y) : 1.0 - min_uv.y;
		} else {
			min_uv.y = mod(world_pos.y * mult, tw) / tw;
			min_uv.x = min_uv.x < 0.0 ? abs(min_uv.x) : 1.0 - min_uv.x;
		}
		vec4 c2 = textureLod(edges[min_dir], min_uv, 0.0);
		return mix(c, vec4(c2.rgb, 1.0), c2.a);
	}
	return c;
}

void fragment() {
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	if (distance(c, target) < 0.1) {
		COLOR = base_color;
		for (int i = 0; i < 2; i++) {
			COLOR = add_layer(COLOR, patterns[i], offsets[i], scales[i], opacities[i]);
		}
		COLOR = add_edges(COLOR, SCREEN_UV, SCREEN_PIXEL_SIZE);
	}
	if (c.a > 0.0001) {
		c.rgb /= c.a;
	}
	COLOR *= c;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
