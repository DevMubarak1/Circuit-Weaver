shader_type canvas_item;

// Animated gradient background with flowing aurora effect
// Use on full-screen ColorRect behind UI screens

uniform vec4 color_top : source_color = vec4(0.02, 0.03, 0.06, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.06, 0.04, 0.10, 1.0);
uniform vec4 accent_1 : source_color = vec4(0.0, 0.5, 0.5, 1.0);
uniform vec4 accent_2 : source_color = vec4(0.25, 0.1, 0.5, 1.0);
uniform float flow_speed : hint_range(0.01, 1.0) = 0.15;
uniform float accent_intensity : hint_range(0.0, 0.5) = 0.12;
uniform float wave_complexity : hint_range(1.0, 10.0) = 4.0;

void fragment() {
	vec2 uv = UV;
	float t = TIME * flow_speed;

	// Base vertical gradient
	vec4 base = mix(color_top, color_bottom, uv.y);

	// Aurora waves (simplified — 2 instead of 3)
	float wave1 = sin(uv.x * wave_complexity + t * 2.0 + uv.y * 3.0) * 0.5 + 0.5;
	float wave2 = cos(uv.x * wave_complexity * 0.7 - t * 1.5 + uv.y * 2.0) * 0.5 + 0.5;

	// Combine waves with vertical position bias
	float aurora_mask = wave1 * wave2 * smoothstep(0.8, 0.2, uv.y);

	// Apply accent colors
	base.rgb += accent_1.rgb * aurora_mask * accent_intensity;
	base.rgb += accent_2.rgb * (1.0 - aurora_mask) * accent_intensity * 0.4;

	COLOR = base;
}
