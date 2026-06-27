shader_type canvas_item;
render_mode world_vertex_coords;
varying vec2 world_pos; 

const float edge_scale = 1.0;

// this is the color that gets replaced with the fill texture
uniform vec4 target : source_color;
// this is the color that shows behind the fill texture if there are any transparent areas
uniform vec4 base_color : source_color;
// TODO: make these structs
// these are the layers of the fill texture. we need to be careful with the number and size
// of this because the GPU has limited space for uniform inputs. so the textures need to be
// small. if you overrun this you'll start getting all white or nothing rendered at all.
uniform sampler2D patterns[4] : source_color;
// Noise functions to distort pattern layers
uniform sampler2D pattern_distortions[1];
// offset per layer. this just lets us adjust a little bit to minimize obvious tiling points
uniform float offsets[4];
// scale each layer individually (again, to minimize repitition
uniform float scales[4];
// opacity per layer to make some layers stand out less
uniform float opacities[4];
// the amount of overlap when tiling the textures
uniform float margin = 100.0;
// the size of the fill textures
uniform float pattern_size = 512.0;
// applied to all the layers on top of the individual scales
uniform float overall_scale = 0.9;
// height of the edge textures
uniform vec2 edge_size = vec2(1000.0, 100.0);
// this is injected by the container. the size of the viewport being rendered in world pixels
uniform vec2 real_screen_size;
// this is created by the CanvasGroup with the rendered tilemap
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform sampler2D[2] edges : source_color;

// A value in world space coordinate for smoothing edge texture
uniform float edge_smoothness: hint_range(0.0, 10.0) = 0.01;

uniform bool fill_enabled = true;
uniform bool edge_enabled = true;


struct EdgeCalc {
	vec4 color;
	float distance_to_edge;
	bool mix_alpha;
};

void vertex() {
	// orient ourselves in world space so the fragment shader knows where to be in the fill texture
	world_pos = VERTEX;
}

const float PI_DOUBLE = PI * 2.;
uniform float distortion_strength: hint_range(0.0, 0.25) = 1.;
uniform float distortion_size: hint_range(0.0, 100.0) = 4.;

// given a point that matched the target color, find the point in the
// given texture that corresponds to world_pos, and return it. 
vec4 get_sample(sampler2D tex, sampler2D distortion_offset, float offset, float layer_scale) {
	float scale = layer_scale * overall_scale;
	float size = pattern_size;
	float margin_px = margin;
	// these are helpers that translate the margin into uv coordinates
	float m = margin_px / size;
	float m2 = m + m;
	float m3 = 1.0 - m;
	float m4 = 1.0 - m2;
	// we take out the margin area of the texture, then mod the current world position
	// against that inner width, then bump back out to the middle of the texture and 
	// convert to uv
	float inner_size = size - margin_px * 2.0;
	float distortion_angle = texture(distortion_offset, mod(world_pos, pattern_size * distortion_size ) / (pattern_size * distortion_size)).r * PI_DOUBLE;
	vec2 tex_uv = clamp(
		vec2(
			(mod((world_pos.x + offset) / scale, inner_size) + margin_px) / size,
			(mod((world_pos.y + offset) / scale, inner_size) + margin_px) / size
		) 
		+ vec2(cos(distortion_angle), sin(distortion_angle)) * distortion_strength
		, 0.1, 0.9
	);
	// first we load up the primary point within the texture
	vec4 c = textureLod(tex, tex_uv, 0.0);
	// then if we're near the left margin we mix back in the right margin
	// originally I was doing this in both directions but that didn't look as smooth
	if (tex_uv.x < m2) {
		float mx = (tex_uv.x - m) / m;
		vec4 c2 = textureLod(tex, vec2(m4 + tex_uv.x, tex_uv.y), 0.0);
		c = mix(c2, c, mx);
	}
	// if we're near the bottom margin we mix back in the part of the texture outside the top margin
	if (tex_uv.y > m4) {
		float mx = (m3 - tex_uv.y) / m;
		vec4 c2 = textureLod(tex, vec2(tex_uv.x, tex_uv.y - m4), 0.0);
		c = mix(c2, c, mx);

		if (tex_uv.x < m2) {
			float mx2 = (tex_uv.x - m) / m;
			vec4 c2 = textureLod(tex, vec2(m4 + tex_uv.x, tex_uv.y - m4), 0.0);
			c = mix(c2, c, mx2);
		}
	}
	return c; 
}

// mix a new layer on top of the existing color
vec4 add_layer(vec4 c, sampler2D tex, sampler2D distortion, float offset, float scale, float opacity) {
	vec4 c2 = get_sample(tex, distortion, offset, scale);
	return mix(c, vec4(c2.rgb, 1.0), c2.a * opacity);
}


float get_edge_x_for_dir(vec2 dir) {
	if (dir.x == 0.0) {
		return world_pos.x;
	}
	if (dir.y == 0.0) {
		return world_pos.y;
	}
    vec2 tangent = normalize(vec2(-dir.y, dir.x));
    return dot(world_pos, tangent);
}

EdgeCalc add_edge(vec2 screen_uv, sampler2D edge_tex, vec2 dir) {
	EdgeCalc output;
	output.distance_to_edge = 1000.0;

	// this is the size within a texture uv of one unit on the global coordinate system
	vec2 global_unit_size_in_uv = 1.0 / real_screen_size;
	float uv_unit_for_dir = length(global_unit_size_in_uv * dir);
	float edge_height_in_uv = edge_size.y * uv_unit_for_dir * edge_scale;

	vec2 edge_uv;
	// I _think_ adding x and y will work here. all we really need is for each point along the
	// edge to move further along the texture at an evenish rate so it doesn't appear to repeat
	// or flip in weird ways. I suspect we might get a little bit of that right around the origin
	// but this was the first thing I thought of that seemed like it'd have the right properties
	// we can probably add an offset if needed to get away from the origin
	//vec2 world_pos_perpendicular = (max(abs(world_pos.x), abs(world_pos.y)) * vec2(dir.y, dir.x)); //world_pos * vec2(dir.y, dir.x);
	edge_uv.x = mod(get_edge_x_for_dir(dir) * edge_scale, edge_size.x) / edge_size.x;
	for (float y = edge_size.y - 1.; y >= 0.0; y--) {
		vec4 test_point = textureLod(screen_texture, screen_uv + dir * y * global_unit_size_in_uv, 0.0);
		if (test_point.a > 0.001) {
			if (y < edge_size.y) {
				output.distance_to_edge = y;
				edge_uv.y = y / edge_size.y;
			}
			break;
		} 
	}
	
	output.color = textureLod(edge_tex, edge_uv, 0.0);
	output.mix_alpha = edge_uv.y > 0.1;
	
	return output;
}

// if the given point is near the edge, add the edge texture on top of the fill texture
vec4 add_edges(vec4 c, vec2 screen_uv) {
	EdgeCalc outputs[16];
	float n = 1.0; //real_screen_size.y;
	float m = 1.0; //real_screen_size.x;
	int l = 0;
	// TODO: just go around the circle and use sin/cos so we can test more iterations
	outputs[l++] = add_edge(screen_uv, edges[0], vec2(0.0, -1.0));
	outputs[l++] = add_edge(screen_uv, edges[0], normalize(vec2(n / 2.0, -m)));
	outputs[l++] = add_edge(screen_uv, edges[0], normalize(vec2(n, -m)));
	outputs[l++] = add_edge(screen_uv, edges[0], normalize(vec2(n, -m / 2.0)));
	outputs[l++] = add_edge(screen_uv, edges[0], vec2(1.0, 0.0));
	outputs[l++] = add_edge(screen_uv, edges[0], normalize(vec2(n, m / 2.0)));
	outputs[l++] = add_edge(screen_uv, edges[0], normalize(vec2(n, m )));
	outputs[l++] = add_edge(screen_uv, edges[0], normalize(vec2(n / 2.0, m)));
	outputs[l++] = add_edge(screen_uv, edges[1], vec2(0.0, 1.0));
	outputs[l++] = add_edge(screen_uv, edges[1], normalize(vec2(-n / 2.0, m)));
	outputs[l++] = add_edge(screen_uv, edges[1], normalize(vec2(-n, m)));
	outputs[l++] = add_edge(screen_uv, edges[1], normalize(vec2(-n, m / 2.0)));
	outputs[l++] = add_edge(screen_uv, edges[1], vec2(-1.0, 0.0));
	outputs[l++] = add_edge(screen_uv, edges[1], normalize(vec2(-n, -m / 2.0)));
	outputs[l++] = add_edge(screen_uv, edges[1], normalize(vec2(-n, -m)));
	outputs[l++] = add_edge(screen_uv, edges[0], normalize(vec2(-n / 2.0, -m)));
	
	float total_diff = 0.0;
	float min_diff = 1000.0;
	float min_diff2 = 1000.0;
	int min_diff_idx = -1;
	int min_diff2_idx = -1;
	for (int i = 0; i < l; i++) {
		if (outputs[i].distance_to_edge < 1000.0) {
			total_diff += outputs[i].distance_to_edge;
		}
		if (outputs[i].distance_to_edge < min_diff) {
			min_diff2 = min_diff;
			min_diff2_idx = min_diff_idx;
			min_diff = outputs[i].distance_to_edge;
			min_diff_idx = i;
		} else if (outputs[i].distance_to_edge < min_diff2) {
			min_diff2 = outputs[i].distance_to_edge;
			min_diff2_idx = i;
		}
	}
	if (min_diff_idx >= 0 && !outputs[min_diff_idx].mix_alpha) {
		c = outputs[min_diff_idx].color;
	} else if (min_diff_idx >= 0 && min_diff2_idx >= 0) {
		float h = clamp(0.5 + 0.5*(min_diff2 - min_diff) / edge_smoothness, 0.0, 1.0);
		vec4 c2 = mix(outputs[min_diff2_idx].color, outputs[min_diff_idx].color, h);
		c = mix(c, vec4(c2.rgb, 1.0), c2.a);
	}
	//if (min_diff_idx >= 0) {
		//if (outputs[min_diff_idx].mix_alpha) {
			//vec4 c2 = outputs[min_diff_idx].color;
			////if (min_diff2_idx >= 0) {
				////float diff2_strength = min_diff2 / min_diff;
				////const float thresh = 0.9;
				////if (diff2_strength > thresh) {
					////diff2_strength = (diff2_strength - thresh) / (1.0 - thresh);
					////c2 = mix(c2, outputs[min_diff2_idx].color, diff2_strength * 0.5);
				////}
			////}
			//c = mix(c, vec4(c2.rgb, 1.0), c2.a);
		//} else {
			//c = outputs[min_diff_idx].color;
		//}
	//}
	//if (total_diff > 0.0) {
		//vec4 c2 = vec4(1.0, 1.0, 1.0, 0.0);
		//for (int i = 0; i < 8; i++) {
			//if (outputs[i].distance_to_edge == 1000.0) {
				//continue;
			//}
			//if (outputs[i].mix_alpha || i != min_diff_idx) {
				//float my_part = 1.0 - outputs[i].distance_to_edge / total_diff;
				//if (my_part >= 0.45 && my_part <= 0.55) {
					//c2 = mix(c2, outputs[i].color, my_part);
				//} else {
					//c2 = outputs[i].color; 
				//}
			//} else {
				//return outputs[i].color;
			//}
		//}
		//return mix(c, vec4(c2.rgb, 1.0), c2.a);
	//}
	return c;
}

void fragment() {
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	if (c.a > 0.001 && distance(c.rgb, target.rgb) < 2.0) {
		COLOR = base_color;
		if (fill_enabled) {
			COLOR = add_layer(COLOR, patterns[0], pattern_distortions[0], offsets[0], scales[0], opacities[0]);
			COLOR = add_layer(COLOR, patterns[1], pattern_distortions[0], offsets[1], scales[1], opacities[1]);
			COLOR = add_layer(COLOR, patterns[2], pattern_distortions[0], offsets[2], scales[2], opacities[2]);
			COLOR = add_layer(COLOR, patterns[3], pattern_distortions[0], offsets[3], scales[3], opacities[3]);
		}
		if (edge_enabled) {
			COLOR = add_edges(COLOR, SCREEN_UV);
		}
		c.rgb /= c.a;
		COLOR *= c;
	} else {
		COLOR = c;
	}
}

