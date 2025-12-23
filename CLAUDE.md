# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ski Free Or Die! is an 80s-themed downhill skiing game combining SkiFree-style physics with California Games aesthetics. The project uses a client-server architecture.

## Documentation

- `docs/game-design.md` - Core vision, aesthetics, and game mode definitions
- `docs/plans/` - Implementation plans with detailed technical specs
  - `unity-project-config.md` - Unity settings, sprite specs, color palette (reference first)
  - `core-game-implementation.md` - Main implementation tasks
  - `gate-slalom-system.md` - Gates, penalties, and slalom scoring
  - `physics-tuck-mechanics-design.md` - Movement and collision systems
  - `tile-system-design.md` - Procedural generation and tile types
  - `yeti-mechanic-design.md` - Endless mode chase mechanic

## Architecture

**Frontend (Unity/C#):**
- Physics-based skiing movement with "slippery" SkiFree-inspired controls
- Pixel-perfect 80s aesthetic rendering (hot pink, electric blue, bright yellow, mint green, white)
- Momentum system with "Flow Multiplier" affecting visuals and audio intensity

**Backend (Go):**
- Weekly seed distribution for deterministic procedural generation (all players get identical maps)
- Leaderboard validation and score security
- JSON API for seed data

## Game Modes

**Weekly Time Trial:** Deterministic maps from weekly seed, slalom gates with +3 second penalty for misses, pure skill-based competition

**Endless Descent:** Progressive difficulty, upgrade gates for power-ups, Yeti "closing wall" mechanic, meta-progression with "Neon Shards" currency

## Key Systems

- **Procedural Generation:** Tile-based map generation from seeds
- **Trick System:** Ramps enable rotations (360s, backflips) for speed boosts
- **Tuck Mechanic:** Crouching for speed vs standing for turning
- **Hazards:** Trees, rocks, cabins (static); slush, ramps, control-inverting "Glitch" zones (dynamic)
