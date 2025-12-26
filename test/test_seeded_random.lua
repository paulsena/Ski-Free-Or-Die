-- test/test_seeded_random.lua
local Runner = require("test.runner")
local SeededRandom = require("src.lib.seeded_random")

Runner.describe("SeededRandom", function()
    
    Runner.it("should be deterministic with the same seed", function()
        local rng1 = SeededRandom.new(12345)
        local rng2 = SeededRandom.new(12345)
        
        for i = 1, 10 do
            local v1 = rng1:random()
            local v2 = rng2:random()
            Runner.assert_equal(v1, v2, "Values at step " .. i .. " should be identical")
        end
    end)

    Runner.it("should produce different values with different seeds", function()
        local rng1 = SeededRandom.new(12345)
        local rng2 = SeededRandom.new(67890)
        
        -- Check first few values
        local all_same = true
        for i = 1, 5 do
            if rng1:random() ~= rng2:random() then
                all_same = false
                break
            end
        end
        Runner.assert_true(not all_same, "Different seeds should produce different sequences")
    end)

    Runner.it("should respect min/max for integers", function()
        local rng = SeededRandom.new(123)
        local min, max = 5, 10
        for i = 1, 100 do
            local val = rng:random_int(min, max)
            Runner.assert_true(val >= min and val <= max, "Value " .. val .. " out of range")
            Runner.assert_equal(val, math.floor(val), "Value should be integer")
        end
    end)

    Runner.it("should restore state correctly", function()
        local rng = SeededRandom.new(999)
        rng:random() -- advance a bit
        rng:random()
        
        local state = rng:get_state()
        local val1 = rng:random()
        
        rng:set_state(state)
        local val2 = rng:random()
        
        Runner.assert_equal(val1, val2, "Should reproduce value after restoring state")
    end)

    Runner.it("should reset to initial seed", function()
        local rng = SeededRandom.new(555)
        local first_val = rng:random()
        
        rng:random() -- advance
        rng:reset()
        
        local reset_val = rng:random()
        Runner.assert_equal(first_val, reset_val, "Should return to first value after reset")
    end)
    
    Runner.it("should weighted_choice correctly", function()
        -- With a deterministic seed, we can predict choices, but let's just check validity
        local rng = SeededRandom.new(1)
        local weights = { a = 10, b = 0, c = 0 } -- Only 'a' should be chosen
        
        for i = 1, 10 do
            local choice = rng:weighted_choice(weights)
            Runner.assert_equal("a", choice, "Should always choose non-zero weight option if others are zero")
        end
    end)

end)
