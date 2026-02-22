shader_type canvas_item;

// Holographic celebration / victory effect
// Apply to a full-screen ColorRect for level-complete backdrop

uniform float time_scale : hint_range(0.1, 3.0) = 1.0;
uniform vec4 color_a : source_color = vec4(0.0, 0.9, 0.9, 1.0);
uniform vec4 color_b : source_color = vec4(0.4, 0.2, 0.9, 1.0);
uniform vec4 color_c : source_color = vec4(0.9, 0.3, 0.6, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.3;
uniform float wave_scale : hint_range(1.0, 20.0) = 6.0;

void fragment() {
	vec2 uv = UV;
	float t = TIME * time_scale;

	// Flowing waves
	float wave1 = sin(uv.x * wave_scale + t * 1.5) * cos(uv.y * wave_scale * 0.7 + t * 0.8);
	float wave2 = sin(uv.y * wave_scale * 1.3 - t * 1.2) * cos(uv.x * wave_scale * 0.5 + t * 1.1);
	float wave3 = sin((uv.x + uv.y) * wave_scale * 0.8 + t * 2.0) * 0.5;

	// Blend three colors based on waves
	float blend1 = wave1 * 0.5 + 0.5;
	float blend2 = wave2 * 0.5 + 0.5;

	vec4 color = mix(color_a, color_b, blend1);
	color = mix(color, color_c, blend2 * 0.4);

	// Add shimmer
	float shimmer = pow(abs(wave3), 3.0) * 2.0;
	color.rgb += shimmer * 0.2;

	// Radial fade from center
	float dist = length(uv - 0.5) * 1.5;
	float vignette = smoothstep(1.2, 0.3, dist);

	color.a = intensity * vignette;
	COLOR = color;
}
