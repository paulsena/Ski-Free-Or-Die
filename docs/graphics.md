# Graphics System

All graphics are procedural pixel art using Love2D drawing primitives. No sprite files.

## Color Palette

**File:** `src/colors.lua`

### Primary Colors
| Name | Hex | Usage |
|------|-----|-------|
| HOT_PINK | #FF1493 | Skier jacket, missed gates |
| ELECTRIC_BLUE | #00FFFF | Skis, goggles, windows |
| BRIGHT_YELLOW | #FFD700 | Helmet, cabin doors |
| MINT_GREEN | #00FF7F | Passed gates, tree highlights |
| SNOW_WHITE | #FFFAFA | Snow effects, snow caps |
| BLACK | #000000 | Outlines |

### Secondary Colors
| Name | Hex | Usage |
|------|-----|-------|
| DEEP_PURPLE | #9400D3 | UI accents |
| SUNSET_ORANGE | #FF4500 | UI accents |
| SKY_BLUE | #87CEEB | Background |
| PINE_GREEN | #228B22 | Tree foliage |
| ROCK_GRAY | #696969 | Rocks, chimneys |
| CABIN_BROWN | #8B4513 | Trunks, cabin walls |
| DARK_PINE | - | Tree shadows |
| DARK_BROWN | - | Wood shadows |

### Helper Functions
- `Colors.set(color)` - Sets Love2D color
- `Colors.dim(color, factor)` - Darken color
- `Colors.bright(color, factor)` - Brighten color

## Drawing Functions

### Skier (`src/entities/skier.lua`)
- `Skier:draw()` - Main draw dispatcher (line 256)
- `Skier:draw_normal()` - Front view, 5 angles (line 349)
- `Skier:draw_side_view(direction)` - Stop positions (line 290)
- `Skier:draw_crashed()` - Crash state (line 406)

### Obstacles (`src/entities/obstacle.lua`)
- `Obstacle:draw()` - Dispatcher (line 158)
- `Obstacle:draw_small_tree()` - (line 182)
- `Obstacle:draw_large_tree()` - (line 215)
- `Obstacle:draw_rock()` - (line 259)
- `Obstacle:draw_cabin()` - (line 293)
- `Obstacle:draw_snow_mound()` - (line 353)

## Particle System

**File:** `src/systems/particles.lua`

### Particle Types
| Type | Color | Gravity | Usage |
|------|-------|---------|-------|
| snow_spray | SNOW_WHITE | 30 | Ski trail during movement |
| impact_snow | SNOW | 50 | Obstacle collision |
| crash_debris | SNOW_WHITE | 80 | Crash impact |
| gate_sparkle | MINT_GREEN | -20 | Gate pass (floats up) |

### Emit Functions
- `Particles:emit(x, y, type, count, dir_min, dir_max)` - Generic emitter
- `Particles:emit_snow_spray(x, y, angle, speed, is_turning)` - Ski spray
- `Particles:emit_crash(x, y)` - Crash effect
- `Particles:emit_gate_pass(x, y, passed)` - Gate feedback (green=pass, pink=miss)

Particles use non-seeded RNG (cosmetic only, no gameplay impact).

## Common Tasks

**Add new color:**
- Add to `src/colors.lua` in the appropriate section (lines 6-37)
- Primary colors: lines 6-12, Secondary: lines 14-24, UI: lines 26-28

**Add new particle type:**
1. Add type config to `TYPES` table in `src/systems/particles.lua` (lines 18-51)
2. Create emit helper function if needed (see `emit_crash` at line 133 for example)

**Add new obstacle type:**
1. Add type definition to `Obstacle.TYPES` in `src/entities/obstacle.lua` (lines 10-46)
2. Add type name to `TYPE_ORDER` array (line 49)
3. Add draw case to `Obstacle:draw()` dispatcher (line 167)
4. Create `draw_<type>()` function (see `draw_rock` at line 259 for example)

**Modify skier appearance:**
- Normal skiing angles: `Skier:draw_normal()` in `src/entities/skier.lua` (line 349)
- Stopped/side view: `Skier:draw_side_view()` (line 290)
- Crash animation: `Skier:draw_crashed()` (line 406)

**Change gate colors:**
- Modify gate state colors in `src/colors.lua` (lines 30-33)
