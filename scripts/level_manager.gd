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

# Input blocking during tutorial
var _input_blocked: bool = true

# Failure panel
var _level_failed_panel: PanelContainer = null
var _level_failed_label: Label = null

# Overlay panels
var _hints_revealed: int = 0
var _hint_panel: PanelContainer = null
var _hint_btn: Button = null
var _truth_table_panel: PanelContainer = null
var _shortcuts_panel: PanelContainer = null

# --- TAP-TO-PLACE (mobile) ---
var _selected_gate_type: String = ""
var _tap_place_label: Label = null
var _sidebar_toggle_btn: Button = null
var _sidebar_visible: bool = true

func _ready() -> void:
	add_to_group("level_manager")
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
	var _chapter: int = level_data.get("chapter", 1)
	var ch_accent: Color = ThemeManager.get_chapter_accent(_chapter)

	var sidebar = get_node_or_null("CanvasLayer/MainUI/HBoxContainer/Sidebar") as PanelContainer
	if sidebar:
		# Glassmorphic sidebar with chapter accent
		var sidebar_style = ThemeManager.create_glass_panel(ch_accent, 0, 2)
		sidebar_style.corner_radius_top_left = 0
		sidebar_style.corner_radius_bottom_left = 0
		sidebar_style.corner_radius_top_right = 12
		sidebar_style.corner_radius_bottom_right = 12
		sidebar.add_theme_stylebox_override("panel", sidebar_style)
		var sw: float = resp.sidebar_width if resp else 250.0
		sidebar.custom_minimum_size = Vector2(sw, 0)

	header_label.add_theme_color_override("font_color", ch_accent)
	header_label.add_theme_font_size_override("font_size", int(16 * ui_scale))
	welcome_label.add_theme_color_override("font_color", ThemeManager.TERMINAL_WHITE)
	welcome_label.add_theme_font_size_override("font_size", int(12 * ui_scale))

	var toolbox_title = get_node_or_null("CanvasLayer/MainUI/HBoxContainer/Sidebar/SidebarMargin/SidebarVBox/ToolboxTitle") as Label
	if toolbox_title:
		toolbox_title.add_theme_color_override("font_color", ch_accent)
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
		# Card-style gate item with colored accent
		var card = PanelContainer.new()
		card.name = gate_type + "Card"
		var gate_color: Color = ThemeManager.get_gate_color(gate_type)
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(gate_color.r * 0.08, gate_color.g * 0.08, gate_color.b * 0.08, 0.6)
		card_style.border_color = Color(gate_color.r * 0.4, gate_color.g * 0.4, gate_color.b * 0.4, 0.5)
		card_style.border_width_left = 3
		card_style.border_width_right = 1
		card_style.border_width_top = 1
		card_style.border_width_bottom = 1
		ThemeManager._apply_radius(card_style, 8)
		card_style.content_margin_left = int(6 * ui_scale)
		card_style.content_margin_right = int(6 * ui_scale)
		card_style.content_margin_top = int(4 * ui_scale)
		card_style.content_margin_bottom = int(4 * ui_scale)
		card_style.shadow_color = Color(gate_color.r * 0.15, gate_color.g * 0.15, gate_color.b * 0.15, 0.3)
		card_style.shadow_size = 4
		card.add_theme_stylebox_override("panel", card_style)

		var wrapper = VBoxContainer.new()
		wrapper.name = gate_type + "Wrapper"
		wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
		wrapper.add_theme_constant_override("separation", int(2 * ui_scale))
		card.add_child(wrapper)
		
		var gate_icon = GateIcon.new()
		gate_icon.gate_type = gate_type
		gate_icon.name = gate_type + "Icon"
		gate_icon.self_modulate = gate_color
		gate_icon.custom_minimum_size = Vector2(icon_size, icon_size)
		wrapper.add_child(gate_icon)
		
		var gate_label = Label.new()
		gate_label.text = gate_type
		gate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gate_label.add_theme_color_override("font_color", Color(gate_color.r * 0.8, gate_color.g * 0.8, gate_color.b * 0.8, 0.9))
		gate_label.add_theme_font_size_override("font_size", int(11 * ui_scale))
		wrapper.add_child(gate_label)
		
		gate_toolbox.add_child(card)
		gate_icon.gate_clicked.connect(_on_gate_icon_clicked)
		# Enhanced hover with glow
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var c_ref = card
		var hover_style = card_style.duplicate()
		hover_style.bg_color = Color(gate_color.r * 0.15, gate_color.g * 0.15, gate_color.b * 0.15, 0.8)
		hover_style.border_color = Color(gate_color.r * 0.7, gate_color.g * 0.7, gate_color.b * 0.7, 0.8)
		hover_style.shadow_size = 8
		var normal_style = card_style
		card.mouse_entered.connect(func() -> void:
			c_ref.add_theme_stylebox_override("panel", hover_style)
			c_ref.pivot_offset = c_ref.size / 2.0
			var tw_h = c_ref.create_tween()
			tw_h.tween_property(c_ref, "scale", Vector2(1.08, 1.08), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)
		card.mouse_exited.connect(func() -> void:
			c_ref.add_theme_stylebox_override("panel", normal_style)
			var tw_h = c_ref.create_tween()
			tw_h.tween_property(c_ref, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)

func setup_circuit_board() -> void:
	if circuit_board and not circuit_board.gate_placed.is_connected(_on_gate_placed):
		circuit_board.gate_placed.connect(_on_gate_placed)
	if circuit_board and not circuit_board.wire_connected.is_connected(_on_wire_connected):
		circuit_board.wire_connected.connect(_on_wire_connected)
	circuit_board.set_process_unhandled_input(true)

# --- SIGNAL HANDLERS ---

func _on_gate_icon_clicked(_gate_type_clicked: String) -> void:
	# Block interaction during tutorial when Continue button is visible
	if _input_blocked and not _tutorial_complete:
		return
	# Tap-to-place: select gate type, then tap board to place
	# Only enable tap-to-place after tutorial is complete (tutorial uses drag-and-drop)
	var resp = get_node_or_null("/root/ResponsiveManager")
	if resp and resp.is_touch_device and _tutorial_complete:
		_selected_gate_type = _gate_type_clicked
		_show_tap_place_indicator(_gate_type_clicked)
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
	# Clear tap-to-place indicator (may have been set if user tapped icon then dragged instead)
	if _selected_gate_type != "":
		_selected_gate_type = ""
		_hide_tap_place_indicator()
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

	# Block all board interactions during tutorial when input is blocked
	if _input_blocked and not _tutorial_complete:
		return

	# Android back button → exit to level select
	if event is InputEventKey and event.pressed and event.keycode == KEY_BACK:
		_on_exit_button_pressed()
		get_viewport().set_input_as_handled()
		return

	# Tap-to-place: if a gate type is selected and user taps the board area
	if _selected_gate_type != "":
		if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or \
		   (event is InputEventScreenTouch and event.pressed):
			# Check if the tap is in the board area (not sidebar)
			var vp_pos = event.position if event is InputEventScreenTouch else (event as InputEventMouseButton).position
			var resp = get_node_or_null("/root/ResponsiveManager")
			var sw: float = resp.sidebar_width if resp else 250.0
			if vp_pos.x > sw and circuit_board:
				var local_pos = circuit_board.get_local_mouse_position()
				circuit_board.place_gate(_selected_gate_type, Vector2i.ZERO, local_pos)
				_selected_gate_type = ""
				_hide_tap_place_indicator()
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
	if not circuit_board:
		return
	var all_complete: bool = true
	for out in circuit_board.output_nodes:
		if not is_instance_valid(out):
			continue
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
	if not is_instance_valid(circuit_board):
		return
	var sfx = get_node_or_null("/root/SFXManager")
	if circuit_board.wires.is_empty():
		# No wires connected — nothing to simulate
		if sfx:
			sfx.play_error_buzz()
		return
	if sfx:
		sfx.play_simulation_hum(1.0)
	await circuit_board.start_simulation()
	if sfx:
		sfx.play_simulation_hum(1.5)
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return
	if sfx:
		sfx.stop_simulation_hum()
	# Check for failure after simulation completes
	if not level_complete and _tutorial_complete and is_instance_valid(circuit_board):
		var any_output_tested: bool = false
		for out in circuit_board.output_nodes:
			if not is_instance_valid(out):
				continue
			if out.received_sequence.size() > 0:
				any_output_tested = true
				break
		if any_output_tested:
			_show_level_failed()
		else:
			# No output received any signal — circuit is not connected properly
			if sfx:
				sfx.play_error_buzz()
				sfx.apply_screen_shake(4.0, 0.2)

# --- SCORING & LEVEL COMPLETION ---

func evaluate_level_performance() -> void:
	if level_complete:
		return
	if not is_instance_valid(circuit_board):
		return
	level_complete = true
	var max_gates: int = level_data.get("max_gates", 1)
	# Use live gate count for scoring — not cumulative placements
	var actual_gates: int = circuit_board.gates.size()
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
	# Check for newly unlocked achievements
	_check_achievements()

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

		# Show interstitial ad (respects frequency cap — every 3 levels)
		var ad_mgr = get_node_or_null("/root/AdManager")
		if ad_mgr:
			ad_mgr.interstitial_closed.connect(_on_ad_closed_proceed.bind(scene_path, is_chapter_change), CONNECT_ONE_SHOT)
			ad_mgr.show_interstitial_if_ready()
		else:
			_do_scene_transition(scene_path, is_chapter_change)
	else:
		show_graduation_screen()

func _on_ad_closed_proceed(scene_path: String, is_chapter_change: bool) -> void:
	_do_scene_transition(scene_path, is_chapter_change)

func _do_scene_transition(scene_path: String, is_chapter_change: bool) -> void:
	var tm = get_node_or_null("/root/TransitionMgr")
	if tm and tm.has_method("transition_to_scene"):
		tm.transition_to_scene(scene_path, is_chapter_change)
	else:
		get_tree().call_deferred("change_scene_to_file", scene_path)

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
	if not level_complete_panel:
		create_level_complete_panel()
	if not is_instance_valid(level_complete_label) or not is_instance_valid(level_complete_panel):
		return
	_result_stars = stars
	
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
	result_text += "Architect: %s\n" % Global.user_name
	result_text += "━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
	result_text += "%s\n\n" % star_display
	result_text += "%s\n\n" % grade_text
	var actual_gates_result: int = circuit_board.gates.size() if is_instance_valid(circuit_board) else gates_placed
	var actual_wires_result: int = circuit_board.wires.size() if is_instance_valid(circuit_board) else wires_connected
	result_text += "Formula: %s\n" % formula
	result_text += "Gates Used: %d / %d\n" % [actual_gates_result, max_gates]
	result_text += "Wires Used: %d" % actual_wires_result
	
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
		# Confetti burst for 3-star performance
		if stars >= 3:
			anim.confetti_burst(level_complete_panel, center, 50)
		elif stars >= 2:
			anim.confetti_burst(level_complete_panel, center, 25)
		# Ripple effect from center
		var ch_accent2 = ThemeManager.get_chapter_accent(level_data.get("chapter", 1))
		anim.ripple_effect(level_complete_panel, center, ch_accent2, 2)
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
	var _chapter: int = level_data.get("chapter", 1)
	var ch_accent: Color = ThemeManager.get_chapter_accent(_chapter)

	level_complete_panel = PanelContainer.new()
	level_complete_panel.name = "LevelCompletePanel"
	level_complete_panel.anchor_left = 0.0
	level_complete_panel.anchor_top = 0.0
	level_complete_panel.anchor_right = 1.0
	level_complete_panel.anchor_bottom = 1.0
	level_complete_panel.visible = false
	level_complete_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	# Dark backdrop with deep glass feel
	var completion_style = StyleBoxFlat.new()
	completion_style.bg_color = Color(0.02, 0.03, 0.06, 0.95)
	completion_style.border_width_left = 0
	completion_style.border_width_right = 0
	completion_style.border_width_top = 0
	completion_style.border_width_bottom = 0
	level_complete_panel.add_theme_stylebox_override("panel", completion_style)

	# Centered card container
	var center_box = CenterContainer.new()
	center_box.anchor_right = 1.0
	center_box.anchor_bottom = 1.0
	level_complete_panel.add_child(center_box)

	# Inner glassmorphic card
	var card = PanelContainer.new()
	card.name = "ResultCard"
	var card_style = ThemeManager.create_glass_panel(ch_accent, 16, 2)
	card_style.shadow_color = Color(ch_accent.r * 0.2, ch_accent.g * 0.2, ch_accent.b * 0.2, 0.4)
	card_style.shadow_size = 16
	card.add_theme_stylebox_override("panel", card_style)
	card.custom_minimum_size = Vector2(420, 300)
	center_box.add_child(card)

	var margin = MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	level_complete_label = Label.new()
	level_complete_label.name = "ResultLabel"
	level_complete_label.text = "LEVEL COMPLETE!"
	level_complete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_complete_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_complete_label.add_theme_color_override("font_color", ch_accent)
	level_complete_label.add_theme_font_size_override("font_size", 20)
	level_complete_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(level_complete_label)

	# Glow divider
	var divider = ThemeManager.create_glow_divider(ch_accent, 300.0)
	vbox.add_child(divider)

	var btn_row = HBoxContainer.new()
	btn_row.name = "ButtonRow"
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	vbox.add_child(btn_row)

	var share_btn = Button.new()
	share_btn.name = "ShareBtn"
	share_btn.text = "SHARE RESULT"
	ThemeManager.create_premium_button(share_btn, ch_accent.darkened(0.3), 13, Vector2(180, 46))
	share_btn.pressed.connect(_on_share_button_pressed)
	btn_row.add_child(share_btn)

	var next_btn = Button.new()
	next_btn.name = "NextLevelBtn"
	next_btn.text = "NEXT LEVEL  ▶"
	ThemeManager.create_primary_button(next_btn, 13, Vector2(180, 46))
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
	var share_gates: int = circuit_board.gates.size() if circuit_board else gates_placed
	var share_wires: int = circuit_board.wires.size() if circuit_board else wires_connected
	const SHARE_URL := "https://circuitweaver.devmubarak.me"
	var caption := "⚡ Circuit Weaver — Level %d: %s\n%s | Gates: %d | Wires: %d\n\nI'm learning logic gates! Can you solve it too?\nDownload & try: %s" % [
		current_level_id, title, star_display, share_gates, share_wires, SHARE_URL
	]

	var share_btn = level_complete_panel.get_node_or_null("Margin/VBox/ButtonRow/ShareBtn") if level_complete_panel else null
	if share_btn:
		share_btn.text = "GENERATING..."

	# Wait for the frame to be fully rendered (level complete panel visible)
	await RenderingServer.frame_post_draw

	# Capture the current screen as the share image
	var view_texture = get_viewport().get_texture()
	if not view_texture:
		_share_fallback_clipboard(caption, share_btn)
		return
	var img: Image = view_texture.get_image()
	if not img:
		_share_fallback_clipboard(caption, share_btn)
		return

	# Save using OS.get_user_data_dir() — required path format for GodotShare plugin
	const SHARE_FILENAME := "circuit_weaver_share.png"
	var user_data_dir: String = OS.get_user_data_dir()
	var absolute_path: String = user_data_dir + "/" + SHARE_FILENAME
	var err: Error = img.save_png(absolute_path)
	if err != OK:
		# Fallback: try user:// virtual path
		var save_path: String = "user://" + SHARE_FILENAME
		err = img.save_png(save_path)
		if err != OK:
			_share_fallback_clipboard(caption, share_btn)
			return
		absolute_path = ProjectSettings.globalize_path(save_path)

	print("SHARE: Image saved to: ", absolute_path)

	# Try native Android share via Java bridge
	var share_opened: bool = false
	if OS.get_name() == "Android":
		share_opened = _android_share_image(absolute_path, caption)

	if not share_opened:
		_share_fallback_clipboard(caption, share_btn)
		return

	if share_btn:
		share_btn.text = "SHARED!"
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(share_btn):
		share_btn.text = "SHARE RESULT"

func _android_share_image(_image_path: String, caption: String) -> bool:
	"""Open Android's native share sheet via the GodotShare plugin.
	   Actual method names discovered by inspecting the AAR bytecode:
	   share_img(path, title, message)  -- primary
	   share_img_web(path, title, message) -- fallback
	"""
	if not Engine.has_singleton("GodotShare"):
		print("SHARE: GodotShare plugin not found!")
		return false

	var share = Engine.get_singleton("GodotShare")
	print("SHARE: Found GodotShare singleton (class: %s)." % share.get_class())

	var title = "Circuit Weaver — Level %d" % current_level_id

	# ── Primary: use the exact method names baked into the installed AAR ────
	# (Discovered by scanning com/godot/godotshare/GodotShare.class bytecode)
	if share.has_method("share_img"):
		print("SHARE: Calling share_img().")
		share.share_img(_image_path, title, caption)
		return true

	if share.has_method("share_img_web"):
		print("SHARE: Calling share_img_web().")
		share.share_img_web(_image_path, title, caption)
		return true

	# ── Blind fallback: has_method() fails for JNISingleton ─────────────────
	# The @UsedByGodot method IS found at JNI level even when has_method()
	# returns false (Godot 4 engine version mismatch with plugin compile target).
	# callv() routes directly through the JNI bridge and works correctly.
	print("SHARE: Calling share_img('%s', '%s', caption)." % [_image_path, title])
	share.callv("share_img", [_image_path, title, caption])
	return true

func _share_fallback_clipboard(caption: String, share_btn: Button) -> void:
	DisplayServer.clipboard_set(caption)
	if share_btn:
		share_btn.text = "COPIED TO CLIPBOARD!"
	# Wait then reset button text
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(share_btn):
		share_btn.text = "SHARE RESULT"

func _on_next_level_button_pressed() -> void:
	proceed_to_next_level()

# --- LEVEL FAILED PANEL ---

func _show_level_failed() -> void:
	var sfx = get_node_or_null("/root/SFXManager")
	if sfx:
		sfx.play_error_buzz()
		sfx.apply_screen_shake(8.0, 0.4)
	if not _level_failed_panel:
		_create_level_failed_panel()
	
	var title = level_data.get("title", "Level %d" % current_level_id)
	var formula = level_data.get("formula", "")
	var actual_gates_result: int = circuit_board.gates.size() if circuit_board else gates_placed
	var actual_wires_result: int = circuit_board.wires.size() if circuit_board else wires_connected
	
	var result_text = ""
	result_text += "━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
	result_text += "SIMULATION FAILED\n"
	result_text += "%s\n" % title
	result_text += "━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
	result_text += "✗  ✗  ✗\n\n"
	result_text += "Your circuit did not produce\nthe expected output.\n\n"
	result_text += "Formula: %s\n" % formula
	result_text += "Gates Used: %d\n" % actual_gates_result
	result_text += "Wires Used: %d\n\n" % actual_wires_result
	result_text += "Review your wiring and try again,\nArchitect %s!" % Global.user_name
	
	_level_failed_label.text = result_text
	_level_failed_panel.visible = true
	
	_level_failed_panel.modulate.a = 0.0
	var anim = get_node_or_null("/root/AnimHelper")
	if anim:
		_level_failed_panel.pivot_offset = _level_failed_panel.size / 2.0
		_level_failed_panel.scale = Vector2(0.85, 0.85)
		var tw = _level_failed_panel.create_tween().set_parallel(true)
		tw.tween_property(_level_failed_panel, "modulate:a", 1.0, 0.4)
		tw.tween_property(_level_failed_panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		var tween = create_tween()
		tween.tween_property(_level_failed_panel, "modulate:a", 1.0, 0.4)

func _create_level_failed_panel() -> void:
	var _chapter: int = level_data.get("chapter", 1)
	var fail_color: Color = ThemeManager.ACCENT_WARNING

	_level_failed_panel = PanelContainer.new()
	_level_failed_panel.name = "LevelFailedPanel"
	_level_failed_panel.anchor_left = 0.0
	_level_failed_panel.anchor_top = 0.0
	_level_failed_panel.anchor_right = 1.0
	_level_failed_panel.anchor_bottom = 1.0
	_level_failed_panel.visible = false
	_level_failed_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var fail_style = StyleBoxFlat.new()
	fail_style.bg_color = Color(0.06, 0.02, 0.02, 0.95)
	_level_failed_panel.add_theme_stylebox_override("panel", fail_style)

	var center_box = CenterContainer.new()
	center_box.anchor_right = 1.0
	center_box.anchor_bottom = 1.0
	_level_failed_panel.add_child(center_box)

	var card = PanelContainer.new()
	card.name = "FailCard"
	var card_style = ThemeManager.create_glass_panel(fail_color, 16, 2)
	card_style.shadow_color = Color(fail_color.r * 0.2, fail_color.g * 0.2, fail_color.b * 0.2, 0.4)
	card_style.shadow_size = 16
	card.add_theme_stylebox_override("panel", card_style)
	card.custom_minimum_size = Vector2(420, 300)
	center_box.add_child(card)

	var margin = MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	_level_failed_label = Label.new()
	_level_failed_label.name = "FailLabel"
	_level_failed_label.text = "SIMULATION FAILED"
	_level_failed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_failed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_level_failed_label.add_theme_color_override("font_color", fail_color)
	_level_failed_label.add_theme_font_size_override("font_size", 20)
	_level_failed_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_level_failed_label)

	var divider = ThemeManager.create_glow_divider(fail_color, 300.0)
	vbox.add_child(divider)

	var btn_row = HBoxContainer.new()
	btn_row.name = "ButtonRow"
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	vbox.add_child(btn_row)

	var retry_btn = Button.new()
	retry_btn.name = "RetryBtn"
	retry_btn.text = "↻  RETRY"
	ThemeManager.create_primary_button(retry_btn, 13, Vector2(180, 46))
	retry_btn.pressed.connect(_on_retry_button_pressed)
	btn_row.add_child(retry_btn)

	var hint_btn = Button.new()
	hint_btn.name = "FailHintBtn"
	hint_btn.text = "HINT"
	ThemeManager.create_premium_button(hint_btn, Color(0.7, 0.55, 0.1), 13, Vector2(120, 46))
	hint_btn.pressed.connect(func() -> void:
		_level_failed_panel.visible = false
		_on_hint_button_pressed()
	)
	btn_row.add_child(hint_btn)

	# Setup button hovers
	var anim = get_node_or_null("/root/AnimHelper")
	if anim:
		_setup_fail_btn_hovers.call_deferred(retry_btn, hint_btn)

	$CanvasLayer/MainUI.add_child(_level_failed_panel)

func _setup_fail_btn_hovers(retry_btn: Button, hint_btn2: Button) -> void:
	var anim = get_node_or_null("/root/AnimHelper")
	if not anim:
		return
	await get_tree().process_frame
	if retry_btn and retry_btn.is_inside_tree():
		anim.setup_button_hover(retry_btn)
	if hint_btn2 and hint_btn2.is_inside_tree():
		anim.setup_button_hover(hint_btn2)

func _on_retry_button_pressed() -> void:
	if _level_failed_panel:
		_level_failed_panel.visible = false
	# Reset simulation state so user can rewire and try again
	if circuit_board:
		circuit_board.reset_all_gates()

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
					tw.tween_interval(1)  # Show for 1 seconds
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
	_good_luck_timer.wait_time = 3.0
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
	# Glassmorphic tutorial panel with chapter accent
	var chapter: int = level_data.get("chapter", 1)
	var ch_accent: Color = ThemeManager.get_chapter_accent(chapter)
	var style = ThemeManager.create_glass_panel_accent(ch_accent, 10)
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
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
	_tutorial_continue_btn.text = "Continue >>"
	ThemeManager.create_primary_button(_tutorial_continue_btn, int(12 * ui_scale), Vector2(120 * ui_scale, 30 * ui_scale))
	_tutorial_continue_btn.pressed.connect(_on_continue_button_pressed)
	vbox.add_child(_tutorial_continue_btn)

	# Continue button hover
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
	if not is_inside_tree():
		return
	# Move tutorial panel out of the way when user drags near it
	if not tutorial_panel or not tutorial_panel.is_inside_tree() or _tutorial_complete:
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

	# Utility button row: HINT, TABLE, SHORTCUTS
	var util_row = HBoxContainer.new()
	util_row.name = "UtilRow"
	util_row.alignment = BoxContainer.ALIGNMENT_CENTER
	util_row.add_theme_constant_override("separation", 4)
	sidebar_vbox.add_child(util_row)

	_hint_btn = Button.new()
	_hint_btn.name = "HintButton"
	_hint_btn.text = "HINT"
	ThemeManager.create_premium_button(_hint_btn, Color(0.7, 0.55, 0.1), 11, Vector2(0, 32))
	_hint_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint_btn.pressed.connect(_on_hint_button_pressed)
	util_row.add_child(_hint_btn)
	var hints: Array = level_data.get("hints", [])
	if hints.is_empty():
		_hint_btn.disabled = true
		_hint_btn.text = "NO HINTS"

	var table_btn = Button.new()
	table_btn.name = "TableButton"
	table_btn.text = "TABLE"
	ThemeManager.create_premium_button(table_btn, Color(0.15, 0.4, 0.5), 11, Vector2(0, 32))
	table_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_btn.pressed.connect(_on_truth_table_button_pressed)
	util_row.add_child(table_btn)

	var help_btn = Button.new()
	help_btn.name = "HelpButton"
	help_btn.text = "?"
	ThemeManager.create_premium_button(help_btn, Color(0.3, 0.3, 0.4), 11, Vector2(32, 32))
	help_btn.pressed.connect(_on_shortcuts_button_pressed)
	util_row.add_child(help_btn)

	var settings_btn = Button.new()
	settings_btn.name = "SettingsButton"
	settings_btn.text = "SETTINGS"
	ThemeManager.create_premium_button(settings_btn, Color(0.25, 0.28, 0.35), 12, Vector2(0, 36))
	sidebar_vbox.add_child(settings_btn)
	settings_btn.pressed.connect(_on_settings_button_pressed)

	var reset_btn = Button.new()
	reset_btn.name = "ResetButton"
	reset_btn.text = "RESET LEVEL"
	ThemeManager.create_premium_button(reset_btn, Color(0.5, 0.3, 0.1), 12, Vector2(0, 36))
	sidebar_vbox.add_child(reset_btn)
	reset_btn.pressed.connect(_on_reset_button_pressed)

	var exit_btn = Button.new()
	exit_btn.name = "ExitButton"
	exit_btn.text = "EXIT"
	ThemeManager.create_danger_button(exit_btn, 12, Vector2(0, 36))
	sidebar_vbox.add_child(exit_btn)
	exit_btn.pressed.connect(_on_exit_button_pressed)

	run_button = Button.new()
	run_button.name = "RunButton"
	run_button.text = "▶  RUN SIMULATION"
	ThemeManager.create_primary_button(run_button, 14, Vector2(0, 44))
	run_button.pressed.connect(_on_run_button_pressed)
	sidebar_vbox.add_child(run_button)
	run_button.hide()
	# Setup hover animations for all sidebar buttons after layout pass
	_setup_sidebar_hover_anims(settings_btn, reset_btn, exit_btn, run_button)
	_setup_util_btn_hovers.call_deferred(_hint_btn, table_btn, help_btn)

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
	get_tree().call_deferred("change_scene_to_file", "res://scenes/level_select.tscn")

func _on_reset_button_pressed() -> void:
	var sfx = get_node_or_null("/root/SFXManager")
	if sfx:
		sfx.play_button_press()
	get_tree().reload_current_scene()

func _on_settings_button_pressed() -> void:
	if _settings_panel and _settings_panel.visible:
		var anim_close = get_node_or_null("/root/AnimHelper")
		if anim_close:
			var tw = anim_close.pop_out(_settings_panel, 0.2)
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
	# Unblock input when Continue is clicked (for 6-step tutorials, steps 2+ need interaction)
	if steps.size() >= 6 and tutorial_step == 1:
		_input_blocked = false
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
	_input_blocked = false
	# Show run button now that tutorial is done
	if run_button and not run_button.visible:
		run_button.show()
		var anim = get_node_or_null("/root/AnimHelper")
		if anim:
			anim.bounce(run_button, 1.15, 0.3)
	# Persist progress through the canonical save path
	Global.save_progress()

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

	# Mobile: add sidebar toggle button
	if resp.is_touch_device and not _sidebar_toggle_btn:
		_create_sidebar_toggle()

	# Mobile portrait: switch gate toolbox to horizontal grid
	if resp.is_mobile() and gate_toolbox:
		var scroll = gate_toolbox.get_parent() as ScrollContainer
		if scroll:
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
			scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

# --- TAP-TO-PLACE INDICATOR (mobile) ---

func _show_tap_place_indicator(gate_type: String) -> void:
	_hide_tap_place_indicator()
	_tap_place_label = Label.new()
	_tap_place_label.name = "TapPlaceLabel"
	_tap_place_label.text = "TAP BOARD TO PLACE %s" % gate_type
	_tap_place_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tap_place_label.anchor_left = 0.5
	_tap_place_label.anchor_top = 0.0
	_tap_place_label.anchor_right = 0.5
	_tap_place_label.anchor_bottom = 0.0
	_tap_place_label.offset_left = -120
	_tap_place_label.offset_top = 6
	_tap_place_label.offset_right = 120
	_tap_place_label.offset_bottom = 30
	var ch_accent: Color = ThemeManager.get_chapter_accent(level_data.get("chapter", 1))
	_tap_place_label.add_theme_color_override("font_color", ch_accent)
	_tap_place_label.add_theme_font_size_override("font_size", 13)
	$CanvasLayer/MainUI.add_child(_tap_place_label)
	# Pulse animation
	var tw = _tap_place_label.create_tween().set_loops(0)
	tw.tween_property(_tap_place_label, "modulate:a", 0.4, 0.5)
	tw.tween_property(_tap_place_label, "modulate:a", 1.0, 0.5)

func _hide_tap_place_indicator() -> void:
	if _tap_place_label and is_instance_valid(_tap_place_label):
		_tap_place_label.queue_free()
		_tap_place_label = null

# --- MOBILE SIDEBAR TOGGLE ---

func _create_sidebar_toggle() -> void:
	_sidebar_toggle_btn = Button.new()
	_sidebar_toggle_btn.name = "SidebarToggle"
	_sidebar_toggle_btn.text = "<"
	_sidebar_toggle_btn.flat = false
	_sidebar_toggle_btn.anchor_left = 0.0
	_sidebar_toggle_btn.anchor_top = 0.5
	_sidebar_toggle_btn.anchor_right = 0.0
	_sidebar_toggle_btn.anchor_bottom = 0.5
	_sidebar_toggle_btn.offset_top = -20
	_sidebar_toggle_btn.offset_bottom = 20
	_sidebar_toggle_btn.offset_right = 28
	_sidebar_toggle_btn.z_index = 10
	_sidebar_toggle_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.12, 0.85)
	style.border_color = ThemeManager.SIGNAL_ACTIVE
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	_sidebar_toggle_btn.add_theme_stylebox_override("normal", style)
	_sidebar_toggle_btn.add_theme_stylebox_override("hover", style)
	_sidebar_toggle_btn.add_theme_stylebox_override("pressed", style)
	_sidebar_toggle_btn.add_theme_color_override("font_color", ThemeManager.SIGNAL_ACTIVE)
	_sidebar_toggle_btn.add_theme_font_size_override("font_size", 16)
	_sidebar_toggle_btn.pressed.connect(_toggle_sidebar)

	$CanvasLayer/MainUI.add_child(_sidebar_toggle_btn)
	_update_sidebar_toggle_position()

func _toggle_sidebar() -> void:
	var sidebar = get_node_or_null("CanvasLayer/MainUI/HBoxContainer/Sidebar") as PanelContainer
	if not sidebar:
		return
	_sidebar_visible = not _sidebar_visible
	sidebar.visible = _sidebar_visible
	_sidebar_toggle_btn.text = "<" if _sidebar_visible else ">"
	_update_sidebar_toggle_position()
	# Keep toggle on top so it stays visible when sidebar is closed
	var main_ui = get_node_or_null("CanvasLayer/MainUI")
	if main_ui and _sidebar_toggle_btn.get_index() < main_ui.get_child_count() - 1:
		main_ui.move_child(_sidebar_toggle_btn, main_ui.get_child_count() - 1)
	# Re-trigger camera layout  
	var resp = get_node_or_null("/root/ResponsiveManager")
	if resp:
		var cam = get_node_or_null("Camera2D") as Camera2D
		if cam:
			if _sidebar_visible:
				cam.zoom = resp.get_camera_zoom()
				cam.position = resp.get_camera_center()
			else:
				# Full screen for board — recalculate
				var vp = get_viewport().get_visible_rect().size
				var z = clampf(vp.x / 750.0, 0.5, 1.6)
				cam.zoom = Vector2(z, z)
				cam.position = Vector2(720.0, 130.0 + 100.0 / z)

func _update_sidebar_toggle_position() -> void:
	if not _sidebar_toggle_btn:
		return
	var resp = get_node_or_null("/root/ResponsiveManager")
	var sw: float = resp.sidebar_width if resp else 250.0
	_sidebar_toggle_btn.visible = true
	if _sidebar_visible:
		_sidebar_toggle_btn.offset_left = sw
		_sidebar_toggle_btn.offset_right = sw + 28
	else:
		# When closed: pin to left edge so "open" (>) button is always visible
		_sidebar_toggle_btn.offset_left = 0
		_sidebar_toggle_btn.offset_right = 28
	# Ensure toggle is drawn on top of HBox and other UI
	var main_ui = get_node_or_null("CanvasLayer/MainUI")
	if main_ui and _sidebar_toggle_btn.get_parent() == main_ui and _sidebar_toggle_btn.get_index() < main_ui.get_child_count() - 1:
		main_ui.move_child(_sidebar_toggle_btn, main_ui.get_child_count() - 1)

# --- SETTINGS PANEL ---

func _create_settings_panel() -> void:
	_settings_panel = PanelContainer.new()
	_settings_panel.name = "SettingsPanel"
	_settings_panel.anchor_left = 0.25
	_settings_panel.anchor_top = 0.15
	_settings_panel.anchor_right = 0.75
	_settings_panel.anchor_bottom = 0.85
	_settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var _chapter: int = level_data.get("chapter", 1)
	var ch_accent: Color = ThemeManager.get_chapter_accent(_chapter)
	var bg_style = ThemeManager.create_glass_panel(ch_accent, 12, 2)
	bg_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	bg_style.shadow_size = 12
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
	title_lbl.add_theme_color_override("font_color", ch_accent)
	title_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title_lbl)

	var settings_div = ThemeManager.create_glow_divider(ch_accent, 200.0)
	vbox.add_child(settings_div)

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
	ThemeManager.create_primary_button(close_btn, 14, Vector2(120, 40))
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
	var anim_setup = get_node_or_null("/root/AnimHelper")
	if anim_setup:
		_setup_close_btn_hover.call_deferred(close_btn)

func _setup_close_btn_hover(btn: Button) -> void:
	var anim_h = get_node_or_null("/root/AnimHelper")
	if anim_h and btn and btn.is_inside_tree():
		anim_h.setup_button_hover(btn)

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

# ===================================================================
# UTILITY BUTTON HOVERS
# ===================================================================

func _setup_util_btn_hovers(h_btn: Button, t_btn: Button, hp_btn: Button) -> void:
	var anim = get_node_or_null("/root/AnimHelper")
	if not anim:
		return
	for btn in [h_btn, t_btn, hp_btn]:
		if btn and btn.is_inside_tree():
			anim.setup_button_hover(btn, 1.05)

# ===================================================================
# KEYBOARD SHORTCUTS PANEL
# ===================================================================

func _on_shortcuts_button_pressed() -> void:
	var sfx = get_node_or_null("/root/SFXManager")
	if sfx:
		sfx.play_button_press()
	if _shortcuts_panel and _shortcuts_panel.visible:
		var anim_out = get_node_or_null("/root/AnimHelper")
		if anim_out:
			var tw = anim_out.pop_out(_shortcuts_panel, 0.2)
			await tw.finished
		_shortcuts_panel.visible = false
		return
	if not _shortcuts_panel:
		_create_shortcuts_panel()
	_shortcuts_panel.visible = true
	var anim = get_node_or_null("/root/AnimHelper")
	if anim:
		anim.pop_in(_shortcuts_panel, 0.3)

func _create_shortcuts_panel() -> void:
	var _chapter: int = level_data.get("chapter", 1)
	var ch_accent: Color = ThemeManager.get_chapter_accent(_chapter)

	_shortcuts_panel = PanelContainer.new()
	_shortcuts_panel.name = "ShortcutsPanel"
	_shortcuts_panel.anchor_left = 0.5
	_shortcuts_panel.anchor_top = 0.5
	_shortcuts_panel.anchor_right = 0.5
	_shortcuts_panel.anchor_bottom = 0.5
	_shortcuts_panel.offset_left = -185
	_shortcuts_panel.offset_top = -165
	_shortcuts_panel.offset_right = 185
	_shortcuts_panel.offset_bottom = 165
	_shortcuts_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg_style = ThemeManager.create_glass_panel(ch_accent, 12, 2)
	bg_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	bg_style.shadow_size = 12
	_shortcuts_panel.add_theme_stylebox_override("panel", bg_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_shortcuts_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = "KEYBOARD SHORTCUTS"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", ch_accent)
	title_lbl.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title_lbl)

	var div = ThemeManager.create_glow_divider(ch_accent, 200.0)
	vbox.add_child(div)

	var shortcuts_data = [
		["Ctrl + Z", "Undo last action"],
		["Ctrl + Shift + Z", "Redo last action"],
		["Ctrl + Y", "Redo (alternate)"],
		["Delete", "Remove selected gate"],
		["Escape", "Cancel current wire"],
		["Click + Drag", "Draw wires between nodes"],
		["Click gate icon", "Place gate on board"],
	]

	for shortcut in shortcuts_data:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var key_lbl = Label.new()
		key_lbl.text = shortcut[0]
		key_lbl.add_theme_color_override("font_color", ThemeManager.ACCENT_WARNING)
		key_lbl.add_theme_font_size_override("font_size", 12)
		key_lbl.custom_minimum_size = Vector2(130, 0)
		row.add_child(key_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = shortcut[1]
		desc_lbl.add_theme_color_override("font_color", ThemeManager.TERMINAL_WHITE)
		desc_lbl.add_theme_font_size_override("font_size", 12)
		row.add_child(desc_lbl)

		vbox.add_child(row)

	var sc_spacer = Control.new()
	sc_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(sc_spacer)

	var close_btn = Button.new()
	close_btn.text = "CLOSE"
	ThemeManager.create_primary_button(close_btn, 12, Vector2(100, 34))
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func() -> void:
		var anim_c = get_node_or_null("/root/AnimHelper")
		if anim_c:
			var tw_c = anim_c.pop_out(_shortcuts_panel, 0.2)
			await tw_c.finished
		_shortcuts_panel.visible = false
	)
	vbox.add_child(close_btn)

	$CanvasLayer/MainUI.add_child(_shortcuts_panel)

	var anim_setup = get_node_or_null("/root/AnimHelper")
	if anim_setup:
		_setup_panel_close_hover.call_deferred(close_btn)

# ===================================================================
# TRUTH TABLE REFERENCE PANEL
# ===================================================================

func _on_truth_table_button_pressed() -> void:
	var sfx = get_node_or_null("/root/SFXManager")
	if sfx:
		sfx.play_button_press()
	if _truth_table_panel and _truth_table_panel.visible:
		var anim_out = get_node_or_null("/root/AnimHelper")
		if anim_out:
			var tw = anim_out.pop_out(_truth_table_panel, 0.2)
			await tw.finished
		_truth_table_panel.visible = false
		return
	if not _truth_table_panel:
		_create_truth_table_panel()
	_truth_table_panel.visible = true
	var anim = get_node_or_null("/root/AnimHelper")
	if anim:
		anim.pop_in(_truth_table_panel, 0.3)

func _create_truth_table_panel() -> void:
	var _chapter: int = level_data.get("chapter", 1)
	var ch_accent: Color = ThemeManager.get_chapter_accent(_chapter)
	var allowed: Array = level_data.get("allowed_gates", [])

	_truth_table_panel = PanelContainer.new()
	_truth_table_panel.name = "TruthTablePanel"
	_truth_table_panel.anchor_left = 0.5
	_truth_table_panel.anchor_top = 0.5
	_truth_table_panel.anchor_right = 0.5
	_truth_table_panel.anchor_bottom = 0.5
	var panel_h: int = mini(120 + allowed.size() * 110, 450)
	_truth_table_panel.offset_left = -200
	_truth_table_panel.offset_top = -panel_h / 2.0
	_truth_table_panel.offset_right = 200
	_truth_table_panel.offset_bottom = panel_h / 2.0
	_truth_table_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg_style = ThemeManager.create_glass_panel(ch_accent, 12, 2)
	bg_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	bg_style.shadow_size = 12
	_truth_table_panel.add_theme_stylebox_override("panel", bg_style)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_truth_table_panel.add_child(scroll)

	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = "TRUTH TABLE REFERENCE"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", ch_accent)
	title_lbl.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title_lbl)

	var div = ThemeManager.create_glow_divider(ch_accent, 220.0)
	vbox.add_child(div)

	for gate_type in allowed:
		var table: Dictionary = GateIcon.TRUTH_TABLES.get(gate_type, {})
		if table.is_empty():
			continue

		var gate_color: Color = ThemeManager.get_gate_color(gate_type)

		var gate_lbl = Label.new()
		gate_lbl.text = "-- %s GATE --" % gate_type
		gate_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gate_lbl.add_theme_color_override("font_color", gate_color)
		gate_lbl.add_theme_font_size_override("font_size", 13)
		vbox.add_child(gate_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = table["desc"]
		desc_lbl.add_theme_color_override("font_color", ThemeManager.TERMINAL_WHITE)
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(desc_lbl)

		var header_lbl = Label.new()
		header_lbl.text = table["header"]
		header_lbl.add_theme_color_override("font_color", ch_accent)
		header_lbl.add_theme_font_size_override("font_size", 12)
		header_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(header_lbl)

		for row_text in table["rows"]:
			var row_lbl = Label.new()
			row_lbl.text = row_text
			row_lbl.add_theme_color_override("font_color", ThemeManager.TERMINAL_WHITE)
			row_lbl.add_theme_font_size_override("font_size", 12)
			row_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(row_lbl)

		var gate_spacer = Control.new()
		gate_spacer.custom_minimum_size = Vector2(0, 6)
		vbox.add_child(gate_spacer)

	var close_btn = Button.new()
	close_btn.text = "CLOSE"
	ThemeManager.create_primary_button(close_btn, 12, Vector2(100, 34))
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func() -> void:
		var anim_c = get_node_or_null("/root/AnimHelper")
		if anim_c:
			var tw_c = anim_c.pop_out(_truth_table_panel, 0.2)
			await tw_c.finished
		_truth_table_panel.visible = false
	)
	vbox.add_child(close_btn)

	$CanvasLayer/MainUI.add_child(_truth_table_panel)

	var anim_setup = get_node_or_null("/root/AnimHelper")
	if anim_setup:
		_setup_panel_close_hover.call_deferred(close_btn)

# ===================================================================
# HINT SYSTEM
# ===================================================================

func _on_hint_button_pressed() -> void:
	var hints_arr: Array = level_data.get("hints", [])
	if hints_arr.is_empty():
		return
	var sfx = get_node_or_null("/root/SFXManager")
	if sfx:
		sfx.play_button_press()

	# All free hints (first 2) have been used
	if _hints_revealed >= 2:
		var ad_mgr = get_node_or_null("/root/AdManager")
		if _hints_revealed < hints_arr.size():
			# More hints exist — require a rewarded ad to unlock the next one
			if ad_mgr and ad_mgr.is_rewarded_ready():
				ad_mgr.show_rewarded(_reveal_next_hint)
				return  # Wait for reward callback
			else:
				# Ad not ready — show panel with a "watch ad" nudge
				_refresh_hint_panel_visible()
				return
		else:
			# All hints already revealed — offer a rewarded ad to replay them
			if ad_mgr and ad_mgr.is_rewarded_ready():
				ad_mgr.show_rewarded(func() -> void:
					_refresh_hint_panel_visible()
				)
				return
			else:
				# No ad ready — just reopen the panel silently
				_refresh_hint_panel_visible()
				return

	# Free hint (hints_revealed < 2) — reveal directly
	_reveal_next_hint()

func _refresh_hint_panel_visible() -> void:
	"""Rebuild and show the hint panel without incrementing the hint counter."""
	if _hint_panel:
		_hint_panel.queue_free()
		_hint_panel = null
	_create_hint_panel()
	_hint_panel.visible = true
	var anim_r = get_node_or_null("/root/AnimHelper")
	if anim_r:
		anim_r.pop_in(_hint_panel, 0.3)

func _reveal_next_hint() -> void:
	var hints_arr: Array = level_data.get("hints", [])
	if _hints_revealed < hints_arr.size():
		_hints_revealed += 1

	# Rebuild hint panel with updated content
	if _hint_panel:
		_hint_panel.queue_free()
		_hint_panel = null
	_create_hint_panel()
	_hint_panel.visible = true
	var anim = get_node_or_null("/root/AnimHelper")
	if anim:
		anim.pop_in(_hint_panel, 0.3)

	# Update button text
	if _hint_btn:
		_hint_btn.text = "HINT %d/%d" % [_hints_revealed, hints_arr.size()]

func _create_hint_panel() -> void:
	var hints_arr: Array = level_data.get("hints", [])

	_hint_panel = PanelContainer.new()
	_hint_panel.name = "HintPanel"
	_hint_panel.anchor_left = 0.5
	_hint_panel.anchor_top = 0.5
	_hint_panel.anchor_right = 0.5
	_hint_panel.anchor_bottom = 0.5
	var panel_h: int = 100 + _hints_revealed * 40
	_hint_panel.offset_left = -180
	_hint_panel.offset_top = -panel_h / 2.0
	_hint_panel.offset_right = 180
	_hint_panel.offset_bottom = panel_h / 2.0
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var hint_accent = Color(0.85, 0.65, 0.1)
	var bg_style = ThemeManager.create_glass_panel(hint_accent, 12, 2)
	bg_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	bg_style.shadow_size = 12
	_hint_panel.add_theme_stylebox_override("panel", bg_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_hint_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = "HINTS (%d/%d)" % [_hints_revealed, hints_arr.size()]
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", hint_accent)
	title_lbl.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title_lbl)

	var div = ThemeManager.create_glow_divider(hint_accent, 160.0)
	vbox.add_child(div)

	for i in range(_hints_revealed):
		var hint_lbl = Label.new()
		hint_lbl.text = ">> " + hints_arr[i]
		hint_lbl.add_theme_color_override("font_color", ThemeManager.TERMINAL_WHITE)
		hint_lbl.add_theme_font_size_override("font_size", 12)
		hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		hint_lbl.custom_minimum_size = Vector2(300, 0)
		vbox.add_child(hint_lbl)

	if _hints_revealed < hints_arr.size():
		var more_lbl = Label.new()
		if _hints_revealed >= 2:
			more_lbl.text = "▶ Watch a short ad to unlock the next hint"
			more_lbl.add_theme_color_override("font_color", Color(0.85, 0.65, 0.1))
		else:
			more_lbl.text = "Tap HINT again for the next free hint..."
			more_lbl.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
		more_lbl.add_theme_font_size_override("font_size", 11)
		more_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		more_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		more_lbl.custom_minimum_size = Vector2(300, 0)
		vbox.add_child(more_lbl)
	elif _hints_revealed >= hints_arr.size():
		var done_lbl = Label.new()
		done_lbl.text = "✓ All hints revealed"
		done_lbl.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
		done_lbl.add_theme_font_size_override("font_size", 11)
		done_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(done_lbl)

	var close_btn = Button.new()
	close_btn.text = "GOT IT"
	ThemeManager.create_primary_button(close_btn, 12, Vector2(100, 34))
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func() -> void:
		var anim_c = get_node_or_null("/root/AnimHelper")
		if anim_c:
			var tw_c = anim_c.pop_out(_hint_panel, 0.2)
			await tw_c.finished
		_hint_panel.visible = false
	)
	vbox.add_child(close_btn)

	$CanvasLayer/MainUI.add_child(_hint_panel)

	var anim_setup = get_node_or_null("/root/AnimHelper")
	if anim_setup:
		_setup_panel_close_hover.call_deferred(close_btn)

# ===================================================================
# ACHIEVEMENT POPUPS
# ===================================================================

func _check_achievements() -> void:
	var newly_unlocked: Array[String] = Global.check_and_unlock_achievements()
	for ach_id in newly_unlocked:
		await _show_achievement_popup(ach_id)

func _show_achievement_popup(ach_id: String) -> void:
	var ach: Dictionary = Global.ACHIEVEMENT_DEFS.get(ach_id, {})
	if ach.is_empty():
		return

	var popup = PanelContainer.new()
	popup.name = "AchievementPopup"
	popup.anchor_left = 1.0
	popup.anchor_top = 0.0
	popup.anchor_right = 1.0
	popup.anchor_bottom = 0.0
	popup.offset_left = -290
	popup.offset_top = 10
	popup.offset_right = -10
	popup.offset_bottom = 74
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style = ThemeManager.create_glass_panel(ThemeManager.ACCENT_WARNING, 10, 2)
	style.shadow_size = 10
	popup.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	popup.add_child(hbox)

	var trophy_lbl = Label.new()
	trophy_lbl.text = "★"
	trophy_lbl.add_theme_font_size_override("font_size", 28)
	trophy_lbl.add_theme_color_override("font_color", ThemeManager.ACCENT_WARNING)
	hbox.add_child(trophy_lbl)

	var text_vbox = VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(text_vbox)

	var header_lbl = Label.new()
	header_lbl.text = "ACHIEVEMENT UNLOCKED!"
	header_lbl.add_theme_color_override("font_color", ThemeManager.ACCENT_WARNING)
	header_lbl.add_theme_font_size_override("font_size", 11)
	text_vbox.add_child(header_lbl)

	var name_lbl = Label.new()
	name_lbl.text = ach["title"]
	name_lbl.add_theme_color_override("font_color", ThemeManager.TERMINAL_WHITE)
	name_lbl.add_theme_font_size_override("font_size", 14)
	text_vbox.add_child(name_lbl)

	$CanvasLayer/MainUI.add_child(popup)

	# Slide in from right
	popup.modulate.a = 0.0
	var target_left: float = popup.offset_left
	var target_right: float = popup.offset_right
	popup.offset_left = -10
	popup.offset_right = 270

	var tw = popup.create_tween().set_parallel(true)
	tw.tween_property(popup, "modulate:a", 1.0, 0.3)
	tw.tween_property(popup, "offset_left", target_left, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(popup, "offset_right", target_right, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished

	# Hold then fade out
	await get_tree().create_timer(2.5).timeout
	var tw2 = popup.create_tween()
	tw2.tween_property(popup, "modulate:a", 0.0, 0.5)
	await tw2.finished
	popup.queue_free()

# ===================================================================
# SHARED PANEL HELPERS
# ===================================================================

func _setup_panel_close_hover(btn: Button) -> void:
	var anim_h = get_node_or_null("/root/AnimHelper")
	if anim_h and btn and btn.is_inside_tree():
		anim_h.setup_button_hover(btn)