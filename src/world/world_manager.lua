-- src/world/world_manager.lua
-- Manages world generation, obstacles, gates, and cleanup
-- Uses tile-based procedural generation for deterministic courses

local Obstacle = require("src.entities.obstacle")
local Gate = require("src.entities.gate")
local SeededRandom = require("src.lib.seeded_random")
local TileData = require("src.world.tile_data")
local TileGenerator = require("src.world.tile_generator")
local Config = require("src.core.config")

local WorldManager = {}

-- World constants
WorldManager.SLOPE_WIDTH = 150         -- Half-width of the skiable area
WorldManager.SPAWN_AHEAD = 400         -- How far ahead to spawn content
WorldManager.DESPAWN_BEHIND = 200      -- How far behind to despawn content

function WorldManager.new(seed, mode)
    seed = seed or Config.get_weekly_seed()
    mode = mode or "time_trial"

    local self = {
        obstacles = {},
        gates = {},
        mode = mode,
        seed = seed,
        -- Tile generator for procedural content
        tile_generator = TileGenerator.new(seed, mode),
        -- Separate RNG for visual variations
        visual_rng = SeededRandom.new(seed + 12345),
        -- Track spawned tiles to avoid re-spawning
        spawned_tile_indices = {},
        -- Current tile index for endless mode
        next_tile_y = 0,
        -- Statistics
        total_obstacles_spawned = 0,
        total_gates_spawned = 0,
        -- Course finish line position (for time trial)
        finish_line_y = nil
    }
    return setmetatable(self, {__index = WorldManager})
end

function WorldManager:reset()
    self.obstacles = {}
    self.gates = {}
    self.spawned_tile_indices = {}
    self.next_tile_y = 0
    self.total_obstacles_spawned = 0
    self.total_gates_spawned = 0
    self.finish_line_y = nil

    -- Reset generators to same seed for identical runs
    self.tile_generator:reset()
    self.visual_rng:reset()

    -- Generate fresh course
    if self.mode == "time_trial" then
        self:generate_time_trial_course()
    else
        self:generate_initial_endless_tiles()
    end
end

-- Generate a complete time trial course
function WorldManager:generate_time_trial_course()
    local tiles = self.tile_generator:generate_time_trial_course()

    -- Spawn all tile content
    for idx, tile in ipairs(tiles) do
        self:spawn_tile_content(tile, idx)
    end

    -- Set finish line at end of course
    self.finish_line_y = self.tile_generator:get_total_height()
end

-- Generate initial tiles for endless mode
function WorldManager:generate_initial_endless_tiles()
    local initial_count = TileGenerator.ENDLESS_INITIAL_TILES
    self.next_tile_y = 0

    for i = 1, initial_count do
        local tile = self.tile_generator:generate_next_endless_tile(self.next_tile_y)
        self:spawn_tile_content(tile, i)
        self.next_tile_y = tile.y_end
    end
end

-- Initial spawn (called when game starts)
function WorldManager:initial_spawn()
    if self.mode == "time_trial" then
        self:generate_time_trial_course()
    else
        self:generate_initial_endless_tiles()
    end
end

function WorldManager:update(dt, camera_y)
    -- For endless mode, generate more tiles as needed
    if self.mode == "endless" then
        while self.next_tile_y < camera_y + WorldManager.SPAWN_AHEAD do
            local tile_idx = #self.tile_generator:get_tiles() + 1
            local tile = self.tile_generator:generate_next_endless_tile(self.next_tile_y)
            self:spawn_tile_content(tile, tile_idx)
            self.next_tile_y = tile.y_end
        end
    end

    -- Update all gates
    for _, gate in ipairs(self.gates) do
        gate:update(dt)
    end

    -- Despawn content behind camera
    self:cleanup(camera_y)
end

-- Spawn obstacles and gates from a tile definition
function WorldManager:spawn_tile_content(tile, tile_idx)
    -- Avoid re-spawning tiles
    if self.spawned_tile_indices[tile_idx] then
        return
    end
    self.spawned_tile_indices[tile_idx] = true

    -- Spawn obstacles defined in the tile
    for _, obs_def in ipairs(tile.obstacles) do
        local obstacle = Obstacle.new_seeded(
            obs_def.x,
            obs_def.y,
            obs_def.type,
            self.visual_rng
        )
        table.insert(self.obstacles, obstacle)
        self.total_obstacles_spawned = self.total_obstacles_spawned + 1
    end

    -- Spawn gates defined in the tile
    for _, gate_def in ipairs(tile.gates) do
        local gate = Gate.new(gate_def.x, gate_def.y)
        table.insert(self.gates, gate)
        self.total_gates_spawned = self.total_gates_spawned + 1
    end
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

-- Get slope speed multiplier at a Y position
function WorldManager:get_slope_multiplier(y)
    return self.tile_generator:get_slope_multiplier_at_y(y)
end

-- Get current tile at Y position
function WorldManager:get_tile_at_y(y)
    return self.tile_generator:get_tile_at_y(y)
end

function WorldManager:get_slope_bounds()
    return {
        min_x = -WorldManager.SLOPE_WIDTH,
        max_x = WorldManager.SLOPE_WIDTH
    }
end

-- Get finish line Y position (for time trial mode)
function WorldManager:get_finish_line_y()
    return self.finish_line_y
end

-- Check if player has crossed finish line
function WorldManager:check_finish(skier_y)
    if self.mode == "time_trial" and self.finish_line_y then
        return skier_y >= self.finish_line_y
    end
    return false
end

function WorldManager:draw(camera_y)
    local visible_top = camera_y - 200
    local visible_bottom = camera_y + 200

    -- Draw tile backgrounds/indicators (optional, for debugging)
    -- self:draw_tile_debug(camera_y)

    -- Draw finish line if in view (time trial mode)
    if self.finish_line_y and self.finish_line_y > visible_top and self.finish_line_y < visible_bottom then
        self:draw_finish_line()
    end

    -- Draw gates (behind other objects)
    for _, gate in ipairs(self.gates) do
        if gate.y > visible_top and gate.y < visible_bottom then
            gate:draw()
        end
    end

    -- Draw obstacles sorted by Y for proper overlap
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

function WorldManager:draw_finish_line()
    local x_left = -WorldManager.SLOPE_WIDTH
    local x_right = WorldManager.SLOPE_WIDTH
    local y = self.finish_line_y

    -- Checkered pattern finish line
    local checker_size = 10
    local num_checkers = math.ceil((x_right - x_left) / checker_size)

    for i = 0, num_checkers - 1 do
        local x = x_left + i * checker_size

        -- Alternating black and white
        if i % 2 == 0 then
            love.graphics.setColor(0, 0, 0)
        else
            love.graphics.setColor(1, 1, 1)
        end
        love.graphics.rectangle("fill", x, y - 5, checker_size, 10)
    end

    -- "FINISH" text
    love.graphics.setColor(1, 0.8, 0)
    love.graphics.printf("FINISH", x_left, y - 25, x_right - x_left, "center")
end

-- Debug visualization of tiles
function WorldManager:draw_tile_debug(camera_y)
    local tiles = self.tile_generator:get_tiles()

    for _, tile in ipairs(tiles) do
        if tile.y_end > camera_y - 100 and tile.y_start < camera_y + 200 then
            -- Draw tile boundary
            love.graphics.setColor(1, 1, 1, 0.1)
            love.graphics.rectangle("line",
                -WorldManager.SLOPE_WIDTH,
                tile.y_start,
                WorldManager.SLOPE_WIDTH * 2,
                TileData.TILE_HEIGHT
            )

            -- Label tile type
            love.graphics.setColor(1, 1, 1, 0.3)
            love.graphics.print(tile.template_name or tile.type, -WorldManager.SLOPE_WIDTH + 5, tile.y_start + 5)
        end
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

-- Get tile generator for external access
function WorldManager:get_tile_generator()
    return self.tile_generator
end

return WorldManager
