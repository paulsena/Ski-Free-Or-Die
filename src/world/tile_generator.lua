-- src/world/tile_generator.lua
-- Generates tile sequences from seeds with pacing rules and difficulty curves

local TileData = require("src.world.tile_data")
local SeededRandom = require("src.lib.seeded_random")
local Obstacle = require("src.entities.obstacle")
local Gate = require("src.entities.gate")

local TileGenerator = {}

-- Course configuration
TileGenerator.TIME_TRIAL_TILES = 20      -- Approximately 60-90 seconds of gameplay
TileGenerator.ENDLESS_INITIAL_TILES = 10 -- Initial tiles for endless mode

-- Difficulty phases (percent of course completion)
TileGenerator.DIFFICULTY_PHASES = {
    {max_percent = 0.25, min_diff = 1, max_diff = 2, name = "warmup"},
    {max_percent = 0.50, min_diff = 2, max_diff = 3, name = "rising"},
    {max_percent = 0.75, min_diff = 3, max_diff = 4, name = "challenge"},
    {max_percent = 1.00, min_diff = 4, max_diff = 5, name = "climax"}
}

-- Set piece insertion points (tile indices for a 20-tile course)
TileGenerator.SET_PIECE_POSITIONS = {8, 15}  -- Midpoint and near end

function TileGenerator.new(seed, mode)
    local self = {
        rng = SeededRandom.new(seed),
        seed = seed,
        mode = mode or "time_trial",
        tiles = {},
        total_tiles_generated = 0,
        last_tile_difficulty = 0,
        hard_tile_count = 0,      -- Track consecutive hard tiles
        tiles_since_speed = 0     -- Track tiles since last speed tile
    }
    return setmetatable(self, {__index = TileGenerator})
end

-- Reset generator to initial state
function TileGenerator:reset()
    self.rng:reset()
    self.tiles = {}
    self.total_tiles_generated = 0
    self.last_tile_difficulty = 0
    self.hard_tile_count = 0
    self.tiles_since_speed = 0
end

-- Generate a complete time trial course
function TileGenerator:generate_time_trial_course()
    self:reset()

    local num_tiles = TileGenerator.TIME_TRIAL_TILES
    local y_position = 0

    for i = 1, num_tiles do
        local progress = i / num_tiles
        local tile = self:generate_tile(progress, y_position, i)
        table.insert(self.tiles, tile)
        y_position = tile.y_end
        self.total_tiles_generated = i
    end

    return self.tiles
end

-- Generate next tile for endless mode
function TileGenerator:generate_next_endless_tile(y_position)
    self.total_tiles_generated = self.total_tiles_generated + 1

    -- Endless mode: difficulty keeps increasing
    -- After 30 tiles, difficulty is maxed but density increases
    local effective_tile = math.min(self.total_tiles_generated, 30)
    local progress = effective_tile / 30

    local tile = self:generate_tile(progress, y_position, self.total_tiles_generated)
    table.insert(self.tiles, tile)

    return tile
end

-- Generate a single tile based on progress and pacing rules
function TileGenerator:generate_tile(progress, y_position, tile_index)
    -- Determine difficulty phase
    local phase = self:get_difficulty_phase(progress)

    -- Check for set piece positions
    if self:is_set_piece_position(tile_index) then
        return self:generate_set_piece_tile(y_position)
    end

    -- Get valid templates based on difficulty and pacing rules
    local valid_templates = self:get_valid_templates(phase)

    -- Select a template
    local template_name = self.rng:choose(valid_templates)
    if not template_name then
        template_name = "warmup"  -- Fallback
    end

    -- Create the tile
    local tile = TileData.new(template_name, y_position)

    -- Populate tile with content
    self:populate_tile(tile)

    -- Update pacing state
    self:update_pacing_state(tile)

    return tile
end

-- Get difficulty phase for progress
function TileGenerator:get_difficulty_phase(progress)
    for _, phase in ipairs(TileGenerator.DIFFICULTY_PHASES) do
        if progress <= phase.max_percent then
            return phase
        end
    end
    return TileGenerator.DIFFICULTY_PHASES[#TileGenerator.DIFFICULTY_PHASES]
end

-- Check if current tile index should be a set piece
function TileGenerator:is_set_piece_position(tile_index)
    for _, pos in ipairs(TileGenerator.SET_PIECE_POSITIONS) do
        if tile_index == pos then
            return true
        end
    end
    return false
end

-- Generate a set piece tile
function TileGenerator:generate_set_piece_tile(y_position)
    local set_pieces = {"cabin_chicane", "the_gauntlet", "ski_lift_alley", "spectator_row"}
    local set_piece_type = self.rng:choose(set_pieces)

    -- Create a custom tile for set pieces
    local tile = {
        template_name = "set_piece_" .. set_piece_type,
        type = TileData.TileType.SET_PIECE,
        set_piece_type = set_piece_type,
        slope = TileData.SlopeIntensity.MODERATE,
        difficulty = 4,
        y_start = y_position,
        y_end = y_position + TileData.TILE_HEIGHT,
        obstacles = {},
        gates = {}
    }

    setmetatable(tile, {__index = TileData})

    -- Populate with set piece content
    self:populate_set_piece(tile)

    return tile
end

-- Get valid templates based on pacing rules
function TileGenerator:get_valid_templates(phase)
    local valid = {}
    local all_templates = TileData.get_templates_for_difficulty(phase.min_diff, phase.max_diff)

    for _, template_name in ipairs(all_templates) do
        local template = TileData.TILE_TEMPLATES[template_name]

        -- Pacing rule: No two hard tiles back-to-back
        if template.difficulty >= 4 and self.hard_tile_count >= 1 then
            goto continue
        end

        -- Pacing rule: Speed tile after 2-3 technical tiles
        if self.tiles_since_speed >= 3 and template.type ~= TileData.TileType.SPEED then
            -- Force speed tile consideration
            if self.rng:random() < 0.7 then
                goto continue
            end
        end

        -- Special handling for warmup phase - only warmup tiles
        if phase.name == "warmup" and template.type ~= TileData.TileType.WARMUP then
            -- Allow some easy slalom in warmup
            if template.type ~= TileData.TileType.SLALOM or template.difficulty > 2 then
                goto continue
            end
        end

        table.insert(valid, template_name)

        ::continue::
    end

    -- If no valid templates, add at least warmup
    if #valid == 0 then
        table.insert(valid, "warmup")
    end

    -- Add speed tile option if we've had too many technical tiles
    if self.tiles_since_speed >= 2 and not self:contains_template(valid, "speed") then
        table.insert(valid, "speed")
    end

    return valid
end

-- Check if a template list contains a specific template
function TileGenerator:contains_template(templates, name)
    for _, t in ipairs(templates) do
        if t == name then
            return true
        end
    end
    return false
end

-- Update pacing state after generating a tile
function TileGenerator:update_pacing_state(tile)
    self.last_tile_difficulty = tile.difficulty

    -- Track hard tile streaks
    if tile.difficulty >= 4 then
        self.hard_tile_count = self.hard_tile_count + 1
    else
        self.hard_tile_count = 0
    end

    -- Track tiles since speed
    if tile.type == TileData.TileType.SPEED then
        self.tiles_since_speed = 0
    else
        self.tiles_since_speed = self.tiles_since_speed + 1
    end
end

-- Populate a tile with obstacles and gates
function TileGenerator:populate_tile(tile)
    local half_width = TileData.TILE_WIDTH / 2

    -- Generate obstacles
    if tile.obstacle_density and tile.obstacle_density > 0 then
        local num_obstacles = math.floor(tile.obstacle_density * 8)  -- 0-8 obstacles per tile

        for i = 1, num_obstacles do
            local x = self.rng:random_float(-half_width * 0.9, half_width * 0.9)
            local y = tile.y_start + TileData.TRANSITION_ZONE +
                      self.rng:random_float(0, TileData.TILE_HEIGHT - 2 * TileData.TRANSITION_ZONE)

            -- Choose obstacle type from template's allowed types
            local obs_type = "small_tree"
            if tile.obstacle_types and #tile.obstacle_types > 0 then
                obs_type = self.rng:choose(tile.obstacle_types)
            end

            table.insert(tile.obstacles, {
                type = obs_type,
                x = x,
                y = y
            })
        end
    end

    -- Generate gates for slalom tiles
    if tile.gate_count then
        local min_gates, max_gates = tile.gate_count[1], tile.gate_count[2]
        local num_gates = self.rng:random_int(min_gates, max_gates)

        if num_gates > 0 then
            local spacing = TileData.GATE_SPACING[tile.gate_spacing or "normal"] or 80
            local available_height = TileData.TILE_HEIGHT - 2 * TileData.TRANSITION_ZONE
            local actual_spacing = math.min(spacing, available_height / num_gates)

            local start_y = tile.y_start + TileData.TRANSITION_ZONE + 20
            local alternate = self.rng:random_bool()  -- Start left or right

            for i = 1, num_gates do
                -- Alternate gates left and right
                local x_offset = half_width * 0.4
                local x = alternate and -x_offset or x_offset
                alternate = not alternate

                -- Add some random variation
                x = x + self.rng:random_float(-20, 20)

                table.insert(tile.gates, {
                    x = x,
                    y = start_y + (i - 1) * actual_spacing
                })
            end
        end
    end
end

-- Populate set piece tiles with handcrafted content
function TileGenerator:populate_set_piece(tile)
    local half_width = TileData.TILE_WIDTH / 2

    if tile.set_piece_type == "cabin_chicane" then
        -- Tight weave between cabins
        local positions = {
            {x = -40, y = tile.y_start + 60},
            {x = 40, y = tile.y_start + 120},
            {x = -30, y = tile.y_start + 180},
            {x = 50, y = tile.y_start + 240}
        }
        for _, pos in ipairs(positions) do
            table.insert(tile.obstacles, {type = "cabin", x = pos.x, y = pos.y})
        end

    elseif tile.set_piece_type == "the_gauntlet" then
        -- Dense obstacles with one clean line
        for i = 1, 20 do
            local x = self.rng:random_float(-half_width * 0.9, half_width * 0.9)
            local y = tile.y_start + TileData.TRANSITION_ZONE +
                      self.rng:random_float(0, TileData.TILE_HEIGHT - 2 * TileData.TRANSITION_ZONE)

            -- Leave a narrow path down the center
            if math.abs(x) > 25 then
                local obs_type = self.rng:random_bool(0.6) and "large_tree" or "rock"
                table.insert(tile.obstacles, {type = obs_type, x = x, y = y})
            end
        end

    elseif tile.set_piece_type == "ski_lift_alley" then
        -- Poles in regular pattern (like ski lift poles)
        for i = 0, 5 do
            local y = tile.y_start + 40 + i * 50
            table.insert(tile.obstacles, {type = "small_tree", x = -60, y = y})
            table.insert(tile.obstacles, {type = "small_tree", x = 60, y = y})
        end

    elseif tile.set_piece_type == "spectator_row" then
        -- No obstacles - just speed! The vibes tile.
        -- Could add spectator sprites on the sides later
        tile.slope = TileData.SlopeIntensity.STEEP
    end
end

-- Get tile at Y position
function TileGenerator:get_tile_at_y(y)
    for _, tile in ipairs(self.tiles) do
        if y >= tile.y_start and y < tile.y_end then
            return tile
        end
    end
    return nil
end

-- Get slope multiplier at Y position
function TileGenerator:get_slope_multiplier_at_y(y)
    local tile = self:get_tile_at_y(y)
    if tile and tile.slope then
        return TileData.SLOPE_MULTIPLIERS[tile.slope] or 1.0
    end
    return 1.0
end

-- Get all tiles
function TileGenerator:get_tiles()
    return self.tiles
end

-- Get total world height (for finish line placement)
function TileGenerator:get_total_height()
    if #self.tiles == 0 then
        return 0
    end
    return self.tiles[#self.tiles].y_end
end

return TileGenerator
