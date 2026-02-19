# Data-driven Level Manager — loads any level from LevelConfig
extends Node2D
class_name LevelManager

# Gate icon paths for the toolbox
const GATE_ICON_PATHS: Dictionary = {
	"AND": "res://assets/AND_ANSI.svg",
	"OR": "res://assets/OR_ANSI.svg",
	"NOT": "res://assets/NOT_ANSI.svg",
	"XOR": "res://assets/XOR_ANSI.svg",
	"NAND": "res://assets/NAND_ANSI.svg",
	"NOR": "res://assets/NOR_ANSI.svg",
	"XNOR": "res://assets/XNOR_ANSI.svg"
}

# Node references
var circuit_board: CircuitBoard
var header_label: Label
var welcome_label: Label
var gate_toolbox: VBoxContainer
var board_area: Control
var level_complete_panel: PanelContainer
var level_complete_label: Label

# Current level data (from LevelConfig)
var level_data: Dictionary = {}
var current_level_id: int = 1

# Level state
var level_started: bool = false
var level_complete: bool = false
var gates_placed: int = 0
var undo_system = preload("res://scripts/undo_redo_system.gd").new()

# Tutorial state machine
var tutorial_step: int = 0
var tutorial_panel: PanelContainer = null
var run_button: Button = null
var gates_placed_in_tutorial: int = 0
var wires_connected: int = 0

var _tutorial_title_label: Label = null
var _tutorial_step_label: Label = null
var _tutorial_continue_btn: Button = null
var _tutorial_bot_image: TextureRect = null
var _panel_position: String = "center"
var _settings_panel: PanelContainer = null
var _good_luck_active: bool = false
var _good_luck_timer: Timer = null
var _tutorial_complete: bool = false

func _ready() -> void:
	current_level_id = Global.current_level
	level_data = LevelConfig.get_level(current_level_id)
	
	if level_data.is_empty():
		return
	
	await get_tree().process_frame
	
	circuit_board = get_node_or_null("CircuitBoard") as CircuitBoard
	header_label = get_node_or_null("CanvasLayer/MainUI/HBoxContainer/Sidebar/SidebarMargin/SidebarVBox/HeaderLabel") as Label
	welcome_label = get_node_or_null("CanvasLayer/MainUI/HBoxContainer/Sidebar/SidebarMargin/SidebarVBox/WelcomeLabel") as Label
	gate_toolbox = get_node_or_null("CanvasLayer/MainUI/HBoxContainer/Sidebar/SidebarMargin/SidebarVBox/ScrollContainer/GateToolbox") as VBoxContainer
	board_area = get_node_or_null("CanvasLayer/MainUI/HBoxContainer/BoardArea") as Control
	
	if not circuit_board:
		return
	if not header_label or not welcome_label or not gate_toolbox or not board_area:
		return
	
	if board_area is BoardDropZone:
		board_area.circuit_board = circuit_board
	
	load_architect_profile()
	apply_level_theme()
	setup_level()

	undo_system.init(circuit_board)

	var music = get_node_or_null("/root/MusicManager")
	if music:
		music.start_music()

	_apply_responsive_layout()
	var resp = get_node_or_null("/root/ResponsiveManager")
	if resp:
		resp.layout_changed.connect(_on_layout_changed)
	
	# Animate sidebar entrance
	_animate_level_entrance()


# --- LEVEL SETUP ---

func setup_level() -> void:
	var title = level_data.get("title", "Level %d" % current_level_id)
	
	var allowed: Array = level_data.get("allowed_gates", [])
	var allowed_typed: Array[String] = []
	for g in allowed:
		allowed_typed.append(str(g))
	setup_gate_toolbox(allowed_typed)
	
	setup_circuit_board()
	
	var inputs: Array = level_data.get("inputs", [])
	for input_def in inputs:
		var input_name: String = input_def["name"]
		var col: int = input_def["col"]
		var row: int = input_def["row"]
		var seq: Array = input_def["sequence"]
		
		var input_node = circuit_board.place_input_node(input_name, col, row)
		if input_node:
			var typed_seq: Array[int] = []
			for v in seq:
				typed_seq.append(int(v))
			input_node.set_binary_sequence(typed_seq)
	
	var outputs: Array = level_data.get("outputs", [])
	for output_def in outputs:
		var output_name: String = output_def["name"]
		var col: int = output_def["col"]
		var row: int = output_def["row"]
		var target: Array = output_def["target"]
		
		var output_node = circuit_board.place_output_node(output_name, col, row)
		if output_node:
			var typed_target: PackedInt32Array = PackedInt32Array()
			for v in target:
				typed_target.append(int(v))
			output_node.set_target_sequence(typed_target)
			
			if not output_node.value_received.is_connected(_on_output_signal_received):
				output_node.value_received.connect(_on_output_signal_received)
	
	start_tutorial()
	level_started = true

# --- PROFILE & THEME ---

func load_architect_profile() -> void:
	if Global.user_name == "" or Global.user_name == "Guest":
		var config := ConfigFile.new()
		var err := config.load(Global.SAVE_PATH)
		if err == OK:
			Global.user_name = config.get_value("Architect", "name", "Guest")
			Global.user_age = config.get_value("Architect", "age", 0)
		else:
			Global.user_name = "Guest"
			Global.user_age = 0
	
	welcome_label.text = "WELCOME, ARCHITECT %s (AGE %d)" % [Global.user_name.to_upper(), Global.user_age]
	header_label.text = "CIRCUIT WEAVER - LEVEL %d" % current_level_id

func apply_level_theme() -> void:
	var resp = get_node_or_null("/root/ResponsiveManager")
	var ui_scale: float = resp.ui_scale if resp else 1.0

	var sidebar = get_node_or_null("CanvasLayer/MainUI/HBoxContainer/Sidebar") as PanelContainer
	if sidebar:
		var sidebar_style = ThemeManager.create_panel_style(
			ThemeManager.SIGNAL_ACTIVE,
			ThemeManager.MIDNIGHT_GRID
		)
		sidebar.add_theme_stylebox_override("panel", sidebar_style)
		var sw: float = resp.sidebar_width if resp else 250.0
		sidebar.custom_minimum_size = Vector2(sw, 0)

	header_label.add_theme_color_override("font_color", ThemeManager.SIGNAL_ACTIVE)
	header_label.add_theme_font_size_override("font_size", int(16 * ui_scale))
	welcome_label.add_theme_color_override("font_color", ThemeManager.TERMINAL_WHITE)
	welcome_label.add_theme_font_size_override("font_size", int(12 * ui_scale))

	var toolbox_title = get_node_or_null("CanvasLayer/MainUI/HBoxContainer/Sidebar/SidebarMargin/SidebarVBox/ToolboxTitle") as Label
	if toolbox_title:
		toolbox_title.add_theme_color_override("font_color", ThemeManager.GATE_OR_GREEN)
		toolbox_title.add_theme_font_size_override("font_size", int(14 * ui_scale))

	var sidebar_margin = get_node_or_null("CanvasLayer/MainUI/HBoxContainer/Sidebar/SidebarMargin") as MarginContainer
	if sidebar_margin and resp:
		var m: int = resp.get_margin(12)
		sidebar_margin.add_theme_constant_override("margin_left", m)
		sidebar_margin.add_theme_constant_override("margin_right", m)
		sidebar_margin.add_theme_constant_override("margin_top", m)
		sidebar_margin.add_theme_constant_override("margin_bottom", m)

# --- TOOLBOX & CIRCUIT BOARD SETUP ---

func setup_gate_toolbox(allowed_gates: Array[String]) -> void:
	var resp = get_node_or_null("/root/ResponsiveManager")
	var ui_scale: float = resp.ui_scale if resp else 1.0
	var icon_size: float = 60.0 * ui_scale

	for gate_type in allowed_gates:
		var wrapper = VBoxContainer.new()
		wrapper.name = gate_type + "Wrapper"
		wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
		wrapper.add_theme_constant_override("separation", int(2 * ui_scale))
		
		var gate_icon = GateIcon.new()
		gate_icon.gate_type = gate_type
		gate_icon.name = gate_type + "Icon"
		gate_icon.self_modulate = ThemeManager.get_gate_color(gate_type)
		gate_icon.custom_minimum_size = Vector2(icon_size, icon_size)
		wrapper.add_child(gate_icon)
		
		var gate_label = Label.new()
		gate_label.text = gate_type
		gate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gate_label.add_theme_color_override("font_color", ThemeManager.SIGNAL_ACTIVE)
		gate_label.add_theme_font_size_override("font_size", int(11 * ui_scale))
		wrapper.add_child(gate_label)
		
		gate_toolbox.add_child(wrapper)
		gate_icon.gate_clicked.connect(_on_gate_icon_clicked)
		# Hover scale animation on gate icon wrapper
		wrapper.mouse_filter = Control.MOUSE_FILTER_STOP
		var w_ref = wrapper
		wrapper.mouse_entered.connect(func() -> void:
			w_ref.pivot_offset = w_ref.size / 2.0
			var tw_h = w_ref.create_tween()
			tw_h.tween_property(w_ref, "scale", Vector2(1.12, 1.12), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)
		wrapper.mouse_exited.connect(func() -> void:
			var tw_h = w_ref.create_tween()
			tw_h.tween_property(w_ref, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)

func setup_circuit_board() -> void:
	if circuit_board and not circuit_board.gate_placed.is_connected(_on_gate_placed):
		circuit_board.gate_placed.connect(_on_gate_placed)
	if circuit_board and not circuit_board.wire_connected.is_connected(_on_wire_connected):
		circuit_board.wire_connected.connect(_on_wire_connected)
	circuit_board.set_process_unhandled_input(true)

# --- SIGNAL HANDLERS ---

func _on_gate_icon_clicked(_gate_type_clicked: String) -> void:
	if _tutorial_complete:
		return  # Normal play — no tutorial action needed
	var steps = _get_tutorial_steps()
	if steps.size() >= 6 and tutorial_step == 2:
		_highlight_toolbox(false)
		advance_tutorial()

func _on_gate_placed(_gate_type: String, _gate: LogicGate) -> void:
	gates_placed += 1
	gates_placed_in_tutorial += 1
	undo_system.record_place_gate(_gate)
	# Gate drop animation
	var anim = get_node_or_null("/root/AnimHelper")
	if anim and _gate:
		_gate.scale = Vector2(1.4, 1.4)
		_gate.modulate.a = 0.5
		var tw = _gate.create_tween().set_parallel(true)
		tw.tween_property(_gate, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(_gate, "modulate:a", 1.0, 0.15)
	if not _tutorial_complete and _get_tutorial_steps().size() >= 6 and tutorial_step == 3:
		await get_tree().create_timer(0.3).timeout
		_highlight_toolbox(false)
		advance_tutorial()

func _on_wire_connected(_wire: Wire) -> void:
	wires_connected += 1
	undo_system.record_connect_wire(_wire)
	# Wire connection flash animation
	var anim = get_node_or_null("/root/AnimHelper")
	if anim and _wire:
		anim.flash_wire(_wire, Color(0.0, 2.5, 2.5, 1.0), 0.4)
	var sfx = get_node_or_null("/root/SFXManager")
	if sfx and sfx.has_method("play_wire_click"):
		pass  # Already handled in circuit_board
	var min_wires: int = level_data.get("min_wires", 2)
	if not _tutorial_complete and _get_tutorial_steps().size() >= 6 and tutorial_step == 4 and wires_connected >= min_wires:
		await get_tree().create_timer(0.3).timeout
		advance_tutorial()

func _unhandled_input(event: InputEvent) -> void:
	# Dismiss GOOD LUCK tutorial on any click or key press
	if _good_luck_active:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			_dismiss_good_luck()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed and event.keycode == KEY_Z:
			if event.shift_pressed:
				undo_system.redo()
			else:
				undo_system.undo()
			get_viewport().set_input_as_handled()
		elif event.ctrl_pressed and event.keycode == KEY_Y:
			undo_system.redo()
			get_viewport().set_input_as_handled()

func _on_output_signal_received(_value: int, output_node: OutputNode) -> void:
	if level_complete:
		return
	if not output_node.is_correct:
		var sfx = get_node_or_null("/root/SFXManager")
		if sfx:
			sfx.play_error_buzz()
			sfx.apply_screen_shake(6.0, 0.3)
		# Error shake animation on the output node
		var anim = get_node_or_null("/root/AnimHelper")
		if anim:
			anim.shake(output_node, 6.0, 0.3)
		output_node.modulate = ThemeManager.ACCENT_WARNING
		await get_tree().create_timer(0.5).timeout
		output_node.modulate = Color.WHITE
		return
	# Correct output — green pulse
	var anim_ok = get_node_or_null("/root/AnimHelper")
	if anim_ok:
		anim_ok.pulse_glow(output_node, ThemeManager.GATE_OR_GREEN, 2)
	var all_complete: bool = true
	for out in circuit_board.output_nodes:
		if out.received_sequence.size() < out.target_sequence.size():
			all_complete = false
			break
		if not out.is_correct:
			all_complete = false
			break
	if all_complete:
		evaluate_level_performance()

# --- SIMULATION ---

func run_simulation() -> void:
	if not level_started or level_complete:
		return
	if circuit_board and circuit_board.wires.is_empty():
		# No wires connected — nothing to simulate
		var sfx = get_node_or_null("/root/SFXManager")
		if sfx:
			sfx.play_error_buzz()
		return
	
	var sfx = get_node_or_null("/root/SFXManager")
	if sfx:
		sfx.play_simulation_hum(1.0)
	await circuit_board.start_simulation()
	if sfx:
		sfx.play_simulation_hum(1.5)
	await get_tree().create_timer(1.0).timeout
	if sfx:
		sfx.stop_simulation_hum()

# --- SCORING & LEVEL COMPLETION ---

func evaluate_level_performance() -> void:
	if level_complete:
		return
	level_complete = true
	var max_gates: int = level_data.get("max_gates", 1)
	# Use live gate count for scoring — not cumulative placements
	var actual_gates: int = circuit_board.gates.size() if circuit_board else gates_placed
	var score = 1
	
	if actual_gates <= max_gates:
		score = 3
	elif actual_gates <= max_gates + 1:
		score = 2
	else:
		score = 1
	
	Global.complete_level(current_level_id, score)
	Global.save_progress()
	var sfx = get_node_or_null("/root/SFXManager")
	if sfx:
		sfx.play_victory_fanfare(score)
		sfx.apply_screen_shake(3.0, 0.2)
	show_level_complete_panel(score)

func proceed_to_next_level() -> void:
	var next_level = current_level_id + 1
	if next_level <= LevelConfig.get_total_levels():
		Global.current_level = next_level
		var scene_path = "res://scenes/level_%d.tscn" % next_level

		# Detect chapter change for a heavier glitch transition
		var cur_chapter: int = level_data.get("chapter", 1)
		var next_data: Dictionary = LevelConfig.get_level(next_level)
		var next_chapter: int = next_data.get("chapter", cur_chapter)
		var is_chapter_change: bool = next_chapter != cur_chapter

		if is_chapter_change:
			var music_mgr = get_node_or_null("/root/MusicManager")
			if music_mgr:
				music_mgr.set_chapter(next_chapter)

		var tm = get_node_or_null("/root/TransitionMgr")
		if tm and tm.has_method("transition_to_scene"):
			tm.transition_to_scene(scene_path, is_chapter_change)
		else:
			get_tree().change_scene_to_file(scene_path)
	else:
		show_graduation_screen()

func show_graduation_screen() -> void:
	if not level_complete_panel:
		create_level_complete_panel()
	
	var total_stars = 0
	for i in range(1, 21):
		total_stars += Global.get_level_score(i)
	
	level_complete_label.text = "━━━━━━━━━━━━━━━━━━━━━━━━━━\nGRADUATION COMPLETE!\n━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n★★★\n\nCongratulations, Architect %s!\nYou have mastered all 20 levels.\n\nTotal Stars: %d / 60\nAll 7 logic gates conquered.\n\nYou are a certified Circuit Architect!" % [Global.user_name, total_stars]
	level_complete_panel.visible = true
	
	# Hide Next Level button, keep Share
	var next_btn = level_complete_panel.get_node_or_null("Margin/VBox/ButtonRow/NextLevelBtn")
	if next_btn:
		next_btn.text = "MAIN MENU"

	# Grand celebration animation
	var anim = get_node_or_null("/root/AnimHelper")
	if anim:
		level_complete_panel.modulate.a = 0.0
		level_complete_panel.pivot_offset = level_complete_panel.size / 2.0
		level_complete_panel.scale = Vector2(0.7, 0.7)
		var tw = level_complete_panel.create_tween().set_parallel(true)
		tw.tween_property(level_complete_panel, "modulate:a", 1.0, 0.5)
		tw.tween_property(level_complete_panel, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tw.finished
		var vp_size = get_viewport().get_visible_rect().size
		var center = vp_size / 2.0
		# Multiple particle bursts
		anim.spawn_particles(level_complete_panel, center + Vector2(-80, -50), ThemeManager.GATE_XOR_AMBER, 20)
		anim.spawn_particles(level_complete_panel, center + Vector2(80, -50), ThemeManager.SIGNAL_ACTIVE, 20)
		anim.spawn_particles(level_complete_panel, center, ThemeManager.GATE_OR_GREEN, 30)
		# Big star celebration
		anim.celebrate_stars(level_complete_panel, 3, center - Vector2(0, 60), 64.0)

# --- LEVEL COMPLETE PANEL ---

var _result_stars: int = 0

func show_level_complete_panel(stars: int) -> void:
	_result_stars = stars
	if not level_complete_panel:
		create_level_complete_panel()
	
	var star_display := ""
	for i in range(3):
		if i < stars:
			star_display += "★"
		else:
			star_display += "☆"
	
	var title = level_data.get("title", "Level %d" % current_level_id)
	var formula = level_data.get("formula", "")
	var max_gates: int = level_data.get("max_gates", 1)
	
	var grade_text = ""
	match stars:
		3: grade_text = "PERFECT SCORE!"
		2: grade_text = "GREAT JOB!"
		1: grade_text = "PASSED!"
	
	var result_text = ""
	result_text += "━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
	result_text += "LEVEL %d COMPLETE\n" % current_level_id
	result_text += "%s\n" % title
	result_text += "━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
	result_text += "%s\n\n" % star_display
	result_text += "%s\n\n" % grade_text
	result_text += "Formula: %s\n" % formula
	result_text += "Gates Used: %d / %d\n" % [gates_placed, max_gates]
	result_text += "Wires Used: %d\n\n" % wires_connected
	result_text += "Architect: %s" % Global.user_name
	
	level_complete_label.text = result_text
	level_complete_panel.visible = true
	
	var next_btn = level_complete_panel.get_node_or_null("Margin/VBox/ButtonRow/NextLevelBtn")
	if next_btn:
		var next_level = current_level_id + 1
		if next_level <= LevelConfig.get_total_levels():
			var next_data = LevelConfig.get_level(next_level)
			next_btn.text = "NEXT LEVEL  ▶"
			next_btn.tooltip_text = next_data.get("title", "Level %d" % next_level)
		else:
			next_btn.text = "GRADUATE"
	
	level_complete_panel.modulate.a = 0.0
	var anim = get_node_or_null("/root/AnimHelper")
	if anim:
		# Dramatic entrance: scale pop from center
		level_complete_panel.pivot_offset = level_complete_panel.size / 2.0
		level_complete_panel.scale = Vector2(0.85, 0.85)
		var tw = level_complete_panel.create_tween().set_parallel(true)
		tw.tween_property(level_complete_panel, "modulate:a", 1.0, 0.4)
		tw.tween_property(level_complete_panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tw.finished
		# Star celebration burst from center
		var vp_size = get_viewport().get_visible_rect().size
		var center = vp_size / 2.0
		anim.celebrate_stars(level_complete_panel, stars, center - Vector2(0, 40))
		anim.spawn_particles(level_complete_panel, center, ThemeManager.SIGNAL_ACTIVE, 25)
		# Setup button hovers on complete panel buttons
		var share_btn = level_complete_panel.get_node_or_null("Margin/VBox/ButtonRow/ShareBtn")
		var next_btn2 = level_complete_panel.get_node_or_null("Margin/VBox/ButtonRow/NextLevelBtn")
		await get_tree().process_frame
		if share_btn:
			anim.setup_button_hover(share_btn)
		if next_btn2:
			anim.setup_button_hover(next_btn2)
	else:
		var tween = create_tween()
		tween.tween_property(level_complete_panel, "modulate:a", 1.0, 0.4)

func create_level_complete_panel() -> void:
	level_complete_panel = PanelContainer.new()
	level_complete_panel.name = "LevelCompletePanel"
	level_complete_panel.anchor_left = 0.0
	level_complete_panel.anchor_top = 0.0
	level_complete_panel.anchor_right = 1.0
	level_complete_panel.anchor_bottom = 1.0
	level_complete_panel.visible = false
	level_complete_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var completion_style = StyleBoxFlat.new()
	completion_style.bg_color = Color(ThemeManager.MIDNIGHT_BG.r, ThemeManager.MIDNIGHT_BG.g,
									   ThemeManager.MIDNIGHT_BG.b, 0.97)
	completion_style.border_width_left = 3
	completion_style.border_width_right = 3
	completion_style.border_width_top = 3
	completion_style.border_width_bottom = 3
	completion_style.border_color = ThemeManager.SIGNAL_ACTIVE
	level_complete_panel.add_theme_stylebox_override("panel", completion_style)
	
	var margin = MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 40)
	level_complete_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	level_complete_label = Label.new()
	level_complete_label.name = "ResultLabel"
	level_complete_label.text = "LEVEL COMPLETE!"
	level_complete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_complete_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_complete_label.add_theme_color_override("font_color", ThemeManager.SIGNAL_ACTIVE)
	level_complete_label.add_theme_font_size_override("font_size", 24)
	level_complete_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(level_complete_label)
	
	var btn_row = HBoxContainer.new()
	btn_row.name = "ButtonRow"
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 30)
	vbox.add_child(btn_row)
	
	var share_btn = Button.new()
	share_btn.name = "ShareBtn"
	share_btn.text = "SHARE RESULT"
	share_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	share_btn.custom_minimum_size = Vector2(200, 50)
	share_btn.add_theme_font_size_override("font_size", 14)
	
	var share_style = StyleBoxFlat.new()
	share_style.bg_color = Color(0.15, 0.18, 0.25, 1.0)
	share_style.border_color = ThemeManager.SIGNAL_ACTIVE
	share_style.border_width_left = 2
	share_style.border_width_right = 2
	share_style.border_width_top = 2
	share_style.border_width_bottom = 2
	share_style.corner_radius_top_left = 6
	share_style.corner_radius_top_right = 6
	share_style.corner_radius_bottom_left = 6
	share_style.corner_radius_bottom_right = 6
	share_style.content_margin_top = 8
	share_style.content_margin_bottom = 8
	share_btn.add_theme_stylebox_override("normal", share_style)
	share_btn.add_theme_color_override("font_color", ThemeManager.SIGNAL_ACTIVE)
	
	var share_hover = share_style.duplicate()
	share_hover.bg_color = Color(0.2, 0.24, 0.32, 1.0)
	share_btn.add_theme_stylebox_override("hover", share_hover)
	
	share_btn.pressed.connect(_on_share_button_pressed)
	btn_row.add_child(share_btn)
	
	var next_btn = Button.new()
	next_btn.name = "NextLevelBtn"
	next_btn.text = "NEXT LEVEL  ▶"
	next_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	next_btn.custom_minimum_size = Vector2(200, 50)
	next_btn.add_theme_font_size_override("font_size", 14)
	
	var next_style = StyleBoxFlat.new()
	next_style.bg_color = ThemeManager.SIGNAL_ACTIVE
	next_style.corner_radius_top_left = 6
	next_style.corner_radius_top_right = 6
	next_style.corner_radius_bottom_left = 6
	next_style.corner_radius_bottom_right = 6
	next_style.content_margin_top = 8
	next_style.content_margin_bottom = 8
	next_btn.add_theme_stylebox_override("normal", next_style)
	next_btn.add_theme_color_override("font_color", ThemeManager.MIDNIGHT_BG)
	
	var next_hover = next_style.duplicate()
	next_hover.bg_color = ThemeManager.SIGNAL_ACTIVE.lightened(0.2)
	next_btn.add_theme_stylebox_override("hover", next_hover)
	
	next_btn.pressed.connect(_on_next_level_button_pressed)
	btn_row.add_child(next_btn)
	
	$CanvasLayer/MainUI.add_child(level_complete_panel)

func _on_share_button_pressed() -> void:
	var title = level_data.get("title", "Level %d" % current_level_id)
	var star_display := ""
	for i in range(3):
		if i < _result_stars:
			star_display += "★"
		else:
			star_display += "☆"
	
	var share_text = "Circuit Weaver — Level %d: %s\n%s\nGates: %d | Wires: %d\n\nI'm learning logic gates! Try it: Circuit Weaver" % [
		current_level_id, title, star_display, gates_placed, wires_connected
	]
	
	DisplayServer.clipboard_set(share_text)
	
	var share_btn = level_complete_panel.get_node_or_null("Margin/VBox/ButtonRow/ShareBtn")
	if share_btn:
		share_btn.text = "COPIED TO CLIPBOARD!"
		await get_tree().create_timer(2.0).timeout
		share_btn.text = "SHARE RESULT"

func _on_next_level_button_pressed() -> void:
	proceed_to_next_level()

# --- TUTORIAL SYSTEM ---

func _get_tutorial_steps() -> Array:
	return level_data.get("tutorial_steps", [])

func start_tutorial() -> void:
	"""Initialize the step-by-step tutorial."""
	tutorial_step = 0
	_create_tutorial_corner()
	_create_run_button()
	advance_tutorial()

func advance_tutorial() -> void:
	var steps = _get_tutorial_steps()
	tutorial_step += 1
	if tutorial_step > steps.size():
		return
	
	var step_data = steps[tutorial_step - 1]
	var title_text: String = step_data["title"]
	var msg_text: String = step_data["msg"]
	
	# Substitute architect name where %s appears
	if "%s" in msg_text:
		msg_text = msg_text % Global.user_name
	
	_update_tutorial_display(title_text, msg_text)
	
	# Check if this is the last step (GOOD LUCK / short tutorial)
	var is_last_step: bool = tutorial_step == steps.size()
	var is_good_luck: bool = title_text in ["GOOD LUCK", "FINAL EXAM"]
	if is_last_step and is_good_luck:
		_set_continue_visible(false)
		_start_good_luck_auto_dismiss()
		return
	
	# For full 6-step tutorials, manage step-specific behavior
	var total_steps: int = steps.size()
	if total_steps >= 6:
		match tutorial_step:
			2:
				_highlight_toolbox(true)
				_set_continue_visible(false)
			3:
				_set_continue_visible(false)
			4:
				_set_continue_visible(false)
			5:
				_set_continue_visible(false)
				_show_run_button_pulse()
			6:
				_set_continue_visible(false)
				# Fade out the tutorial panel for the COMPLETE step
				if tutorial_panel:
					var tw = tutorial_panel.create_tween()
					tw.tween_interval(2.5)  # Show for 2.5 seconds
					tw.tween_property(tutorial_panel, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
					tw.tween_callback(func() -> void:
						if tutorial_panel:
							tutorial_panel.queue_free()
							tutorial_panel = null
					)
				_on_tutorial_complete()
			_:
				_set_continue_visible(true)
	else:
		# Short tutorials — show continue on non-final steps
		_set_continue_visible(true)
	

func _update_tutorial_display(title: String, message: String) -> void:
	var steps = _get_tutorial_steps()
	if _tutorial_title_label:
		_tutorial_title_label.text = "%s  (Step %d/%d)" % [title, tutorial_step, steps.size()]
	if _tutorial_step_label:
		_tutorial_step_label.text = message
	
	if tutorial_panel:
		var anim = get_node_or_null("/root/AnimHelper")
		if anim:
			# Slide the content in from left for each step change
			tutorial_panel.modulate.a = 0.0
			var orig_x = tutorial_panel.position.x
			tutorial_panel.position.x = orig_x - 30.0
			var tw = tutorial_panel.create_tween().set_parallel(true)
			tw.tween_property(tutorial_panel, "modulate:a", 1.0, 0.25)
			tw.tween_property(tutorial_panel, "position:x", orig_x, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			tutorial_panel.modulate.a = 0.0
			var tween = create_tween()
			tween.tween_property(tutorial_panel, "modulate:a", 1.0, 0.25)

func _set_continue_visible(vis: bool) -> void:
	if _tutorial_continue_btn:
		_tutorial_continue_btn.visible = vis

func _start_good_luck_auto_dismiss() -> void:
	_good_luck_active = true
	# Create a one-shot timer for 5 seconds
	if _good_luck_timer:
		_good_luck_timer.queue_free()
	_good_luck_timer = Timer.new()
	_good_luck_timer.one_shot = true
	_good_luck_timer.wait_time = 5.0
	_good_luck_timer.timeout.connect(_dismiss_good_luck)
	add_child(_good_luck_timer)
	_good_luck_timer.start()

func _dismiss_good_luck() -> void:
	if not _good_luck_active:
		return
	_good_luck_active = false
	# Stop and clean up timer
	if _good_luck_timer:
		_good_luck_timer.stop()
		_good_luck_timer.queue_free()
		_good_luck_timer = null
	# Fade out tutorial panel then remove it
	if tutorial_panel:
		var tw = tutorial_panel.create_tween()
		tw.tween_property(tutorial_panel, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void:
			if tutorial_panel:
				tutorial_panel.queue_free()
				tutorial_panel = null
		)
	_on_tutorial_complete()

func _create_tutorial_corner() -> void:
	if tutorial_panel:
		tutorial_panel.queue_free()
	
	var resp = get_node_or_null("/root/ResponsiveManager")
	var ui_scale: float = 1.0
	if resp:
		ui_scale = resp.ui_scale
	
	tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_panel.add_child(hbox)
	
	var instruction_box = PanelContainer.new()
	instruction_box.name = "InstructionBox"
	instruction_box.mouse_filter = Control.MOUSE_FILTER_PASS
	var style = StyleBoxFlat.new()
	style.bg_color = Color(ThemeManager.MIDNIGHT_BG.r, ThemeManager.MIDNIGHT_BG.g, ThemeManager.MIDNIGHT_BG.b, 0.94)
	style.border_color = ThemeManager.SIGNAL_ACTIVE
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	instruction_box.add_theme_stylebox_override("panel", style)
	instruction_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(instruction_box)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	instruction_box.add_child(vbox)
	
	_tutorial_title_label = Label.new()
	_tutorial_title_label.text = "..."
	_tutorial_title_label.add_theme_color_override("font_color", ThemeManager.ACCENT_WARNING)
	_tutorial_title_label.add_theme_font_size_override("font_size", int(15 * ui_scale))
	vbox.add_child(_tutorial_title_label)
	
	_tutorial_step_label = Label.new()
	_tutorial_step_label.text = "..."
	_tutorial_step_label.add_theme_color_override("font_color", ThemeManager.TERMINAL_WHITE)
	_tutorial_step_label.add_theme_font_size_override("font_size", int(13 * ui_scale))
	_tutorial_step_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_tutorial_step_label.custom_minimum_size = Vector2(280 * ui_scale, 0)
	vbox.add_child(_tutorial_step_label)
	
	_tutorial_continue_btn = Button.new()
	_tutorial_continue_btn.name = "ContinueBtn"
	_tutorial_continue_btn.text = "Continue →"
	_tutorial_continue_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_tutorial_continue_btn.add_theme_color_override("font_color", ThemeManager.MIDNIGHT_BG)
	_tutorial_continue_btn.add_theme_font_size_override("font_size", int(12 * ui_scale))
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = ThemeManager.SIGNAL_ACTIVE
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.corner_radius_bottom_right = 4
	_tutorial_continue_btn.add_theme_stylebox_override("normal", btn_style)
	_tutorial_continue_btn.custom_minimum_size = Vector2(120 * ui_scale, 30 * ui_scale)
	_tutorial_continue_btn.pressed.connect(_on_continue_button_pressed)
	vbox.add_child(_tutorial_continue_btn)
	
	# Continue button hover + pressed style
	var btn_hover_style = btn_style.duplicate()
	btn_hover_style.bg_color = ThemeManager.SIGNAL_ACTIVE.lightened(0.2)
	_tutorial_continue_btn.add_theme_stylebox_override("hover", btn_hover_style)
	var anim = get_node_or_null("/root/AnimHelper")
	if anim:
		_setup_continue_btn_hover.call_deferred()
	
	_tutorial_bot_image = TextureRect.new()
	_tutorial_bot_image.texture = load("res://assets/bot-instructor.png")
	_tutorial_bot_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tutorial_bot_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_tutorial_bot_image.custom_minimum_size = Vector2(260 * ui_scale, 290 * ui_scale)
	_tutorial_bot_image.size_flags_vertical = Control.SIZE_SHRINK_END
	hbox.add_child(_tutorial_bot_image)
	
	_anchor_tutorial_bottom()
	
	if has_node("CanvasLayer/MainUI"):
		get_node("CanvasLayer/MainUI").add_child(tutorial_panel)
	else:
		add_child(tutorial_panel)

func _anchor_tutorial_bottom() -> void:
	if not tutorial_panel:
		return
	tutorial_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tutorial_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	# Anchor at bottom-center
	tutorial_panel.anchor_left = 0.5
	tutorial_panel.anchor_top = 1.0
	tutorial_panel.anchor_right = 0.5
	tutorial_panel.anchor_bottom = 1.0
	# Will be properly positioned after first layout pass
	tutorial_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE)
	_panel_position = "bottom"

func _setup_continue_btn_hover() -> void:
	var anim = get_node_or_null("/root/AnimHelper")
	if anim and _tutorial_continue_btn and _tutorial_continue_btn.is_inside_tree():
		anim.setup_button_hover(_tutorial_continue_btn, 1.06)

func _move_panel_top() -> void:
	if not tutorial_panel:
		return
	tutorial_panel.anchor_left = 0.5
	tutorial_panel.anchor_top = 0.0
	tutorial_panel.anchor_right = 0.5
	tutorial_panel.anchor_bottom = 0.0
	var panel_size = tutorial_panel.get_combined_minimum_size()
	tutorial_panel.offset_left = -panel_size.x / 2.0
	tutorial_panel.offset_top = 12
	tutorial_panel.offset_right = panel_size.x / 2.0
	tutorial_panel.offset_bottom = 12 + panel_size.y
	_panel_position = "top"

func _move_panel_bottom() -> void:
	if not tutorial_panel:
		return
	tutorial_panel.anchor_left = 0.5
	tutorial_panel.anchor_top = 1.0
	tutorial_panel.anchor_right = 0.5
	tutorial_panel.anchor_bottom = 1.0
	var panel_size = tutorial_panel.get_combined_minimum_size()
	tutorial_panel.offset_left = -panel_size.x / 2.0
	tutorial_panel.offset_top = -panel_size.y - 12
	tutorial_panel.offset_right = panel_size.x / 2.0
	tutorial_panel.offset_bottom = -12
	_panel_position = "bottom"

func _process(_delta: float) -> void:
	# Move tutorial panel out of the way when user drags near it
	if not tutorial_panel or not tutorial_panel.is_inside_tree():
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	
	var mouse = get_viewport().get_mouse_position()
	var panel_rect = Rect2(tutorial_panel.global_position, tutorial_panel.size)
	var expanded = panel_rect.grow(40.0)
	
	if expanded.has_point(mouse):
		var viewport_h = get_viewport().get_visible_rect().size.y
		if mouse.y < viewport_h / 2.0:
			if _panel_position != "bottom":
				_move_panel_bottom()
		else:
			if _panel_position != "top":
				_move_panel_top()

func _highlight_toolbox(highlight: bool) -> void:
	if not gate_toolbox:
		return
	for child in gate_toolbox.get_children():
		child.modulate = Color(1.4, 1.4, 1.4) if highlight else Color.WHITE

func _create_run_button() -> void:
	run_button = get_node_or_null("CanvasLayer/MainUI/HBoxContainer/Sidebar/SidebarMargin/SidebarVBox/RunButton")
	if run_button:
		run_button.hide()
		return
	
	var sidebar_vbox = get_node_or_null("CanvasLayer/MainUI/HBoxContainer/Sidebar/SidebarMargin/SidebarVBox")
	if not sidebar_vbox:
		return
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar_vbox.add_child(spacer)
	
	var settings_btn = Button.new()
	settings_btn.name = "SettingsButton"
	settings_btn.text = "SETTINGS"
	settings_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_btn.add_theme_color_override("font_color", ThemeManager.TERMINAL_WHITE)
	settings_btn.add_theme_font_size_override("font_size", 12)
	var settings_style = StyleBoxFlat.new()
	settings_style.bg_color = Color(0.12, 0.14, 0.20)
	settings_style.corner_radius_top_left = 4
	settings_style.corner_radius_top_right = 4
	settings_style.corner_radius_bottom_left = 4
	settings_style.corner_radius_bottom_right = 4
	settings_style.content_margin_top = 6
	settings_style.content_margin_bottom = 6
	settings_btn.add_theme_stylebox_override("normal", settings_style)
	var settings_hover = settings_style.duplicate()
	settings_hover.bg_color = Color(0.18, 0.20, 0.28)
	settings_btn.add_theme_stylebox_override("hover", settings_hover)
	settings_btn.custom_minimum_size = Vector2(0, 36)
	settings_btn.pressed.connect(_on_settings_button_pressed)
	sidebar_vbox.add_child(settings_btn)

	var reset_btn = Button.new()
	reset_btn.name = "ResetButton"
	reset_btn.text = "RESET LEVEL"
	reset_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	reset_btn.add_theme_color_override("font_color", ThemeManager.ACCENT_WARNING)
	reset_btn.add_theme_font_size_override("font_size", 12)
	var reset_style = StyleBoxFlat.new()
	reset_style.bg_color = Color(0.15, 0.10, 0.12)
	reset_style.corner_radius_top_left = 4
	reset_style.corner_radius_top_right = 4
	reset_style.corner_radius_bottom_left = 4
	reset_style.corner_radius_bottom_right = 4
	reset_style.content_margin_top = 6
	reset_style.content_margin_bottom = 6
	reset_btn.add_theme_stylebox_override("normal", reset_style)
	var reset_hover = reset_style.duplicate()
	reset_hover.bg_color = Color(0.25, 0.15, 0.18)
	reset_btn.add_theme_stylebox_override("hover", reset_hover)
	reset_btn.custom_minimum_size = Vector2(0, 36)
	reset_btn.pressed.connect(_on_reset_button_pressed)
	sidebar_vbox.add_child(reset_btn)

	var exit_btn = Button.new()
	exit_btn.name = "ExitButton"
	exit_btn.text = "EXIT"
	exit_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	exit_btn.add_theme_color_override("font_color", Color.WHITE)
	exit_btn.add_theme_font_size_override("font_size", 12)
	var exit_style = StyleBoxFlat.new()
	exit_style.bg_color = Color(0.6, 0.15, 0.15)
	exit_style.corner_radius_top_left = 4
	exit_style.corner_radius_top_right = 4
	exit_style.corner_radius_bottom_left = 4
	exit_style.corner_radius_bottom_right = 4
	exit_style.content_margin_top = 6
	exit_style.content_margin_bottom = 6
	exit_btn.add_theme_stylebox_override("normal", exit_style)
	var exit_hover = exit_style.duplicate()
	exit_hover.bg_color = Color(0.8, 0.2, 0.2)
	exit_btn.add_theme_stylebox_override("hover", exit_hover)
	exit_btn.custom_minimum_size = Vector2(0, 36)
	exit_btn.pressed.connect(_on_exit_button_pressed)
	sidebar_vbox.add_child(exit_btn)

	run_button = Button.new()
	run_button.name = "RunButton"
	run_button.text = "RUN SIMULATION"
	run_button.mouse_filter = Control.MOUSE_FILTER_STOP
	run_button.add_theme_color_override("font_color", ThemeManager.MIDNIGHT_BG)
	run_button.add_theme_font_size_override("font_size", 14)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = ThemeManager.SIGNAL_ACTIVE
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.corner_radius_bottom_right = 4
	btn_style.content_margin_top = 8
	btn_style.content_margin_bottom = 8
	run_button.add_theme_stylebox_override("normal", btn_style)
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = ThemeManager.SIGNAL_ACTIVE.lightened(0.2)
	run_button.add_theme_stylebox_override("hover", btn_hover)
	run_button.custom_minimum_size = Vector2(0, 42)
	run_button.pressed.connect(_on_run_button_pressed)
	sidebar_vbox.add_child(run_button)
	run_button.hide()

	# Setup hover animations for all sidebar buttons after layout pass
	_setup_sidebar_hover_anims(settings_btn, reset_btn, exit_btn, run_button)

func _setup_sidebar_hover_anims(s_btn: Button, r_btn: Button, e_btn: Button, rn_btn: Button) -> void:
	var anim = get_node_or_null("/root/AnimHelper")
	if not anim:
		return
	await get_tree().process_frame
	for btn in [s_btn, r_btn, e_btn, rn_btn]:
		if btn and btn.is_inside_tree():
			anim.setup_button_hover(btn, 1.05)

func _show_run_button_pulse() -> void:
	if not run_button:
		return
	run_button.show()
	var anim = get_node_or_null("/root/AnimHelper")
	if anim:
		anim.bounce(run_button, 1.2, 0.35)
		anim.pulse_scale(run_button, 0.97, 1.03, 0.6)
	else:
		var tween = create_tween().set_loops(4)
		tween.tween_property(run_button, "modulate:a", 0.5, 0.25)
		tween.tween_property(run_button, "modulate:a", 1.0, 0.25)

func _on_exit_button_pressed() -> void:
	Global.save_progress()
	var music_mgr = get_node_or_null("/root/MusicManager")
	if music_mgr:
		music_mgr.stop_music()
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _on_reset_button_pressed() -> void:
	var sfx = get_node_or_null("/root/SFXManager")
	if sfx:
		sfx.play_button_press()
	get_tree().reload_current_scene()

func _on_settings_button_pressed() -> void:
	if _settings_panel and _settings_panel.visible:
		var anim = get_node_or_null("/root/AnimHelper")
		if anim:
			var tw = anim.pop_out(_settings_panel, 0.2)
			await tw.finished
		_settings_panel.visible = false
		return
	if not _settings_panel:
		_create_settings_panel()
	_settings_panel.visible = true
	var anim = get_node_or_null("/root/AnimHelper")
	if anim:
		anim.pop_in(_settings_panel, 0.35, 0.0)

func _on_continue_button_pressed() -> void:
	var steps = _get_tutorial_steps()
	if tutorial_step < steps.size():
		advance_tutorial()
	elif tutorial_step >= steps.size() and not _tutorial_complete:
		# Last step reached via continue — dismiss
		_dismiss_good_luck()

func _on_run_button_pressed() -> void:
	if _tutorial_complete:
		await run_simulation()
		return
	var steps = _get_tutorial_steps()
	if steps.size() >= 6 and tutorial_step == 5:
		await run_simulation()
		if level_complete:
			advance_tutorial()

func _on_tutorial_complete() -> void:
	_tutorial_complete = true
	# Show run button now that tutorial is done
	if run_button and not run_button.visible:
		run_button.show()
		var anim = get_node_or_null("/root/AnimHelper")
		if anim:
			anim.bounce(run_button, 1.15, 0.3)
	var config := ConfigFile.new()
	config.load(Global.SAVE_PATH)
	config.set_value("Progress", "tutorial_done", true)
	config.set_value("Progress", "level_%d_score" % current_level_id, Global.current_level_score)
	config.save(Global.SAVE_PATH)

# --- LEVEL ENTRANCE ANIMATION ---

func _animate_level_entrance() -> void:
	var anim = get_node_or_null("/root/AnimHelper")
	if not anim:
		return
	# Sidebar slide in from left
	var sidebar = get_node_or_null("CanvasLayer/MainUI/HBoxContainer/Sidebar") as Control
	if sidebar:
		anim.slide_in_from_left(sidebar, 100.0, 0.5, 0.0)
	# Header fade
	if header_label:
		anim.fade_in(header_label, 0.4, 0.1)
	if welcome_label:
		anim.fade_in(welcome_label, 0.3, 0.2)
	# Stagger gate toolbox icons
	if gate_toolbox:
		var children = gate_toolbox.get_children()
		for i in range(children.size()):
			var child = children[i]
			if child is Control:
				anim.slide_in_from_left(child, 50.0, 0.3, 0.15 + float(i) * 0.08)

# --- RESPONSIVE LAYOUT ---

func _on_layout_changed(_form_factor: String) -> void:
	_apply_responsive_layout()

func _apply_responsive_layout() -> void:
	var resp = get_node_or_null("/root/ResponsiveManager")
	if not resp:
		return

	var cam = get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.zoom = resp.get_camera_zoom()
		cam.position = resp.get_camera_center()

	var sidebar = get_node_or_null("CanvasLayer/MainUI/HBoxContainer/Sidebar") as PanelContainer
	if sidebar:
		sidebar.custom_minimum_size = Vector2(resp.sidebar_width, 0)

	var ui_scale: float = resp.ui_scale
	if header_label:
		header_label.add_theme_font_size_override("font_size", int(16 * ui_scale))
	if welcome_label:
		welcome_label.add_theme_font_size_override("font_size", int(12 * ui_scale))
	var toolbox_title = get_node_or_null("CanvasLayer/MainUI/HBoxContainer/Sidebar/SidebarMargin/SidebarVBox/ToolboxTitle") as Label
	if toolbox_title:
		toolbox_title.add_theme_font_size_override("font_size", int(14 * ui_scale))

	var icon_size: float = 60.0 * ui_scale
	if gate_toolbox:
		for wrapper in gate_toolbox.get_children():
			for child in wrapper.get_children():
				if child is TextureRect:
					child.custom_minimum_size = Vector2(icon_size, icon_size)
				elif child is Label:
					child.add_theme_font_size_override("font_size", int(11 * ui_scale))

	if run_button:
		run_button.custom_minimum_size = Vector2(0, resp.get_button_height())
		run_button.add_theme_font_size_override("font_size", int(14 * ui_scale))

# --- SETTINGS PANEL ---

func _create_settings_panel() -> void:
	_settings_panel = PanelContainer.new()
	_settings_panel.name = "SettingsPanel"
	_settings_panel.anchor_left = 0.25
	_settings_panel.anchor_top = 0.15
	_settings_panel.anchor_right = 0.75
	_settings_panel.anchor_bottom = 0.85
	_settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(ThemeManager.MIDNIGHT_BG.r, ThemeManager.MIDNIGHT_BG.g, ThemeManager.MIDNIGHT_BG.b, 0.97)
	bg_style.border_color = ThemeManager.SIGNAL_ACTIVE
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	_settings_panel.add_theme_stylebox_override("panel", bg_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_settings_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	# Title
	var title_lbl = Label.new()
	title_lbl.text = "SETTINGS"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", ThemeManager.SIGNAL_ACTIVE)
	title_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title_lbl)

	_add_slider_row(vbox, "Master Volume", _get_master_vol(), func(val: float) -> void:
		var sfx = get_node_or_null("/root/SFXManager")
		if sfx:
			sfx.set_master_volume(val)
			sfx.save_audio_settings()
	)

	_add_slider_row(vbox, "Music Volume", _get_music_vol(), func(val: float) -> void:
		var music = get_node_or_null("/root/MusicManager")
		if music:
			music.music_volume = val
			music.save_music_settings()
	)

	var music_row = HBoxContainer.new()
	var music_lbl = Label.new()
	music_lbl.text = "Music Enabled"
	music_lbl.add_theme_color_override("font_color", ThemeManager.TERMINAL_WHITE)
	music_lbl.add_theme_font_size_override("font_size", 14)
	music_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_row.add_child(music_lbl)
	var music_chk = CheckBox.new()
	music_chk.button_pressed = _get_music_enabled()
	music_chk.toggled.connect(func(on: bool) -> void:
		var m = get_node_or_null("/root/MusicManager")
		if m:
			m.music_enabled = on
			m.save_music_settings()
	)
	music_row.add_child(music_chk)
	vbox.add_child(music_row)

	var shake_row = HBoxContainer.new()
	var shake_lbl = Label.new()
	shake_lbl.text = "Screen Shake"
	shake_lbl.add_theme_color_override("font_color", ThemeManager.TERMINAL_WHITE)
	shake_lbl.add_theme_font_size_override("font_size", 14)
	shake_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shake_row.add_child(shake_lbl)
	var shake_chk = CheckBox.new()
	shake_chk.button_pressed = _get_shake_enabled()
	shake_chk.toggled.connect(func(on: bool) -> void:
		var s = get_node_or_null("/root/SFXManager")
		if s:
			s.set_screen_shake(on)
			s.save_audio_settings()
	)
	shake_row.add_child(shake_chk)
	vbox.add_child(shake_row)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var close_btn = Button.new()
	close_btn.text = "CLOSE"
	close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	close_btn.add_theme_color_override("font_color", ThemeManager.MIDNIGHT_BG)
	close_btn.add_theme_font_size_override("font_size", 14)
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = ThemeManager.SIGNAL_ACTIVE
	close_style.corner_radius_top_left = 4
	close_style.corner_radius_top_right = 4
	close_style.corner_radius_bottom_left = 4
	close_style.corner_radius_bottom_right = 4
	close_style.content_margin_top = 8
	close_style.content_margin_bottom = 8
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.custom_minimum_size = Vector2(120, 40)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func() -> void:
		var anim2 = get_node_or_null("/root/AnimHelper")
		if anim2:
			var tw2 = anim2.pop_out(_settings_panel, 0.2)
			await tw2.finished
		_settings_panel.visible = false
	)
	vbox.add_child(close_btn)

	$CanvasLayer/MainUI.add_child(_settings_panel)

	# Setup hover on close button (deferred so it has layout size)
	var anim = get_node_or_null("/root/AnimHelper")
	if anim:
		_setup_close_btn_hover.call_deferred(close_btn)

func _setup_close_btn_hover(btn: Button) -> void:
	var anim = get_node_or_null("/root/AnimHelper")
	if anim and btn and btn.is_inside_tree():
		anim.setup_button_hover(btn)

func _add_slider_row(parent: VBoxContainer, label_text: String, initial: float, on_change: Callable) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_color_override("font_color", ThemeManager.TERMINAL_WHITE)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.custom_minimum_size = Vector2(130, 0)
	row.add_child(lbl)
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(100, 20)
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	parent.add_child(row)

func _get_master_vol() -> float:
	var sfx = get_node_or_null("/root/SFXManager")
	return sfx.get_master_volume() if sfx else 0.8

func _get_music_vol() -> float:
	var m = get_node_or_null("/root/MusicManager")
	return m.music_volume if m else 0.5

func _get_music_enabled() -> bool:
	var m = get_node_or_null("/root/MusicManager")
	return m.music_enabled if m else true

func _get_shake_enabled() -> bool:
	var s = get_node_or_null("/root/SFXManager")
	return s.get_screen_shake() if s else true