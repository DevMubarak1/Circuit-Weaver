# AnimHelper — Reusable animation utilities for Circuit Weaver UI
# Add as autoload: AnimHelper
extends Node

# --- FADE ---

func fade_in(node: CanvasItem, duration: float = 0.35, delay: float = 0.0) -> Tween:
	node.modulate.a = 0.0
	var tw = node.create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(node, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tw

func fade_out(node: CanvasItem, duration: float = 0.25) -> Tween:
	var tw = node.create_tween()
	tw.tween_property(node, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return tw

# --- SLIDE ---

func slide_in_from_bottom(node: Control, distance: float = 60.0, duration: float = 0.4, delay: float = 0.0) -> Tween:
	var orig_y: float = node.position.y
	node.position.y = orig_y + distance
	node.modulate.a = 0.0
	var tw = node.create_tween().set_parallel(true)
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(node, "position:y", orig_y, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
	tw.tween_property(node, "modulate:a", 1.0, duration * 0.6).set_delay(delay)
	return tw

func slide_in_from_top(node: Control, distance: float = 40.0, duration: float = 0.35, delay: float = 0.0) -> Tween:
	var orig_y: float = node.position.y
	node.position.y = orig_y - distance
	node.modulate.a = 0.0
	var tw = node.create_tween().set_parallel(true)
	tw.tween_property(node, "position:y", orig_y, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
	tw.tween_property(node, "modulate:a", 1.0, duration * 0.6).set_delay(delay)
	return tw

func slide_in_from_left(node: Control, distance: float = 80.0, duration: float = 0.4, delay: float = 0.0) -> Tween:
	var orig_x: float = node.position.x
	node.position.x = orig_x - distance
	node.modulate.a = 0.0
	var tw = node.create_tween().set_parallel(true)
	tw.tween_property(node, "position:x", orig_x, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
	tw.tween_property(node, "modulate:a", 1.0, duration * 0.6).set_delay(delay)
	return tw

func slide_in_from_right(node: Control, distance: float = 80.0, duration: float = 0.4, delay: float = 0.0) -> Tween:
	var orig_x: float = node.position.x
	node.position.x = orig_x + distance
	node.modulate.a = 0.0
	var tw = node.create_tween().set_parallel(true)
	tw.tween_property(node, "position:x", orig_x, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
	tw.tween_property(node, "modulate:a", 1.0, duration * 0.6).set_delay(delay)
	return tw

# --- SCALE POP ---

func pop_in(node: Control, duration: float = 0.35, delay: float = 0.0) -> Tween:
	node.pivot_offset = node.size / 2.0
	node.scale = Vector2(0.3, 0.3)
	node.modulate.a = 0.0
	var tw = node.create_tween().set_parallel(true)
	tw.tween_property(node, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
	tw.tween_property(node, "modulate:a", 1.0, duration * 0.5).set_delay(delay)
	return tw

func pop_out(node: Control, duration: float = 0.2) -> Tween:
	node.pivot_offset = node.size / 2.0
	var tw = node.create_tween().set_parallel(true)
	tw.tween_property(node, "scale", Vector2(0.5, 0.5), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(node, "modulate:a", 0.0, duration)
	return tw

# --- BOUNCE / PULSE ---

func bounce(node: Control, strength: float = 1.15, duration: float = 0.3) -> Tween:
	node.pivot_offset = node.size / 2.0
	var tw = node.create_tween()
	tw.tween_property(node, "scale", Vector2(strength, strength), duration * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2.ONE, duration * 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tw

func pulse_glow(node: CanvasItem, color: Color = Color(0.0, 2.5, 2.5, 1.0), loops: int = 3) -> Tween:
	var orig_mod: Color = node.modulate
	var tw = node.create_tween().set_loops(loops)
	tw.tween_property(node, "modulate", color, 0.3).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "modulate", orig_mod, 0.3).set_trans(Tween.TRANS_SINE)
	return tw

func pulse_scale(node: Control, min_s: float = 0.95, max_s: float = 1.05, speed: float = 0.5) -> Tween:
	node.pivot_offset = node.size / 2.0
	var tw = node.create_tween().set_loops(0)
	tw.tween_property(node, "scale", Vector2(max_s, max_s), speed).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "scale", Vector2(min_s, min_s), speed).set_trans(Tween.TRANS_SINE)
	return tw

# --- TYPEWRITER ---

func typewriter(label: Label, text: String, chars_per_sec: float = 40.0, delay: float = 0.0) -> Tween:
	label.text = text
	label.visible_ratio = 0.0
	var duration: float = float(text.length()) / chars_per_sec
	var tw = label.create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(label, "visible_ratio", 1.0, duration)
	return tw

# --- SHAKE ---

func shake(node: Node2D, intensity: float = 8.0, duration: float = 0.3) -> Tween:
	var orig_pos: Vector2 = node.position
	var tw = node.create_tween()
	var steps: int = int(duration / 0.03)
	for i in range(steps):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(node, "position", orig_pos + offset, 0.03)
	tw.tween_property(node, "position", orig_pos, 0.03)
	return tw

# --- STAGGER CHILDREN ---

func stagger_children(parent: Control, stagger_delay: float = 0.08, anim_type: String = "slide_up") -> void:
	var children = parent.get_children()
	for i in range(children.size()):
		var child = children[i]
		if child is Control:
			var d: float = float(i) * stagger_delay
			match anim_type:
				"slide_up":
					slide_in_from_bottom(child, 40.0, 0.35, d)
				"pop":
					pop_in(child, 0.3, d)
				"fade":
					fade_in(child, 0.3, d)
				"slide_left":
					slide_in_from_left(child, 60.0, 0.35, d)

# --- BUTTON HOVER ANIMATION (connect to mouse_entered/exited) ---

func setup_button_hover(btn: Button, scale_up: float = 1.06) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.mouse_entered.connect(func() -> void:
		var tw = btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(scale_up, scale_up), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func() -> void:
		var tw = btn.create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)

# --- STAR CELEBRATION ---

func celebrate_stars(parent: Control, star_count: int, center: Vector2, star_size: float = 48.0) -> void:
	var colors = [ThemeManager.GATE_XOR_AMBER, ThemeManager.SIGNAL_ACTIVE, ThemeManager.GATE_OR_GREEN]
	for i in range(star_count):
		var star_lbl = Label.new()
		star_lbl.text = "★"
		star_lbl.add_theme_font_size_override("font_size", int(star_size))
		star_lbl.add_theme_color_override("font_color", colors[i % colors.size()])
		star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_lbl.position = center
		star_lbl.modulate.a = 0.0
		star_lbl.pivot_offset = Vector2(star_size / 2.0, star_size / 2.0)
		parent.add_child(star_lbl)
		# Fly out with delay
		var angle: float = (-PI / 2.0) + (float(i) - float(star_count - 1) / 2.0) * 0.6
		var dist: float = 80.0 + randf() * 30.0
		var target_pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * dist
		var delay: float = float(i) * 0.2
		var tw = star_lbl.create_tween().set_parallel(true)
		tw.tween_property(star_lbl, "position", target_pos, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
		tw.tween_property(star_lbl, "modulate:a", 1.0, 0.2).set_delay(delay)
		tw.tween_property(star_lbl, "scale", Vector2(1.3, 1.3), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(delay)
		tw.chain().tween_property(star_lbl, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		# Fade out after hold
		tw.chain().tween_interval(1.5)
		tw.chain().tween_property(star_lbl, "modulate:a", 0.0, 0.4)
		tw.chain().tween_callback(star_lbl.queue_free)

# --- PARTICLE BURST (CPU particles via code) ---

func spawn_particles(parent: Control, center: Vector2, color: Color, count: int = 20) -> void:
	for i in range(count):
		var dot = ColorRect.new()
		dot.size = Vector2(4, 4)
		dot.color = color
		dot.position = center
		dot.modulate.a = 0.8
		parent.add_child(dot)
		var angle: float = randf() * TAU
		var speed: float = 60.0 + randf() * 120.0
		var target: Vector2 = center + Vector2(cos(angle), sin(angle)) * speed
		var tw = dot.create_tween().set_parallel(true)
		tw.tween_property(dot, "position", target, 0.6 + randf() * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(dot, "modulate:a", 0.0, 0.5).set_delay(0.3)
		tw.chain().tween_callback(dot.queue_free)

# --- SCANNING LINE EFFECT ---

func scanning_line(parent: Control, color: Color = Color(0, 2.5, 2.5, 0.15), duration: float = 2.0) -> void:
	var line = ColorRect.new()
	line.size = Vector2(parent.size.x, 2)
	line.color = color
	line.position = Vector2(0, -2)
	parent.add_child(line)
	var tw = line.create_tween().set_loops(0)
	tw.tween_property(line, "position:y", parent.size.y, duration).set_trans(Tween.TRANS_LINEAR)
	tw.tween_property(line, "position:y", -2.0, 0.0)

# --- WIRE CONNECTION FLASH ---

func flash_wire(wire: Node2D, color: Color = Color(0.0, 2.5, 2.5, 1.0), duration: float = 0.35) -> void:
	var orig_mod: Color = wire.modulate
	wire.modulate = color
	var tw = wire.create_tween()
	tw.tween_property(wire, "modulate", orig_mod, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# --- FLOATING TEXT ("+1 WIRE" etc.) ---

func floating_text(parent: Control, text: String, from_pos: Vector2, color: Color = Color.WHITE, font_size: int = 14) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = from_pos
	lbl.modulate.a = 1.0
	lbl.z_index = 100
	parent.add_child(lbl)
	var tw = lbl.create_tween().set_parallel(true)
	tw.tween_property(lbl, "position:y", from_pos.y - 40.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tw.chain().tween_callback(lbl.queue_free)

# --- CIRCUIT GRID BACKGROUND ---

func create_circuit_bg(parent: Control) -> void:
	# Shader-based animated circuit background
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.name = "BGBase"
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader_res = load("res://shaders/circuit_bg.gdshader")
	if shader_res:
		var mat = ShaderMaterial.new()
		mat.shader = shader_res
		bg.material = mat
	else:
		bg.color = ThemeManager.MIDNIGHT_BG
	parent.add_child(bg)
	parent.move_child(bg, 0)
	# Gradient vignette on top
	var vignette = _create_vignette()
	parent.add_child(vignette)
	parent.move_child(vignette, 1)

func _create_vignette() -> ColorRect:
	var v = ColorRect.new()
	v.anchor_right = 1.0
	v.anchor_bottom = 1.0
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.color = Color(0, 0, 0, 0)
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv) * 1.4;
	float vignette = smoothstep(0.4, 1.2, dist);
	COLOR = vec4(0.0, 0.0, 0.0, vignette * 0.6);
}
"""
	mat.shader = shader
	v.material = mat
	v.name = "Vignette"
	return v

# --- CONFETTI BURST (multi-colored rectangles + rotation) ---

func confetti_burst(parent: Control, center: Vector2, count: int = 40) -> void:
	var confetti_colors = [
		Color(0.0, 0.9, 0.9, 1.0),   # Cyan
		Color(1.0, 0.8, 0.1, 1.0),   # Gold
		Color(0.4, 0.9, 0.4, 1.0),   # Green
		Color(0.8, 0.3, 0.9, 1.0),   # Purple
		Color(1.0, 0.4, 0.5, 1.0),   # Pink
		Color(0.3, 0.5, 1.0, 1.0),   # Blue
	]
	for i in range(count):
		var piece = ColorRect.new()
		var w = randf_range(4, 10)
		var h = randf_range(2, 6)
		piece.size = Vector2(w, h)
		piece.color = confetti_colors[i % confetti_colors.size()]
		piece.position = center - Vector2(w / 2.0, h / 2.0)
		piece.pivot_offset = Vector2(w / 2.0, h / 2.0)
		piece.rotation = randf() * TAU
		piece.modulate.a = 1.0
		parent.add_child(piece)
		# Physics-like arc: outward + gravity
		var angle = randf() * TAU
		var speed = randf_range(100, 280)
		var target_x = center.x + cos(angle) * speed
		var target_y = center.y + sin(angle) * speed * 0.5 + randf_range(80, 200)  # gravity pull
		var duration = randf_range(0.8, 1.5)
		var spin = randf_range(-6.0, 6.0)
		var tw = piece.create_tween().set_parallel(true)
		tw.tween_property(piece, "position:x", target_x, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(piece, "position:y", target_y, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(piece, "rotation", piece.rotation + spin, duration)
		tw.tween_property(piece, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)
		tw.chain().tween_callback(piece.queue_free)

# --- RIPPLE EFFECT (expanding concentric rings) ---

func ripple_effect(parent: Control, center: Vector2, color: Color = Color(0, 0.85, 0.85, 1.0), rings: int = 3) -> void:
	for i in range(rings):
		var ring = _RippleRing.new(center, color, 80.0 + float(i) * 30.0)
		parent.add_child(ring)
		# Stagger the rings
		var tw = ring.create_tween()
		tw.tween_interval(float(i) * 0.15)
		tw.tween_callback(ring.start_animation)

# --- GLOW CARD HOVER (enhanced hover with border glow tween) ---

func card_hover_enter(panel: PanelContainer, hover_style: StyleBoxFlat, base_scale: float = 1.05) -> void:
	panel.pivot_offset = panel.size / 2.0
	panel.add_theme_stylebox_override("panel", hover_style)
	var tw = panel.create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2(base_scale, base_scale), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func card_hover_exit(panel: PanelContainer, normal_style: StyleBoxFlat) -> void:
	panel.add_theme_stylebox_override("panel", normal_style)
	var tw = panel.create_tween()
	tw.tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# --- COUNTER ANIMATION (number counting up) ---

func count_up(label: Label, from_val: int, to_val: int, duration: float = 0.8, prefix: String = "", suffix: String = "") -> Tween:
	var tw = label.create_tween()
	tw.tween_method(func(v: float) -> void:
		label.text = "%s%d%s" % [prefix, int(v), suffix]
	, float(from_val), float(to_val), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tw

# --- PROGRESS BAR FILL ANIMATION ---

func animate_progress(bar: ProgressBar, to_val: float, duration: float = 0.6) -> Tween:
	var tw = bar.create_tween()
	tw.tween_property(bar, "value", to_val, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tw

# --- GLOW TEXT (slow breathing glow on a label) ---

func glow_text(label: Label, base_color: Color, glow_factor: float = 1.4) -> Tween:
	var glow_color = Color(base_color.r * glow_factor, base_color.g * glow_factor, base_color.b * glow_factor, 1.0)
	label.add_theme_color_override("font_color", base_color)
	var tw = label.create_tween().set_loops(0)
	tw.tween_method(func(t: float) -> void:
		var c = base_color.lerp(glow_color, t)
		label.add_theme_color_override("font_color", c)
	, 0.0, 1.0, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_method(func(t: float) -> void:
		var c = glow_color.lerp(base_color, t)
		label.add_theme_color_override("font_color", c)
	, 0.0, 1.0, 1.2).set_trans(Tween.TRANS_SINE)
	return tw

# --- Internal: Ripple ring node ---

class _RippleRing extends Node2D:
	var _center: Vector2
	var _color: Color
	var _max_radius: float
	var _started: bool = false
	var _elapsed: float = 0.0
	var _duration: float = 0.7

	func _init(center: Vector2, color: Color, max_r: float) -> void:
		_center = center
		_color = color
		_max_radius = max_r

	func start_animation() -> void:
		_started = true

	func _process(delta: float) -> void:
		if not is_inside_tree():
			return
		if not _started:
			return
		_elapsed += delta
		if _elapsed >= _duration:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		if not _started:
			return
		var t = _elapsed / _duration
		var radius = _max_radius * t
		var alpha = (1.0 - t) * 0.5
		var c = Color(_color.r, _color.g, _color.b, alpha)
		draw_arc(_center, radius, 0, TAU, 48, c, 2.0)
