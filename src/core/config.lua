-- src/core/config.lua
-- Centralized game configuration

local Config = {}

-- Display settings (3:4 portrait ratio for vertical skiing view)
Config.GAME_WIDTH = 360
Config.GAME_HEIGHT = 480
Config.SCALE = 3

-- Physics (scaled for 360x480 resolution)
Config.BASE_SPEED = 140
Config.MAX_SPEED = 320

-- Weekly seed (would be fetched from server in production)
Config.WEEKLY_SEED = 20251225  -- Christmas 2025!

-- Difficulty settings
Config.DIFFICULTY_INCREASE_RATE = 0.5  -- Per 5000 pixels
Config.MAX_DIFFICULTY = 2.0

-- Yeti settings (scaled for 360x480 resolution)
Config.YETI_START_DISTANCE = 600
Config.YETI_BASE_SPEED = 100
Config.YETI_SPEED_INCREASE_RATE = 0.01

-- Gate settings (scaled for 360x480 resolution)
Config.GATE_PENALTY = 3  -- Seconds added for missed gate
Config.GATE_WIDTH = 75

-- Spawn settings (scaled for 360x480 resolution)
Config.SPAWN_AHEAD = 550
Config.DESPAWN_BEHIND = 300

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
