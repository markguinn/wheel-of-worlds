shader_type canvas_item;

// this just zooms in enough to push a certain amount of margin off the screen
// it is disabled in tool mode

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

// this should match the height of the edges on the painted shader
uniform vec2 margin_size = vec2(100.0, 100.0);

uniform bool enabled = true;

void fragment() {
	//if (enabled) {
		vec2 uv_margin = margin_size * TEXTURE_PIXEL_SIZE;
		vec2 uv_scale = vec2(1.0, 1.0) - uv_margin;
		if (SCREEN_UV.x > 0.5) {
			COLOR = vec4(1.0, 0.0, 0.0, 1.0);
		}
		//vec2 uv = UV * uv_scale + uv_margin / 2.0;
		//COLOR = texture(TEXTURE, uv);
	//}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
