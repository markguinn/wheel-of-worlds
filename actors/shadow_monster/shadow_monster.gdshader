shader_type canvas_item;

const int MONSTER_BODY_PARTS = 1;

uniform sampler2D noise;
uniform sampler2D monster_color;
uniform vec2 monster_body[MONSTER_BODY_PARTS];
uniform float noise_middle_range: hint_range(0.0, 1.0) = 0.3;
uniform float monster_thickness: hint_range(0.0, 1.0) = 0.3;
uniform float monster_radius: hint_range(0.0, 1.0) = 0.3;
uniform float i_dont_even_know: hint_range(0.0, 10.0) = 3.;
uniform vec2 noise_offset;

void fragment() {
	float color_sampling_value = smoothstep(
		0., monster_thickness,
		abs(texture(noise, (UV + 0.5) / 3. + noise_offset).r - noise_middle_range)
	);
	COLOR = texture(monster_color, vec2(color_sampling_value, 0.));
	// make monster close only to its body
	float px_distance_min = length(monster_body[0] - UV);
	for(int i = 1; i < MONSTER_BODY_PARTS; ++i){
		px_distance_min = min(px_distance_min, length(monster_body[i] - UV));
	}
	float thickness_threshold = smoothstep(monster_radius, 0., px_distance_min) * monster_thickness;
	thickness_threshold = pow(thickness_threshold, i_dont_even_know);
	COLOR.a = min(COLOR.a, smoothstep(thickness_threshold, 0., color_sampling_value));
}

