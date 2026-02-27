# Gate icon for drag-and-drop placement
extends TextureRect
class_name GateIcon

signal gate_clicked(gate_type: String)

@export var gate_type: String = "AND"

# Scroll-safe touch tracking
var _touch_start_pos: Vector2 = Vector2.ZERO
var _touch_moved: bool = false
const _SCROLL_THRESHOLD: float = 10.0

# --- TRUTH TABLE DATA ---

const TRUTH_TABLES: Dictionary = {
	"NOT": {
		"header": "A | Y",
		"rows": ["0 | 1", "1 | 0"],
		"desc": "Inverts the input signal."
	},
	"AND": {
		"header": "A B | Y",
		"rows": ["0 0 | 0", "0 1 | 0", "1 0 | 0", "1 1 | 1"],
		"desc": "Output 1 only when ALL inputs are 1."
	},
	"OR": {
		"header": "A B | Y",
		"rows": ["0 0 | 0", "0 1 | 1", "1 0 | 1", "1 1 | 1"],
		"desc": "Output 1 when ANY input is 1."
	},
	"XOR": {
		"header": "A B | Y",
		"rows": ["0 0 | 0", "0 1 | 1", "1 0 | 1", "1 1 | 0"],
		"desc": "Output 1 when inputs DIFFER."
	},
	"NAND": {
		"header": "A B | Y",
		"rows": ["0 0 | 1", "0 1 | 1", "1 0 | 1", "1 1 | 0"],
		"desc": "Inverted AND — 0 only when both 1."
	},
	"NOR": {
		"header": "A B | Y",
		"rows": ["0 0 | 1", "0 1 | 0", "1 0 | 0", "1 1 | 0"],
		"desc": "Inverted OR — 1 only when both 0."
	},
	"XNOR": {
		"header": "A B | Y",
		"rows": ["0 0 | 1", "0 1 | 0", "1 0 | 0", "1 1 | 1"],
		"desc": "Output 1 when inputs are SAME."
	}
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(60, 60)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var svg_path = get_gate_svg_path(gate_type)
	if ResourceLoader.exists(svg_path):
		texture = load(svg_path)
	else:
		pass

	tooltip_text = _build_tooltip_text()

func get_gate_svg_path(gate: String) -> String:
	match gate:
		"AND":  return "res://assets/and-whiteansi.svg"
		"OR":   return "res://assets/or-whiteansi.svg"
		"NOT":  return "res://assets/not-whiteansi.svg"
		"XOR":  return "res://assets/xor-whiteansi.svg"
		"NAND": return "res://assets/nand-whiteansi.svg"
		"NOR":  return "res://assets/nor-whiteansi.svg"
		"XNOR": return "res://assets/xnor-whiteansi.svg"
		_:      return "res://assets/and-whiteansi.svg"

func _build_tooltip_text() -> String:
	var table: Dictionary = TRUTH_TABLES.get(gate_type, {})
	if table.is_empty():
		return gate_type
	var text: String = "━━ %s GATE ━━\n" % gate_type
	text += table["desc"] + "\n\n"
	text += "TRUTH TABLE:\n"
	text += table["header"] + "\n"
	text += "─".repeat(table["header"].length()) + "\n"
	for row in table["rows"]:
		text += row + "\n"
	return text

func _make_custom_tooltip(for_text: String) -> Control:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.10, 0.97)
	style.border_color = ThemeManager.SIGNAL_ACTIVE
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var label = Label.new()
	label.text = for_text
	label.add_theme_color_override("font_color", ThemeManager.SIGNAL_ACTIVE)
	label.add_theme_font_size_override("font_size", 12)
	panel.add_child(label)

	return panel

func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview = TextureRect.new()
	preview.texture = texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = Vector2(64, 64)
	preview.modulate.a = 0.7
	preview.self_modulate = ThemeManager.SIGNAL_ACTIVE
	set_drag_preview(preview)
	return {
		"type": "gate",
		"gate_type": gate_type,
		"source": self
	}

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		self_modulate = ThemeManager.SIGNAL_ACTIVE
		modulate = Color(1.5, 1.5, 1.5)
		gate_clicked.emit(gate_type)
		var sfx = get_node_or_null("/root/SFXManager")
		if sfx:
			sfx.play_button_press()
	elif event is InputEventScreenTouch:
		if event.pressed:
			# Record where the finger landed — don't fire yet (could be start of a scroll)
			_touch_start_pos = event.position
			_touch_moved = false
		else:
			# Finger lifted — only treat as a tap if it barely moved
			if not _touch_moved:
				self_modulate = ThemeManager.SIGNAL_ACTIVE
				modulate = Color(1.5, 1.5, 1.5)
				gate_clicked.emit(gate_type)
				var sfx = get_node_or_null("/root/SFXManager")
				if sfx:
					sfx.play_button_press()
	elif event is InputEventScreenDrag:
		# Finger is dragging — mark as scroll if it moved past threshold
		if _touch_start_pos != Vector2.ZERO and event.position.distance_to(_touch_start_pos) > _SCROLL_THRESHOLD:
			_touch_moved = true

func clear_highlight() -> void:
	modulate = Color.WHITE

func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	return false
