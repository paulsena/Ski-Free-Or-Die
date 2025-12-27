-- src/world/tile_data.lua
-- Tile data structures for procedural generation

local TileData = {}

-- Tile type enumeration
TileData.TileType = {
    WARMUP = "warmup",
    SLALOM = "slalom",
    OBSTACLE_FIELD = "obstacle_field",
    SPEED = "speed",
    RAMP = "ramp",
    CHOICE = "choice",
    SET_PIECE = "set_piece"
}

-- Slope intensity enumeration
TileData.SlopeIntensity = {
    GENTLE = "gentle",
    MODERATE = "moderate",
    STEEP = "steep"
}

-- Slope intensity multipliers (affects skier speed)
TileData.SLOPE_MULTIPLIERS = {
    gentle = 0.85,
    moderate = 1.0,
    steep = 1.2
}

-- Tile dimension constants (scaled for 360x480 resolution)
TileData.TILE_HEIGHT = 400          -- Vertical length of each tile (roughly 3-5 seconds of skiing)
TileData.TILE_WIDTH = 340           -- Width of skiable area (slightly less than screen width)
TileData.TRANSITION_ZONE = 50       -- Safe zone at tile edges (no obstacles)

-- Slalom variants
TileData.SlalomVariant = {
    EASY = "easy",
    MEDIUM = "medium",
    HARD = "hard"
}

-- Obstacle field variants
TileData.ObstacleFieldVariant = {
    FOREST_RUN = "forest_run",
    ROCK_GARDEN = "rock_garden",
    MIXED_HAZARD = "mixed_hazard"
}

-- Set piece types (handcrafted memorable sections)
TileData.SetPieceType = {
    CABIN_CHICANE = "cabin_chicane",
    THE_GAUNTLET = "the_gauntlet",
    SKI_LIFT_ALLEY = "ski_lift_alley",
    SPECTATOR_ROW = "spectator_row"
}

-- Tile definition templates
-- These define constraints for procedural content within tiles
TileData.TILE_TEMPLATES = {
    -- Warmup tiles
    warmup = {
        type = TileData.TileType.WARMUP,
        slope = TileData.SlopeIntensity.GENTLE,
        difficulty = 1,
        obstacle_density = 0.2,         -- Low density
        obstacle_types = {"small_tree"},
        gate_count = {0, 1},            -- Range: 0-1 gates
        gate_spacing = "wide"
    },

    -- Slalom variants
    slalom_easy = {
        type = TileData.TileType.SLALOM,
        variant = TileData.SlalomVariant.EASY,
        slope = TileData.SlopeIntensity.GENTLE,
        difficulty = 2,
        obstacle_density = 0.0,
        obstacle_types = {},
        gate_count = {2, 3},
        gate_spacing = "wide"
    },
    slalom_medium = {
        type = TileData.TileType.SLALOM,
        variant = TileData.SlalomVariant.MEDIUM,
        slope = TileData.SlopeIntensity.MODERATE,
        difficulty = 3,
        obstacle_density = 0.3,
        obstacle_types = {"small_tree"},
        gate_count = {3, 4},
        gate_spacing = "normal"
    },
    slalom_hard = {
        type = TileData.TileType.SLALOM,
        variant = TileData.SlalomVariant.HARD,
        slope = TileData.SlopeIntensity.STEEP,
        difficulty = 4,
        obstacle_density = 0.5,
        obstacle_types = {"small_tree", "large_tree"},
        gate_count = {4, 5},
        gate_spacing = "tight"
    },

    -- Obstacle field variants
    obstacle_forest = {
        type = TileData.TileType.OBSTACLE_FIELD,
        variant = TileData.ObstacleFieldVariant.FOREST_RUN,
        slope = TileData.SlopeIntensity.MODERATE,
        difficulty = 3,
        obstacle_density = 0.7,
        obstacle_types = {"small_tree", "large_tree"},
        gate_count = {0, 0}
    },
    obstacle_rocks = {
        type = TileData.TileType.OBSTACLE_FIELD,
        variant = TileData.ObstacleFieldVariant.ROCK_GARDEN,
        slope = TileData.SlopeIntensity.MODERATE,
        difficulty = 4,
        obstacle_density = 0.5,
        obstacle_types = {"rock"},
        gate_count = {0, 0}
    },
    obstacle_mixed = {
        type = TileData.TileType.OBSTACLE_FIELD,
        variant = TileData.ObstacleFieldVariant.MIXED_HAZARD,
        slope = TileData.SlopeIntensity.STEEP,
        difficulty = 5,
        obstacle_density = 0.8,
        obstacle_types = {"small_tree", "large_tree", "rock", "cabin"},
        gate_count = {0, 0}
    },

    -- Speed tiles (breathing room)
    speed = {
        type = TileData.TileType.SPEED,
        slope = TileData.SlopeIntensity.STEEP,
        difficulty = 1,
        obstacle_density = 0.1,
        obstacle_types = {"small_tree"},
        gate_count = {0, 0}
    },

    -- Ramp tile (future use)
    ramp = {
        type = TileData.TileType.RAMP,
        slope = TileData.SlopeIntensity.MODERATE,
        difficulty = 3,
        obstacle_density = 0.2,
        obstacle_types = {"small_tree"},
        gate_count = {0, 0},
        has_ramp = true
    }
}

-- Gate spacing constants (scaled for 360x480 resolution)
TileData.GATE_SPACING = {
    wide = 120,      -- Easy: lots of room
    normal = 100,    -- Medium: moderate challenge
    tight = 75       -- Hard: precision required
}

-- Create a new tile instance from a template
function TileData.new(template_name, y_position)
    local template = TileData.TILE_TEMPLATES[template_name]
    if not template then
        error("Unknown tile template: " .. tostring(template_name))
    end

    local self = {
        template_name = template_name,
        type = template.type,
        variant = template.variant,
        slope = template.slope,
        difficulty = template.difficulty,
        obstacle_density = template.obstacle_density,
        obstacle_types = template.obstacle_types,
        gate_count = template.gate_count,
        gate_spacing = template.gate_spacing,
        has_ramp = template.has_ramp,

        -- Position in world
        y_start = y_position,
        y_end = y_position + TileData.TILE_HEIGHT,

        -- Generated content (filled by tile_generator)
        obstacles = {},
        gates = {}
    }

    return setmetatable(self, {__index = TileData})
end

-- Get the slope speed multiplier for this tile
function TileData:get_slope_multiplier()
    return TileData.SLOPE_MULTIPLIERS[self.slope] or 1.0
end

-- Check if a Y position is within this tile
function TileData:contains_y(y)
    return y >= self.y_start and y < self.y_end
end

-- Check if Y is in the transition zone (top or bottom edges)
function TileData:is_transition_zone(y)
    local rel_y = y - self.y_start
    return rel_y < TileData.TRANSITION_ZONE or rel_y > (TileData.TILE_HEIGHT - TileData.TRANSITION_ZONE)
end

-- Get available templates for a given difficulty range
function TileData.get_templates_for_difficulty(min_diff, max_diff)
    local templates = {}
    for name, template in pairs(TileData.TILE_TEMPLATES) do
        if template.difficulty >= min_diff and template.difficulty <= max_diff then
            table.insert(templates, name)
        end
    end
    return templates
end

-- Get templates by type
function TileData.get_templates_by_type(tile_type)
    local templates = {}
    for name, template in pairs(TileData.TILE_TEMPLATES) do
        if template.type == tile_type then
            table.insert(templates, name)
        end
    end
    return templates
end

return TileData
