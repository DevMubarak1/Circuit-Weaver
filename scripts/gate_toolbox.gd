# Gate selection toolbox UI
extends Control
class_name GateToolbox

const AVAILABLE_GATES = ["AND", "OR", "NOT", "XOR", "NAND", "NOR", "XNOR"]

var selected_gate: String = ""
var dragging_gate: String = ""
var drag_start_pos: Vector2 = Vector2.ZERO
var game_manager: GameManager

signal gate_selected(gate_type: String)
signal gate_placement_requested(gate_type: String, position: Vector2)

func setup(manager: GameManager) -> void:
	"""Setup the toolbox with reference to game manager."""
	game_manager = manager

func _on_gate_button_pressed(gate_type: String) -> void:
	"""Handle gate button click."""
	selected_gate = gate_type
	gate_selected.emit(gate_type)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and selected_gate != "":
			dragging_gate = selected_gate
			drag_start_pos = get_global_mouse_position()
		elif event.released and dragging_gate != "":
			var drop_pos = get_global_mouse_position()
			# Only place if dropped on the circuit board
			if drop_pos.x > 250:  # Assume toolbox is on left
				gate_placement_requested.emit(dragging_gate, drop_pos)
			dragging_gate = ""

func get_selected_gate() -> String:
	"""Return the currently selected gate type."""
	return selected_gate

