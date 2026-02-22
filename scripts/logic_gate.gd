# Base class for all logic gates
extends Area2D
class_name LogicGate

signal output_changed(value: int)
signal gate_activated

@export var gate_type: String = "AND"
@export var position_in_grid: Vector2i = Vector2i.ZERO

var input_slots: Dictionary = {}  # Maps input_index -> value
var output_value: int = 0
@onready var sprite: Sprite2D = $Sprite2D
var input_ports: Node2D
var output_port: Area2D
var connected_output_wires: Array[Wire] = []
var _propagation_depth: int = 0
const MAX_PROPAGATION_DEPTH: int = 50

func _ready() -> void:
	input_ports = get_node_or_null("InputPorts")
	output_port = get_node_or_null("OutputPort")
	set_process_input(true)
	# Only reload icon if not already loaded (create_gate_instance may have loaded it)
	if sprite and not sprite.texture:
		load_gate_icon()
	set_meta("gate_ref", self)

func load_gate_icon() -> void:
	if not sprite:
		sprite = get_node_or_null("Sprite2D")
		if not sprite:
			return
	var svg_path = _get_white_svg_path(gate_type)
	if svg_path and ResourceLoader.exists(svg_path):
		var texture = load(svg_path)
		if texture:
			sprite.texture = texture
		else:
			pass
	else:
		# Fallback to black SVG
		var fallback = _get_black_svg_path(gate_type)
		if fallback and ResourceLoader.exists(fallback):
			sprite.texture = load(fallback)
		else:
			pass

func _get_white_svg_path(gate: String) -> String:
	match gate:
		"AND":
			return "res://assets/and-whiteansi.svg"
		"OR":
			return "res://assets/or-whiteansi.svg"
		"NOT":
			return "res://assets/not-whiteansi.svg"
		"NAND":
			return "res://assets/nand-whiteansi.svg"
		"NOR":
			return "res://assets/nor-whiteansi.svg"
		"XOR":
			return "res://assets/xor-whiteansi.svg"
		"XNOR":
			return "res://assets/xnor-whiteansi.svg"
		_:
			return "res://assets/and-whiteansi.svg"

func _get_black_svg_path(gate: String) -> String:
	match gate:
		"AND":
			return "res://assets/AND_ANSI.svg"
		"OR":
			return "res://assets/OR_ANSI.svg"
		"NOT":
			return "res://assets/NOT_ANSI.svg"
		"NAND":
			return "res://assets/NAND_ANSI.svg"
		"NOR":
			return "res://assets/NOR_ANSI.svg"
		"XOR":
			return "res://assets/XOR_ANSI.svg"
		"XNOR":
			return "res://assets/XNOR_ANSI.svg"
		_:
			return "res://assets/AND_ANSI.svg"


func add_input(value: int, port_index: int = 0) -> void:
	input_slots[port_index] = value
	evaluate()

func clear_inputs() -> void:
	input_slots.clear()
	output_value = -1  # Sentinel so first evaluate() always propagates

func evaluate() -> void:
	var new_output = compute_output()
	if new_output == output_value:
		return  # No change — skip redundant propagation
	output_value = new_output
	output_changed.emit(output_value)
	gate_activated.emit()
	propagate_output()

func propagate_output() -> void:
	_propagation_depth += 1
	if _propagation_depth > MAX_PROPAGATION_DEPTH:
		push_warning("Circuit Weaver: Propagation depth exceeded — possible feedback loop in gate %s" % get_gate_id())
		_propagation_depth = 0
		return
	for wire in connected_output_wires:
		wire.transmit_signal(output_value)
		wire.receive_at_destination()
	_propagation_depth = 0

func compute_output() -> int:
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
	# Require both inputs present; missing inputs default to 0
	for i in range(2):
		if input_slots.get(i, 0) == 0:
			return 0
	return 1

func compute_or() -> int:
	# Check both inputs; missing inputs default to 0
	for i in range(2):
		if input_slots.get(i, 0) == 1:
			return 1
	return 0

func compute_not() -> int:
	# Use .get(0, 0) to avoid errors if port 0 isn't connected yet
	return 1 if input_slots.get(0, 0) == 0 else 0

func compute_xor() -> int:
	# XOR over both inputs; missing inputs default to 0
	var result = 0
	for i in range(2):
		result = result ^ input_slots.get(i, 0)
	return result

func compute_nand() -> int:
	return 1 - compute_and()

func compute_nor() -> int:
	return 1 - compute_or()

func compute_xnor() -> int:
	return 1 - compute_xor()

func get_input_port_position(index: int) -> Vector2:
	if input_ports and index < input_ports.get_child_count():
		return input_ports.get_child(index).global_position
	return global_position

func get_gate_id() -> String:
	return "%s_%d" % [gate_type, get_instance_id()]

func add_output_wire(wire: Wire) -> void:
	if wire not in connected_output_wires:
		connected_output_wires.append(wire)

func highlight(color: Color) -> void:
	modulate = color

func reset_highlight() -> void:
	modulate = Color.WHITE

func is_fully_connected() -> bool:
	var required_inputs = 2
	if gate_type == "NOT":
		required_inputs = 1
	return input_slots.size() >= required_inputs

func get_output_port_position() -> Vector2:
	if output_port:
		return output_port.global_position
	return global_position
