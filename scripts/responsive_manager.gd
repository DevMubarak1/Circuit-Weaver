# Responsive Manager — adapts UI layout for any screen size
# Autoload as: ResponsiveManager
#
# Detects device form factor from viewport size and emits signals
# so UI elements can adapt. Also provides helper scale factors.
extends Node

signal layout_changed(form_factor: String)

enum FormFactor { MOBILE_PORTRAIT, MOBILE_LANDSCAPE, TABLET, DESKTOP }

var current_form_factor: FormFactor = FormFactor.DESKTOP
var form_factor_name: String = "desktop"

# Scale multipliers other scripts can read
var ui_scale: float = 1.0          # For font sizes, margins, button heights
var port_hit_radius: float = 35.0  # Base port click distance
var grid_size_display: int = 40    # Visual grid cell size
var sidebar_width: float = 250.0
var is_touch_device: bool = false

# Thresholds (viewport width in pixels after stretch)
const MOBILE_PORTRAIT_MAX: float = 600.0
const MOBILE_LANDSCAPE_MAX: float = 900.0
const TABLET_MAX: float = 1100.0

var _last_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Detect touch capability
	is_touch_device = _detect_touch()
	get_tree().root.size_changed.connect(_on_viewport_resized)
	# Initial calculation after one frame
	await get_tree().process_frame
	_on_viewport_resized()

func _detect_touch() -> bool:
	# Godot's touch emulation settings + check OS
	var os_name: String = OS.get_name()
	return os_name in ["Android", "iOS", "Web"]

func _on_viewport_resized() -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	if vp_size == _last_size:
		return
	_last_size = vp_size

	var w: float = vp_size.x
	var h: float = vp_size.y
	var aspect: float = w / maxf(h, 1.0)

	if w <= MOBILE_PORTRAIT_MAX or (aspect < 1.0 and w < MOBILE_LANDSCAPE_MAX):
		current_form_factor = FormFactor.MOBILE_PORTRAIT
		form_factor_name = "mobile_portrait"
		ui_scale = clampf(w / 400.0, 0.6, 1.0)
		sidebar_width = clampf(w * 0.35, 120.0, 200.0)
		port_hit_radius = 50.0
	elif w <= MOBILE_LANDSCAPE_MAX:
		current_form_factor = FormFactor.MOBILE_LANDSCAPE
		form_factor_name = "mobile_landscape"
		ui_scale = clampf(w / 800.0, 0.7, 1.0)
		sidebar_width = clampf(w * 0.25, 150.0, 220.0)
		port_hit_radius = 45.0
	elif w <= TABLET_MAX:
		current_form_factor = FormFactor.TABLET
		form_factor_name = "tablet"
		ui_scale = clampf(w / 1100.0, 0.8, 1.1)
		sidebar_width = clampf(w * 0.22, 180.0, 250.0)
		port_hit_radius = 40.0
	else:
		current_form_factor = FormFactor.DESKTOP
		form_factor_name = "desktop"
		ui_scale = clampf(w / 1280.0, 0.9, 1.3)
		sidebar_width = clampf(w * 0.19, 220.0, 320.0)
		port_hit_radius = 35.0

	# Accessibility: larger touch targets on touch devices regardless of size
	if is_touch_device:
		port_hit_radius = maxf(port_hit_radius, 48.0)

	layout_changed.emit(form_factor_name)

# --- HELPERS FOR OTHER SCRIPTS ---

func get_font_size(base_size: int) -> int:
	return int(float(base_size) * ui_scale)

func get_margin(base_margin: int) -> int:
	return int(float(base_margin) * ui_scale)

func get_button_height(base_height: float = 42.0) -> float:
	return base_height * ui_scale

func is_mobile() -> bool:
	return current_form_factor == FormFactor.MOBILE_PORTRAIT or current_form_factor == FormFactor.MOBILE_LANDSCAPE

func get_camera_zoom() -> Vector2:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	# Available screen area for the board (right of sidebar, with padding)
	var avail_w: float = vp.x - sidebar_width - 60.0
	# Use ~60% of screen height for circuit; bottom 40% for tutorial panel
	var avail_h: float = vp.y * 0.6

	# Board content world size (generous padding for gate sprites & labels)
	var content_w: float = 750.0  # inputs col 1 to outputs col 15 + node visuals
	var content_h: float = 300.0  # rows 1-5 + gate visual heights

	var zx: float = avail_w / content_w
	var zy: float = avail_h / content_h
	var z: float = minf(zx, zy)
	z = clampf(z, 0.5, 1.6)
	return Vector2(z, z)

func get_camera_center() -> Vector2:
	var z: float = get_camera_zoom().x

	# Board content center in world coordinates
	# Inputs at col 1 → world x=440, outputs at col 15 → world x=1000
	# Rows 1-5 → world y=40..200, typical center y=120
	var content_cx: float = 720.0
	var content_cy: float = 130.0

	# The sidebar covers sidebar_width screen pixels on the left.
	# Camera position maps to screen center (vp.x/2, vp.y/2).
	# The non-sidebar area center is at screen_x = (vp.x + sidebar_width) / 2.
	# For content_cx to appear at that screen position:
	#   screen_x = (content_cx - cam_x) * z + vp.x / 2
	#   (vp.x + sidebar_width) / 2 = (content_cx - cam_x) * z + vp.x / 2
	#   sidebar_width / 2 = (content_cx - cam_x) * z
	#   cam_x = content_cx - sidebar_width / (2 * z)
	var cam_x: float = content_cx - sidebar_width / (2.0 * z)

	# Vertically, center content in the top ~60% of the screen (above tutorial).
	# Available area for content: top 0 to vp.y - 200 (leaving 200px for tutorial).
	# Center of that area: (vp.y - 200) / 2 in screen coords.
	#   (vp.y - 200) / 2 = (content_cy - cam_y) * z + vp.y / 2
	#   cam_y = content_cy + (vp.y / 2 - (vp.y - 200) / 2) / z
	#   cam_y = content_cy + 100 / z
	var cam_y: float = content_cy + 100.0 / z

	return Vector2(cam_x, cam_y)
