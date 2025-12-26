-- src/lib/utils.lua
-- Common utility functions

local Utils = {}

-- Clamp a value between min and max
function Utils.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Linear interpolation
function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

-- Distance between two points
function Utils.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Check if two circles overlap
function Utils.circles_collide(x1, y1, r1, x2, y2, r2)
    return Utils.distance(x1, y1, x2, y2) < r1 + r2
end

-- Check if two AABBs overlap
function Utils.aabb_collide(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end

-- Check if point is inside rectangle
function Utils.point_in_rect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

-- Sign of a number (-1, 0, or 1)
function Utils.sign(x)
    if x > 0 then return 1
    elseif x < 0 then return -1
    else return 0 end
end

-- Round to nearest integer
function Utils.round(x)
    return math.floor(x + 0.5)
end

-- Normalize an angle to [-pi, pi]
function Utils.normalize_angle(angle)
    while angle > math.pi do angle = angle - 2 * math.pi end
    while angle < -math.pi do angle = angle + 2 * math.pi end
    return angle
end

-- Convert degrees to radians
function Utils.deg_to_rad(degrees)
    return degrees * math.pi / 180
end

-- Convert radians to degrees
function Utils.rad_to_deg(radians)
    return radians * 180 / math.pi
end

-- Smooth damp (for smooth camera following, etc.)
function Utils.smooth_damp(current, target, velocity, smooth_time, dt)
    local omega = 2 / smooth_time
    local x = omega * dt
    local exp_factor = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x)
    local change = current - target
    local temp = (velocity + omega * change) * dt
    velocity = (velocity - omega * temp) * exp_factor
    local output = target + (change + temp) * exp_factor
    return output, velocity
end

-- Format time as MM:SS.ms
function Utils.format_time(seconds)
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%05.2f", mins, secs)
end

-- Deep copy a table
function Utils.deep_copy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for k, v in pairs(orig) do
            copy[k] = Utils.deep_copy(v)
        end
    else
        copy = orig
    end
    return copy
end

return Utils
