-- src/core/config.lua
-- Centralized game configuration

local Config = {}

-- Display settings
Config.GAME_WIDTH = 480
Config.GAME_HEIGHT = 270
Config.SCALE = 4

-- Physics
Config.BASE_SPEED = 80
Config.MAX_SPEED = 200

-- Weekly seed (would be fetched from server in production)
Config.WEEKLY_SEED = 20251225  -- Christmas 2025!

-- Difficulty settings
Config.DIFFICULTY_INCREASE_RATE = 0.5  -- Per 5000 pixels
Config.MAX_DIFFICULTY = 2.0

-- Yeti settings
Config.YETI_START_DISTANCE = 500
Config.YETI_BASE_SPEED = 70
Config.YETI_SPEED_INCREASE_RATE = 0.01

-- Gate settings
Config.GATE_PENALTY = 3  -- Seconds added for missed gate
Config.GATE_WIDTH = 50

-- Spawn settings
Config.SPAWN_AHEAD = 400
Config.DESPAWN_BEHIND = 200

-- Get a deterministic seed for the current week
function Config.get_weekly_seed()
    -- In production, this would fetch from a server
    -- For now, use a simple formula based on date
    local date = os.date("*t")
    -- ISO week number calculation
    local year = date.year
    local day_of_year = date.yday
    local week = math.ceil(day_of_year / 7)
    return year * 100 + week
end

return Config
