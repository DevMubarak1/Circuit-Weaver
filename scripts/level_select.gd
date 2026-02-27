# Level Select screen — premium glassmorphic chapter grid
# Features: aurora background, chapter-themed cards, animated progress,
# confetti on perfect chapters, glow hover effects, responsive layout
extends Control
class_name LevelSelect

const CHAPTERS: Array[Dictionary] = [
	{"name": "Foundations", "levels": [1,2,3,4,5], "icon": "01", "desc": "Learn the basics"},
	{"name": "Combinations", "levels": [6,7,8,9,10,11,12,13], "icon": "02", "desc": "Combine gates"},
	{"name": "Advanced", "levels": [14,15,16,17], "icon": "03", "desc": "Complex circuits"},
	{"name": "Mastery", "levels": [18,19,20], "icon": "04", "desc": "Final challenges"},
]

var _tab_container: TabContainer
var _total_stars_label: Label
var _header_title: Label
var _welcome_label: Label
var _progress_bar: ProgressBar
var _progress_label: Label
var _level_panels: Array[PanelContainer] = []
# Store styles per-card for hover toggling
var _card_normal_styles: Dictionary = {}
var _card_hover_styles: Dictionary = {}

func _ready() -> void:
	_build_ui()
	await get_tree().process_frame
	_animate_entrance()

func _unhandled_input(event: InputEvent) -> void:
	# Android back button → quit from level select
	if event is InputEventKey and event.pressed and event.keycode == KEY_BACK:
		get_tree().quit()

# ===================================================================
# BUILD UI
# ===================================================================

func _build_ui() -> void:
	var anim = get_node_or_null("/root/AnimHelper")
	var resp = get_node_or_null("/root/ResponsiveManager")
	var ui_scale: float = resp.ui_scale if resp else 1.0
	var vp_size: Vector2 = get_viewport().get_visible_rect().size

	# --- AURORA GRADIENT BACKGROUND ---
	ThemeManager.create_aurora_bg(self)

	# Circuit grid overlay (subtle)
	if anim:
		anim.create_circuit_bg(self)
		# The circuit_bg + vignette already added; adjust opacity
		var circuit_bg = get_node_or_null("BGBase")
		if circuit_bg:
			circuit_bg.modulate.a = 0.3  # Subtle overlay, aurora shows through

	var margin = MarginContainer.new()
	margin.name = "MainMargin"
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", int(32 * ui_scale))
	margin.add_theme_constant_override("margin_right", int(32 * ui_scale))
	margin.add_theme_constant_override("margin_top", int(20 * ui_scale))
	margin.add_theme_constant_override("margin_bottom", int(16 * ui_scale))
	add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.name = "MainVBox"
	vbox.add_theme_constant_override("separation", int(8 * ui_scale))
	margin.add_child(vbox)

	# ===========================================
	# HEADER — Glassmorphic bar with title + stars
	# ===========================================
	var header_panel = PanelContainer.new()
	header_panel.name = "HeaderPanel"
	header_panel.add_theme_stylebox_override("panel", ThemeManager.create_glass_panel(
		Color(0.0, 0.85, 0.85, 1.0), 14, 1
	))
	vbox.add_child(header_panel)

	var header_margin = MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", int(20 * ui_scale))
	header_margin.add_theme_constant_override("margin_right", int(20 * ui_scale))
	header_margin.add_theme_constant_override("margin_top", int(12 * ui_scale))
	header_margin.add_theme_constant_override("margin_bottom", int(12 * ui_scale))
	header_panel.add_child(header_margin)

	var header_row = HBoxContainer.new()
	header_row.name = "HeaderRow"
	header_row.add_theme_constant_override("separation", int(12 * ui_scale))
	header_margin.add_child(header_row)

	# Title with subtle glow
	_header_title = Label.new()
	_header_title.text = "CIRCUIT WEAVER"
	_header_title.add_theme_color_override("font_color", Color(0.0, 0.92, 0.92, 1.0))
	_header_title.add_theme_font_size_override("font_size", int(26 * ui_scale))
	_header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(_header_title)

	# Divider dot
	var dot = Label.new()
	dot.text = "|"
	dot.add_theme_color_override("font_color", ThemeManager.TEXT_DIM)
	dot.add_theme_font_size_override("font_size", int(20 * ui_scale))
	header_row.add_child(dot)

	# Star counter with amber glow
	_total_stars_label = Label.new()
	_total_stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	_total_stars_label.add_theme_font_size_override("font_size", int(16 * ui_scale))
	header_row.add_child(_total_stars_label)
	_update_total_stars()

	# ===========================================
	# INFO ROW — Welcome + Progress
	# ===========================================
	var info_row = HBoxContainer.new()
	info_row.name = "InfoRow"
	info_row.add_theme_constant_override("separation", int(16 * ui_scale))
	vbox.add_child(info_row)

	_welcome_label = Label.new()
	_welcome_label.text = "Welcome back, Architect %s" % Global.user_name
	_welcome_label.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	_welcome_label.add_theme_font_size_override("font_size", int(12 * ui_scale))
	_welcome_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(_welcome_label)

	# Gradient progress bar
	var progress_vbox = VBoxContainer.new()
	progress_vbox.add_theme_constant_override("separation", 3)
	info_row.add_child(progress_vbox)

	var completed_count: int = 0
	for i in range(1, 21):
		if Global.get_level_score(i) > 0:
			completed_count += 1

	_progress_label = Label.new()
	_progress_label.text = "%d / 20 Complete" % completed_count
	_progress_label.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	_progress_label.add_theme_font_size_override("font_size", int(10 * ui_scale))
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress_vbox.add_child(_progress_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0
	_progress_bar.max_value = 20
	_progress_bar.value = 0  # Will animate up
	_progress_bar.custom_minimum_size = Vector2(180 * ui_scale, 6 * ui_scale)
	_progress_bar.show_percentage = false

	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.08, 0.10, 0.15, 0.6)
	ThemeManager._apply_radius(bar_bg, 3)
	_progress_bar.add_theme_stylebox_override("background", bar_bg)

	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.0, 0.7, 0.7, 0.9)
	ThemeManager._apply_radius(bar_fill, 3)
	_progress_bar.add_theme_stylebox_override("fill", bar_fill)
	progress_vbox.add_child(_progress_bar)

	# ===========================================
	# TAB CONTAINER — Chapter tabs with glass styling
	# ===========================================
	_tab_container = TabContainer.new()
	_tab_container.name = "ChapterTabs"
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Tab colors
	_tab_container.add_theme_color_override("font_selected_color", Color(0.0, 0.92, 0.92, 1.0))
	_tab_container.add_theme_color_override("font_unselected_color", ThemeManager.TEXT_MUTED)
	_tab_container.add_theme_color_override("font_hovered_color", Color(0.5, 0.8, 0.8, 1.0))
	_tab_container.add_theme_font_size_override("font_size", int(13 * ui_scale))

	# Glass tab panel
	var tab_panel_style = StyleBoxFlat.new()
	tab_panel_style.bg_color = Color(0.04, 0.05, 0.08, 0.4)
	ThemeManager._apply_radius(tab_panel_style, 0)
	tab_panel_style.corner_radius_bottom_left = 10
	tab_panel_style.corner_radius_bottom_right = 10
	_tab_container.add_theme_stylebox_override("panel", tab_panel_style)
	vbox.add_child(_tab_container)

	for ch_idx in range(CHAPTERS.size()):
		var ch = CHAPTERS[ch_idx]
		var chapter_num: int = ch_idx + 1
		var locked: bool = not Global.is_chapter_unlocked(chapter_num)

		var scroll = ScrollContainer.new()
		scroll.name = ch["name"]
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_tab_container.add_child(scroll)

		# Chapter content wrapper — expand to use full width
		var ch_vbox = VBoxContainer.new()
		ch_vbox.add_theme_constant_override("separation", int(12 * ui_scale))
		ch_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(ch_vbox)

		# Chapter description header
		var ch_header = MarginContainer.new()
		ch_header.add_theme_constant_override("margin_left", int(20 * ui_scale))
		ch_header.add_theme_constant_override("margin_right", int(20 * ui_scale))
		ch_header.add_theme_constant_override("margin_top", int(12 * ui_scale))
		ch_header.add_theme_constant_override("margin_bottom", int(4 * ui_scale))
		ch_vbox.add_child(ch_header)

		var ch_info = HBoxContainer.new()
		ch_info.add_theme_constant_override("separation", int(12 * ui_scale))
		ch_header.add_child(ch_info)

		# Chapter number badge
		var badge = Label.new()
		badge.text = ch["icon"]
		badge.add_theme_font_size_override("font_size", int(22 * ui_scale))
		var ch_accent = ThemeManager.get_chapter_accent(chapter_num)
		badge.add_theme_color_override("font_color", ch_accent)
		ch_info.add_child(badge)

		var ch_text_vbox = VBoxContainer.new()
		ch_text_vbox.add_theme_constant_override("separation", 1)
		ch_text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ch_info.add_child(ch_text_vbox)

		var ch_title = Label.new()
		ch_title.text = ch["name"].to_upper()
		ch_title.add_theme_font_size_override("font_size", int(14 * ui_scale))
		ch_title.add_theme_color_override("font_color", ch_accent)
		ch_text_vbox.add_child(ch_title)

		var ch_desc = Label.new()
		ch_desc.text = ch["desc"] if not locked else "Complete previous chapter to unlock"
		ch_desc.add_theme_font_size_override("font_size", int(10 * ui_scale))
		ch_desc.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED if not locked else ThemeManager.TEXT_DIM)
		ch_text_vbox.add_child(ch_desc)

		# Chapter star count
		var ch_stars = _get_chapter_stars(chapter_num)
		var ch_max = ch["levels"].size() * 3
		var ch_star_lbl = Label.new()
		ch_star_lbl.text = "★ %d/%d" % [ch_stars, ch_max]
		ch_star_lbl.add_theme_font_size_override("font_size", int(12 * ui_scale))
		ch_star_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 0.8) if ch_stars > 0 else ThemeManager.TEXT_DIM)
		ch_info.add_child(ch_star_lbl)

		# Thin divider
		var ch_div = ThemeManager.create_glow_divider(ch_accent, 500.0 * ui_scale)
		ch_div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ch_vbox.add_child(ch_div)

		# Level grid — expand to fill screen width
		var grid_margin = MarginContainer.new()
		grid_margin.add_theme_constant_override("margin_left", int(16 * ui_scale))
		grid_margin.add_theme_constant_override("margin_right", int(16 * ui_scale))
		grid_margin.add_theme_constant_override("margin_top", int(8 * ui_scale))
		grid_margin.add_theme_constant_override("margin_bottom", int(16 * ui_scale))
		grid_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ch_vbox.add_child(grid_margin)

		var grid = GridContainer.new()
		grid.name = "Grid"
		# Use more columns on wide screens so content fills the area
		var is_mobile: bool = resp and resp.is_mobile()
		if is_mobile:
			grid.columns = 3
		else:
			var avail_w: float = vp_size.x - 64.0 * ui_scale  # minus margins
			grid.columns = clampi(int(avail_w / (140.0 * ui_scale)), 5, 8)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", int(12 * ui_scale))
		grid.add_theme_constant_override("v_separation", int(12 * ui_scale))
		grid_margin.add_child(grid)

		for level_id in ch["levels"]:
			var panel = _create_level_card(level_id, chapter_num, locked, ui_scale)
			grid.add_child(panel)
			_level_panels.append(panel)

	# ===========================================
	# ACHIEVEMENTS TAB — Trophy showcase
	# ===========================================
	_build_achievements_tab(ui_scale)

	# ===========================================
	# BOTTOM BUTTONS — Premium styled
	# ===========================================
	var bottom = HBoxContainer.new()
	bottom.name = "BottomRow"
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", int(16 * ui_scale))
	vbox.add_child(bottom)

	var quit_btn = Button.new()
	quit_btn.text = "QUIT GAME"
	ThemeManager.create_danger_button(quit_btn, int(12 * ui_scale), Vector2(140 * ui_scale, 38 * ui_scale))
	quit_btn.pressed.connect(func() -> void: get_tree().quit())
	bottom.add_child(quit_btn)

	var logout_btn = Button.new()
	logout_btn.text = "LOG OUT"
	ThemeManager.create_premium_button(logout_btn, Color(0.6, 0.45, 0.1), int(12 * ui_scale), Vector2(140 * ui_scale, 38 * ui_scale))
	logout_btn.pressed.connect(_on_logout_pressed)
	bottom.add_child(logout_btn)

	_setup_bottom_hovers.call_deferred(quit_btn, logout_btn)

func _setup_bottom_hovers(b1: Button, b2: Button) -> void:
	var anim = get_node_or_null("/root/AnimHelper")
	if anim:
		anim.setup_button_hover(b1, 1.05)
		anim.setup_button_hover(b2, 1.05)

# ===================================================================
# ACHIEVEMENTS TAB — Glassmorphic trophy grid
# ===================================================================

func _build_achievements_tab(ui_scale: float) -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var resp = get_node_or_null("/root/ResponsiveManager")
	var scroll = ScrollContainer.new()
	scroll.name = "Achievements"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tab_container.add_child(scroll)

	var ach_vbox = VBoxContainer.new()
	ach_vbox.add_theme_constant_override("separation", int(12 * ui_scale))
	ach_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(ach_vbox)

	# Header row
	var ach_header = MarginContainer.new()
	ach_header.add_theme_constant_override("margin_left", int(20 * ui_scale))
	ach_header.add_theme_constant_override("margin_right", int(20 * ui_scale))
	ach_header.add_theme_constant_override("margin_top", int(12 * ui_scale))
	ach_header.add_theme_constant_override("margin_bottom", int(4 * ui_scale))
	ach_vbox.add_child(ach_header)

	var ach_info = HBoxContainer.new()
	ach_info.add_theme_constant_override("separation", int(12 * ui_scale))
	ach_header.add_child(ach_info)

	var trophy_icon = Label.new()
	trophy_icon.text = "🏆"
	trophy_icon.add_theme_font_size_override("font_size", int(22 * ui_scale))
	trophy_icon.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	ach_info.add_child(trophy_icon)

	var ach_text_vbox = VBoxContainer.new()
	ach_text_vbox.add_theme_constant_override("separation", 1)
	ach_text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ach_info.add_child(ach_text_vbox)

	var ach_title = Label.new()
	ach_title.text = "ACHIEVEMENTS"
	ach_title.add_theme_font_size_override("font_size", int(14 * ui_scale))
	ach_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	ach_text_vbox.add_child(ach_title)

	var unlocked_count: int = Global.get_unlocked_count()
	var total_count: int = Global.ACHIEVEMENT_DEFS.size()
	var ach_subtitle = Label.new()
	ach_subtitle.text = "%d / %d Unlocked" % [unlocked_count, total_count]
	ach_subtitle.add_theme_font_size_override("font_size", int(10 * ui_scale))
	ach_subtitle.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	ach_text_vbox.add_child(ach_subtitle)

	# Divider
	var ach_div = ThemeManager.create_glow_divider(Color(1.0, 0.85, 0.2, 0.7), 500.0 * ui_scale)
	ach_div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ach_vbox.add_child(ach_div)

	# Achievement grid — expand to fill width
	var grid_margin = MarginContainer.new()
	grid_margin.add_theme_constant_override("margin_left", int(16 * ui_scale))
	grid_margin.add_theme_constant_override("margin_right", int(16 * ui_scale))
	grid_margin.add_theme_constant_override("margin_top", int(8 * ui_scale))
	grid_margin.add_theme_constant_override("margin_bottom", int(16 * ui_scale))
	grid_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ach_vbox.add_child(grid_margin)

	var is_mobile: bool = resp and resp.is_mobile()
	var grid = GridContainer.new()
	if is_mobile:
		grid.columns = 2
	else:
		var avail_w: float = vp_size.x - 64.0 * ui_scale
		grid.columns = clampi(int(avail_w / (200.0 * ui_scale)), 3, 6)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", int(10 * ui_scale))
	grid.add_theme_constant_override("v_separation", int(10 * ui_scale))
	grid_margin.add_child(grid)

	for ach_id in Global.ACHIEVEMENT_DEFS:
		var def: Dictionary = Global.ACHIEVEMENT_DEFS[ach_id]
		var unlocked: bool = Global.has_achievement(ach_id)
		var card = _create_achievement_card(ach_id, def, unlocked, ui_scale)
		grid.add_child(card)

# ===================================================================
# ACHIEVEMENT CARD — Glassmorphic badge
# ===================================================================

func _create_achievement_card(ach_id: String, def: Dictionary, unlocked: bool, ui_scale: float) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.name = "Ach_%s" % ach_id
	panel.custom_minimum_size = Vector2(180 * ui_scale, 80 * ui_scale)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style = StyleBoxFlat.new()
	if unlocked:
		style.bg_color = Color(0.08, 0.12, 0.06, 0.6)
		style.border_color = Color(0.3, 0.7, 0.2, 0.5)
	else:
		style.bg_color = Color(0.06, 0.06, 0.08, 0.4)
		style.border_color = Color(0.2, 0.2, 0.25, 0.3)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	ThemeManager._apply_radius(style, 8)
	panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", int(10 * ui_scale))
	margin.add_theme_constant_override("margin_right", int(10 * ui_scale))
	margin.add_theme_constant_override("margin_top", int(8 * ui_scale))
	margin.add_theme_constant_override("margin_bottom", int(8 * ui_scale))
	panel.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", int(8 * ui_scale))
	margin.add_child(hbox)

	# Badge icon
	var icon_lbl = Label.new()
	if unlocked:
		icon_lbl.text = "★"
		icon_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	else:
		icon_lbl.text = "☆"
		icon_lbl.add_theme_color_override("font_color", ThemeManager.TEXT_DIM)
	icon_lbl.add_theme_font_size_override("font_size", int(20 * ui_scale))
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_lbl)

	# Text column
	var text_vbox = VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 2)
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)

	var title_lbl = Label.new()
	title_lbl.text = def.get("title", ach_id.to_upper())
	title_lbl.add_theme_font_size_override("font_size", int(11 * ui_scale))
	if unlocked:
		title_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.3, 1.0))
	else:
		title_lbl.add_theme_color_override("font_color", ThemeManager.TEXT_DIM)
	text_vbox.add_child(title_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = def.get("desc", "")
	desc_lbl.add_theme_font_size_override("font_size", int(9 * ui_scale))
	desc_lbl.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED if unlocked else ThemeManager.TEXT_DIM)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_vbox.add_child(desc_lbl)

	return panel

# ===================================================================
# LEVEL CARD — Chapter-themed glassmorphic card
# ===================================================================

func _create_level_card(level_id: int, chapter: int, chapter_locked: bool, ui_scale: float) -> PanelContainer:
	var unlocked: bool = Global.is_level_unlocked(level_id) and not chapter_locked
	var score: int = Global.get_level_score(level_id)
	var data: Dictionary = LevelConfig.get_level(level_id)
	var title_text: String = data.get("title", "Level %d" % level_id)
	var ch_accent = ThemeManager.get_chapter_accent(chapter)

	var panel = PanelContainer.new()
	panel.name = "Level%d" % level_id
	panel.custom_minimum_size = Vector2(130 * ui_scale, 100 * ui_scale)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Chapter-themed card style with completion state
	var normal_style = ThemeManager.create_level_card_style(chapter, unlocked, score)
	panel.add_theme_stylebox_override("panel", normal_style)

	# Store for hover toggling
	_card_normal_styles[level_id] = normal_style
	if unlocked:
		_card_hover_styles[level_id] = ThemeManager.create_level_card_hover(chapter)

	# Card content
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", int(4 * ui_scale))
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vb)

	# Level number — large, chapter-colored
	var num_lbl = Label.new()
	num_lbl.text = "%02d" % level_id
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lbl.add_theme_font_size_override("font_size", int(22 * ui_scale))
	if unlocked:
		num_lbl.add_theme_color_override("font_color", ch_accent)
	else:
		num_lbl.add_theme_color_override("font_color", ThemeManager.TEXT_DIM)
	vb.add_child(num_lbl)

	# Title
	var title_lbl = Label.new()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", int(9 * ui_scale))
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	if unlocked:
		title_lbl.text = title_text
		title_lbl.add_theme_color_override("font_color", ThemeManager.TERMINAL_WHITE)
	else:
		title_lbl.text = "LOCKED"
		title_lbl.add_theme_color_override("font_color", ThemeManager.TEXT_DIM)
	vb.add_child(title_lbl)

	# Stars row
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
				s.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
			else:
				s.add_theme_color_override("font_color", ThemeManager.TEXT_DIM)
			star_row.add_child(s)
	else:
		var lock_icon = Label.new()
		lock_icon.text = "---"
		lock_icon.add_theme_font_size_override("font_size", int(11 * ui_scale))
		lock_icon.add_theme_color_override("font_color", ThemeManager.TEXT_DIM)
		star_row.add_child(lock_icon)

	# Clickable overlay with enhanced hover
	if unlocked:
		var btn_overlay = Button.new()
		btn_overlay.flat = true
		btn_overlay.anchor_right = 1.0
		btn_overlay.anchor_bottom = 1.0
		btn_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		btn_overlay.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		var lvl = level_id
		btn_overlay.pressed.connect(func() -> void: _launch_level(lvl))
		btn_overlay.mouse_entered.connect(func() -> void: _on_card_hover_enter(panel, lvl))
		btn_overlay.mouse_exited.connect(func() -> void: _on_card_hover_exit(panel, lvl))
		panel.add_child(btn_overlay)

	return panel

# ===================================================================
# ANIMATIONS
# ===================================================================

func _animate_entrance() -> void:
	var anim = get_node_or_null("/root/AnimHelper")
	if not anim:
		return

	# Header slide down
	var header_panel: Control = get_node_or_null("MainMargin/MainVBox/HeaderPanel")
	if header_panel:
		anim.slide_in_from_top(header_panel, 35.0, 0.45, 0.0)

	var info: Control = get_node_or_null("MainMargin/MainVBox/InfoRow")
	if info:
		anim.fade_in(info, 0.35, 0.15)

	# Animated progress bar fill
	var completed_count: int = 0
	for i in range(1, 21):
		if Global.get_level_score(i) > 0:
			completed_count += 1
	if anim and _progress_bar:
		anim.animate_progress(_progress_bar, float(completed_count), 0.8)

	# Stagger level cards with pop-in
	await get_tree().create_timer(0.2).timeout
	for i in range(_level_panels.size()):
		var p = _level_panels[i]
		anim.pop_in(p, 0.28, float(i) * 0.035)

	# Bottom buttons slide up
	var bottom: Control = get_node_or_null("MainMargin/MainVBox/BottomRow")
	if bottom:
		anim.slide_in_from_bottom(bottom, 25.0, 0.35, 0.4)

	# Glow the title
	if anim and _header_title:
		anim.glow_text(_header_title, Color(0.0, 0.85, 0.85, 1.0), 1.3)

func _on_card_hover_enter(panel: PanelContainer, level_id: int) -> void:
	if _card_hover_styles.has(level_id):
		var anim = get_node_or_null("/root/AnimHelper")
		if anim:
			anim.card_hover_enter(panel, _card_hover_styles[level_id], 1.06)
		else:
			panel.add_theme_stylebox_override("panel", _card_hover_styles[level_id])

func _on_card_hover_exit(panel: PanelContainer, level_id: int) -> void:
	if _card_normal_styles.has(level_id):
		var anim = get_node_or_null("/root/AnimHelper")
		if anim:
			anim.card_hover_exit(panel, _card_normal_styles[level_id])
		else:
			panel.add_theme_stylebox_override("panel", _card_normal_styles[level_id])

# ===================================================================
# NAVIGATION
# ===================================================================

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
		get_tree().call_deferred("change_scene_to_file", scene_path)

# ===================================================================
# HELPERS
# ===================================================================

func _update_total_stars() -> void:
	if _total_stars_label:
		var total: int = Global.get_total_stars()
		_total_stars_label.text = "★ %d / 60" % total

func _get_chapter_stars(chapter: int) -> int:
	var ch = CHAPTERS[chapter - 1]
	var total: int = 0
	for lvl in ch["levels"]:
		total += Global.get_level_score(lvl)
	return total

func _on_logout_pressed() -> void:
	Global.logout()
	var tm = get_node_or_null("/root/TransitionMgr")
	if tm and tm.has_method("transition_to_scene"):
		tm.transition_to_scene("res://scenes/user_profile.tscn", false)
	else:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/user_profile.tscn")
