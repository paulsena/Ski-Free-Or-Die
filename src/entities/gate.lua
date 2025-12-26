-- src/entities/gate.lua
-- Slalom gate entities

local Colors = require("src.colors")
local Utils = require("src.lib.utils")

local Gate = {}

Gate.WIDTH = 50          -- Default gate width
Gate.PENALTY = 3         -- Seconds added for missed gate

function Gate.new(x, y, width, direction)
    local self = {
        x = x,
        y = y,
        width = width or Gate.WIDTH,
        direction = direction or "center",  -- "left", "right", "center"
        state = "pending",                   -- "pending", "passed", "missed"
        anim_timer = 0,
        flash_timer = 0
    }
    return setmetatable(self, {__index = Gate})
end

function Gate:get_trigger_zone()
    return {
        x = self.x - self.width / 2,
        y = self.y - 8,
        width = self.width,
        height = 16
    }
end

function Gate:check_pass(skier_x, skier_y, prev_y)
    -- Only check if still pending
    if self.state ~= "pending" then
        return nil
    end

    -- Check if skier crossed the gate line
    if prev_y < self.y and skier_y >= self.y then
        -- Check if within gate width
        if math.abs(skier_x - self.x) <= self.width / 2 then
            self.state = "passed"
            self.flash_timer = 0.5
            return "passed"
        else
            self.state = "missed"
            self.flash_timer = 0.5
            return "missed"
        end
    end

    return nil
end

function Gate:update(dt)
    self.anim_timer = self.anim_timer + dt
    if self.flash_timer > 0 then
        self.flash_timer = self.flash_timer - dt
    end
end

function Gate:draw()
    local color
    local pole_height = 20
    local banner_height = 6

    -- Determine color based on state
    if self.state == "passed" then
        color = Colors.GATE_PASSED
    elseif self.state == "missed" then
        color = Colors.GATE_MISSED
    else
        color = Colors.GATE_PENDING
    end

    -- Flash effect when state just changed
    if self.flash_timer > 0 and math.floor(self.flash_timer * 10) % 2 == 0 then
        color = Colors.SNOW_WHITE
    end

    -- Draw shadows
    love.graphics.setColor(0, 0, 0, 0.15)
    love.graphics.ellipse("fill", self.x - self.width/2 + 2, self.y + 12, 3, 2)
    love.graphics.ellipse("fill", self.x + self.width/2 + 2, self.y + 12, 3, 2)

    -- Left pole
    Colors.set(color)
    love.graphics.rectangle("fill",
        self.x - self.width/2 - 2,
        self.y - pole_height/2,
        4, pole_height,
        1, 1
    )

    -- Right pole
    love.graphics.rectangle("fill",
        self.x + self.width/2 - 2,
        self.y - pole_height/2,
        4, pole_height,
        1, 1
    )

    -- Banner between poles
    love.graphics.rectangle("fill",
        self.x - self.width/2,
        self.y - pole_height/2,
        self.width,
        banner_height,
        1, 1
    )

    -- Banner stripes (alternating pattern)
    local stripe_width = self.width / 5
    for i = 0, 4 do
        if i % 2 == 0 then
            Colors.set(Colors.SNOW_WHITE)
        else
            Colors.set(color)
        end
        love.graphics.rectangle("fill",
            self.x - self.width/2 + i * stripe_width,
            self.y - pole_height/2,
            stripe_width,
            banner_height
        )
    end

    -- Pole tops (little balls)
    Colors.set(color)
    love.graphics.circle("fill", self.x - self.width/2, self.y - pole_height/2 - 2, 3)
    love.graphics.circle("fill", self.x + self.width/2, self.y - pole_height/2 - 2, 3)

    -- Direction arrow indicator (subtle)
    if self.state == "pending" then
        love.graphics.setColor(1, 1, 1, 0.5 + math.sin(self.anim_timer * 4) * 0.3)
        local arrow_y = self.y - pole_height - 8
        love.graphics.polygon("fill",
            self.x, arrow_y,
            self.x - 6, arrow_y - 8,
            self.x + 6, arrow_y - 8
        )
    end
end

-- Create a sequence of gates for slalom sections
function Gate.create_slalom_sequence(start_y, count, spacing, slope_width)
    local gates = {}
    local alternating = math.random() > 0.5

    for i = 1, count do
        local y = start_y + (i - 1) * spacing
        local x_offset

        if alternating then
            -- Alternating left/right pattern
            if i % 2 == 1 then
                x_offset = -slope_width * 0.3
            else
                x_offset = slope_width * 0.3
            end
        else
            -- Random positions with constraints
            x_offset = (math.random() - 0.5) * slope_width * 0.6
        end

        local gate = Gate.new(x_offset, y)
        table.insert(gates, gate)
    end

    return gates
end

return Gate
