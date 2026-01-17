-- src/entities/skier.lua
-- Player-controlled skier entity with physics

local Colors = require("src.colors")
local Utils = require("src.lib.utils")

local Skier = {}

-- Discrete positions (like original SkiFree)
-- Each position maps to an angle and can have a sprite assigned
Skier.POSITIONS = {
    { name = "FULL_LEFT",   angle = -80, speed_mult = 0.35 }, -- 1: Hard brake left (slow creep)
    { name = "FAR_LEFT",    angle = -60, speed_mult = 1.0 },  -- 2: Sharp left (geometry only)
    { name = "LEFT",        angle = -30, speed_mult = 1.0 },  -- 3: Gentle left (geometry only)
    { name = "CENTER",      angle = 0,   speed_mult = 1.0 },  -- 4: Straight down (full speed)
    { name = "RIGHT",       angle = 30,  speed_mult = 1.0 },  -- 5: Gentle right (geometry only)
    { name = "FAR_RIGHT",   angle = 60,  speed_mult = 1.0 },  -- 6: Sharp right (geometry only)
    { name = "FULL_RIGHT",  angle = 80,  speed_mult = 0.35 }, -- 7: Hard brake right (slow creep)
}

-- Position index constants for easy reference
Skier.POS_FULL_LEFT = 1
Skier.POS_FAR_LEFT = 2
Skier.POS_LEFT = 3
Skier.POS_CENTER = 4
Skier.POS_RIGHT = 5
Skier.POS_FAR_RIGHT = 6
Skier.POS_FULL_RIGHT = 7

-- Physics constants (scaled for 360x480 resolution)
Skier.BASE_SPEED = 140             -- Base downhill speed (pixels/sec)
Skier.MAX_SPEED = 320              -- Maximum speed
Skier.TUCK_SPEED_BONUS = 0.12      -- 12% speed increase when tucking
Skier.CRASH_DURATION = 1.0         -- Recovery time after crash
Skier.IMMUNITY_DURATION = 1.0      -- Immunity time after crash recovery
Skier.HITBOX_RADIUS = 8            -- Forgiving collision radius (scaled)
Skier.DEFLECT_VX_FACTOR = 0.8      -- How much X velocity reverses on deflect

-- Mouse control settings (zone thresholds in pixels from center)
Skier.ZONE_CENTER = 60             -- 0-60px = straight (position 4)
Skier.ZONE_GENTLE = 100            -- 61-100px = gentle turn (position 3/5)
Skier.ZONE_SHARP = 140             -- 101-140px = sharp turn (position 2/6)
                                   -- 141px+ = full brake turn (position 1/7)

function Skier.new(x, y)
    local self = {
        x = x or 0,
        y = y or 0,
        vx = 0,
        vy = Skier.BASE_SPEED,
        position = Skier.POS_CENTER,  -- Current position index (1-7)
        speed = Skier.BASE_SPEED,
        is_tucking = false,
        is_crashed = false,
        crash_timer = 0,
        is_immune = false,
        immunity_timer = 0,
        -- Animation state
        anim_timer = 0,
        ski_spread = 1
    }
    return setmetatable(self, {__index = Skier})
end

function Skier:get_position_data()
    return Skier.POSITIONS[self.position]
end

function Skier:get_angle()
    return self:get_position_data().angle
end

function Skier:handle_input(dt, skier_screen_x)
    if self.is_crashed then
        return
    end

    -- Tuck state - mouse button or keyboard
    self.is_tucking = love.mouse.isDown(1) or love.mouse.isDown(2) or
                      love.keyboard.isDown("down") or
                      love.keyboard.isDown("s") or
                      love.keyboard.isDown("lshift") or
                      love.keyboard.isDown("rshift")

    -- Get mouse position in game coordinates
    local mouse_x, _ = love.getGameMousePosition()

    -- Calculate offset from skier's screen position
    local offset = mouse_x - skier_screen_x
    local abs_offset = math.abs(offset)

    -- Map offset to position using explicit zone thresholds
    local new_position
    if abs_offset <= Skier.ZONE_CENTER then
        -- Center zone - go straight
        new_position = Skier.POS_CENTER
    elseif abs_offset <= Skier.ZONE_GENTLE then
        -- Gentle turn zone
        new_position = offset > 0 and Skier.POS_RIGHT or Skier.POS_LEFT
    elseif abs_offset <= Skier.ZONE_SHARP then
        -- Sharp turn zone
        new_position = offset > 0 and Skier.POS_FAR_RIGHT or Skier.POS_FAR_LEFT
    else
        -- Full brake turn zone
        new_position = offset > 0 and Skier.POS_FULL_RIGHT or Skier.POS_FULL_LEFT
    end

    self.position = new_position
end

function Skier:move_position(delta)
    self.position = Utils.clamp(self.position + delta, 1, #Skier.POSITIONS)
end

function Skier:update(dt, slope_bounds)
    -- Update animation timer
    self.anim_timer = self.anim_timer + dt

    -- Handle crash recovery
    if self.is_crashed then
        self.crash_timer = self.crash_timer - dt
        if self.crash_timer <= 0 then
            self.is_crashed = false
            self.is_immune = true
            self.immunity_timer = Skier.IMMUNITY_DURATION
            self.speed = Skier.BASE_SPEED * 0.5
            self.position = Skier.POS_CENTER
        end
        return
    end

    -- Handle immunity countdown
    if self.is_immune then
        self.immunity_timer = self.immunity_timer - dt
        if self.immunity_timer <= 0 then
            self.is_immune = false
        end
    end

    -- Get current position data
    local pos_data = self:get_position_data()
    local angle = pos_data.angle
    local speed_mult = pos_data.speed_mult

    -- Calculate target speed based on position and tuck
    local target_speed = Skier.BASE_SPEED * speed_mult
    if self.is_tucking and speed_mult > 0 then
        target_speed = target_speed * (1 + Skier.TUCK_SPEED_BONUS)
    end

    -- Accelerate/decelerate towards target speed
    self.speed = Utils.lerp(self.speed, target_speed, dt * 4)
    self.speed = Utils.clamp(self.speed, 0, Skier.MAX_SPEED)

    -- Calculate velocity based on angle
    local angle_rad = Utils.deg_to_rad(angle)
    self.vx = math.sin(angle_rad) * self.speed
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
    -- Move position towards center on deflect
    if self.position < Skier.POS_CENTER then
        self.position = math.min(self.position + 2, Skier.POS_CENTER)
    elseif self.position > Skier.POS_CENTER then
        self.position = math.max(self.position - 2, Skier.POS_CENTER)
    end
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
    love.graphics.rotate(Utils.deg_to_rad(-self:get_angle()))

    -- Flash effect during immunity (blink on/off rapidly)
    local visible = true
    if self.is_immune then
        visible = math.floor(self.anim_timer * 10) % 2 == 0
    end

    if visible then
        if self.is_crashed then
            self:draw_crashed()
        else
            self:draw_normal()
        end
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
