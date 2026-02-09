# Base class for all logic gates
extends Node2D
class_name LogicGate

signal output_changed(value: int)
signal gate_activated

@export var gate_type: String = "AND"
@export var position_in_grid: Vector2i = Vector2i.ZERO

var input_slots: Dictionary = {}  # Maps input_index -> value
var output_value: int = 0
var is_hovering: bool = false
var sprite: Sprite2D
var input_ports: Node2D
var output_port: Area2D
var connected_output_wires: Array[Wire] = []
var background: ColorRect

func _ready() -> void:
	sprite = get_node_or_null("Sprite2D")
	input_ports = get_node_or_null("InputPorts")
	output_port = get_node_or_null("OutputPort")
	background = get_node_or_null("Background")
	set_process_input(true)
	
func add_input(value: int, port_index: int = 0) -> void:
	"""Add an input value to a specific input port."""
	input_slots[port_index] = value
	evaluate()

func clear_inputs() -> void:
	"""Clear all inputs for re-evaluation."""
	input_slots.clear()

func evaluate() -> void:
	"""Evaluate the gate based on current inputs and emit output if changed."""
	var new_output = compute_output()
	if new_output != output_value:
		output_value = new_output
		output_changed.emit(output_value)
		gate_activated.emit()
		propagate_output()

func propagate_output() -> void:
	"""Send output to all connected wires."""
	for wire in connected_output_wires:
		wire.transmit_signal(output_value)

func compute_output() -> int:
	"""Override in subclasses. Compute output based on gate type and inputs."""
	match gate_type:
		"AND":
			return compute_and()
		"OR":
			return compute_or()
		"NOT":
			return compute_not()
		"XOR":
			return compute_xor()
		"NAND":
			return compute_nand()
		"NOR":
			return compute_nor()
		"XNOR":
			return compute_xnor()
		_:
			return 0

func compute_and() -> int:
	if input_slots.is_empty():
		return 0
	for value in input_slots.values():
		if value == 0:
			return 0
	return 1

func compute_or() -> int:
	if input_slots.is_empty():
		return 0
	for value in input_slots.values():
		if value == 1:
			return 1
	return 0

func compute_not() -> int:
	if input_slots.is_empty():
		return 1
	return 1 - input_slots.get(0, 0)

func compute_xor() -> int:
	if input_slots.is_empty():
		return 0
	var result = 0
	for value in input_slots.values():
		result = result ^ value
	return result

func compute_nand() -> int:
	return 1 - compute_and()

func compute_nor() -> int:
	return 1 - compute_or()

func compute_xnor() -> int:
	return 1 - compute_xor()

func get_input_port_position(index: int) -> Vector2:
	"""Return the world position of an input port."""
	if input_ports and index < input_ports.get_child_count():
		return input_ports.get_child(index).global_position
	return global_position

func get_gate_id() -> String:
	"""Return a unique identifier for this gate instance."""
	return "%s_%d" % [gate_type, get_instance_id()]

func add_output_wire(wire: Wire) -> void:
	"""Register a wire connected to this gate's output."""
	if wire not in connected_output_wires:
		connected_output_wires.append(wire)

func highlight(color: Color) -> void:
	"""Highlight the gate with a color."""
	if background:
		background.color = color
	modulate = Color.WHITE

func reset_highlight() -> void:
	"""Reset the highlight to normal."""
	modulate = Color.WHITE

func is_fully_connected() -> bool:
	"""Check if all input ports have connections."""
	# Count how many inputs are needed
	var required_inputs = 2
	if gate_type == "NOT":
		required_inputs = 1
	return input_slots.size() >= required_inputs

func get_output_port_position() -> Vector2:
	"""Return the world position of the output port."""
	if output_port:
		return output_port.global_position
	return global_position
