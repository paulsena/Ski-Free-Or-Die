-- src/world/world_manager.lua
-- Manages world generation, obstacles, gates, and cleanup

local Obstacle = require("src.entities.obstacle")
local Gate = require("src.entities.gate")
local SeededRandom = require("src.lib.seeded_random")
local Config = require("src.core.config")

local WorldManager = {}

-- World constants
WorldManager.SLOPE_WIDTH = 150         -- Half-width of the skiable area
WorldManager.SPAWN_AHEAD = 400         -- How far ahead to spawn content
WorldManager.DESPAWN_BEHIND = 200      -- How far behind to despawn content
WorldManager.MIN_OBSTACLE_SPACING = 30 -- Minimum Y distance between obstacles
WorldManager.GATE_CHANCE = 0.12        -- Chance to spawn gate per spawn cycle

function WorldManager.new(seed)
    seed = seed or Config.get_weekly_seed()
    local self = {
        obstacles = {},
        gates = {},
        spawn_y = 200,           -- Next spawn Y position
        last_gate_y = -1000,     -- Last gate spawn position
        min_gate_spacing = 150,  -- Minimum distance between gates
        difficulty = 1.0,        -- Difficulty multiplier (increases over time)
        -- Seeded random for deterministic generation
        rng = SeededRandom.new(seed),
        seed = seed,
        -- Statistics
        total_obstacles_spawned = 0,
        total_gates_spawned = 0
    }
    return setmetatable(self, {__index = WorldManager})
end

function WorldManager:reset()
    self.obstacles = {}
    self.gates = {}
    self.spawn_y = 200
    self.last_gate_y = -1000
    self.difficulty = 1.0
    self.total_obstacles_spawned = 0
    self.total_gates_spawned = 0
    -- Reset RNG to same seed for identical runs
    self.rng:reset()
end

function WorldManager:initial_spawn()
    -- Spawn initial content ahead of the player
    for i = 1, 15 do
        self:spawn_obstacle_cluster(self.spawn_y)
        self.spawn_y = self.spawn_y + self.rng:random_int(40, 70)
    end

    -- Spawn a few initial gates
    for i = 1, 3 do
        self:spawn_gate(200 + i * 180)
    end
end

function WorldManager:update(dt, camera_y)
    -- Update difficulty based on distance
    self.difficulty = 1.0 + (camera_y / 5000) * 0.5
    self.difficulty = math.min(2.0, self.difficulty)

    -- Spawn more content as camera advances
    while self.spawn_y < camera_y + WorldManager.SPAWN_AHEAD do
        self:spawn_obstacle_cluster(self.spawn_y)

        -- Occasionally spawn gates
        if self.rng:random() < WorldManager.GATE_CHANCE and
           self.spawn_y - self.last_gate_y > self.min_gate_spacing then
            self:spawn_gate(self.spawn_y + 30)
        end

        self.spawn_y = self.spawn_y + self.rng:random_int(35, 60)
    end

    -- Update all gates
    for _, gate in ipairs(self.gates) do
        gate:update(dt)
    end

    -- Despawn content behind camera
    self:cleanup(camera_y)
end

function WorldManager:spawn_obstacle_cluster(y)
    -- Spawn 1-3 obstacles at this Y level
    local count = self.rng:random_int(1, math.floor(1 + self.difficulty))

    for i = 1, count do
        local x = (self.rng:random() - 0.5) * WorldManager.SLOPE_WIDTH * 1.8
        local y_offset = self.rng:random_int(-20, 20)

        local obstacle = Obstacle.spawn_random_seeded(x, y + y_offset, self.rng)
        table.insert(self.obstacles, obstacle)
        self.total_obstacles_spawned = self.total_obstacles_spawned + 1
    end
end

function WorldManager:spawn_gate(y)
    -- Create a gate with slight X variation
    local x = (self.rng:random() - 0.5) * WorldManager.SLOPE_WIDTH * 0.8
    local gate = Gate.new(x, y)

    table.insert(self.gates, gate)
    self.last_gate_y = y
    self.total_gates_spawned = self.total_gates_spawned + 1
end

function WorldManager:spawn_slalom_section(start_y, gate_count)
    -- Spawn a slalom sequence
    local gates = Gate.create_slalom_sequence(
        start_y,
        gate_count or 4,
        100,  -- spacing
        WorldManager.SLOPE_WIDTH
    )

    for _, gate in ipairs(gates) do
        table.insert(self.gates, gate)
        self.total_gates_spawned = self.total_gates_spawned + 1
    end

    self.last_gate_y = start_y + (gate_count - 1) * 100
end

function WorldManager:cleanup(camera_y)
    local despawn_y = camera_y - WorldManager.DESPAWN_BEHIND

    -- Remove obstacles behind camera
    for i = #self.obstacles, 1, -1 do
        if self.obstacles[i].y < despawn_y then
            table.remove(self.obstacles, i)
        end
    end

    -- Remove gates behind camera
    for i = #self.gates, 1, -1 do
        if self.gates[i].y < despawn_y then
            table.remove(self.gates, i)
        end
    end
end

function WorldManager:get_slope_bounds()
    return {
        min_x = -WorldManager.SLOPE_WIDTH,
        max_x = WorldManager.SLOPE_WIDTH
    }
end

function WorldManager:draw(camera_y)
    local visible_top = camera_y - 200
    local visible_bottom = camera_y + 200

    -- Draw gates (behind other objects)
    for _, gate in ipairs(self.gates) do
        if gate.y > visible_top and gate.y < visible_bottom then
            gate:draw()
        end
    end

    -- Draw obstacles sorted by Y for proper overlap
    -- (objects further down drawn on top)
    local sorted_obstacles = {}
    for _, obs in ipairs(self.obstacles) do
        if obs.y > visible_top and obs.y < visible_bottom then
            table.insert(sorted_obstacles, obs)
        end
    end
    table.sort(sorted_obstacles, function(a, b) return a.y < b.y end)

    for _, obs in ipairs(sorted_obstacles) do
        obs:draw()
    end
end

-- Get all obstacles for collision checking
function WorldManager:get_obstacles()
    return self.obstacles
end

-- Get all gates for pass checking
function WorldManager:get_gates()
    return self.gates
end

return WorldManager
