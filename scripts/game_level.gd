# Represents a single game level
extends RefCounted
class_name GameLevel

var name: String = ""
var description: String = ""
var input_nodes: Array[Dictionary] = []
var output_nodes: Array[Dictionary] = []
var allowed_gates: Array[String] = []
var max_gates: int = 10

func _init(p_name: String = "", p_desc: String = "") -> void:
	name = p_name
	description = p_desc
	input_nodes = []
	output_nodes = []
	allowed_gates = []
	max_gates = 10

func add_input(input_name: String, sequence: PackedInt32Array, position: Vector2i) -> void:
	input_nodes.append({
		"name": input_name,
		"sequence": sequence,
		"position": position
	})

func add_output(output_name: String, target: PackedInt32Array, position: Vector2i) -> void:
	output_nodes.append({
		"name": output_name,
		"target": target,
		"position": position
	})
