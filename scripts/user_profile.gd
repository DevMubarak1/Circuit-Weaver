extends Control

# Use scene unique names (%) for the new DOB-based age screen
@onready var name_edit = get_node_or_null("%NameEdit")
@onready var month_option: OptionButton = get_node_or_null("%MonthOption")
@onready var day_option: OptionButton = get_node_or_null("%DayOption")
@onready var year_option: OptionButton = get_node_or_null("%YearOption")
@onready var button = get_node_or_null("%Button")

var notification_panel: PanelContainer
var notification_label: Label

const MONTHS := [
	"Month", "January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December"
]

func _ready():
	await get_tree().process_frame

	# Aurora background for visual depth
	ThemeManager.create_aurora_bg(self)

	create_notification_panel()
	_populate_dob_dropdowns()
	_apply_responsive_layout()
	apply_profile_styling()
	
	if button and not button.pressed.is_connected(_on_initialize_button_pressed):
		button.pressed.connect(_on_initialize_button_pressed)
	
	# Entrance animations
	_animate_entrance()

func _populate_dob_dropdowns() -> void:
	# --- MONTH ---
	if month_option:
		month_option.clear()
		for i in range(MONTHS.size()):
			month_option.add_item(MONTHS[i], i)
		month_option.selected = 0  # "Month" placeholder

	# --- DAY ---
	if day_option:
		day_option.clear()
		day_option.add_item("Day", 0)  # Placeholder
		for d in range(1, 32):
			day_option.add_item(str(d), d)
		day_option.selected = 0

	# --- YEAR ---
	if year_option:
		year_option.clear()
		year_option.add_item("Year", 0)  # Placeholder — no preset!
		var current_year: int = Time.get_date_dict_from_system()["year"]
		# Show years from current year down to 1920 — completely neutral
		for y in range(current_year, 1919, -1):
			year_option.add_item(str(y), y)
		year_option.selected = 0

func _calculate_age_from_dob(year: int, month: int, day: int) -> int:
	var now: Dictionary = Time.get_date_dict_from_system()
	var age: int = now["year"] - year
	# If birthday hasn't happened yet this year, subtract 1
	if now["month"] < month or (now["month"] == month and now["day"] < day):
		age -= 1
	return age

func _on_initialize_button_pressed():
	if not name_edit or not month_option or not day_option or not year_option:
		show_notification("Error: UI components missing!", 2.0)
		return
	
	var architect_name = name_edit.text.strip_edges()
	
	if architect_name == "":
		show_notification("Architect Identification Required. Please enter a name.", 2.5)
		return
	
	if architect_name.length() < 3:
		show_notification("Minimum 3 characters required.", 2.5)
		return

	# Validate DOB selections (index 0 = placeholder for all three)
	var month_idx: int = month_option.selected
	var day_idx: int = day_option.selected
	var year_idx: int = year_option.selected

	if month_idx == 0 or day_idx == 0 or year_idx == 0:
		show_notification("Please select your full date of birth.", 2.5)
		return

	var sel_month: int = month_idx  # 1-12
	var sel_day: int = day_option.get_item_id(day_idx)
	var sel_year: int = year_option.get_item_id(year_idx)

	# Basic date validity
	if sel_day > 30 and sel_month in [4, 6, 9, 11]:
		show_notification("Invalid date — that month has only 30 days.", 2.5)
		return
	if sel_month == 2 and sel_day > 29:
		show_notification("Invalid date — February has at most 29 days.", 2.5)
		return

	var architect_age: int = _calculate_age_from_dob(sel_year, sel_month, sel_day)

	if architect_age < 0 or architect_age > 120:
		show_notification("Please enter a valid date of birth.", 2.5)
		return

	Global.user_name = architect_name
	Global.user_age = architect_age
	Global.is_child = architect_age < 13
	Global.save_progress()

	get_tree().call_deferred("change_scene_to_file", "res://scenes/level_select.tscn")

func create_notification_panel() -> void:
	notification_panel = PanelContainer.new()
	notification_panel.name = "NotificationPanel"
	notification_panel.anchor_top = 0.1
	notification_panel.anchor_right = 1.0
	notification_panel.anchor_left = 0.0
	notification_panel.offset_top = 20
	notification_panel.offset_bottom = 80
	notification_panel.visible = false
	
	var warning_style = StyleBoxFlat.new()
	warning_style.bg_color = Color(0.15, 0.08, 0.02, 0.92)  # Deep amber glass
	warning_style.border_width_left = 3
	warning_style.border_width_right = 1
	warning_style.border_width_top = 1
	warning_style.border_width_bottom = 1
	warning_style.border_color = Color(1.0, 0.7, 0.2, 0.8)
	ThemeManager._apply_radius(warning_style, 8)
	warning_style.shadow_color = Color(1.0, 0.6, 0.0, 0.2)
	warning_style.shadow_size = 6
	notification_panel.add_theme_stylebox_override("panel", warning_style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	notification_panel.add_child(margin)
	
	notification_label = Label.new()
	notification_label.text = "Validation Error"
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))  # Amber text on dark
	notification_label.add_theme_font_size_override("font_size", 18)
	margin.add_child(notification_label)
	
	add_child(notification_panel)
	move_child(notification_panel, 1)  # Move after background but before other elements

func show_notification(message: String, duration: float = 2.0) -> void:
	if not notification_panel or not notification_label:
		return
	
	notification_label.text = message
	notification_panel.visible = true
	
	# Slide in from top with bounce
	var anim = get_node_or_null("/root/AnimHelper")
	if anim:
		notification_panel.modulate.a = 0.0
		notification_panel.position.y = -60
		var tw = notification_panel.create_tween().set_parallel(true)
		tw.tween_property(notification_panel, "position:y", 20.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(notification_panel, "modulate:a", 1.0, 0.2)
		await tw.finished
		if not is_inside_tree():
			return
		await get_tree().create_timer(duration).timeout
		if not is_inside_tree():
			return
		var tw_out = notification_panel.create_tween()
		tw_out.tween_property(notification_panel, "modulate:a", 0.0, 0.3)
		await tw_out.finished
	else:
		await get_tree().create_timer(duration).timeout
	if is_inside_tree() and is_instance_valid(notification_panel):
		notification_panel.visible = false

func apply_profile_styling():
	# Guard against multiple styling passes
	if has_meta("profile_styled"):
		return
	
	var title = get_node_or_null("PanelContainer/VBox/Title")
	if title:
		ThemeManager.apply_header_style(title, ThemeManager.SIGNAL_ACTIVE)
	
	var name_label = get_node_or_null("PanelContainer/VBox/NameLabel")
	if name_label:
		ThemeManager.apply_body_style(name_label, ThemeManager.TERMINAL_WHITE)
	
	var age_label = get_node_or_null("PanelContainer/VBox/AgeLabel")
	if age_label:
		ThemeManager.apply_body_style(age_label, ThemeManager.TERMINAL_WHITE)
	
	if name_edit:
		ThemeManager.apply_input_style(name_edit, ThemeManager.SIGNAL_ACTIVE)
	
	# Style DOB dropdowns
	if month_option:
		ThemeManager.apply_input_style(month_option, ThemeManager.SIGNAL_ACTIVE)
	if day_option:
		ThemeManager.apply_input_style(day_option, ThemeManager.SIGNAL_ACTIVE)
	if year_option:
		ThemeManager.apply_input_style(year_option, ThemeManager.SIGNAL_ACTIVE)
	
	if button:
		ThemeManager.apply_button_style(button, ThemeManager.SIGNAL_ACTIVE)
	
	set_meta("profile_styled", true)

func _apply_responsive_layout() -> void:
	var resp = get_node_or_null("/root/ResponsiveManager")
	var ui_scale: float = 1.0
	if resp:
		ui_scale = resp.ui_scale
	else:
		var vp_w: float = get_viewport().get_visible_rect().size.x
		ui_scale = clampf(vp_w / 1280.0, 0.6, 1.3)

	var main_panel = get_node_or_null("Center/MainPanel")
	if main_panel:
		main_panel.custom_minimum_size.x = 450.0 * ui_scale

	var margins = get_node_or_null("Center/MainPanel/Margins")
	if margins:
		var m: int = int(40.0 * ui_scale)
		margins.add_theme_constant_override("margin_left", m)
		margins.add_theme_constant_override("margin_top", m)
		margins.add_theme_constant_override("margin_right", m)
		margins.add_theme_constant_override("margin_bottom", m)

	var title_rs = get_node_or_null("Center/MainPanel/Margins/VBox/Title")
	if title_rs:
		title_rs.add_theme_font_size_override("font_size", int(22.0 * ui_scale))

	if name_edit:
		name_edit.custom_minimum_size.y = 45.0 * ui_scale
		name_edit.add_theme_font_size_override("font_size", int(16.0 * ui_scale))

	# Responsive DOB dropdowns
	var dob_font: int = int(14.0 * ui_scale)
	var dob_height: float = 45.0 * ui_scale
	for opt in [month_option, day_option, year_option]:
		if opt:
			opt.custom_minimum_size.y = dob_height
			opt.add_theme_font_size_override("font_size", dob_font)

	if button:
		button.custom_minimum_size.y = 55.0 * ui_scale
		button.add_theme_font_size_override("font_size", int(16.0 * ui_scale))

	for path in ["Center/MainPanel/Margins/VBox/NameSection/Label", "Center/MainPanel/Margins/VBox/AgeSection/Label"]:
		var lbl = get_node_or_null(path)
		if lbl:
			lbl.add_theme_font_size_override("font_size", int(14.0 * ui_scale))

func _animate_entrance() -> void:
	var anim = get_node_or_null("/root/AnimHelper")
	if not anim:
		return
	# Animate main panel
	var main_panel = get_node_or_null("Center/MainPanel")
	if main_panel:
		anim.pop_in(main_panel, 0.45, 0.1)
	# Animate title
	var title_node = get_node_or_null("Center/MainPanel/Margins/VBox/Title")
	if title_node:
		anim.slide_in_from_top(title_node, 20.0, 0.35, 0.2)
	# Stagger form fields
	var name_section = get_node_or_null("Center/MainPanel/Margins/VBox/NameSection")
	if name_section:
		anim.slide_in_from_left(name_section, 40.0, 0.3, 0.3)
	var age_section = get_node_or_null("Center/MainPanel/Margins/VBox/AgeSection")
	if age_section:
		anim.slide_in_from_left(age_section, 40.0, 0.3, 0.4)
	# Button bounce in
	if button:
		anim.slide_in_from_bottom(button, 30.0, 0.35, 0.5)
