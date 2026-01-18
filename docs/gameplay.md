# Gameplay Mechanics Reference

Quick reference for Claude Code agents. File paths and key values.

## Skier Physics (`src/entities/skier.lua`)

### Constants
```lua
BASE_SPEED = 140           -- pixels/sec
MAX_SPEED = 320            -- pixels/sec
TUCK_SPEED_BONUS = 0.30    -- +30% when tucking
CRASH_DURATION = 1.0       -- seconds
IMMUNITY_DURATION = 1.0    -- seconds post-crash
HITBOX_RADIUS = 8          -- collision radius
DEFLECT_VX_FACTOR = 0.8    -- velocity reversal factor
```

### Positions (discrete, not continuous)
| Index | Name        | Angle | Speed Mult | Notes           |
|-------|-------------|-------|------------|-----------------|
| 1     | FULL_LEFT   | -90   | 0          | Stop (sideways) |
| 2     | FAR_LEFT    | -60   | 1.0        | Sharp turn      |
| 3     | LEFT        | -30   | 1.0        | Gentle turn     |
| 4     | CENTER      | 0     | 1.0        | Straight down   |
| 5     | RIGHT       | 30    | 1.0        | Gentle turn     |
| 6     | FAR_RIGHT   | 60    | 1.0        | Sharp turn      |
| 7     | FULL_RIGHT  | 90    | 0          | Stop (sideways) |

### Key Functions
- `Skier.new(x, y)` - constructor
- `Skier:handle_input(dt, skier_screen_x)` - mouse/keyboard input
- `Skier:update(dt, slope_bounds)` - physics tick
- `Skier:crash()` - trigger crash state
- `Skier:slow_down(factor)` - multiply speed by factor
- `Skier:deflect()` - reverse X velocity, move position toward center

## Obstacles (`src/entities/obstacle.lua`)

### Collision Hierarchy
| Type       | Collision  | Speed Penalty | Spawn Weight |
|------------|------------|---------------|--------------|
| small_tree | slow       | 0.8 (20% loss)| 35           |
| large_tree | deflect    | 0.4 (60% loss)| 25           |
| rock       | crash      | 0 (full stop) | 20           |
| cabin      | crash      | 0 (full stop) | 10           |
| snow_mound | slow       | 0.9 (10% loss)| 10           |

### Key Functions
- `Obstacle.new(x, y, type)` - non-seeded constructor
- `Obstacle.new_seeded(x, y, type, rng)` - deterministic constructor
- `Obstacle:check_collision(skier_hitbox)` - circle vs rect collision

## Gates (`src/entities/gate.lua`)

### Constants
```lua
WIDTH = 75                 -- default gate width (pixels)
PENALTY = 3                -- seconds added for miss
```

### States
- `pending` - not yet crossed
- `passed` - crossed within gate width
- `missed` - crossed outside gate width

### Key Functions
- `Gate.new(x, y, width, direction)` - constructor
- `Gate:check_pass(skier_x, skier_y, prev_y)` - returns "passed", "missed", or nil
- `Gate.create_slalom_sequence(start_y, count, spacing, slope_width)` - batch create

## Yeti - Endless Mode (`src/entities/yeti.lua`)

### Constants
```lua
BASE_SPEED = 70            -- slightly slower than skier
SPEED_INCREASE_RATE = 0.01 -- speed increase per second
CATCH_DISTANCE = 30        -- game over distance
START_DISTANCE = -300      -- initial distance behind player
BOOST_ON_CRASH = 1.5       -- speed multiplier when player crashes
```

### Danger Zones (distance behind player)
| Zone     | Distance | Effect          |
|----------|----------|-----------------|
| safe     | > 500    | No overlay      |
| warning  | 350-500  | Orange vignette |
| danger   | 150-350  | Red vignette    |
| critical | < 150    | Pulsing red     |

### Key Functions
- `Yeti.new()` - constructor
- `Yeti:update(dt, skier_speed, is_skier_crashed)` - returns true if caught
- `Yeti:get_danger_zone()` - returns zone string

## Collision System (`src/systems/collision.lua`)

### Response Logic
```lua
Collision.resolve_obstacle_collision(skier, obstacle, camera)
```
- `slow`: `skier:slow_down(penalty)` only
- `deflect`: `slow_down` + `skier:deflect()` + camera shake (2px, 0.2s)
- `crash`: `skier:crash()` + camera shake (4px, 0.4s)

### Key Functions
- `Collision.circle_rect(cx, cy, radius, rx, ry, rw, rh)` - hit test
- `Collision.check_skier_obstacles(skier, obstacles)` - returns first collision
- `Collision.check_skier_gates(skier, prev_y, gates)` - returns passed, missed counts

## Common Tasks

**Add new obstacle type:**
1. Add entry to `TYPES` table in `src/entities/obstacle.lua:10-46`
2. Add type name to `TYPE_ORDER` array at line 49
3. Add `draw_X()` function (see `draw_rock()` at line 259 for example)
4. Call your draw function in `:draw()` at line 167-177

**Change crash recovery time:**
- Edit `CRASH_DURATION` in `src/entities/skier.lua:34`

**Adjust skier speed/physics:**
- `BASE_SPEED`, `MAX_SPEED`, `TUCK_SPEED_BONUS` in `src/entities/skier.lua:31-33`

**Add new color to palette:**
- Add to `src/colors.lua` (see lines 7-24 for examples)
- Use with `Colors.set(Colors.YOUR_COLOR)`

**Change gate penalty time:**
- Edit `PENALTY` in `src/entities/gate.lua:11`
