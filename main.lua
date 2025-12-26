-- main.lua
-- Ski Free Or Die! - Entry point
-- 80s-themed downhill skiing game

local StateManager = require("src.core.state_manager")
local Colors = require("src.colors")

-- Game constants
local GAME_WIDTH = 320
local GAME_HEIGHT = 180

-- Canvas for pixel-perfect rendering
local canvas

function love.load(args)
    -- Check for test mode
    if args then
        for _, arg in ipairs(args) do
            if arg == "--test" then
                require("test.suite")
                return -- Stop loading the game
            end
        end
    end

    -- Set up pixel-perfect rendering
    love.graphics.setDefaultFilter("nearest", "nearest")
    canvas = love.graphics.newCanvas(GAME_WIDTH, GAME_HEIGHT)

    -- Set window icon (TODO: add icon later)
    -- love.window.setIcon(love.image.newImageData("assets/icon.png"))

    -- Load and register states
    local PlayState = require("src.states.play_state")
    local MenuState = require("src.states.menu_state")

    StateManager.register("menu", MenuState)
    StateManager.register("play", PlayState)

    -- Start in menu state
    StateManager.switch("menu")
end

function love.update(dt)
    -- Cap delta time to prevent physics issues on slow frames
    dt = math.min(dt, 1/30)
    StateManager.update(dt)
end

function love.draw()
    -- Draw to canvas at native resolution
    love.graphics.setCanvas(canvas)
    love.graphics.clear(Colors.SKY_BLUE)

    StateManager.draw()

    love.graphics.setCanvas()

    -- Scale canvas to window with letterboxing
    Colors.set(Colors.SNOW_WHITE)
    local scale_x = love.graphics.getWidth() / GAME_WIDTH
    local scale_y = love.graphics.getHeight() / GAME_HEIGHT
    local scale = math.min(scale_x, scale_y)

    local offset_x = (love.graphics.getWidth() - GAME_WIDTH * scale) / 2
    local offset_y = (love.graphics.getHeight() - GAME_HEIGHT * scale) / 2

    -- Draw letterbox bars if needed
    if offset_x > 0 or offset_y > 0 then
        love.graphics.setColor(0.05, 0.05, 0.1)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(canvas, offset_x, offset_y, 0, scale, scale)
end

function love.keypressed(key)
    if key == "escape" then
        if StateManager.get_current_name() == "play" then
            StateManager.switch("menu")
        else
            love.event.quit()
        end
    end
    StateManager.keypressed(key)
end

function love.keyreleased(key)
    StateManager.keyreleased(key)
end

function love.resize(w, h)
    -- Window resized, canvas scaling handled in draw
end

-- Expose game dimensions for other modules
function love.getGameDimensions()
    return GAME_WIDTH, GAME_HEIGHT
end
