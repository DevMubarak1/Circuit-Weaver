shader_type canvas_item;

// Animated circuit board background pattern
uniform float time_scale : hint_range(0.01, 1.0) = 0.08;
uniform vec4 line_color : source_color = vec4(0.12, 0.14, 0.19, 1.0);
uniform vec4 bg_color : source_color = vec4(0.043, 0.055, 0.078, 1.0);
uniform vec4 glow_color : source_color = vec4(0.0, 0.6, 0.6, 1.0);
uniform float grid_size : hint_range(10.0, 80.0) = 40.0;
uniform float line_width : hint_range(0.5, 3.0) = 1.0;
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.3;

float grid_lines(vec2 uv, float size, float width) {
	vec2 grid = abs(fract(uv / size - 0.5) - 0.5) * size;
	float d = min(grid.x, grid.y);
	return 1.0 - smoothstep(0.0, width, d);
}

float dot_pattern(vec2 uv, float size) {
	vec2 cell = fract(uv / size);
	float d = length(cell - 0.5) * size;
	return 1.0 - smoothstep(1.0, 1.5, d);
}

void fragment() {
	vec2 uv = FRAGCOORD.xy;
	float t = TIME * time_scale;

	// Base grid
	float grid = grid_lines(uv, grid_size, line_width);

	// Dot intersections
	float dots = dot_pattern(uv, grid_size);

	// Traveling pulse
	float pulse_x = sin(uv.x * 0.02 + t * 4.0) * 0.5 + 0.5;
	float pulse_y = cos(uv.y * 0.015 + t * 3.0) * 0.5 + 0.5;
	float pulse = pulse_x * pulse_y * pulse_intensity;

	vec4 base = bg_color;
	base = mix(base, line_color, grid * 0.6);
	base = mix(base, line_color, dots * 0.8);
	base = mix(base, glow_color, grid * pulse * 0.4);
	base = mix(base, glow_color, dots * pulse * 0.6);

	COLOR = base;
}
