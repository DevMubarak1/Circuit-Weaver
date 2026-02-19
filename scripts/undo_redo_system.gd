# Undo / Redo system for Circuit Weaver
# Tracks gate placements, deletions, and wire connections
extends RefCounted
class_name UndoRedoSystem

# Action types
enum ActionType { PLACE_GATE, DELETE_GATE, CONNECT_WIRE, DELETE_WIRE }

# Each action is a Dictionary:
#   { "type": ActionType, "data": { ... } }
var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []
var _max_history: int = 50
var _circuit_board: CircuitBoard

func init(board: CircuitBoard) -> void:
	_circuit_board = board

# --- RECORD ACTIONS ---

func record_place_gate(gate: LogicGate) -> void:
	_push_undo({
		"type": ActionType.PLACE_GATE,
		"data": {
			"gate_id": gate.get_gate_id(),
			"gate_type": gate.gate_type,
			"position": gate.position
		}
	})

func record_delete_gate(gate: LogicGate, connected_wires_data: Array[Dictionary]) -> void:
	_push_undo({
		"type": ActionType.DELETE_GATE,
		"data": {
			"gate_type": gate.gate_type,
			"position": gate.position,
			"connected_wires": connected_wires_data
		}
	})

func record_connect_wire(wire: Wire) -> void:
	_push_undo({
		"type": ActionType.CONNECT_WIRE,
		"data": {
			"wire_name": wire.name,
			"from_port_path": _get_port_path(wire.from_port),
			"to_port_path": _get_port_path(wire.to_port),
			"from_gate_path": _get_node_path(wire.from_gate),
			"to_gate_path": _get_node_path(wire.to_gate)
		}
	})

func record_delete_wire(wire: Wire) -> void:
	_push_undo({
		"type": ActionType.DELETE_WIRE,
		"data": {
			"from_port_path": _get_port_path(wire.from_port),
			"to_port_path": _get_port_path(wire.to_port),
			"from_gate_path": _get_node_path(wire.from_gate),
			"to_gate_path": _get_node_path(wire.to_gate)
		}
	})

# --- UNDO / REDO ---

func can_undo() -> bool:
	return not _undo_stack.is_empty()

func can_redo() -> bool:
	return not _redo_stack.is_empty()

func undo() -> void:
	if _undo_stack.is_empty() or not _circuit_board:
		return
	var action: Dictionary = _undo_stack.pop_back()
	_redo_stack.append(action)

	match action["type"]:
		ActionType.PLACE_GATE:
			_undo_place_gate(action["data"])
		ActionType.DELETE_GATE:
			_undo_delete_gate(action["data"])
		ActionType.CONNECT_WIRE:
			_undo_connect_wire(action["data"])
		ActionType.DELETE_WIRE:
			_undo_delete_wire(action["data"])

func redo() -> void:
	if _redo_stack.is_empty() or not _circuit_board:
		return
	var action: Dictionary = _redo_stack.pop_back()
	_undo_stack.append(action)

	match action["type"]:
		ActionType.PLACE_GATE:
			_redo_place_gate(action["data"])
		ActionType.DELETE_GATE:
			_redo_delete_gate(action["data"])
		ActionType.CONNECT_WIRE:
			_redo_connect_wire(action["data"])
		ActionType.DELETE_WIRE:
			_redo_delete_wire(action["data"])

func clear() -> void:
	_undo_stack.clear()
	_redo_stack.clear()

# --- UNDO IMPLEMENTATIONS ---

func _undo_place_gate(data: Dictionary) -> void:
	var gate_id: String = data["gate_id"]
	if _circuit_board.gates.has(gate_id):
		var gate: LogicGate = _circuit_board.gates[gate_id]
		# Remove connected wires
		var wires_to_remove: Array[Wire] = []
		for wire in _circuit_board.wires:
			if wire.from_gate == gate or wire.to_gate == gate:
				wires_to_remove.append(wire)
		for wire in wires_to_remove:
			wire.queue_free()
			_circuit_board.wires.erase(wire)
		_circuit_board.gates.erase(gate_id)
		gate.queue_free()

func _undo_delete_gate(data: Dictionary) -> void:
	var gate_type: String = data["gate_type"]
	var pos: Vector2 = data["position"]
	var grid_pos = Vector2i(int(pos.x / _circuit_board.GRID_SIZE), int(pos.y / _circuit_board.GRID_SIZE))
	_circuit_board.place_gate(gate_type, grid_pos, pos)

func _undo_connect_wire(data: Dictionary) -> void:
	for i in range(_circuit_board.wires.size() - 1, -1, -1):
		var wire: Wire = _circuit_board.wires[i]
		if _get_port_path(wire.from_port) == data["from_port_path"] and _get_port_path(wire.to_port) == data["to_port_path"]:
			wire.queue_free()
			_circuit_board.wires.remove_at(i)
			break

func _undo_delete_wire(data: Dictionary) -> void:
	_reconnect_wire_from_data(data)

# --- REDO IMPLEMENTATIONS ---

func _redo_place_gate(data: Dictionary) -> void:
	var gate_type: String = data["gate_type"]
	var pos: Vector2 = data["position"]
	var grid_pos = Vector2i(int(pos.x / _circuit_board.GRID_SIZE), int(pos.y / _circuit_board.GRID_SIZE))
	var new_gate = _circuit_board.place_gate(gate_type, grid_pos, pos)
	# Update stored gate_id so subsequent undos target the correct instance
	if new_gate:
		data["gate_id"] = new_gate.get_gate_id()

func _redo_delete_gate(data: Dictionary) -> void:
	_undo_place_gate(data)  # Same logic — remove the gate

func _redo_connect_wire(data: Dictionary) -> void:
	_reconnect_wire_from_data(data)

func _redo_delete_wire(data: Dictionary) -> void:
	_undo_connect_wire(data)

# --- WIRE RECONNECTION HELPER ---

func _reconnect_wire_from_data(data: Dictionary) -> void:
	var from_path: String = data.get("from_port_path", "")
	var to_path: String = data.get("to_port_path", "")
	if from_path.is_empty() or to_path.is_empty():
		return
	var from_port: Node2D = _circuit_board.get_node_or_null(NodePath(from_path)) as Node2D
	var to_port: Node2D = _circuit_board.get_node_or_null(NodePath(to_path)) as Node2D
	if not from_port or not to_port:
		# Try relative to root
		from_port = _circuit_board.get_tree().root.get_node_or_null(NodePath(from_path)) as Node2D
		to_port = _circuit_board.get_tree().root.get_node_or_null(NodePath(to_path)) as Node2D
	if not from_port or not to_port:
		return
	# Create wire via board's helper
	var from_gate = from_port.get_meta("gate_owner") if from_port.has_meta("gate_owner") else null
	var to_gate = to_port.get_meta("gate_owner") if to_port.has_meta("gate_owner") else null
	var wire: Wire = Wire.new()
	wire.name = "Wire_%d" % _circuit_board.wires.size()
	var container = _circuit_board.get_node_or_null("WiresContainer")
	if container:
		container.add_child(wire)
		wire.connect_ports(from_port, from_gate, to_port, to_gate)
		_circuit_board.wires.append(wire)
		if from_gate and from_gate is LogicGate:
			from_gate.add_output_wire(wire)
		elif from_gate and from_gate is InputNode:
			from_gate.add_connected_wire(wire)

# --- UTILITIES ---

func _push_undo(action: Dictionary) -> void:
	_undo_stack.append(action)
	_redo_stack.clear()  # New action invalidates redo history
	if _undo_stack.size() > _max_history:
		_undo_stack.pop_front()

func _get_port_path(port: Node2D) -> String:
	if port and port.is_inside_tree():
		return str(port.get_path())
	return ""

func _get_node_path(node: Node) -> String:
	if node and node.is_inside_tree():
		return str(node.get_path())
	return ""

func get_undo_count() -> int:
	return _undo_stack.size()

func get_redo_count() -> int:
	return _redo_stack.size()
