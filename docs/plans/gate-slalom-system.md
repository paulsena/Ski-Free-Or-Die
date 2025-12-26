# Gate & Slalom System Design

**Date:** 2025-12-23
**Status:** Validated
**Engine:** Love2D (Lua) - Engine-agnostic design

> **For AI Agents:** This document defines gate *mechanics and behavior*. Implementation in `src/entities/gate.lua` and `src/systems/gate_manager.lua`.

---

## Overview

Gates are slalom markers that players must ski between. Missing a gate adds a +3 second time penalty. Gates provide the precision challenge that makes Time Trial mode competitive.

---

## Gate States

| State | Visual | Trigger |
|-------|--------|---------|
| Pending | Hot Pink | Gate not yet reached |
| Passed | Mint Green | Player passed through trigger zone |
| Missed | Rock Gray | Player passed gate Y position without triggering |

---

## Gate Structure

Each gate consists of:
- **Left Pole** - Sprite at x - width/2
- **Right Pole** - Sprite at x + width/2
- **Trigger Zone** - Invisible hitbox between poles

```
  [Left Pole]     [Trigger Zone]     [Right Pole]
       |<------------ width ----------->|
```

### Gate Dimensions

| Difficulty | Width (pixels) | Notes |
|------------|----------------|-------|
| Easy | 64 | Wide, forgiving |
| Medium | 48 | Standard |
| Hard | 40 | Tight, requires precision |

---

## Detection Logic

### Passing Through (Success)

Player's collision circle overlaps the trigger zone:
```
if player_y > gate_y - trigger_height/2 and
   player_y < gate_y + trigger_height/2 and
   player_x > gate_x - gate_width/2 and
   player_x < gate_x + gate_width/2 then
    mark_passed()
end
```

### Missing (Failure)

Player's Y position passes the gate without triggering:
```
if player_y > gate_y + buffer_distance and gate_state == PENDING then
    mark_missed()
end
```

Buffer distance (~20 pixels) prevents edge-case detection issues.

---

## Gate Manager

Tracks all gates in sequence:

```lua
GateManager = {
    gates = {},           -- List of gate data
    next_gate_index = 1,  -- Index of next expected gate

    total_penalty = 0,
    gates_passed = 0,
    gates_missed = 0
}
```

### Key Methods

| Method | Purpose |
|--------|---------|
| `register_gate(x, y, width)` | Add gate to tracking list |
| `update(player_y)` | Check for missed gates based on position |
| `notify_passed(gate_index)` | Mark gate as passed |
| `get_total_penalty()` | Sum of all missed gate penalties (count * 3) |

---

## Time Penalty

| Gates Missed | Penalty |
|--------------|---------|
| 0 | 0 seconds |
| 1 | 3 seconds |
| 2 | 6 seconds |
| 5 | 15 seconds |

**Final Time = Elapsed Time + Total Penalty**

This means a clean run with slightly slower skiing often beats a fast run with missed gates.

---

## Visual Feedback

### On Pass
- Gate poles change from Hot Pink to Mint Green
- Brief flash/glow effect (optional)
- Success sound plays

### On Miss
- Gate poles change to Rock Gray
- "+3" text floats up briefly
- Failure sound plays
- Penalty counter in HUD updates

---

## Gate Placement in Tiles

Slalom tiles contain 2-4 gates arranged in alternating left-right pattern:

```
|                     |
|        [Gate 1]     |  (right side)
|                     |
|  [Gate 2]           |  (left side)
|                     |
|        [Gate 3]     |  (right side)
|                     |
```

### Generation Rules

1. First gate: Random left or right
2. Subsequent gates: Alternate sides
3. Add small random X offset for variety
4. Y spacing: Evenly distributed within tile

```lua
-- Pseudocode for gate generation
for i = 1, gate_count do
    local side = (i % 2 == 0) and 0.35 or 0.65  -- Alternate
    local x_offset = random(-0.1, 0.1)
    local x = clamp(side + x_offset, 0.2, 0.8)
    local y = i / (gate_count + 1)  -- Even spacing

    spawn_gate(x * tile_width, y * tile_height)
end
```

---

## Integration with Game Systems

### Timer
```lua
function get_final_time()
    return elapsed_time + gate_manager.get_total_penalty()
end
```

### HUD Display
- Show gates passed: "GATES: 5/7"
- Show penalty if any: "+6s" in red

### Finish Screen
```
FINISH!
01:23.45

Gates: 5/7
Penalty: +6s
Final: 01:29.45
```

---

## Implementation Files

```
src/
├── entities/
│   └── gate.lua           # Gate entity (poles, trigger zone, state)
├── systems/
│   └── gate_manager.lua   # Tracks all gates, calculates penalties
└── world/
    └── tile_generator.lua # Spawns gates in slalom tiles
```
