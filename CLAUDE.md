# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ski Free Or Die! is an 80s-themed downhill skiing game combining SkiFree-style physics with California Games aesthetics.

## Quick Start for AI Agents

1. **Read `docs/ROADMAP.md` first** - Master task list with phased implementation
2. Check current phase status
3. Execute tasks in order from the current phase
4. Mark tasks complete in ROADMAP.md as you finish them

## Documentation Structure

```
docs/
├── ROADMAP.md                    # MASTER TASK LIST - Start here!
├── game-design.md                # Vision, aesthetics, game modes
└── plans/
    ├── phase-0-love2d-setup.md   # Project setup (Love2D specific)
    ├── physics-tuck-mechanics-design.md  # Movement physics (engine-agnostic)
    ├── tile-system-design.md     # Procedural generation (engine-agnostic)
    ├── gate-slalom-system.md     # Gate mechanics (engine-agnostic)
    └── yeti-mechanic-design.md   # Endless mode chase (engine-agnostic)
```

## Tech Stack

**Frontend:** LÖVE (Love2D) 11.4+ with Lua 5.1
- Lightweight 2D game framework
- Perfect for retro pixel art games
- Cross-platform (Windows, Mac, Linux)

**Backend (Phase 2):** Go (Golang)
- Weekly seed distribution
- Leaderboard validation

## Running the Game

```bash
cd SkiFreeOrDie
love .
```

## Testing

Run unit tests using the `--test` flag:
```bash
love . --test
```

## Code Structure

```
SkiFreeOrDie/
├── main.lua              # Entry point (love.load/update/draw)
├── conf.lua              # Love2D configuration
├── src/
│   ├── core/             # Game manager, state machine
│   ├── entities/         # Skier, obstacles, gates, yeti
│   ├── world/            # Tile generator, world manager
│   ├── systems/          # Collision, input, camera
│   ├── ui/               # HUD, menus
│   └── lib/              # Utilities (seeded random, colors, etc.)
├── assets/
│   ├── sprites/
│   └── sounds/
└── config/
    └── seeds.lua
```

## Code Style

```lua
-- Use snake_case for functions and variables
-- Use PascalCase for modules/classes
-- Every file is a module that returns a table

local Skier = {}

function Skier.new(x, y)
    local self = {x = x, y = y}
    return setmetatable(self, {__index = Skier})
end

function Skier:update(dt)
    -- implementation
end

return Skier
```

## Game Modes

**Weekly Time Trial:** Deterministic maps from weekly seed, slalom gates with +3 second penalty for misses, pure skill-based competition

**Endless Descent:** Progressive difficulty, Yeti "closing wall" mechanic that creates constant tension

## Key Systems

- **Procedural Generation:** Tile-based map generation from seeds (deterministic)
- **Tuck Mechanic:** Hold down/shift for +12% speed, reduced turn control
- **Hybrid Turning:** Direct control at low speed, momentum-based at high speed
- **Collision Hierarchy:** Small trees (slow), large trees (big slow + deflect), rocks/cabins (crash)
- **Gates:** Pass through for clean time, miss for +3 second penalty

## Color Palette

The "80s Windbreaker" palette (defined in `src/colors.lua`):
- Hot Pink (#FF1493)
- Electric Blue (#00FFFF)
- Bright Yellow (#FFD700)
- Mint Green (#00FF7F)
- Snow White (#FFFAFA)

## Display Settings

- Native resolution: 360x480 (3:4 portrait ratio for vertical skiing view)
- Scaled up 3x to 1080x1440 window (fits 1440p monitors perfectly)
- Pixel-perfect rendering with nearest-neighbor filtering
- Side letterboxing on 16:9 displays (can be used for UI)
