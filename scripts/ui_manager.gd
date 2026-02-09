# Professional UI Manager with enhanced UX
extends Control
class_name UIManager

# UI Components
var level_info_panel: PanelContainer
var gate_buttons_container: GridContainer
var simulation_controls: HBoxContainer
var level_status_label: Label
var objective_label: Label
var gate_buttons: Dictionary = {}  # gate_type -> Button
var game_manager: GameManager

# UI State
var current_allowed_gates: Array[String] = []
var level_complete: bool = false
var selected_gate: String = ""

signal run_simulation
signal reset_level
signal gate_selected(gate_type: String)

func _ready() -> void:
	await get_tree().process_frame
	game_manager = get_node_or_null("/root/Main")
	create_ui()

func create_ui() -> void:
	"""Build the complete UI with modern styling."""
	# Color scheme
	var bg_color = Color(0.15, 0.15, 0.15, 0.95)
	var accent_color = Color(0.2, 0.6, 1.0, 1.0)
	var success_color = Color(0.2, 1.0, 0.4, 1.0)
	
	# ============ RIGHT SIDE PANEL ============
	var right_panel = PanelContainer.new()
	right_panel.anchor_left = 1.0
	right_panel.anchor_top = 0.0
	right_panel.anchor_right = 1.0
	right_panel.anchor_bottom = 1.0
	right_panel.offset_left = -320
	right_panel.offset_right = 0
	right_panel.offset_top = 0
	right_panel.offset_bottom = 0
	
	# Panel styling
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = bg_color
	panel_style.border_color = accent_color
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	right_panel.add_theme_stylebox_override("panel", panel_style)
	
	add_child(right_panel)
	
	# Main container for right panel
	var right_container = VBoxContainer.new()
	right_container.add_theme_constant_override("separation", 15)
	right_panel.add_child(right_container)
	var right_margin = MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 15)
	right_margin.add_theme_constant_override("margin_right", 15)
	right_margin.add_theme_constant_override("margin_top", 15)
	right_margin.add_theme_constant_override("margin_bottom", 15)
	right_container.add_child(right_margin)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 12)
	right_margin.add_child(content_vbox)
	
	# ============ HEADER ============
	var header_label = Label.new()
	header_label.text = "⚙ CIRCUIT WEAVER"
	header_label.add_theme_font_size_override("font_size", 18)
	header_label.add_theme_color_override("font_color", accent_color)
	content_vbox.add_child(header_label)
	
	# Level progress
	level_status_label = Label.new()
	level_status_label.text = "Level 1 / 4"
	level_status_label.add_theme_font_size_override("font_size", 12)
	level_status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	content_vbox.add_child(level_status_label)
	
	# Separator
	var sep1 = HSeparator.new()
	content_vbox.add_child(sep1)
	
	# ============ OBJECTIVE SECTION ============
	var obj_title = Label.new()
	obj_title.text = "📋 OBJECTIVE"
	obj_title.add_theme_font_size_override("font_size", 13)
	obj_title.add_theme_color_override("font_color", accent_color)
	content_vbox.add_child(obj_title)
	
	objective_label = Label.new()
	objective_label.text = "Build your circuit here"
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	objective_label.custom_minimum_size = Vector2(280, 60)
	objective_label.add_theme_font_size_override("font_size", 11)
	content_vbox.add_child(objective_label)
	
	# ============ GATES SECTION ============
	var gates_title = Label.new()
	gates_title.text = "🔧 AVAILABLE GATES"
	gates_title.add_theme_font_size_override("font_size", 13)
	gates_title.add_theme_color_override("font_color", accent_color)
	content_vbox.add_child(gates_title)
	
	# Gate buttons grid
	gate_buttons_container = GridContainer.new()
	gate_buttons_container.columns = 2
	gate_buttons_container.add_theme_constant_override("h_separation", 8)
	gate_buttons_container.add_theme_constant_override("v_separation", 8)
	content_vbox.add_child(gate_buttons_container)
	
	# Create gate buttons (will be filtered by set_level_info)
	var all_gates = ["AND", "OR", "NOT", "XOR", "NAND", "NOR", "XNOR"]
	for gate in all_gates:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(130, 40)
		btn.text = gate
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_on_gate_button_pressed.bind(gate))
		btn.disabled = true  # Start disabled, enabled based on level
		gate_buttons[gate] = btn
		gate_buttons_container.add_child(btn)
	
	# Separator
	var sep2 = HSeparator.new()
	content_vbox.add_child(sep2)
	
	# ============ CONTROLS SECTION ============
	var controls_title = Label.new()
	controls_title.text = "🎮 CONTROLS"
	controls_title.add_theme_font_size_override("font_size", 13)
	controls_title.add_theme_color_override("font_color", accent_color)
	content_vbox.add_child(controls_title)
	
	simulation_controls = HBoxContainer.new()
	simulation_controls.add_theme_constant_override("separation", 8)
	content_vbox.add_child(simulation_controls)
	
	# Run button
	var run_btn = Button.new()
	run_btn.text = "▶ RUN"
	run_btn.custom_minimum_size = Vector2(140, 45)
	run_btn.add_theme_font_size_override("font_size", 12)
	run_btn.add_theme_color_override("font_color", success_color)
	var run_style = StyleBoxFlat.new()
	run_style.bg_color = Color(0.1, 0.4, 0.1, 0.8)
	run_style.corner_radius_top_left = 6
	run_style.corner_radius_top_right = 6
	run_style.corner_radius_bottom_left = 6
	run_style.corner_radius_bottom_right = 6
	run_btn.add_theme_stylebox_override("normal", run_style)
	var run_hover_style = StyleBoxFlat.new()
	run_hover_style.bg_color = Color(0.15, 0.5, 0.15, 0.9)
	run_hover_style.corner_radius_top_left = 6
	run_hover_style.corner_radius_top_right = 6
	run_hover_style.corner_radius_bottom_left = 6
	run_hover_style.corner_radius_bottom_right = 6
	run_btn.add_theme_stylebox_override("hover", run_hover_style)
	run_btn.pressed.connect(_on_run_pressed)
	simulation_controls.add_child(run_btn)
	
	# Reset button
	var reset_btn = Button.new()
	reset_btn.text = "⟲ RESET"
	reset_btn.custom_minimum_size = Vector2(140, 45)
	reset_btn.add_theme_font_size_override("font_size", 12)
	var reset_style = StyleBoxFlat.new()
	reset_style.bg_color = Color(0.4, 0.3, 0.1, 0.8)
	reset_style.corner_radius_top_left = 6
	reset_style.corner_radius_top_right = 6
	reset_style.corner_radius_bottom_left = 6
	reset_style.corner_radius_bottom_right = 6
	reset_btn.add_theme_stylebox_override("normal", reset_style)
	var reset_hover_style = StyleBoxFlat.new()
	reset_hover_style.bg_color = Color(0.5, 0.4, 0.15, 0.9)
	reset_hover_style.corner_radius_top_left = 6
	reset_hover_style.corner_radius_top_right = 6
	reset_hover_style.corner_radius_bottom_left = 6
	reset_hover_style.corner_radius_bottom_right = 6
	reset_btn.add_theme_stylebox_override("hover", reset_hover_style)
	reset_btn.pressed.connect(_on_reset_pressed)
	simulation_controls.add_child(reset_btn)
	
	# ============ OUTPUT DISPLAY ============
	var sep_output = HSeparator.new()
	content_vbox.add_child(sep_output)
	
	var output_title = Label.new()
	output_title.text = "📊 OUTPUT"
	output_title.add_theme_font_size_override("font_size", 13)
	output_title.add_theme_color_override("font_color", accent_color)
	content_vbox.add_child(output_title)
	
	var output_display = VBoxContainer.new()
	output_display.name = "OutputDisplay"
	output_display.add_theme_constant_override("separation", 8)
	content_vbox.add_child(output_display)
	
	var target_label = Label.new()
	target_label.name = "TargetLabel"
	target_label.text = "Target: [color=ffaa00]—[/color]"
	target_label.add_theme_font_size_override("font_size", 12)
	output_display.add_child(target_label)
	
	var actual_label = Label.new()
	actual_label.name = "ActualLabel"
	actual_label.text = "Actual: [color=666666]—[/color]"
	actual_label.add_theme_font_size_override("font_size", 12)
	output_display.add_child(actual_label)
	
	# ============ INSTRUCTIONS ============
	var sep3 = HSeparator.new()
	content_vbox.add_child(sep3)
	
	var instructions_title = Label.new()
	instructions_title.text = "💡 TIPS"
	instructions_title.add_theme_font_size_override("font_size", 12)
	instructions_title.add_theme_color_override("font_color", accent_color)
	content_vbox.add_child(instructions_title)
	
	var tips_label = Label.new()
	tips_label.text = "1. Click gate button to place\n2. Click gates to drag\n3. Left-click output port to wire\n4. Click input port to complete\n5. RIGHT-CLICK to cancel wire"
	tips_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	tips_label.add_theme_font_size_override("font_size", 10)
	tips_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	content_vbox.add_child(tips_label)
	
	content_vbox.add_child(Control.new())  # Spacer

func set_level_info(level_name: String, description: String, allowed_gates: Array[String], target_output: int = 0) -> void:
	"""Update UI with level information and enable/disable gates."""
	current_allowed_gates = allowed_gates
	level_complete = false
	selected_gate = ""
	
	# Update level status
	if game_manager:
		level_status_label.text = "Level %d / 4" % (game_manager.current_level_index + 1)
	
	# Update objective
	objective_label.text = "[b]%s[/b]\n%s" % [level_name, description]
	
	# Update target output display
	var target_color = "00ff00" if target_output == 1 else "ff0000"
	var output_display = get_node_or_null("PanelContainer/VBoxContainer/MarginContainer/VBoxContainer/OutputDisplay")
	if output_display:
		var target_label = output_display.get_node_or_null("TargetLabel")
		if target_label:
			target_label.text = "Target: [color=%s]%d[/color]" % [target_color, target_output]
	
	# Update gate button states
	for gate in gate_buttons.keys():
		var btn = gate_buttons[gate]
		var is_allowed = gate in allowed_gates
		
		btn.disabled = not is_allowed
		
		if is_allowed:
			# Enable and style
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.2, 0.4, 0.6, 0.8)
			for corner in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
				style.set(corner, 4)
			btn.add_theme_stylebox_override("normal", style)
			
			var hover_style = StyleBoxFlat.new()
			hover_style.bg_color = Color(0.3, 0.5, 0.8, 0.9)
			for corner in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
				hover_style.set(corner, 4)
			btn.add_theme_stylebox_override("hover", hover_style)
			
			var focus_style = StyleBoxFlat.new()
			focus_style.bg_color = Color(0.4, 0.6, 1.0, 1.0)
			for corner in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
				focus_style.set(corner, 4)
			btn.add_theme_stylebox_override("focus", focus_style)
		else:
			# Disable and gray out
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.2, 0.2, 0.2, 0.5)
			for corner in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
				style.set(corner, 4)
			btn.add_theme_stylebox_override("normal", style)

func _on_gate_button_pressed(gate_type: String) -> void:
	"""Handle gate button press."""
	if gate_type not in current_allowed_gates:
		return
	
	selected_gate = gate_type
	gate_selected.emit(gate_type)
	
	if game_manager and game_manager.circuit_board:
		var new_gate = game_manager.circuit_board.place_gate(gate_type, Vector2i(8, 5))
		if new_gate:
			print("📍 Placed %s gate" % gate_type)

func _on_run_pressed() -> void:
	"""Handle run button."""
	run_simulation.emit()
	print("▶ Running simulation...")

func _on_reset_pressed() -> void:
	"""Handle reset button."""
	reset_level.emit()
	print("⟲ Resetting level...")

func show_level_complete(level_name: String) -> void:
	"""Show completion message."""
	level_complete = true
	print("✓ Level Complete: %s" % level_name)
	# Can add animation/sound here later

func update_wiring_status(_is_wiring: bool) -> void:
	"""Update UI to reflect wiring mode status."""
	# Visual feedback for wiring mode
	pass

func update_output_display(actual_value: int, is_correct: bool = false) -> void:
	"""Update the displayed output value."""
	var color = "00ff00" if actual_value == 1 else "ff0000"
	var status = "✓" if is_correct else "✗"
	
	var output_display = get_node_or_null("PanelContainer/VBoxContainer/MarginContainer/VBoxContainer/OutputDisplay")
	if output_display:
		var actual_label = output_display.get_node_or_null("ActualLabel")
		if actual_label:
			actual_label.text = "Actual: [color=%s]%d[/color] %s" % [color, actual_value, status]
