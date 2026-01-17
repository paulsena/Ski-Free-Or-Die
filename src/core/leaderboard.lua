-- src/core/leaderboard.lua
-- Arcade-style high score tracking and persistence

local Leaderboard = {}

local SAVE_FILE = "highscores.dat"
local MAX_SCORES = 10

-- Structure: { name = "ABC", score = 12345, mode = "time_trial" or "endless", is_new = false }
local scores = {
    time_trial = {},
    endless = {}
}

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

-- Calculate score for time trial mode (lower is better, so invert)
-- Score = 1000000 - (time_in_seconds * 1000)
local function calculate_time_trial_score(time, gates_missed)
    local total_time = time + (gates_missed * 3)
    -- Lower time = higher score
    return math.floor(1000000 - (total_time * 1000))
end

-- Calculate score for endless mode (higher distance is better)
local function calculate_endless_score(distance)
    -- Distance in pixels / 10 = meters
    return math.floor(distance / 10)
end

-- Sort scores in descending order (higher = better)
local function sort_scores(mode_scores)
    table.sort(mode_scores, function(a, b)
        return a.score > b.score
    end)
end

--------------------------------------------------------------------------------
-- Persistence
--------------------------------------------------------------------------------

-- Save scores to file
local function save_scores()
    local success, result = pcall(function()
        local save_data = {
            version = 1,
            time_trial = scores.time_trial,
            endless = scores.endless
        }

        local serialized = require("src.lib.utils").serialize(save_data)
        love.filesystem.write(SAVE_FILE, serialized)
        return true
    end)

    if not success then
        print("Failed to save high scores: " .. tostring(result))
        return false
    end

    return result
end

-- Load scores from file
local function load_scores()
    if not love.filesystem.getInfo(SAVE_FILE) then
        -- No save file yet, use empty scores
        return
    end

    local success, result = pcall(function()
        local data = love.filesystem.read(SAVE_FILE)
        local save_data = require("src.lib.utils").deserialize(data)

        if save_data and save_data.version == 1 then
            scores.time_trial = save_data.time_trial or {}
            scores.endless = save_data.endless or {}
        end
    end)

    if not success then
        print("Failed to load high scores: " .. tostring(result))
    end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

-- Initialize the leaderboard system
function Leaderboard.init()
    load_scores()
end

-- Check if a score qualifies for the leaderboard
-- @param mode string: "time_trial" or "endless"
-- @param score number: the calculated score
-- @return boolean, number: (qualifies, rank) - rank is 1-10 if qualifies, nil otherwise
function Leaderboard.qualifies(mode, score)
    local mode_scores = scores[mode]

    if #mode_scores < MAX_SCORES then
        -- Not full yet, always qualifies
        return true, #mode_scores + 1
    end

    -- Check if score beats the lowest score
    if score > mode_scores[MAX_SCORES].score then
        -- Find the rank
        for i, entry in ipairs(mode_scores) do
            if score > entry.score then
                return true, i
            end
        end
    end

    return false, nil
end

-- Add a score to the leaderboard
-- @param mode string: "time_trial" or "endless"
-- @param name string: player initials/name (max 3-8 chars)
-- @param score number: the calculated score
-- @return number: rank (1-10) where the score was inserted
function Leaderboard.add(mode, name, score)
    local mode_scores = scores[mode]

    -- Create new entry
    local entry = {
        name = name,
        score = score,
        mode = mode,
        is_new = true,
        timestamp = os.time()
    }

    -- Insert into list
    table.insert(mode_scores, entry)

    -- Sort
    sort_scores(mode_scores)

    -- Trim to MAX_SCORES
    while #mode_scores > MAX_SCORES do
        table.remove(mode_scores)
    end

    -- Find rank
    local rank = nil
    for i, e in ipairs(mode_scores) do
        if e == entry then
            rank = i
            break
        end
    end

    -- Save to disk
    save_scores()

    return rank
end

-- Get all scores for a mode
-- @param mode string: "time_trial" or "endless"
-- @return table: array of score entries
function Leaderboard.get_scores(mode)
    return scores[mode]
end

-- Clear the "is_new" flag from all scores (call when leaving high score screen)
function Leaderboard.clear_new_flags()
    for _, mode_scores in pairs(scores) do
        for _, entry in ipairs(mode_scores) do
            entry.is_new = false
        end
    end
end

-- Calculate score from game stats
-- @param mode string: "time_trial" or "endless"
-- @param stats table: {time, distance, gates_passed, gates_missed, ...}
-- @return number: the calculated score
function Leaderboard.calculate_score(mode, stats)
    if mode == "time_trial" then
        return calculate_time_trial_score(stats.time, stats.gates_missed)
    elseif mode == "endless" then
        return calculate_endless_score(stats.distance)
    end
    return 0
end

-- Get a human-readable score display
-- @param mode string: "time_trial" or "endless"
-- @param score number: the score value
-- @return string: formatted score string
function Leaderboard.format_score(mode, score)
    if mode == "time_trial" then
        -- Convert back to time
        local time_seconds = (1000000 - score) / 1000
        local minutes = math.floor(time_seconds / 60)
        local seconds = time_seconds % 60
        return string.format("%d:%05.2f", minutes, seconds)
    elseif mode == "endless" then
        return string.format("%dm", score)
    end
    return tostring(score)
end

-- Clear all scores (for debugging/testing)
function Leaderboard.clear_all()
    scores.time_trial = {}
    scores.endless = {}
    save_scores()
end

-- Populate with dummy data for testing
function Leaderboard.add_test_data()
    -- Time trial scores (times in seconds)
    local test_times = {
        {name = "ACE", time = 45.2, gates_missed = 0},
        {name = "BOB", time = 48.5, gates_missed = 1},
        {name = "CAT", time = 52.0, gates_missed = 0},
        {name = "DAN", time = 55.8, gates_missed = 2},
        {name = "EVE", time = 58.3, gates_missed = 1},
    }

    for _, entry in ipairs(test_times) do
        local score = calculate_time_trial_score(entry.time, entry.gates_missed)
        Leaderboard.add("time_trial", entry.name, score)
    end

    -- Endless mode scores (distances in meters)
    local test_distances = {
        {name = "ZEN", distance = 5000},
        {name = "YAK", distance = 4200},
        {name = "WAX", distance = 3800},
        {name = "VIK", distance = 3200},
        {name = "UFO", distance = 2800},
    }

    for _, entry in ipairs(test_distances) do
        Leaderboard.add("endless", entry.name, entry.distance)
    end
end

return Leaderboard
