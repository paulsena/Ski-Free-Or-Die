-- src/entities/yeti.lua
-- The dreaded Yeti that chases players in endless mode

local Colors = require("src.colors")
local Utils = require("src.lib.utils")

local Yeti = {}

-- Yeti constants (scaled for 360x480 resolution)
Yeti.BASE_SPEED = 70               -- Base speed (slightly slower than skier)
Yeti.SPEED_INCREASE_RATE = 0.01    -- Speed increase per second
Yeti.CATCH_DISTANCE = 30           -- Distance at which yeti catches player
Yeti.START_DISTANCE = -300         -- Starting distance behind player (closer for more tension)
Yeti.BOOST_ON_CRASH = 1.5          -- Speed multiplier when player crashes
Yeti.WIDTH = 36
Yeti.HEIGHT = 48

-- Yeti danger zones (scaled for 360x480 resolution)
Yeti.ZONE_SAFE = 500               -- Beyond this, player is safe
Yeti.ZONE_WARNING = 350            -- Warning zone starts here
Yeti.ZONE_DANGER = 150             -- Danger zone starts here
Yeti.ZONE_CRITICAL = 75            -- Critical zone - about to catch

function Yeti.new()
    local self = {
        distance = Yeti.START_DISTANCE,  -- Distance behind player (negative)
        speed_multiplier = 1.0,
        elapsed_time = 0,
        anim_timer = 0,
        -- Animation state
        frame = 1,
        arm_swing = 0,
        is_lunging = false,
        lunge_timer = 0
    }
    return setmetatable(self, {__index = Yeti})
end

function Yeti:reset()
    self.distance = Yeti.START_DISTANCE
    self.speed_multiplier = 1.0
    self.elapsed_time = 0
    self.anim_timer = 0
    self.is_lunging = false
end

function Yeti:update(dt, skier_speed, is_skier_crashed)
    self.elapsed_time = self.elapsed_time + dt
    self.anim_timer = self.anim_timer + dt

    -- Gradually increase speed over time
    self.speed_multiplier = 1.0 + self.elapsed_time * Yeti.SPEED_INCREASE_RATE

    -- Calculate yeti speed
    local yeti_speed = Yeti.BASE_SPEED * self.speed_multiplier

    -- Speed boost when player crashes
    if is_skier_crashed then
        yeti_speed = yeti_speed * Yeti.BOOST_ON_CRASH
    end

    -- Update distance relative to player
    local relative_speed = yeti_speed - skier_speed
    self.distance = self.distance + relative_speed * dt

    -- Arm swing animation
    self.arm_swing = math.sin(self.anim_timer * 6) * 0.4

    -- Lunge animation when very close
    if self.distance > -Yeti.ZONE_CRITICAL and not self.is_lunging then
        self.is_lunging = true
        self.lunge_timer = 0
    end

    if self.is_lunging then
        self.lunge_timer = self.lunge_timer + dt
        if self.lunge_timer > 0.5 then
            self.is_lunging = false
        end
    end

    -- Check if caught
    return self.distance >= -Yeti.CATCH_DISTANCE
end

function Yeti:get_danger_zone()
    local abs_dist = -self.distance

    if abs_dist > Yeti.ZONE_SAFE then
        return "safe"
    elseif abs_dist > Yeti.ZONE_WARNING then
        return "warning"
    elseif abs_dist > Yeti.ZONE_DANGER then
        return "danger"
    else
        return "critical"
    end
end

function Yeti:get_danger_intensity()
    -- Returns 0-1 based on how close yeti is
    local abs_dist = math.max(0, -self.distance)
    return 1 - Utils.clamp(abs_dist / Yeti.ZONE_SAFE, 0, 1)
end

function Yeti:draw(camera_y, screen_height)
    -- Only draw if yeti is close enough to be visible
    if self.distance < -350 then
        return
    end

    -- Calculate screen position (yeti appears at top of screen when close)
    local yeti_y = camera_y + self.distance
    local screen_y = yeti_y - (camera_y - screen_height * 0.7)

    -- Only draw if on screen
    if screen_y < -50 or screen_y > screen_height + 50 then
        return
    end

    -- Center yeti horizontally on screen (180 = GAME_WIDTH / 2)
    local screen_x = 180

    love.graphics.push()
    love.graphics.translate(screen_x, screen_y)

    -- Apply lunge effect
    local scale = 1.0
    if self.is_lunging then
        local t = self.lunge_timer / 0.5
        scale = 1.0 + math.sin(t * math.pi) * 0.3
    end
    love.graphics.scale(scale, scale)

    self:draw_yeti()

    love.graphics.pop()
end

function Yeti:draw_yeti()
    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.ellipse("fill", 0, 16, 16, 6)

    -- Fur body (white/light gray)
    love.graphics.setColor(0.95, 0.95, 1)
    love.graphics.ellipse("fill", 0, 0, 14, 18)

    -- Fur texture (darker patches)
    love.graphics.setColor(0.85, 0.85, 0.9)
    love.graphics.ellipse("fill", -5, -5, 4, 6)
    love.graphics.ellipse("fill", 6, 2, 3, 5)

    -- Left arm with swing animation
    love.graphics.push()
    love.graphics.rotate(self.arm_swing)
    love.graphics.setColor(0.92, 0.92, 0.97)
    love.graphics.ellipse("fill", -14, -2, 6, 10)
    -- Claws
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.polygon("fill", -18, 6, -20, 10, -17, 8)
    love.graphics.polygon("fill", -15, 7, -16, 11, -13, 9)
    love.graphics.pop()

    -- Right arm with opposite swing
    love.graphics.push()
    love.graphics.rotate(-self.arm_swing)
    love.graphics.setColor(0.92, 0.92, 0.97)
    love.graphics.ellipse("fill", 14, -2, 6, 10)
    -- Claws
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.polygon("fill", 18, 6, 20, 10, 17, 8)
    love.graphics.polygon("fill", 15, 7, 16, 11, 13, 9)
    love.graphics.pop()

    -- Head
    love.graphics.setColor(0.95, 0.95, 1)
    love.graphics.ellipse("fill", 0, -22, 10, 12)

    -- Face - angry expression
    -- Eyes (red, glowing)
    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.circle("fill", -4, -24, 3)
    love.graphics.circle("fill", 4, -24, 3)

    -- Eye pupils
    love.graphics.setColor(0.1, 0, 0)
    love.graphics.circle("fill", -3, -24, 1.5)
    love.graphics.circle("fill", 5, -24, 1.5)

    -- Eye glow effect
    if math.floor(self.anim_timer * 4) % 2 == 0 then
        love.graphics.setColor(1, 0.4, 0.4, 0.5)
        love.graphics.circle("fill", -4, -24, 4)
        love.graphics.circle("fill", 4, -24, 4)
    end

    -- Angry eyebrows
    love.graphics.setColor(0.7, 0.7, 0.75)
    love.graphics.polygon("fill", -8, -28, -7, -26, -1, -27)
    love.graphics.polygon("fill", 8, -28, 7, -26, 1, -27)

    -- Mouth with fangs
    love.graphics.setColor(0.2, 0, 0)
    love.graphics.ellipse("fill", 0, -16, 6, 4)

    -- Fangs
    love.graphics.setColor(1, 1, 1)
    love.graphics.polygon("fill", -3, -18, -4, -13, -2, -18)
    love.graphics.polygon("fill", 3, -18, 4, -13, 2, -18)

    -- Legs
    love.graphics.setColor(0.92, 0.92, 0.97)
    love.graphics.ellipse("fill", -6, 14, 5, 8)
    love.graphics.ellipse("fill", 6, 14, 5, 8)

    -- Feet
    love.graphics.setColor(0.85, 0.85, 0.9)
    love.graphics.ellipse("fill", -6, 20, 6, 3)
    love.graphics.ellipse("fill", 6, 20, 6, 3)
end

-- Draw danger vignette effect
function Yeti:draw_danger_overlay(screen_width, screen_height)
    local intensity = self:get_danger_intensity()
    if intensity < 0.1 then
        return
    end

    local zone = self:get_danger_zone()
    local r, g, b = 0.8, 0, 0

    if zone == "warning" then
        r, g, b = 0.8, 0.4, 0
    elseif zone == "critical" then
        -- Pulsing red for critical
        local pulse = 0.5 + math.sin(self.anim_timer * 8) * 0.5
        r = 1 * pulse
    end

    local alpha = intensity * 0.4

    -- Vignette effect on edges
    love.graphics.setColor(r, g, b, alpha)

    -- Top edge
    love.graphics.rectangle("fill", 0, 0, screen_width, 12)
    -- Bottom edge
    love.graphics.rectangle("fill", 0, screen_height - 12, screen_width, 12)
    -- Left edge
    love.graphics.rectangle("fill", 0, 0, 12, screen_height)
    -- Right edge
    love.graphics.rectangle("fill", screen_width - 12, 0, 12, screen_height)
end

return Yeti
