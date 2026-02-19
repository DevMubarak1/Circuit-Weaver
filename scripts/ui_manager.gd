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
var gate_toolbox: GateToolbox

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
	setup_gate_toolbox()

func create_ui() -> void:
	"""Build the complete UI with Midnight Architect theme."""
	# Use Midnight Architect palette from ThemeManager
	var bg_color = ThemeManager.MIDNIGHT_BG
	var signal_active = ThemeManager.SIGNAL_ACTIVE
	var _success_color = ThemeManager.GATE_OR_GREEN
	var accent_color: Color = ThemeManager.SIGNAL_ACTIVE # Electric Cyan for accent
	
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
	
	# Panel styling with Midnight Architect theme
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = bg_color
	panel_style.border_color = signal_active  # Electric cyan border for glow
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
	header_label.text = "CIRCUIT WEAVER"
	# Apply header styling with Midnight Architect electric cyan
	ThemeManager.apply_header_style(header_label, ThemeManager.SIGNAL_ACTIVE)
	content_vbox.add_child(header_label)
	
	# Level progress
	level_status_label = Label.new()
	level_status_label.text = "Level 1 / 4"
	ThemeManager.apply_body_style(level_status_label, ThemeManager.TERMINAL_WHITE)
	content_vbox.add_child(level_status_label)
	
	# Separator
	var sep1 = HSeparator.new()
	content_vbox.add_child(sep1)
	
	# ============ OBJECTIVE SECTION ============
	var obj_title = Label.new()
	obj_title.text = "OBJECTIVE"
	# Apply header styling with Midnight Architect emerald green
	ThemeManager.apply_header_style(obj_title, ThemeManager.GATE_OR_GREEN)
	content_vbox.add_child(obj_title)
	
	objective_label = Label.new()
	objective_label.text = "Build your circuit here"
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	objective_label.custom_minimum_size = Vector2(280, 60)
	ThemeManager.apply_body_style(objective_label, ThemeManager.TERMINAL_WHITE)
	content_vbox.add_child(objective_label)
	
	# ============ GATES SECTION ============
	var gates_title = Label.new()
	gates_title.text = "AVAILABLE GATES"
	gates_title.add_theme_font_size_override("font_size", 13)
	gates_title.add_theme_color_override("font_color", accent_color)
	content_vbox.add_child(gates_title)
	
	var gates_info = Label.new()
	gates_info.text = "Drag gates to circuit board"
	gates_info.add_theme_font_size_override("font_size", 10)
	gates_info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	content_vbox.add_child(gates_info)
	
	# Gate buttons grid with TextureButtons and icons
	gate_buttons_container = GridContainer.new()
	gate_buttons_container.columns = 2
	gate_buttons_container.add_theme_constant_override("h_separation", 8)
	gate_buttons_container.add_theme_constant_override("v_separation", 8)
	content_vbox.add_child(gate_buttons_container)
	
	# Create gate TextureButtons with SVG icons (will be filtered by set_level_info)
	var all_gates = ["AND", "OR", "NOT", "XOR", "NAND", "NOR", "XNOR"]
	var gate_icon_paths = {
		"AND": "res://assets/AND_ANSI.svg",
		"OR": "res://assets/OR_ANSI.svg",
		"NOT": "res://assets/NOT_ANSI.svg",
		"XOR": "res://assets/XOR_ANSI.svg",
		"NAND": "res://assets/NAND_ANSI.svg",
		"NOR": "res://assets/NOR_ANSI.svg",
		"XNOR": "res://assets/XNOR_ANSI.svg"
	}
	
	for gate in all_gates:
		# Container for gate label and button
		var gate_item = VBoxContainer.new()
		gate_item.add_theme_constant_override("separation", 0)
		
		# Label above button
		var label = Label.new()
		label.text = gate
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		label.custom_minimum_size = Vector2(130, 16)  # Match button width for proper centering
		gate_item.add_child(label)
		
		# TextureButton with SVG icon
		var btn = TextureButton.new()
		btn.custom_minimum_size = Vector2(130, 100)
		# Godot 4: TextureButton does not have expand_mode. Remove or set stretch_mode if needed.
		# btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED  # Optional, or remove line
		
		# Load SVG texture
		var icon_path = gate_icon_paths.get(gate)
		if icon_path and ResourceLoader.exists(icon_path):
			var texture = load(icon_path)
			if texture:
				btn.texture_normal = texture
		
		btn.modulate = Color.WHITE
		btn.name = "GateButton_%s" % gate
		btn.set_meta("gate_type", gate)
		btn.tooltip_text = "Drag %s gate to circuit board" % gate
		btn.pressed.connect(_on_gate_button_pressed.bind(gate))
		
		# Setup button drag detection signals
		btn.button_down.connect(func(): _on_gate_button_down(btn, gate))
		btn.button_up.connect(func(): _on_gate_button_up(gate))
		
		btn.disabled = true  # Start disabled, enabled based on level
		
		gate_item.add_child(btn)
		
		gate_buttons[gate] = btn
		gate_buttons_container.add_child(gate_item)
	
	# Separator
	var sep2 = HSeparator.new()
	content_vbox.add_child(sep2)
	
	# ============ CONTROLS SECTION ============
	var controls_title = Label.new()
	controls_title.text = "CONTROLS"
	controls_title.add_theme_font_size_override("font_size", 13)
	controls_title.add_theme_color_override("font_color", accent_color)
	content_vbox.add_child(controls_title)
	
	simulation_controls = HBoxContainer.new()
	simulation_controls.add_theme_constant_override("separation", 8)
	content_vbox.add_child(simulation_controls)
	
	# Run button - apply digital frontier style with success color (emerald green)
	var run_btn = Button.new()
	run_btn.text = "> RUN"
	run_btn.custom_minimum_size = Vector2(140, 45)
	ThemeManager.apply_button_style(run_btn, ThemeManager.GATE_OR_GREEN)
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
	
	# Reset button - apply digital frontier style with Midnight Architect orange
	var reset_btn = Button.new()
	reset_btn.text = "⟲ RESET"
	reset_btn.custom_minimum_size = Vector2(140, 45)
	ThemeManager.apply_button_style(reset_btn, ThemeManager.GATE_NOR_ORANGE)
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
	output_title.text = "OUTPUT"
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

func setup_gate_toolbox() -> void:
	"""Initialize the GateToolbox with drag-and-drop support."""
	# Create the GateToolbox instance
	gate_toolbox = GateToolbox.new()
	gate_toolbox.setup(game_manager)
	add_child(gate_toolbox)
	
	# Connect toolbox signals to gate placement handler
	gate_toolbox.gate_placement_requested.connect(_on_toolbox_gate_placed)
	gate_toolbox.set_process_input(true)
	gate_toolbox.mouse_filter = Control.MOUSE_FILTER_PASS

func _on_toolbox_gate_placed(gate_type: String, world_pos: Vector2) -> void:
	"""Handle gate placement from toolbox drag-and-drop."""
	if gate_type not in current_allowed_gates:
		return
	
	if not game_manager or not game_manager.circuit_board:
		return
	
	# Place gate directly at the world position where mouse was
	var circuit_board = game_manager.circuit_board
	var new_gate = circuit_board.place_gate(gate_type, Vector2i.ZERO, world_pos)

func _on_gate_button_pressed(gate_type: String) -> void:
	"""Handle gate button press."""
	if gate_type not in current_allowed_gates:
		return
	
	selected_gate = gate_type
	gate_selected.emit(gate_type)

func _on_gate_button_down(btn: TextureButton, gate_type: String) -> void:
	"""Handle gate button press down (start drag detection)."""
	if gate_toolbox:
		gate_toolbox._on_gate_button_down(btn, gate_type)

func _on_gate_button_up(_gate_type: String) -> void:
	"""Handle gate button release (end drag or click)."""
	# Check if it was a drag or just a click
	if gate_toolbox:
		# Instead of sending an abstract InputEvent, call a cleanup method directly
		gate_toolbox._cleanup_drag()

func _on_run_pressed() -> void:
	"""Handle run button."""
	run_simulation.emit()

func _on_reset_pressed() -> void:
	"""Handle reset button."""
	reset_level.emit()

func show_level_complete(level_name: String) -> void:
	"""Show completion message."""
	level_complete = true
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
