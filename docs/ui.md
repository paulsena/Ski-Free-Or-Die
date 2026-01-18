# UI System Documentation

## State Machine

**File:** `src/core/state_manager.lua`

Registered states: `menu`, `play`, `highscores`, `name_entry`

API: `StateManager.register(name, state)`, `StateManager.switch(name, ...)`, `StateManager.get_current_name()`

## State Transition Flow

```
menu ─┬─> play (time_trial) ─┬─> name_entry ─> highscores ─> menu
      │                      └─> highscores ─> menu
      ├─> play (endless) ────┬─> name_entry ─> highscores ─> menu
      │                      └─> highscores ─> menu
      ├─> highscores ─> menu
      └─> quit
```

## States

### MenuState (`src/states/menu_state.lua`)
Options: Time Trial, Endless Mode, High Scores, Quit
- Switches to `play` with `{mode = "time_trial"}` or `{mode = "endless"}`
- Switches to `highscores` with no params

### PlayState (`src/states/play_state.lua`)
Entry params: `{mode = "time_trial" | "endless"}`
- On finish: checks `Leaderboard.qualifies()` -> `name_entry` or `highscores`
- Pause overlay (P key), game over overlay on finish

### NameEntryState (`src/states/name_entry_state.lua`)
Entry params: `{mode, score, rank, stats}`
- Arcade-style character selector (A-Z, 0-9, symbols)
- Max 8 chars, min 3 to submit
- Calls `Leaderboard.add()` then switches to `highscores` with `{from_entry = true}`

### HighScoresState (`src/states/highscores_state.lua`)
Entry params: `{mode?, from_entry?}`
- Tab to switch between time_trial/endless views
- ESC returns to menu

## HUD (`src/ui/sidebar_hud.lua`)

Right sidebar stats displayed:
- TIME (elapsed + penalty)
- PENALTY (+Xs from missed gates)
- GATES (passed count)
- SPEED (MPH)
- DIST (meters)
- TUCK (flashing indicator when tucking)
- Mode label (TRIAL / ENDLESS)

Left sidebar: decorative 80s art with game title

## Leaderboard (`src/core/leaderboard.lua`)

Save file: `highscores.dat` (Love2D save directory)
Max entries: 10 per mode

Score calculation:
- `time_trial`: `1000000 - (total_time * 1000)` (lower time = higher score)
- `endless`: `distance / 10` (meters)

API:
- `Leaderboard.init()` - load from disk
- `Leaderboard.qualifies(mode, score)` -> bool, rank
- `Leaderboard.add(mode, name, score)` -> rank
- `Leaderboard.get_scores(mode)` -> entries[]
- `Leaderboard.format_score(mode, score)` -> string

## Common Tasks

**Add new game state:**
1. Create state file in `src/states/` (follow pattern from `menu_state.lua`)
2. Register in `main.lua` lines 45-48: `StateManager.register("name", YourState)`
3. Add transitions: call `StateManager.switch("name", params)` from other states

**Add new HUD stat:**
- Edit `src/ui/sidebar_hud.lua` `draw_right()` function (line 639)
- Add label with `draw_block_text("LABEL", ...)` and value below it
- Update `y` position after each stat block

**Add menu option:**
- Edit `menu_options` table in `src/states/menu_state.lua` line 24
- Add handler in `select_option()` function (line 206)

**Add new character to blocky font:**
- Add pattern to `CHARS` table in `src/ui/sidebar_hud.lua` (starts line 30)
- Pattern is 5x7 grid: `{0,1,1,1,0}` for each row

**Change state transition flow:**
- Find `StateManager.switch()` calls in source state file
- Update destination state name and params as needed
