-- src/states/menu_state.lua
-- Main menu state with 80s retro aesthetic

local StateManager = require("src.core.state_manager")
local Colors = require("src.colors")
local Config = require("src.core.config")
local Music = require("src.lib.music")

local MenuState = {}

local GAME_WIDTH = Config.GAME_WIDTH
local GAME_HEIGHT = Config.GAME_HEIGHT

-- Background image
local background_image = nil

-- Fonts
local menu_font = nil
local hint_font = nil

-- Animation variables
local snow_particles = {}
local menu_selection = 1
local menu_options = {"Time Trial", "Endless Mode", "High Scores", "Quit"}

function MenuState:enter()
    menu_selection = 1

    -- Load background image
    if not background_image then
        background_image = love.graphics.newImage("assets/images/game_main_screen.png")
        background_image:setFilter("nearest", "nearest")
    end

    -- Create fonts
    if not menu_font then
        menu_font = love.graphics.newFont(16)
        hint_font = love.graphics.newFont(10)
    end

    -- Initialize falling snow particles for overlay effect
    snow_particles = {}
    for i = 1, 20 do
        table.insert(snow_particles, {
            x = math.random(0, GAME_WIDTH),
            y = math.random(0, GAME_HEIGHT),
            speed = math.random(15, 35),
            size = math.random(1, 2)
        })
    end

    -- Play menu music
    Music.play("menu")
end

function MenuState:exit()
end

function MenuState:update(dt)
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
    -- Draw background image scaled to fit game window
    love.graphics.setColor(1, 1, 1)
    local img_width = background_image:getWidth()
    local img_height = background_image:getHeight()
    local scale_x = GAME_WIDTH / img_width
    local scale_y = GAME_HEIGHT / img_height
    love.graphics.draw(background_image, 0, 0, 0, scale_x, scale_y)

    -- Draw subtle snow particles overlay
    love.graphics.setColor(1, 1, 1, 0.7)
    for _, p in ipairs(snow_particles) do
        love.graphics.rectangle("fill", p.x, p.y, p.size, p.size)
    end

    -- Draw menu options with drop shadows (positioned in lower portion of image)
    love.graphics.setFont(menu_font)
    local menu_start_y = 355
    for i, option in ipairs(menu_options) do
        local y = menu_start_y + (i - 1) * 28
        local is_selected = (i == menu_selection)

        -- Draw thick outline/shadow (multiple passes for bold shadow)
        love.graphics.setColor(0, 0, 0, 1)
        for ox = -2, 2 do
            for oy = -2, 2 do
                if ox ~= 0 or oy ~= 0 then
                    love.graphics.printf(option, ox, y + oy, GAME_WIDTH, "center")
                end
            end
        end

        -- Draw selection arrows with outline
        if is_selected then
            love.graphics.setColor(0, 0, 0, 1)
            for ox = -2, 2 do
                for oy = -2, 2 do
                    if ox ~= 0 or oy ~= 0 then
                        love.graphics.print(">", 70 + ox, y + oy)
                        love.graphics.print("<", 245 + ox, y + oy)
                    end
                end
            end
        end

        -- Draw main text
        if is_selected then
            Colors.set(Colors.BRIGHT_YELLOW)
            love.graphics.print(">", 70, y)
            love.graphics.print("<", 245, y)
        else
            Colors.set(Colors.SNOW_WHITE)
        end
        love.graphics.printf(option, 0, y, GAME_WIDTH, "center")
    end

    -- Draw controls hint with drop shadow
    love.graphics.setFont(hint_font)
    local hint_y = 455
    love.graphics.setColor(0, 0, 0, 1)
    for ox = -1, 1 do
        for oy = -1, 1 do
            if ox ~= 0 or oy ~= 0 then
                love.graphics.printf("Arrows: Steer | Down: Tuck | M: Mute", ox, hint_y + oy, GAME_WIDTH, "center")
            end
        end
    end
    love.graphics.setColor(0.9, 0.9, 1, 1)
    love.graphics.printf("Arrows: Steer | Down: Tuck | M: Mute", 0, hint_y, GAME_WIDTH, "center")
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
        -- High Scores
        StateManager.switch("highscores")
    elseif menu_selection == 4 then
        -- Quit
        love.event.quit()
    end
end

return MenuState
