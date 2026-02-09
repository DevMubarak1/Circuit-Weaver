# Main circuit board manager
extends Node2D
class_name CircuitBoard

const GRID_SIZE: int = 40
const GATE_TEMPLATE_PATH = "res://scenes/gates/logic_gate.tscn"
const WIRE_SCENE_PATH = "res://scenes/wires/wire.tscn"

var gates: Dictionary = {}  # Dictionary of placed gates by ID
var wires: Array[Wire] = []
var input_nodes: Array[InputNode] = []
var output_nodes: Array[OutputNode] = []
var ui_manager: UIManager = null
var next_gate_column: int = 2  # Placement column offset
var total_gates_to_place: int = 0  # Track how many gates will be placed
var gates_placed: int = 0  # Track how many we've placed

var selected_port: Node2D = null
var selected_gate: Node = null
var wiring_mode: bool = false
var is_simulating: bool = false
var dragging_gate: LogicGate = null
var drag_offset: Vector2 = Vector2.ZERO

signal simulation_started
signal simulation_ended
signal level_complete

func _ready() -> void:
	set_process_input(true)
	queue_redraw()  # Trigger grid drawing
	
	# Create containers if they don't exist
	if not has_node("GatesContainer"):
		var gates_cont = Node2D.new()
		gates_cont.name = "GatesContainer"
		add_child(gates_cont)
	
	if not has_node("WiresContainer"):
		var wires_cont = Node2D.new()
		wires_cont.name = "WiresContainer"
		add_child(wires_cont)
	
	if not has_node("InputContainer"):
		var input_cont = Node2D.new()
		input_cont.name = "InputContainer"
		add_child(input_cont)
	
	if not has_node("OutputContainer"):
		var output_cont = Node2D.new()
		output_cont.name = "OutputContainer"
		add_child(output_cont)

func _draw() -> void:
	"""Draw grid background and wiring preview for circuit board."""
	# Draw grid background
	var grid_color = Color(0.3, 0.3, 0.3, 0.3)
	var grid_range = 800
	
	# Draw vertical lines
	for x in range(-grid_range, grid_range, GRID_SIZE):
		draw_line(Vector2(x, -grid_range), Vector2(x, grid_range), grid_color, 1.0)
	
	# Draw horizontal lines
	for y in range(-grid_range, grid_range, GRID_SIZE):
		draw_line(Vector2(-grid_range, y), Vector2(grid_range, y), grid_color, 1.0)
	
	# Draw wiring preview line if in wiring mode
	if wiring_mode and selected_port:
		var mouse_pos = get_global_mouse_position()
		var port_pos = selected_port.global_position
		
		# Draw line with curve
		draw_line(port_pos, mouse_pos, Color.CYAN, 2.0)

func _input(event: InputEvent) -> void:
	# Handle zoom with mouse wheel
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				var camera = get_viewport().get_camera_2d()
				if camera:
					camera.zoom *= 1.1
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				var camera = get_viewport().get_camera_2d()
				if camera:
					camera.zoom /= 1.1
					camera.zoom = camera.zoom.clamp(Vector2(0.5, 0.5), Vector2(3.0, 3.0))
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				if wiring_mode:
					cancel_wiring()
			elif event.button_index == MOUSE_BUTTON_LEFT:
				# Check what was clicked
				var mouse_pos = get_global_mouse_position()
				
			# PRIORITY 1: Check for port clicks (wiring) FIRST - smaller hit radius
			if _handle_port_click(mouse_pos):
				print("✅ Port click detected")
			# PRIORITY 2: Check for gate clicks (dragging)
			elif _handle_gate_click(mouse_pos):
				print("✅ Gate click detected")
			else:
				print("⚠️ Clicked at %s - no gate or port detected" % mouse_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Right-click to cancel wiring
			if wiring_mode:
				cancel_wiring()
				print("❌ Wiring cancelled")
	else:
		# Mouse button released (LEFT)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if dragging_gate:
				dragging_gate = null
				print("✓ Gate dropped")
		var output = gate.get_node_or_null("OutputPort")
		if output:
			var port_world_pos = gate.global_position + output.position
			var distance = mouse_pos.distance_to(port_world_pos)
			if distance < 100:  # Only print if reasonably close
				print("      Gate %s output port at world %s, distance: %.1f" % [gate.gate_type, port_world_pos, distance])
			if distance < click_distance:
				print("📌 Gate output port CLICKED (distance %.1f)" % distance)
				# Ensure gate_owner is set
				if not output.has_meta("gate_owner"):
					output.set_meta("gate_owner", gate)
					output.set_meta("port_type", "output")
				start_wiring_from_port(output)
				return true
	
	# Check gate input ports (for completing wires)
	for gate_id in gates:
		var gate = gates[gate_id]
		var input_ports = gate.get_node_or_null("InputPorts")
		if input_ports:
			for i in range(input_ports.get_child_count()):
				var port = input_ports.get_child(i)
				var port_world_pos = gate.global_position + port.position
				var distance = mouse_pos.distance_to(port_world_pos)
				if distance < click_distance:
					print("📌 Gate input port %d CLICKED (distance %.1f), wiring_mode=%s" % [i, distance, wiring_mode])
					# Ensure metadata is set
					if not port.has_meta("gate_owner"):
						port.set_meta("gate_owner", gate)
						port.set_meta("port_type", "input")
						port.set_meta("port_index", i)
					if wiring_mode and selected_port:
						complete_wiring(port)
						return true
					elif not wiring_mode:
						# Allow starting wire from input port too (if needed)
						start_wiring_from_port(port)
						return true
					return true
	
	# Check input/output node ports
	print("   🔍 Checking %d input nodes for port clicks" % input_nodes.size())
	for input_node in input_nodes:
		var port = input_node.get_node_or_null("OutputPort")
		if port:
			var port_world_pos = input_node.global_position + port.position
			var distance = mouse_pos.distance_to(port_world_pos)
			if distance < click_distance:
				print("📌 Input node output port CLICKED (distance %.1f)" % distance)
				if not port.has_meta("gate_owner"):
					port.set_meta("gate_owner", input_node)
					port.set_meta("port_type", "output")
				start_wiring_from_port(port)
				return true
	
	print("   🔍 Checking %d output nodes for port clicks" % output_nodes.size())
	for output_node in output_nodes:
		var port = output_node.get_node_or_null("InputPort")
		if port:
			var port_world_pos = output_node.global_position + port.position
			var distance = mouse_pos.distance_to(port_world_pos)
			if distance < click_distance:
				print("📌 Output node input port CLICKED (distance %.1f), wiring_mode=%s" % [distance, wiring_mode])
				if not port.has_meta("gate_owner"):
					port.set_meta("gate_owner", output_node)
					port.set_meta("port_type", "input")
				if wiring_mode and selected_port:
					complete_wiring(port)
					return true
				return true
	
	return false

func _handle_gate_click(mouse_pos: Vector2) -> bool:
	"""Check if a gate was clicked and start dragging."""
	var click_distance = 80.0  # Pixels - size of gate + margin
	
	# Debug: Show all placed gates
	if gates.is_empty():
		print("⚠️ No gates placed yet")
		return false
	
	if gates.size() > 0:
		print("🔍 Checking %d gates for click at %s" % [gates.size(), mouse_pos])
	
	for gate_id in gates:
		var gate = gates[gate_id]
		var distance = mouse_pos.distance_to(gate.global_position)
		print("  - %s at %s, distance: %.1f" % [gate.gate_type, gate.global_position, distance])
		if distance < click_distance:
			dragging_gate = gate
			drag_offset = mouse_pos - gate.global_position
			print("🎯 DRAGGING %s from position %s" % [gate.gate_type, gate.global_position])
			return true
	
	return false


func _process(_delta: float) -> void:
	# Handle gate dragging
	if dragging_gate and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		dragging_gate.global_position = get_global_mouse_position() - drag_offset
	
	# Draw wiring preview line if in wiring mode
	if wiring_mode and selected_port:
		queue_redraw()

func place_gate(gate_type: String, _grid_position: Vector2i) -> LogicGate:
	"""Place a gate in the center of the screen (overlappable, users can drag apart)."""
	print("📍 place_gate() called with type: %s" % gate_type)
	
	# Always place in the center - users can drag to move apart
	# Center of usable area (640px / 2 = 320px)
	var center_x: float = 300.0  # Slightly offset from exact center for visibility
	var center_y: float = 240.0  # Middle vertical position
	
	var grid_position = Vector2i(int(center_x / GRID_SIZE), int(center_y / GRID_SIZE))
	var gate = create_gate_instance(gate_type, grid_position)
	if gate:
		get_node("GatesContainer").add_child(gate)
		gate.global_position = Vector2(center_x, center_y)
		gate.gate_type = gate_type
		gates[gate.get_gate_id()] = gate
		print("✅ Added gate to gates dict, total gates: %d" % gates.size())
		# Set gate as draggable
		gate.add_to_group("draggable_gate")
		gates_placed += 1
		print("🔧 Gate placed: %s at world(%.0f, %.0f) ID:%s" % [gate_type, gate.global_position.x, gate.global_position.y, gate.get_gate_id()])
		return gate
	else:
		print("❌ Failed to create gate instance for: %s" % gate_type)
	return null

func create_gate_instance(gate_type: String, grid_pos: Vector2i) -> LogicGate:
	"""Create a new gate instance from scene or fallback to code creation."""
	print("   Creating gate instance for: %s from %s" % [gate_type, GATE_TEMPLATE_PATH])
	
	# Try to load the scene
	var gate_scene = load(GATE_TEMPLATE_PATH)
	if gate_scene == null:
		print("   ⚠️ Scene load failed, using code fallback")
		return _create_gate_from_code(gate_type, grid_pos)
	
	print("   ✓ Scene loaded successfully")
	var gate = gate_scene.instantiate()
	if gate == null:
		print("   ❌ instantiate() returned null, using code fallback")
		return _create_gate_from_code(gate_type, grid_pos)
	
	print("   ✓ Gate instantiated")
	gate.gate_type = gate_type
	gate.position_in_grid = grid_pos
	gate.get_node("Label").text = gate_type.substr(0, 3).to_upper()
	gate.modulate = get_gate_color(gate_type)
	
	# Setup ports
	var output = gate.get_node("OutputPort")
	output.add_to_group("output_port")
	
	var main_area = gate.get_node("Area2D")
	main_area.add_to_group("gate_body")
	main_area.set_meta("gate_ref", gate)
	
	var input_ports = gate.get_node("InputPorts")
	for i in range(input_ports.get_child_count()):
		var port = input_ports.get_child(i)
		port.add_to_group("input_port")
		port.set_meta("gate_owner", gate)
		port.set_meta("port_type", "input")
		port.set_meta("port_index", i)
	
	output.set_meta("gate_owner", gate)
	output.set_meta("port_type", "output")
	
	print("   ✓ Gate fully configured and ready")
	return gate

func _create_gate_from_code(gate_type: String, grid_pos: Vector2i) -> LogicGate:
	"""Fallback: Create gate structure entirely in code."""
	print("   🔨 Building gate structure in code...")
	
	var gate = LogicGate.new()
	gate.name = "LogicGate_%s" % gate_type
	gate.gate_type = gate_type
	gate.position_in_grid = grid_pos
	
	# Background with type-specific color
	var background = ColorRect.new()
	background.name = "Background"
	background.size = Vector2(70, 70)
	background.position = Vector2(-35, -35)
	var gate_color = get_gate_color(gate_type)
	background.color = Color(gate_color.r * 0.6, gate_color.g * 0.6, gate_color.b * 0.6, 0.9)
	background.z_index = 0
	gate.add_child(background)
	
	# Label
	var label = Label.new()
	label.name = "Label"
	label.text = gate_type.substr(0, 3).to_upper()
	label.size = Vector2(40, 24)
	label.position = Vector2(-20, -12)
	label.add_theme_font_size_override("font_size", 14)
	label.horizontal_alignment = 1  # CENTER
	label.vertical_alignment = 1  # CENTER
	gate.add_child(label)
	
	# Main Area2D for dragging
	var main_area = Area2D.new()
	main_area.name = "Area2D"
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(60, 60)
	collision_shape.shape = rect_shape
	main_area.add_child(collision_shape)
	main_area.add_to_group("gate_body")
	main_area.set_meta("gate_ref", gate)
	gate.add_child(main_area)
	
	# Input ports container
	var input_ports = Node2D.new()
	input_ports.name = "InputPorts"
	
	var input_port1 = Area2D.new()
	input_port1.name = "InputPort1"
	input_port1.position = Vector2(-30, -18)
	
	# Visual indicator for input port
	var port1_visual = ColorRect.new()
	port1_visual.size = Vector2(12, 12)
	port1_visual.position = Vector2(-6, -6)
	port1_visual.color = Color(0.2, 0.8, 1.0, 1)  # Cyan
	port1_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input_port1.add_child(port1_visual)
	
	var port1_collision = CollisionShape2D.new()
	port1_collision.shape = RectangleShape2D.new()
	port1_collision.shape.size = Vector2(24, 24)
	input_port1.add_child(port1_collision)
	input_port1.add_to_group("input_port")
	input_port1.set_meta("gate_owner", gate)
	input_port1.set_meta("port_type", "input")
	input_port1.set_meta("port_index", 0)
	input_ports.add_child(input_port1)
	
	var input_port2 = Area2D.new()
	input_port2.name = "InputPort2"
	input_port2.position = Vector2(-30, 18)
	
	# Visual indicator for input port
	var port2_visual = ColorRect.new()
	port2_visual.size = Vector2(12, 12)
	port2_visual.position = Vector2(-6, -6)
	port2_visual.color = Color(0.2, 0.8, 1.0, 1)  # Cyan
	port2_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input_port2.add_child(port2_visual)
	
	var port2_collision = CollisionShape2D.new()
	port2_collision.shape = RectangleShape2D.new()
	port2_collision.shape.size = Vector2(24, 24)
	input_port2.add_child(port2_collision)
	input_port2.add_to_group("input_port")
	input_port2.set_meta("gate_owner", gate)
	input_port2.set_meta("port_type", "input")
	input_port2.set_meta("port_index", 1)
	input_ports.add_child(input_port2)
	
	gate.add_child(input_ports)
	
	# Output port
	var output_port = Area2D.new()
	output_port.name = "OutputPort"
	output_port.position = Vector2(30, 0)
	
	# Visual indicator for output port
	var output_visual = ColorRect.new()
	output_visual.size = Vector2(12, 12)
	output_visual.position = Vector2(-6, -6)
	output_visual.color = Color(1.0, 0.8, 0.2, 1)  # Yellow
	output_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	output_port.add_child(output_visual)
	
	var output_collision = CollisionShape2D.new()
	output_collision.shape = RectangleShape2D.new()
	output_collision.shape.size = Vector2(24, 24)
	output_port.add_child(output_collision)
	output_port.add_to_group("output_port")
	output_port.set_meta("gate_owner", gate)
	output_port.set_meta("port_type", "output")
	gate.add_child(output_port)
	
	gate.modulate = get_gate_color(gate_type)
	print("   ✓ Gate created from code successfully")
	return gate


func add_input_node(input_name: String, signal_sequence: PackedInt32Array, grid_position: Vector2i) -> InputNode:
	"""Add an input node to the circuit."""
	var input_node = InputNode.new()
	input_node.name = "InputNode_%s" % input_name
	input_node.input_name = input_name
	input_node.signal_sequence = signal_sequence
	input_node.position_in_grid = grid_position
	
	# Add visual components
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.modulate = Color(0.2, 0.8, 1.0, 1)  # Bright cyan
	input_node.add_child(sprite)
	
	var label = Label.new()
	label.name = "Label"
	label.text = input_name
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.position = Vector2(-8, 25)
	input_node.add_child(label)
	
	var output_area = Area2D.new()
	output_area.name = "OutputPort"
	output_area.add_to_group("output_port")
	output_area.position = Vector2(25, 0)
	
	# Visual indicator for input node's output port
	var node_port_visual = ColorRect.new()
	node_port_visual.size = Vector2(14, 14)
	node_port_visual.position = Vector2(-7, -7)
	node_port_visual.color = Color(0.2, 0.8, 1.0, 1)  # Cyan
	node_port_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	output_area.add_child(node_port_visual)
	
	var port_shape = RectangleShape2D.new()
	port_shape.size = Vector2(20, 20)
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = port_shape
	output_area.add_child(collision_shape)
	
	output_area.set_meta("gate_owner", input_node)
	output_area.set_meta("port_type", "output")
	
	input_node.add_child(output_area)
	get_node("InputContainer").add_child(input_node)
	input_node.global_position = grid_to_world(grid_position)
	input_nodes.append(input_node)
	input_node.output_changed.connect(_on_input_changed)
	print("✓ Input node created: %s at world(%d,%d)" % [input_name, int(input_node.global_position.x), int(input_node.global_position.y)])
	
	return input_node

func add_output_node(output_name: String, target_sequence: PackedInt32Array, grid_position: Vector2i) -> OutputNode:
	"""Add an output node to the circuit."""
	var output_node = OutputNode.new()
	output_node.name = "OutputNode_%s" % output_name
	output_node.output_name = output_name
	output_node.target_sequence = target_sequence
	output_node.position_in_grid = grid_position
	
	print("📍 Creating output node: %s at grid(%d,%d)" % [output_name, grid_position.x, grid_position.y])
	
	# Add visual components
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.modulate = Color(1.0, 0.8, 0.2, 1)  # Bright yellow
	output_node.add_child(sprite)
	
	var label = Label.new()
	label.name = "Label"
	label.text = output_name
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.position = Vector2(-50, 25)  # Position below the node, centered
	label.horizontal_alignment = 1  # CENTER
	output_node.add_child(label)
	
	# Visual indicator removed - not needed
	# var indicator = ColorRect.new()
	# indicator.name = "Indicator"
	# indicator.color = Color.RED
	# indicator.size = Vector2(40, 40)
	# indicator.position = Vector2(-20, -20)
	# indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# output_node.add_child(indicator)
	
	var input_area = Area2D.new()
	input_area.name = "InputPort"
	input_area.add_to_group("input_port")
	input_area.position = Vector2(-25, 0)
	
	# Visual indicator for output node's input port
	var output_port_visual = ColorRect.new()
	output_port_visual.size = Vector2(14, 14)
	output_port_visual.position = Vector2(-7, -7)
	output_port_visual.color = Color(0.2, 0.8, 1.0, 1)  # Cyan (input indicator)
	output_port_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input_area.add_child(output_port_visual)
	
	var input_port_shape = RectangleShape2D.new()
	input_port_shape.size = Vector2(20, 20)
	var input_collision_shape = CollisionShape2D.new()
	input_collision_shape.shape = input_port_shape
	input_area.add_child(input_collision_shape)
	
	input_area.set_meta("gate_owner", output_node)
	input_area.set_meta("port_type", "input")
	
	output_node.add_child(input_area)
	
	get_node("OutputContainer").add_child(output_node)
	output_node.global_position = grid_to_world(grid_position)
	output_nodes.append(output_node)
	
	output_node.level_complete.connect(_on_level_complete)
	output_node.value_received.connect(_on_output_value_received)
	
	print("✓ Output node created: %s at world(%d,%d)" % [output_name, int(output_node.global_position.x), int(output_node.global_position.y)])
	
	return output_node

func start_wiring_from_port(port: Node2D) -> void:
	"""Start wiring from a source port."""
	selected_port = port
	selected_gate = port.get_meta("gate_owner") if port.has_meta("gate_owner") else null
	wiring_mode = true
	
	# Visual feedback - highlight the port
	if port is ColorRect or port is Control:
		port.modulate = Color.GREEN
	
	print("🔌 WIRING MODE ACTIVE from %s" % [selected_gate.name if selected_gate else "unknown owner"])
	print("   Click an input port to complete the connection (RIGHT-CLICK to cancel)")
	if ui_manager:
		ui_manager.update_wiring_status(true)
	queue_redraw()  # Redraw to show preview line

func complete_wiring(target_port: Node2D) -> bool:
	"""Complete a wire connection between two ports."""
	if not wiring_mode or not selected_port or not target_port:
		cancel_wiring()
		return false
	
	# Prevent same port connection
	if selected_port == target_port:
		print("❌ Cannot connect port to itself")
		return false
	
	# Get the owners
	var source_gate = selected_port.get_meta("gate_owner") if selected_port.has_meta("gate_owner") else null
	var target_gate = target_port.get_meta("gate_owner") if target_port.has_meta("gate_owner") else null
	
	# Prevent feedback loops (output to output)
	var source_is_output = selected_port.get_meta("port_type") == "output" if selected_port.has_meta("port_type") else false
	var target_is_input = target_port.get_meta("port_type") == "input" if target_port.has_meta("port_type") else false
	
	if not source_is_output or not target_is_input:
		print("❌ Invalid connection: can only connect output → input")
		return false
	
	# Create wire
	var wire = Wire.new()
	wire.name = "Wire_%d" % wires.size()
	get_node("WiresContainer").add_child(wire)
	
	# Connect ports
	wire.connect_ports(selected_port, source_gate, target_port, target_gate)
	wires.append(wire)
	
	# Register wire with gates
	if source_gate and source_gate is LogicGate:
		source_gate.add_output_wire(wire)
	elif source_gate and source_gate is InputNode:
		source_gate.add_connected_wire(wire)
	
	print("✓ Wire connected: %s → %s" % [source_gate.name if source_gate else "Unknown", target_gate.name if target_gate else "Unknown"])
	cancel_wiring()
	return true

func cancel_wiring() -> void:
	"""Cancel the current wiring operation."""
	if selected_port:
		selected_port.modulate = Color.WHITE
	selected_port = null
	selected_gate = null
	wiring_mode = false
	queue_redraw()
	if ui_manager:
		ui_manager.update_wiring_status(false)

func start_simulation() -> void:
	"""Begin circuit simulation with signal propagation."""
	print("\n▶️ === SIMULATION STARTED ===")
	if is_simulating:
		return
	
	is_simulating = true
	simulation_started.emit()
	
	# Clear previous outputs
	reset_all_gates()
	
	# Start propagating signals from input nodes
	var has_inputs = false
	for input_node in input_nodes:
		var current_value = input_node.get_current_value()
		print("📍 Input %s = %d" % [input_node.input_name, current_value])
		has_inputs = true
		propagate_signal_from_input(input_node, current_value)
	
	if not has_inputs:
		print("⚠️ No input nodes configured")
	
	print("▶️ === END PROPAGATION CYCLE ===\n")

func propagate_signal_from_input(input_node: InputNode, value: int) -> void:
	"""Propagate an input signal through all its wires."""
	for wire in input_node.connected_wires:
		wire.transmit_signal(value)
		await get_tree().process_frame  # Wait one frame for animation
		wire.receive_at_destination()

func reset_all_gates() -> void:
	"""Reset all gates and output nodes for new simulation."""
	for gate in gates.values():
		gate.clear_inputs()
	
	for output in output_nodes:
		output.reset()

func end_simulation() -> void:
	"""End the simulation."""
	is_simulating = false
	simulation_ended.emit()
	print("⏹️ Simulation ended")

func _on_level_complete() -> void:
	"""Called when an output node detects the circuit is correct."""
	level_complete.emit()
	end_simulation()

func _on_input_changed(_value: int) -> void:
	"""Called when an input node's value changes."""
	# Propagate through wires
	pass

func _on_output_value_received(_value: int) -> void:
	"""Called when output node receives a value."""
	pass

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	"""Convert grid coordinates to world coordinates."""
	return Vector2(grid_pos) * GRID_SIZE

func world_to_grid(world_pos: Vector2) -> Vector2i:
	"""Convert world coordinates to grid coordinates."""
	return (world_pos / GRID_SIZE).round()

func get_gate_color(gate_type: String) -> Color:
	"""Return a unique color for each gate type."""
	match gate_type:
		"AND":
			return Color(1.0, 0.3, 0.3, 1)  # Red
		"OR":
			return Color(0.3, 1.0, 0.3, 1)  # Green
		"NOT":
			return Color(0.3, 0.6, 1.0, 1)  # Blue
		"XOR":
			return Color(1.0, 0.8, 0.2, 1)  # Yellow
		"NAND":
			return Color(1.0, 0.5, 0.1, 1)  # Orange
		"NOR":
			return Color(0.8, 0.2, 0.8, 1)  # Purple
		"XNOR":
			return Color(0.2, 0.8, 0.8, 1)  # Cyan
		_:
			return Color(0.7, 0.7, 0.7, 1)  # Gray

func clear_circuit() -> void:
	"""Clear all gates and wires from the circuit."""
	for wire in wires:
		wire.queue_free()
	wires.clear()
	
	for gate_id in gates:
		gates[gate_id].queue_free()
	gates.clear()
	
	gates_placed = 0
	total_gates_to_place = 0
