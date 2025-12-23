# Yeti Mechanic Design

**Date:** 2025-12-23
**Status:** Validated
**Mode:** Endless Descent only

---

## Overview

The Yeti is a persistent chase threat in Endless Descent—not a surprise appearance like original SkiFree, but an ever-present "closing wall" that creates constant tension.

**Design Philosophy:** The Yeti answers the question "why can't I just ski carefully forever?" It forces pace, rewards flow, and ensures all runs eventually end.

---

## Core Mechanics

### Always Present

- Yeti spawns at run start, far behind the player
- Moves at a base speed matching "good" skiing pace
- Optimal play (tucking, clean lines, trick bonuses) outpaces the Yeti
- Suboptimal play (crashes, hesitation, missed lines) lets Yeti gain ground

### Speed Scaling

| Run Progress | Yeti Behavior |
|--------------|---------------|
| 0-60 seconds | Base speed. Skilled players build comfortable lead. |
| 60-120 seconds | +15% speed. Pressure increases. |
| 120-180 seconds | +30% speed. Mistakes hurt more. |
| 180+ seconds | +50% and climbing. Eventually uncatchable. All runs end. |

This creates natural run length variation:
- Great players: 3-4 minutes
- Average players: 1-2 minutes
- The Yeti is the clock

---

## Proximity System

### Distance Zones

Distance is measured in **time behind player**, not pixels. This means Yeti feels equally threatening whether you're going fast or slow.

| Zone | Distance | Indicators |
|------|----------|------------|
| **Safe** | 5+ seconds behind | Occasional distant roar. Subtle blue tint at screen top. |
| **Warning** | 3-5 seconds | Yeti silhouette visible at top edge. Music shifts darker. |
| **Danger** | 1-3 seconds | Yeti large and visible. Heartbeat audio. Screen edge pulses red. |
| **Critical** | <1 second | Full panic. Heavy breathing. Yeti arms reaching. |
| **Caught** | 0 | Grab animation. Run ends. |

---

## Crash Recovery Tension

This is where the Yeti creates real stakes:

1. Player crashes (1.5-2 second recovery from physics design)
2. Yeti gains ~2-3 seconds of ground during recovery
3. Player was in "Safe" zone → now in "Warning" or "Danger"
4. Creates genuine tension: "Can I recover before it catches me?"

**Consequences:**
- Multiple crashes in sequence = death spiral
- One crash = recoverable with clean skiing afterward

---

## Visual Design

### The Yeti

- Classic SkiFree white yeti silhouette (homage)
- 80s pixel art style matching game aesthetic
- Exaggerated running animation, arms pumping
- Gets larger and more detailed as it approaches
- At "Critical" distance, arms reach toward player

### Screen Effects

| Zone | Visual Effect |
|------|---------------|
| Safe | Subtle cool blue tint at top edge |
| Warning | Yeti silhouette, slight vignette |
| Danger | Red pulse at screen edges, stronger vignette |
| Critical | Heavy red pulse, screen shake |

---

## Audio Design

### Progression

| Zone | Audio |
|------|-------|
| Safe | Distant roar every 15-20 seconds |
| Warning | Rhythmic footsteps in snow, synth drone |
| Danger | Heavy breathing, heartbeat, music intensifies |
| Critical | Breathing overwhelms, music cuts to heartbeat only |
| Caught | Roar + crunch, silence, game over jingle |

### The 80s Touch

The danger audio should feel like an 80s horror synth score. Think John Carpenter tension—building dread with analog synth drones and pulsing bass.

---

## What the Yeti Does NOT Do

| Anti-Feature | Reason |
|--------------|--------|
| Surprise spawns | Frustrating, feels unfair. Persistent presence is scarier. |
| Random speed bursts | Unpredictable = unfair. Consistent rules = learnable. |
| Slow down for struggling players | Removes stakes. The Yeti is merciless. |
| Affect tile generation | Tiles are static. Yeti is pressure, not level design. |
| Appear in Time Trial | That mode is pure skill vs. clock. Yeti is Endless only. |

---

## Edge Cases

| Scenario | Result |
|----------|--------|
| Player stops completely | Yeti catches them. No mercy. |
| Player skis backward/uphill | Yeti closes rapidly. Bad idea. |
| Player is frame-perfect optimal | 4-5 minute run until speed scaling makes escape impossible. Great run. |

---

## System Integration

| System | Yeti Interaction |
|--------|------------------|
| Physics | Yeti speed compared against player speed |
| Crashes | 1.5-2 sec recovery = Yeti gains 2-3 seconds |
| Tricks | Successful tricks = speed boost = slight distance gain |
| Tiles | None. Tiles don't respond to Yeti proximity. |
| Flow Multiplier | High flow = faster skiing = more Yeti buffer |

---

## Implementation Notes

### Yeti Position Calculation

```
yetiDistance = initialDistance
each frame:
    playerProgress = player.distanceTraveled
    yetiProgress = yetiSpeed * elapsedTime
    yetiDistance = playerProgress - yetiProgress

    if yetiDistance <= 0:
        triggerCaught()
```

### Speed Scaling Formula

```
baseSpeed = averageGoodPlayerSpeed * 0.95  // Slightly slower than good play
scalingFactor = 1 + (elapsedTime / 60) * 0.15  // +15% per minute
yetiSpeed = baseSpeed * scalingFactor
```

These are starting points—tune based on playtesting.
