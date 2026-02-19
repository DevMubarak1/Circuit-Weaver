# What You'll Actually Learn Playing Circuit Weaver

This isn't a textbook. It's a puzzle game. But by the time you finish all 20 levels, you'll understand how computers think at the lowest level — the logic gates that make everything work.

Here's what each chapter teaches you, explained like a human would explain it.

---

## Chapter 1: The Basics (Levels 1-5)

You start with two gates: NOT and AND.

**NOT** is the simplest gate in existence. It flips a signal. Give it a 1, it gives you 0. Give it 0, you get 1. That's it. One input, one output, total inversion. Every computer on the planet uses billions of these.

**AND** is your first two-input gate. It only outputs 1 when both inputs are 1. Think of it like two switches in a row — both have to be on for the light to turn on. Input A is 1 and input B is 1? Output is 1. Anything else? Output is 0.

By level 5, you're chaining these together. NOT into AND, multiple ANDs feeding each other. You're already building real circuits.

---

## Chapter 2: Expanding the Toolkit (Levels 6-13)

Now it gets interesting. You pick up OR, XOR, NAND, NOR, and XNOR.

**OR** outputs 1 if either input is 1. Both on? Still 1. Both off? That's the only time you get 0. Think of it like two switches in parallel — either one can turn on the light.

**XOR** (exclusive OR) is the oddball. It outputs 1 only when the inputs are different. A is 1 and B is 0? Output is 1. Both the same? Output is 0. This is the gate behind every addition operation in your CPU.

**NAND** is just NOT-AND. Take an AND gate, flip its output. Here's the wild part: you can build every other gate using only NAND gates. Entire computers have been built from nothing but NAND. The levels will push you to discover this yourself.

**NOR** is NOT-OR. Same deal — it's universal too. Any logic function can be built from just NOR gates.

**XNOR** checks if inputs are the same. It's the opposite of XOR. Both 1? Output 1. Both 0? Output 1. Different? Output 0. Basically an equality checker.

This chapter has the most levels because combinational logic is where you really learn to think. Don't rush it.

---

## Chapter 3: Building Real Things (Levels 14-17)

By now you know every gate. This chapter asks you to combine them into circuits that actually do something. Multi-gate chains, multiple inputs, multiple outputs. The puzzles get harder, but you have every tool you need.

You'll start seeing patterns — how certain gate combinations always produce specific truth table results. That's not memorization, that's understanding. It's the same thing an electrical engineer does when designing a chip.

---

## Chapter 4: The Final Exam (Levels 18-20)

No more hand-holding. You get a target output, a set of gates, and you figure it out. These levels combine everything from the first three chapters. If you can solve level 20, you genuinely understand digital logic.

---

## The Truth Tables

Every gate has a truth table. It shows every possible input combination and the corresponding output. Here they all are.

### NOT

| A | Y |
|---|---|
| 0 | 1 |
| 1 | 0 |

### AND

| A | B | Y |
|---|---|---|
| 0 | 0 | 0 |
| 0 | 1 | 0 |
| 1 | 0 | 0 |
| 1 | 1 | 1 |

### OR

| A | B | Y |
|---|---|---|
| 0 | 0 | 0 |
| 0 | 1 | 1 |
| 1 | 0 | 1 |
| 1 | 1 | 1 |

### XOR

| A | B | Y |
|---|---|---|
| 0 | 0 | 0 |
| 0 | 1 | 1 |
| 1 | 0 | 1 |
| 1 | 1 | 0 |

### NAND

| A | B | Y |
|---|---|---|
| 0 | 0 | 1 |
| 0 | 1 | 1 |
| 1 | 0 | 1 |
| 1 | 1 | 0 |

### NOR

| A | B | Y |
|---|---|---|
| 0 | 0 | 1 |
| 0 | 1 | 0 |
| 1 | 0 | 0 |
| 1 | 1 | 0 |

### XNOR

| A | B | Y |
|---|---|---|
| 0 | 0 | 1 |
| 0 | 1 | 0 |
| 1 | 0 | 0 |
| 1 | 1 | 1 |

---

## Why This Matters

Everything digital — your phone, your laptop, game consoles, traffic lights, satellites — is built on exactly these gates. There's nothing else at the bottom. Just 0s and 1s flowing through AND, OR, NOT, and their friends.

When you play Circuit Weaver, you're not just solving puzzles. You're learning the language that hardware speaks. And once you see it, you can't unsee it.

---

## Tips If You're Stuck

- Read the formula. `Y = A AND B` tells you exactly what gate to use and how to wire it.
- Start from the output. Look at what the target expects, then work backwards to figure out which gates produce that result.
- Count your wires. Every input port on a gate needs a wire. Every output needs to go somewhere. Missing a connection is the most common mistake.
- Don't overthink it. The early levels are supposed to be simple. If your solution feels complicated, there's probably a simpler path.
- Run the simulation even if you think it's wrong. Watching signals flow teaches you more than staring at the board.
