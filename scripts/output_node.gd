# Output node that receives a signal and checks against target
extends Node2D
class_name OutputNode

@export var output_name: String = "Output"
@export var target_sequence: PackedInt32Array = [1]  # Expected output sequence
@export var position_in_grid: Vector2i = Vector2i.ZERO

var current_index: int = 0
var received_value: int = 0
var is_correct: bool = false
var received_sequence: PackedInt32Array = []
var label: Label
var sprite: Sprite2D
var indicator: ColorRect
var input_port: Area2D

signal value_received(received_value: int)
signal level_complete
signal mismatch_detected

func _ready() -> void:
	label = get_node_or_null("Label")
	sprite = get_node_or_null("Sprite2D")
	indicator = get_node_or_null("Indicator")
	input_port = get_node_or_null("InputPort")
	
	if label:
		label.text = output_name
	update_indicator()

func receive_input(value: int) -> void:
	"""Receive an input signal and validate it."""
	received_value = value
	received_sequence.append(value)
	print("✓ Output '%s' received: %d (expected: %d)" % [output_name, value, get_target_value()])
	value_received.emit(value)
	check_correctness()
	update_indicator()

func get_target_value() -> int:
	"""Get the target value at current position."""
	if target_sequence.is_empty():
		return 0
	return target_sequence[current_index % target_sequence.size()]

func advance_sequence() -> void:
	"""Move to next position in the sequence."""
	current_index += 1

func check_correctness() -> bool:
	"""Check if the received sequence matches the target so far."""
	if received_sequence.size() > target_sequence.size():
		is_correct = false
		mismatch_detected.emit()
		return false
	
	for i in range(received_sequence.size()):
		if received_sequence[i] != target_sequence[i % target_sequence.size()]:
			is_correct = false
			mismatch_detected.emit()
			return false
	
	is_correct = true
	if received_sequence.size() == target_sequence.size():
		level_complete.emit()
	
	return true

func update_indicator() -> void:
	"""Update visual feedback based on correctness."""
	if indicator:
		if is_correct:
			indicator.color = Color.GREEN
		else:
			indicator.color = Color.RED

func get_input_port_position() -> Vector2:
	"""Return the world position of the input port."""
	if input_port:
		return input_port.global_position
	return global_position

func get_node_id() -> String:
	"""Return a unique identifier."""
	return "output_%s" % output_name

func reset() -> void:
	"""Reset for a new simulation."""
	current_index = 0
	received_value = 0
	is_correct = false
	received_sequence.clear()
	update_indicator()
