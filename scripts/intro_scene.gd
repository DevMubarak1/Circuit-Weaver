extends Control

var _boot_lines: Array[Label] = []
var _title_label: Label = null
var _subtitle_label: Label = null
var _skip_pressed: bool = false

func _ready() -> void:
	# Allow tap/click to skip
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

	await get_tree().process_frame
	_build_cinematic_intro()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_skip_pressed = true

func _build_cinematic_intro() -> void:
	var anim = get_node_or_null("/root/AnimHelper")
	var resp = get_node_or_null("/root/ResponsiveManager")
	var ui_scale: float = resp.ui_scale if resp else 1.0
	var vp_size: Vector2 = get_viewport().get_visible_rect().size

	# --- BACKGROUND IMAGE ---
	var bg_image = TextureRect.new()
	var tex = load("res://assets/intro_bg.jpg")
	if tex:
		bg_image.texture = tex
	bg_image.anchor_right = 1.0
	bg_image.anchor_bottom = 1.0
	bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_image.modulate = Color(0.35, 0.45, 0.55, 1.0)  # Dark teal tint overlay
	bg_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_image)

	# Dark gradient overlay for readability
	var gradient_overlay = ColorRect.new()
	gradient_overlay.anchor_right = 1.0
	gradient_overlay.anchor_bottom = 1.0
	gradient_overlay.color = Color(0.03, 0.04, 0.06, 0.65)
	gradient_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gradient_overlay)

	# Animated circuit background effect on top
	if anim:
		anim.create_circuit_bg(self)

	# Scanning line
	if anim:
		await get_tree().process_frame
		anim.scanning_line(self, Color(0, 2.5, 2.5, 0.06), 3.0)

	# Center container for boot text
	var center_box = VBoxContainer.new()
	center_box.anchor_left = 0.5
	center_box.anchor_top = 0.5
	center_box.anchor_right = 0.5
	center_box.anchor_bottom = 0.5
	center_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	center_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center_box.add_theme_constant_override("separation", int(6 * ui_scale))
	add_child(center_box)

	# Boot sequence lines
	var boot_texts: Array[String] = [
		"> Initializing Circuit Weaver v1.0...",
		"> Loading gate library... OK",
		"> Calibrating signal paths... OK",
		"> Neural interface ready.",
		"",
	]

	for i in range(boot_texts.size()):
		var line = Label.new()
		line.text = ""
		line.add_theme_color_override("font_color", ThemeManager.SIGNAL_ACTIVE)
		line.add_theme_font_size_override("font_size", int(13 * ui_scale))
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.modulate.a = 0.0
		center_box.add_child(line)
		_boot_lines.append(line)

	# Spacer before title
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, int(18 * ui_scale))
	center_box.add_child(spacer)

	# Title — CIRCUIT WEAVER
	_title_label = Label.new()
	_title_label.text = "CIRCUIT WEAVER"
	_title_label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0, 1.0))  # Bright cyan
	_title_label.add_theme_font_size_override("font_size", int(54 * ui_scale))
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate.a = 0.0
	center_box.add_child(_title_label)

	# Decorative divider line
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(int(280 * ui_scale), int(2 * ui_scale))
	divider.color = Color(0.0, 0.9, 0.9, 0.5)
	divider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	divider.modulate.a = 0.0
	center_box.add_child(divider)

	# Motto / tagline
	_subtitle_label = Label.new()
	_subtitle_label.text = "Master the Logic. Weave the Future."
	_subtitle_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.88, 1.0))
	_subtitle_label.add_theme_font_size_override("font_size", int(16 * ui_scale))
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.modulate.a = 0.0
	center_box.add_child(_subtitle_label)

	# "Tap to skip" hint at bottom
	var skip_hint = Label.new()
	skip_hint.text = "Tap anywhere to skip"
	skip_hint.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	skip_hint.add_theme_font_size_override("font_size", int(11 * ui_scale))
	skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_hint.anchor_left = 0.0
	skip_hint.anchor_right = 1.0
	skip_hint.anchor_top = 1.0
	skip_hint.anchor_bottom = 1.0
	skip_hint.offset_top = -40
	skip_hint.offset_bottom = -20
	add_child(skip_hint)
	if anim:
		anim.pulse_glow(skip_hint, Color(ThemeManager.TEXT_MUTED.r, ThemeManager.TEXT_MUTED.g, ThemeManager.TEXT_MUTED.b, 0.3), 100)

	# Play boot sequence
	await _play_boot_sequence(boot_texts)

	if _skip_pressed:
		_navigate_next()
		return

	# Title reveal — dramatic scale + glow
	if anim:
		_title_label.modulate.a = 0.0
		_title_label.pivot_offset = _title_label.size / 2.0
		_title_label.scale = Vector2(0.6, 0.6)
		var tw = _title_label.create_tween().set_parallel(true)
		tw.tween_property(_title_label, "modulate:a", 1.0, 0.7)
		tw.tween_property(_title_label, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tw.finished
	else:
		_title_label.modulate.a = 1.0

	if _skip_pressed:
		_navigate_next()
		return

	# Divider fade-in + expand
	if anim:
		divider.modulate.a = 0.0
		divider.pivot_offset = Vector2(divider.custom_minimum_size.x / 2.0, 0)
		divider.scale = Vector2(0.0, 1.0)
		var tw_div = divider.create_tween().set_parallel(true)
		tw_div.tween_property(divider, "modulate:a", 1.0, 0.4)
		tw_div.tween_property(divider, "scale:x", 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tw_div.finished
	else:
		divider.modulate.a = 1.0

	if _skip_pressed:
		_navigate_next()
		return

	# Subtitle typewriter effect
	if anim:
		anim.typewriter(_subtitle_label, _subtitle_label.text, 35.0)
		_subtitle_label.modulate.a = 1.0
		await get_tree().create_timer(1.4).timeout
	else:
		_subtitle_label.modulate.a = 1.0

	if _skip_pressed:
		_navigate_next()
		return

	# Particle burst around title
	if anim:
		var center_pt = Vector2(vp_size.x / 2.0, vp_size.y / 2.0 - 20)
		anim.spawn_particles(self, center_pt, Color(0.0, 1.0, 1.0, 1.0), 35)

	await get_tree().create_timer(1.5).timeout
	_navigate_next()

func _play_boot_sequence(texts: Array[String]) -> void:
	var anim = get_node_or_null("/root/AnimHelper")
	for i in range(texts.size()):
		if _skip_pressed:
			return
		var line = _boot_lines[i]
		if texts[i] == "":
			await get_tree().create_timer(0.15).timeout
			continue
		line.modulate.a = 1.0
		if anim:
			anim.typewriter(line, texts[i], 60.0)
		else:
			line.text = texts[i]
		await get_tree().create_timer(0.45).timeout

func _navigate_next() -> void:
	var tm = get_node_or_null("/root/TransitionMgr")
	var target: String
	if Global.user_name != "" and Global.user_name != "Guest":
		target = "res://scenes/level_select.tscn"
	else:
		target = "res://scenes/user_profile.tscn"
	if tm and tm.has_method("transition_to_scene"):
		tm.transition_to_scene(target, false)
	else:
		get_tree().change_scene_to_file(target)
