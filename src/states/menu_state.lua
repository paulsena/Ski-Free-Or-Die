-- src/states/menu_state.lua
-- Main menu state with 80s retro aesthetic

local Colors = require("src.colors")
local StateManager = require("src.core.state_manager")
local Music = require("src.lib.music")

local MenuState = {}

local GAME_WIDTH = 320
local GAME_HEIGHT = 180

-- Animation variables
local title_wave = 0
local snow_particles = {}
local menu_selection = 1
local menu_options = {"Start Game", "Endless Mode", "Quit"}

function MenuState:enter()
    menu_selection = 1
    title_wave = 0

    -- Initialize falling snow particles for background
    snow_particles = {}
    for i = 1, 30 do
        table.insert(snow_particles, {
            x = math.random(0, GAME_WIDTH),
            y = math.random(0, GAME_HEIGHT),
            speed = math.random(10, 30),
            size = math.random(1, 2)
        })
    end

    -- Play menu music
    Music.play("menu")
end

function MenuState:exit()
end

function MenuState:update(dt)
    -- Animate title wave
    title_wave = title_wave + dt * 3

    -- Update snow particles
    for _, p in ipairs(snow_particles) do
        p.y = p.y + p.speed * dt
        p.x = p.x + math.sin(p.y * 0.05) * 0.5
        if p.y > GAME_HEIGHT then
            p.y = -5
            p.x = math.random(0, GAME_WIDTH)
        end
    end
end

function MenuState:draw()
    -- Draw gradient sky background
    for y = 0, GAME_HEIGHT do
        local t = y / GAME_HEIGHT
        local r = 0.529 * (1 - t * 0.3)
        local g = 0.808 * (1 - t * 0.2)
        local b = 0.922
        love.graphics.setColor(r, g, b)
        love.graphics.line(0, y, GAME_WIDTH, y)
    end

    -- Draw snow particles
    Colors.set(Colors.SNOW_WHITE)
    for _, p in ipairs(snow_particles) do
        love.graphics.rectangle("fill", p.x, p.y, p.size, p.size)
    end

    -- Draw mountains in background
    love.graphics.setColor(0.7, 0.75, 0.85)
    love.graphics.polygon("fill",
        0, 140,
        60, 80,
        120, 140
    )
    love.graphics.polygon("fill",
        80, 140,
        160, 60,
        240, 140
    )
    love.graphics.polygon("fill",
        200, 140,
        280, 90,
        320, 140
    )

    -- Snow caps on mountains
    Colors.set(Colors.SNOW_WHITE)
    love.graphics.polygon("fill",
        60, 80,
        50, 95,
        70, 95
    )
    love.graphics.polygon("fill",
        160, 60,
        145, 80,
        175, 80
    )
    love.graphics.polygon("fill",
        280, 90,
        268, 105,
        292, 105
    )

    -- Draw snow ground
    Colors.set(Colors.SNOW)
    love.graphics.rectangle("fill", 0, 140, GAME_WIDTH, 40)

    -- Draw title with wave effect
    self:draw_wavy_title("SKI FREE", 60, 25)
    self:draw_wavy_title("OR DIE!", 85, 45)

    -- Draw menu options
    for i, option in ipairs(menu_options) do
        local y = 95 + i * 18
        if i == menu_selection then
            -- Selected item with hot pink
            Colors.set(Colors.HOT_PINK)
            love.graphics.print(">", 100, y)
            love.graphics.print("<", 215, y)
        else
            Colors.set(Colors.SNOW_WHITE)
        end
        love.graphics.printf(option, 0, y, GAME_WIDTH, "center")
    end

    -- Draw controls hint
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.printf("Arrows: Steer | Down: Tuck | M: Mute | ESC: Menu", 0, 168, GAME_WIDTH, "center")
end

function MenuState:draw_wavy_title(text, start_x, y)
    local letters = {}
    local colors = {
        Colors.HOT_PINK,
        Colors.ELECTRIC_BLUE,
        Colors.BRIGHT_YELLOW,
        Colors.MINT_GREEN
    }

    for i = 1, #text do
        local char = text:sub(i, i)
        local wave_offset = math.sin(title_wave + i * 0.5) * 3
        local color = colors[(i - 1) % #colors + 1]

        Colors.set(color)

        -- Draw shadow
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.print(char, start_x + (i - 1) * 10 + 1, y + wave_offset + 1)

        -- Draw letter
        Colors.set(color)
        love.graphics.print(char, start_x + (i - 1) * 10, y + wave_offset)
    end
end

function MenuState:keypressed(key)
    if key == "up" or key == "w" then
        menu_selection = menu_selection - 1
        if menu_selection < 1 then
            menu_selection = #menu_options
        end
    elseif key == "down" or key == "s" then
        menu_selection = menu_selection + 1
        if menu_selection > #menu_options then
            menu_selection = 1
        end
    elseif key == "return" or key == "space" then
        self:select_option()
    elseif key == "m" then
        -- Toggle mute
        if Music.get_volume() > 0 then
            Music.set_volume(0)
        else
            Music.set_volume(0.7)
        end
    end
end

function MenuState:select_option()
    if menu_selection == 1 then
        -- Start Game (Time Trial)
        StateManager.switch("play", {mode = "time_trial"})
    elseif menu_selection == 2 then
        -- Endless Mode
        StateManager.switch("play", {mode = "endless"})
    elseif menu_selection == 3 then
        -- Quit
        love.event.quit()
    end
end

return MenuState
