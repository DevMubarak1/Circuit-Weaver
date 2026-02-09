# Circuit Weaver - Development Guide

## Architecture Overview

### Signal Flow

```
Input Nodes -> Gates -> Wire Propagation -> Output Nodes
     ↓           ↓            ↓                  ↓
  (emit)     (compute)    (propagate)      (validate)
```

1. **Input Nodes** emit their current value through connected wires
2. **Gates** receive inputs and compute outputs based on their logic type
3. **Wires** transmit signals between gates
4. **Output Nodes** receive signals and check correctness

### Key Classes & Their Relationships

```
LogicGate (extends Node2D)
├─ input_slots: Array[int]
├─ output_value: int
└─ Methods: evaluate(), compute_output(), add_input()

Wire (extends Node2D)
├─ from_port, to_port
├─ from_gate, to_gate
└─ Methods: connect_ports(), propagate signal

InputNode (extends Node2D)
├─ signal_sequence: PackedInt32Array
├─ connected_wires: Array[Wire]
└─ Methods: propagate_to_wires()

OutputNode (extends Node2D)
├─ target_sequence: PackedInt32Array
├─ received_sequence: PackedInt32Array
└─ Methods: receive_input(), check_correctness()

CircuitBoard (extends Node2D)
├─ gates: Dictionary
├─ wires: Array[Wire]
├─ input_nodes, output_nodes: Arrays
└─ Methods: place_gate(), start_wiring(), start_simulation()

GameManager (extends Node2D)
├─ levels: Array[Level]
├─ circuit_board: CircuitBoard
└─ Methods: load_level(), start_simulation(), next_level()
```

## Adding New Gate Types

To add a new logic gate type:

1. Add the gate name to `AVAILABLE_GATES` in `gate_toolbox.gd`
2. Add a compute function in `logic_gate.gd`:
   ```gdscript
   func compute_my_gate() -> int:
       # Your logic here
       return result
   ```
3. Add a case in the `compute_output()` match statement
4. (Optional) Add color in `get_gate_color()` in `circuit_board.gd`

## Creating Custom Levels

Add new levels in `game_manager.gd` setup_levels():

```gdscript
var my_level = Level.new("Level Name", "Description")
my_level.input_nodes.append({
    "name": "A",
    "sequence": PackedInt32Array([1, 0, 1, 0]),
    "position": Vector2i(2, 5)
})
my_level.output_nodes.append({
    "name": "Output",
    "target": PackedInt32Array([0, 1, 0, 1]),
    "position": Vector2i(15, 5)
})
my_level.allowed_gates = ["NOT", "AND"]
my_level.max_gates = 3
levels.append(my_level)
```

## Implementing Proper Visuals

### Creating Gate Sprites

For each gate type, create a `gate_template.tscn` file with:

```
Node2D (LogicGate)
├── Sprite2D (gate body with icon)
├── Area2D (for mouse detection)
├── Node2D (InputPorts container)
│   ├── Area2D (input_port_1)
│   └── Area2D (input_port_2)
└── Node2D (OutputPort)
    └── Area2D (output_port)
```

The Area2D nodes should have `highlight()` and `dehighlight()` methods for visual feedback.

### Wire Shader

Create a shader for animated/glowing wires:

```glsl
shader_type canvas_item;

uniform float glow_strength : hint_range(0.0, 2.0) = 1.0;
uniform float animation_speed : hint_range(0.0, 5.0) = 1.0;

void fragment() {
    COLOR = texture(TEXTURE, UV);
    COLOR.a *= glow_strength;
    
    // Add glow based on flow
    if (COLOR.a > 0.1) {
        COLOR.rgb *= 1.0 + sin(TIME * animation_speed) * 0.3;
    }
}
```

## Extending the Simulation Engine

### Adding Timing/Sequence Support

Currently, sequences advance through manual calls. To auto-advance:

```gdscript
# In CircuitBoard._process()
var simulation_speed = 0.5  # seconds per tick
var time_accumulator = 0.0

func _process(delta: float) -> void:
    if is_simulating:
        time_accumulator += delta
        if time_accumulator >= simulation_speed:
            advance_simulation_tick()
            time_accumulator = 0.0

func advance_simulation_tick() -> void:
    for input_node in input_nodes:
        input_node.advance_sequence()
    for output_node in output_nodes:
        output_node.advance_sequence()
```

### Multi-Output Validation

Modify `OutputNode.check_correctness()` to allow multiple outputs validating together:

```gdscript
# In CircuitBoard
func check_all_outputs_correct() -> bool:
    for output in output_nodes:
        if not output.is_correct:
            return false
    return true
```

## Performance Considerations

1. **Large Circuits**: Cache gate computation results to avoid redundant calculations
2. **Many Wires**: Use object pooling for wire updates
3. **UI Updates**: Batch visual updates at frame rate rather than continuous

## Testing Checklist

- [ ] Each gate type computes correctly
- [ ] Signals properly propagate through multiple gates
- [ ] Output validation correctly identifies matches/mismatches
- [ ] Level progression works smoothly
- [ ] UI responds to all user inputs
- [ ] No memory leaks with gate/wire creation/deletion

## Common Issues & Solutions

### Issue: Signals not propagating
**Solution**: Ensure `output_changed.emit()` is called and wires are properly connected

### Issue: Gates computing wrong values
**Solution**: Verify the compute function matches the boolean logic truth table

### Issue: UI buttons not responding
**Solution**: Check signal connections in the scene and ensure callback functions exist

### Issue: Level doesn't complete
**Solution**: Debug by printing `output_node.received_sequence` vs `target_sequence`
