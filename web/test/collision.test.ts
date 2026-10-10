// test/test_collision.lua
import { describe, it, expect } from "vitest";
import Collision from "../src/systems/collision";
describe("Collision", () => {
    describe("circle_rect", () => {
        it("should detect collision inside", () => {
            // Circle at 10,10 radius 5. Rect at 5,5 width 10 height 10.
            expect(Collision.circle_rect(10, 10, 5, 5, 5, 10, 10), "Should collide").toBe(true);
        });
        it("should detect collision on edge", () => {
            // Circle at 15,10 radius 5. Rect at 0,0 width 10 height 20.
            // Closest point on rect is 10,10. Dist is 5. Should collide (overlap < radius? usually <=)
            // Utils.distance < radius is strictly less in the code.
            // Let's check Utils.distance code. "dist < radius"
            // So exact touch might be false.
            // Let's test slight overlap.
            expect(Collision.circle_rect(14.9, 10, 5, 0, 0, 10, 20), "Should collide with overlap").toBe(true);
        });
        it("should not detect when far away", () => {
            expect(!Collision.circle_rect(100, 100, 5, 0, 0, 10, 10), "Should not collide").toBe(true);
        });
    });
    describe("rect_rect", () => {
        it("should detect overlapping rects", () => {
            expect(Collision.rect_rect(0, 0, 10, 10, 5, 5, 10, 10), "Should overlap").toBe(true);
        });
        it("should not detect separated rects", () => {
            expect(!Collision.rect_rect(0, 0, 10, 10, 20, 20, 10, 10), "Should not overlap").toBe(true);
        });
    });
});
