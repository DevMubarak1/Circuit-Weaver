# Theme Manager - Centralized styling
extends Node
class_name ThemeManager

const COLORS = {
	"bg_dark": Color(0.12, 0.12, 0.12, 1.0),
	"bg_darker": Color(0.08, 0.08, 0.08, 1.0),
	"accent_blue": Color(0.2, 0.6, 1.0, 1.0),
	"accent_cyan": Color(0.0, 0.8, 1.0, 1.0),
	"success_green": Color(0.2, 1.0, 0.4, 1.0),
	"warning_yellow": Color(1.0, 0.8, 0.2, 1.0),
	"danger_red": Color(1.0, 0.3, 0.3, 1.0),
	"text_primary": Color.WHITE,
	"text_secondary": Color(0.7, 0.7, 0.7, 1.0),
	"text_muted": Color(0.5, 0.5, 0.5, 1.0),
}

const GATE_COLORS = {
	"AND": Color(0.8, 0.2, 0.8),
	"OR": Color(0.8, 0.2, 0.2),
	"NOT": Color(0.2, 0.8, 0.2),
	"XOR": Color(0.8, 0.8, 0.2),
	"NAND": Color(0.6, 0.4, 0.8),
	"NOR": Color(0.8, 0.4, 0.4),
	"XNOR": Color(0.6, 0.8, 0.4),
}

static func get_color(key: String) -> Color:
	"""Get a theme color by key."""
	return COLORS.get(key, Color.WHITE)

static func get_gate_color(gate_type: String) -> Color:
	"""Get color for a specific gate type."""
	return GATE_COLORS.get(gate_type, Color(0.5, 0.5, 0.5))

static func create_button_style(bg_color: Color, _hover_color: Color) -> StyleBoxFlat:
	"""Create a styled button box."""
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style

static func create_panel_style(border_color: Color = Color.WHITE, bg_color: Color = Color(0.15, 0.15, 0.15, 0.95)) -> StyleBoxFlat:
	"""Create a styled panel box."""
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

static func create_label_settings(font_size: int = 12, color: Color = Color.WHITE) -> LabelSettings:
	"""Create label settings for consistent text styling."""
	var settings = LabelSettings.new()
	settings.font_sizes[TextServer.SPECIMEN_BASE_SIZE] = font_size
	settings.font_colors[TextServer.SPECIMEN_BASE_SIZE] = color
	return settings
