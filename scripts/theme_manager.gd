# Theme Manager - "Midnight Architect" Aesthetic for Circuit Weaver
extends Node
class_name ThemeManager

# --- MIDNIGHT ARCHITECT PALETTE ---
# HDR signal colors (values > 1.0) for WorldEnvironment glow

# Background & Structure
const MIDNIGHT_BG = Color(0.043, 0.055, 0.078, 1.0)          # #0B0E14 - Deep Charcoal
const MIDNIGHT_GRID = Color(0.122, 0.141, 0.188, 1.0)        # #1F2430 - Muted Dark Blue
const MIDNIGHT_DARKER = Color(0.02, 0.03, 0.05, 1.0)         # Even darker for depth

# Signal States (HDR - high intensity for glow)
const SIGNAL_ACTIVE = Color(0.0, 2.5, 2.5, 1.0)              # #00F5FF - Electric Cyan (HDR boosted)
const SIGNAL_INACTIVE = Color(0.173, 0.192, 0.235, 1.0)      # #2C313C - Steel Grey
const ACCENT_WARNING = Color(2.0, 1.0, 1.5, 1.0)             # #FF3366 - Cyber Pink (HDR boosted)

# --- GATE-SPECIFIC HDR COLORS ---
const GATE_AND_RED = Color(2.0, 1.0, 1.0, 1.0)               # Ruby Red (#FF4D4D) - Heavy & restrictive
const GATE_OR_GREEN = Color(1.0, 2.0, 1.3, 1.0)              # Emerald Green (#4DFF88) - Additive & welcoming
const GATE_NOT_BLUE = Color(1.0, 1.5, 2.5, 1.0)              # Electric Blue (#3399FF) - Standard inversion
const GATE_XOR_AMBER = Color(2.5, 2.0, 0.3, 1.0)             # Vivid Amber (#FFCC00) - Exclusive logic
const GATE_NAND_PURPLE = Color(2.0, 0.8, 2.0, 1.0)           # Purple variant - Negated AND
const GATE_NOR_ORANGE = Color(2.0, 1.2, 0.5, 1.0)            # Orange variant - Negated OR
const GATE_XNOR_MAGENTA = Color(2.0, 0.5, 1.5, 1.0)          # Magenta variant - Negated XOR

# --- UI TEXT COLORS ---
const TERMINAL_WHITE = Color(0.8, 0.8, 0.8, 1.0)             # Soft white
const TERMINAL_GRAY = Color(0.3, 0.3, 0.3, 1.0)              # Muted gray
const TEXT_MUTED = Color(0.5, 0.5, 0.5, 1.0)                 # Grey for secondary text

# Font sizes for consistent hierarchy
const TITLE_SIZE = 72      # "CIRCUIT WEAVER" (Geometric Font)
const HEADER_SIZE = 24     # Section headers (Geometric Font)
const BODY_SIZE = 16       # Regular text (Monospaced Font)
const SMALL_SIZE = 12      # Gate labels (Pixel Font)

# --- COLOR LOOKUP DICTIONARIES ---
const COLORS = {
	"bg_dark": MIDNIGHT_BG,
	"bg_darker": MIDNIGHT_DARKER,
	"grid": MIDNIGHT_GRID,
	"signal_active": SIGNAL_ACTIVE,
	"signal_inactive": SIGNAL_INACTIVE,
	"accent_warning": ACCENT_WARNING,
	"text_primary": TERMINAL_WHITE,
	"text_secondary": TERMINAL_GRAY,
	"text_muted": TEXT_MUTED,
}

const GATE_COLORS = {
	"AND": GATE_AND_RED,
	"OR": GATE_OR_GREEN,
	"NOT": GATE_NOT_BLUE,
	"XOR": GATE_XOR_AMBER,
	"NAND": GATE_NAND_PURPLE,
	"NOR": GATE_NOR_ORANGE,
	"XNOR": GATE_XNOR_MAGENTA,
}

static func get_color(key: String) -> Color:
	return COLORS.get(key, TERMINAL_WHITE)

static func get_gate_color(gate_type: String) -> Color:
	return GATE_COLORS.get(gate_type, Color(0.5, 0.5, 0.5, 1.0))

static func create_button_style(bg_color: Color, _hover_color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(bg_color.r * 0.3, bg_color.g * 0.3, bg_color.b * 0.3, 0.8)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style

static func create_panel_style(border_color: Color = SIGNAL_ACTIVE, bg_color: Color = MIDNIGHT_BG) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

static func create_label_settings(font_size: int = 12, color: Color = TERMINAL_WHITE) -> LabelSettings:
	var settings = LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = color
	return settings
# --- FONT STYLING ---

static func apply_title_style(label: Label, color: Color = SIGNAL_ACTIVE) -> void:
	label.add_theme_font_size_override("font_size", TITLE_SIZE)
	label.add_theme_color_override("font_color", color)

static func apply_header_style(label: Label, color: Color = SIGNAL_ACTIVE) -> void:
	label.add_theme_font_size_override("font_size", HEADER_SIZE)
	label.add_theme_color_override("font_color", color)

static func apply_body_style(label: Label, color: Color = TERMINAL_WHITE) -> void:
	label.add_theme_font_size_override("font_size", BODY_SIZE)
	label.add_theme_color_override("font_color", color)

static func apply_input_style(control: Control, color: Color = SIGNAL_ACTIVE) -> void:
	control.add_theme_font_size_override("font_size", BODY_SIZE)
	control.add_theme_color_override("font_color", color)

static func apply_button_style(button: Button, color: Color = SIGNAL_ACTIVE) -> void:
	button.add_theme_font_size_override("font_size", HEADER_SIZE)
	button.add_theme_color_override("font_color", color)

static func apply_gate_label_style(label: Label, gate_type: String = "") -> void:
	label.add_theme_font_size_override("font_size", SMALL_SIZE)
	
	if gate_type:
		var gate_color = get_gate_color(gate_type)
		label.add_theme_color_override("font_color", gate_color)
		label.text = gate_type
	else:
		label.add_theme_color_override("font_color", TERMINAL_WHITE)

static func apply_console_style(label: Label, color: Color = SIGNAL_ACTIVE) -> void:
	"""Apply console/output styling (16px, Monospaced Font, Electric Cyan default)
	For simulation output, debug info, and success messages.
	Recommended Font: JetBrains Mono, Fira Code, or Roboto Mono
	"""
	label.add_theme_font_size_override("font_size", BODY_SIZE)
	label.add_theme_color_override("font_color", color)