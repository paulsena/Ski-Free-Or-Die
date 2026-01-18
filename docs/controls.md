# Controls Reference

## Input Flow

```
main.lua                    -> StateManager -> play_state.lua / menu_state.lua
  keypressed()                                   keypressed()
  mousepressed()                                 update() -> skier:handle_input()
  wheelmoved()
  love.getGameMousePosition()  -- converts window coords to game coords
```

## Gameplay Controls (src/entities/skier.lua:82-130)

### Mouse Steering
Zone-based turning using horizontal distance from skier (screen center = 180px).

| Zone | Offset (px) | Position | Angle |
|------|-------------|----------|-------|
| Center | 0-30 | CENTER (4) | 0 |
| Gentle | 31-80 | LEFT/RIGHT (3/5) | 30 |
| Sharp | 81-140 | FAR_LEFT/FAR_RIGHT (2/6) | 60 |
| Full Stop | 141+ | FULL_LEFT/FULL_RIGHT (1/7) | 90 |

Thresholds defined at lines 40-43:
- `ZONE_CENTER = 30`
- `ZONE_GENTLE = 80`
- `ZONE_SHARP = 140`

### Tuck (Speed Boost)
**+30% speed**, reduced turn control. Any of:
- Left/Right mouse button
- Down arrow / S key
- Left/Right Shift

### Sideways Push (when stopped/sliding)
- A key while facing full left
- D key while facing full right

### Pause/Menu
- P: Toggle pause (play_state.lua:383)
- R: Restart run (play_state.lua:380)
- M: Toggle mute (play_state.lua:391)
- Escape: Return to menu (main.lua:118)
- Enter: Continue after game over (play_state.lua:398)

## Menu Controls (src/states/menu_state.lua)

### Keyboard
- Up/W, Down/S: Navigate (line 145)
- Enter/Space: Select (line 155)
- M: Toggle mute

### Mouse
- Click menu item: Select (line 167)
- Scroll wheel: Navigate with dead zone (line 186)
  - `WHEEL_THRESHOLD = 2` clicks to move selection

## Common Tasks

**Add new keyboard shortcut:**
- Add to `keypressed()` in relevant state file (`src/states/play_state.lua:379`, `src/states/menu_state.lua:145`)

**Adjust mouse sensitivity:**
- Edit zone thresholds in `src/entities/skier.lua` (lines 40-43: `ZONE_CENTER`, `ZONE_GENTLE`, `ZONE_SHARP`)

**Change tuck speed boost:**
- Edit `TUCK_SPEED_BONUS` in `src/entities/skier.lua:33` (currently 0.30 = 30%)

**Add new game state shortcut:**
- Add key check in `main.lua:keypressed()` (line ~115) for global shortcuts
- Or in specific state's `keypressed()` for state-specific shortcuts

**Modify crash/immunity timing:**
- Edit `CRASH_DURATION` and `IMMUNITY_DURATION` in `src/entities/skier.lua:34-35`
