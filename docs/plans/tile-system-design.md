# Tile System Design

**Date:** 2025-12-23
**Status:** Validated
**Engine:** Love2D (Lua) - Engine-agnostic design

> **For AI Agents:** This document defines tile *types and generation rules*. Implementation in `src/world/tile_generator.lua` and `src/world/tile_data.lua`.

---

## Overview

This document defines the procedural tile system for Ski Free Or Die!'s map generation. The goal is a hybrid system that balances retro homage (SkiFree, California Games, Skate or Die) with modern game design for competitive fairness and player agency.

---

## Section 1: Core Architecture

### Approach: Hybrid System

- **Set piece tiles** create memorable, handcrafted moments that feel intentional (like NES-era level design)
- **Rule-based tiles** add variety so courses aren't purely memorization
- **Deterministic from seed** means the Weekly Time Trial generates identically for all players

### Tile Dimensions

Each tile represents a vertical "chunk" of the slope—roughly 3-5 seconds of skiing at moderate speed. Wide enough to allow meaningful left/right positioning. Think of them as screens in an NES game scrolling vertically.

### Tile Properties

Every tile carries metadata:

| Property | Description |
|----------|-------------|
| Slope intensity | Gentle / Moderate / Steep (from physics design) |
| Difficulty rating | 1-5 scale for sequencing logic |
| Category | What type of challenge it presents |
| Entry/exit width | Ensures tiles connect cleanly (no spawning into a tree) |

### The Retro Feel

SkiFree and Skate or Die felt endless but had rhythm. California Games had structure. We blend both: structured pacing with enough randomization that runs feel fresh, but the seed means everyone faces the same "fresh."

---

## Section 2: Tile Categories

### 1. Warmup Tiles

**Purpose:** Ease players in, establish rhythm.

- Gentle slope, sparse obstacles
- Wide gates (if any) to teach slalom basics
- 1-2 of these at course start only

*Retro homage:* SkiFree's opening seconds before chaos.

### 2. Slalom Tiles

**Purpose:** Precision challenges. The "meat" of Time Trial mode.

| Variant | Gates | Slope | Obstacles |
|---------|-------|-------|-----------|
| Easy | Wide spacing, forgiving angles | Gentle | None between gates |
| Medium | Moderate spacing | Moderate | Occasional tree near gate |
| Hard | Tight spacing, sharp angles | Steep | Obstacles force committed lines |

*Retro homage:* Ski event from Winter Games. Clean gates, pure racing.

### 3. Obstacle Field Tiles

**Purpose:** Navigation challenges. Read and react.

| Variant | Contents |
|---------|----------|
| Forest Run | Mix of small and large trees. Clip small ones, dodge large. |
| Rock Garden | Scattered rocks. Full crash on contact—high stakes. |
| Mixed Hazard | Trees, rocks, and cabins. Maximum chaos. |

*Retro homage:* SkiFree's random tree chaos. The "oh no oh no" feeling.

### 4. Speed Tiles

**Purpose:** Reward after technical sections. Tuck and fly.

- Steep slope, minimal obstacles
- Wide open space to build momentum
- Often precedes a decision point (ramp, hard section)
- The "relief" beat in the pacing

*Retro homage:* Downhill events where you just GO.

### 5. Ramp Tiles

**Purpose:** Risk/reward trick opportunities.

| Variant | Setup |
|---------|-------|
| Single Ramp | One ramp, take it or go around. Simple decision. |
| Ramp Alley | Multiple ramps in sequence. Commit to air or weave through. |
| Gap Jump | Ramp over hazard. Must jump to avoid crash. Rare, memorable. |

*Retro homage:* California Games half-pipe energy. Skate or Die jump sections.

*Modern addition:* Optional ramps let players choose their style. Purists skip them, trick hunters hit them all.

### 6. Choice Tiles

**Purpose:** Branching paths with risk/reward. Modern depth.

- Left path: Safe, slower, more gates
- Right path: Risky, faster, obstacles or gaps

Both paths rejoin at tile exit. Creates "optimal line" meta for competitive players without punishing casual players who take the safe route.

*Modern addition:* This is pure modern game design. Gives players agency within the deterministic seed.

### 7. Set Piece Tiles

**Purpose:** Handcrafted memorable moments. Signature challenges.

| Name | Description |
|------|-------------|
| Cabin Chicane | Tight weave between 3-4 cabins. Requires precise control. |
| The Gauntlet | Dense obstacle field with ONE clean line. Rewards course knowledge. |
| Ski Lift Alley | Poles and cables to dodge. SkiFree homage. |
| Spectator Row | Crowd sprites on sidelines, cheering. No obstacles—just vibes and speed. California Games energy. |

These appear at fixed seed-determined points. Players learn to anticipate them. Creates "moments" to discuss ("I always choke at the Cabin Chicane").

---

## Section 3: Pacing & Sequencing

### Difficulty Curve

**Weekly Time Trial (fixed length):**

| Progress | Phase | Tile Types |
|----------|-------|------------|
| 0-25% | Warmup | Warmup + Easy tiles. Build confidence. |
| 25-50% | Rising | Easy/Medium mix. Introduce challenge. |
| 50-75% | Challenge | Medium/Hard mix. Test skills. |
| 75-100% | Climax | Hard tiles + Set Pieces. The crucible. |

**Endless Descent:**

- Difficulty increases continuously
- No ceiling—eventually becomes impossible
- Yeti pacing accelerates to match

### Pacing Rules (The Rhythm)

| Rule | Why |
|------|-----|
| Never two Hard tiles back-to-back | Prevents frustration. Players need recovery. |
| Speed tile after every 2-3 technical tiles | Release valve. Let them breathe and build momentum. |
| Set Pieces spaced evenly | Memorable moments shouldn't cluster. |
| Ramp tiles are optional paths, not blockers | Except rare Gap Jumps. Tricks stay optional. |
| Choice tiles appear in middle difficulty | Early = confusing. Late = overwhelming. Middle = strategic. |

### Tile Transitions

**Entry/Exit Matching:**

- Each tile defines "safe zones" at top and bottom edges
- Generator ensures obstacles don't spawn in transition zones
- Prevents "spawned into a tree" unfairness

**Slope Continuity:**

- Gentle to Moderate to Steep transitions feel natural
- Jumping from Gentle directly to Steep creates intentional "drop" moments
- Never Steep to Gentle (would feel like hitting a wall)

### Retro Pacing Inspiration

- **SkiFree:** Constant chaos, no real structure. We add structure.
- **California Games:** Events had clear phases (warmup, performance, finale). We borrow this arc.
- **Skate or Die / Winter Games:** Difficulty ramped predictably. Players could feel progress. We replicate that satisfaction.

---

## Section 4: Seed & Generation

### Weekly Seed System

**Phase 1 (Local):**

1. Seeds stored in a local JSON file (e.g., `seeds.json`)
2. Game reads current week's seed on launch
3. Client's procedural generator uses seed to produce identical tile sequence
4. Manual seed updates weekly (or player-shared)

**Phase 2 (API - Deferred):**

1. Go backend generates a weekly seed (simple integer or hash)
2. Seed is distributed to all clients via API
3. Automatic weekly rotation
4. Leaderboard validation and score security

**Determinism requirements:**

- Same seed produces same tile order
- Same seed produces same obstacle positions within tiles
- Same seed produces same set piece placements
- Cross-platform consistency (Unity's seeded random, not system random)

### Generation Algorithm

```
1. Initialize RNG with weekly seed
2. Set difficulty = 0
3. For each tile slot:
   a. Increase difficulty based on position %
   b. Filter tile pool by difficulty rating
   c. Apply pacing rules (no two hard tiles, etc.)
   d. Randomly select from valid tiles
   e. Populate tile with obstacles using RNG
   f. Advance to next slot
4. Insert set pieces at predetermined intervals
```

**Rule-based tiles:** The tile defines constraints (tree density range, gate count range), RNG fills in exact positions within those constraints.

**Set piece tiles:** Fixed layouts, no RNG. Identical every time they appear.

### Course Length

**Weekly Time Trial:**

- Fixed length: ~60-90 seconds at optimal pace
- Approximately 15-25 tiles depending on difficulty mix
- Clear finish line with timing

**Endless Descent:**

- No fixed length
- Difficulty keeps escalating
- Ends when player crashes fatally or Yeti catches them

### Retro Reference

- **SkiFree:** Purely random, no seed. Every run different.
- **NES games:** Fixed levels, memorization rewarded.
- **Our hybrid:** Seeded randomness. Same as everyone else this week, but different next week. Rewards both skill AND adaptation.

---

## Section 5: Mode Considerations

### Weekly Time Trial

Core tile system works as designed. No modifications needed.

### Endless Descent (Roguelite)

Core tiles work. The following are noted for Phase 2 expansion:

- **Upgrade Gate tiles:** Fork tiles where players choose power-ups
- **Neon Shard spawns:** Meta-currency placement on tiles
- **Yeti pressure response:** Whether tile difficulty responds to Yeti distance (recommended: static/no response)

---

## Summary

| Aspect | Decision |
|--------|----------|
| Architecture | Hybrid: set pieces + rule-based |
| Tile Categories | 7 types covering all gameplay needs |
| Pacing | Difficulty curve with breathing room rules |
| Seed System | Weekly deterministic generation |
| Course Length | 60-90 seconds (~15-25 tiles) for Time Trial |
| Roguelite | Core tiles work; specifics deferred to Phase 2 |

### Retro Balance Achieved

- SkiFree chaos in Obstacle Fields
- California Games structure in pacing
- NES-era set pieces for memorable moments
- Modern choice tiles for player agency
