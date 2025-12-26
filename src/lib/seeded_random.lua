-- src/lib/seeded_random.lua
-- Deterministic seeded random number generator
-- Uses a simple but effective Linear Congruential Generator (LCG)
-- Same seed always produces same sequence of numbers

local SeededRandom = {}

-- LCG parameters (same as MINSTD)
local MULTIPLIER = 48271
local MODULUS = 2147483647  -- 2^31 - 1 (Mersenne prime)

function SeededRandom.new(seed)
    local self = {
        seed = seed or os.time(),
        state = nil
    }
    self.state = self.seed % MODULUS
    if self.state == 0 then
        self.state = 1  -- Avoid zero state
    end
    return setmetatable(self, {__index = SeededRandom})
end

-- Get next random number in range [0, 1)
function SeededRandom:random()
    self.state = (self.state * MULTIPLIER) % MODULUS
    return self.state / MODULUS
end

-- Get random integer in range [min, max]
function SeededRandom:random_int(min, max)
    if not max then
        -- random_int(n) returns [1, n]
        max = min
        min = 1
    end
    return min + math.floor(self:random() * (max - min + 1))
end

-- Get random float in range [min, max]
function SeededRandom:random_float(min, max)
    return min + self:random() * (max - min)
end

-- Get random boolean with given probability of true
function SeededRandom:random_bool(probability)
    probability = probability or 0.5
    return self:random() < probability
end

-- Choose random element from array
function SeededRandom:choose(array)
    if #array == 0 then
        return nil
    end
    return array[self:random_int(1, #array)]
end

-- Shuffle array in place (Fisher-Yates)
function SeededRandom:shuffle(array)
    for i = #array, 2, -1 do
        local j = self:random_int(1, i)
        array[i], array[j] = array[j], array[i]
    end
    return array
end

-- Weighted random selection
-- weights is a table of {item = weight, ...}
function SeededRandom:weighted_choice(weights)
    local total = 0
    for _, weight in pairs(weights) do
        total = total + weight
    end

    local roll = self:random() * total
    local cumulative = 0

    for item, weight in pairs(weights) do
        cumulative = cumulative + weight
        if roll <= cumulative then
            return item
        end
    end

    -- Fallback (shouldn't happen)
    for item, _ in pairs(weights) do
        return item
    end
end

-- Reset to initial seed
function SeededRandom:reset()
    self.state = self.seed % MODULUS
    if self.state == 0 then
        self.state = 1
    end
end

-- Get current state for save/load
function SeededRandom:get_state()
    return self.state
end

-- Set state for save/load
function SeededRandom:set_state(state)
    self.state = state
end

-- Get the original seed
function SeededRandom:get_seed()
    return self.seed
end

return SeededRandom
