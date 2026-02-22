# Input node that provides a binary signal
extends Node2D
class_name InputNode

@export var input_name: String = "A"
@export var signal_sequence: PackedInt32Array = [1]  # Can be single value or sequence
@export var position_in_grid: Vector2i = Vector2i.ZERO

var current_index: int = 0
var output_value: int = 1
var connected_wires: Array[Wire] = []
var label: Label
var output_port: Area2D

signal output_changed(value: int)

func _ready() -> void:
	label = get_node_or_null("Label")
	output_port = get_node_or_null("OutputPort")
	
	if label:
		label.text = input_name
	output_value = signal_sequence[0]
	set_process_input(true)

func get_current_value() -> int:
	return signal_sequence[current_index % signal_sequence.size()]

func advance_sequence() -> void:
	current_index += 1
	var new_value = get_current_value()
	if new_value != output_value:
		output_value = new_value
		output_changed.emit(output_value)
		propagate_to_wires()

func propagate_to_wires() -> void:
	var value = get_current_value()
	for wire in connected_wires:
		wire.transmit_signal(value)

func add_connected_wire(wire: Wire) -> void:
	if wire not in connected_wires:
		connected_wires.append(wire)

func get_output_port_position() -> Vector2:
	if output_port:
		return output_port.global_position
	return global_position

func get_node_id() -> String:
	return "input_%s" % input_name

func reset() -> void:
	current_index = 0
	output_value = signal_sequence[0]

func set_binary_sequence(seq: Array[int]) -> void:
	signal_sequence = PackedInt32Array(seq)
	output_value = signal_sequence[0]
	current_index = 0
