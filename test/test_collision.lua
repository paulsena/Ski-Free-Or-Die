-- test/test_collision.lua
local Runner = require("test.runner")
local Collision = require("src.systems.collision")

Runner.describe("Collision", function()
    
    Runner.describe("circle_rect", function()
        Runner.it("should detect collision inside", function()
            -- Circle at 10,10 radius 5. Rect at 5,5 width 10 height 10.
            Runner.assert_true(Collision.circle_rect(10, 10, 5, 5, 5, 10, 10), "Should collide")
        end)
        
        Runner.it("should detect collision on edge", function()
            -- Circle at 15,10 radius 5. Rect at 0,0 width 10 height 20.
            -- Closest point on rect is 10,10. Dist is 5. Should collide (overlap < radius? usually <=)
            -- Utils.distance < radius is strictly less in the code.
            -- Let's check Utils.distance code. "dist < radius"
            -- So exact touch might be false.
            -- Let's test slight overlap.
            Runner.assert_true(Collision.circle_rect(14.9, 10, 5, 0, 0, 10, 20), "Should collide with overlap")
        end)

        Runner.it("should not detect when far away", function()
            Runner.assert_true(not Collision.circle_rect(100, 100, 5, 0, 0, 10, 10), "Should not collide")
        end)
    end)

    Runner.describe("rect_rect", function()
        Runner.it("should detect overlapping rects", function()
            Runner.assert_true(Collision.rect_rect(0, 0, 10, 10, 5, 5, 10, 10), "Should overlap")
        end)

        Runner.it("should not detect separated rects", function()
            Runner.assert_true(not Collision.rect_rect(0, 0, 10, 10, 20, 20, 10, 10), "Should not overlap")
        end)
    end)

end)
