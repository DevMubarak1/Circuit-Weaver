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
var indicator: ColorRect
var input_port: Area2D
var _analyzer_label: Label = null

signal value_received(received_value: int, node: OutputNode)
signal level_complete
signal mismatch_detected

func _ready() -> void:
	label = get_node_or_null("Label")
	indicator = get_node_or_null("Indicator")
	input_port = get_node_or_null("InputPort")

	if label:
		label.text = output_name
	update_indicator()

func _create_analyzer_display() -> void:
	_analyzer_label = Label.new()
	_analyzer_label.name = "AnalyzerLabel"
	_analyzer_label.add_theme_font_size_override("font_size", 10)
	_analyzer_label.add_theme_color_override("font_color", ThemeManager.SIGNAL_ACTIVE)
	_analyzer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_analyzer_label.position = Vector2(-60, -55)
	_analyzer_label.custom_minimum_size = Vector2(120, 0)
	_analyzer_label.visible = false  # Hidden until simulation runs
	add_child(_analyzer_label)

func _update_analyzer_display() -> void:
	if not _analyzer_label:
		return

	var expected_str: String = ""
	var received_str: String = ""

	for i in range(target_sequence.size()):
		expected_str += str(target_sequence[i])
		if i < received_sequence.size():
			var match_char: String = str(received_sequence[i])
			if received_sequence[i] == target_sequence[i]:
				received_str += match_char  # correct
			else:
				received_str += "✗"  # mismatch marker
		else:
			received_str += "·"  # not yet received

	_analyzer_label.text = "EXP: %s\nGOT: %s" % [expected_str, received_str]

func receive_input(value: int) -> void:
	received_value = value
	received_sequence.append(value)
	check_correctness()
	value_received.emit(value, self)
	update_indicator()
	# Create & show analyzer only when simulation actually runs
	if target_sequence.size() > 1:
		if not _analyzer_label:
			_create_analyzer_display()
			_analyzer_label.visible = true
		_update_analyzer_display()

func get_target_value() -> int:
	if target_sequence.is_empty():
		return 0
	return target_sequence[current_index % target_sequence.size()]

func advance_sequence() -> void:
	current_index += 1

func check_correctness() -> bool:
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
	if indicator:
		if is_correct:
			indicator.color = Color.GREEN
		else:
			indicator.color = Color.RED

func get_input_port_position() -> Vector2:
	if input_port:
		return input_port.global_position
	return global_position

func get_node_id() -> String:
	return "output_%s" % output_name

func reset() -> void:
	current_index = 0
	received_value = 0
	is_correct = false
	received_sequence.clear()
	update_indicator()
	if _analyzer_label:
		_analyzer_label.visible = false

func set_target_sequence(seq: Variant) -> void:
	if seq is PackedInt32Array:
		target_sequence = seq
	else:
		target_sequence = PackedInt32Array(seq)
	# Don't create analyzer display here — wait until simulation runs
