# Visual Feedback System - Status indicators and animations
extends Node2D
class_name VisualFeedbackSystem

var animated_signals: Array[Dictionary] = []  # Active signal animations

func _process(delta: float) -> void:
	var i = 0
	while i < animated_signals.size():
		var signal_anim = animated_signals[i]
		signal_anim["progress"] += delta / signal_anim["duration"]
		
		if signal_anim["progress"] >= 1.0:
			animated_signals.remove_at(i)
		else:
			i += 1
	
	queue_redraw()

func _draw() -> void:
	for signal_anim in animated_signals:
		var start_pos = signal_anim["start"]
		var end_pos = signal_anim["end"]
		var progress = signal_anim["progress"]
		var value = signal_anim["value"]
		var current_pos = start_pos.lerp(end_pos, progress)
		
		# Active = Electric Cyan, Inactive = Cyber Pink
		var color = ThemeManager.SIGNAL_ACTIVE if value == 1 else ThemeManager.ACCENT_WARNING
		draw_circle(current_pos, 4, color)
		
		draw_circle(current_pos, 3 + (1.0 - progress) * 2, Color(color.r, color.g, color.b, 0.3))

func add_signal_animation(start_pos: Vector2, end_pos: Vector2, value: int, duration: float = 0.5) -> void:
	animated_signals.append({
		"start": start_pos,
		"end": end_pos,
		"value": value,
		"duration": duration,
		"progress": 0.0
	})

class GateVisualState:
	var gate_type: String
	var input_values: Array[int]
	var output_value: int
	var is_active: bool
	var position: Vector2
	
	func _init(p_type: String, p_position: Vector2) -> void:
		gate_type = p_type
		position = p_position
		output_value = 0
		is_active = false
		input_values = []
	
	func get_display_text() -> String:
		return gate_type.substr(0, 3).to_upper()
	
	func update_inputs(values: Array[int]) -> void:
		input_values = values
		is_active = true

class PortVisualState:
	var port_type: String  # "input" or "output"
	var is_connected: bool
	var current_value: int
	var position: Vector2
	
	func _init(p_type: String, p_position: Vector2) -> void:
		port_type = p_type
		position = p_position
		current_value = 0
		is_connected = false

var gate_states: Dictionary = {}  # gate_id -> GateVisualState
var port_states: Dictionary = {}  # port_id -> PortVisualState

func register_gate(gate_id: String, gate_type: String, position: Vector2) -> void:
	gate_states[gate_id] = GateVisualState.new(gate_type, position)

func update_gate_state(gate_id: String, input_values: Array[int], output_value: int) -> void:
	if gate_states.has(gate_id):
		var state = gate_states[gate_id]
		state.update_inputs(input_values)
		state.output_value = output_value

func register_port(port_id: String, port_type: String, position: Vector2) -> void:
	port_states[port_id] = PortVisualState.new(port_type, position)

func update_port_value(port_id: String, value: int) -> void:
	if port_states.has(port_id):
		port_states[port_id].current_value = value

func emit_success_feedback(at_position: Vector2) -> void:
	_spawn_ring(at_position, ThemeManager.SIGNAL_ACTIVE, 30.0)

func emit_error_feedback(at_position: Vector2) -> void:
	_spawn_ring(at_position, ThemeManager.ACCENT_WARNING, 25.0)

func _spawn_ring(center: Vector2, color: Color, max_radius: float) -> void:
	var ring := _FeedbackRing.new(center, color, max_radius)
	add_child(ring)

class _FeedbackRing extends Node2D:
	var _center: Vector2
	var _color: Color
	var _max_radius: float
	var _elapsed: float = 0.0
	var _duration: float = 0.4

	func _init(center: Vector2, color: Color, max_r: float) -> void:
		_center = center
		_color = color
		_max_radius = max_r

	func _process(delta: float) -> void:
		_elapsed += delta
		if _elapsed >= _duration:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t: float = _elapsed / _duration
		var radius: float = _max_radius * t
		var alpha: float = 1.0 - t
		var c := Color(_color.r, _color.g, _color.b, alpha * 0.7)
		draw_arc(_center, radius, 0, TAU, 32, c, 2.0)

func get_port_color(port_id: String) -> Color:
	if port_states.has(port_id):
		var value = port_states[port_id].current_value
		return ThemeManager.SIGNAL_ACTIVE if value == 1 else ThemeManager.ACCENT_WARNING
	return ThemeManager.SIGNAL_INACTIVE
