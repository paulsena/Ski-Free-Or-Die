-- test/test_leaderboard.lua
local Runner = require("test.runner")
local Leaderboard = require("src.core.leaderboard")

Runner.describe("Leaderboard", function()

    Runner.describe("calculate_score", function()
        Runner.describe("time_trial mode", function()
            Runner.it("should calculate score from time with no gates missed", function()
                local stats = {time = 60, gates_missed = 0}
                local score = Leaderboard.calculate_score("time_trial", stats)
                -- Expected: 1000000 - (60 * 1000) = 940000
                Runner.assert_equal(940000, score)
            end)

            Runner.it("should add penalty for missed gates", function()
                local stats = {time = 60, gates_missed = 2}
                local score = Leaderboard.calculate_score("time_trial", stats)
                -- Expected: 1000000 - ((60 + 2*3) * 1000) = 1000000 - 66000 = 934000
                Runner.assert_equal(934000, score)
            end)

            Runner.it("should give higher score for faster time", function()
                local fast_stats = {time = 45, gates_missed = 0}
                local slow_stats = {time = 60, gates_missed = 0}
                local fast_score = Leaderboard.calculate_score("time_trial", fast_stats)
                local slow_score = Leaderboard.calculate_score("time_trial", slow_stats)
                Runner.assert_true(fast_score > slow_score, "Faster time should have higher score")
            end)

            Runner.it("should penalize gate misses correctly (3 seconds each)", function()
                local clean_stats = {time = 50, gates_missed = 0}
                local missed_stats = {time = 50, gates_missed = 1}
                local clean_score = Leaderboard.calculate_score("time_trial", clean_stats)
                local missed_score = Leaderboard.calculate_score("time_trial", missed_stats)
                -- Difference should be 3000 (3 seconds * 1000)
                Runner.assert_equal(3000, clean_score - missed_score)
            end)

            Runner.it("should handle zero time", function()
                local stats = {time = 0, gates_missed = 0}
                local score = Leaderboard.calculate_score("time_trial", stats)
                Runner.assert_equal(1000000, score)
            end)
        end)

        Runner.describe("endless mode", function()
            Runner.it("should calculate score from distance", function()
                local stats = {distance = 5000}
                local score = Leaderboard.calculate_score("endless", stats)
                -- Expected: floor(5000 / 10) = 500 meters
                Runner.assert_equal(500, score)
            end)

            Runner.it("should floor the result", function()
                local stats = {distance = 5009}
                local score = Leaderboard.calculate_score("endless", stats)
                -- Expected: floor(5009 / 10) = 500 meters
                Runner.assert_equal(500, score)
            end)

            Runner.it("should handle zero distance", function()
                local stats = {distance = 0}
                local score = Leaderboard.calculate_score("endless", stats)
                Runner.assert_equal(0, score)
            end)

            Runner.it("should give higher score for longer distance", function()
                local short_stats = {distance = 1000}
                local long_stats = {distance = 5000}
                local short_score = Leaderboard.calculate_score("endless", short_stats)
                local long_score = Leaderboard.calculate_score("endless", long_stats)
                Runner.assert_true(long_score > short_score, "Longer distance should have higher score")
            end)
        end)

        Runner.describe("unknown mode", function()
            Runner.it("should return 0 for unknown mode", function()
                local stats = {time = 60, distance = 5000}
                local score = Leaderboard.calculate_score("unknown_mode", stats)
                Runner.assert_equal(0, score)
            end)
        end)
    end)

    Runner.describe("format_score", function()
        Runner.describe("time_trial mode", function()
            Runner.it("should format score back to time", function()
                -- Score 940000 = time of 60 seconds
                local formatted = Leaderboard.format_score("time_trial", 940000)
                Runner.assert_equal("1:00.00", formatted)
            end)

            Runner.it("should format perfect score (0 seconds)", function()
                local formatted = Leaderboard.format_score("time_trial", 1000000)
                Runner.assert_equal("0:00.00", formatted)
            end)

            Runner.it("should format with decimal seconds", function()
                -- Score 954800 = 1000000 - 45200 = time of 45.2 seconds
                local formatted = Leaderboard.format_score("time_trial", 954800)
                Runner.assert_equal("0:45.20", formatted)
            end)

            Runner.it("should format times over a minute", function()
                -- Score 910000 = time of 90 seconds = 1:30
                local formatted = Leaderboard.format_score("time_trial", 910000)
                Runner.assert_equal("1:30.00", formatted)
            end)
        end)

        Runner.describe("endless mode", function()
            Runner.it("should format distance in meters", function()
                local formatted = Leaderboard.format_score("endless", 500)
                Runner.assert_equal("500m", formatted)
            end)

            Runner.it("should format zero distance", function()
                local formatted = Leaderboard.format_score("endless", 0)
                Runner.assert_equal("0m", formatted)
            end)

            Runner.it("should format large distances", function()
                local formatted = Leaderboard.format_score("endless", 12345)
                Runner.assert_equal("12345m", formatted)
            end)
        end)

        Runner.describe("unknown mode", function()
            Runner.it("should return score as string for unknown mode", function()
                local formatted = Leaderboard.format_score("unknown", 12345)
                Runner.assert_equal("12345", formatted)
            end)
        end)
    end)

    Runner.describe("qualifies", function()
        -- Note: These tests work with the internal scores state
        -- We test the logic rather than full integration

        Runner.it("should return true when leaderboard is empty", function()
            -- Clear scores first
            Leaderboard.clear_all()
            local qualifies, rank = Leaderboard.qualifies("time_trial", 100)
            Runner.assert_true(qualifies, "Should qualify when empty")
            Runner.assert_equal(1, rank)
        end)

        Runner.it("should return true when leaderboard is not full", function()
            Leaderboard.clear_all()
            -- Add a few scores
            Leaderboard.add("time_trial", "AAA", 900000)
            Leaderboard.add("time_trial", "BBB", 800000)

            local qualifies, rank = Leaderboard.qualifies("time_trial", 850000)
            Runner.assert_true(qualifies, "Should qualify when not full")
        end)

        Runner.it("should track separate leaderboards per mode", function()
            Leaderboard.clear_all()
            Leaderboard.add("time_trial", "AAA", 900000)

            -- Endless should still be empty
            local qualifies, rank = Leaderboard.qualifies("endless", 100)
            Runner.assert_true(qualifies, "Should qualify for empty endless leaderboard")
            Runner.assert_equal(1, rank)
        end)
    end)

end)
