# Theme Manager - "Midnight Architect" Aesthetic for Circuit Weaver
# Enhanced with glassmorphic panels, gradient accents, chapter themes
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
const ACCENT_SUCCESS = Color(0.2, 1.0, 0.5, 1.0)             # Emerald success (non-HDR for UI)

# --- GATE-SPECIFIC HDR COLORS ---
const GATE_AND_RED = Color(2.0, 1.0, 1.0, 1.0)               # Ruby Red (#FF4D4D)
const GATE_OR_GREEN = Color(1.0, 2.0, 1.3, 1.0)              # Emerald Green (#4DFF88)
const GATE_NOT_BLUE = Color(1.0, 1.5, 2.5, 1.0)              # Electric Blue (#3399FF)
const GATE_XOR_AMBER = Color(2.5, 2.0, 0.3, 1.0)             # Vivid Amber (#FFCC00)
const GATE_NAND_PURPLE = Color(2.0, 0.8, 2.0, 1.0)           # Purple variant
const GATE_NOR_ORANGE = Color(2.0, 1.2, 0.5, 1.0)            # Orange variant
const GATE_XNOR_MAGENTA = Color(2.0, 0.5, 1.5, 1.0)          # Magenta variant

# --- UI TEXT COLORS ---
const TERMINAL_WHITE = Color(0.88, 0.90, 0.92, 1.0)          # Crisp soft white
const TERMINAL_GRAY = Color(0.3, 0.3, 0.3, 1.0)              # Muted gray
const TEXT_MUTED = Color(0.45, 0.48, 0.52, 1.0)              # Cool grey for secondary
const TEXT_DIM = Color(0.25, 0.27, 0.30, 1.0)                # Very subtle text

# --- CHAPTER COLOR THEMES ---
# Each chapter has an accent color and a subtle tint for its cards/borders
const CHAPTER_COLORS: Dictionary = {
	1: {"accent": Color(0.0, 0.85, 0.85, 1.0), "tint": Color(0.0, 0.15, 0.18, 1.0), "name": "Cyan"},
	2: {"accent": Color(0.4, 0.6, 1.0, 1.0), "tint": Color(0.06, 0.08, 0.18, 1.0), "name": "Sapphire"},
	3: {"accent": Color(0.7, 0.4, 1.0, 1.0), "tint": Color(0.10, 0.05, 0.18, 1.0), "name": "Violet"},
	4: {"accent": Color(1.0, 0.65, 0.2, 1.0), "tint": Color(0.15, 0.10, 0.04, 1.0), "name": "Gold"},
}

# --- GLASS PANEL COLORS ---
const GLASS_BG = Color(0.06, 0.08, 0.12, 0.75)               # Semi-transparent dark
const GLASS_BG_LIGHT = Color(0.10, 0.12, 0.18, 0.65)         # Lighter glass
const GLASS_BORDER = Color(0.2, 0.25, 0.35, 0.5)             # Subtle glass border
const GLASS_HIGHLIGHT = Color(1.0, 1.0, 1.0, 0.04)           # Top reflection

# Font sizes for consistent hierarchy
const TITLE_SIZE = 72
const HEADER_SIZE = 24
const SUBHEADER_SIZE = 18
const BODY_SIZE = 16
const CAPTION_SIZE = 13
const SMALL_SIZE = 12
const TINY_SIZE = 10

const GATE_COLORS = {
	"AND": GATE_AND_RED,
	"OR": GATE_OR_GREEN,
	"NOT": GATE_NOT_BLUE,
	"XOR": GATE_XOR_AMBER,
	"NAND": GATE_NAND_PURPLE,
	"NOR": GATE_NOR_ORANGE,
	"XNOR": GATE_XNOR_MAGENTA,
}

static func get_gate_color(gate_type: String) -> Color:
	return GATE_COLORS.get(gate_type, Color(0.5, 0.5, 0.5, 1.0))

static func get_chapter_accent(chapter: int) -> Color:
	var ch = CHAPTER_COLORS.get(chapter, CHAPTER_COLORS[1])
	return ch["accent"]

# ===================================================================
# GLASSMORPHIC PANEL STYLES — the core of the new visual language
# ===================================================================

static func create_glass_panel(accent: Color = SIGNAL_ACTIVE, radius: int = 12, border_w: int = 1) -> StyleBoxFlat:
	"""Semi-transparent panel with subtle border — the 'glass card' look."""
	var style = StyleBoxFlat.new()
	style.bg_color = GLASS_BG
	style.border_color = Color(accent.r * 0.3, accent.g * 0.3, accent.b * 0.3, 0.35)
	style.border_width_left = border_w
	style.border_width_right = border_w
	style.border_width_top = border_w
	style.border_width_bottom = border_w
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

static func create_glass_panel_accent(accent: Color, radius: int = 12) -> StyleBoxFlat:
	"""Glass panel with a colored left accent bar — for feature cards."""
	var style = create_glass_panel(accent, radius)
	style.border_width_left = 3
	style.border_color = Color(accent.r * 0.4, accent.g * 0.4, accent.b * 0.4, 0.5)
	# Left border is accent colored, others are subtle
	return style

# ===================================================================
# PREMIUM BUTTON STYLES
# ===================================================================

static func create_premium_button(btn: Button, accent: Color, font_sz: int = 14, min_size: Vector2 = Vector2(160, 44)) -> void:
	"""Apply a polished button style with accent color, hover glow, pressed state."""
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", font_sz)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	# Normal
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(accent.r * 0.15, accent.g * 0.15, accent.b * 0.15, 0.85)
	normal.border_color = Color(accent.r * 0.4, accent.g * 0.4, accent.b * 0.4, 0.6)
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 1
	normal.border_width_bottom = 1
	_apply_radius(normal, 8)
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.shadow_color = Color(accent.r * 0.1, accent.g * 0.1, accent.b * 0.1, 0.3)
	normal.shadow_size = 4
	normal.shadow_offset = Vector2(0, 2)
	btn.add_theme_stylebox_override("normal", normal)

	# Hover
	var hover = normal.duplicate()
	hover.bg_color = Color(accent.r * 0.22, accent.g * 0.22, accent.b * 0.22, 0.9)
	hover.border_color = Color(accent.r * 0.6, accent.g * 0.6, accent.b * 0.6, 0.8)
	hover.shadow_size = 8
	hover.shadow_color = Color(accent.r * 0.15, accent.g * 0.15, accent.b * 0.15, 0.5)
	btn.add_theme_stylebox_override("hover", hover)

	# Pressed
	var pressed = normal.duplicate()
	pressed.bg_color = Color(accent.r * 0.25, accent.g * 0.25, accent.b * 0.25, 0.95)
	pressed.border_color = accent
	pressed.shadow_size = 2
	btn.add_theme_stylebox_override("pressed", pressed)

	# Focus (same as hover for keyboard nav)
	btn.add_theme_stylebox_override("focus", hover.duplicate())

static func create_primary_button(btn: Button, font_sz: int = 14, min_size: Vector2 = Vector2(180, 48)) -> void:
	"""Bright filled CTA button — for 'NEXT LEVEL', 'RUN SIMULATION', etc."""
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", font_sz)
	btn.add_theme_color_override("font_color", MIDNIGHT_DARKER)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	var accent = Color(0.0, 0.85, 0.85, 1.0)  # Cyan (non-HDR for bg)

	var normal = StyleBoxFlat.new()
	normal.bg_color = accent
	_apply_radius(normal, 8)
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	normal.content_margin_left = 20
	normal.content_margin_right = 20
	normal.shadow_color = Color(accent.r * 0.3, accent.g * 0.3, accent.b * 0.3, 0.5)
	normal.shadow_size = 8
	normal.shadow_offset = Vector2(0, 3)
	btn.add_theme_stylebox_override("normal", normal)

	var hover = normal.duplicate()
	hover.bg_color = accent.lightened(0.15)
	hover.shadow_size = 12
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = normal.duplicate()
	pressed.bg_color = accent.darkened(0.1)
	pressed.shadow_size = 3
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_stylebox_override("focus", hover.duplicate())

static func create_danger_button(btn: Button, font_sz: int = 13, min_size: Vector2 = Vector2(140, 40)) -> void:
	"""Red-tinted button for destructive actions (EXIT, RESET)."""
	var accent = Color(0.85, 0.2, 0.2, 1.0)
	create_premium_button(btn, accent, font_sz, min_size)
	btn.add_theme_color_override("font_color", Color(1.0, 0.7, 0.7, 1.0))

# ===================================================================
# CARD STYLES FOR LEVEL SELECT
# ===================================================================

static func create_level_card_style(chapter: int, is_unlocked: bool, stars: int) -> StyleBoxFlat:
	"""Level select card with chapter-colored accents and completion state."""
	var style = StyleBoxFlat.new()
	var ch = CHAPTER_COLORS.get(chapter, CHAPTER_COLORS[1])
	var accent: Color = ch["accent"]
	var tint: Color = ch["tint"]

	if is_unlocked:
		if stars >= 3:
			# Gold border for perfect score
			style.bg_color = Color(tint.r * 1.2, tint.g * 1.2, tint.b * 1.2, 0.85)
			style.border_color = Color(1.0, 0.8, 0.2, 0.7)
		elif stars > 0:
			# Accent border for completed
			style.bg_color = Color(tint.r, tint.g, tint.b, 0.75)
			style.border_color = Color(accent.r * 0.5, accent.g * 0.5, accent.b * 0.5, 0.5)
		else:
			# Subtle border for unlocked but not played
			style.bg_color = Color(0.06, 0.07, 0.10, 0.7)
			style.border_color = Color(accent.r * 0.25, accent.g * 0.25, accent.b * 0.25, 0.4)
	else:
		# Locked — very dim
		style.bg_color = Color(0.04, 0.04, 0.06, 0.5)
		style.border_color = Color(0.12, 0.12, 0.14, 0.3)

	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	_apply_radius(style, 10)
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func create_level_card_hover(chapter: int) -> StyleBoxFlat:
	"""Hover state for level card — brightened border + stronger shadow."""
	var ch = CHAPTER_COLORS.get(chapter, CHAPTER_COLORS[1])
	var accent: Color = ch["accent"]
	var tint: Color = ch["tint"]
	var style = StyleBoxFlat.new()
	style.bg_color = Color(tint.r * 1.5, tint.g * 1.5, tint.b * 1.5, 0.9)
	style.border_color = Color(accent.r * 0.7, accent.g * 0.7, accent.b * 0.7, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	_apply_radius(style, 10)
	style.shadow_color = Color(accent.r * 0.1, accent.g * 0.1, accent.b * 0.1, 0.5)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

# ===================================================================
# HELPER: CORNER RADIUS
# ===================================================================

static func _apply_radius(style: StyleBoxFlat, r: int) -> void:
	style.corner_radius_top_left = r
	style.corner_radius_top_right = r
	style.corner_radius_bottom_left = r
	style.corner_radius_bottom_right = r

# ===================================================================
# AURORA / GRADIENT BACKGROUND HELPERS
# ===================================================================

static func create_aurora_bg(parent: Control) -> ColorRect:
	"""Full-screen aurora gradient background. Returns the ColorRect."""
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.name = "AuroraBG"
	var shader_res = load("res://shaders/aurora_bg.gdshader")
	if shader_res:
		var mat = ShaderMaterial.new()
		mat.shader = shader_res
		bg.material = mat
	else:
		bg.color = MIDNIGHT_BG
	parent.add_child(bg)
	parent.move_child(bg, 0)
	return bg

# ===================================================================
# SEPARATOR / DIVIDER HELPERS
# ===================================================================

static func create_glow_divider(accent: Color = SIGNAL_ACTIVE, width: float = 200.0) -> ColorRect:
	"""Thin glowing horizontal line for visual separation."""
	var line = ColorRect.new()
	line.custom_minimum_size = Vector2(width, 2)
	line.color = Color(accent.r * 0.4, accent.g * 0.4, accent.b * 0.4, 0.6)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return line

# ===================================================================
# FONT STYLING
# ===================================================================

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