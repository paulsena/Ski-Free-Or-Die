-- src/states/name_entry_state.lua
-- Arcade-style name entry screen for high scores

local StateManager = require("src.core.state_manager")
local Colors = require("src.colors")
local Config = require("src.core.config")
local Leaderboard = require("src.core.leaderboard")
local Music = require("src.lib.music")

local NameEntryState = {}

local GAME_WIDTH = Config.GAME_WIDTH
local GAME_HEIGHT = Config.GAME_HEIGHT

-- Entry state
local entry_data = nil -- {mode, score, rank}
local player_name = ""
local max_name_length = 8
local cursor_pos = 1
local char_selector_index = 1
local blink_timer = 0

-- Character set for selection (arcade style - uppercase letters, numbers, some symbols)
local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .-_"

-- Animation
local star_particles = {}
local flash_timer = 0

-- Blocky retro font rendering
local function draw_blocky_char(char, x, y, size, color)
    size = size or 3
    Colors.set(color or Colors.SNOW_WHITE)

    -- Define pixel patterns for each character (5x7 grid)
    -- 1 = filled pixel, 0 = empty
    local patterns = {
        A = {
            "01110",
            "10001",
            "10001",
            "11111",
            "10001",
            "10001",
            "10001"
        },
        B = {
            "11110",
            "10001",
            "10001",
            "11110",
            "10001",
            "10001",
            "11110"
        },
        C = {
            "01110",
            "10001",
            "10000",
            "10000",
            "10000",
            "10001",
            "01110"
        },
        D = {
            "11110",
            "10001",
            "10001",
            "10001",
            "10001",
            "10001",
            "11110"
        },
        E = {
            "11111",
            "10000",
            "10000",
            "11110",
            "10000",
            "10000",
            "11111"
        },
        F = {
            "11111",
            "10000",
            "10000",
            "11110",
            "10000",
            "10000",
            "10000"
        },
        G = {
            "01110",
            "10001",
            "10000",
            "10111",
            "10001",
            "10001",
            "01110"
        },
        H = {
            "10001",
            "10001",
            "10001",
            "11111",
            "10001",
            "10001",
            "10001"
        },
        I = {
            "11111",
            "00100",
            "00100",
            "00100",
            "00100",
            "00100",
            "11111"
        },
        J = {
            "11111",
            "00010",
            "00010",
            "00010",
            "00010",
            "10010",
            "01100"
        },
        K = {
            "10001",
            "10010",
            "10100",
            "11000",
            "10100",
            "10010",
            "10001"
        },
        L = {
            "10000",
            "10000",
            "10000",
            "10000",
            "10000",
            "10000",
            "11111"
        },
        M = {
            "10001",
            "11011",
            "10101",
            "10101",
            "10001",
            "10001",
            "10001"
        },
        N = {
            "10001",
            "11001",
            "10101",
            "10101",
            "10011",
            "10001",
            "10001"
        },
        O = {
            "01110",
            "10001",
            "10001",
            "10001",
            "10001",
            "10001",
            "01110"
        },
        P = {
            "11110",
            "10001",
            "10001",
            "11110",
            "10000",
            "10000",
            "10000"
        },
        Q = {
            "01110",
            "10001",
            "10001",
            "10001",
            "10101",
            "10010",
            "01101"
        },
        R = {
            "11110",
            "10001",
            "10001",
            "11110",
            "10100",
            "10010",
            "10001"
        },
        S = {
            "01110",
            "10001",
            "10000",
            "01110",
            "00001",
            "10001",
            "01110"
        },
        T = {
            "11111",
            "00100",
            "00100",
            "00100",
            "00100",
            "00100",
            "00100"
        },
        U = {
            "10001",
            "10001",
            "10001",
            "10001",
            "10001",
            "10001",
            "01110"
        },
        V = {
            "10001",
            "10001",
            "10001",
            "10001",
            "10001",
            "01010",
            "00100"
        },
        W = {
            "10001",
            "10001",
            "10001",
            "10101",
            "10101",
            "11011",
            "10001"
        },
        X = {
            "10001",
            "10001",
            "01010",
            "00100",
            "01010",
            "10001",
            "10001"
        },
        Y = {
            "10001",
            "10001",
            "01010",
            "00100",
            "00100",
            "00100",
            "00100"
        },
        Z = {
            "11111",
            "00001",
            "00010",
            "00100",
            "01000",
            "10000",
            "11111"
        },
        ["0"] = {
            "01110",
            "10001",
            "10011",
            "10101",
            "11001",
            "10001",
            "01110"
        },
        ["1"] = {
            "00100",
            "01100",
            "00100",
            "00100",
            "00100",
            "00100",
            "01110"
        },
        ["2"] = {
            "01110",
            "10001",
            "00001",
            "00010",
            "00100",
            "01000",
            "11111"
        },
        ["3"] = {
            "11111",
            "00010",
            "00100",
            "00010",
            "00001",
            "10001",
            "01110"
        },
        ["4"] = {
            "00010",
            "00110",
            "01010",
            "10010",
            "11111",
            "00010",
            "00010"
        },
        ["5"] = {
            "11111",
            "10000",
            "11110",
            "00001",
            "00001",
            "10001",
            "01110"
        },
        ["6"] = {
            "00110",
            "01000",
            "10000",
            "11110",
            "10001",
            "10001",
            "01110"
        },
        ["7"] = {
            "11111",
            "00001",
            "00010",
            "00100",
            "01000",
            "01000",
            "01000"
        },
        ["8"] = {
            "01110",
            "10001",
            "10001",
            "01110",
            "10001",
            "10001",
            "01110"
        },
        ["9"] = {
            "01110",
            "10001",
            "10001",
            "01111",
            "00001",
            "00010",
            "01100"
        },
        [" "] = {
            "00000",
            "00000",
            "00000",
            "00000",
            "00000",
            "00000",
            "00000"
        },
        ["."] = {
            "00000",
            "00000",
            "00000",
            "00000",
            "00000",
            "01100",
            "01100"
        },
        ["-"] = {
            "00000",
            "00000",
            "00000",
            "11111",
            "00000",
            "00000",
            "00000"
        },
        ["_"] = {
            "00000",
            "00000",
            "00000",
            "00000",
            "00000",
            "00000",
            "11111"
        }
    }

    local pattern = patterns[char]
    if not pattern then
        pattern = patterns[" "] -- Default to space for unknown chars
    end

    -- Draw the character pixel by pixel
    for row = 1, 7 do
        for col = 1, 5 do
            if pattern[row]:sub(col, col) == "1" then
                love.graphics.rectangle("fill",
                    x + (col - 1) * size,
                    y + (row - 1) * size,
                    size - 1, -- Small gap between pixels
                    size - 1
                )
            end
        end
    end
end

-- Draw a blocky string
local function draw_blocky_string(text, x, y, size, color, spacing)
    spacing = spacing or 1
    local char_width = 5 * size + spacing
    for i = 1, #text do
        local char = text:sub(i, i)
        draw_blocky_char(char, x + (i - 1) * char_width, y, size, color)
    end
end

-- Get width of a blocky string
local function get_blocky_string_width(text, size, spacing)
    spacing = spacing or 1
    local char_width = 5 * size + spacing
    return #text * char_width - spacing
end

function NameEntryState:enter(params)
    entry_data = params or {}
    player_name = ""
    cursor_pos = 1
    char_selector_index = 1
    blink_timer = 0
    flash_timer = 0

    -- Create star particles for celebration
    star_particles = {}
    for i = 1, 50 do
        table.insert(star_particles, {
            x = math.random(0, GAME_WIDTH),
            y = math.random(0, GAME_HEIGHT),
            vx = math.random(-30, 30),
            vy = math.random(-30, 30),
            size = math.random(1, 3),
            color = ({Colors.HOT_PINK, Colors.ELECTRIC_BLUE, Colors.BRIGHT_YELLOW, Colors.MINT_GREEN})[math.random(1, 4)],
            life = math.random(2, 5)
        })
    end

    -- Play awards music
    Music.play("awards")
end

function NameEntryState:exit()
end

function NameEntryState:update(dt)
    blink_timer = blink_timer + dt
    flash_timer = flash_timer + dt

    -- Update star particles
    for i = #star_particles, 1, -1 do
        local p = star_particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt

        if p.life <= 0 then
            table.remove(star_particles, i)
        end
    end
end

function NameEntryState:draw()
    -- Background
    love.graphics.setColor(0.05, 0.05, 0.15)
    love.graphics.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)

    -- Draw star particles
    for _, p in ipairs(star_particles) do
        local alpha = math.min(1, p.life / 2)
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.rectangle("fill", p.x, p.y, p.size, p.size)
    end

    -- Title with flash
    local title_y = 20
    local title_colors = {Colors.HOT_PINK, Colors.ELECTRIC_BLUE, Colors.BRIGHT_YELLOW}
    local title_color = title_colors[math.floor(flash_timer * 3) % 3 + 1]

    local title_text = "NEW HIGH SCORE!"
    local title_width = get_blocky_string_width(title_text, 2, 2)
    draw_blocky_string(title_text, (GAME_WIDTH - title_width) / 2, title_y, 2, title_color, 2)

    -- Rank display
    Colors.set(Colors.MINT_GREEN)
    local rank_text = string.format("RANK #%d", entry_data.rank or 1)
    love.graphics.printf(rank_text, 0, title_y + 30, GAME_WIDTH, "center")

    -- Score display
    Colors.set(Colors.BRIGHT_YELLOW)
    local score_text = Leaderboard.format_score(entry_data.mode, entry_data.score)
    love.graphics.printf(score_text, 0, title_y + 45, GAME_WIDTH, "center")

    -- Instructions
    Colors.set(Colors.SNOW_WHITE)
    love.graphics.printf("ENTER YOUR NAME", 0, 85, GAME_WIDTH, "center")

    -- Name entry display
    local name_y = 105
    local char_size = 4
    local char_spacing = 3
    local total_name_width = max_name_length * (5 * char_size + char_spacing)
    local name_start_x = (GAME_WIDTH - total_name_width) / 2

    -- Draw name slots
    for i = 1, max_name_length do
        local char_x = name_start_x + (i - 1) * (5 * char_size + char_spacing)

        -- Draw the character or underscore
        local char = " "
        if i <= #player_name then
            char = player_name:sub(i, i)
        end

        local char_color = Colors.SNOW_WHITE
        if i == cursor_pos then
            char_color = Colors.BRIGHT_YELLOW
        end

        if char == " " and i <= cursor_pos then
            -- Draw blinking underscore for current position
            if math.floor(blink_timer * 2) % 2 == 0 then
                draw_blocky_char("_", char_x, name_y, char_size, char_color)
            end
        else
            draw_blocky_char(char, char_x, name_y, char_size, char_color)
        end
    end

    -- Character selector (only for current position)
    if cursor_pos <= max_name_length then
        local selector_y = name_y + 45
        local current_char = charset:sub(char_selector_index, char_selector_index)

        -- Up arrow
        Colors.set(Colors.ELECTRIC_BLUE)
        love.graphics.polygon("fill",
            GAME_WIDTH / 2, selector_y - 15,
            GAME_WIDTH / 2 - 5, selector_y - 8,
            GAME_WIDTH / 2 + 5, selector_y - 8
        )

        -- Selected character
        local sel_char_width = get_blocky_string_width(current_char, 5, 3)
        draw_blocky_char(current_char, (GAME_WIDTH - 5 * 5) / 2, selector_y, 5, Colors.HOT_PINK)

        -- Down arrow
        Colors.set(Colors.ELECTRIC_BLUE)
        love.graphics.polygon("fill",
            GAME_WIDTH / 2, selector_y + 50,
            GAME_WIDTH / 2 - 5, selector_y + 43,
            GAME_WIDTH / 2 + 5, selector_y + 43
        )
    end

    -- Controls
    Colors.set(Colors.SNOW_WHITE)
    love.graphics.printf("UP/DOWN: Select Character", 0, GAME_HEIGHT - 50, GAME_WIDTH, "center")
    love.graphics.printf("LEFT/RIGHT: Move Cursor", 0, GAME_HEIGHT - 38, GAME_WIDTH, "center")
    love.graphics.printf("ENTER: Confirm  |  BACKSPACE: Delete", 0, GAME_HEIGHT - 26, GAME_WIDTH, "center")
end

function NameEntryState:keypressed(key)
    if key == "up" then
        -- Previous character
        char_selector_index = char_selector_index - 1
        if char_selector_index < 1 then
            char_selector_index = #charset
        end
    elseif key == "down" then
        -- Next character
        char_selector_index = char_selector_index + 1
        if char_selector_index > #charset then
            char_selector_index = 1
        end
    elseif key == "left" then
        -- Move cursor left
        if cursor_pos > 1 then
            cursor_pos = cursor_pos - 1
            -- Update selector to match current character
            if cursor_pos <= #player_name then
                local char = player_name:sub(cursor_pos, cursor_pos)
                char_selector_index = charset:find(char) or 1
            end
        end
    elseif key == "right" then
        -- Move cursor right
        if cursor_pos < max_name_length and cursor_pos <= #player_name + 1 then
            cursor_pos = cursor_pos + 1
            -- Update selector to match current character
            if cursor_pos <= #player_name then
                local char = player_name:sub(cursor_pos, cursor_pos)
                char_selector_index = charset:find(char) or 1
            end
        end
    elseif key == "return" or key == "space" then
        -- Add current character
        if cursor_pos <= max_name_length then
            local char = charset:sub(char_selector_index, char_selector_index)

            if cursor_pos <= #player_name then
                -- Replace character
                player_name = player_name:sub(1, cursor_pos - 1) .. char .. player_name:sub(cursor_pos + 1)
            else
                -- Append character
                player_name = player_name .. char
            end

            -- Move to next position
            if cursor_pos < max_name_length then
                cursor_pos = cursor_pos + 1
            end
        end
    elseif key == "backspace" or key == "delete" then
        -- Delete character
        if #player_name > 0 and cursor_pos > 1 then
            player_name = player_name:sub(1, cursor_pos - 2) .. player_name:sub(cursor_pos)
            cursor_pos = cursor_pos - 1
        elseif #player_name > 0 and cursor_pos == 1 then
            player_name = player_name:sub(2)
        end
    elseif key == "escape" then
        -- Submit with default name if empty
        if #player_name == 0 then
            player_name = "AAA"
        end
        self:submit_score()
    end

    -- Check if we have a complete name and user presses enter on last char
    if key == "return" and #player_name >= 3 then
        -- Allow submission
        self:submit_score()
    end
end

function NameEntryState:submit_score()
    -- Trim whitespace from name
    local trimmed_name = player_name:gsub("^%s+", ""):gsub("%s+$", "")

    if #trimmed_name < 1 then
        trimmed_name = "ANON"
    end

    -- Add to leaderboard
    Leaderboard.add(entry_data.mode, trimmed_name, entry_data.score)

    -- Go to high scores screen
    StateManager.switch("highscores", {mode = entry_data.mode, from_entry = true})
end

return NameEntryState
