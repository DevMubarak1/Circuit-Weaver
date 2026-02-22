shader_type canvas_item;

// Lightweight glowing border + inner gradient for UI panels
uniform vec4 glow_color : source_color = vec4(0.0, 0.85, 0.85, 1.0);
uniform vec4 inner_color_top : source_color = vec4(0.08, 0.10, 0.16, 0.85);
uniform vec4 inner_color_bottom : source_color = vec4(0.03, 0.04, 0.07, 0.95);
uniform float border_width : hint_range(0.5, 8.0) = 2.0;
uniform float glow_spread : hint_range(0.0, 30.0) = 12.0;
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.6;
uniform float corner_radius : hint_range(0.0, 40.0) = 10.0;

// Signed distance to rounded rectangle
float rounded_rect_sdf(vec2 p, vec2 half_size, float r) {
	vec2 d = abs(p) - half_size + vec2(r);
	return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - r;
}

void fragment() {
	vec2 uv = UV;
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 center = (uv - 0.5) * size;
	vec2 half_size = size * 0.5;

	float dist = rounded_rect_sdf(center, half_size, corner_radius);

	// Inner gradient fill
	vec4 fill = mix(inner_color_top, inner_color_bottom, uv.y);

	// Border
	float border_line = smoothstep(border_width * 0.5 + 0.5, border_width * 0.5 - 0.5, abs(dist));

	// Static glow (no pulse — saves a sin(TIME) per pixel)
	float glow = smoothstep(glow_spread, 0.0, dist) * glow_intensity;

	// Compose
	vec4 color = fill;
	float outside = smoothstep(-1.0, 0.0, dist);
	color.rgb = mix(color.rgb, glow_color.rgb, glow * (1.0 - outside * 0.5));
	color.rgb = mix(color.rgb, glow_color.rgb * 0.9, border_line * 0.9);

	// Inside mask
	float inside_mask = smoothstep(1.0, -0.5, dist);
	color.a *= inside_mask;
	float glow_alpha = glow * smoothstep(glow_spread + 5.0, 0.0, dist) * 0.5;
	color.a = max(color.a, glow_alpha);

	COLOR = color;
}
