extends Node

static func evaluate_gate(type: String, inputs: Array[int]) -> int:
	match type:
		"AND":  return inputs[0] & inputs[1]
		"OR":   return inputs[0] | inputs[1]
		"NOT":  return 1 if inputs[0] == 0 else 0
		"XOR":  return inputs[0] ^ inputs[1]
		"NAND": return 1 - (inputs[0] & inputs[1])
		"NOR":  return 1 - (inputs[0] | inputs[1])
		"XNOR": return 1 - (inputs[0] ^ inputs[1])
		_:      return 0
