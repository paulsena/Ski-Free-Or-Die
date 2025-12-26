# Physics & Tuck Mechanics Design

**Date:** 2025-12-23
**Status:** Validated
**Engine:** Love2D (Lua) - Engine-agnostic design, implement with manual velocity/position updates

> **For AI Agents:** This document defines the physics *behavior*. Implementation will be in Lua with Love2D's update loop. No physics engine needed - we handle velocity and collision manually.

---

## Overview

This document defines the physics system for Ski Free Or Die!, covering movement, tuck mechanics, collision, terrain, and air physics. The goal is a skill-based system inspired by SkiFree's "slippery" feel with modern depth for competitive leaderboards.

---

## Section 1: Core Movement & Controls

**Input:** Keyboard-first using arrow keys or WASD. Touch/mobile is secondary consideration.

### Turning Model: Hybrid Response

- **Low speeds (0-40% max):** Direct turning. Press left, skier immediately angles left. Responsive and forgiving for beginners or recovery situations.
- **High speeds (60-100% max):** Momentum-based. Input shifts weight, skier carves gradually. Must plan lines ahead and commit to turns.
- **Transition zone (40-60%):** Blended response. Gradual shift between modes so players don't feel a jarring switch.

### Speed & Terrain

The slope uses 2-3 terrain intensities that affect acceleration:

| Slope Type | Effect |
|------------|--------|
| Gentle | Slow acceleration, easier control. Good for technical gate sections. |
| Moderate | Standard acceleration. The baseline feel. |
| Steep | Fast acceleration, harder to control. High-risk, high-reward sections. |

Flat or uphill sections bleed speed, making tuck and momentum management critical.

---

## Section 2: Tuck Mechanic

**Activation:** Hold to tuck (Down arrow or Shift). Release to stand. Gives players constant, immediate control over their stance.

**Speed Benefit:** Subtle boost of 10-15%. Tucking is an optimization, not a requirement. Clean runs are possible without tucking, but podium times require mastering when to commit.

### Control Tradeoffs (while tucked)

- **Wider turn radius:** Carving arcs are broader. Tight slalom gates become risky.
- **Slower turn responsiveness:** Initiating a turn takes longer. Must anticipate obstacles earlier.

Both penalties stack, making tuck a genuine commitment. You're trading control for speed.

### Strategic Depth

| Situation | Tuck Decision |
|-----------|---------------|
| Gentle slopes | Valuable to maintain momentum. Low risk since you're moving slower. |
| Steep slopes | Risky. Already accelerating fast, now with reduced control. |
| Before gate sequences | Decision point—carry speed in and fight the wide radius, or stand up for precision? |
| After crashes | Can't tuck immediately during recovery. Must rebuild speed first. |

**Visual Feedback:** Skier visibly crouches. Optional wind/speed lines intensify. Ties into the Flow Multiplier system—sustained tucking during high flow could intensify the 80s visual effects.

---

## Section 3: Collision System

### Obstacle Hierarchy

| Obstacle | Effect |
|----------|--------|
| Small trees/bushes | Slight slowdown (~20% speed loss), no stop. Can clip intentionally to hold a line. |
| Large trees | Major speed loss (~60%), deflection to the side. Keeps you moving but hurts momentum. |
| Rocks | Full crash. Complete stop + 1.5-2 second recovery animation. |
| Cabins | Full crash. Same as rocks. |
| Fences/barriers | Full crash. Course boundaries are non-negotiable. |

**Design Intent:** A clean severity spectrum from "brush through" to "full stop." No zone-based effects—every obstacle is a discrete object you can see and avoid. Simple to learn, depth comes from line optimization.

### Recovery Animation

Duration: 1.5-2 seconds.

- Long enough to matter in time trials and let the Yeti close the gap in Endless mode
- Short enough that one crash doesn't end a run
- Use this time for character personality (frustrated gestures, dusting off snow)

### Pacing

Pacing comes from terrain, not zones. Slope intensity (gentle/moderate/steep) provides natural rhythm. Technical sections on gentle slopes, speed sections on steep slopes.

---

## Section 4: Air Physics & Tricks

### Ramp Launch

When hitting a ramp, launch angle and speed are determined by approach. Once airborne, trajectory is committed—no steering mid-air.

### Air Controls

| Input | Action |
|-------|--------|
| Left/Right | Spin rotation (180, 360, 540, etc.) |
| Up/Down | Flip rotation (backflip, front flip) |
| No trajectory control | What you get is what you committed to |

### Landing Requirements

**Angle-based:** Skis must land facing roughly downhill (within ~45 degrees of forward).

- Land clean: Small speed boost (trick bonus)
- Land sideways/backwards: Crash + recovery

This naturally rewards completed rotations. A 270 degree spin lands you sideways (crash). A full 360 lands you forward (success).

### Trick Rewards

Small speed boosts on successful landings. Enough to matter for optimization, not enough to make ramps mandatory. Fits the "tricks are seasoning" philosophy—the meat is gates and line choice.

### Risk/Reward

Ramps create decision points:
- Skip the ramp, hold your line, stay safe
- Hit the ramp, nail the trick, gain a small edge
- Botch the landing, crash, lose 1.5-2 seconds

---

## Section 5: System Integration

### The Core Loop

1. Read the terrain ahead (slope intensity, obstacles, gates, ramps)
2. Decide: tuck for speed or stand for control?
3. Commit to your line through gates and around obstacles
4. Hit ramps intentionally or avoid them
5. Maintain flow, build the multiplier, chase the time

### Skill Progression

| Level | Behavior |
|-------|----------|
| Beginner | Go slow, stay standing, direct controls protect them. Learn obstacle patterns. |
| Intermediate | Start tucking on safe sections, learn when to commit. Avoid ramps until comfortable. |
| Advanced | Chain tuck windows perfectly, clip small trees for optimal lines, nail trick landings for bonus speed. |

### Mode Differences

**Weekly Time Trial:** No power-ups, pure physics mastery. Every decision matters against the clock. Gate penalties (+3 sec) often outweigh crash recovery—precision beats aggression.

**Endless Descent:** Same physics, but upgrade gates modify stats. The Yeti punishes hesitation. Ramps become more valuable for maintaining lead over the closing wall.

### Tuning Knobs for Development

- Hybrid turning threshold speeds (when does momentum kick in?)
- Tuck speed bonus percentage
- Slope intensity acceleration values
- Collision speed penalties per obstacle type
- Trick landing bonus amount

---

## Removed from Scope

The following were considered but cut for Phase 1 simplicity:

- **Slush zones:** Speed-drain areas. Cut because small trees already serve as "soft" obstacles and slope intensity handles pacing.
- **Glitch zones:** Control-inversion areas. Cut because they add complexity and potential frustration without enough benefit.

Both could be reconsidered for Phase 2 if the procedural generator needs more variety.
