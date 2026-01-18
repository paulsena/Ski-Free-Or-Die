-- test/test_utils.lua
local Runner = require("test.runner")
local Utils = require("src.lib.utils")

Runner.describe("Utils", function()

    Runner.describe("clamp", function()
        Runner.it("should return value when within range", function()
            Runner.assert_equal(5, Utils.clamp(5, 0, 10))
        end)

        Runner.it("should return min when value is below", function()
            Runner.assert_equal(0, Utils.clamp(-5, 0, 10))
        end)

        Runner.it("should return max when value is above", function()
            Runner.assert_equal(10, Utils.clamp(15, 0, 10))
        end)

        Runner.it("should handle value equal to min", function()
            Runner.assert_equal(0, Utils.clamp(0, 0, 10))
        end)

        Runner.it("should handle value equal to max", function()
            Runner.assert_equal(10, Utils.clamp(10, 0, 10))
        end)

        Runner.it("should work with negative ranges", function()
            Runner.assert_equal(-5, Utils.clamp(-5, -10, -1))
        end)
    end)

    Runner.describe("lerp", function()
        Runner.it("should return a when t is 0", function()
            Runner.assert_equal(10, Utils.lerp(10, 20, 0))
        end)

        Runner.it("should return b when t is 1", function()
            Runner.assert_equal(20, Utils.lerp(10, 20, 1))
        end)

        Runner.it("should return midpoint when t is 0.5", function()
            Runner.assert_equal(15, Utils.lerp(10, 20, 0.5))
        end)

        Runner.it("should work with negative values", function()
            Runner.assert_equal(0, Utils.lerp(-10, 10, 0.5))
        end)

        Runner.it("should extrapolate when t > 1", function()
            Runner.assert_equal(30, Utils.lerp(10, 20, 2))
        end)

        Runner.it("should extrapolate when t < 0", function()
            Runner.assert_equal(0, Utils.lerp(10, 20, -1))
        end)
    end)

    Runner.describe("distance", function()
        Runner.it("should return 0 for same point", function()
            Runner.assert_equal(0, Utils.distance(5, 5, 5, 5))
        end)

        Runner.it("should calculate horizontal distance", function()
            Runner.assert_equal(10, Utils.distance(0, 0, 10, 0))
        end)

        Runner.it("should calculate vertical distance", function()
            Runner.assert_equal(10, Utils.distance(0, 0, 0, 10))
        end)

        Runner.it("should calculate diagonal distance (3-4-5 triangle)", function()
            Runner.assert_equal(5, Utils.distance(0, 0, 3, 4))
        end)

        Runner.it("should work with negative coordinates", function()
            Runner.assert_equal(5, Utils.distance(-3, -4, 0, 0))
        end)
    end)

    Runner.describe("normalize_angle", function()
        Runner.it("should return 0 for 0", function()
            Runner.assert_equal(0, Utils.normalize_angle(0))
        end)

        Runner.it("should keep angles within [-pi, pi] unchanged", function()
            Runner.assert_close(1.0, Utils.normalize_angle(1.0), 0.0001)
            Runner.assert_close(-1.0, Utils.normalize_angle(-1.0), 0.0001)
        end)

        Runner.it("should normalize angle > pi", function()
            -- 2*pi should wrap to ~0
            Runner.assert_close(0, Utils.normalize_angle(2 * math.pi), 0.0001)
        end)

        Runner.it("should normalize angle < -pi", function()
            -- -2*pi should wrap to ~0
            Runner.assert_close(0, Utils.normalize_angle(-2 * math.pi), 0.0001)
        end)

        Runner.it("should handle large positive angles", function()
            -- 3*pi should wrap to -pi (or pi, which is equivalent)
            local result = Utils.normalize_angle(3 * math.pi)
            Runner.assert_close(math.pi, math.abs(result), 0.0001)
        end)

        Runner.it("should handle large negative angles", function()
            -- -3*pi should wrap to pi (or -pi)
            local result = Utils.normalize_angle(-3 * math.pi)
            Runner.assert_close(math.pi, math.abs(result), 0.0001)
        end)
    end)

    Runner.describe("sign", function()
        Runner.it("should return 1 for positive numbers", function()
            Runner.assert_equal(1, Utils.sign(5))
            Runner.assert_equal(1, Utils.sign(0.001))
        end)

        Runner.it("should return -1 for negative numbers", function()
            Runner.assert_equal(-1, Utils.sign(-5))
            Runner.assert_equal(-1, Utils.sign(-0.001))
        end)

        Runner.it("should return 0 for zero", function()
            Runner.assert_equal(0, Utils.sign(0))
        end)
    end)

    Runner.describe("round", function()
        Runner.it("should round down when fractional part < 0.5", function()
            Runner.assert_equal(5, Utils.round(5.4))
        end)

        Runner.it("should round up when fractional part >= 0.5", function()
            Runner.assert_equal(6, Utils.round(5.5))
            Runner.assert_equal(6, Utils.round(5.9))
        end)

        Runner.it("should handle negative numbers (round down)", function()
            -- floor(-5.4 + 0.5) = floor(-4.9) = -5
            Runner.assert_equal(-5, Utils.round(-5.4))
        end)

        Runner.it("should handle negative numbers (round up)", function()
            -- floor(-5.6 + 0.5) = floor(-5.1) = -6
            Runner.assert_equal(-6, Utils.round(-5.6))
        end)

        Runner.it("should return integers unchanged", function()
            Runner.assert_equal(5, Utils.round(5))
            Runner.assert_equal(-5, Utils.round(-5))
        end)

        Runner.it("should handle zero", function()
            Runner.assert_equal(0, Utils.round(0))
        end)
    end)

    Runner.describe("format_time", function()
        Runner.it("should format zero seconds", function()
            Runner.assert_equal("00:00.00", Utils.format_time(0))
        end)

        Runner.it("should format seconds only", function()
            Runner.assert_equal("00:05.00", Utils.format_time(5))
        end)

        Runner.it("should format with decimal seconds", function()
            Runner.assert_equal("00:05.25", Utils.format_time(5.25))
        end)

        Runner.it("should format with minutes", function()
            Runner.assert_equal("01:30.00", Utils.format_time(90))
        end)

        Runner.it("should format complex time", function()
            Runner.assert_equal("02:15.50", Utils.format_time(135.5))
        end)

        Runner.it("should pad minutes with zeros", function()
            Runner.assert_equal("00:45.00", Utils.format_time(45))
        end)

        Runner.it("should pad seconds with zeros", function()
            Runner.assert_equal("01:05.00", Utils.format_time(65))
        end)
    end)

    Runner.describe("deg_to_rad", function()
        Runner.it("should convert 0 degrees to 0 radians", function()
            Runner.assert_equal(0, Utils.deg_to_rad(0))
        end)

        Runner.it("should convert 180 degrees to pi radians", function()
            Runner.assert_close(math.pi, Utils.deg_to_rad(180), 0.0001)
        end)

        Runner.it("should convert 90 degrees to pi/2 radians", function()
            Runner.assert_close(math.pi / 2, Utils.deg_to_rad(90), 0.0001)
        end)

        Runner.it("should convert 360 degrees to 2*pi radians", function()
            Runner.assert_close(2 * math.pi, Utils.deg_to_rad(360), 0.0001)
        end)
    end)

    Runner.describe("rad_to_deg", function()
        Runner.it("should convert 0 radians to 0 degrees", function()
            Runner.assert_equal(0, Utils.rad_to_deg(0))
        end)

        Runner.it("should convert pi radians to 180 degrees", function()
            Runner.assert_close(180, Utils.rad_to_deg(math.pi), 0.0001)
        end)

        Runner.it("should convert pi/2 radians to 90 degrees", function()
            Runner.assert_close(90, Utils.rad_to_deg(math.pi / 2), 0.0001)
        end)
    end)

    Runner.describe("deep_copy", function()
        Runner.it("should copy primitive values", function()
            Runner.assert_equal(5, Utils.deep_copy(5))
            Runner.assert_equal("test", Utils.deep_copy("test"))
            Runner.assert_equal(true, Utils.deep_copy(true))
        end)

        Runner.it("should create independent copy of table", function()
            local original = {a = 1, b = 2}
            local copy = Utils.deep_copy(original)
            copy.a = 99
            Runner.assert_equal(1, original.a)  -- Original unchanged
            Runner.assert_equal(99, copy.a)     -- Copy changed
        end)

        Runner.it("should deep copy nested tables", function()
            local original = {outer = {inner = 5}}
            local copy = Utils.deep_copy(original)
            copy.outer.inner = 99
            Runner.assert_equal(5, original.outer.inner)  -- Original unchanged
        end)
    end)

end)
