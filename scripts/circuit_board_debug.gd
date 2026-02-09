# Debug helper for circuit board visualization
extends Node2D
class_name CircuitBoardDebug

var parent_board: CircuitBoard

func _ready() -> void:
	parent_board = get_parent()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	"""Draw debug info about placed elements."""
	if not parent_board:
		return
	
	# Draw grid numbers at key positions
	var grid_color = Color(0.4, 0.4, 0.4, 0.2)
	var text_color = Color(0.5, 0.5, 0.5, 0.5)
	
	# Draw axis labels and grid reference points
	for x in range(-10, 20, 2):
		for y in range(-10, 20, 2):
			var world_pos = Vector2(x * CircuitBoard.GRID_SIZE, y * CircuitBoard.GRID_SIZE)
			draw_circle(world_pos, 2, grid_color)
