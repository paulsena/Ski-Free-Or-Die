import { describe, it, expect } from "vitest";
import Utils from "../src/lib/utils";

// test/utils.test.ts

describe("Utils", () => {

    describe("clamp", () => {
        it("should return value when within range", () => {
            expect(Utils.clamp(5, 0, 10)).toBe(5);
        });

        it("should return min when value is below", () => {
            expect(Utils.clamp(-5, 0, 10)).toBe(0);
        });

        it("should return max when value is above", () => {
            expect(Utils.clamp(15, 0, 10)).toBe(10);
        });

        it("should handle value equal to min", () => {
            expect(Utils.clamp(0, 0, 10)).toBe(0);
        });

        it("should handle value equal to max", () => {
            expect(Utils.clamp(10, 0, 10)).toBe(10);
        });

        it("should work with negative ranges", () => {
            expect(Utils.clamp(-5, -10, -1)).toBe(-5);
        });
    });

    describe("lerp", () => {
        it("should return a when t is 0", () => {
            expect(Utils.lerp(10, 20, 0)).toBe(10);
        });

        it("should return b when t is 1", () => {
            expect(Utils.lerp(10, 20, 1)).toBe(20);
        });

        it("should return midpoint when t is 0.5", () => {
            expect(Utils.lerp(10, 20, 0.5)).toBe(15);
        });

        it("should work with negative values", () => {
            expect(Utils.lerp(-10, 10, 0.5)).toBe(0);
        });

        it("should extrapolate when t > 1", () => {
            expect(Utils.lerp(10, 20, 2)).toBe(30);
        });

        it("should extrapolate when t < 0", () => {
            expect(Utils.lerp(10, 20, -1)).toBe(0);
        });
    });

    describe("distance", () => {
        it("should return 0 for same point", () => {
            expect(Utils.distance(5, 5, 5, 5)).toBe(0);
        });

        it("should calculate horizontal distance", () => {
            expect(Utils.distance(0, 0, 10, 0)).toBe(10);
        });

        it("should calculate vertical distance", () => {
            expect(Utils.distance(0, 0, 0, 10)).toBe(10);
        });

        it("should calculate diagonal distance (3-4-5 triangle)", () => {
            expect(Utils.distance(0, 0, 3, 4)).toBe(5);
        });

        it("should work with negative coordinates", () => {
            expect(Utils.distance(-3, -4, 0, 0)).toBe(5);
        });
    });

    describe("normalize_angle", () => {
        it("should return 0 for 0", () => {
            expect(Utils.normalize_angle(0)).toBe(0);
        });

        it("should keep angles within [-pi, pi] unchanged", () => {
            expect(Math.abs(1.0 - Utils.normalize_angle(1.0))).toBeLessThanOrEqual(0.0001);
            expect(Math.abs(-1.0 - Utils.normalize_angle(-1.0))).toBeLessThanOrEqual(0.0001);
        });

        it("should normalize angle > pi", () => {
            // 2*pi should wrap to ~0
            expect(Math.abs(0 - Utils.normalize_angle(2 * Math.PI))).toBeLessThanOrEqual(0.0001);
        });

        it("should normalize angle < -pi", () => {
            // -2*pi should wrap to ~0
            expect(Math.abs(0 - Utils.normalize_angle(-2 * Math.PI))).toBeLessThanOrEqual(0.0001);
        });

        it("should handle large positive angles", () => {
            // 3*pi should wrap to -pi (or pi, which is equivalent)
            let result = Utils.normalize_angle(3 * Math.PI);
            expect(Math.abs(Math.PI - Math.abs(result))).toBeLessThanOrEqual(0.0001);
        });

        it("should handle large negative angles", () => {
            // -3*pi should wrap to pi (or -pi)
            let result = Utils.normalize_angle(-3 * Math.PI);
            expect(Math.abs(Math.PI - Math.abs(result))).toBeLessThanOrEqual(0.0001);
        });
    });

    describe("sign", () => {
        it("should return 1 for positive numbers", () => {
            expect(Utils.sign(5)).toBe(1);
            expect(Utils.sign(0.001)).toBe(1);
        });

        it("should return -1 for negative numbers", () => {
            expect(Utils.sign(-5)).toBe(-1);
            expect(Utils.sign(-0.001)).toBe(-1);
        });

        it("should return 0 for zero", () => {
            expect(Utils.sign(0)).toBe(0);
        });
    });

    describe("round", () => {
        it("should round down when fractional part < 0.5", () => {
            expect(Utils.round(5.4)).toBe(5);
        });

        it("should round up when fractional part >= 0.5", () => {
            expect(Utils.round(5.5)).toBe(6);
            expect(Utils.round(5.9)).toBe(6);
        });

        it("should handle negative numbers (round down)", () => {
            // floor(-5.4 + 0.5) = floor(-4.9) = -5
            expect(Utils.round(-5.4)).toBe(-5);
        });

        it("should handle negative numbers (round up)", () => {
            // floor(-5.6 + 0.5) = floor(-5.1) = -6
            expect(Utils.round(-5.6)).toBe(-6);
        });

        it("should return integers unchanged", () => {
            expect(Utils.round(5)).toBe(5);
            expect(Utils.round(-5)).toBe(-5);
        });

        it("should handle zero", () => {
            expect(Utils.round(0)).toBe(0);
        });
    });

    describe("format_time", () => {
        it("should format zero seconds", () => {
            expect(Utils.format_time(0)).toBe("00:00.00");
        });

        it("should format seconds only", () => {
            expect(Utils.format_time(5)).toBe("00:05.00");
        });

        it("should format with decimal seconds", () => {
            expect(Utils.format_time(5.25)).toBe("00:05.25");
        });

        it("should format with minutes", () => {
            expect(Utils.format_time(90)).toBe("01:30.00");
        });

        it("should format complex time", () => {
            expect(Utils.format_time(135.5)).toBe("02:15.50");
        });

        it("should pad minutes with zeros", () => {
            expect(Utils.format_time(45)).toBe("00:45.00");
        });

        it("should pad seconds with zeros", () => {
            expect(Utils.format_time(65)).toBe("01:05.00");
        });
    });

    describe("deg_to_rad", () => {
        it("should convert 0 degrees to 0 radians", () => {
            expect(Utils.deg_to_rad(0)).toBe(0);
        });

        it("should convert 180 degrees to pi radians", () => {
            expect(Math.abs(Math.PI - Utils.deg_to_rad(180))).toBeLessThanOrEqual(0.0001);
        });

        it("should convert 90 degrees to pi/2 radians", () => {
            expect(Math.abs(Math.PI / 2 - Utils.deg_to_rad(90))).toBeLessThanOrEqual(0.0001);
        });

        it("should convert 360 degrees to 2*pi radians", () => {
            expect(Math.abs(2 * Math.PI - Utils.deg_to_rad(360))).toBeLessThanOrEqual(0.0001);
        });
    });

    describe("rad_to_deg", () => {
        it("should convert 0 radians to 0 degrees", () => {
            expect(Utils.rad_to_deg(0)).toBe(0);
        });

        it("should convert pi radians to 180 degrees", () => {
            expect(Math.abs(180 - Utils.rad_to_deg(Math.PI))).toBeLessThanOrEqual(0.0001);
        });

        it("should convert pi/2 radians to 90 degrees", () => {
            expect(Math.abs(90 - Utils.rad_to_deg(Math.PI / 2))).toBeLessThanOrEqual(0.0001);
        });
    });

    describe("deep_copy", () => {
        it("should copy primitive values", () => {
            expect(Utils.deep_copy(5)).toBe(5);
            expect(Utils.deep_copy("test")).toBe("test");
            expect(Utils.deep_copy(true)).toBe(true);
        });

        it("should create independent copy of table", () => {
            let original = {a: 1, b: 2};
            let copy = Utils.deep_copy(original);
            copy.a = 99;
            expect(original.a).toBe(1); // Original unchanged
            expect(copy.a).toBe(99); // Copy changed
        });

        it("should deep copy nested tables", () => {
            let original = {outer: {inner: 5}};
            let copy = Utils.deep_copy(original);
            copy.outer.inner = 99;
            expect(original.outer.inner).toBe(5); // Original unchanged
        });
    });

});
