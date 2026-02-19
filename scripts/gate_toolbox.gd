# Gate selection toolbox - coordinator for UI and drag-and-drop
extends Control
class_name GateToolbox

const AVAILABLE_GATES = ["AND", "OR", "NOT", "XOR", "NAND", "NOR", "XNOR"]
const GATE_ICON_PATHS: Dictionary = {
	"AND": "res://assets/AND_ANSI.svg",
	"OR": "res://assets/OR_ANSI.svg",
	"NOT": "res://assets/NOT_ANSI.svg",
	"XOR": "res://assets/XOR_ANSI.svg",
	"NAND": "res://assets/NAND_ANSI.svg",
	"NOR": "res://assets/NOR_ANSI.svg",
	"XNOR": "res://assets/XNOR_ANSI.svg"
}

var selected_gate: String = ""
var dragging_gate_type: String = ""
var dragging_button: TextureButton = null
var drag_start_pos: Vector2 = Vector2.ZERO
var drag_preview: TextureRect = null
var game_manager: GameManager
var gate_buttons: Dictionary = {}  # gate_type -> TextureButton

signal gate_selected(gate_type: String)
signal gate_placement_requested(gate_type: String, position: Vector2)

func setup(manager: GameManager) -> void:
	"""Setup the toolbox with reference to game manager."""
	game_manager = manager
	mouse_filter = Control.MOUSE_FILTER_PASS
	# Clean up drag preview if scene changes while dragging
	tree_exiting.connect(_cleanup_drag)

func _process(_delta: float) -> void:
	"""Handle drag preview during dragging."""
	if dragging_gate_type != "" and dragging_button:
		var current_pos = get_global_mouse_position()
		var drag_distance = drag_start_pos.distance_to(current_pos)
		
		# Start drag preview after moving 20 pixels
		if drag_distance > 20.0:
			if not drag_preview:
				_create_drag_preview()
			
			if drag_preview:
				# Position preview directly at cursor with no offset
				drag_preview.global_position = current_pos
				drag_preview.visible = true

func _create_drag_preview() -> void:
	"""Create a preview texture rect that follows the mouse during drag."""
	drag_preview = TextureRect.new()
	drag_preview.custom_minimum_size = Vector2(120, 120)
	# Godot 4: TextureRect does not have expand_mode or TextureContainer. Use stretch_mode if needed.
	drag_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED  # Or another valid mode
	
	var icon_path = GATE_ICON_PATHS.get(dragging_gate_type)
	if icon_path:
		var texture = load(icon_path)
		if texture:
			drag_preview.texture = texture
	
	drag_preview.modulate = Color(1.0, 1.0, 1.0, 0.7)
	drag_preview.z_index = 1000
	get_viewport().add_child(drag_preview)

func _input(event: InputEvent) -> void:
	"""Handle mouse input for drag-and-drop."""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# In Godot 4, released is not a property. Use not event.pressed for release.
			if not event.pressed and dragging_gate_type != "":
				_handle_gate_drop()

func _on_gate_button_down(btn: TextureButton, gate_type: String) -> void:
	"""Called when a gate button is pressed down."""
	dragging_gate_type = gate_type
	dragging_button = btn
	drag_start_pos = get_global_mouse_position()
	selected_gate = gate_type
	gate_selected.emit(gate_type)
	# Change cursor to hand while dragging
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	set_process(true)

func _handle_gate_drop() -> void:
	"""Handle gate drop at current mouse position."""
	# Get mouse position in local toolbox coordinates to check if over toolbox
	var local_mouse_pos = get_local_mouse_position()
	var toolbox_rect = get_rect()
	var is_over_toolbox = toolbox_rect.has_point(local_mouse_pos)
	
	if not is_over_toolbox:
		# Use simplest coordinate system: global mouse position
		var world_pos = get_global_mouse_position()
		gate_placement_requested.emit(dragging_gate_type, world_pos)
	
	_cleanup_drag()

func _cleanup_drag() -> void:
	"""Clean up drag preview and state."""
	if drag_preview and drag_preview.is_queued_for_deletion() == false:
		drag_preview.queue_free()
	drag_preview = null
	dragging_gate_type = ""
	dragging_button = null
	drag_start_pos = Vector2.ZERO
	# Reset cursor to default
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	set_process(false)

func get_selected_gate() -> String:
	"""Return the currently selected gate type."""
	return selected_gate
