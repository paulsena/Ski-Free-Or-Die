-- src/lib/camera.lua
-- Simple 2D camera with follow behavior

local Camera = {}

function Camera.new()
    local self = {
        x = 0,
        y = 0,
        target_x = 0,
        target_y = 0,
        offset_x = 0,
        offset_y = 0,
        smooth = 5,  -- Higher = faster follow
        shake_intensity = 0,
        shake_duration = 0,
        shake_timer = 0,
        shake_offset_x = 0,
        shake_offset_y = 0
    }
    return setmetatable(self, {__index = Camera})
end

function Camera:set_target(x, y)
    self.target_x = x
    self.target_y = y
end

function Camera:set_offset(x, y)
    self.offset_x = x
    self.offset_y = y
end

function Camera:update(dt)
    -- Smooth follow
    local t = 1 - math.exp(-self.smooth * dt)
    self.x = self.x + (self.target_x - self.x) * t
    self.y = self.y + (self.target_y - self.y) * t

    -- Screen shake
    if self.shake_timer > 0 then
        self.shake_timer = self.shake_timer - dt
        local progress = self.shake_timer / self.shake_duration
        local intensity = self.shake_intensity * progress
        self.shake_offset_x = (math.random() * 2 - 1) * intensity
        self.shake_offset_y = (math.random() * 2 - 1) * intensity
    else
        self.shake_offset_x = 0
        self.shake_offset_y = 0
    end
end

function Camera:snap()
    -- Instantly move to target
    self.x = self.target_x
    self.y = self.target_y
end

function Camera:shake(intensity, duration)
    self.shake_intensity = intensity
    self.shake_duration = duration
    self.shake_timer = duration
end

function Camera:apply()
    -- Apply camera transform
    love.graphics.push()
    love.graphics.translate(
        -self.x + self.offset_x + self.shake_offset_x,
        -self.y + self.offset_y + self.shake_offset_y
    )
end

function Camera:reset()
    love.graphics.pop()
end

-- Convert screen coords to world coords
function Camera:screen_to_world(sx, sy)
    return sx + self.x - self.offset_x, sy + self.y - self.offset_y
end

-- Convert world coords to screen coords
function Camera:world_to_screen(wx, wy)
    return wx - self.x + self.offset_x, wy - self.y + self.offset_y
end

-- Get visible world bounds
function Camera:get_visible_bounds(screen_width, screen_height)
    local world_x, world_y = self:screen_to_world(0, 0)
    return world_x, world_y, screen_width, screen_height
end

return Camera
