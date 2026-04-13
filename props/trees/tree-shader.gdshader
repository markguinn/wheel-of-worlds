// this wonderful shader is adapted from work by buddhanomad - thank you!
// see https://godotshaders.com/shader/2d-flag-wave-animetion-shader/

shader_type canvas_item;

uniform float amplitude       : hint_range(0.0, 64.0) = 0.5;   // Controls the height of the wave.
uniform float frequency       : hint_range(-64.0, 64.0) = 32.0;  // Sets the number of waves (negative values flip the wave).
uniform float speed           : hint_range(0.0, 10.0) = 1.0;    // Adjusts how fast the wave moves.
uniform float fixed_edge_range: hint_range(0.0, 1.0) = 0.25;    // Determines the area where the wave is damped.

void fragment() {
    vec2 distorted_uv = UV; // Start with the original UV coordinates.
    float wave;             // Will hold the calculated wave offset.
    float influence;        // Factor that reduces the wave effect near the base.
    wave = sin(UV.y * frequency + TIME * speed) * amplitude * 0.01;
    influence = smoothstep(fixed_edge_range, 0.0, UV.y);
    distorted_uv.x += wave * influence;

    // Retrieve the texture color from the modified UV coordinates.
    vec4 tex_color = texture(TEXTURE, distorted_uv);

    // Discard pixels that are nearly transparent.
    if (tex_color.a < 0.1) {
        discard;
    }

    // Output the final color.
    COLOR = tex_color;
}
