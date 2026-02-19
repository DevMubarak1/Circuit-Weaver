# Drop zone overlay for the circuit board area
# Catches gate drops from the toolbox and forwards them to the CircuitBoard
extends Control
class_name BoardDropZone

var circuit_board: CircuitBoard = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is Dictionary:
		return data.has("type") and data["type"] == "gate" and data.has("gate_type")
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not circuit_board:
		return
	if data is Dictionary and data.has("gate_type"):
		var gate_type: String = data["gate_type"]
		var global_drop_pos = get_global_mouse_position()
		var local_pos = circuit_board.to_local(global_drop_pos)
		var grid_pos = Vector2i(int(local_pos.x / circuit_board.GRID_SIZE), int(local_pos.y / circuit_board.GRID_SIZE))
		circuit_board.place_gate(gate_type, grid_pos, local_pos)
