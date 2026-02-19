# Main game manager and level controller
extends Node2D
class_name GameManager

var current_level_index: int = 0
var levels: Array[GameLevel] = []
var circuit_board: CircuitBoard
var ui_manager: UIManager

signal level_started(level_name: String)
signal level_completed(level_name: String)
signal game_over

@onready var canvas_layer = $CanvasLayer

func _ready() -> void:
	setup_levels()
	setup_ui()
	await get_tree().process_frame  # Wait for all nodes to initialize
	load_level(0)

func setup_levels() -> void:
	"""Create the level progression."""
	# Level 1: Simple NOT gate
	var level1 = GameLevel.new("NOT Gate Basics", "Place a NOT gate to invert the input signal")
	level1.input_nodes.append({
		"name": "A",
		"sequence": PackedInt32Array([1, 0, 1]),
		"position": Vector2i(2, 5)
	})
	level1.output_nodes.append({
		"name": "Output",
		"target": PackedInt32Array([0, 1, 0]),
		"position": Vector2i(15, 5)
	})
	level1.allowed_gates.append("NOT")
	level1.allowed_gates.append("AND")
	level1.allowed_gates.append("OR")
	level1.allowed_gates.append("XOR")
	level1.allowed_gates.append("NAND")
	level1.allowed_gates.append("NOR")
	level1.allowed_gates.append("XNOR")
	level1.max_gates = 1
	levels.append(level1)
	
	# Level 2: AND gate
	var level2 = GameLevel.new("AND Gate Logic", "Connect two inputs to an AND gate")
	level2.input_nodes.append({
		"name": "A",
		"sequence": PackedInt32Array([1, 1, 0, 0]),
		"position": Vector2i(2, 3)
	})
	level2.input_nodes.append({
		"name": "B",
		"sequence": PackedInt32Array([1, 0, 1, 0]),
		"position": Vector2i(2, 7)
	})
	level2.output_nodes.append({
		"name": "Output",
		"target": PackedInt32Array([1, 0, 0, 0]),
		"position": Vector2i(15, 5)
	})
	level2.allowed_gates.append("AND")
	level2.max_gates = 1
	levels.append(level2)
	
	# Level 3: OR gate
	var level3 = GameLevel.new("OR Gate Logic", "Connect two inputs to an OR gate")
	level3.input_nodes.append({
		"name": "A",
		"sequence": PackedInt32Array([1, 1, 0, 0]),
		"position": Vector2i(2, 3)
	})
	level3.input_nodes.append({
		"name": "B",
		"sequence": PackedInt32Array([1, 0, 1, 0]),
		"position": Vector2i(2, 7)
	})
	level3.output_nodes.append({
		"name": "Output",
		"target": PackedInt32Array([1, 1, 1, 0]),
		"position": Vector2i(15, 5)
	})
	level3.allowed_gates.append("OR")
	level3.max_gates = 1
	levels.append(level3)
	
	# Level 4: XOR gate
	var level4 = GameLevel.new("XOR Gate Logic", "Exclusive OR - output is 1 when inputs differ")
	level4.input_nodes.append({
		"name": "A",
		"sequence": PackedInt32Array([1, 1, 0, 0]),
		"position": Vector2i(2, 3)
	})
	level4.input_nodes.append({
		"name": "B",
		"sequence": PackedInt32Array([1, 0, 1, 0]),
		"position": Vector2i(2, 7)
	})
	level4.output_nodes.append({
		"name": "Output",
		"target": PackedInt32Array([0, 1, 1, 0]),
		"position": Vector2i(15, 5)
	})
	level4.allowed_gates.append("XOR")
	level4.max_gates = 1
	levels.append(level4)

func setup_ui() -> void:
	"""Set up UI elements."""
	# Find UIManager in the scene
	var ui_node = get_node_or_null("CanvasLayer/UIManager")
	ui_manager = ui_node as UIManager
	if ui_manager:
		ui_manager.run_simulation.connect(_on_run_button_pressed)
		ui_manager.reset_level.connect(_on_reset_button_pressed)

func load_level(level_index: int) -> void:
	"""Load and initialize a level."""
	if level_index >= levels.size():
		return
	
	current_level_index = level_index
	var level = levels[level_index]
	
	# Get circuit board
	circuit_board = get_node_or_null("CircuitBoard")
	if not circuit_board:
		circuit_board = CircuitBoard.new()
		add_child(circuit_board)
		circuit_board.level_complete.connect(_on_circuit_level_complete)
	else:
		circuit_board.clear_circuit()
	
	# Pass UI manager to circuit board for status updates
	circuit_board.ui_manager = ui_manager
	
	# Set expected gate count so spacing is calculated properly
	circuit_board.total_gates_to_place = level.allowed_gates.size()
	circuit_board.gates_placed = 0
	
	# Set up level
	level_started.emit(level.name)
	
	# Add input nodes
	for input_data in level.input_nodes:
		circuit_board.add_input_node(
			input_data.name,
			input_data.sequence,
			input_data.position
		)
	
	# Add output nodes
	var first_target = 0
	for output_data in level.output_nodes:
		circuit_board.add_output_node(
			output_data.name,
			output_data.target,
			output_data.position
		)
		if first_target == 0 and output_data.target.size() > 0:
			first_target = output_data.target[0]
	
	if ui_manager:
		ui_manager.set_level_info(level.name, level.description, level.allowed_gates, first_target)
		
		# Connect output node signals to UI
		if circuit_board.output_nodes.size() > 0:
			var output_node = circuit_board.output_nodes[0]
			if not output_node.value_received.is_connected(_on_output_value_received):
				output_node.value_received.connect(_on_output_value_received.bind(output_node))

func start_simulation() -> void:
	"""Start circuit simulation."""
	if circuit_board:
		circuit_board.start_simulation()

func _on_run_button_pressed() -> void:
	"""Handle run simulation button."""
	start_simulation()

func _on_reset_button_pressed() -> void:
	"""Handle reset button."""
	restart_level()

func next_level() -> void:
	"""Load the next level."""
	if current_level_index + 1 < levels.size():
		load_level(current_level_index + 1)
	else:
		game_over.emit()

func restart_level() -> void:
	"""Restart the current level."""
	load_level(current_level_index)

func _on_circuit_level_complete() -> void:
	"""Handle level completion."""
	level_completed.emit(levels[current_level_index].name)
	if ui_manager:
		ui_manager.show_level_complete(levels[current_level_index].name)
	await get_tree().create_timer(2.0).timeout
	next_level()

func _on_output_value_received(value: int, output_node: OutputNode) -> void:
	"""Handle output value update and display."""
	if ui_manager:
		ui_manager.update_output_display(value, output_node.is_correct)
