-- src/states/highscores_state.lua
-- High scores / leaderboard display with retro arcade styling

local StateManager = require("src.core.state_manager")
local Colors = require("src.colors")
local Config = require("src.core.config")
local Leaderboard = require("src.core.leaderboard")
local Music = require("src.lib.music")

local HighScoresState = {}

local GAME_WIDTH = Config.GAME_WIDTH
local GAME_HEIGHT = Config.GAME_HEIGHT

-- State
local current_mode = "time_trial"
local mode_selection = 1
local scroll_offset = 0
local flash_timer = 0
local podium_animation = 0
local came_from_entry = false

-- Medal colors for top 3
local medal_colors = {
    Colors.BRIGHT_YELLOW,  -- Gold
    {0.75, 0.75, 0.75, 1}, -- Silver
    {0.8, 0.5, 0.2, 1}     -- Bronze
}

-- Floating sparkles for top scores
local sparkles = {}

function HighScoresState:enter(params)
    params = params or {}
    current_mode = params.mode or "time_trial"
    mode_selection = (current_mode == "time_trial") and 1 or 2
    came_from_entry = params.from_entry or false
    scroll_offset = 0
    flash_timer = 0
    podium_animation = 0

    -- Create sparkles for celebration
    sparkles = {}
    for i = 1, 30 do
        table.insert(sparkles, {
            x = math.random(0, GAME_WIDTH),
            y = math.random(0, GAME_HEIGHT / 2),
            vx = math.random(-10, 10),
            vy = math.random(-20, 0),
            size = math.random(1, 2),
            life = math.random(3, 6),
            max_life = math.random(3, 6)
        })
    end

    -- Play awards music if coming from name entry, otherwise menu music
    if came_from_entry then
        Music.play("awards")
    else
        Music.play("menu")
    end
end

function HighScoresState:exit()
    -- Clear new flags when leaving
    Leaderboard.clear_new_flags()
end

function HighScoresState:update(dt)
    flash_timer = flash_timer + dt
    podium_animation = math.min(podium_animation + dt * 2, 1)

    -- Update sparkles
    for i = #sparkles, 1, -1 do
        local s = sparkles[i]
        s.x = s.x + s.vx * dt
        s.y = s.y + s.vy * dt
        s.vy = s.vy + 30 * dt -- Gravity
        s.life = s.life - dt

        if s.life <= 0 then
            table.remove(sparkles, i)
        end
    end

    -- Continuously spawn new sparkles if coming from entry
    if came_from_entry and math.random() < 0.3 then
        table.insert(sparkles, {
            x = math.random(0, GAME_WIDTH),
            y = 0,
            vx = math.random(-10, 10),
            vy = math.random(-20, 0),
            size = math.random(1, 2),
            life = math.random(3, 6),
            max_life = math.random(3, 6)
        })
    end
end

function HighScoresState:draw()
    -- Background gradient
    for y = 0, GAME_HEIGHT do
        local t = y / GAME_HEIGHT
        local r = 0.05 + t * 0.05
        local g = 0.05 + t * 0.08
        local b = 0.15 + t * 0.1
        love.graphics.setColor(r, g, b)
        love.graphics.line(0, y, GAME_WIDTH, y)
    end

    -- Draw sparkles
    for _, s in ipairs(sparkles) do
        local alpha = math.min(1, s.life / 2)
        local color_idx = math.floor(flash_timer * 4 + s.x) % 4 + 1
        local color = ({Colors.HOT_PINK, Colors.ELECTRIC_BLUE, Colors.BRIGHT_YELLOW, Colors.MINT_GREEN})[color_idx]
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        love.graphics.rectangle("fill", s.x, s.y, s.size, s.size)
    end

    -- Title
    Colors.set(Colors.BRIGHT_YELLOW)
    love.graphics.printf("HIGH SCORES", 0, 10, GAME_WIDTH, "center")

    -- Mode tabs
    self:draw_mode_tabs()

    -- Leaderboard
    self:draw_leaderboard()

    -- Controls
    Colors.set(Colors.SNOW_WHITE)
    love.graphics.printf("TAB: Switch Mode  |  ESC: Back to Menu", 0, GAME_HEIGHT - 14, GAME_WIDTH, "center")
end

function HighScoresState:draw_mode_tabs()
    local tab_y = 25
    local tab_width = 80
    local tab_height = 12
    local tab_spacing = 10
    local total_width = tab_width * 2 + tab_spacing
    local start_x = (GAME_WIDTH - total_width) / 2

    local modes = {"time_trial", "endless"}
    local labels = {"TIME TRIAL", "ENDLESS"}

    for i = 1, 2 do
        local tab_x = start_x + (i - 1) * (tab_width + tab_spacing)
        local is_selected = (mode_selection == i)

        -- Tab background
        if is_selected then
            Colors.set(Colors.HOT_PINK)
        else
            love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
        end
        love.graphics.rectangle("fill", tab_x, tab_y, tab_width, tab_height)

        -- Tab border
        Colors.set(Colors.SNOW_WHITE)
        love.graphics.rectangle("line", tab_x, tab_y, tab_width, tab_height)

        -- Tab label
        if is_selected then
            Colors.set(Colors.BLACK)
        else
            Colors.set(Colors.SNOW_WHITE)
        end
        love.graphics.printf(labels[i], tab_x, tab_y + 2, tab_width, "center")
    end
end

function HighScoresState:draw_leaderboard()
    local scores = Leaderboard.get_scores(current_mode)
    local start_y = 50
    local line_height = 14

    -- Header
    Colors.set(Colors.ELECTRIC_BLUE)
    love.graphics.print("RANK", 20, start_y)
    love.graphics.print("NAME", 80, start_y)
    love.graphics.print("SCORE", GAME_WIDTH - 100, start_y)

    -- Separator line
    Colors.set(Colors.ROCK_GRAY)
    love.graphics.line(10, start_y + 10, GAME_WIDTH - 10, start_y + 10)

    -- Scores
    local list_start_y = start_y + 15

    if #scores == 0 then
        -- No scores yet
        Colors.set(Colors.ROCK_GRAY)
        love.graphics.printf("NO SCORES YET", 0, list_start_y + 30, GAME_WIDTH, "center")
        love.graphics.printf("BE THE FIRST!", 0, list_start_y + 45, GAME_WIDTH, "center")
    else
        for i, entry in ipairs(scores) do
            local y = list_start_y + (i - 1) * line_height
            local is_new = entry.is_new or false
            local rank = i

            -- Highlight new entries
            if is_new then
                local flash = math.floor(flash_timer * 3) % 2 == 0
                if flash then
                    Colors.set(Colors.MINT_GREEN)
                    love.graphics.rectangle("fill", 10, y - 2, GAME_WIDTH - 20, line_height - 2)
                end
            end

            -- Medal/rank display
            if rank <= 3 then
                -- Top 3 get medals with podium animation
                local medal_color = medal_colors[rank]
                Colors.set(medal_color)

                -- Animated entrance for top 3
                local scale = 1
                if podium_animation < 1 then
                    scale = math.min(1, podium_animation * (4 - rank))
                end

                -- Draw medal circle
                love.graphics.circle("fill", 35 + (1 - scale) * 5, y + 5, 6 * scale)

                -- Medal number
                Colors.set(Colors.BLACK)
                love.graphics.printf(tostring(rank), 32 + (1 - scale) * 5, y + 1, 10, "center")
            else
                -- Regular rank number
                if is_new then
                    Colors.set(Colors.BLACK)
                else
                    Colors.set(Colors.ROCK_GRAY)
                end
                love.graphics.printf(string.format("%2d", rank), 20, y, 30, "left")
            end

            -- Name
            if is_new then
                Colors.set(Colors.BLACK)
            elseif rank <= 3 then
                Colors.set(medal_colors[rank])
            else
                Colors.set(Colors.SNOW_WHITE)
            end
            love.graphics.print(entry.name, 80, y)

            -- Score
            local score_text = Leaderboard.format_score(current_mode, entry.score)
            local score_x = GAME_WIDTH - 100

            if is_new then
                Colors.set(Colors.BLACK)
            elseif rank <= 3 then
                Colors.set(medal_colors[rank])
            else
                Colors.set(Colors.ELECTRIC_BLUE)
            end
            love.graphics.print(score_text, score_x, y)

            -- Trophy for #1
            if rank == 1 and podium_animation >= 0.5 then
                local trophy_x = GAME_WIDTH - 25
                local trophy_y = y + 2

                -- Animate trophy with bounce
                local bounce = math.abs(math.sin(flash_timer * 4)) * 2

                -- Trophy cup
                Colors.set(Colors.BRIGHT_YELLOW)
                love.graphics.polygon("fill",
                    trophy_x, trophy_y + 3 - bounce,
                    trophy_x + 3, trophy_y - bounce,
                    trophy_x + 6, trophy_y - bounce,
                    trophy_x + 9, trophy_y + 3 - bounce,
                    trophy_x + 7, trophy_y + 3 - bounce,
                    trophy_x + 7, trophy_y + 6 - bounce,
                    trophy_x + 2, trophy_y + 6 - bounce,
                    trophy_x + 2, trophy_y + 3 - bounce
                )

                -- Trophy base
                love.graphics.rectangle("fill", trophy_x + 1, trophy_y + 6 - bounce, 7, 2)
            end
        end
    end
end

function HighScoresState:keypressed(key)
    if key == "escape" then
        StateManager.switch("menu")
    elseif key == "tab" then
        -- Switch between modes
        mode_selection = mode_selection == 1 and 2 or 1
        current_mode = mode_selection == 1 and "time_trial" or "endless"
        podium_animation = 0 -- Reset animation
    elseif key == "left" then
        mode_selection = 1
        current_mode = "time_trial"
        podium_animation = 0
    elseif key == "right" then
        mode_selection = 2
        current_mode = "endless"
        podium_animation = 0
    end
end

return HighScoresState
