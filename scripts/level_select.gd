# Level Select screen — animated chapter grid with star display and hover effects
extends Control
class_name LevelSelect

const CHAPTERS: Array[Dictionary] = [
	{"name": "Ch.1 Foundations", "levels": [1,2,3,4,5]},
	{"name": "Ch.2 Combinations", "levels": [6,7,8,9,10,11,12,13]},
	{"name": "Ch.3 Advanced", "levels": [14,15,16,17]},
	{"name": "Ch.4 Mastery", "levels": [18,19,20]},
]

var _tab_container: TabContainer
var _total_stars_label: Label
var _header_title: Label
var _welcome_label: Label
var _progress_bar: ProgressBar
var _level_panels: Array[PanelContainer] = []

func _ready() -> void:
	_build_ui()
	await get_tree().process_frame
	_animate_entrance()

# --- BUILD UI ---

func _build_ui() -> void:
	var anim = get_node_or_null("/root/AnimHelper")
	var resp = get_node_or_null("/root/ResponsiveManager")
	var ui_scale: float = resp.ui_scale if resp else 1.0

	# Full-screen background with grid pattern
	if anim:
		anim.create_circuit_bg(self)
	else:
		var bg = ColorRect.new()
		bg.anchor_right = 1.0
		bg.anchor_bottom = 1.0
		bg.color = ThemeManager.MIDNIGHT_BG
		add_child(bg)

	var margin = MarginContainer.new()
	margin.name = "MainMargin"
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", int(40 * ui_scale))
	margin.add_theme_constant_override("margin_right", int(40 * ui_scale))
	margin.add_theme_constant_override("margin_top", int(24 * ui_scale))
	margin.add_theme_constant_override("margin_bottom", int(20 * ui_scale))
	add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.name = "MainVBox"
	vbox.add_theme_constant_override("separation", int(10 * ui_scale))
	margin.add_child(vbox)

	# --- HEADER ROW ---
	var header_row = HBoxContainer.new()
	header_row.name = "HeaderRow"
	header_row.add_theme_constant_override("separation", int(16 * ui_scale))
	vbox.add_child(header_row)

	_header_title = Label.new()
	_header_title.text = "CIRCUIT WEAVER"
	_header_title.add_theme_color_override("font_color", ThemeManager.SIGNAL_ACTIVE)
	_header_title.add_theme_font_size_override("font_size", int(28 * ui_scale))
	_header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(_header_title)

	_total_stars_label = Label.new()
	_total_stars_label.add_theme_color_override("font_color", ThemeManager.GATE_XOR_AMBER)
	_total_stars_label.add_theme_font_size_override("font_size", int(16 * ui_scale))
	header_row.add_child(_total_stars_label)
	_update_total_stars()

	# --- WELCOME + PROGRESS ---
	var info_row = HBoxContainer.new()
	info_row.name = "InfoRow"
	info_row.add_theme_constant_override("separation", int(20 * ui_scale))
	vbox.add_child(info_row)

	_welcome_label = Label.new()
	_welcome_label.text = "Welcome back, Architect %s" % Global.user_name
	_welcome_label.add_theme_color_override("font_color", ThemeManager.TERMINAL_WHITE)
	_welcome_label.add_theme_font_size_override("font_size", int(13 * ui_scale))
	_welcome_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(_welcome_label)

	# Overall progress bar
	var progress_vbox = VBoxContainer.new()
	progress_vbox.add_theme_constant_override("separation", 2)
	info_row.add_child(progress_vbox)

	var progress_lbl = Label.new()
	var completed_count: int = 0
	for i in range(1, 21):
		if Global.get_level_score(i) > 0:
			completed_count += 1
	progress_lbl.text = "%d/20 Levels" % completed_count
	progress_lbl.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	progress_lbl.add_theme_font_size_override("font_size", int(10 * ui_scale))
	progress_vbox.add_child(progress_lbl)

	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0
	_progress_bar.max_value = 20
	_progress_bar.value = completed_count
	_progress_bar.custom_minimum_size = Vector2(160 * ui_scale, 8 * ui_scale)
	_progress_bar.show_percentage = false
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = ThemeManager.MIDNIGHT_GRID
	bar_bg.corner_radius_top_left = 4
	bar_bg.corner_radius_top_right = 4
	bar_bg.corner_radius_bottom_left = 4
	bar_bg.corner_radius_bottom_right = 4
	_progress_bar.add_theme_stylebox_override("background", bar_bg)
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color(ThemeManager.SIGNAL_ACTIVE.r * 0.4, ThemeManager.SIGNAL_ACTIVE.g * 0.4, ThemeManager.SIGNAL_ACTIVE.b * 0.4, 1.0)
	bar_fill.corner_radius_top_left = 4
	bar_fill.corner_radius_top_right = 4
	bar_fill.corner_radius_bottom_left = 4
	bar_fill.corner_radius_bottom_right = 4
	_progress_bar.add_theme_stylebox_override("fill", bar_fill)
	progress_vbox.add_child(_progress_bar)

	# --- SEPARATOR ---
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	sep.add_theme_stylebox_override("separator", _create_thin_line())
	vbox.add_child(sep)

	# --- TAB CONTAINER ---
	_tab_container = TabContainer.new()
	_tab_container.name = "ChapterTabs"
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.add_theme_color_override("font_selected_color", ThemeManager.SIGNAL_ACTIVE)
	_tab_container.add_theme_color_override("font_unselected_color", ThemeManager.TEXT_MUTED)
	_tab_container.add_theme_font_size_override("font_size", int(13 * ui_scale))
	var tab_panel_style = StyleBoxFlat.new()
	tab_panel_style.bg_color = Color(ThemeManager.MIDNIGHT_BG.r, ThemeManager.MIDNIGHT_BG.g, ThemeManager.MIDNIGHT_BG.b, 0.5)
	tab_panel_style.corner_radius_bottom_left = 6
	tab_panel_style.corner_radius_bottom_right = 6
	_tab_container.add_theme_stylebox_override("panel", tab_panel_style)
	vbox.add_child(_tab_container)

	for ch_idx in range(CHAPTERS.size()):
		var ch = CHAPTERS[ch_idx]
		var chapter_num: int = ch_idx + 1
		var locked: bool = not Global.is_chapter_unlocked(chapter_num)
		var scroll = ScrollContainer.new()
		scroll.name = ch["name"]
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_tab_container.add_child(scroll)

		var grid_margin = MarginContainer.new()
		grid_margin.add_theme_constant_override("margin_left", int(16 * ui_scale))
		grid_margin.add_theme_constant_override("margin_right", int(16 * ui_scale))
		grid_margin.add_theme_constant_override("margin_top", int(16 * ui_scale))
		grid_margin.add_theme_constant_override("margin_bottom", int(16 * ui_scale))
		scroll.add_child(grid_margin)

		var grid = GridContainer.new()
		grid.name = "Grid"
		grid.columns = 5 if not resp or not resp.is_mobile() else 3
		grid.add_theme_constant_override("h_separation", int(14 * ui_scale))
		grid.add_theme_constant_override("v_separation", int(14 * ui_scale))
		grid_margin.add_child(grid)
		for level_id in ch["levels"]:
			var panel = _create_level_button(level_id, locked, ui_scale)
			grid.add_child(panel)
			_level_panels.append(panel)

	# --- BOTTOM BUTTONS ---
	var bottom = HBoxContainer.new()
	bottom.name = "BottomRow"
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", int(16 * ui_scale))
	vbox.add_child(bottom)

	var quit_btn = _styled_button("QUIT GAME", Color(0.5, 0.12, 0.12), ui_scale)
	quit_btn.pressed.connect(func() -> void: get_tree().quit())
	bottom.add_child(quit_btn)

	var logout_btn = _styled_button("LOG OUT", Color(0.45, 0.32, 0.08), ui_scale)
	logout_btn.pressed.connect(_on_logout_pressed)
	bottom.add_child(logout_btn)

	# Button hover animations (deferred so they have layout size)
	_setup_bottom_button_hovers.call_deferred(quit_btn, logout_btn)

func _setup_bottom_button_hovers(quit_b: Button, logout_b: Button) -> void:
	var anim = get_node_or_null("/root/AnimHelper")
	if anim:
		anim.setup_button_hover(quit_b, 1.06)
		anim.setup_button_hover(logout_b, 1.06)

# --- LEVEL BUTTON ---

func _create_level_button(level_id: int, chapter_locked: bool, ui_scale: float) -> PanelContainer:
	var unlocked: bool = Global.is_level_unlocked(level_id) and not chapter_locked
	var score: int = Global.get_level_score(level_id)
	var data: Dictionary = LevelConfig.get_level(level_id)
	var title_text: String = data.get("title", "Level %d" % level_id)

	var panel = PanelContainer.new()
	panel.name = "Level%d" % level_id
	panel.custom_minimum_size = Vector2(130 * ui_scale, 95 * ui_scale)
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	if unlocked:
		if score >= 3:
			style.bg_color = Color(0.06, 0.12, 0.10)
			style.border_color = ThemeManager.GATE_OR_GREEN
		elif score > 0:
			style.bg_color = Color(0.08, 0.10, 0.16)
			style.border_color = ThemeManager.SIGNAL_ACTIVE
		else:
			style.bg_color = Color(0.07, 0.08, 0.12)
			style.border_color = ThemeManager.SIGNAL_INACTIVE
	else:
		style.bg_color = Color(0.04, 0.05, 0.07)
		style.border_color = Color(0.12, 0.12, 0.12)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style)

	var inner_margin = MarginContainer.new()
	inner_margin.add_theme_constant_override("margin_left", int(8 * ui_scale))
	inner_margin.add_theme_constant_override("margin_right", int(8 * ui_scale))
	inner_margin.add_theme_constant_override("margin_top", int(8 * ui_scale))
	inner_margin.add_theme_constant_override("margin_bottom", int(8 * ui_scale))
	panel.add_child(inner_margin)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", int(3 * ui_scale))
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_margin.add_child(vb)

	var num_lbl = Label.new()
	num_lbl.text = "%d" % level_id
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lbl.add_theme_font_size_override("font_size", int(20 * ui_scale))
	num_lbl.add_theme_color_override("font_color", ThemeManager.SIGNAL_ACTIVE if unlocked else ThemeManager.TERMINAL_GRAY)
	vb.add_child(num_lbl)

	var title_lbl = Label.new()
	title_lbl.text = title_text if unlocked else "LOCKED"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", int(9 * ui_scale))
	title_lbl.add_theme_color_override("font_color", ThemeManager.TERMINAL_WHITE if unlocked else ThemeManager.TERMINAL_GRAY)
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(title_lbl)

	var star_row = HBoxContainer.new()
	star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	star_row.add_theme_constant_override("separation", int(2 * ui_scale))
	vb.add_child(star_row)

	if unlocked:
		for i in range(3):
			var s = Label.new()
			s.text = "★" if i < score else "☆"
			s.add_theme_font_size_override("font_size", int(14 * ui_scale))
			if i < score:
				s.add_theme_color_override("font_color", ThemeManager.GATE_XOR_AMBER)
			else:
				s.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
			star_row.add_child(s)
	else:
		var lock_lbl = Label.new()
		lock_lbl.text = "---"
		lock_lbl.add_theme_font_size_override("font_size", int(12 * ui_scale))
		lock_lbl.add_theme_color_override("font_color", ThemeManager.TERMINAL_GRAY)
		star_row.add_child(lock_lbl)

	if unlocked:
		var btn_overlay = Button.new()
		btn_overlay.flat = true
		btn_overlay.anchor_right = 1.0
		btn_overlay.anchor_bottom = 1.0
		btn_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		btn_overlay.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var lvl_id_captured: int = level_id
		btn_overlay.pressed.connect(func() -> void: _launch_level(lvl_id_captured))
		btn_overlay.mouse_entered.connect(func() -> void: _on_card_hover(panel, true))
		btn_overlay.mouse_exited.connect(func() -> void: _on_card_hover(panel, false))
		panel.add_child(btn_overlay)

	return panel

# --- ANIMATIONS ---

func _animate_entrance() -> void:
	var anim = get_node_or_null("/root/AnimHelper")
	if not anim:
		return

	var header: Control = get_node_or_null("MainMargin/MainVBox/HeaderRow")
	if header:
		anim.slide_in_from_top(header, 30.0, 0.4, 0.0)
	var info: Control = get_node_or_null("MainMargin/MainVBox/InfoRow")
	if info:
		anim.slide_in_from_top(info, 20.0, 0.35, 0.1)

	await get_tree().create_timer(0.15).timeout
	for i in range(_level_panels.size()):
		var p = _level_panels[i]
		anim.pop_in(p, 0.3, float(i) * 0.04)

	var bottom: Control = get_node_or_null("MainMargin/MainVBox/BottomRow")
	if bottom:
		anim.slide_in_from_bottom(bottom, 30.0, 0.35, 0.3)

func _on_card_hover(panel: PanelContainer, enter: bool) -> void:
	panel.pivot_offset = panel.size / 2.0
	var tw = panel.create_tween()
	if enter:
		tw.tween_property(panel, "scale", Vector2(1.07, 1.07), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		tw.tween_property(panel, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# --- NAVIGATION ---

func _launch_level(level_id: int) -> void:
	Global.current_level = level_id
	var scene_path = "res://scenes/level_%d.tscn" % level_id
	var sfx = get_node_or_null("/root/SFXManager")
	if sfx and sfx.has_method("play_button_press"):
		sfx.play_button_press()
	var tm = get_node_or_null("/root/TransitionMgr")
	if tm and tm.has_method("transition_to_scene"):
		tm.transition_to_scene(scene_path, false)
	else:
		get_tree().change_scene_to_file(scene_path)

# --- HELPERS ---

func _update_total_stars() -> void:
	if _total_stars_label:
		var total: int = Global.get_total_stars()
		_total_stars_label.text = "★ %d / 60" % total

func _create_thin_line() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = ThemeManager.MIDNIGHT_GRID
	s.content_margin_top = 1
	s.content_margin_bottom = 1
	return s

func _styled_button(text: String, bg_color: Color, ui_scale: float = 1.0) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.custom_minimum_size = Vector2(150 * ui_scale, 40 * ui_scale)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", int(13 * ui_scale))
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_top = int(8 * ui_scale)
	style.content_margin_bottom = int(8 * ui_scale)
	style.content_margin_left = int(12 * ui_scale)
	style.content_margin_right = int(12 * ui_scale)
	btn.add_theme_stylebox_override("normal", style)
	var hover = style.duplicate()
	hover.bg_color = bg_color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed_style = style.duplicate()
	pressed_style.bg_color = bg_color.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	return btn

func _on_logout_pressed() -> void:
	Global.logout()
	var tm = get_node_or_null("/root/TransitionMgr")
	if tm and tm.has_method("transition_to_scene"):
		tm.transition_to_scene("res://scenes/user_profile.tscn", false)
	else:
		get_tree().change_scene_to_file("res://scenes/user_profile.tscn")
