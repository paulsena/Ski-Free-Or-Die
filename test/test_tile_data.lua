-- test/test_tile_data.lua
local Runner = require("test.runner")
local TileData = require("src.world.tile_data")

Runner.describe("TileData", function()

    Runner.describe("new", function()
        Runner.it("should create tile from warmup template", function()
            local tile = TileData.new("warmup", 0)
            Runner.assert_equal("warmup", tile.template_name)
            Runner.assert_equal(TileData.TileType.WARMUP, tile.type)
            Runner.assert_equal(TileData.SlopeIntensity.GENTLE, tile.slope)
            Runner.assert_equal(1, tile.difficulty)
        end)

        Runner.it("should create tile from slalom_easy template", function()
            local tile = TileData.new("slalom_easy", 0)
            Runner.assert_equal(TileData.TileType.SLALOM, tile.type)
            Runner.assert_equal(TileData.SlalomVariant.EASY, tile.variant)
            Runner.assert_equal(2, tile.difficulty)
        end)

        Runner.it("should create tile from slalom_hard template", function()
            local tile = TileData.new("slalom_hard", 0)
            Runner.assert_equal(TileData.TileType.SLALOM, tile.type)
            Runner.assert_equal(TileData.SlalomVariant.HARD, tile.variant)
            Runner.assert_equal(4, tile.difficulty)
        end)

        Runner.it("should set y_start from position parameter", function()
            local tile = TileData.new("warmup", 500)
            Runner.assert_equal(500, tile.y_start)
        end)

        Runner.it("should calculate y_end based on TILE_HEIGHT", function()
            local tile = TileData.new("warmup", 500)
            Runner.assert_equal(500 + TileData.TILE_HEIGHT, tile.y_end)
        end)

        Runner.it("should initialize empty obstacles array", function()
            local tile = TileData.new("warmup", 0)
            Runner.assert_equal(0, #tile.obstacles)
        end)

        Runner.it("should initialize empty gates array", function()
            local tile = TileData.new("warmup", 0)
            Runner.assert_equal(0, #tile.gates)
        end)

        Runner.it("should error on unknown template", function()
            local success = pcall(function()
                TileData.new("nonexistent_template", 0)
            end)
            Runner.assert_true(not success, "Should error on unknown template")
        end)
    end)

    Runner.describe("get_templates_for_difficulty", function()
        Runner.it("should return warmup and speed for difficulty 1", function()
            local templates = TileData.get_templates_for_difficulty(1, 1)
            -- Difficulty 1 templates: warmup, speed
            Runner.assert_true(#templates >= 2, "Should have at least 2 templates for difficulty 1")

            -- Check that warmup is included
            local has_warmup = false
            local has_speed = false
            for _, name in ipairs(templates) do
                if name == "warmup" then has_warmup = true end
                if name == "speed" then has_speed = true end
            end
            Runner.assert_true(has_warmup, "Should include warmup template")
            Runner.assert_true(has_speed, "Should include speed template")
        end)

        Runner.it("should return slalom_easy for difficulty 2", function()
            local templates = TileData.get_templates_for_difficulty(2, 2)

            local has_slalom_easy = false
            for _, name in ipairs(templates) do
                if name == "slalom_easy" then has_slalom_easy = true end
            end
            Runner.assert_true(has_slalom_easy, "Should include slalom_easy template")
        end)

        Runner.it("should return multiple templates for difficulty range 3-4", function()
            local templates = TileData.get_templates_for_difficulty(3, 4)
            -- Difficulty 3: slalom_medium, obstacle_forest, ramp
            -- Difficulty 4: slalom_hard, obstacle_rocks
            Runner.assert_true(#templates >= 4, "Should have multiple templates for difficulty 3-4")
        end)

        Runner.it("should return hardest templates for difficulty 5", function()
            local templates = TileData.get_templates_for_difficulty(5, 5)

            local has_obstacle_mixed = false
            for _, name in ipairs(templates) do
                if name == "obstacle_mixed" then has_obstacle_mixed = true end
            end
            Runner.assert_true(has_obstacle_mixed, "Should include obstacle_mixed (difficulty 5)")
        end)

        Runner.it("should return empty array for out-of-range difficulty", function()
            local templates = TileData.get_templates_for_difficulty(99, 100)
            Runner.assert_equal(0, #templates)
        end)

        Runner.it("should return all templates for wide difficulty range", function()
            local templates = TileData.get_templates_for_difficulty(1, 5)
            -- Count all templates in TILE_TEMPLATES
            local template_count = 0
            for _ in pairs(TileData.TILE_TEMPLATES) do
                template_count = template_count + 1
            end
            Runner.assert_equal(template_count, #templates)
        end)
    end)

    Runner.describe("get_templates_by_type", function()
        Runner.it("should return slalom templates", function()
            local templates = TileData.get_templates_by_type(TileData.TileType.SLALOM)
            -- Should have easy, medium, hard
            Runner.assert_equal(3, #templates)
        end)

        Runner.it("should return obstacle field templates", function()
            local templates = TileData.get_templates_by_type(TileData.TileType.OBSTACLE_FIELD)
            -- Should have forest, rocks, mixed
            Runner.assert_equal(3, #templates)
        end)

        Runner.it("should return warmup templates", function()
            local templates = TileData.get_templates_by_type(TileData.TileType.WARMUP)
            Runner.assert_equal(1, #templates)
        end)

        Runner.it("should return empty array for unknown type", function()
            local templates = TileData.get_templates_by_type("nonexistent_type")
            Runner.assert_equal(0, #templates)
        end)
    end)

    Runner.describe("get_slope_multiplier", function()
        Runner.it("should return gentle multiplier for warmup tile", function()
            local tile = TileData.new("warmup", 0)
            Runner.assert_close(0.85, tile:get_slope_multiplier(), 0.001)
        end)

        Runner.it("should return moderate multiplier for slalom_medium tile", function()
            local tile = TileData.new("slalom_medium", 0)
            Runner.assert_close(1.0, tile:get_slope_multiplier(), 0.001)
        end)

        Runner.it("should return steep multiplier for speed tile", function()
            local tile = TileData.new("speed", 0)
            Runner.assert_close(1.2, tile:get_slope_multiplier(), 0.001)
        end)
    end)

    Runner.describe("contains_y", function()
        Runner.it("should return true for y within tile", function()
            local tile = TileData.new("warmup", 100)
            Runner.assert_true(tile:contains_y(200), "Should contain y=200 in tile starting at 100")
        end)

        Runner.it("should return true for y at tile start", function()
            local tile = TileData.new("warmup", 100)
            Runner.assert_true(tile:contains_y(100), "Should contain y at tile start")
        end)

        Runner.it("should return false for y at tile end", function()
            local tile = TileData.new("warmup", 100)
            -- y_end is exclusive (uses < not <=)
            Runner.assert_true(not tile:contains_y(100 + TileData.TILE_HEIGHT), "Should not contain y at tile end")
        end)

        Runner.it("should return false for y before tile", function()
            local tile = TileData.new("warmup", 100)
            Runner.assert_true(not tile:contains_y(50), "Should not contain y before tile")
        end)

        Runner.it("should return false for y after tile", function()
            local tile = TileData.new("warmup", 100)
            Runner.assert_true(not tile:contains_y(600), "Should not contain y after tile")
        end)
    end)

    Runner.describe("is_transition_zone", function()
        Runner.it("should return true for y near tile start", function()
            local tile = TileData.new("warmup", 0)
            -- Transition zone is first TRANSITION_ZONE pixels
            Runner.assert_true(tile:is_transition_zone(10), "Should be in transition zone near start")
        end)

        Runner.it("should return true for y near tile end", function()
            local tile = TileData.new("warmup", 0)
            -- Transition zone is last TRANSITION_ZONE pixels
            local near_end = TileData.TILE_HEIGHT - 10
            Runner.assert_true(tile:is_transition_zone(near_end), "Should be in transition zone near end")
        end)

        Runner.it("should return false for y in middle of tile", function()
            local tile = TileData.new("warmup", 0)
            local middle = TileData.TILE_HEIGHT / 2
            Runner.assert_true(not tile:is_transition_zone(middle), "Should not be in transition zone in middle")
        end)
    end)

    Runner.describe("constants", function()
        Runner.it("should have positive TILE_HEIGHT", function()
            Runner.assert_true(TileData.TILE_HEIGHT > 0, "TILE_HEIGHT should be positive")
        end)

        Runner.it("should have positive TILE_WIDTH", function()
            Runner.assert_true(TileData.TILE_WIDTH > 0, "TILE_WIDTH should be positive")
        end)

        Runner.it("should have TRANSITION_ZONE less than half TILE_HEIGHT", function()
            Runner.assert_true(TileData.TRANSITION_ZONE < TileData.TILE_HEIGHT / 2,
                "TRANSITION_ZONE should be less than half TILE_HEIGHT")
        end)

        Runner.it("should have valid gate spacing values", function()
            Runner.assert_true(TileData.GATE_SPACING.wide > 0, "wide spacing should be positive")
            Runner.assert_true(TileData.GATE_SPACING.normal > 0, "normal spacing should be positive")
            Runner.assert_true(TileData.GATE_SPACING.tight > 0, "tight spacing should be positive")
            Runner.assert_true(TileData.GATE_SPACING.wide > TileData.GATE_SPACING.tight,
                "wide spacing should be greater than tight")
        end)
    end)

end)
