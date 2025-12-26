# Ski Free Or Die! - Love2D Version

A Love2D implementation of the 80s-themed downhill skiing game.

## Requirements

- [Love2D](https://love2d.org/) 11.4 or later

## How to Run

### macOS
```bash
# If Love2D is installed as an app
/Applications/love.app/Contents/MacOS/love .

# Or if installed via Homebrew
love .
```

### Windows
```bash
love.exe .
```

### Linux
```bash
love .
```

## Controls

| Key | Action |
|-----|--------|
| Left Arrow / A | Turn left |
| Right Arrow / D | Turn right |
| Down Arrow / S | Tuck (speed boost, less control) |
| Up Arrow / W | Slow down (more control) |
| ESC | Quit |
| SPACE | Restart (after game over) |

## Features

- SkiFree-style physics with slippery controls
- 80s color palette (hot pink, electric blue, bright yellow, mint green)
- Slalom gates with +3 second penalty for misses
- Progressive difficulty (speed increases over time)
- Obstacles: trees, rocks, cabins
- Tuck mechanic for speed vs control trade-off

## Game Design

Ski down the mountain, pass through gates (yellow poles), and avoid obstacles.
Missing a gate adds a 3-second time penalty. Hitting an obstacle ends the game.
