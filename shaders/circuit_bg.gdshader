shader_type canvas_item;

// Lightweight animated circuit board background — clean grid with subtle pulse
uniform float time_scale : hint_range(0.01, 1.0) = 0.08;
uniform vec4 line_color : source_color = vec4(0.10, 0.12, 0.18, 1.0);
uniform vec4 bg_color : source_color = vec4(0.028, 0.035, 0.058, 1.0);
uniform vec4 glow_color : source_color = vec4(0.0, 0.65, 0.65, 1.0);
uniform float grid_size : hint_range(10.0, 80.0) = 40.0;
uniform float line_width : hint_range(0.5, 3.0) = 1.0;
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.35;

float grid_lines(vec2 uv, float size, float width) {
	vec2 grid = abs(fract(uv / size - 0.5) - 0.5) * size;
	float d = min(grid.x, grid.y);
	return 1.0 - smoothstep(0.0, width, d);
}

float dot_pattern(vec2 uv, float size) {
	vec2 cell = fract(uv / size);
	float d = length(cell - 0.5) * size;
	return 1.0 - smoothstep(1.2, 2.0, d);
}

void fragment() {
	vec2 uv = FRAGCOORD.xy;
	float t = TIME * time_scale;

	// Base grid
	float grid = grid_lines(uv, grid_size, line_width);

	// Dot intersections
	float dots = dot_pattern(uv, grid_size);

	// Simple slow pulse
	float pulse = (sin(t * 4.0) * 0.5 + 0.5) * pulse_intensity;

	// Subtle vignette
	vec2 norm_uv = UV;
	float vignette = 1.0 - smoothstep(0.3, 0.85, length(norm_uv - vec2(0.5)));

	// Compose — minimal passes
	vec4 base = bg_color;
	base = mix(base, line_color, grid * 0.55);
	base = mix(base, line_color, dots * 0.7);
	base = mix(base, glow_color, dots * pulse * 0.4);
	base.rgb *= (0.75 + 0.25 * vignette);

	COLOR = base;
}
