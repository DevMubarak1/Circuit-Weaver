# Manages screen transitions between levels/chapters
# Add as autoload: TransitionManager
extends CanvasLayer
class_name TransitionManager

var _overlay: ColorRect
var _shader_mat: ShaderMaterial
var _is_transitioning: bool = false

signal transition_midpoint  # Fired at full coverage — swap scenes here
signal transition_finished

func _ready() -> void:
	layer = 100  # Always on top
	_overlay = ColorRect.new()
	_overlay.name = "TransitionOverlay"
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false

	var shader_res = load("res://shaders/glitch_transition.gdshader")
	if shader_res:
		_shader_mat = ShaderMaterial.new()
		_shader_mat.shader = shader_res
		_shader_mat.set_shader_parameter("progress", 0.0)
		_overlay.material = _shader_mat

	add_child(_overlay)

func transition_to_scene(scene_path: String, is_chapter_change: bool = false) -> void:
	if _is_transitioning:
		return
	if not ResourceLoader.exists(scene_path):
		push_error("TransitionMgr: Scene not found: %s" % scene_path)
		return
	_is_transitioning = true

	var duration: float = 0.6 if is_chapter_change else 0.35
	var block: float = 12.0 if is_chapter_change else 24.0
	var glitch: float = 0.6 if is_chapter_change else 0.3

	if _shader_mat:
		_shader_mat.set_shader_parameter("block_size", block)
		_shader_mat.set_shader_parameter("glitch_intensity", glitch)
		_shader_mat.set_shader_parameter("progress", 0.0)

	_overlay.visible = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # Block input during transition

	# Phase 1: Cover screen
	var tween_in = create_tween()
	tween_in.tween_method(_set_progress, 0.0, 1.0, duration)
	await tween_in.finished

	transition_midpoint.emit()

	# Swap scene
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame

	# Phase 2: Reveal new scene
	var tween_out = create_tween()
	tween_out.tween_method(_set_progress, 1.0, 0.0, duration)
	await tween_out.finished

	_overlay.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false
	transition_finished.emit()

func _set_progress(value: float) -> void:
	if _shader_mat:
		_shader_mat.set_shader_parameter("progress", value)

func is_transitioning() -> bool:
	return _is_transitioning
