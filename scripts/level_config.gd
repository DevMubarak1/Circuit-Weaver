# Level progression data for all Circuit Weaver levels
extends RefCounted
class_name LevelConfig

# ──────────────────────────────────────────────────────────────
# Each level is a Dictionary with:
#   id            : int           – 1-based level number
#   chapter       : int           – chapter grouping (1-5)
#   title         : String        – display name
#   description   : String        – one-line objective text
#   formula       : String        – logic formula shown in UI
#   tutorial_steps: Array[Dict]   – bot tutorial messages (step-by-step)
#   allowed_gates : Array[String] – gates available in toolbox
#   max_gates     : int           – gate limit for 3-star rating
#   inputs        : Array[Dict]   – {name, sequence, col, row}
#   outputs       : Array[Dict]   – {name, target, col, row}
#   min_wires     : int           – expected wire count for tutorial auto-advance
# ──────────────────────────────────────────────────────────────

static func get_total_levels() -> int:
	return ALL_LEVELS.size()

static func get_level(level_id: int) -> Dictionary:
	if level_id > 0 and level_id <= ALL_LEVELS.size():
		return ALL_LEVELS[level_id - 1]
	return {}

static func get_chapter_levels(chapter: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for lvl in ALL_LEVELS:
		if lvl["chapter"] == chapter:
			result.append(lvl)
	return result

const ALL_LEVELS: Array[Dictionary] = [
	# --- CHAPTER 1: NOT & AND (Levels 1-5) ---

	# Level 1: The Spark — NOT gate introduction
	{
		"id": 1,
		"chapter": 1,
		"title": "THE SPARK",
		"description": "Invert the signal using a NOT gate.",
		"formula": "Y = NOT A",
		"allowed_gates": ["NOT"],
		"max_gates": 1,
		"min_wires": 2,
		"inputs": [
			{"name": "A", "sequence": [1], "col": 1, "row": 3}
		],
		"outputs": [
			{"name": "Output", "target": [0], "col": 15, "row": 3}
		],
		"tutorial_steps": [
			{"title": "WELCOME", "msg": "Welcome, Architect %s!\nIn this level you will learn how a NOT Gate works — it flips a signal, turning 1 into 0 and 0 into 1."},
			{"title": "IDENTIFY", "msg": "Your goal is to place a NOT Gate and wire it up.\nLocate the NOT Gate in the toolbox on the left."},
			{"title": "PLACEMENT", "msg": "Drag the NOT Gate from the toolbox and drop it onto the circuit board."},
			{"title": "WIRING", "msg": "Connect the circuit:\nDraw a wire from Input A to the gate's input, then from the gate's output to the Output."},
			{"title": "SIMULATE", "msg": "Your circuit is wired! Click RUN SIMULATION to verify the NOT Gate inverts the signal."},
			{"title": "COMPLETE", "msg": "ARCHITECT AUTHENTICATED.\nYou've proven the NOT Gate inverts every signal. LEVEL 1 COMPLETE!"}
		]
	},

	# Level 2: The AND Junction
	{
		"id": 2,
		"chapter": 1,
		"title": "THE AND JUNCTION",
		"description": "Both inputs must be 1 for output to be 1.",
		"formula": "Y = A AND B",
		"allowed_gates": ["AND"],
		"max_gates": 1,
		"min_wires": 3,
		"inputs": [
			{"name": "A", "sequence": [1], "col": 1, "row": 2},
			{"name": "B", "sequence": [0], "col": 1, "row": 4}
		],
		"outputs": [
			{"name": "Output", "target": [0], "col": 15, "row": 3}
		],
		"tutorial_steps": [
			{"title": "MISSION", "msg": "Architect %s, your mission: Y = A AND B.\nThe AND Gate outputs 1 only when BOTH inputs are 1. You've got this!"},
			{"title": "GOOD LUCK", "msg": "You learned the basics in Level 1 — now apply them!\nPlace gates, wire them up, and hit RUN SIMULATION. Good luck, Architect!"}
		]
	},

	# Level 3: The Filter — NOT + AND chaining
	{
		"id": 3,
		"chapter": 1,
		"title": "THE FILTER",
		"description": "Chain NOT and AND to compute (NOT A) AND B.",
		"formula": "Y = (NOT A) AND B",
		"allowed_gates": ["NOT", "AND"],
		"max_gates": 2,
		"min_wires": 4,
		"inputs": [
			{"name": "A", "sequence": [1], "col": 1, "row": 2},
			{"name": "B", "sequence": [1], "col": 1, "row": 4}
		],
		"outputs": [
			{"name": "Output", "target": [0], "col": 15, "row": 3}
		],
		"tutorial_steps": [
			{"title": "MISSION", "msg": "Architect %s, your mission: Y = (NOT A) AND B.\nYou'll need 2 gates — a NOT and an AND. Chain them together!"},
			{"title": "GOOD LUCK", "msg": "Remember: invert first, then combine.\nPlace your gates, wire them up, and hit RUN SIMULATION. Good luck, Architect!"}
		]
	},

	# Level 4: Double Inversion — prove NOT NOT A = A
	{
		"id": 4,
		"chapter": 1,
		"title": "DOUBLE INVERSION",
		"description": "Prove that inverting twice returns the original signal.",
		"formula": "Y = NOT (NOT A)",
		"allowed_gates": ["NOT"],
		"max_gates": 2,
		"min_wires": 3,
		"inputs": [
			{"name": "A", "sequence": [1], "col": 1, "row": 3}
		],
		"outputs": [
			{"name": "Output", "target": [1], "col": 15, "row": 3}
		],
		"tutorial_steps": [
			{"title": "MISSION", "msg": "Architect %s, your mission: Y = NOT(NOT A).\nYou'll need 2 NOT gates in series — prove that double inversion returns the original signal!"},
			{"title": "GOOD LUCK", "msg": "Two negations cancel out. Chain the gates and see for yourself.\nGood luck, Architect!"}
		]
	},

	# Level 5: The Gate Keeper — AND with both inputs high
	{
		"id": 5,
		"chapter": 1,
		"title": "THE GATE KEEPER",
		"description": "Only when all signals align does the gate open.",
		"formula": "Y = A AND B",
		"allowed_gates": ["AND", "NOT"],
		"max_gates": 1,
		"min_wires": 3,
		"inputs": [
			{"name": "A", "sequence": [1], "col": 1, "row": 2},
			{"name": "B", "sequence": [1], "col": 1, "row": 4}
		],
		"outputs": [
			{"name": "Output", "target": [1], "col": 15, "row": 3}
		],
		"tutorial_steps": [
			{"title": "MISSION", "msg": "Architect %s, the Gate Keeper demands: Y = A AND B.\nBoth inputs are 1 — only when all signals align does the gate open."},
			{"title": "GOOD LUCK", "msg": "You've mastered NOT and AND — put it all together!\nGood luck, Architect. Chapter 1 finale!"}
		]
	},

	# --- CHAPTER 2: OR & XOR (Levels 6-13) ---

	# Level 6: The OR Gateway
	{
		"id": 6,
		"chapter": 2,
		"title": "THE OR GATEWAY",
		"description": "Either input being 1 activates the output.",
		"formula": "Y = A OR B",
		"allowed_gates": ["OR"],
		"max_gates": 1,
		"min_wires": 3,
		"inputs": [
			{"name": "A", "sequence": [1], "col": 1, "row": 2},
			{"name": "B", "sequence": [0], "col": 1, "row": 4}
		],
		"outputs": [
			{"name": "Output", "target": [1], "col": 15, "row": 3}
		],
		"tutorial_steps": [
			{"title": "WELCOME", "msg": "Architect %s, welcome to Chapter 2!\nThe OR gate outputs 1 if ANY input is 1."},
			{"title": "IDENTIFY", "msg": "A=1, B=0. The OR gate should output 1 since at least one input is high."},
			{"title": "PLACEMENT", "msg": "Drag the OR gate onto the board."},
			{"title": "WIRING", "msg": "Wire both inputs to the OR gate, then OR output to Output."},
			{"title": "SIMULATE", "msg": "1 OR 0 = 1. At least one input is true!"},
			{"title": "COMPLETE", "msg": "OR gate mastered! Disjunction — either or both inputs activate the output."}
		]
	},

	# Level 7: The Selector — OR with NOT
	{
		"id": 7,
		"chapter": 2,
		"title": "THE SELECTOR",
		"description": "Combine NOT and OR to select the right signal.",
		"formula": "Y = (NOT A) OR B",
		"allowed_gates": ["NOT", "OR"],
		"max_gates": 2,
		"min_wires": 4,
		"inputs": [
			{"name": "A", "sequence": [1], "col": 1, "row": 2},
			{"name": "B", "sequence": [0], "col": 1, "row": 4}
		],
		"outputs": [
			{"name": "Output", "target": [0], "col": 15, "row": 3}
		],
		"tutorial_steps": [
			{"title": "MISSION", "msg": "Architect %s, your mission: Y = (NOT A) OR B.\nYou'll need 2 gates — a NOT and an OR. Invert first, then combine!"},
			{"title": "GOOD LUCK", "msg": "You learned OR in Level 6 — now combine it with NOT.\nGood luck, Architect!"}
		]
	},

	# Level 8: The Merger — multi-gate chain
	{
		"id": 8,
		"chapter": 2,
		"title": "THE MERGER",
		"description": "Merge signals with AND and OR together.",
		"formula": "Y = (A AND B) OR C",
		"allowed_gates": ["AND", "OR"],
		"max_gates": 2,
		"min_wires": 5,
		"inputs": [
			{"name": "A", "sequence": [1], "col": 1, "row": 1},
			{"name": "B", "sequence": [0], "col": 1, "row": 3},
			{"name": "C", "sequence": [1], "col": 1, "row": 5}
		],
		"outputs": [
			{"name": "Output", "target": [1], "col": 15, "row": 3}
		],
		"tutorial_steps": [
			{"title": "MISSION", "msg": "Architect %s, your mission: Y = (A AND B) OR C.\nThree inputs! You'll need 2 gates — an AND and an OR."},
			{"title": "GOOD LUCK", "msg": "AND the first two inputs, then OR with the third.\nGood luck, Architect!"}
		]
	},

	# Level 9: The Comparator — detect equal inputs
	{
		"id": 9,
		"chapter": 2,
		"title": "THE COMPARATOR",
		"description": "Detect when two inputs are equal.",
		"formula": "Y = (A AND B) OR (NOT A AND NOT B)",
		"allowed_gates": ["AND", "OR", "NOT"],
		"max_gates": 5,
		"min_wires": 8,
		"inputs": [
			{"name": "A", "sequence": [1], "col": 1, "row": 2},
			{"name": "B", "sequence": [1], "col": 1, "row": 4}
		],
		"outputs": [
			{"name": "Output", "target": [1], "col": 15, "row": 3}
		],
		"tutorial_steps": [
			{"title": "MISSION", "msg": "Architect %s, your mission: build an equality detector!\nY = (A AND B) OR (NOT A AND NOT B).\nYou'll need 5 gates: 2 NOTs, 2 ANDs, and 1 OR."},
			{"title": "GOOD LUCK", "msg": "Output 1 when both inputs match. Two comparison paths combined with OR.\nGood luck, Architect!"}
		]
	},

	# Level 10: The XOR Exclusive
	{
		"id": 10,
		"chapter": 2,
		"title": "THE XOR EXCLUSIVE",
		"description": "Output 1 only when inputs differ.",
		"formula": "Y = A XOR B",
		"allowed_gates": ["XOR"],
		"max_gates": 1,
		"min_wires": 3,
		"inputs": [
			{"name": "A", "sequence": [1], "col": 1, "row": 2},
			{"name": "B", "sequence": [1], "col": 1, "row": 4}
		],
		"outputs": [
			{"name": "Output", "target": [0], "col": 15, "row": 3}
		],
		"tutorial_steps": [
			{"title": "MISSION", "msg": "Architect %s, meet the XOR gate!\nY = A XOR B — it outputs 1 ONLY when inputs are different."},
			{"title": "GOOD LUCK", "msg": "A=1, B=1 — same inputs, so XOR should output 0.\nGood luck, Architect!"}
		]
	},

	# Level 11: The Half Adder — two outputs!
	{
		"id": 11,
		"chapter": 2,
		"title": "THE HALF ADDER",
		"description": "Build a 1-bit adder: Sum and Carry outputs.",
		"formula": "Sum = A XOR B, Carry = A AND B",
		"allowed_gates": ["XOR", "AND"],
		"max_gates": 2,
		"min_wires": 5,
		"inputs": [
			{"name": "A", "sequence": [1], "col": 1, "row": 2},
			{"name": "B", "sequence": [1], "col": 1, "row": 4}
		],
		"outputs": [
			{"name": "Sum", "target": [0], "col": 15, "row": 2},
			{"name": "Carry", "target": [1], "col": 15, "row": 4}
		],
		"tutorial_steps": [
			{"title": "MISSION", "msg": "Architect %s, build a half adder!\nSum = A XOR B, Carry = A AND B.\nYou'll need 2 gates — a XOR and an AND."},
			{"title": "GOOD LUCK", "msg": "Two outputs this time: Sum and Carry. 1+1 = 10 in binary!\nGood luck, Architect!"}
		]
	},

	# Level 12: Difference Engine — XOR chain
	{
		"id": 12,
		"chapter": 2,
		"title": "DIFFERENCE ENGINE",
		"description": "Chain XOR gates to compute 3-input parity.",
		"formula": "Y = A XOR B XOR C",
		"allowed_gates": ["XOR"],
		"max_gates": 2,
		"min_wires": 5,
		"inputs": [
			{"name": "A", "sequence": [1], "col": 1, "row": 1},
			{"name": "B", "sequence": [0], "col": 1, "row": 3},
			{"name": "C", "sequence": [1], "col": 1, "row": 5}
		],
		"outputs": [
			{"name": "Output", "target": [0], "col": 15, "row": 3}
		],
		"tutorial_steps": [
			{"title": "MISSION", "msg": "Architect %s, your mission: Y = A XOR B XOR C.\nYou'll need 2 XOR gates chained in series for 3-input parity."},
			{"title": "GOOD LUCK", "msg": "First XOR combines A and B, second XOR adds C.\nGood luck, Architect!"}
		]
	},

	# Level 13: The Multiplexer
	{
		"id": 13,
		"chapter": 2,
		"title": "THE MULTIPLEXER",
		"description": "Select between two inputs using a control signal.",
		"formula": "Y = (A AND NOT S) OR (B AND S)",
		"allowed_gates": ["AND", "OR", "NOT"],
		"max_gates": 4,
		"min_wires": 7,
		"inputs": [
			{"name": "A", "sequence": [1], "col": 1, "row": 1},
			{"name": "B", "sequence": [0], "col": 1, "row": 3},
			{"name": "S", "sequence": [0], "col": 1, "row": 5}
		],
		"outputs": [
			{"name": "Output", "target": [1], "col": 15, "row": 3}
		],
		"tutorial_steps": [
			{"title": "MISSION", "msg": "Architect %s, build a multiplexer!\nY = (A AND NOT S) OR (B AND S).\nYou'll need 4 gates: 1 NOT, 2 ANDs, and 1 OR."},
			{"title": "GOOD LUCK", "msg": "S=0 selects A, S=1 selects B. This is how CPUs route data!\nGood luck, Architect!"}
		]
	},

	# --- CHAPTER 3: NAND & NOR (Levels 14-17) ---

	# Level 14: The NAND Revelation
	{
		"id": 14,
		"chapter": 3,
		"title": "NAND REVELATION",
		"description": "Discover NAND — the inverted AND gate.",
		"formula": "Y = A NAND B",
		"allowed_gates": ["NAND"],
		"max_gates": 1,
		"min_wires": 3,
		"inputs": [
			{"name": "A", "sequence": [1], "col": 1, "row": 2},
			{"name": "B", "sequence": [1], "col": 1, "row": 4}
		],
		"outputs": [
			{"name": "Output", "target": [0], "col": 15, "row": 3}
		],
		"tutorial_steps": [
			{"title": "WELCOME", "msg": "Architect %s, welcome to Chapter 3!\nNAND is NOT-AND: it inverts the AND result."},
			{"title": "IDENTIFY", "msg": "NAND outputs 0 only when both inputs are 1. Otherwise it outputs 1."},
			{"title": "PLACEMENT", "msg": "Place the NAND gate between the two inputs."},
			{"title": "WIRING", "msg": "Wire A and B to NAND, then NAND output to Output."},
			{"title": "SIMULATE", "msg": "1 NAND 1 = 0 (inverted AND)."},
			{"title": "COMPLETE", "msg": "NAND discovered! It's a 'universal gate' — you can build ANY logic from NANDs alone."}
		]
	},

	# Level 15: NAND as NOT
	{
		"id": 15,
		"chapter": 3,
		"title": "NAND AS NOT",
		"description": "Build a NOT gate using only NAND gates.",
		"formula": "Y = A NAND A = NOT A",
		"allowed_gates": ["NAND"],
		"max_gates": 1,
		"min_wires": 2,
		"inputs": [
			{"name": "A", "sequence": [1], "col": 1, "row": 3}
		],
		"outputs": [
			{"name": "Output", "target": [0], "col": 15, "row": 3}
		],
		"tutorial_steps": [
			{"title": "MISSION", "msg": "Architect %s, prove NAND's universality!\nY = A NAND A = NOT A. Connect both inputs of a NAND to the same signal."},
			{"title": "GOOD LUCK", "msg": "One NAND gate, one trick — wire the same input to both sides.\nGood luck, Architect!"}
		]
	},

	# Level 16: The NOR Revelation
	{
		"id": 16,
		"chapter": 3,
		"title": "NOR REVELATION",
		"description": "Discover NOR — the inverted OR gate.",
		"formula": "Y = A NOR B",
		"allowed_gates": ["NOR"],
		"max_gates": 1,
		"min_wires": 3,
		"inputs": [
			{"name": "A", "sequence": [0], "col": 1, "row": 2},
			{"name": "B", "sequence": [0], "col": 1, "row": 4}
		],
		"outputs": [
			{"name": "Output", "target": [1], "col": 15, "row": 3}
		],
		"tutorial_steps": [
			{"title": "MISSION", "msg": "Architect %s, meet NOR — the universal complement!\nY = A NOR B. NOR is NOT-OR: it outputs 1 only when BOTH inputs are 0."},
			{"title": "GOOD LUCK", "msg": "Like NAND, NOR is a universal gate. Wire it up and prove it!\nGood luck, Architect!"}
		]
	},

	# Level 17: Building OR from NOR
	{
		"id": 17,
		"chapter": 3,
		"title": "OR FROM NOR",
		"description": "Build an OR gate using only NOR gates.",
		"formula": "Y = (A NOR B) NOR (A NOR B)",
		"allowed_gates": ["NOR"],
		"max_gates": 2,
		"min_wires": 4,
		"inputs": [
			{"name": "A", "sequence": [1], "col": 1, "row": 2},
			{"name": "B", "sequence": [0], "col": 1, "row": 4}
		],
		"outputs": [
			{"name": "Output", "target": [1], "col": 15, "row": 3}
		],
		"tutorial_steps": [
			{"title": "MISSION", "msg": "Architect %s, prove NOR's universality by building OR!\nY = (A NOR B) NOR (A NOR B). You'll need 2 NOR gates chained."},
			{"title": "GOOD LUCK", "msg": "NOR then NOR again (both inputs tied) = OR.\nGood luck, Architect! Chapter 3 finale!"}
		]
	},

	# --- CHAPTER 4: ADVANCED & FINAL EXAM (Levels 18-20) ---

	# Level 18: The XNOR Identity
	{
		"id": 18,
		"chapter": 4,
		"title": "XNOR IDENTITY",
		"description": "XNOR — output 1 when inputs are the same.",
		"formula": "Y = A XNOR B",
		"allowed_gates": ["XNOR"],
		"max_gates": 1,
		"min_wires": 3,
		"inputs": [
			{"name": "A", "sequence": [1], "col": 1, "row": 2},
			{"name": "B", "sequence": [1], "col": 1, "row": 4}
		],
		"outputs": [
			{"name": "Output", "target": [1], "col": 15, "row": 3}
		],
		"tutorial_steps": [
			{"title": "WELCOME", "msg": "Architect %s, welcome to Chapter 4!\nXNOR outputs 1 when inputs are the SAME."},
			{"title": "IDENTIFY", "msg": "A=1, B=1 → same inputs → XNOR outputs 1."},
			{"title": "PLACEMENT", "msg": "Place the XNOR gate."},
			{"title": "WIRING", "msg": "Wire both inputs to XNOR, then to Output."},
			{"title": "SIMULATE", "msg": "1 XNOR 1 = 1. Inputs match!"},
			{"title": "COMPLETE", "msg": "XNOR mastered! The equality gate — perfect for bit comparison."}
		]
	},

	# Level 19: The Grand Circuit
	{
		"id": 19,
		"chapter": 4,
		"title": "THE GRAND CIRCUIT",
		"description": "Use any gates to compute a complex expression.",
		"formula": "Y = (A AND B) OR (NOT C)",
		"allowed_gates": ["AND", "OR", "NOT", "XOR", "NAND", "NOR", "XNOR"],
		"max_gates": 3,
		"min_wires": 6,
		"inputs": [
			{"name": "A", "sequence": [1], "col": 1, "row": 1},
			{"name": "B", "sequence": [1], "col": 1, "row": 3},
			{"name": "C", "sequence": [1], "col": 1, "row": 5}
		],
		"outputs": [
			{"name": "Output", "target": [1], "col": 15, "row": 3}
		],
		"tutorial_steps": [
			{"title": "MISSION", "msg": "Architect %s, the Grand Circuit awaits!\nY = (A AND B) OR (NOT C). All gates are at your disposal.\nYou'll need 3 gates: AND, NOT, and OR."},
			{"title": "GOOD LUCK", "msg": "Three inputs, three gates — combine everything you've learned!\nGood luck, Architect!"}
		]
	},

	# Level 20: The Architect's Final Exam
	{
		"id": 20,
		"chapter": 4,
		"title": "ARCHITECT'S FINAL EXAM",
		"description": "Build a 2-input equality comparator from basic gates only.",
		"formula": "Y = (A AND B) OR (NOT A AND NOT B)",
		"allowed_gates": ["AND", "OR", "NOT"],
		"max_gates": 5,
		"min_wires": 8,
		"inputs": [
			{"name": "A", "sequence": [0], "col": 1, "row": 2},
			{"name": "B", "sequence": [0], "col": 1, "row": 4}
		],
		"outputs": [
			{"name": "Output", "target": [1], "col": 15, "row": 3}
		],
		"tutorial_steps": [
			{"title": "FINAL EXAM", "msg": "Architect %s, this is your FINAL EXAM!\nY = (A AND B) OR (NOT A AND NOT B).\nYou'll need 5 gates: 2 NOTs, 2 ANDs, and 1 OR. No XOR or XNOR allowed!"},
			{"title": "GOOD LUCK", "msg": "Build an equality comparator from basic gates only. Prove everything you've learned!\nGood luck, Architect — make us proud!"}
		]
	},
]
