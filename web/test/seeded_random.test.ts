import { describe, it, expect } from "vitest";
import SeededRandom from "../src/lib/seeded_random";

// test/seeded_random.test.ts

describe("SeededRandom", () => {

    it("should be deterministic with the same seed", () => {
        let rng1 = SeededRandom.new(12345);
        let rng2 = SeededRandom.new(12345);

        for (let i = 1; i <= 10; i++) {
            let v1 = rng1.random();
            let v2 = rng2.random();
            expect(v2, "Values at step " + i + " should be identical").toBe(v1);
        }
    });

    it("should produce different values with different seeds", () => {
        let rng1 = SeededRandom.new(12345);
        let rng2 = SeededRandom.new(67890);

        // Check first few values
        let all_same = true;
        for (let i = 1; i <= 5; i++) {
            if (rng1.random() !== rng2.random()) {
                all_same = false;
                break;
            }
        }
        expect(!all_same, "Different seeds should produce different sequences").toBeTruthy();
    });

    it("should respect min/max for integers", () => {
        let rng = SeededRandom.new(123);
        let min = 5, max = 10;
        for (let i = 1; i <= 100; i++) {
            let val = rng.random_int(min, max);
            expect(val >= min && val <= max, "Value " + val + " out of range").toBeTruthy();
            expect(Math.floor(val), "Value should be integer").toBe(val);
        }
    });

    it("should restore state correctly", () => {
        let rng = SeededRandom.new(999);
        rng.random(); // advance a bit
        rng.random();

        let state = rng.get_state();
        let val1 = rng.random();

        rng.set_state(state);
        let val2 = rng.random();

        expect(val2, "Should reproduce value after restoring state").toBe(val1);
    });

    it("should reset to initial seed", () => {
        let rng = SeededRandom.new(555);
        let first_val = rng.random();

        rng.random(); // advance
        rng.reset();

        let reset_val = rng.random();
        expect(reset_val, "Should return to first value after reset").toBe(first_val);
    });

    it("should weighted_choice correctly", () => {
        // With a deterministic seed, we can predict choices, but let's just check validity
        let rng = SeededRandom.new(1);
       // Keep Lua source key order for weighted_choice RNG decisions.
        let weights = { a: 10, b: 0, c: 0 }; // Only 'a' should be chosen

        for (let i = 1; i <= 10; i++) {
            let choice = rng.weighted_choice(weights);
            expect(choice, "Should always choose non-zero weight option if others are zero").toBe("a");
        }
    });

});

it("pins the first five MINSTD values for seed 12345", () => {
    const rng = SeededRandom.new(12345);
   // Hand-computed state = state * 48271 - quotient * 2147483647:
   // 12345 * 48271 - 0 * 2147483647 = 595905495
   // 595905495 * 48271 - 13394 * 2147483647 = 1558181227
   // 1558181227 * 48271 - 35024 * 2147483647 = 1498755989
   // 1498755989 * 48271 - 33688 * 2147483647 = 2021244883
   // 2021244883 * 48271 - 45433 * 2147483647 = 887213142
    const expected = [595905495, 1558181227, 1498755989, 2021244883, 887213142];
    for (const state of expected) {
        expect(rng.random()).toBe(state / 2147483647);
    }
});
