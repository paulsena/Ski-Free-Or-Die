-- src/entities/skier.lua
-- Player-controlled skier entity with physics

local Colors = require("src.colors")
local Utils = require("src.lib.utils")

local Skier = {}

-- Physics constants (from physics-tuck-mechanics-design.md)
Skier.BASE_SPEED = 80              -- Base downhill speed (pixels/sec)
Skier.MAX_SPEED = 200              -- Maximum speed
Skier.TURN_SPEED = 120             -- Turn rate in degrees/sec
Skier.TUCK_SPEED_BONUS = 0.12      -- 12% speed increase when tucking
Skier.TUCK_TURN_PENALTY = 0.5      -- 50% reduction in turn rate when tucking
Skier.SPEED_TURN_DAMPING = 0.4     -- How much speed affects turn rate
Skier.MAX_ANGLE = 80               -- Maximum turn angle in degrees
Skier.CRASH_DURATION = 1.75        -- Recovery time after crash
Skier.HITBOX_RADIUS = 5            -- Forgiving collision radius
Skier.DEFLECT_VX_FACTOR = 0.8      -- How much X velocity reverses on deflect
Skier.DEFLECT_ANGLE_FACTOR = 0.5   -- How much angle reverses on deflect

function Skier.new(x, y)
    local self = {
        x = x or 0,
        y = y or 0,
        vx = 0,
        vy = Skier.BASE_SPEED,
        angle = 0,               -- Current facing angle in degrees
        target_angle = 0,        -- Target angle from input
        speed = Skier.BASE_SPEED,
        is_tucking = false,
        is_crashed = false,
        crash_timer = 0,
        -- Animation state
        anim_timer = 0,
        ski_spread = 1           -- For subtle animation
    }
    return setmetatable(self, {__index = Skier})
end

function Skier:handle_input(dt)
    if self.is_crashed then
        return
    end

    -- Get input direction
    local turn_input = 0
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        turn_input = -1
    elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        turn_input = 1
    end

    -- Tuck state
    self.is_tucking = love.keyboard.isDown("down") or
                      love.keyboard.isDown("s") or
                      love.keyboard.isDown("lshift") or
                      love.keyboard.isDown("rshift")

    -- Calculate turn rate based on speed and tuck state
    local speed_factor = 1 - (self.speed / Skier.MAX_SPEED) * Skier.SPEED_TURN_DAMPING
    local tuck_factor = self.is_tucking and Skier.TUCK_TURN_PENALTY or 1
    local effective_turn_rate = Skier.TURN_SPEED * speed_factor * tuck_factor

    -- Update target angle
    self.target_angle = self.target_angle + turn_input * effective_turn_rate * dt
    self.target_angle = Utils.clamp(self.target_angle, -Skier.MAX_ANGLE, Skier.MAX_ANGLE)

    -- Return to center when no input
    if turn_input == 0 then
        self.target_angle = self.target_angle * 0.95
    end
end

function Skier:update(dt, slope_bounds)
    -- Update animation timer
    self.anim_timer = self.anim_timer + dt

    -- Handle crash recovery
    if self.is_crashed then
        self.crash_timer = self.crash_timer - dt
        if self.crash_timer <= 0 then
            self.is_crashed = false
            self.speed = Skier.BASE_SPEED * 0.5
        end
        return
    end

    -- Smoothly interpolate angle
    self.angle = Utils.lerp(self.angle, self.target_angle, dt * 8)

    -- Calculate speed with tuck bonus
    local target_speed = Skier.BASE_SPEED
    if self.is_tucking then
        target_speed = Skier.BASE_SPEED * (1 + Skier.TUCK_SPEED_BONUS)
    end

    -- Accelerate/decelerate towards target speed
    self.speed = Utils.lerp(self.speed, target_speed, dt * 2)
    self.speed = Utils.clamp(self.speed, 0, Skier.MAX_SPEED)

    -- Calculate velocity based on angle
    local angle_rad = Utils.deg_to_rad(self.angle)
    self.vx = math.sin(angle_rad) * self.speed * 0.8
    self.vy = math.cos(angle_rad) * self.speed

    -- Apply velocity
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Clamp X position to slope bounds
    if slope_bounds then
        self.x = Utils.clamp(self.x, slope_bounds.min_x, slope_bounds.max_x)
    end

    -- Subtle ski animation
    if not self.is_tucking then
        self.ski_spread = 1 + math.sin(self.anim_timer * 3) * 0.1
    else
        self.ski_spread = 0.3
    end
end

function Skier:crash()
    if not self.is_crashed then
        self.is_crashed = true
        self.crash_timer = Skier.CRASH_DURATION
        self.speed = 0
    end
end

function Skier:slow_down(factor)
    self.speed = self.speed * factor
end

function Skier:deflect(direction)
    self.vx = -self.vx * Skier.DEFLECT_VX_FACTOR
    self.target_angle = -self.target_angle * Skier.DEFLECT_ANGLE_FACTOR
end

function Skier:get_hitbox()
    return {
        x = self.x,
        y = self.y,
        radius = Skier.HITBOX_RADIUS
    }
end

function Skier:draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(Utils.deg_to_rad(self.angle))

    if self.is_crashed then
        self:draw_crashed()
    else
        self:draw_normal()
    end

    love.graphics.pop()
end

function Skier:draw_normal()
    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.ellipse("fill", 2, 8, 6, 3)

    -- Skis (electric blue)
    Colors.set(Colors.ELECTRIC_BLUE)
    local ski_offset = 3 * self.ski_spread
    if self.is_tucking then
        -- Tucked position - skis together
        love.graphics.rectangle("fill", -2, 2, 4, 14, 1, 1)
    else
        -- Normal stance - skis apart
        love.graphics.rectangle("fill", -ski_offset - 1.5, 2, 3, 14, 1, 1)
        love.graphics.rectangle("fill", ski_offset - 1.5, 2, 3, 14, 1, 1)
    end

    -- Body (hot pink jacket)
    Colors.set(Colors.HOT_PINK)
    love.graphics.rectangle("fill", -4, -8, 8, 12, 2, 2)

    -- Jacket highlights
    love.graphics.setColor(1, 0.3, 0.7)
    love.graphics.rectangle("fill", -3, -7, 2, 8, 1, 1)

    -- Head
    love.graphics.setColor(1, 0.85, 0.7)
    love.graphics.circle("fill", 0, -12, 4)

    -- Goggles (electric blue)
    Colors.set(Colors.ELECTRIC_BLUE)
    love.graphics.rectangle("fill", -3, -13, 6, 2, 1, 1)

    -- Helmet
    Colors.set(Colors.BRIGHT_YELLOW)
    love.graphics.arc("fill", 0, -12, 4, math.pi, 0)

    -- Poles (when not tucking)
    if not self.is_tucking then
        love.graphics.setColor(0.6, 0.6, 0.65)
        love.graphics.line(-5, -4, -8, 8)
        love.graphics.line(5, -4, 8, 8)
    end
end

function Skier:draw_crashed()
    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.ellipse("fill", 0, 2, 12, 4)

    -- Sprawled body
    Colors.set(Colors.HOT_PINK)
    love.graphics.rectangle("fill", -10, -4, 20, 8, 2, 2)

    -- Head
    love.graphics.setColor(1, 0.85, 0.7)
    love.graphics.circle("fill", -10, 0, 4)

    -- Skis scattered
    Colors.set(Colors.ELECTRIC_BLUE)
    love.graphics.push()
    love.graphics.rotate(0.5)
    love.graphics.rectangle("fill", 5, -8, 3, 12, 1, 1)
    love.graphics.pop()
    love.graphics.push()
    love.graphics.rotate(-0.3)
    love.graphics.rectangle("fill", -8, 2, 3, 12, 1, 1)
    love.graphics.pop()

    -- Stars above head (dizzy effect)
    Colors.set(Colors.BRIGHT_YELLOW)
    local star_offset = math.sin(self.anim_timer * 8) * 3
    love.graphics.circle("fill", -12 + star_offset, -8, 2)
    love.graphics.circle("fill", -8 - star_offset, -10, 1.5)
    love.graphics.circle("fill", -14, -6 + star_offset * 0.5, 1.5)
end

return Skier
