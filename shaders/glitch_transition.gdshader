shader_type canvas_item;

// Digital glitch transition shader for chapter changes
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float block_size : hint_range(2.0, 64.0) = 16.0;
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.5;
uniform vec4 base_color : source_color = vec4(0.043, 0.055, 0.078, 1.0);
uniform vec4 glow_color : source_color = vec4(0.0, 0.96, 1.0, 1.0);

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;

	// Block-based reveal: screen is divided into cells
	vec2 block = floor(uv * block_size) / block_size;
	float noise = rand(block + vec2(floor(TIME * 12.0)));

	// Threshold rises with progress — more blocks become visible
	float threshold = progress * 1.2; // slightly overshoot for full coverage

	if (noise < threshold) {
		// Glitch offset: shift UV horizontally for "scan line" effect
		float glitch_offset = (rand(vec2(block.y, floor(TIME * 8.0))) - 0.5) * glitch_intensity * (1.0 - progress);
		vec2 shifted_uv = uv + vec2(glitch_offset, 0.0);
		shifted_uv = clamp(shifted_uv, vec2(0.0), vec2(1.0));

		// Scanline flicker at the boundary between covered/uncovered
		float edge_dist = abs(noise - threshold);
		float scanline = sin(uv.y * 300.0 + TIME * 20.0) * 0.5 + 0.5;
		float edge_glow = smoothstep(0.08, 0.0, edge_dist) * scanline;

		// Mix between solid black overlay and cyan edge glow
		vec4 overlay = base_color;
		overlay.rgb += glow_color.rgb * edge_glow * 2.0;
		overlay.a = 1.0;
		COLOR = overlay;
	} else {
		// Not yet covered — fully transparent (show game underneath)
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
}
