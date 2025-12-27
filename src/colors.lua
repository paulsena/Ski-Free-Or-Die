-- src/colors.lua
-- 80s "Windbreaker" color palette

local Colors = {}

-- Primary Palette
Colors.HOT_PINK = {1, 0.078, 0.576, 1}        -- #FF1493
Colors.ELECTRIC_BLUE = {0, 1, 1, 1}            -- #00FFFF
Colors.BRIGHT_YELLOW = {1, 0.843, 0, 1}        -- #FFD700
Colors.MINT_GREEN = {0, 1, 0.498, 1}           -- #00FF7F
Colors.SNOW_WHITE = {1, 0.98, 0.98, 1}         -- #FFFAFA
Colors.BLACK = {0, 0, 0, 1}                    -- #000000

-- Secondary Palette
Colors.DEEP_PURPLE = {0.58, 0, 0.827, 1}       -- #9400D3
Colors.SUNSET_ORANGE = {1, 0.271, 0, 1}        -- #FF4500
Colors.SKY_BLUE = {0.529, 0.808, 0.922, 1}     -- #87CEEB
Colors.PINE_GREEN = {0.133, 0.545, 0.133, 1}   -- #228B22
Colors.ROCK_GRAY = {0.412, 0.412, 0.412, 1}    -- #696969
Colors.CABIN_BROWN = {0.545, 0.271, 0.075, 1}  -- #8B4513

-- Darker variants for shadows/outlines
Colors.DARK_PINE = {0.08, 0.35, 0.08, 1}       -- Darker pine green
Colors.DARK_BROWN = {0.35, 0.18, 0.05, 1}      -- Darker cabin brown

-- UI Colors
Colors.UI_PANEL_BG = {0, 0, 0, 0.8}            -- #000000CC
Colors.UI_TEXT = {1, 1, 1, 1}                  -- White text

-- Gate States
Colors.GATE_PENDING = Colors.HOT_PINK
Colors.GATE_PASSED = Colors.MINT_GREEN
Colors.GATE_MISSED = Colors.ROCK_GRAY

-- Slope/Snow colors
Colors.SNOW = {0.95, 0.97, 1, 1}               -- Main snow
Colors.SNOW_SHADOW = {0.85, 0.88, 0.92, 1}     -- Ski track shadows

-- Helper function to unpack color for love.graphics.setColor
function Colors.set(color)
    love.graphics.setColor(unpack(color))
end

-- Create a dimmed version of a color
function Colors.dim(color, factor)
    factor = factor or 0.5
    return {color[1] * factor, color[2] * factor, color[3] * factor, color[4] or 1}
end

-- Create a brighter version of a color
function Colors.bright(color, factor)
    factor = factor or 1.3
    return {
        math.min(1, color[1] * factor),
        math.min(1, color[2] * factor),
        math.min(1, color[3] * factor),
        color[4] or 1
    }
end

return Colors
