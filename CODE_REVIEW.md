# Code Review: Ski Free Or Die

**Reviewer:** Cranky Senior Staff Engineer
**Date:** 2026-01-17
**Verdict:** Needs Work. A lot of it.

---

## Executive Summary

Look, kid. This code *works*. I can see you put effort into it. But there's a difference between "it runs" and "it's maintainable." Let me tell you about all the skeletons I found in this closet.

---

## CRITICAL ISSUES

### 1. MASSIVE Code Duplication Between music.lua and sfx.lua

**Files:** `src/lib/music.lua:36-73` and `src/lib/sfx.lua:23-50`

This is a TEXTBOOK DRY violation. You literally copy-pasted the waveform generators, envelope functions, and helper utilities between these two files. I counted:

- `square_wave()` - duplicated
- `triangle_wave()` - duplicated
- `sawtooth_wave()` - duplicated
- `sine_wave()` - duplicated
- `noise_wave()` - duplicated
- `reset_noise()` - duplicated
- `adsr_envelope()` - duplicated
- `punchy_envelope()` - duplicated
- `normalize_samples()` - duplicated
- `samples_to_sound_data()` - duplicated

**Why this is bad:** When you inevitably need to fix a bug in the noise generator, you'll fix it in one file and forget the other. Or worse, you'll "fix" them differently.

**Fix:** Extract shared audio synthesis code into `src/lib/audio_synthesis.lua` and require it in both music.lua and sfx.lua.

---

### 2. Non-Deterministic RNG Breaking Reproducibility

**The CLAUDE.md specifically says:** "Procedural Generation: Tile-based map generation from seeds (deterministic)"

Yet I found `math.random()` splattered everywhere like confetti:

| File | Lines | Issue |
|------|-------|-------|
| `src/states/menu_state.lua` | 43-49, 64-67 | Snow particles use non-seeded random |
| `src/entities/obstacle.lua` | 64-65 | `Obstacle.new()` uses `math.random()` for visual variation |
| `src/entities/obstacle.lua` | 77 | `spawn_random()` uses non-seeded RNG |
| `src/systems/particles.lua` | 69-72, 105-121 | ALL particle emissions use `math.random()` |

**Why this matters:** Your "Weekly Time Trial" mode claims deterministic courses, but visual variations aren't deterministic. If a player records a replay, the snow particles and obstacle scales will look different every time. Sloppy.

**Fix:**
- Menu particles: Fine to stay random, they're decoration
- Obstacles: Always use `new_seeded()` or remove the visual variation from the non-seeded constructor
- Particles: Create particle-specific seeded RNG or accept the non-determinism (document it)

---

### 3. Dead/Unreachable Code

**File:** `src/lib/music.lua:513-524`

```lua
-- This entire block does NOTHING
local kick_beats = {0, 1.5, 2, 3.5}
for _, kick_offset in ipairs(kick_beats) do
    if beat + kick_offset / 4 < 4 then
        local actual_beat = beat + (kick_offset % 1) * 0.5
        if kick_offset == 0 or kick_offset == 1.5 or kick_offset == 2 or kick_offset == 3.5 then
            local is_on_beat = (beat == 0 or beat == 2) and (kick_offset % 2 == 0)
            if is_on_beat or (kick_offset == 1.5 or kick_offset == 3.5) then
                -- Simplified: kick on 1, 2-and, 3, 4-and
                -- NOTHING HAPPENS HERE. EMPTY BLOCK.
            end
        end
    end
end
```

You wrote a complex nested conditional that does absolutely nothing. The actual kick generation happens AFTER this block. Delete this garbage.

**File:** `src/lib/sfx.lua:83-85`

```lua
local function smooth_fade(t, duration)
    return adsr_envelope(t, duration, 0.1, 0.1, 0.8, 0.2)
end
```

Defined but never used. Either use it or lose it.

---

### 4. Stub Functions Masquerading as Real Ones

**File:** `src/lib/music.lua:1067-1072`

```lua
function Music.fade_out(duration)
    duration = duration or 1.0
    -- Note: This would need to be called in an update loop
    -- For now, just stop
    Music.stop()
end
```

This function lies. It claims to fade out but just stops abruptly. Either implement it properly or remove it and don't pretend you have fade functionality.

---

### 5. Unused Function Parameter

**File:** `src/entities/skier.lua:189`

```lua
function Skier:deflect(direction)
    self.vx = -self.vx * Skier.DEFLECT_VX_FACTOR
    -- 'direction' parameter is NEVER USED
```

Why accept a parameter you don't use? This confuses anyone reading the call sites who thinks direction matters.

---

## MODERATE ISSUES

### 6. Runtime Require Inside Render Loop

**File:** `main.lua:90`

```lua
function love.draw()
    -- ...
    local Skier = require("src.entities.skier")  -- EVERY FRAME!
```

You're calling `require()` inside the draw function. Yes, Lua caches requires, but this is still checking the cache 60 times per second. Move it to the top of the file with the other requires.

---

### 7. Table Iteration Order Non-Determinism

**File:** `src/entities/obstacle.lua:80`

```lua
for type_name, def in pairs(Obstacle.TYPES) do
```

In Lua 5.1, `pairs()` does not guarantee iteration order. The order depends on the internal hash table. This means `spawn_random_seeded()` might select different obstacles on different Lua versions or even different runs if the hash changes.

**Fix:** Use an ordered array of type names and iterate that instead.

---

### 8. Memory Accumulation in SFX

**File:** `src/lib/sfx.lua:357-358`

```lua
if sfx_name ~= "ski_loop" then
    play_source = source:clone()
end
```

Every sound effect creates a new clone that's never tracked. Rapid-fire sound effects (like gate passes in quick succession) will accumulate Source objects until garbage collection kicks in.

**Fix:** Either pool the sources or explicitly release them after playback.

---

### 9. Magic Numbers Galore

| File | Line | Magic Number | What it means |
|------|------|--------------|---------------|
| `main.lua` | 96 | `0.17` | Pixels/sec to MPH conversion. WHY 0.17? |
| `play_state.lua` | 148 | `50` | Collision detection radius. Why 50? |
| `skier.lua` | 152 | `4` | Lerp factor for speed. Why 4? |
| `particles.lua` | 92 | `30` | Minimum speed for snow spray. Why 30? |

**Fix:** Define constants with meaningful names. Future you will thank present you.

---

### 10. No Input Validation in StateManager

**File:** `src/core/state_manager.lua:18-19`

```lua
current_state = states[name]  -- Could be nil
current_state_name = name
```

If someone calls `StateManager.switch("typo")`, this silently sets `current_state` to nil and then everything breaks when you try to call update/draw. At least throw a helpful error.

---

## MINOR ISSUES / NITPICKS

### 11. Inconsistent Naming

- Constants: `TYPES`, `POSITIONS`, `NOTES` (uppercase)
- But they're all mutable tables, not true constants
- Mix of `snake_case` and unclear abbreviations (`obs`, `hb`)

### 12. Empty Exit Function

**File:** `src/states/menu_state.lua:56-57`

```lua
function MenuState:exit()
end
```

If it's empty, either add a comment explaining why or delete it. Blank functions are cruft.

### 13. Hardcoded UI Positions

**File:** `src/states/menu_state.lua:88-89`

```lua
local menu_start_y = 355
-- ...
local hint_y = 455
```

These magic numbers depend on your background image. If you ever change the image, good luck finding these.

---

## SUMMARY OF FIXES REQUIRED

1. **[CRITICAL]** Extract shared audio code into `src/lib/audio_synthesis.lua`
2. **[CRITICAL]** Remove dead code block in `music.lua:513-524`
3. **[CRITICAL]** Remove unused `smooth_fade()` in sfx.lua
4. **[HIGH]** Either implement `Music.fade_out()` properly or remove it
5. **[HIGH]** Remove unused `direction` parameter from `Skier:deflect()`
6. **[HIGH]** Move runtime require to top of `main.lua`
7. **[MEDIUM]** Fix table iteration order in obstacle.lua for determinism
8. **[MEDIUM]** Add validation to `StateManager.switch()`
9. **[LOW]** Define constants for magic numbers
10. **[LOW]** Clean up empty functions

---

## Final Words

The architecture is actually decent - you've got clean separation between entities, states, and systems. The procedural audio synthesis is creative. But the devil's in the details, and these details will bite you when you least expect it.

Now go fix this mess.

*- Your Friendly Neighborhood Cranky Senior Staff Engineer*
