# Circuit Weaver

A digital logic puzzle game built with Godot 4.5. You learn how computers actually work — by building circuits with real logic gates.

No theory dumps. No boring lectures. Just you, a circuit board, and 20 levels that teach you everything from a simple NOT inverter to multi-gate combinational logic.

---

## What Is This

Circuit Weaver is an educational game where each level gives you a target output, a set of logic gates, and a blank canvas. Wire the gates together, run the simulation, and see if your circuit produces the right signals.

The game covers all 7 fundamental logic gates: NOT, AND, OR, XOR, NAND, NOR, and XNOR. By level 20, you're designing multi-input, multi-output circuits from scratch.

## How to Play

1. Read the objective — it tells you the logic formula you need to build
2. Drag gates from the toolbox onto the circuit board
3. Wire inputs to gates, gates to gates, and gates to outputs
4. Hit RUN SIMULATION and watch your signals propagate
5. Get it right and earn up to 3 stars based on gate efficiency

## Structure

- **Chapter 1** (Levels 1-5) — NOT and AND gates. The fundamentals.
- **Chapter 2** (Levels 6-13) — OR, XOR, NAND, NOR, XNOR. Combinational logic.
- **Chapter 3** (Levels 14-17) — Multi-gate circuits. Real problem solving.
- **Chapter 4** (Levels 18-20) — Final exam. Everything combined.

Each chapter unlocks after completing the previous chapter's final level.

## Tech Stack

- **Engine**: Godot 4.5 (GDScript)
- **Renderer**: Forward+
- **Resolution**: 1280x720, scales to any aspect ratio
- **Platforms**: Windows, Linux, macOS, Web (planned)

## Project Structure

```text
project.godot          — engine config and autoloads
scripts/               — all game logic (GDScript)
  Global.gd            — save/load, progression, user state
  level_config.gd      — all 20 level definitions
  level_manager.gd     — level controller, tutorial, simulation
  circuit_board.gd     — gate placement, wiring, signal propagation
  logic_gate.gd        — gate evaluation (AND, OR, NOT, etc.)
  theme_manager.gd     — Midnight Architect color palette
  anim_helper.gd       — animations, transitions, effects
scenes/                — Godot scene files (.tscn)
assets/                — gate SVG icons, background art
shaders/               — circuit background, wire pulse, glitch transition
```

## Running It

1. Install [Godot 4.5+](https://godotengine.org/download)
2. Clone this repo
3. Open `project.godot` in Godot
4. Press F5

## Learning

Check out [learn.md](learn.md) for a plain-language walkthrough of every logic gate and what each chapter teaches you. No emojis, no fluff — just the concepts explained like a person would explain them.

## License

Educational project. Built for learning.
