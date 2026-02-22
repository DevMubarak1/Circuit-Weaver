# Main circuit board manager
extends Node2D
class_name CircuitBoard

const GRID_SIZE: int = 40
const BOARD_WIDTH: int = 10
const BOARD_HEIGHT: int = 8

const GATE_TEMPLATE_PATH: String = "res://scenes/gates/Logic_Gate.tscn"

var gates: Dictionary = {}
var wires: Array[Wire] = []
var input_nodes: Array[InputNode] = []
var output_nodes: Array[OutputNode] = []
var total_gates_to_place: int = 0
var gates_placed: int = 0

var selected_port: Node2D = null
var selected_gate: Node = null
var wiring_mode: bool = false
var is_simulating: bool = false
var dragging_gate: LogicGate = null
var drag_offset: Vector2 = Vector2.ZERO
var _touch_active: bool = false
var current_selected_gate: LogicGate = null
var _current_selected_wire: Wire = null
var context_menu: PopupMenu = null

# --- TOUCH / PINCH-TO-ZOOM ---
var _touch_points: Dictionary = {}  # finger_index -> position
var _pinch_start_distance: float = 0.0
var _pinch_start_zoom: Vector2 = Vector2.ONE
var _pan_start_cam_pos: Vector2 = Vector2.ZERO
var _pan_start_touch_center: Vector2 = Vector2.ZERO
var _long_press_timer: Timer = null
var _long_press_position: Vector2 = Vector2.ZERO
const LONG_PRESS_DURATION: float = 0.5
const LONG_PRESS_MOVE_THRESHOLD: float = 15.0

signal simulation_started
signal simulation_ended
signal level_complete
signal gate_placed(gate_type: String, gate: LogicGate)
signal wire_connected(wire: Wire)

func _ready() -> void:
	set_process_input(true)
	queue_redraw()
	setup_default_board()

# --- GRID & NODE PLACEMENT ---

func place_input_node(input_name: String, column: int, row: int) -> InputNode:
	var input_node = InputNode.new()
	input_node.name = "InputNode_%s" % input_name
	input_node.input_name = input_name
	input_node.position_in_grid = Vector2i(column, row)
	
	var body = ColorRect.new()
	body.name = "Body"
	body.size = Vector2(80, 50)
	body.position = Vector2(-40, -25)
	body.color = Color(0.06, 0.08, 0.12, 0.95)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input_node.add_child(body)
	
	# Cyan border
	var border = ColorRect.new()
	border.name = "Border"
	border.size = Vector2(80, 50)
	border.position = Vector2(-40, -25)
	border.color = ThemeManager.SIGNAL_ACTIVE
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input_node.add_child(border)
	var inner = ColorRect.new()
	inner.size = Vector2(76, 46)
	inner.position = Vector2(-38, -23)
	inner.color = Color(0.06, 0.08, 0.12, 0.95)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input_node.add_child(inner)
	
	# Label
	var label = Label.new()
	label.name = "Label"
	label.text = "Input " + input_name
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", ThemeManager.SIGNAL_ACTIVE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-35, -12)
	label.custom_minimum_size = Vector2(70, 0)
	input_node.add_child(label)
	
	var output_area = Area2D.new()
	output_area.name = "OutputPort"
	output_area.add_to_group("output_port")
	output_area.position = Vector2(50, 0)
	
	var port_dot = ColorRect.new()
	port_dot.size = Vector2(14, 14)
	port_dot.position = Vector2(-7, -7)
	port_dot.color = ThemeManager.SIGNAL_ACTIVE
	port_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	output_area.add_child(port_dot)
	
	var port_shape = RectangleShape2D.new()
	port_shape.size = Vector2(28, 28)
	var collision = CollisionShape2D.new()
	collision.shape = port_shape
	output_area.add_child(collision)
	
	output_area.set_meta("gate_owner", input_node)
	output_area.set_meta("port_type", "output")
	input_node.add_child(output_area)
	
	add_child(input_node)
	input_node.position = Vector2(column * GRID_SIZE, row * GRID_SIZE)
	input_nodes.append(input_node)
	input_node.output_changed.connect(_on_input_changed)
	return input_node

func place_output_node(output_name: String, column: int, row: int) -> OutputNode:
	var output_node = OutputNode.new()
	output_node.name = "OutputNode_%s" % output_name
	output_node.output_name = output_name
	output_node.position_in_grid = Vector2i(column, row)
	
	var body = ColorRect.new()
	body.name = "Body"
	body.size = Vector2(100, 50)
	body.position = Vector2(-50, -25)
	body.color = Color(0.06, 0.08, 0.12, 0.95)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	output_node.add_child(body)
	
	# Pink border
	var border = ColorRect.new()
	border.name = "Border"
	border.size = Vector2(100, 50)
	border.position = Vector2(-50, -25)
	border.color = ThemeManager.ACCENT_WARNING
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	output_node.add_child(border)
	var inner = ColorRect.new()
	inner.size = Vector2(96, 46)
	inner.position = Vector2(-48, -23)
	inner.color = Color(0.06, 0.08, 0.12, 0.95)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	output_node.add_child(inner)
	
	var label = Label.new()
	label.name = "Label"
	label.text = output_name
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", ThemeManager.ACCENT_WARNING)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-30, -12)
	label.custom_minimum_size = Vector2(60, 0)
	output_node.add_child(label)
	
	var input_area = Area2D.new()
	input_area.name = "InputPort"
	input_area.add_to_group("input_port")
	input_area.position = Vector2(-60, 0)
	
	var port_dot = ColorRect.new()
	port_dot.size = Vector2(14, 14)
	port_dot.position = Vector2(-7, -7)
	port_dot.color = ThemeManager.ACCENT_WARNING
	port_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input_area.add_child(port_dot)
	
	var port_shape = RectangleShape2D.new()
	port_shape.size = Vector2(28, 28)
	var collision = CollisionShape2D.new()
	collision.shape = port_shape
	input_area.add_child(collision)
	
	input_area.set_meta("gate_owner", output_node)
	input_area.set_meta("port_type", "input")
	output_node.add_child(input_area)
	
	add_child(output_node)
	output_node.position = Vector2(column * GRID_SIZE, row * GRID_SIZE)
	output_nodes.append(output_node)
	output_node.level_complete.connect(_on_level_complete)
	output_node.value_received.connect(_on_output_value_received)
	return output_node

func setup_default_board():
	# This is called in _ready() but can be overridden by level setup
	# For Level 1, circuit_board setup is handled by level_manager
	pass

func _draw() -> void:
	var grid_color = Color(ThemeManager.MIDNIGHT_GRID.r, ThemeManager.MIDNIGHT_GRID.g, ThemeManager.MIDNIGHT_GRID.b, 0.4)
	var grid_range = 2000
	
	for x in range(-grid_range, grid_range, GRID_SIZE):
		draw_line(Vector2(x, -grid_range), Vector2(x, grid_range), grid_color, 1.0)
	
	for y in range(-grid_range, grid_range, GRID_SIZE):
		draw_line(Vector2(-grid_range, y), Vector2(grid_range, y), grid_color, 1.0)
	
	# Wiring preview line
	if wiring_mode and selected_port:
		var mouse_pos = get_local_mouse_position()
		var port_pos = to_local(selected_port.global_position)
		
		var mid_x: float = (port_pos.x + mouse_pos.x) * 0.5
		draw_line(port_pos, Vector2(mid_x, port_pos.y), ThemeManager.SIGNAL_ACTIVE, 2.0)
		draw_line(Vector2(mid_x, port_pos.y), Vector2(mid_x, mouse_pos.y), ThemeManager.SIGNAL_ACTIVE, 2.0)
		draw_line(Vector2(mid_x, mouse_pos.y), mouse_pos, ThemeManager.SIGNAL_ACTIVE, 2.0)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if wiring_mode:
			cancel_wiring()
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_DELETE:
		if current_selected_gate:
			delete_gate(current_selected_gate)
			current_selected_gate = null
		return

	# --- PINCH-TO-ZOOM & TWO-FINGER PAN ---
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_points[event.index] = event.position
			if _touch_points.size() == 1 and event.index == 0:
				# Start long-press timer for context menu
				_long_press_position = event.position
				_start_long_press_timer()
			if _touch_points.size() == 2:
				_cancel_long_press_timer()
				var points = _touch_points.values()
				_pinch_start_distance = points[0].distance_to(points[1])
				var cam = get_parent().get_node_or_null("Camera2D") as Camera2D
				if cam:
					_pinch_start_zoom = cam.zoom
					_pan_start_cam_pos = cam.position
					_pan_start_touch_center = (points[0] + points[1]) / 2.0
		else:
			_touch_points.erase(event.index)
			if event.index == 0:
				_cancel_long_press_timer()

	if event is InputEventScreenDrag:
		_touch_points[event.index] = event.position
		if _touch_points.size() == 2:
			# Cancel any single-finger actions during pinch
			_cancel_long_press_timer()
			if dragging_gate:
				dragging_gate = null
			var points = _touch_points.values()
			var current_distance = points[0].distance_to(points[1])
			var cam = get_parent().get_node_or_null("Camera2D") as Camera2D
			if cam and _pinch_start_distance > 10.0:
				# Zoom
				var zoom_factor = current_distance / _pinch_start_distance
				var new_zoom = _pinch_start_zoom * zoom_factor
				new_zoom = new_zoom.clamp(Vector2(0.3, 0.3), Vector2(2.5, 2.5))
				cam.zoom = new_zoom
				# Pan
				var current_center = (points[0] + points[1]) / 2.0
				var delta = (current_center - _pan_start_touch_center) / cam.zoom.x
				cam.position = _pan_start_cam_pos - delta
			return
		elif _touch_points.size() == 1 and event.index == 0:
			# Check if finger moved too far for long-press
			if _long_press_position.distance_to(event.position) > LONG_PRESS_MOVE_THRESHOLD:
				_cancel_long_press_timer()

	# --- MOUSE SCROLL ZOOM (desktop + trackpad) ---
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var cam = get_parent().get_node_or_null("Camera2D") as Camera2D
			if cam:
				var zoom_step: float = 0.1
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					cam.zoom += Vector2(zoom_step, zoom_step)
				else:
					cam.zoom -= Vector2(zoom_step, zoom_step)
				cam.zoom = cam.zoom.clamp(Vector2(0.3, 0.3), Vector2(2.5, 2.5))
			return

	var pressed: bool = false
	var released: bool = false
	var is_right: bool = false

	# Block board interactions during tutorial
	var level_mgr = get_tree().get_first_node_in_group("level_manager") as LevelManager
	if level_mgr and level_mgr._input_blocked and not level_mgr._tutorial_complete:
		return

	if event is InputEventMouseButton:
		if event.pressed:
			pressed = true
			is_right = event.button_index == MOUSE_BUTTON_RIGHT
		else:
			released = true
	elif event is InputEventScreenTouch:
		if event.pressed:
			pressed = true
			_touch_active = true
		else:
			released = true
			_touch_active = false

	if pressed:
		var mouse_pos = get_local_mouse_position()
		if is_right:
			_handle_right_click(mouse_pos)
		else:
			if _handle_port_click(mouse_pos):
				pass
			elif _handle_gate_click(mouse_pos):
				pass
	elif released:
		if dragging_gate:
			dragging_gate = null

func _handle_port_click(mouse_pos: Vector2) -> bool:
	var resp = get_node_or_null("/root/ResponsiveManager")
	var click_distance: float = resp.port_hit_radius if resp else 35.0
	
	# Check Input Nodes (their OutputPort is the starting point for wires)
	for input_node in input_nodes:
		var output = input_node.get_node_or_null("OutputPort")
		if output:
			var port_pos = to_local(output.global_position)
			if mouse_pos.distance_to(port_pos) < click_distance:
				if wiring_mode:
					pass
				else:
					start_wiring_from_port(output)
				return true
	
	# Check Output Nodes (their InputPort is a wiring endpoint)
	for output_node in output_nodes:
		var input_port = output_node.get_node_or_null("InputPort")
		if input_port:
			var port_pos = to_local(input_port.global_position)
			if mouse_pos.distance_to(port_pos) < click_distance:
				if wiring_mode:
					complete_wiring(input_port)
				return true
	
	# Check Gates
	for gate in gates.values():
		# Check Output port
		var output = gate.get_node_or_null("OutputPort")
		if output:
			var port_local_pos = to_local(output.global_position)
			if mouse_pos.distance_to(port_local_pos) < click_distance:
				if wiring_mode:
					pass
				else:
					start_wiring_from_port(output)
				return true
		# Check Input ports
		var input_ports_node = gate.get_node_or_null("InputPorts")
		if input_ports_node:
			for port in input_ports_node.get_children():
				var port_local_pos = to_local(port.global_position)
				if mouse_pos.distance_to(port_local_pos) < click_distance:
					if wiring_mode:
						complete_wiring(port)
					return true
	return false

func _handle_gate_click(mouse_pos: Vector2) -> bool:
	var resp = get_node_or_null("/root/ResponsiveManager")
	var click_radius: float = 110.0
	if resp and resp.is_mobile():
		click_radius = 130.0
	for gate in gates.values():
		var gate_local_pos = to_local(gate.global_position)
		if mouse_pos.distance_to(gate_local_pos) < click_radius:
			dragging_gate = gate
			current_selected_gate = gate
			drag_offset = mouse_pos - gate_local_pos
			return true
	return false


func _process(_delta: float) -> void:
	# Handle gate dragging (mouse or touch)
	if dragging_gate and (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or _touch_active):
		dragging_gate.position = get_local_mouse_position() - drag_offset
	
	# Redraw for wiring preview only when actively wiring
	if wiring_mode and selected_port:
		queue_redraw()
	elif not dragging_gate:
		# Nothing active — no need to process every frame
		return

func place_gate(gate_type: String, _grid_position: Vector2i, world_position: Vector2 = Vector2.ZERO) -> LogicGate:
	var placement_pos: Vector2
	if world_position != Vector2.ZERO:
		placement_pos = world_position
	else:
		var center_x: float = 300.0
		var center_y: float = 240.0
		placement_pos = Vector2(center_x, center_y)
	var grid_position = Vector2i(int(placement_pos.x / GRID_SIZE), int(placement_pos.y / GRID_SIZE))
	var gate = create_gate_instance(gate_type, grid_position)
	if gate:
		var container = get_node_or_null("GatesContainer")
		if container:
			container.add_child(gate)
		gate.position = placement_pos
		gate.gate_type = gate_type
		gates[gate.get_gate_id()] = gate
		gate.add_to_group("draggable_gate")
		gates_placed += 1
		var sfx = get_node_or_null("/root/SFXManager")
		if sfx:
			sfx.play_gate_snap()
		gate_placed.emit(gate_type, gate)
		return gate
	return null

func create_gate_instance(g_type: String, grid_pos: Vector2i) -> LogicGate:
	var gate_scene = load(GATE_TEMPLATE_PATH)
	if gate_scene == null:
		return _create_gate_from_code(g_type, grid_pos)
	var instance = gate_scene.instantiate()
	if instance == null:
		return _create_gate_from_code(g_type, grid_pos)
	if instance is LogicGate:
		instance.gate_type = g_type
		instance.position_in_grid = grid_pos
		instance.name = g_type + "_" + str(instance.get_instance_id())
		var gate_label = instance.get_node_or_null("Label")
		if gate_label:
			gate_label.text = g_type
			gate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			gate_label.add_theme_color_override("font_color", ThemeManager.SIGNAL_ACTIVE)
			gate_label.add_theme_font_size_override("font_size", 14)
			# Position set dynamically by _ensure_gate_ports based on actual texture size
		var sprite_node = instance.get_node_or_null("Sprite2D")
		if sprite_node:
			sprite_node.z_index = 1
		
		instance.load_gate_icon()
		instance.add_to_group("gate_body")
		
		# Create ports and auto-scale sprite based on actual texture size
		_ensure_gate_ports(instance, g_type)
		
		return instance
	else:
		return null

func _create_gate_from_code(g_type: String, grid_pos: Vector2i) -> LogicGate:
	
	var gate = LogicGate.new()
	gate.name = "LogicGate_%s" % g_type
	gate.gate_type = g_type
	gate.position_in_grid = grid_pos
	
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.position = Vector2(0, 0)
	sprite.centered = true
	sprite.z_index = 1
	gate.add_child(sprite)
	gate.sprite = sprite
	
	var label = Label.new()
	label.name = "Label"
	label.text = g_type
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", ThemeManager.SIGNAL_ACTIVE)
	label.add_theme_font_size_override("font_size", 14)
	gate.add_child(label)
	
	# Load the SVG icon
	gate.load_gate_icon()
	
	gate.add_to_group("gate_body")
	
	_ensure_gate_ports(gate, g_type)
	
	return gate


func _ensure_gate_ports(gate: LogicGate, g_type: String) -> void:
	"""Create input/output ports on a gate and auto-scale sprite to a consistent visual size.
	SVGs have viewBox '0 -25 100 100' (square) in a 288x288 texture. Wire tips at viewBox
	x=5,95 and y=25 map to texture center. With centered=true, wire tips at gate origin."""
	const DESIRED_WIRE_WIDTH = 220.0
	const TIP_X_FRACTION = 0.45   # wire tips at viewBox x=5,95 → ±45% from center
	const TIP_Y_FRACTION = 0.10   # 2-input wires at viewBox y=15,35 → ±10%
	const WIRE_SPAN_FRACTION = 0.90
	const VIEWBOX_ASPECT = 0.5    # viewBox 50/100
	
	var num_inputs = 2
	if g_type == "NOT":
		num_inputs = 1
	
	# Defaults
	var port_x: float = DESIRED_WIRE_WIDTH / 2.0
	var port_y_offset: float = DESIRED_WIRE_WIDTH * TIP_Y_FRACTION / WIRE_SPAN_FRACTION
	var content_cy: float = 0.0  # content center Y in gate-local space
	var half_h: float = DESIRED_WIRE_WIDTH * VIEWBOX_ASPECT / WIRE_SPAN_FRACTION / 2.0
	
	var sprite_node = gate.get_node_or_null("Sprite2D")
	if sprite_node and sprite_node.texture:
		var tex_w: float = float(sprite_node.texture.get_size().x)
		var sc: float = DESIRED_WIRE_WIDTH / (tex_w * WIRE_SPAN_FRACTION)
		sprite_node.scale = Vector2(sc, sc)
		sprite_node.offset = Vector2.ZERO
		sprite_node.position = Vector2.ZERO
		
		# SVG preserveAspectRatio="xMidYMid meet" (default) centers the viewBox
		# content in the 288×288 texture. Wire center (viewBox y=25) maps to
		# texture y=144 = texture center. With centered=true, that's gate y=0.
		content_cy = 0.0
		port_x = TIP_X_FRACTION * tex_w * sc
		port_y_offset = TIP_Y_FRACTION * tex_w * sc
		half_h = tex_w * VIEWBOX_ASPECT / 2.0 * sc
	
	# Collision shape centered on content
	var col_shape = gate.get_node_or_null("CollisionShape2D")
	if col_shape:
		col_shape.position = Vector2(0, content_cy)
		if not col_shape.shape:
			col_shape.shape = RectangleShape2D.new()
		col_shape.shape.size = Vector2(DESIRED_WIRE_WIDTH, half_h * 2.0)
	
	# Label just below content
	var gate_label = gate.get_node_or_null("Label")
	if gate_label:
		gate_label.position = Vector2(-20, content_cy + half_h + 4)
	
	# --- OutputPort at right wire tip, at content center Y ---
	if not gate.has_node("OutputPort"):
		var output_port = Area2D.new()
		output_port.name = "OutputPort"
		output_port.position = Vector2(port_x, content_cy)
		output_port.add_to_group("output_port")
		output_port.set_meta("gate_owner", gate)
		output_port.set_meta("port_type", "output")
		var port_dot = ColorRect.new()
		port_dot.size = Vector2(12, 12)
		port_dot.position = Vector2(-6, -6)
		port_dot.color = ThemeManager.SIGNAL_ACTIVE
		port_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		output_port.add_child(port_dot)
		var ps = RectangleShape2D.new()
		ps.size = Vector2(28, 28)
		var c2 = CollisionShape2D.new()
		c2.shape = ps
		output_port.add_child(c2)
		gate.add_child(output_port)
		gate.output_port = output_port
	else:
		var output = gate.get_node("OutputPort")
		output.position = Vector2(port_x, content_cy)
		output.add_to_group("output_port")
		output.set_meta("gate_owner", gate)
		output.set_meta("port_type", "output")
	
	# --- InputPorts at left wire tips, at content center Y ---
	if not gate.has_node("InputPorts"):
		var input_ports_container = Node2D.new()
		input_ports_container.name = "InputPorts"
		for i in range(num_inputs):
			var input_port = Area2D.new()
			input_port.name = "InputPort_%d" % i
			if num_inputs == 1:
				input_port.position = Vector2(-port_x, content_cy)
			else:
				var y_off = -port_y_offset + i * port_y_offset * 2.0
				input_port.position = Vector2(-port_x, content_cy + y_off)
			input_port.add_to_group("input_port")
			input_port.set_meta("gate_owner", gate)
			input_port.set_meta("port_type", "input")
			input_port.set_meta("port_index", i)
			var port_dot = ColorRect.new()
			port_dot.size = Vector2(12, 12)
			port_dot.position = Vector2(-6, -6)
			port_dot.color = ThemeManager.ACCENT_WARNING
			port_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			input_port.add_child(port_dot)
			var ps = RectangleShape2D.new()
			ps.size = Vector2(28, 28)
			var c2 = CollisionShape2D.new()
			c2.shape = ps
			input_port.add_child(c2)
			input_ports_container.add_child(input_port)
		gate.add_child(input_ports_container)
		gate.input_ports = input_ports_container
	else:
		var input_ports_node = gate.get_node("InputPorts")
		for i in range(input_ports_node.get_child_count()):
			var port = input_ports_node.get_child(i)
			if num_inputs == 1:
				port.position = Vector2(-port_x, content_cy)
			else:
				var y_off = -port_y_offset + i * port_y_offset * 2.0
				port.position = Vector2(-port_x, content_cy + y_off)
			port.add_to_group("input_port")
			port.set_meta("gate_owner", gate)
			port.set_meta("port_type", "input")
			port.set_meta("port_index", i)


func add_input_node(input_name: String, signal_sequence: PackedInt32Array, grid_position: Vector2i) -> InputNode:
	var input_node = InputNode.new()
	input_node.name = "InputNode_%s" % input_name
	input_node.input_name = input_name
	input_node.signal_sequence = signal_sequence
	input_node.position_in_grid = grid_position
	
	var body = ColorRect.new()
	body.name = "Body"
	body.size = Vector2(80, 50)
	body.position = Vector2(-40, -25)
	body.color = Color(0.06, 0.08, 0.12, 0.95)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input_node.add_child(body)
	
	# Border overlay
	var border = ColorRect.new()
	border.name = "Border"
	border.size = Vector2(80, 50)
	border.position = Vector2(-40, -25)
	border.color = ThemeManager.SIGNAL_ACTIVE
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input_node.add_child(border)
	var inner = ColorRect.new()
	inner.size = Vector2(76, 46)
	inner.position = Vector2(-38, -23)
	inner.color = Color(0.06, 0.08, 0.12, 0.95)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input_node.add_child(inner)
	
	# Label
	var label = Label.new()
	label.name = "Label"
	label.text = "Input " + input_name
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", ThemeManager.SIGNAL_ACTIVE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-35, -12)
	label.custom_minimum_size = Vector2(70, 0)
	input_node.add_child(label)
	
	var output_area = Area2D.new()
	output_area.name = "OutputPort"
	output_area.add_to_group("output_port")
	output_area.position = Vector2(50, 0)
	
	var port_circle = ColorRect.new()
	port_circle.size = Vector2(18, 18)
	port_circle.position = Vector2(-9, -9)
	port_circle.color = ThemeManager.SIGNAL_ACTIVE
	port_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	output_area.add_child(port_circle)
	
	var port_hint = Label.new()
	port_hint.text = "→"
	port_hint.add_theme_font_size_override("font_size", 18)
	port_hint.add_theme_color_override("font_color", ThemeManager.SIGNAL_ACTIVE)
	port_hint.position = Vector2(-6, -14)
	output_area.add_child(port_hint)
	
	var port_shape = RectangleShape2D.new()
	port_shape.size = Vector2(24, 24)
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = port_shape
	output_area.add_child(collision_shape)
	
	output_area.set_meta("gate_owner", input_node)
	output_area.set_meta("port_type", "output")
	
	input_node.add_child(output_area)
	var input_container = get_node_or_null("InputContainer")
	if input_container:
		input_container.add_child(input_node)
	else:
		add_child(input_node)
	input_node.position = grid_to_world(grid_position)
	input_nodes.append(input_node)
	input_node.output_changed.connect(_on_input_changed)
	
	return input_node

func add_output_node(output_name: String, target_sequence: PackedInt32Array, grid_position: Vector2i) -> OutputNode:
	var output_node = OutputNode.new()
	output_node.name = "OutputNode_%s" % output_name
	output_node.output_name = output_name
	output_node.target_sequence = target_sequence
	output_node.position_in_grid = grid_position
	
	
	var body = ColorRect.new()
	body.name = "Body"
	body.size = Vector2(100, 50)
	body.position = Vector2(-50, -25)
	body.color = Color(0.06, 0.08, 0.12, 0.95)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	output_node.add_child(body)
	
	# Border overlay (pink/warning color for output)
	var border = ColorRect.new()
	border.name = "Border"
	border.size = Vector2(100, 50)
	border.position = Vector2(-50, -25)
	border.color = ThemeManager.ACCENT_WARNING
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	output_node.add_child(border)
	var inner = ColorRect.new()
	inner.size = Vector2(96, 46)
	inner.position = Vector2(-48, -23)
	inner.color = Color(0.06, 0.08, 0.12, 0.95)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	output_node.add_child(inner)
	
	# Label
	var label = Label.new()
	label.name = "Label"
	label.text = "Output"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", ThemeManager.ACCENT_WARNING)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-30, -12)
	label.custom_minimum_size = Vector2(60, 0)
	output_node.add_child(label)
	
	var input_area = Area2D.new()
	input_area.name = "InputPort"
	input_area.add_to_group("input_port")
	input_area.position = Vector2(-60, 0)
	
	var port_circle = ColorRect.new()
	port_circle.size = Vector2(18, 18)
	port_circle.position = Vector2(-9, -9)
	port_circle.color = ThemeManager.ACCENT_WARNING
	port_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input_area.add_child(port_circle)
	
	var port_hint = Label.new()
	port_hint.text = "→"
	port_hint.add_theme_font_size_override("font_size", 18)
	port_hint.add_theme_color_override("font_color", ThemeManager.ACCENT_WARNING)
	port_hint.position = Vector2(-6, -14)
	input_area.add_child(port_hint)
	
	var input_port_shape = RectangleShape2D.new()
	input_port_shape.size = Vector2(24, 24)
	var input_collision_shape = CollisionShape2D.new()
	input_collision_shape.shape = input_port_shape
	input_area.add_child(input_collision_shape)
	
	input_area.set_meta("gate_owner", output_node)
	input_area.set_meta("port_type", "input")
	
	output_node.add_child(input_area)
	
	var output_container = get_node_or_null("OutputContainer")
	if output_container:
		output_container.add_child(output_node)
	else:
		add_child(output_node)
	output_node.position = grid_to_world(grid_position)
	output_nodes.append(output_node)
	
	output_node.level_complete.connect(_on_level_complete)
	output_node.value_received.connect(_on_output_value_received)
	
	
	return output_node

func start_wiring_from_port(port: Node2D) -> void:
	selected_port = port
	selected_gate = port.get_meta("gate_owner") if port.has_meta("gate_owner") else null
	wiring_mode = true
	
	port.modulate = Color.GREEN
	
	queue_redraw()

func complete_wiring(target_port: Node2D) -> bool:
	if not wiring_mode or not selected_port or not target_port:
		cancel_wiring()
		return false
	
	if selected_port == target_port:
		return false
	
	var source_gate = selected_port.get_meta("gate_owner") if selected_port.has_meta("gate_owner") else null
	var target_gate = target_port.get_meta("gate_owner") if target_port.has_meta("gate_owner") else null
	
	var source_is_output: bool = false
	if selected_port.has_meta("port_type"):
		source_is_output = selected_port.get_meta("port_type") == "output"
	
	var target_is_input: bool = false
	if target_port.has_meta("port_type"):
		target_is_input = target_port.get_meta("port_type") == "input"
	
	if not source_is_output or not target_is_input:
		return false
	
	var wire = Wire.new()
	wire.name = "Wire_%d" % wires.size()
	var wire_container = get_node_or_null("WiresContainer")
	if wire_container:
		wire_container.add_child(wire)
	else:
		add_child(wire)
	
	wire.connect_ports(selected_port, source_gate, target_port, target_gate)
	wires.append(wire)
	
	if source_gate and source_gate is LogicGate:
		source_gate.add_output_wire(wire)
	elif source_gate and source_gate is InputNode:
		source_gate.add_connected_wire(wire)
	
	var sfx = get_node_or_null("/root/SFXManager")
	if sfx:
		sfx.play_wire_click()
	wire_connected.emit(wire)
	cancel_wiring()
	return true

func cancel_wiring() -> void:
	if selected_port:
		selected_port.modulate = Color.WHITE
	selected_port = null
	selected_gate = null
	wiring_mode = false
	queue_redraw()

func start_simulation() -> void:
	if is_simulating:
		return

	is_simulating = true
	simulation_started.emit()

	reset_all_gates()

	var seq_length: int = 1
	for input_node in input_nodes:
		if input_node.signal_sequence.size() > seq_length:
			seq_length = input_node.signal_sequence.size()

	for step in range(seq_length):
		if step > 0:
			# Advance all inputs and reset gate intermediate state
			for input_node in input_nodes:
				input_node.advance_sequence()
			for gate in gates.values():
				gate.clear_inputs()
			# Small pause between steps for visual feedback
			await get_tree().create_timer(0.15).timeout


		for input_node in input_nodes:
			var current_value: int = input_node.get_current_value()
			await propagate_signal_from_input(input_node, current_value)

		# Wait for all gates to settle this step
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame

	# Simulation finished — reset flag so it can run again
	end_simulation()


func propagate_signal_from_input(input_node: InputNode, value: int) -> void:
	for wire in input_node.connected_wires:
		wire.transmit_signal(value)
		await get_tree().process_frame
		await get_tree().process_frame
		wire.receive_at_destination()
		
		await get_tree().process_frame
		await get_tree().process_frame

func reset_all_gates() -> void:
	for gate in gates.values():
		gate.clear_inputs()
	
	for output in output_nodes:
		output.reset()

func end_simulation() -> void:
	is_simulating = false
	simulation_ended.emit()

func _on_level_complete() -> void:
	level_complete.emit()

func _on_context_menu_selected(id: int) -> void:
	if id == 10:  # Delete Wire
		if _current_selected_wire and is_instance_valid(_current_selected_wire):
			_delete_wire(_current_selected_wire)
		_current_selected_wire = null
		return

	if not current_selected_gate:
		return
	
	match id:
		0:  # Delete Gate
			delete_gate(current_selected_gate)
		1:  # Duplicate Gate
			duplicate_gate(current_selected_gate)
		2:  # Move Gate
			dragging_gate = current_selected_gate
			drag_offset = get_local_mouse_position() - current_selected_gate.position

func delete_gate(gate: LogicGate) -> void:
	var gate_id = gate.get_gate_id()
	
	# Remove all wires connected to this gate
	var wires_to_remove = []
	for wire in wires:
		if wire.from_gate == gate or wire.to_gate == gate:
			wires_to_remove.append(wire)
	
	for wire in wires_to_remove:
		wire.queue_free()
		wires.erase(wire)
	
	# Remove gate from dict and scene
	gates.erase(gate_id)
	gates_placed = maxi(gates_placed - 1, 0)
	gate.queue_free()

func duplicate_gate(gate: LogicGate) -> void:
	var new_gate = create_gate_instance(gate.gate_type, gate.position_in_grid)
	if new_gate:
		var container = get_node_or_null("GatesContainer")
		if container:
			container.add_child(new_gate)
		else:
			add_child(new_gate)
		new_gate.global_position = gate.global_position + Vector2(80, 0)
		new_gate.gate_type = gate.gate_type
		gates[new_gate.get_gate_id()] = new_gate
		gates_placed += 1
	if is_simulating:
		end_simulation()

func _on_input_changed(_value: int) -> void:
	# Propagate through wires
	pass

func _on_output_value_received(_value: int, _output_node: OutputNode) -> void:
	pass

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos) * GRID_SIZE

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return (world_pos / GRID_SIZE).round()

func clear_circuit() -> void:
	for wire in wires:
		wire.queue_free()
	wires.clear()
	
	for gate_id in gates:
		gates[gate_id].queue_free()
	gates.clear()
	
	for input_n in input_nodes:
		if is_instance_valid(input_n):
			input_n.queue_free()
	input_nodes.clear()
	
	for output_n in output_nodes:
		if is_instance_valid(output_n):
			output_n.queue_free()
	output_nodes.clear()
	
	gates_placed = 0
	total_gates_to_place = 0
	is_simulating = false

func _handle_right_click(mouse_pos: Vector2) -> void:
	_show_gate_context_menu(mouse_pos)

func _show_gate_context_menu(mouse_pos: Vector2) -> void:
	var gate_clicked_flag = false
	var click_radius = 110.0
	var resp = get_node_or_null("/root/ResponsiveManager")
	if resp and resp.is_mobile():
		click_radius = 140.0
	for gate in gates.values():
		var gate_local_pos = to_local(gate.global_position)
		var distance = mouse_pos.distance_to(gate_local_pos)
		if distance < click_radius:
			current_selected_gate = gate
			_current_selected_wire = null
			_rebuild_context_menu(true, false)
			context_menu.popup(Rect2i(get_viewport().get_mouse_position(), Vector2i.ZERO))
			gate_clicked_flag = true
			break
	if not gate_clicked_flag:
		# Check for nearby wires
		var wire_hit_dist = 25.0
		if resp and resp.is_mobile():
			wire_hit_dist = 40.0
		var closest_wire: Wire = null
		var closest_dist: float = wire_hit_dist
		for wire in wires:
			if not wire or not is_instance_valid(wire):
				continue
			if not wire.from_port or not wire.to_port:
				continue
			var d = _point_to_wire_distance(mouse_pos, wire)
			if d < closest_dist:
				closest_dist = d
				closest_wire = wire
		if closest_wire:
			_current_selected_wire = closest_wire
			current_selected_gate = null
			_rebuild_context_menu(false, true)
			context_menu.popup(Rect2i(get_viewport().get_mouse_position(), Vector2i.ZERO))
		elif wiring_mode:
			cancel_wiring()

func _rebuild_context_menu(for_gate: bool, for_wire: bool) -> void:
	if context_menu and is_instance_valid(context_menu):
		context_menu.queue_free()
		context_menu = null
	context_menu = PopupMenu.new()
	add_child(context_menu)
	context_menu.connect("id_pressed", Callable(self, "_on_context_menu_selected"))
	if for_gate:
		context_menu.add_item("Delete Gate", 0)
		context_menu.add_item("Duplicate Gate", 1)
		context_menu.add_item("Move Gate", 2)
	if for_wire:
		context_menu.add_item("Delete Wire", 10)

func _point_to_wire_distance(point: Vector2, wire: Wire) -> float:
	# Calculate min distance from point to the wire's polyline segments
	var start_pos = to_local(wire.from_port.global_position)
	var end_pos = to_local(wire.to_port.global_position)
	var mid_x = (start_pos.x + end_pos.x) / 2.0
	var segments: Array[Vector2] = [
		start_pos,
		Vector2(mid_x, start_pos.y),
		Vector2(mid_x, end_pos.y),
		end_pos,
	]
	var min_dist = INF
	for i in range(segments.size() - 1):
		var d = _point_to_segment(point, segments[i], segments[i + 1])
		min_dist = minf(min_dist, d)
	return min_dist

func _point_to_segment(point: Vector2, seg_a: Vector2, seg_b: Vector2) -> float:
	var ab = seg_b - seg_a
	var ap = point - seg_a
	var len_sq = ab.length_squared()
	if len_sq < 0.001:
		return point.distance_to(seg_a)
	var t = clampf(ap.dot(ab) / len_sq, 0.0, 1.0)
	var closest = seg_a + ab * t
	return point.distance_to(closest)

func _delete_wire(wire: Wire) -> void:
	if wire.from_port and wire.from_port.has_meta("connected_wire"):
		if wire.from_port.get_meta("connected_wire") == wire:
			wire.from_port.remove_meta("connected_wire")
	if wire.to_port and wire.to_port.has_meta("connected_wire"):
		if wire.to_port.get_meta("connected_wire") == wire:
			wire.to_port.remove_meta("connected_wire")
	wires.erase(wire)
	wire.queue_free()
	if is_simulating:
		end_simulation()

# --- DRAG AND DROP ---

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is Dictionary:
		return data.has("type") and data["type"] == "gate" and data.has("gate_type")
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary and data.has("gate_type"):
		var gate_type: String = data["gate_type"]
		var local_pos = get_local_mouse_position()
		place_gate(gate_type, Vector2i.ZERO, local_pos)

# --- LONG-PRESS HELPERS (mobile context menu) ---

func _start_long_press_timer() -> void:
	_cancel_long_press_timer()
	_long_press_timer = Timer.new()
	_long_press_timer.one_shot = true
	_long_press_timer.wait_time = LONG_PRESS_DURATION
	_long_press_timer.timeout.connect(_on_long_press_timeout)
	add_child(_long_press_timer)
	_long_press_timer.start()

func _cancel_long_press_timer() -> void:
	if _long_press_timer and is_instance_valid(_long_press_timer):
		_long_press_timer.stop()
		_long_press_timer.queue_free()
		_long_press_timer = null

func _on_long_press_timeout() -> void:
	# Long press triggers context menu (same as right-click)
	var mouse_pos = get_local_mouse_position()
	_show_gate_context_menu(mouse_pos)
	# Cancel any dragging to prevent accidental moves
	if dragging_gate:
		dragging_gate = null
