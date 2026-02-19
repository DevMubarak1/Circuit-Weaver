shader_type canvas_item;

// Wire pulse shader — creates a flowing, pulsing glow effect on active wires
uniform float pulse_speed : hint_range(0.5, 5.0) = 2.0;
uniform float glow_intensity : hint_range(0.0, 3.0) = 1.5;
uniform float flow_speed : hint_range(0.0, 4.0) = 1.5;
uniform bool is_active = false;
uniform vec4 active_color : source_color = vec4(0.0, 0.96, 1.0, 1.0); // Electric cyan
uniform vec4 inactive_color : source_color = vec4(0.173, 0.192, 0.235, 1.0); // Steel grey

void fragment() {
	vec4 base = COLOR;

	if (is_active) {
		// Pulsing glow — sinusoidal brightness oscillation
		float pulse = sin(TIME * pulse_speed) * 0.3 + 0.7;

		// Flowing effect along the wire (uses UV.x as wire-length parameter)
		float flow = sin((UV.x - TIME * flow_speed) * 6.2832 * 2.0) * 0.15 + 0.85;

		float combined = pulse * flow * glow_intensity;
		vec4 glow_color = active_color * combined;

		// Blend: boost the color beyond 1.0 for HDR bloom pickup
		COLOR = vec4(glow_color.rgb, base.a);
	} else {
		COLOR = vec4(inactive_color.rgb, base.a * 0.8);
	}
}
