# Audio System

Procedural 80s chiptune synthesis. No external audio files.

## Files

| File | Purpose |
|------|---------|
| `src/lib/audio_synthesis.lua` | Waveforms, envelopes, sample utilities |
| `src/lib/music.lua` | Track generators, playback API |
| `src/lib/sfx.lua` | Sound effect generators, playback API |

## Music Tracks

| Track | BPM | Style |
|-------|-----|-------|
| `menu` | 110 | Chill synth arpeggios, Am-F-C-G progression |
| `gameplay` | 140 | Driving beat, E minor power chords |
| `gameover` | 80 | Melancholic, descending melody |
| `awards` | 120 | Triumphant fanfare, C-F-G-C progression |

### Music API
```lua
local Music = require("src.lib.music")
Music.play("gameplay")  -- "menu", "gameplay", "gameover", "awards"
Music.stop()
Music.set_volume(0.5)
```

## Sound Effects

| SFX | Duration | Description |
|-----|----------|-------------|
| `ski_loop` | 1.0s | Looping whoosh/snow slide |
| `crash` | 0.4s | Heavy impact with noise burst |
| `gate_pass` | 0.15s | Ascending chirp (positive) |
| `gate_miss` | 0.25s | Descending buzz (negative) |
| `tree_hit` | 0.2s | Wood-like thump |

### SFX API
```lua
local SFX = require("src.lib.sfx")
SFX.play("crash")
SFX.play("gate_pass", 0.7)  -- optional volume
SFX.stop("ski_loop")
```

## Waveforms (audio_synthesis.lua)

| Function | Sound |
|----------|-------|
| `square_wave(phase, duty)` | Classic 8-bit lead |
| `triangle_wave(phase)` | Soft bass |
| `sawtooth_wave(phase)` | Bright/buzzy synth |
| `sine_wave(phase)` | Smooth bass |
| `noise_wave()` | Percussion/hi-hats |
| `pulse_wave(phase, width)` | 80s synth stabs |

## Envelopes (audio_synthesis.lua)

| Function | Use Case |
|----------|----------|
| `adsr_envelope(t, dur, a, d, s, r)` | Custom ADSR |
| `punchy_envelope(t, dur)` | Bass/drums |
| `stab_envelope(t, dur)` | Synth stabs |
| `lead_envelope(t, dur)` | Lead melodies |
| `hihat_envelope(t, dur)` | Hi-hats |
| `quick_envelope(t, dur)` | Short SFX |

## Adding New Audio

### New Music Track
1. In `music.lua`, add `generate_yourtrack_theme()` function
2. Add case to `get_or_generate_track()`: `elseif name == "yourtrack" then`
3. Call with `Music.play("yourtrack")`

### New Sound Effect
1. In `sfx.lua`, add `generate_yoursfx()` function
2. Add case to `get_or_generate_sfx()`: `elseif name == "yoursfx" then`
3. Call with `SFX.play("yoursfx")`

## Common Tasks

**Add new music track:**
1. Create `generate_yourtrack_theme()` in `src/lib/music.lua` (~line 130)
2. Add case in `get_or_generate_track()` (line 820): `elseif name == "yourtrack" then`
3. Call `Music.play("yourtrack")`

**Add new sound effect:**
1. Create `generate_yoursfx()` in `src/lib/sfx.lua` (~line 50)
2. Add case in `get_or_generate_sfx()` (line 222): `elseif name == "yoursfx" then`
3. Call `SFX.play("yoursfx")`

**Add new waveform:**
1. Create function in `src/lib/audio_synthesis.lua`
2. Export in module return table at bottom of file
3. Import in `music.lua` or `sfx.lua` as needed

**Adjust music volume:**
1. Call `Music.set_volume(0.0-1.0)` from any game state
2. Default is 0.4 (set in `music.lua` line 35)

**Stop ski loop when transitioning states:**
1. Call `SFX.stop("ski_loop")` before state change
2. Or call `SFX.stop_all()` to stop everything
