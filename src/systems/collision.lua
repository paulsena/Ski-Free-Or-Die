-- src/systems/collision.lua
-- Collision detection and response system

local Utils = require("src.lib.utils")

local Collision = {}

-- Check circle vs rectangle collision
function Collision.circle_rect(cx, cy, radius, rx, ry, rw, rh)
    local closest_x = Utils.clamp(cx, rx, rx + rw)
    local closest_y = Utils.clamp(cy, ry, ry + rh)
    local dist = Utils.distance(cx, cy, closest_x, closest_y)
    return dist < radius
end

-- Check circle vs circle collision
function Collision.circle_circle(x1, y1, r1, x2, y2, r2)
    return Utils.distance(x1, y1, x2, y2) < r1 + r2
end

-- Check rectangle vs rectangle collision (AABB)
function Collision.rect_rect(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end

-- Check skier collision against a list of obstacles
-- Returns the first obstacle collided with, or nil
function Collision.check_skier_obstacles(skier, obstacles)
    local hitbox = skier:get_hitbox()

    for _, obs in ipairs(obstacles) do
        if obs:check_collision(hitbox) then
            return obs
        end
    end

    return nil
end

-- Handle collision response between skier and obstacle
function Collision.resolve_obstacle_collision(skier, obstacle, camera)
    if obstacle.collision_type == "slow" then
        -- Just slow down
        skier:slow_down(obstacle.speed_penalty)

    elseif obstacle.collision_type == "deflect" then
        -- Slow down and deflect
        skier:slow_down(obstacle.speed_penalty)
        skier:deflect()
        if camera then
            camera:shake(2, 0.2)
        end

    elseif obstacle.collision_type == "crash" then
        -- Full crash
        skier:crash()
        if camera then
            camera:shake(4, 0.4)
        end
    end
end

-- Check skier passing through gates
-- Returns number of gates passed and missed in this frame
function Collision.check_skier_gates(skier, prev_y, gates)
    local passed = 0
    local missed = 0

    for _, gate in ipairs(gates) do
        local result = gate:check_pass(skier.x, skier.y, prev_y)
        if result == "passed" then
            passed = passed + 1
        elseif result == "missed" then
            missed = missed + 1
        end
    end

    return passed, missed
end

-- Broad phase collision filtering
-- Returns only obstacles that are near the skier
function Collision.get_nearby_obstacles(skier, obstacles, radius)
    radius = radius or 100
    local nearby = {}

    for _, obs in ipairs(obstacles) do
        if Utils.distance(skier.x, skier.y, obs.x, obs.y) < radius then
            table.insert(nearby, obs)
        end
    end

    return nearby
end

-- Get separation vector to push skier out of obstacle
function Collision.get_separation(skier_x, skier_y, skier_radius, obs)
    local hb = obs:get_hitbox()
    local closest_x = Utils.clamp(skier_x, hb.x, hb.x + hb.width)
    local closest_y = Utils.clamp(skier_y, hb.y, hb.y + hb.height)

    local dx = skier_x - closest_x
    local dy = skier_y - closest_y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist == 0 then
        return 1, 0  -- Default push direction
    end

    local overlap = skier_radius - dist
    return (dx / dist) * overlap, (dy / dist) * overlap
end

return Collision
