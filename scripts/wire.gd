# Represents a connection between two ports (gates or nodes)
extends Node2D
class_name Wire

var from_port: Node2D
var to_port: Node2D
var from_gate: Node
var to_gate: Node
var is_flowing: bool = false
var current_signal: int = 0
var line: Line2D
var glow_line: Line2D
var is_animating: bool = false
var animation_progress: float = 0.0
var _shader_material: ShaderMaterial = null
var _cached_start: Vector2 = Vector2.INF
var _cached_end: Vector2 = Vector2.INF

signal signal_transmitted(value: int)

func _ready() -> void:
	line = get_node_or_null("Line2D")
	if not line:
		line = Line2D.new()
		line.name = "Line2D"
		line.width = 2.0
		line.default_color = ThemeManager.SIGNAL_INACTIVE
		line.z_index = -1
		add_child(line)

	glow_line = Line2D.new()
	glow_line.name = "GlowLine"
	glow_line.width = 10.0
	glow_line.default_color = Color(0, 0, 0, 0)
	glow_line.z_index = -2
	add_child(glow_line)

	var shader_res = load("res://shaders/wire_pulse.gdshader")
	if shader_res:
		_shader_material = ShaderMaterial.new()
		_shader_material.shader = shader_res
		_shader_material.set_shader_parameter("is_active", false)
		line.material = _shader_material

	if from_port and to_port:
		update_line()
	if is_inside_tree():
		set_process(true)

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	# Only rebuild line when port positions actually change (gate dragged)
	if from_port and to_port:
		var s: Vector2 = from_port.global_position
		var e: Vector2 = to_port.global_position
		if s != _cached_start or e != _cached_end:
			_cached_start = s
			_cached_end = e
			_rebuild_line()
	if is_animating:
		update_animation(delta)

func update_line() -> void:
	# Force a full line rebuild and cache update
	_cached_start = Vector2.INF
	_cached_end = Vector2.INF
	_rebuild_line()

func _rebuild_line() -> void:
	if not line:
		line = get_node_or_null("Line2D")
	if not glow_line:
		glow_line = get_node_or_null("GlowLine")

	if line and from_port and to_port:
		line.clear_points()
		if glow_line:
			glow_line.clear_points()
		var start: Vector2 = to_local(from_port.global_position)
		var end_pt: Vector2 = to_local(to_port.global_position)
		var mid_x: float = (start.x + end_pt.x) / 2.0

		var points: Array[Vector2] = [
			start,
			Vector2(mid_x, start.y),
			Vector2(mid_x, end_pt.y),
			end_pt,
		]
		for pt in points:
			line.add_point(pt)
			if glow_line:
				glow_line.add_point(pt)

		# Color based on signal state
		if is_flowing:
			var active_col: Color = ThemeManager.SIGNAL_ACTIVE if current_signal == 1 else ThemeManager.ACCENT_WARNING
			line.default_color = active_col
			line.width = 4.0
			if glow_line:
				glow_line.default_color = Color(active_col.r, active_col.g, active_col.b, 0.25)
				glow_line.width = 14.0
			_set_shader_active(true, active_col)
		elif is_animating:
			line.default_color = ThemeManager.SIGNAL_ACTIVE
			line.width = 3.0
			if glow_line:
				glow_line.default_color = Color(ThemeManager.SIGNAL_ACTIVE.r, ThemeManager.SIGNAL_ACTIVE.g, ThemeManager.SIGNAL_ACTIVE.b, 0.15)
				glow_line.width = 12.0
			_set_shader_active(true, ThemeManager.SIGNAL_ACTIVE)
		else:
			line.default_color = ThemeManager.SIGNAL_INACTIVE
			line.width = 2.0
			if glow_line:
				glow_line.default_color = Color(0, 0, 0, 0)
				glow_line.width = 0.0
			_set_shader_active(false, ThemeManager.SIGNAL_INACTIVE)

func _set_shader_active(active: bool, color: Color) -> void:
	if _shader_material:
		_shader_material.set_shader_parameter("is_active", active)
		_shader_material.set_shader_parameter("active_color", color)

func connect_ports(source_port: Node2D, source_gate: Node, dest_port: Node2D, dest_gate: Node) -> void:
	from_port = source_port
	from_gate = source_gate
	to_port = dest_port
	to_gate = dest_gate

	if not line:
		line = Line2D.new()
		line.name = "Line2D"
		line.width = 2.0
		line.default_color = ThemeManager.SIGNAL_INACTIVE
		line.z_index = -1
		add_child(line)

	update_line()

	if from_port:
		from_port.set_meta("connected_wire", self)
	if to_port:
		to_port.set_meta("connected_wire", self)

func transmit_signal(value: int) -> void:
	current_signal = value
	is_flowing = true
	is_animating = true
	animation_progress = 0.0
	if is_inside_tree():
		set_process(true)
	signal_transmitted.emit(value)

func receive_at_destination() -> void:
	if to_gate:
		if to_gate is LogicGate:
			var port_idx: int = 0
			if to_port and to_port.has_meta("port_index"):
				port_idx = to_port.get_meta("port_index")
			to_gate.add_input(current_signal, port_idx)
		elif to_gate is OutputNode:
			to_gate.receive_input(current_signal)

func update_animation(delta: float) -> void:
	if is_animating:
		animation_progress += delta * 3.0
		if animation_progress >= 1.0:
			is_animating = false
			is_flowing = false
			animation_progress = 1.0
			# NOTE: Do NOT call set_process(false) here — update_line() must
			# keep running so wires redraw when gates are dragged.
	elif not is_flowing:
		set_process(false)

func get_signal_value() -> int:
	return current_signal

func stop_flowing() -> void:
	is_animating = false
	is_flowing = false
	animation_progress = 0.0
	_set_shader_active(false, ThemeManager.SIGNAL_INACTIVE)
	set_process(false)
