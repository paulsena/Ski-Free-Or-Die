# Phase 0: Love2D Project Setup

> **For AI Agents:** Execute these tasks in order. Each task includes the exact code to write. Verify each step works before moving on.

**Goal:** Create a working Love2D project skeleton with pixel-perfect rendering and the 80s color palette.

**Prerequisites:** Love2D 11.4+ installed and available in PATH

---

## Task 0.1: Create Project Structure

**Create these files and folders:**

```
SkiFreeOrDie/
├── main.lua
├── conf.lua
├── src/
│   ├── core/
│   ├── entities/
│   ├── world/
│   ├── systems/
│   ├── ui/
│   └── lib/
├── assets/
│   ├── sprites/
│   └── sounds/
├── config/
└── test/
```

**Step 1: Create `conf.lua`**

```lua
-- conf.lua
-- Love2D configuration - runs before love.load

function love.conf(t)
    t.identity = "ski_free_or_die"
    t.version = "11.4"

    t.window.title = "Ski Free Or Die!"
    t.window.width = 960          -- 320 * 3
    t.window.height = 540         -- 180 * 3
    t.window.resizable = true
    t.window.minwidth = 320
    t.window.minheight = 180
    t.window.vsync = 1

    t.modules.joystick = false    -- Not using gamepads yet
    t.modules.physics = false     -- We'll do our own physics
end
```

**Step 2: Create `main.lua`**

```lua
-- main.lua
-- Ski Free Or Die! - Entry point

-- Game constants
local GAME_WIDTH = 320
local GAME_HEIGHT = 180

-- Canvas for pixel-perfect rendering
local canvas

function love.load()
    -- Set up pixel-perfect rendering
    love.graphics.setDefaultFilter("nearest", "nearest")
    canvas = love.graphics.newCanvas(GAME_WIDTH, GAME_HEIGHT)

    -- Set background color (Sky Blue)
    love.graphics.setBackgroundColor(135/255, 206/255, 235/255)
end

function love.update(dt)
    -- Game logic goes here
end

function love.draw()
    -- Draw to canvas at native resolution
    love.graphics.setCanvas(canvas)
    love.graphics.clear(135/255, 206/255, 235/255)

    -- All game drawing happens here
    -- (placeholder: draw a test rectangle)
    love.graphics.setColor(1, 0.08, 0.58) -- Hot Pink
    love.graphics.rectangle("fill", GAME_WIDTH/2 - 8, GAME_HEIGHT/2 - 12, 16, 24)
    love.graphics.setColor(1, 1, 1)

    love.graphics.setCanvas()

    -- Scale canvas to window
    local scale_x = love.graphics.getWidth() / GAME_WIDTH
    local scale_y = love.graphics.getHeight() / GAME_HEIGHT
    local scale = math.min(scale_x, scale_y)

    local offset_x = (love.graphics.getWidth() - GAME_WIDTH * scale) / 2
    local offset_y = (love.graphics.getHeight() - GAME_HEIGHT * scale) / 2

    love.graphics.draw(canvas, offset_x, offset_y, 0, scale, scale)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

function love.resize(w, h)
    -- Window resized, canvas scaling handled in draw
end
```

**Verification:**
```bash
cd SkiFreeOrDie && love .
```
- Window opens at 960x540
- Sky blue background
- Pink rectangle in center
- ESC quits

---

## Task 0.2: Create Color Palette Module

**Create `src/colors.lua`:**

```lua
-- src/colors.lua
-- 80s "Windbreaker" color palette

local Colors = {}

-- Primary Palette
Colors.HOT_PINK = {1, 0.078, 0.576, 1}        -- #FF1493
Colors.ELECTRIC_BLUE = {0, 1, 1, 1}            -- #00FFFF
Colors.BRIGHT_YELLOW = {1, 0.843, 0, 1}        -- #FFD700
Colors.MINT_GREEN = {0, 1, 0.498, 1}           -- #00FF7F
Colors.SNOW_WHITE = {1, 0.98, 0.98, 1}         -- #FFFAFA

-- Secondary Palette
Colors.DEEP_PURPLE = {0.58, 0, 0.827, 1}       -- #9400D3
Colors.SUNSET_ORANGE = {1, 0.271, 0, 1}        -- #FF4500
Colors.SKY_BLUE = {0.529, 0.808, 0.922, 1}     -- #87CEEB
Colors.PINE_GREEN = {0.133, 0.545, 0.133, 1}   -- #228B22
Colors.ROCK_GRAY = {0.412, 0.412, 0.412, 1}    -- #696969
Colors.CABIN_BROWN = {0.545, 0.271, 0.075, 1}  -- #8B4513

-- UI Colors
Colors.UI_PANEL_BG = {0, 0, 0, 0.8}            -- #000000CC

-- Gate States
Colors.GATE_PENDING = Colors.HOT_PINK
Colors.GATE_PASSED = Colors.MINT_GREEN
Colors.GATE_MISSED = Colors.ROCK_GRAY

-- Helper function to unpack color for love.graphics.setColor
function Colors.set(color)
    love.graphics.setColor(color)
end

return Colors
```

**Update `main.lua` to use colors:**

```lua
-- At top of main.lua, after constants
local Colors = require("src.colors")

-- In love.draw, replace hardcoded color:
Colors.set(Colors.HOT_PINK)
love.graphics.rectangle("fill", GAME_WIDTH/2 - 8, GAME_HEIGHT/2 - 12, 16, 24)
Colors.set(Colors.SNOW_WHITE)
```

---

## Task 0.3: Create Game State Manager

**Create `src/core/state_manager.lua`:**

```lua
-- src/core/state_manager.lua
-- Simple game state machine

local StateManager = {}

local current_state = nil
local states = {}

function StateManager.register(name, state)
    states[name] = state
end

function StateManager.switch(name, ...)
    if current_state and current_state.exit then
        current_state:exit()
    end

    current_state = states[name]

    if current_state and current_state.enter then
        current_state:enter(...)
    end
end

function StateManager.update(dt)
    if current_state and current_state.update then
        current_state:update(dt)
    end
end

function StateManager.draw()
    if current_state and current_state.draw then
        current_state:draw()
    end
end

function StateManager.keypressed(key)
    if current_state and current_state.keypressed then
        current_state:keypressed(key)
    end
end

function StateManager.keyreleased(key)
    if current_state and current_state.keyreleased then
        current_state:keyreleased(key)
    end
end

function StateManager.get_current()
    return current_state
end

return StateManager
```

**Create `src/states/play_state.lua`:**

```lua
-- src/states/play_state.lua
-- Main gameplay state

local Colors = require("src.colors")

local PlayState = {}

function PlayState:enter()
    -- Initialize game objects here
    self.skier_x = 160  -- Center of 320
    self.skier_y = 90   -- Center of 180
end

function PlayState:exit()
    -- Cleanup if needed
end

function PlayState:update(dt)
    -- Game logic here
end

function PlayState:draw()
    -- Draw game world
    Colors.set(Colors.ELECTRIC_BLUE)
    love.graphics.rectangle("fill", self.skier_x - 8, self.skier_y - 12, 16, 24)
    Colors.set(Colors.SNOW_WHITE)

    -- Debug text
    love.graphics.print("Ski Free Or Die!", 10, 10)
end

function PlayState:keypressed(key)
    if key == "r" then
        self:enter()  -- Restart
    end
end

return PlayState
```

**Update `main.lua` to use states:**

```lua
-- main.lua
-- Ski Free Or Die! - Entry point

local StateManager = require("src.core.state_manager")
local PlayState = require("src.states.play_state")
local Colors = require("src.colors")

-- Game constants
local GAME_WIDTH = 320
local GAME_HEIGHT = 180

-- Canvas for pixel-perfect rendering
local canvas

function love.load()
    -- Set up pixel-perfect rendering
    love.graphics.setDefaultFilter("nearest", "nearest")
    canvas = love.graphics.newCanvas(GAME_WIDTH, GAME_HEIGHT)

    -- Register states
    StateManager.register("play", PlayState)

    -- Start in play state
    StateManager.switch("play")
end

function love.update(dt)
    StateManager.update(dt)
end

function love.draw()
    -- Draw to canvas at native resolution
    love.graphics.setCanvas(canvas)
    love.graphics.clear(Colors.SKY_BLUE)

    StateManager.draw()

    love.graphics.setCanvas()

    -- Scale canvas to window
    local scale_x = love.graphics.getWidth() / GAME_WIDTH
    local scale_y = love.graphics.getHeight() / GAME_HEIGHT
    local scale = math.min(scale_x, scale_y)

    local offset_x = (love.graphics.getWidth() - GAME_WIDTH * scale) / 2
    local offset_y = (love.graphics.getHeight() - GAME_HEIGHT * scale) / 2

    love.graphics.draw(canvas, offset_x, offset_y, 0, scale, scale)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    StateManager.keypressed(key)
end

function love.keyreleased(key)
    StateManager.keyreleased(key)
end

function love.resize(w, h)
    -- Window resized, canvas scaling handled in draw
end
```

---

## Task 0.4: Create Utility Modules

**Create `src/lib/utils.lua`:**

```lua
-- src/lib/utils.lua
-- Common utility functions

local Utils = {}

-- Clamp a value between min and max
function Utils.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Linear interpolation
function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

-- Distance between two points
function Utils.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Check if two circles overlap
function Utils.circles_collide(x1, y1, r1, x2, y2, r2)
    return Utils.distance(x1, y1, x2, y2) < r1 + r2
end

-- Check if two AABBs overlap
function Utils.aabb_collide(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end

-- Sign of a number (-1, 0, or 1)
function Utils.sign(x)
    if x > 0 then return 1
    elseif x < 0 then return -1
    else return 0 end
end

-- Round to nearest integer
function Utils.round(x)
    return math.floor(x + 0.5)
end

return Utils
```

**Create `src/lib/camera.lua`:**

```lua
-- src/lib/camera.lua
-- Simple 2D camera with follow behavior

local Camera = {}

function Camera.new()
    local self = {
        x = 0,
        y = 0,
        target_x = 0,
        target_y = 0,
        offset_x = 0,
        offset_y = 0,
        smooth = 5  -- Higher = faster follow
    }
    return setmetatable(self, {__index = Camera})
end

function Camera:set_target(x, y)
    self.target_x = x
    self.target_y = y
end

function Camera:set_offset(x, y)
    self.offset_x = x
    self.offset_y = y
end

function Camera:update(dt)
    -- Smooth follow
    local t = 1 - math.exp(-self.smooth * dt)
    self.x = self.x + (self.target_x - self.x) * t
    self.y = self.y + (self.target_y - self.y) * t
end

function Camera:snap()
    -- Instantly move to target
    self.x = self.target_x
    self.y = self.target_y
end

function Camera:apply()
    -- Apply camera transform
    love.graphics.push()
    love.graphics.translate(
        -self.x + self.offset_x,
        -self.y + self.offset_y
    )
end

function Camera:reset()
    love.graphics.pop()
end

-- Convert screen coords to world coords
function Camera:screen_to_world(sx, sy)
    return sx + self.x - self.offset_x, sy + self.y - self.offset_y
end

-- Convert world coords to screen coords
function Camera:world_to_screen(wx, wy)
    return wx - self.x + self.offset_x, wy - self.y + self.offset_y
end

return Camera
```

---

## Task 0.5: Final Verification

**Updated `src/states/play_state.lua` with camera test:**

```lua
-- src/states/play_state.lua
-- Main gameplay state

local Colors = require("src.colors")
local Camera = require("src.lib.camera")

local PlayState = {}

local GAME_WIDTH = 320
local GAME_HEIGHT = 180

function PlayState:enter()
    self.camera = Camera.new()
    self.camera:set_offset(GAME_WIDTH / 2, GAME_HEIGHT * 0.7)  -- Skier in lower portion

    self.skier = {
        x = 0,
        y = 0,
        speed = 50
    }
end

function PlayState:exit()
end

function PlayState:update(dt)
    -- Move skier down (positive Y = down the slope)
    self.skier.y = self.skier.y + self.skier.speed * dt

    -- Camera follows skier
    self.camera:set_target(self.skier.x, self.skier.y)
    self.camera:update(dt)
end

function PlayState:draw()
    self.camera:apply()

    -- Draw some reference lines on the slope
    Colors.set(Colors.SNOW_WHITE)
    for y = -200, 2000, 100 do
        love.graphics.line(-150, y, 150, y)
        love.graphics.print(tostring(y), -140, y)
    end

    -- Draw skier
    Colors.set(Colors.ELECTRIC_BLUE)
    love.graphics.rectangle("fill", self.skier.x - 8, self.skier.y - 12, 16, 24)

    self.camera:reset()

    -- HUD (not affected by camera)
    Colors.set(Colors.SNOW_WHITE)
    love.graphics.print(string.format("Y: %.0f", self.skier.y), 10, 10)
end

function PlayState:keypressed(key)
    if key == "r" then
        self:enter()
    end
end

return PlayState
```

**Run and verify:**

```bash
cd SkiFreeOrDie && love .
```

- [x] Window opens at 960x540
- [x] Sky blue background with proper scaling
- [x] Blue rectangle (skier) visible in lower portion of screen
- [x] World scrolls down (reference lines move up)
- [x] Y position updates in top left
- [x] Press R to restart
- [x] Press ESC to quit

---

## Phase 0 Complete!

**Files created:**
```
SkiFreeOrDie/
├── main.lua
├── conf.lua
├── src/
│   ├── core/
│   │   └── state_manager.lua
│   ├── states/
│   │   └── play_state.lua
│   ├── lib/
│   │   ├── utils.lua
│   │   └── camera.lua
│   └── colors.lua
├── assets/
│   ├── sprites/
│   └── sounds/
└── config/
```

**Next Phase:** Phase 1 - Core Movement (skier turning and tuck mechanics)
