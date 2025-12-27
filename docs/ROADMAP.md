# Ski Free Or Die - Implementation Roadmap

> **For AI Agents:** This is the master task list. Work through phases in order. Each phase should result in a playable/testable state. Mark tasks complete as you finish them.

**Tech Stack:** LÖVE (Love2D) 11.4+ with Lua 5.1

---

## Phase Overview

| Phase | Name | Goal | Status |
|-------|------|------|--------|
| 0 | Project Setup | Love2D project structure, basic game loop | Complete |
| 1 | Core Movement | Playable skier with physics | Complete |
| 2 | World & Obstacles | Scrolling world, collision with obstacles | Complete |
| 3 | Procedural Generation | Tile-based map generation from seed | Complete |
| 4 | Game Loop | Timer, finish line, restart | Complete |
| 5 | Gates & Slalom | Gate system with penalties | Complete |
| 6 | HUD & Polish | UI, visual feedback, basic audio | Partial |
| 7 | Endless Mode | Infinite generation, Yeti chase | Complete |
| 8 | Advanced Features | Tricks, ramps, meta-progression | Not Started |

---

## Phase 0: Project Setup

**Goal:** Skeleton Love2D project that runs and shows a colored screen.

### Tasks

- [x] **0.1** Create Love2D project structure
  - `main.lua` with love.load/update/draw
  - Folder structure: `src/`, `assets/sprites/`, `assets/sounds/`, `lib/`
  - `conf.lua` with window settings (320x180 base, scaled up)

- [x] **0.2** Configure pixel-perfect rendering
  - Create render canvas at 320x180
  - Scale up to window size with nearest-neighbor filtering
  - Set up camera module for world offset

- [x] **0.3** Create color palette module
  - `src/colors.lua` with all 80s palette colors as Lua tables
  - Hot Pink, Electric Blue, Mint Green, etc.

- [x] **0.4** Create game state manager
  - Simple state machine: `menu`, `playing`, `paused`, `gameover`
  - `src/states/` folder with state files

**Verification:** Game window opens, shows sky blue background, can press ESC to quit.

**Reference:** `plans/phase-0-love2d-setup.md`

---

## Phase 1: Core Movement

**Goal:** Controllable skier that moves and turns. Tuck mechanic working.

### Tasks

- [x] **1.1** Create Skier entity
  - Position, velocity, angle
  - `src/entities/skier.lua`
  - Placeholder rectangle sprite (16x24, Electric Blue)

- [x] **1.2** Implement basic downhill movement
  - Constant downward velocity (skier moves down the slope)
  - World scrolls relative to skier (or skier moves in world coords)

- [x] **1.3** Implement turning controls
  - Left/Right arrow keys control angle
  - Direct control at low speed, momentum-based at high speed
  - Clamp angle to ±80 degrees

- [x] **1.4** Implement tuck mechanic
  - Down arrow or Shift to tuck
  - +12% speed boost while tucking
  - Reduced turn rate while tucking

- [x] **1.5** Camera follow system
  - Camera follows skier with offset (skier in lower portion of screen)
  - Smooth interpolation

**Verification:** Skier moves down screen, turns left/right, tucks for speed boost.

**Reference:** `plans/physics-tuck-mechanics-design.md`

---

## Phase 2: World & Obstacles

**Goal:** Procedural obstacles appear, collisions cause crashes/slowdowns.

### Tasks

- [x] **2.1** Create obstacle types
  - SmallTree, LargeTree, Rock, Cabin
  - Each with sprite placeholder, hitbox size, collision behavior
  - `src/entities/obstacle.lua`

- [x] **2.2** Create world manager
  - Spawns obstacles in world space
  - Removes obstacles that are far behind the camera
  - `src/world/world_manager.lua`

- [x] **2.3** Implement collision detection
  - Circle-circle or AABB collision
  - Skier has small forgiving hitbox
  - `src/systems/collision.lua`

- [x] **2.4** Implement collision responses
  - SmallTree: 20% speed penalty
  - LargeTree: 60% speed penalty + deflection
  - Rock/Cabin: Full crash (1.75s recovery)

- [x] **2.5** Crash & recovery state
  - Skier stops, plays crash animation (or just freezes)
  - After 1.75s, resumes skiing

**Verification:** Obstacles appear, hitting them causes appropriate slowdown or crash.

**Reference:** `plans/physics-tuck-mechanics-design.md` Section 3

---

## Phase 3: Procedural Generation

**Goal:** Tile-based procedural world from seed. Same seed = same obstacles.

### Tasks

- [x] **3.1** Create seeded random number generator
  - Lua-based deterministic RNG (not math.random)
  - `src/lib/seeded_random.lua`

- [x] **3.2** Create tile data structure
  - TileType enum: Warmup, Slalom, ObstacleField, Speed, Ramp
  - SlopeIntensity: Gentle, Moderate, Steep
  - Obstacle spawn list per tile
  - `src/world/tile_data.lua`

- [x] **3.3** Create tile generator
  - Generates list of TileData from seed
  - Difficulty progression over course
  - Pacing rules (no 2 hard tiles in a row)
  - `src/world/tile_generator.lua`

- [x] **3.4** Integrate tiles with world manager
  - Spawn obstacles based on tile definitions
  - Spawn/despawn tiles as camera moves
  - Apply slope multiplier to skier speed

- [x] **3.5** Create seed configuration
  - `config/seeds.lua` with weekly seed (moved to src/core/config.lua)
  - Load seed on game start

**Verification:** Different seeds produce different courses. Same seed is identical every time.

**Reference:** `plans/tile-system-design.md`

---

## Phase 4: Game Loop

**Goal:** Complete time trial run with timer and finish line.

### Tasks

- [x] **4.1** Create game timer
  - Counts up from 0
  - Displays as MM:SS.ms

- [x] **4.2** Create finish line
  - Trigger zone at end of course
  - Stops timer, shows final time
  - Integrated into world_manager.lua with checkered finish line

- [x] **4.3** Create game manager
  - Handles start/finish/restart
  - Tracks elapsed time
  - Integrated into play_state.lua and world_manager.lua

- [x] **4.4** Implement restart
  - Press R or Enter to restart
  - Resets position, timer, regenerates from same seed

**Verification:** Can ski from start to finish, see time, restart and try again.

---

## Phase 5: Gates & Slalom

**Goal:** Slalom gates with +3 second penalty for misses.

### Tasks

- [x] **5.1** Create gate entity
  - Two poles with trigger zone between
  - Visual states: Pending (pink), Passed (green), Missed (gray)
  - `src/entities/gate.lua`

- [x] **5.2** Create gate manager
  - Tracks all gates in order (integrated into world_manager)
  - Detects when player passes gate Y without triggering
  - Calculates total penalty

- [x] **5.3** Integrate gates into tile generation
  - Slalom tiles spawn 2-4 gates
  - Alternating left/right positions
  - Integrated via tile_generator.lua populate_tile()

- [x] **5.4** Add penalties to final time
  - Total Time = Elapsed + (Missed Gates * 3)
  - Show penalty breakdown on finish

**Verification:** Gates appear, passing through changes color, missing adds penalty.

**Reference:** `plans/gate-slalom-system.md`

---

## Phase 6: HUD & Polish

**Goal:** On-screen UI, basic visual/audio feedback.

### Tasks

- [x] **6.1** Create HUD overlay
  - Timer (top center)
  - Speed (top right)
  - Gates passed counter
  - (Integrated into play_state.lua)

- [x] **6.2** Create finish screen
  - Shows final time, penalties, gate stats
  - Press to restart

- [ ] **6.3** Add basic sound effects
  - Ski loop, crash, gate pass, gate miss
  - `assets/sounds/`

- [x] **6.4** Add screen shake on crash
  - Brief camera shake on rock/cabin collision

- [x] **6.5** Add basic particle effects (optional)
  - Snow spray on turns
  - `src/systems/particles.lua`

**Verification:** Clean HUD, audio feedback, feels polished.

---

## Phase 7: Endless Mode (Nice to Have)

**Goal:** Infinite course with Yeti chase mechanic.

### Tasks

- [x] **7.1** Add game mode selection
  - Menu to choose Time Trial or Endless

- [x] **7.2** Implement infinite tile generation
  - World manager generates obstacles on-demand
  - Difficulty caps but Yeti speeds up

- [x] **7.3** Create Yeti entity
  - Follows behind player at increasing speed
  - `src/entities/yeti.lua`

- [x] **7.4** Implement Yeti zones
  - Safe/Warning/Danger/Critical based on time distance
  - Visual effects (vignette, screen tint)

- [x] **7.5** Game over on catch
  - Yeti catches player = run ends
  - Show distance traveled as score

**Verification:** Can play endless mode, Yeti creates tension, eventually catches you.

**Reference:** `plans/yeti-mechanic-design.md`

---

## Phase 8: Advanced Features (Nice to Have)

**Goal:** Ramps, tricks, and polish.

### Tasks

- [ ] **8.1** Create ramp entity
  - Launches player into air

- [ ] **8.2** Implement air physics
  - No steering mid-air
  - Rotation controls (360s, flips)

- [ ] **8.3** Landing detection
  - Clean landing = speed boost
  - Bad angle = crash

- [ ] **8.4** Choice tiles
  - Split paths with different risk/reward

- [ ] **8.5** Set piece tiles
  - Handcrafted memorable sections

- [ ] **8.6** Flow multiplier system
  - Visual feedback for sustained clean play

---

## Implementation Notes for AI Agents

### Code Style

```lua
-- Use snake_case for functions and variables
-- Use PascalCase for modules/classes
-- Every file should be a module that returns a table

local Skier = {}

function Skier.new(x, y)
    local self = {
        x = x,
        y = y,
        speed = 0
    }
    return setmetatable(self, {__index = Skier})
end

function Skier:update(dt)
    -- implementation
end

return Skier
```

### Testing

- Love2D has no built-in test framework
- Create `test/` folder with simple assertion-based tests
- Run with `lua test/run_tests.lua` (pure Lua, no Love2D required for logic tests)

### File Organization

```
SkiFreeOrDie/
├── main.lua              # Entry point
├── conf.lua              # Love2D configuration
├── src/
│   ├── core/             # Game manager, state machine
│   ├── entities/         # Skier, obstacles, gates, yeti
│   ├── world/            # Tile generator, world manager
│   ├── systems/          # Collision, input, camera
│   ├── ui/               # HUD, menus
│   └── lib/              # Utilities (seeded random, etc.)
├── assets/
│   ├── sprites/
│   └── sounds/
├── config/
│   └── seeds.lua
└── test/
    └── run_tests.lua
```

### Key Differences from Unity

| Unity | Love2D |
|-------|--------|
| MonoBehaviour lifecycle | love.load/update/draw |
| Physics2D | Manual velocity/position updates |
| Prefabs | Factory functions (Entity.new()) |
| ScriptableObject | Lua tables |
| SerializeField | Config files or constructor params |
| Coroutines | State machines or timer callbacks |

### Performance Tips

- Use object pooling for obstacles (create once, reuse)
- SpriteBatch for drawing many similar sprites
- Keep hot path allocation-free

---

## Quick Start for New Session

1. Check current phase status in this file
2. Read the specific phase plan in `plans/`
3. Implement tasks in order, testing each
4. Mark tasks complete with [x] when done
5. Move to next phase when current is verified

**Current Phase:** 6 - HUD & Polish (remaining: sound effects)
