-- src/ui/sidebar_hud.lua
-- California Games style sidebar HUD
-- Left: Decorative 80s ski art | Right: Game stats

local Colors = require("src.colors")
local Utils = require("src.lib.utils")

local SidebarHUD = {}

-- Background images (loaded on first use)
local bg_left = nil
local bg_right = nil

-- Load background images
local function load_images()
    if not bg_left then
        bg_left = love.graphics.newImage("assets/images/hud_sidebar_background_left.png")
        bg_left:setFilter("nearest", "nearest")  -- Pixel-perfect scaling
    end
    if not bg_right then
        bg_right = love.graphics.newImage("assets/images/hud_sidebar_background_right.png")
        bg_right:setFilter("nearest", "nearest")
    end
end

-- Blocky pixel font - each letter is a 5x7 grid of pixels
local BLOCK_SIZE = 4  -- Size of each "pixel" in the blocky font

-- Character definitions (5 wide x 7 tall, 1 = filled, 0 = empty)
local CHARS = {
    ["0"] = {
        {0,1,1,1,0},
        {1,0,0,0,1},
        {1,0,0,1,1},
        {1,0,1,0,1},
        {1,1,0,0,1},
        {1,0,0,0,1},
        {0,1,1,1,0},
    },
    ["1"] = {
        {0,0,1,0,0},
        {0,1,1,0,0},
        {0,0,1,0,0},
        {0,0,1,0,0},
        {0,0,1,0,0},
        {0,0,1,0,0},
        {0,1,1,1,0},
    },
    ["2"] = {
        {0,1,1,1,0},
        {1,0,0,0,1},
        {0,0,0,0,1},
        {0,0,1,1,0},
        {0,1,0,0,0},
        {1,0,0,0,0},
        {1,1,1,1,1},
    },
    ["3"] = {
        {0,1,1,1,0},
        {1,0,0,0,1},
        {0,0,0,0,1},
        {0,0,1,1,0},
        {0,0,0,0,1},
        {1,0,0,0,1},
        {0,1,1,1,0},
    },
    ["4"] = {
        {0,0,0,1,0},
        {0,0,1,1,0},
        {0,1,0,1,0},
        {1,0,0,1,0},
        {1,1,1,1,1},
        {0,0,0,1,0},
        {0,0,0,1,0},
    },
    ["5"] = {
        {1,1,1,1,1},
        {1,0,0,0,0},
        {1,1,1,1,0},
        {0,0,0,0,1},
        {0,0,0,0,1},
        {1,0,0,0,1},
        {0,1,1,1,0},
    },
    ["6"] = {
        {0,1,1,1,0},
        {1,0,0,0,0},
        {1,0,0,0,0},
        {1,1,1,1,0},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {0,1,1,1,0},
    },
    ["7"] = {
        {1,1,1,1,1},
        {0,0,0,0,1},
        {0,0,0,1,0},
        {0,0,1,0,0},
        {0,1,0,0,0},
        {0,1,0,0,0},
        {0,1,0,0,0},
    },
    ["8"] = {
        {0,1,1,1,0},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {0,1,1,1,0},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {0,1,1,1,0},
    },
    ["9"] = {
        {0,1,1,1,0},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {0,1,1,1,1},
        {0,0,0,0,1},
        {0,0,0,0,1},
        {0,1,1,1,0},
    },
    [":"] = {
        {0,0,0,0,0},
        {0,0,1,0,0},
        {0,0,1,0,0},
        {0,0,0,0,0},
        {0,0,1,0,0},
        {0,0,1,0,0},
        {0,0,0,0,0},
    },
    ["."] = {
        {0,0,0,0,0},
        {0,0,0,0,0},
        {0,0,0,0,0},
        {0,0,0,0,0},
        {0,0,0,0,0},
        {0,1,1,0,0},
        {0,1,1,0,0},
    },
    ["+"] = {
        {0,0,0,0,0},
        {0,0,1,0,0},
        {0,0,1,0,0},
        {1,1,1,1,1},
        {0,0,1,0,0},
        {0,0,1,0,0},
        {0,0,0,0,0},
    },
    ["m"] = {
        {0,0,0,0,0},
        {0,0,0,0,0},
        {1,1,0,1,1},
        {1,0,1,0,1},
        {1,0,1,0,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
    },
    ["s"] = {
        {0,0,0,0,0},
        {0,0,0,0,0},
        {0,1,1,1,0},
        {1,0,0,0,0},
        {0,1,1,1,0},
        {0,0,0,0,1},
        {1,1,1,1,0},
    },
    ["d"] = {
        {0,0,0,0,1},
        {0,0,0,0,1},
        {0,1,1,0,1},
        {1,0,0,1,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {0,1,1,1,1},
    },
    [" "] = {
        {0,0,0,0,0},
        {0,0,0,0,0},
        {0,0,0,0,0},
        {0,0,0,0,0},
        {0,0,0,0,0},
        {0,0,0,0,0},
        {0,0,0,0,0},
    },
    ["T"] = {
        {1,1,1,1,1},
        {0,0,1,0,0},
        {0,0,1,0,0},
        {0,0,1,0,0},
        {0,0,1,0,0},
        {0,0,1,0,0},
        {0,0,1,0,0},
    },
    ["I"] = {
        {0,1,1,1,0},
        {0,0,1,0,0},
        {0,0,1,0,0},
        {0,0,1,0,0},
        {0,0,1,0,0},
        {0,0,1,0,0},
        {0,1,1,1,0},
    },
    ["M"] = {
        {1,0,0,0,1},
        {1,1,0,1,1},
        {1,0,1,0,1},
        {1,0,1,0,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
    },
    ["E"] = {
        {1,1,1,1,1},
        {1,0,0,0,0},
        {1,0,0,0,0},
        {1,1,1,1,0},
        {1,0,0,0,0},
        {1,0,0,0,0},
        {1,1,1,1,1},
    },
    ["S"] = {
        {0,1,1,1,0},
        {1,0,0,0,1},
        {1,0,0,0,0},
        {0,1,1,1,0},
        {0,0,0,0,1},
        {1,0,0,0,1},
        {0,1,1,1,0},
    },
    ["P"] = {
        {1,1,1,1,0},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,1,1,1,0},
        {1,0,0,0,0},
        {1,0,0,0,0},
        {1,0,0,0,0},
    },
    ["D"] = {
        {1,1,1,1,0},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,1,1,1,0},
    },
    ["G"] = {
        {0,1,1,1,0},
        {1,0,0,0,1},
        {1,0,0,0,0},
        {1,0,1,1,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {0,1,1,1,0},
    },
    ["A"] = {
        {0,1,1,1,0},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,1,1,1,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
    },
    ["N"] = {
        {1,0,0,0,1},
        {1,1,0,0,1},
        {1,0,1,0,1},
        {1,0,1,0,1},
        {1,0,0,1,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
    },
    ["C"] = {
        {0,1,1,1,0},
        {1,0,0,0,1},
        {1,0,0,0,0},
        {1,0,0,0,0},
        {1,0,0,0,0},
        {1,0,0,0,1},
        {0,1,1,1,0},
    },
    ["O"] = {
        {0,1,1,1,0},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {0,1,1,1,0},
    },
    ["R"] = {
        {1,1,1,1,0},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,1,1,1,0},
        {1,0,1,0,0},
        {1,0,0,1,0},
        {1,0,0,0,1},
    },
    ["U"] = {
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {0,1,1,1,0},
    },
    ["K"] = {
        {1,0,0,0,1},
        {1,0,0,1,0},
        {1,0,1,0,0},
        {1,1,0,0,0},
        {1,0,1,0,0},
        {1,0,0,1,0},
        {1,0,0,0,1},
    },
    ["L"] = {
        {1,0,0,0,0},
        {1,0,0,0,0},
        {1,0,0,0,0},
        {1,0,0,0,0},
        {1,0,0,0,0},
        {1,0,0,0,0},
        {1,1,1,1,1},
    },
    ["Y"] = {
        {1,0,0,0,1},
        {1,0,0,0,1},
        {0,1,0,1,0},
        {0,0,1,0,0},
        {0,0,1,0,0},
        {0,0,1,0,0},
        {0,0,1,0,0},
    },
    ["W"] = {
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,0,1,0,1},
        {1,0,1,0,1},
        {1,1,0,1,1},
        {1,0,0,0,1},
    },
    ["F"] = {
        {1,1,1,1,1},
        {1,0,0,0,0},
        {1,0,0,0,0},
        {1,1,1,1,0},
        {1,0,0,0,0},
        {1,0,0,0,0},
        {1,0,0,0,0},
    },
    ["B"] = {
        {1,1,1,1,0},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,1,1,1,0},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,1,1,1,0},
    },
    ["H"] = {
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,1,1,1,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
    },
}

-- Draw a single blocky character
local function draw_block_char(char, x, y, size, color, shadow_color)
    local pattern = CHARS[char]
    if not pattern then return 0 end

    size = size or BLOCK_SIZE

    -- Draw shadow first
    if shadow_color then
        love.graphics.setColor(shadow_color)
        for row = 1, 7 do
            for col = 1, 5 do
                if pattern[row][col] == 1 then
                    love.graphics.rectangle("fill", x + (col-1)*size + 2, y + (row-1)*size + 2, size, size)
                end
            end
        end
    end

    -- Draw main character
    love.graphics.setColor(color)
    for row = 1, 7 do
        for col = 1, 5 do
            if pattern[row][col] == 1 then
                love.graphics.rectangle("fill", x + (col-1)*size, y + (row-1)*size, size, size)
            end
        end
    end

    return 6 * size  -- Character width + spacing
end

-- Draw blocky text string
local function draw_block_text(text, x, y, size, color, shadow_color, centered_width)
    size = size or BLOCK_SIZE
    local char_width = 6 * size
    local total_width = #text * char_width

    if centered_width then
        x = x + (centered_width - total_width) / 2
    end

    for i = 1, #text do
        local char = text:sub(i, i)
        draw_block_char(char, x + (i-1) * char_width, y, size, color, shadow_color)
    end
end

-- Draw detailed mountain range
local function draw_mountains(x, y, width, height)
    -- Back mountains (darker, further away)
    love.graphics.setColor(0.12, 0.12, 0.18, 1)
    local back_peaks = {
        x, y + height,
        x + width * 0.15, y + height * 0.3,
        x + width * 0.3, y + height * 0.6,
        x + width * 0.45, y + height * 0.15,
        x + width * 0.6, y + height * 0.5,
        x + width * 0.75, y + height * 0.25,
        x + width * 0.9, y + height * 0.45,
        x + width, y + height,
    }
    love.graphics.polygon("fill", back_peaks)

    -- Front mountains (lighter, closer)
    love.graphics.setColor(0.18, 0.18, 0.25, 1)
    local front_peaks = {
        x, y + height,
        x + width * 0.1, y + height * 0.5,
        x + width * 0.25, y + height * 0.2,
        x + width * 0.4, y + height * 0.55,
        x + width * 0.55, y + height * 0.1,
        x + width * 0.7, y + height * 0.4,
        x + width * 0.85, y + height * 0.25,
        x + width, y + height * 0.5,
        x + width, y + height,
    }
    love.graphics.polygon("fill", front_peaks)

    -- Snow caps
    love.graphics.setColor(0.9, 0.92, 0.95, 0.8)
    -- Peak 1
    love.graphics.polygon("fill",
        x + width * 0.25, y + height * 0.2,
        x + width * 0.22, y + height * 0.32,
        x + width * 0.28, y + height * 0.32
    )
    -- Peak 2 (main peak)
    love.graphics.polygon("fill",
        x + width * 0.55, y + height * 0.1,
        x + width * 0.50, y + height * 0.25,
        x + width * 0.60, y + height * 0.25
    )
    -- Peak 3
    love.graphics.polygon("fill",
        x + width * 0.85, y + height * 0.25,
        x + width * 0.82, y + height * 0.35,
        x + width * 0.88, y + height * 0.35
    )
end

-- Draw pine tree silhouette
local function draw_pine_tree(x, y, height, color)
    love.graphics.setColor(color)
    local width = height * 0.6

    -- Tree layers (triangles stacked)
    for i = 0, 2 do
        local layer_y = y + i * (height * 0.25)
        local layer_height = height * 0.4
        local layer_width = width * (1 - i * 0.2)
        love.graphics.polygon("fill",
            x, layer_y + layer_height,
            x + layer_width / 2, layer_y,
            x + layer_width, layer_y + layer_height
        )
    end

    -- Trunk
    love.graphics.rectangle("fill", x + width * 0.35, y + height * 0.85, width * 0.3, height * 0.15)
end

-- Draw 80s style sun with gradient stripes
local function draw_80s_sun(x, y, radius)
    -- Sun circle segments (gradient effect)
    local colors = {
        {1, 0.2, 0.6, 1},     -- Hot pink
        {1, 0.4, 0.2, 1},     -- Orange
        {1, 0.7, 0, 1},       -- Yellow-orange
        {1, 0.85, 0.2, 1},    -- Yellow
    }

    for i = #colors, 1, -1 do
        love.graphics.setColor(colors[i])
        local segment_radius = radius * (i / #colors)
        love.graphics.circle("fill", x, y, segment_radius)
    end

    -- Horizontal stripe cutouts (80s aesthetic)
    love.graphics.setColor(0.02, 0.02, 0.05, 1)
    for stripe = 1, 5 do
        local stripe_y = y + stripe * (radius * 0.15)
        local stripe_width = math.sqrt(radius * radius - (stripe * radius * 0.15)^2) * 2
        if stripe_width > 0 then
            love.graphics.rectangle("fill", x - stripe_width/2, stripe_y, stripe_width, 3)
        end
    end
end

-- Draw skier silhouette doing a trick
local function draw_skier_silhouette(x, y, scale)
    love.graphics.setColor(0.1, 0.1, 0.15, 1)
    scale = scale or 1

    -- Body (leaning forward in tuck)
    love.graphics.ellipse("fill", x, y, 8 * scale, 12 * scale)

    -- Head
    love.graphics.circle("fill", x + 6 * scale, y - 10 * scale, 5 * scale)

    -- Skis (crossed/jumping)
    love.graphics.setLineWidth(3 * scale)
    love.graphics.line(x - 15 * scale, y + 8 * scale, x + 20 * scale, y + 15 * scale)
    love.graphics.line(x - 12 * scale, y + 15 * scale, x + 18 * scale, y + 5 * scale)
    love.graphics.setLineWidth(1)

    -- Poles
    love.graphics.setLineWidth(2 * scale)
    love.graphics.line(x - 5 * scale, y - 5 * scale, x - 18 * scale, y + 20 * scale)
    love.graphics.line(x + 8 * scale, y - 5 * scale, x + 22 * scale, y + 15 * scale)
    love.graphics.setLineWidth(1)
end

-- Draw falling snow particles
local function draw_snow_particles(x, width, height, time)
    love.graphics.setColor(1, 1, 1, 0.6)
    local seed = 12345
    for i = 1, 20 do
        seed = (seed * 1103515245 + 12345) % 2147483648
        local px = x + (seed % width)
        seed = (seed * 1103515245 + 12345) % 2147483648
        local base_y = seed % height
        local py = (base_y + time * 30 * (1 + (i % 3) * 0.3)) % height
        local size = 2 + (i % 3)
        love.graphics.rectangle("fill", px, py, size, size)
    end
end

-- Draw 80s geometric pattern
local function draw_80s_pattern(x, y, width, height)
    -- Diagonal lines
    love.graphics.setColor(Colors.HOT_PINK[1], Colors.HOT_PINK[2], Colors.HOT_PINK[3], 0.15)
    love.graphics.setLineWidth(2)
    for i = 0, 10 do
        local offset = i * 25
        love.graphics.line(x + offset, y, x, y + offset)
        love.graphics.line(x + width - offset, y + height, x + width, y + height - offset)
    end

    -- Triangle accents
    love.graphics.setColor(Colors.ELECTRIC_BLUE[1], Colors.ELECTRIC_BLUE[2], Colors.ELECTRIC_BLUE[3], 0.1)
    love.graphics.polygon("fill", x + 20, y + height - 80, x + 50, y + height - 40, x + 80, y + height - 80)
    love.graphics.setLineWidth(1)
end

-- Draw ski lodge silhouette
local function draw_lodge(x, y, width, height)
    love.graphics.setColor(0.08, 0.08, 0.12, 1)

    -- Main building
    love.graphics.rectangle("fill", x, y + height * 0.4, width, height * 0.6)

    -- Peaked roof
    love.graphics.polygon("fill",
        x - 5, y + height * 0.4,
        x + width / 2, y,
        x + width + 5, y + height * 0.4
    )

    -- Chimney
    love.graphics.rectangle("fill", x + width * 0.7, y - 10, width * 0.15, height * 0.3)

    -- Windows (lit up)
    love.graphics.setColor(1, 0.9, 0.5, 0.7)
    love.graphics.rectangle("fill", x + width * 0.15, y + height * 0.55, width * 0.2, height * 0.2)
    love.graphics.rectangle("fill", x + width * 0.45, y + height * 0.55, width * 0.2, height * 0.2)
    love.graphics.rectangle("fill", x + width * 0.3, y + height * 0.8, width * 0.25, height * 0.15)
end

-- Draw the left sidebar (Decorative art)
function SidebarHUD.draw_left(x, width, height)
    load_images()

    -- Background fill (in case image doesn't cover everything)
    love.graphics.setColor(0.02, 0.02, 0.05, 1)
    love.graphics.rectangle("fill", x, 0, width, height)

    -- Draw background image scaled to fit width
    if bg_left then
        local img_width = bg_left:getWidth()
        local img_height = bg_left:getHeight()
        local scale = width / img_width

        -- Center vertically if scaled image is shorter than sidebar
        local scaled_height = img_height * scale
        local y_offset = (height - scaled_height) / 2
        if y_offset < 0 then y_offset = 0 end

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(bg_left, x, y_offset, 0, scale, scale)
    end

    -- Title text overlay
    draw_block_text("SKI", x, 450, 5, Colors.HOT_PINK, {0,0,0,1}, width)
    draw_block_text("FREE", x, 495, 5, Colors.ELECTRIC_BLUE, {0,0,0,1}, width)
    draw_block_text("OR", x, 540, 4, Colors.BRIGHT_YELLOW, {0,0,0,1}, width)
    draw_block_text("DIE", x, 575, 5, Colors.MINT_GREEN, {0,0,0,1}, width)

    -- Insert Coin at bottom
    draw_block_text("INSERT", x, height - 90, 3, Colors.ELECTRIC_BLUE, {0,0,0,1}, width)
    draw_block_text("COIN", x, height - 55, 3, Colors.HOT_PINK, {0,0,0,1}, width)
end

-- Draw the right sidebar (Stats)
function SidebarHUD.draw_right(x, width, height, state)
    load_images()

    -- Background fill
    love.graphics.setColor(0.02, 0.02, 0.05, 1)
    love.graphics.rectangle("fill", x, 0, width, height)

    -- Draw background image scaled to fit width
    if bg_right then
        local img_width = bg_right:getWidth()
        local img_height = bg_right:getHeight()
        local scale = width / img_width

        -- Center vertically if scaled image is shorter than sidebar
        local scaled_height = img_height * scale
        local y_offset = (height - scaled_height) / 2
        if y_offset < 0 then y_offset = 0 end

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(bg_right, x, y_offset, 0, scale, scale)
    end

    local y = 120

    -- GROUP 1: Time, Penalty, Gates

    -- TIME
    draw_block_text("TIME", x, y, 4, Colors.SNOW_WHITE, {0,0,0,1}, width)
    y = y + 35
    local total_time = state.elapsed_time + (state.gates_missed or 0) * 3
    draw_block_text(Utils.format_time(total_time), x, y, 5, Colors.HOT_PINK, {0,0,0,1}, width)
    y = y + 60

    -- TOTAL PENALTY
    draw_block_text("PENALTY", x, y, 3, Colors.SNOW_WHITE, {0,0,0,1}, width)
    y = y + 28
    local penalty_seconds = (state.gates_missed or 0) * 3
    local penalty_color = penalty_seconds > 0 and Colors.HOT_PINK or Colors.SNOW_WHITE
    draw_block_text(string.format("+%ds", penalty_seconds), x, y, 4, penalty_color, {0,0,0,1}, width)
    y = y + 55

    -- GATES
    draw_block_text("GATES", x, y, 4, Colors.SNOW_WHITE, {0,0,0,1}, width)
    y = y + 35
    draw_block_text(string.format("%d", state.gates_passed or 0), x, y, 5, Colors.MINT_GREEN, {0,0,0,1}, width)
    y = y + 90

    -- GROUP 2: Speed, Distance (bigger space before this group)

    -- SPEED (MPH)
    draw_block_text("SPEED", x, y, 4, Colors.SNOW_WHITE, {0,0,0,1}, width)
    y = y + 35
    local speed_color = Colors.ELECTRIC_BLUE
    if state.speed_ratio and state.speed_ratio > 0.8 then
        speed_color = Colors.BRIGHT_YELLOW
    end
    draw_block_text(string.format("%.0f", state.speed_mph or 0), x, y, 5, speed_color, {0,0,0,1}, width)
    y = y + 45
    draw_block_text("MPH", x, y, 3, Colors.SNOW_WHITE, {0,0,0,1}, width)
    y = y + 60

    -- DISTANCE
    draw_block_text("DIST", x, y, 4, Colors.SNOW_WHITE, {0,0,0,1}, width)
    y = y + 35
    draw_block_text(string.format("%dm", math.floor((state.distance or 0) / 10)), x, y, 5, Colors.ELECTRIC_BLUE, {0,0,0,1}, width)
    y = y + 60

    -- TUCK indicator
    if state.is_tucking then
        -- Flashing effect
        if math.floor(love.timer.getTime() * 4) % 2 == 0 then
            draw_block_text("TUCK", x, y, 5, Colors.BRIGHT_YELLOW, {0,0,0,1}, width)
        end
    end

    -- Mode indicator at bottom
    local mode_text = state.mode == "endless" and "ENDLESS" or "TRIAL"
    draw_block_text(mode_text, x, height - 50, 3, Colors.MINT_GREEN, {0,0,0,1}, width)
end

-- Main draw function
function SidebarHUD.draw(left_x, left_width, right_x, right_width, window_height, state)
    SidebarHUD.draw_left(left_x, left_width, window_height)
    SidebarHUD.draw_right(right_x, right_width, window_height, state)
end

return SidebarHUD
