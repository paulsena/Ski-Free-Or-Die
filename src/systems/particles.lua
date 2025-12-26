-- src/systems/particles.lua
-- Simple particle system for visual effects

local Colors = require("src.colors")
local Utils = require("src.lib.utils")

local Particles = {}

-- Particle types
Particles.TYPES = {
    snow_spray = {
        lifetime = {0.3, 0.6},
        speed = {20, 60},
        size = {1, 3},
        gravity = 30,
        fade = true,
        color = Colors.SNOW_WHITE
    },
    impact_snow = {
        lifetime = {0.4, 0.8},
        speed = {40, 100},
        size = {2, 4},
        gravity = 50,
        fade = true,
        color = Colors.SNOW
    },
    crash_debris = {
        lifetime = {0.5, 1.0},
        speed = {30, 80},
        size = {1, 3},
        gravity = 80,
        fade = true,
        color = Colors.SNOW_WHITE
    },
    gate_sparkle = {
        lifetime = {0.2, 0.5},
        speed = {20, 50},
        size = {2, 4},
        gravity = -20,  -- Float up
        fade = true,
        color = Colors.MINT_GREEN
    }
}

function Particles.new()
    local self = {
        particles = {},
        max_particles = 200
    }
    return setmetatable(self, {__index = Particles})
end

function Particles:emit(x, y, particle_type, count, direction_min, direction_max)
    local type_def = Particles.TYPES[particle_type]
    if not type_def then
        type_def = Particles.TYPES.snow_spray
    end

    count = count or 5
    direction_min = direction_min or 0
    direction_max = direction_max or math.pi * 2

    for i = 1, count do
        if #self.particles >= self.max_particles then
            -- Remove oldest particle
            table.remove(self.particles, 1)
        end

        local angle = direction_min + math.random() * (direction_max - direction_min)
        local speed = type_def.speed[1] + math.random() * (type_def.speed[2] - type_def.speed[1])
        local lifetime = type_def.lifetime[1] + math.random() * (type_def.lifetime[2] - type_def.lifetime[1])
        local size = type_def.size[1] + math.random() * (type_def.size[2] - type_def.size[1])

        local particle = {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = size,
            lifetime = lifetime,
            max_lifetime = lifetime,
            gravity = type_def.gravity,
            fade = type_def.fade,
            color = type_def.color
        }

        table.insert(self.particles, particle)
    end
end

function Particles:emit_snow_spray(x, y, skier_angle, skier_speed, is_turning)
    if skier_speed < 30 then
        return
    end

    -- More particles when turning
    local count = is_turning and 3 or 1
    local speed_factor = skier_speed / 100

    -- Spray direction based on skier angle and turning
    local base_angle = math.pi + Utils.deg_to_rad(skier_angle)
    local spray_spread = is_turning and 0.6 or 0.3

    for i = 1, count do
        local angle = base_angle + (math.random() - 0.5) * spray_spread
        local speed = (20 + math.random() * 40) * speed_factor

        if #self.particles < self.max_particles then
            table.insert(self.particles, {
                x = x + (math.random() - 0.5) * 6,
                y = y + 8 + math.random() * 4,
                vx = math.cos(angle) * speed,
                vy = math.sin(angle) * speed * 0.3,
                size = 1 + math.random() * 2,
                lifetime = 0.3 + math.random() * 0.3,
                max_lifetime = 0.6,
                gravity = 30,
                fade = true,
                color = Colors.SNOW_WHITE
            })
        end
    end
end

function Particles:emit_crash(x, y)
    -- Big impact spray
    self:emit(x, y, "crash_debris", 15, 0, math.pi * 2)

    -- Some upward debris
    for i = 1, 5 do
        if #self.particles < self.max_particles then
            table.insert(self.particles, {
                x = x + (math.random() - 0.5) * 10,
                y = y,
                vx = (math.random() - 0.5) * 60,
                vy = -40 - math.random() * 40,
                size = 2 + math.random() * 2,
                lifetime = 0.6 + math.random() * 0.4,
                max_lifetime = 1.0,
                gravity = 100,
                fade = true,
                color = Colors.SNOW
            })
        end
    end
end

function Particles:emit_gate_pass(x, y, passed)
    local color = passed and Colors.MINT_GREEN or Colors.HOT_PINK
    local count = passed and 8 or 4

    for i = 1, count do
        if #self.particles < self.max_particles then
            local angle = -math.pi/2 + (math.random() - 0.5) * 1.2  -- Mostly upward
            local speed = 30 + math.random() * 40

            table.insert(self.particles, {
                x = x + (math.random() - 0.5) * 30,
                y = y,
                vx = math.cos(angle) * speed,
                vy = math.sin(angle) * speed,
                size = 2 + math.random() * 2,
                lifetime = 0.3 + math.random() * 0.3,
                max_lifetime = 0.6,
                gravity = -30,
                fade = true,
                color = color
            })
        end
    end
end

function Particles:update(dt)
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]

        -- Apply gravity
        p.vy = p.vy + p.gravity * dt

        -- Update position
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt

        -- Update lifetime
        p.lifetime = p.lifetime - dt

        -- Remove dead particles
        if p.lifetime <= 0 then
            table.remove(self.particles, i)
        end
    end
end

function Particles:draw()
    for _, p in ipairs(self.particles) do
        local alpha = 1
        if p.fade then
            alpha = p.lifetime / p.max_lifetime
        end

        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.rectangle("fill",
            p.x - p.size/2,
            p.y - p.size/2,
            p.size,
            p.size
        )
    end
end

function Particles:clear()
    self.particles = {}
end

function Particles:get_count()
    return #self.particles
end

return Particles
