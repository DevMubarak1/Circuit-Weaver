# Represents a connection between two ports (gates or nodes)
extends Node2D
class_name Wire

var from_port: Node2D  # The output port we're connecting from
var to_port: Node2D   # The input port we're connecting to
var from_gate: Node   # Reference to source gate/input node
var to_gate: Node     # Reference to destination gate/output node
var is_flowing: bool = false
var current_signal: int = 0  # Current signal value being transmitted
var line: Line2D
var is_animating: bool = false
var animation_progress: float = 0.0

signal signal_transmitted(value: int)

func _ready() -> void:
	line = get_node_or_null("Line2D")
	if from_port and to_port:
		update_line()
	set_process(false)  # Start disabled, enable during simulation

func _process(delta: float) -> void:
	update_line()
	update_animation(delta)

func update_line() -> void:
	"""Update the visual line between ports."""
	if not line:
		line = get_node_or_null("Line2D")
	
	if line and from_port and to_port:
		line.clear_points()
		line.add_point(from_port.global_position)
		
		# Add a curve for visual appeal
		var mid_point = from_port.global_position.lerp(to_port.global_position, 0.5)
		mid_point.y -= 20
		
		line.add_point(mid_point)
		line.add_point(to_port.global_position)
		
		# Color based on signal value
		if is_flowing:
			line.default_color = Color.GREEN if current_signal == 1 else Color.RED
			line.width = 4.0
		elif is_animating:
			line.default_color = Color.CYAN
			line.width = 3.0
		else:
			line.default_color = Color(0.4, 0.8, 0.9, 0.7)
			line.width = 2.0

func connect_ports(source_port: Node2D, source_gate: Node, dest_port: Node2D, dest_gate: Node) -> void:
	"""Set up the connection between two ports."""
	from_port = source_port
	from_gate = source_gate
	to_port = dest_port
	to_gate = dest_gate
	
	# Store reference to port for tracking
	if from_port:
		from_port.set_meta("connected_wire", self)
	if to_port:
		to_port.set_meta("connected_wire", self)

func transmit_signal(value: int) -> void:
	"""Transmit a signal through this wire."""
	current_signal = value
	is_flowing = true
	is_animating = true
	animation_progress = 0.0
	set_process(true)
	
	signal_transmitted.emit(value)

func receive_at_destination() -> void:
	"""Called when signal reaches the destination."""
	if to_gate:
		if to_gate is LogicGate:
			to_gate.add_input(current_signal)
		elif to_gate is OutputNode:
			to_gate.receive_input(current_signal)

func update_animation(delta: float) -> void:
	"""Update signal flow animation."""
	if is_animating:
		animation_progress += delta * 3.0  # 3.0 = animation speed
		
		if animation_progress >= 1.0:
			is_animating = false
			is_flowing = false
			animation_progress = 1.0
			set_process(false)

func get_signal_value() -> int:
	"""Get the current signal value being transmitted."""
	return current_signal

func stop_flowing() -> void:
	"""Stop the signal flow animation."""
	is_animating = false
	is_flowing = false
	animation_progress = 0.0
	set_process(false)
