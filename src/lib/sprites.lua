-- src/lib/sprites.lua
-- Procedural sprite drawing system using Love2D primitives
-- 80s "Windbreaker" aesthetic with chunky pixel-art style

local Colors = require("src.colors")

local Sprites = {}

-- Cached canvases for performance (created on first use)
local sprite_cache = {}

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------

-- Draw a chunky pixel-art style rectangle (integer coords for crisp edges)
local function draw_rect(x, y, w, h, rx, ry)
    rx = rx or 0
    ry = ry or 0
    love.graphics.rectangle("fill", math.floor(x), math.floor(y), w, h, rx, ry)
end

-- Draw a blocky polygon (floor all coordinates)
local function draw_polygon(mode, ...)
    local coords = {...}
    local floored = {}
    for i, v in ipairs(coords) do
        floored[i] = math.floor(v)
    end
    love.graphics.polygon(mode, unpack(floored))
end

-- Create a slightly darker version of a color for shading
local function darken(color, factor)
    factor = factor or 0.7
    return {color[1] * factor, color[2] * factor, color[3] * factor, color[4] or 1}
end

-- Create a slightly lighter version of a color for highlights
local function lighten(color, factor)
    factor = factor or 1.3
    return {
        math.min(1, color[1] * factor),
        math.min(1, color[2] * factor),
        math.min(1, color[3] * factor),
        color[4] or 1
    }
end

--------------------------------------------------------------------------------
-- TREE SPRITES
--------------------------------------------------------------------------------

-- Small Tree: Simple triangular pine with snow caps (~16px)
function Sprites.draw_small_tree(x, y)
    love.graphics.push()
    love.graphics.translate(x, y)

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.15)
    love.graphics.ellipse("fill", 2, 8, 8, 3)

    -- Trunk
    Colors.set(Colors.CABIN_BROWN)
    draw_rect(-2, 2, 4, 10)

    -- Dark trunk edge
    Colors.set(Colors.DARK_BROWN)
    draw_rect(-2, 2, 1, 10)

    -- Back foliage layer (darker for depth)
    Colors.set(Colors.DARK_PINE)
    draw_polygon("fill",
        0, -10,
        -9, 4,
        9, 4
    )

    -- Front foliage layer
    Colors.set(Colors.PINE_GREEN)
    draw_polygon("fill",
        0, -14,
        -7, 0,
        7, 0
    )

    -- Highlight edge (mint green pop)
    Colors.set(Colors.MINT_GREEN)
    draw_polygon("fill",
        0, -14,
        3, -8,
        1, -2
    )

    -- Snow cap on top
    Colors.set(Colors.SNOW_WHITE)
    draw_polygon("fill",
        0, -15,
        -3, -10,
        3, -10
    )

    -- Small snow patches on branches
    love.graphics.ellipse("fill", -4, -4, 2, 1)
    love.graphics.ellipse("fill", 3, -2, 2, 1)

    love.graphics.pop()
end

-- Large Tree: Bigger, multi-tiered pine tree (~26px)
function Sprites.draw_large_tree(x, y)
    love.graphics.push()
    love.graphics.translate(x, y)

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.ellipse("fill", 3, 12, 12, 4)

    -- Trunk
    Colors.set(Colors.CABIN_BROWN)
    draw_rect(-3, 4, 6, 14)

    -- Dark trunk side
    Colors.set(Colors.DARK_BROWN)
    draw_rect(-3, 4, 2, 14)

    -- Bottom tier (darkest, back layer)
    Colors.set(Colors.DARK_PINE)
    draw_polygon("fill",
        0, -6,
        -14, 10,
        14, 10
    )

    -- Middle tier
    Colors.set(Colors.PINE_GREEN)
    draw_polygon("fill",
        0, -14,
        -12, 4,
        12, 4
    )

    -- Top tier (brightest mint green)
    Colors.set(Colors.MINT_GREEN)
    draw_polygon("fill",
        0, -20,
        -8, -4,
        8, -4
    )

    -- Highlight streaks
    love.graphics.setColor(0.2, 0.9, 0.6, 0.8)
    draw_polygon("fill",
        0, -20,
        2, -12,
        0, -8
    )

    -- Snow cap on top
    Colors.set(Colors.SNOW_WHITE)
    draw_polygon("fill",
        0, -21,
        -4, -14,
        4, -14
    )

    -- Snow patches on tiers
    love.graphics.ellipse("fill", -6, -2, 3, 2)
    love.graphics.ellipse("fill", 5, 2, 2.5, 1.5)
    love.graphics.ellipse("fill", -8, 6, 3, 1.5)
    love.graphics.ellipse("fill", 7, 7, 2, 1)

    love.graphics.pop()
end

--------------------------------------------------------------------------------
-- ROCK SPRITE
--------------------------------------------------------------------------------

-- Rock: Gray boulder with highlight/shadow (~16x12px)
function Sprites.draw_rock(x, y)
    love.graphics.push()
    love.graphics.translate(x, y)

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.ellipse("fill", 2, 5, 10, 4)

    -- Main rock body (dark base)
    local rock_dark = darken(Colors.ROCK_GRAY, 0.7)
    love.graphics.setColor(rock_dark)
    draw_polygon("fill",
        -8, 4,
        -7, -2,
        -2, -6,
        6, -4,
        10, 2,
        8, 5
    )

    -- Main rock surface
    Colors.set(Colors.ROCK_GRAY)
    draw_polygon("fill",
        -8, 4,
        -6, -4,
        0, -7,
        8, -3,
        10, 4
    )

    -- Highlight facet (top)
    love.graphics.setColor(0.55, 0.55, 0.6, 1)
    draw_polygon("fill",
        -4, -2,
        0, -5,
        4, -2,
        0, 0
    )

    -- Bright highlight spot
    love.graphics.setColor(0.7, 0.7, 0.75, 1)
    draw_polygon("fill",
        -2, -3,
        1, -4,
        0, -1
    )

    -- Snow cap
    Colors.set(Colors.SNOW_WHITE)
    draw_polygon("fill",
        -3, -5,
        0, -8,
        5, -4,
        0, -3
    )

    love.graphics.pop()
end

--------------------------------------------------------------------------------
-- CABIN SPRITE
--------------------------------------------------------------------------------

-- Cabin: Small ski lodge with colorful roof (~28x24px)
function Sprites.draw_cabin(x, y, roof_color)
    roof_color = roof_color or Colors.HOT_PINK

    love.graphics.push()
    love.graphics.translate(x, y)

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.ellipse("fill", 2, 12, 16, 5)

    -- Cabin body
    Colors.set(Colors.CABIN_BROWN)
    draw_rect(-12, -4, 24, 16)

    -- Wood grain details (horizontal lines)
    Colors.set(Colors.DARK_BROWN)
    love.graphics.setLineWidth(1)
    love.graphics.line(-12, 0, 12, 0)
    love.graphics.line(-12, 4, 12, 4)
    love.graphics.line(-12, 8, 12, 8)

    -- Dark left edge for depth
    draw_rect(-12, -4, 2, 16)

    -- Roof (dark underside)
    local roof_dark = darken(roof_color, 0.6)
    love.graphics.setColor(roof_dark)
    draw_polygon("fill",
        0, -14,
        -16, -4,
        16, -4
    )

    -- Roof (main color)
    love.graphics.setColor(roof_color)
    draw_polygon("fill",
        0, -16,
        -14, -5,
        14, -5
    )

    -- Roof highlight stripe
    local roof_light = lighten(roof_color, 1.2)
    love.graphics.setColor(roof_light)
    draw_polygon("fill",
        0, -16,
        -6, -8,
        6, -8
    )

    -- Snow on roof
    Colors.set(Colors.SNOW_WHITE)
    draw_polygon("fill",
        0, -18,
        -14, -6,
        14, -6
    )

    -- Snow drip effects on edges
    draw_polygon("fill",
        -12, -6,
        -14, -6,
        -13, -2
    )
    draw_polygon("fill",
        10, -6,
        12, -6,
        11, -3
    )
    draw_polygon("fill",
        -6, -6,
        -7, -6,
        -6.5, -3
    )

    -- Door (bright yellow, 80s style)
    Colors.set(Colors.BRIGHT_YELLOW)
    draw_rect(-3, 2, 6, 10)

    -- Door dark edge
    love.graphics.setColor(0.8, 0.6, 0, 1)
    draw_rect(-3, 2, 1, 10)

    -- Door handle
    love.graphics.setColor(0.4, 0.4, 0.45, 1)
    love.graphics.circle("fill", 2, 7, 1)

    -- Window (electric blue glow)
    Colors.set(Colors.ELECTRIC_BLUE)
    draw_rect(5, 0, 5, 5)

    -- Window frame/panes
    love.graphics.setColor(0.4, 0.4, 0.45, 1)
    love.graphics.setLineWidth(1)
    love.graphics.line(7.5, 0, 7.5, 5)
    love.graphics.line(5, 2.5, 10, 2.5)

    -- Chimney
    Colors.set(Colors.ROCK_GRAY)
    draw_rect(6, -14, 4, 6)

    -- Chimney snow cap
    Colors.set(Colors.SNOW_WHITE)
    draw_rect(5, -15, 6, 2)

    -- Smoke puffs from chimney
    love.graphics.setColor(0.9, 0.9, 0.95, 0.6)
    love.graphics.circle("fill", 8, -18, 2)
    love.graphics.circle("fill", 9, -21, 1.5)

    love.graphics.pop()
end

-- Cabin variant with electric blue roof
function Sprites.draw_cabin_blue(x, y)
    Sprites.draw_cabin(x, y, Colors.ELECTRIC_BLUE)
end

-- Cabin variant with hot pink roof
function Sprites.draw_cabin_pink(x, y)
    Sprites.draw_cabin(x, y, Colors.HOT_PINK)
end

--------------------------------------------------------------------------------
-- GATE SPRITES
--------------------------------------------------------------------------------

-- Gate Pole: Slalom pole with alternating stripes (~4x20px)
function Sprites.draw_gate_pole(x, y, color, height)
    color = color or Colors.HOT_PINK
    height = height or 20

    love.graphics.push()
    love.graphics.translate(x, y)

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.15)
    love.graphics.ellipse("fill", 1, height/2 + 2, 3, 2)

    -- Pole stripes (alternating color and white)
    local stripe_height = 4
    local num_stripes = math.ceil(height / stripe_height)

    for i = 0, num_stripes - 1 do
        local stripe_y = -height/2 + i * stripe_height
        if i % 2 == 0 then
            love.graphics.setColor(color)
        else
            Colors.set(Colors.SNOW_WHITE)
        end
        draw_rect(-2, stripe_y, 4, stripe_height)
    end

    -- Pole top ball
    love.graphics.setColor(color)
    love.graphics.circle("fill", 0, -height/2 - 2, 3)

    -- Highlight on ball
    Colors.set(Colors.SNOW_WHITE)
    love.graphics.circle("fill", -1, -height/2 - 3, 1)

    love.graphics.pop()
end

-- Gate Flag: Triangular flag (~12x8px)
function Sprites.draw_gate_flag(x, y, color, direction)
    color = color or Colors.HOT_PINK
    direction = direction or 1  -- 1 = right, -1 = left

    love.graphics.push()
    love.graphics.translate(x, y)

    -- Flag shadow
    love.graphics.setColor(0, 0, 0, 0.2)
    draw_polygon("fill",
        2, 2,
        12 * direction + 2, 5,
        2, 10
    )

    -- Flag body (dark edge for depth)
    local flag_dark = darken(color, 0.7)
    love.graphics.setColor(flag_dark)
    draw_polygon("fill",
        0, 0,
        12 * direction, 4,
        0, 8
    )

    -- Flag front face
    love.graphics.setColor(color)
    draw_polygon("fill",
        0, 0,
        10 * direction, 3,
        0, 6
    )

    -- Highlight stripe
    local flag_light = lighten(color, 1.3)
    love.graphics.setColor(flag_light)
    draw_polygon("fill",
        0, 1,
        5 * direction, 2,
        0, 3
    )

    love.graphics.pop()
end

-- Complete gate with two poles and banner
function Sprites.draw_gate(x, y, width, color)
    color = color or Colors.HOT_PINK
    width = width or 50

    love.graphics.push()
    love.graphics.translate(x, y)

    local pole_height = 20
    local banner_height = 6

    -- Shadows
    love.graphics.setColor(0, 0, 0, 0.15)
    love.graphics.ellipse("fill", -width/2 + 2, 12, 3, 2)
    love.graphics.ellipse("fill", width/2 + 2, 12, 3, 2)

    -- Left pole
    love.graphics.setColor(color)
    draw_rect(-width/2 - 2, -pole_height/2, 4, pole_height, 1, 1)

    -- Right pole
    draw_rect(width/2 - 2, -pole_height/2, 4, pole_height, 1, 1)

    -- Banner between poles
    draw_rect(-width/2, -pole_height/2, width, banner_height, 1, 1)

    -- Banner stripes
    local stripe_width = width / 5
    for i = 0, 4 do
        if i % 2 == 0 then
            Colors.set(Colors.SNOW_WHITE)
        else
            love.graphics.setColor(color)
        end
        draw_rect(-width/2 + i * stripe_width, -pole_height/2, stripe_width, banner_height)
    end

    -- Pole top balls
    love.graphics.setColor(color)
    love.graphics.circle("fill", -width/2, -pole_height/2 - 2, 3)
    love.graphics.circle("fill", width/2, -pole_height/2 - 2, 3)

    -- Highlights on balls
    Colors.set(Colors.SNOW_WHITE)
    love.graphics.circle("fill", -width/2 - 1, -pole_height/2 - 3, 1)
    love.graphics.circle("fill", width/2 - 1, -pole_height/2 - 3, 1)

    love.graphics.pop()
end

--------------------------------------------------------------------------------
-- YETI SPRITE
--------------------------------------------------------------------------------

-- Yeti: Iconic white furry monster (~24x32px)
function Sprites.draw_yeti(x, y, arm_swing, is_lunging)
    arm_swing = arm_swing or 0
    is_lunging = is_lunging or false

    love.graphics.push()
    love.graphics.translate(x, y)

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.ellipse("fill", 0, 16, 16, 6)

    -- Fur body (white/light gray base)
    love.graphics.setColor(0.95, 0.95, 1, 1)
    love.graphics.ellipse("fill", 0, 0, 14, 18)

    -- Fur texture patches (slightly darker for depth)
    love.graphics.setColor(0.85, 0.85, 0.9, 1)
    love.graphics.ellipse("fill", -5, -5, 4, 6)
    love.graphics.ellipse("fill", 6, 2, 3, 5)
    love.graphics.ellipse("fill", -2, 8, 5, 4)

    -- Left arm with swing animation
    love.graphics.push()
    love.graphics.rotate(arm_swing)
    love.graphics.setColor(0.92, 0.92, 0.97, 1)
    love.graphics.ellipse("fill", -14, -2, 6, 10)

    -- Left arm fur detail
    love.graphics.setColor(0.85, 0.85, 0.9, 1)
    love.graphics.ellipse("fill", -12, 0, 2, 4)

    -- Left claws
    love.graphics.setColor(0.3, 0.3, 0.35, 1)
    draw_polygon("fill", -18, 6, -20, 10, -17, 8)
    draw_polygon("fill", -15, 7, -16, 11, -13, 9)
    draw_polygon("fill", -12, 6, -12, 10, -10, 8)
    love.graphics.pop()

    -- Right arm with opposite swing
    love.graphics.push()
    love.graphics.rotate(-arm_swing)
    love.graphics.setColor(0.92, 0.92, 0.97, 1)
    love.graphics.ellipse("fill", 14, -2, 6, 10)

    -- Right arm fur detail
    love.graphics.setColor(0.85, 0.85, 0.9, 1)
    love.graphics.ellipse("fill", 12, 0, 2, 4)

    -- Right claws
    love.graphics.setColor(0.3, 0.3, 0.35, 1)
    draw_polygon("fill", 18, 6, 20, 10, 17, 8)
    draw_polygon("fill", 15, 7, 16, 11, 13, 9)
    draw_polygon("fill", 12, 6, 12, 10, 10, 8)
    love.graphics.pop()

    -- Head
    love.graphics.setColor(0.95, 0.95, 1, 1)
    love.graphics.ellipse("fill", 0, -22, 10, 12)

    -- Head fur texture
    love.graphics.setColor(0.88, 0.88, 0.93, 1)
    love.graphics.ellipse("fill", -4, -26, 3, 4)
    love.graphics.ellipse("fill", 5, -20, 2, 3)

    -- Eyes - glowing electric blue (80s vibe!)
    Colors.set(Colors.ELECTRIC_BLUE)
    love.graphics.circle("fill", -4, -24, 3)
    love.graphics.circle("fill", 4, -24, 3)

    -- Eye glow effect (pulsing)
    love.graphics.setColor(0, 1, 1, 0.4)
    love.graphics.circle("fill", -4, -24, 4)
    love.graphics.circle("fill", 4, -24, 4)

    -- Eye pupils (menacing)
    love.graphics.setColor(0.1, 0, 0.2, 1)
    love.graphics.circle("fill", -3, -24, 1.5)
    love.graphics.circle("fill", 5, -24, 1.5)

    -- Angry eyebrows
    love.graphics.setColor(0.7, 0.7, 0.75, 1)
    draw_polygon("fill", -8, -28, -7, -26, -1, -27)
    draw_polygon("fill", 8, -28, 7, -26, 1, -27)

    -- Mouth (open roar)
    love.graphics.setColor(0.2, 0, 0.1, 1)
    love.graphics.ellipse("fill", 0, -16, 6, 4)

    -- Tongue
    Colors.set(Colors.HOT_PINK)
    love.graphics.ellipse("fill", 0, -14, 3, 2)

    -- Fangs
    Colors.set(Colors.SNOW_WHITE)
    draw_polygon("fill", -3, -18, -4, -13, -2, -18)
    draw_polygon("fill", 3, -18, 4, -13, 2, -18)

    -- Legs
    love.graphics.setColor(0.92, 0.92, 0.97, 1)
    love.graphics.ellipse("fill", -6, 14, 5, 8)
    love.graphics.ellipse("fill", 6, 14, 5, 8)

    -- Leg fur detail
    love.graphics.setColor(0.85, 0.85, 0.9, 1)
    love.graphics.ellipse("fill", -4, 12, 2, 3)
    love.graphics.ellipse("fill", 4, 12, 2, 3)

    -- Feet
    love.graphics.setColor(0.85, 0.85, 0.9, 1)
    love.graphics.ellipse("fill", -6, 20, 6, 3)
    love.graphics.ellipse("fill", 6, 20, 6, 3)

    love.graphics.pop()
end

--------------------------------------------------------------------------------
-- SNOW MOUND SPRITE
--------------------------------------------------------------------------------

function Sprites.draw_snow_mound(x, y)
    love.graphics.push()
    love.graphics.translate(x, y)

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.1)
    love.graphics.ellipse("fill", 1, 4, 12, 3)

    -- Snow mound base
    Colors.set(Colors.SNOW)
    love.graphics.ellipse("fill", 0, 0, 12, 6)

    -- Highlight (top)
    Colors.set(Colors.SNOW_WHITE)
    love.graphics.ellipse("fill", -2, -2, 6, 3)

    -- Shadow crease (subtle)
    love.graphics.setColor(0.88, 0.9, 0.95, 0.5)
    love.graphics.ellipse("fill", 4, 2, 4, 2)

    love.graphics.pop()
end

--------------------------------------------------------------------------------
-- SKIER SPRITE
--------------------------------------------------------------------------------

-- Skier (normal stance)
function Sprites.draw_skier(x, y, ski_spread, is_tucking)
    ski_spread = ski_spread or 1
    is_tucking = is_tucking or false

    love.graphics.push()
    love.graphics.translate(x, y)

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.ellipse("fill", 2, 8, 6, 3)

    -- Skis (electric blue)
    Colors.set(Colors.ELECTRIC_BLUE)
    local ski_offset = 3 * ski_spread
    if is_tucking then
        -- Tucked - skis together
        draw_rect(-2, 2, 4, 14, 1, 1)
    else
        -- Normal stance - skis apart
        draw_rect(-ski_offset - 1.5, 2, 3, 14, 1, 1)
        draw_rect(ski_offset - 1.5, 2, 3, 14, 1, 1)
    end

    -- Body (hot pink jacket)
    Colors.set(Colors.HOT_PINK)
    draw_rect(-4, -8, 8, 12, 2, 2)

    -- Jacket highlight
    love.graphics.setColor(1, 0.3, 0.7, 1)
    draw_rect(-3, -7, 2, 8, 1, 1)

    -- Jacket stripe (80s racing style)
    Colors.set(Colors.BRIGHT_YELLOW)
    draw_rect(-4, -2, 8, 2)

    -- Head (skin tone)
    love.graphics.setColor(1, 0.85, 0.7, 1)
    love.graphics.circle("fill", 0, -12, 4)

    -- Goggles (electric blue)
    Colors.set(Colors.ELECTRIC_BLUE)
    draw_rect(-3, -13, 6, 2, 1, 1)

    -- Goggle shine
    Colors.set(Colors.SNOW_WHITE)
    draw_rect(-2, -13, 1, 1)

    -- Helmet (bright yellow)
    Colors.set(Colors.BRIGHT_YELLOW)
    love.graphics.arc("fill", 0, -12, 4, math.pi, 0)

    -- Helmet stripe
    Colors.set(Colors.HOT_PINK)
    draw_rect(-1, -16, 2, 2)

    -- Poles (when not tucking)
    if not is_tucking then
        love.graphics.setColor(0.6, 0.6, 0.65, 1)
        love.graphics.setLineWidth(1)
        love.graphics.line(-5, -4, -8, 8)
        love.graphics.line(5, -4, 8, 8)

        -- Pole grips
        love.graphics.setColor(0.3, 0.3, 0.35, 1)
        love.graphics.circle("fill", -5, -4, 1.5)
        love.graphics.circle("fill", 5, -4, 1.5)

        -- Pole baskets
        love.graphics.setColor(0.4, 0.4, 0.45, 1)
        love.graphics.circle("line", -8, 8, 2)
        love.graphics.circle("line", 8, 8, 2)
    end

    love.graphics.pop()
end

-- Crashed skier
function Sprites.draw_skier_crashed(x, y, anim_timer)
    anim_timer = anim_timer or 0

    love.graphics.push()
    love.graphics.translate(x, y)

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.ellipse("fill", 0, 2, 12, 4)

    -- Sprawled body
    Colors.set(Colors.HOT_PINK)
    draw_rect(-10, -4, 20, 8, 2, 2)

    -- Head
    love.graphics.setColor(1, 0.85, 0.7, 1)
    love.graphics.circle("fill", -10, 0, 4)

    -- Dizzy swirl eyes
    Colors.set(Colors.ELECTRIC_BLUE)
    love.graphics.circle("line", -11, -1, 1.5)
    love.graphics.circle("line", -9, -1, 1.5)

    -- Skis scattered
    Colors.set(Colors.ELECTRIC_BLUE)
    love.graphics.push()
    love.graphics.rotate(0.5)
    draw_rect(5, -8, 3, 12, 1, 1)
    love.graphics.pop()
    love.graphics.push()
    love.graphics.rotate(-0.3)
    draw_rect(-8, 2, 3, 12, 1, 1)
    love.graphics.pop()

    -- Stars above head (animated)
    Colors.set(Colors.BRIGHT_YELLOW)
    local star_offset = math.sin(anim_timer * 8) * 3
    love.graphics.circle("fill", -12 + star_offset, -8, 2)
    love.graphics.circle("fill", -8 - star_offset, -10, 1.5)
    love.graphics.circle("fill", -14, -6 + star_offset * 0.5, 1.5)

    love.graphics.pop()
end

--------------------------------------------------------------------------------
-- UI / DECORATIVE SPRITES
--------------------------------------------------------------------------------

-- Ski tracks (for trail behind skier)
function Sprites.draw_ski_tracks(x, y, length, spread)
    spread = spread or 3
    length = length or 20

    Colors.set(Colors.SNOW_SHADOW)
    love.graphics.setLineWidth(1)
    love.graphics.line(x - spread, y, x - spread, y + length)
    love.graphics.line(x + spread, y, x + spread, y + length)
end

-- Speed lines (for tuck boost effect)
function Sprites.draw_speed_lines(x, y, count, length)
    count = count or 3
    length = length or 8

    Colors.set(Colors.SNOW_WHITE)
    love.graphics.setLineWidth(1)

    for i = 1, count do
        local offset_x = (i - (count + 1) / 2) * 4
        local offset_y = (i % 2) * 3
        love.graphics.line(
            x + offset_x, y + offset_y,
            x + offset_x, y + offset_y + length
        )
    end
end

-- Snowflake (decorative)
function Sprites.draw_snowflake(x, y, size)
    size = size or 3

    Colors.set(Colors.SNOW_WHITE)
    love.graphics.setLineWidth(1)

    -- Six-pointed snowflake
    for i = 0, 5 do
        local angle = (i / 6) * math.pi * 2
        local x2 = x + math.cos(angle) * size
        local y2 = y + math.sin(angle) * size
        love.graphics.line(x, y, x2, y2)
    end

    -- Center dot
    love.graphics.circle("fill", x, y, 1)
end

--------------------------------------------------------------------------------
-- CACHE SYSTEM (for performance)
--------------------------------------------------------------------------------

-- Get or create a cached canvas for a sprite
function Sprites.get_cached(name, width, height, draw_func)
    if not sprite_cache[name] then
        local canvas = love.graphics.newCanvas(width, height)
        love.graphics.setCanvas(canvas)
        love.graphics.clear(0, 0, 0, 0)
        love.graphics.setBlendMode("alpha")

        -- Draw centered on canvas
        love.graphics.push()
        love.graphics.translate(width / 2, height / 2)
        draw_func()
        love.graphics.pop()

        love.graphics.setCanvas()
        sprite_cache[name] = canvas
    end
    return sprite_cache[name]
end

-- Draw a cached sprite at position
function Sprites.draw_cached(name, x, y, width, height, draw_func)
    local canvas = Sprites.get_cached(name, width, height, draw_func)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas, x - width/2, y - height/2)
end

-- Clear the sprite cache (call on resize or cleanup)
function Sprites.clear_cache()
    sprite_cache = {}
end

-- Pre-cache common sprites for better performance
function Sprites.precache()
    Sprites.get_cached("small_tree", 24, 32, function()
        Sprites.draw_small_tree(0, 0)
    end)

    Sprites.get_cached("large_tree", 32, 48, function()
        Sprites.draw_large_tree(0, 0)
    end)

    Sprites.get_cached("rock", 24, 20, function()
        Sprites.draw_rock(0, 0)
    end)

    Sprites.get_cached("snow_mound", 28, 16, function()
        Sprites.draw_snow_mound(0, 0)
    end)

    Sprites.get_cached("cabin_pink", 40, 44, function()
        Sprites.draw_cabin_pink(0, 0)
    end)

    Sprites.get_cached("cabin_blue", 40, 44, function()
        Sprites.draw_cabin_blue(0, 0)
    end)
end

return Sprites
