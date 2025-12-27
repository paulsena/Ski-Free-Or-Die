-- src/entities/obstacle.lua
-- Obstacle entities: trees, rocks, cabins

local Colors = require("src.colors")
local Utils = require("src.lib.utils")

local Obstacle = {}

-- Obstacle type definitions (scaled for 360x480 resolution)
Obstacle.TYPES = {
    small_tree = {
        width = 18,
        height = 24,
        collision_type = "slow",    -- Just slows down
        speed_penalty = 0.8,        -- 20% speed loss
        spawn_weight = 35           -- Spawn probability weight
    },
    large_tree = {
        width = 28,
        height = 40,
        collision_type = "deflect", -- Slows and deflects
        speed_penalty = 0.4,        -- 60% speed loss
        spawn_weight = 25
    },
    rock = {
        width = 24,
        height = 18,
        collision_type = "crash",   -- Full crash
        speed_penalty = 0,
        spawn_weight = 20
    },
    cabin = {
        width = 42,
        height = 36,
        collision_type = "crash",   -- Full crash
        speed_penalty = 0,
        spawn_weight = 10
    },
    snow_mound = {
        width = 30,
        height = 12,
        collision_type = "slow",
        speed_penalty = 0.9,        -- 10% speed loss
        spawn_weight = 10
    }
}

function Obstacle.new(x, y, obs_type)
    local type_def = Obstacle.TYPES[obs_type]
    if not type_def then
        obs_type = "small_tree"
        type_def = Obstacle.TYPES.small_tree
    end

    local self = {
        x = x,
        y = y,
        type = obs_type,
        width = type_def.width,
        height = type_def.height,
        collision_type = type_def.collision_type,
        speed_penalty = type_def.speed_penalty,
        -- Visual variation
        scale = 0.9 + math.random() * 0.2,
        flip = math.random() > 0.5
    }
    return setmetatable(self, {__index = Obstacle})
end

function Obstacle.spawn_random(x, y)
    -- Weighted random selection (uses math.random - non-deterministic)
    local total_weight = 0
    for _, def in pairs(Obstacle.TYPES) do
        total_weight = total_weight + def.spawn_weight
    end

    local roll = math.random() * total_weight
    local cumulative = 0

    for type_name, def in pairs(Obstacle.TYPES) do
        cumulative = cumulative + def.spawn_weight
        if roll <= cumulative then
            return Obstacle.new(x, y, type_name)
        end
    end

    return Obstacle.new(x, y, "small_tree")
end

-- Seeded version for deterministic generation
function Obstacle.spawn_random_seeded(x, y, rng)
    -- Weighted random selection using seeded RNG
    local total_weight = 0
    for _, def in pairs(Obstacle.TYPES) do
        total_weight = total_weight + def.spawn_weight
    end

    local roll = rng:random() * total_weight
    local cumulative = 0

    for type_name, def in pairs(Obstacle.TYPES) do
        cumulative = cumulative + def.spawn_weight
        if roll <= cumulative then
            return Obstacle.new_seeded(x, y, type_name, rng)
        end
    end

    return Obstacle.new_seeded(x, y, "small_tree", rng)
end

-- Seeded constructor for visual variations
function Obstacle.new_seeded(x, y, obs_type, rng)
    local type_def = Obstacle.TYPES[obs_type]
    if not type_def then
        obs_type = "small_tree"
        type_def = Obstacle.TYPES.small_tree
    end

    local self = {
        x = x,
        y = y,
        type = obs_type,
        width = type_def.width,
        height = type_def.height,
        collision_type = type_def.collision_type,
        speed_penalty = type_def.speed_penalty,
        -- Visual variation using seeded RNG
        scale = 0.9 + rng:random() * 0.2,
        flip = rng:random() > 0.5
    }
    return setmetatable(self, {__index = Obstacle})
end

function Obstacle:get_hitbox()
    return {
        x = self.x - self.width / 2,
        y = self.y - self.height / 2,
        width = self.width,
        height = self.height
    }
end

function Obstacle:check_collision(skier_hitbox)
    -- Circle vs rectangle collision
    local hb = self:get_hitbox()
    local closest_x = Utils.clamp(skier_hitbox.x, hb.x, hb.x + hb.width)
    local closest_y = Utils.clamp(skier_hitbox.y, hb.y, hb.y + hb.height)

    return Utils.distance(skier_hitbox.x, skier_hitbox.y, closest_x, closest_y) < skier_hitbox.radius
end

function Obstacle:draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)

    if self.flip then
        love.graphics.scale(-1, 1)
    end
    love.graphics.scale(self.scale, self.scale)

    if self.type == "small_tree" then
        self:draw_small_tree()
    elseif self.type == "large_tree" then
        self:draw_large_tree()
    elseif self.type == "rock" then
        self:draw_rock()
    elseif self.type == "cabin" then
        self:draw_cabin()
    elseif self.type == "snow_mound" then
        self:draw_snow_mound()
    end

    love.graphics.pop()
end

function Obstacle:draw_small_tree()
    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.15)
    love.graphics.ellipse("fill", 2, 8, 8, 3)

    -- Trunk
    Colors.set(Colors.CABIN_BROWN)
    love.graphics.rectangle("fill", -2, 2, 4, 10)

    -- Foliage layers (back to front for depth)
    Colors.set(Colors.DARK_PINE)
    love.graphics.polygon("fill",
        0, -10,
        -9, 4,
        9, 4
    )

    Colors.set(Colors.PINE_GREEN)
    love.graphics.polygon("fill",
        0, -14,
        -7, 0,
        7, 0
    )

    -- Snow on top
    Colors.set(Colors.SNOW_WHITE)
    love.graphics.polygon("fill",
        0, -15,
        -3, -10,
        3, -10
    )
end

function Obstacle:draw_large_tree()
    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.ellipse("fill", 3, 12, 12, 4)

    -- Trunk
    Colors.set(Colors.CABIN_BROWN)
    love.graphics.rectangle("fill", -3, 4, 6, 14)
    Colors.set(Colors.DARK_BROWN)
    love.graphics.rectangle("fill", -3, 4, 2, 14)

    -- Foliage layers
    Colors.set(Colors.DARK_PINE)
    love.graphics.polygon("fill",
        0, -6,
        -14, 10,
        14, 10
    )

    Colors.set(Colors.PINE_GREEN)
    love.graphics.polygon("fill",
        0, -14,
        -12, 4,
        12, 4
    )

    Colors.set(Colors.MINT_GREEN)
    love.graphics.polygon("fill",
        0, -20,
        -8, -4,
        8, -4
    )

    -- Snow patches
    Colors.set(Colors.SNOW_WHITE)
    love.graphics.polygon("fill",
        0, -21,
        -4, -14,
        4, -14
    )
    love.graphics.ellipse("fill", -6, -2, 3, 2)
    love.graphics.ellipse("fill", 5, 2, 2.5, 1.5)
end

function Obstacle:draw_rock()
    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.ellipse("fill", 2, 5, 10, 4)

    -- Main rock shape
    Colors.set(Colors.ROCK_GRAY)
    love.graphics.polygon("fill",
        -8, 4,
        -6, -4,
        0, -7,
        8, -3,
        10, 4
    )

    -- Highlight
    love.graphics.setColor(0.55, 0.55, 0.6)
    love.graphics.polygon("fill",
        -4, -2,
        0, -5,
        4, -2,
        0, 0
    )

    -- Snow cap
    Colors.set(Colors.SNOW_WHITE)
    love.graphics.polygon("fill",
        -3, -5,
        0, -8,
        5, -4,
        0, -3
    )
end

function Obstacle:draw_cabin()
    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.ellipse("fill", 2, 12, 16, 5)

    -- Cabin body
    Colors.set(Colors.CABIN_BROWN)
    love.graphics.rectangle("fill", -12, -4, 24, 16)

    -- Wood grain details
    Colors.set(Colors.DARK_BROWN)
    love.graphics.line(-12, 0, 12, 0)
    love.graphics.line(-12, 4, 12, 4)
    love.graphics.line(-12, 8, 12, 8)

    -- Roof
    Colors.set(Colors.DARK_BROWN)
    love.graphics.polygon("fill",
        0, -16,
        -16, -4,
        16, -4
    )

    -- Snow on roof
    Colors.set(Colors.SNOW_WHITE)
    love.graphics.polygon("fill",
        0, -18,
        -14, -6,
        14, -6
    )
    -- Snow drip effect
    love.graphics.polygon("fill",
        -12, -6,
        -14, -6,
        -13, -2
    )
    love.graphics.polygon("fill",
        10, -6,
        12, -6,
        11, -3
    )

    -- Door
    Colors.set(Colors.BRIGHT_YELLOW)
    love.graphics.rectangle("fill", -3, 2, 6, 10)

    -- Window
    Colors.set(Colors.ELECTRIC_BLUE)
    love.graphics.rectangle("fill", 5, 0, 5, 5)
    love.graphics.setColor(0.4, 0.4, 0.45)
    love.graphics.line(7.5, 0, 7.5, 5)
    love.graphics.line(5, 2.5, 10, 2.5)

    -- Chimney
    Colors.set(Colors.ROCK_GRAY)
    love.graphics.rectangle("fill", 6, -14, 4, 6)
    Colors.set(Colors.SNOW_WHITE)
    love.graphics.rectangle("fill", 5, -15, 6, 2)
end

function Obstacle:draw_snow_mound()
    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.1)
    love.graphics.ellipse("fill", 1, 4, 12, 3)

    -- Snow mound
    Colors.set(Colors.SNOW)
    love.graphics.ellipse("fill", 0, 0, 12, 6)

    -- Highlight
    Colors.set(Colors.SNOW_WHITE)
    love.graphics.ellipse("fill", -2, -2, 6, 3)
end

return Obstacle
