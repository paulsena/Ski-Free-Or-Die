import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import Leaderboard from "../src/core/leaderboard";

// In-memory localStorage for the actual love.filesystem shim.
beforeEach(() => {
    const data = new Map<string, string>();
    vi.stubGlobal("localStorage", {
        getItem: (key: string) => data.get(key) ?? null,
        setItem: (key: string, value: string) => { data.set(key, String(value)); },
        removeItem: (key: string) => { data.delete(key); },
        clear: () => data.clear(),
        key: (index: number) => Array.from(data.keys())[index] ?? null,
        get length() { return data.size; }
    });
    Leaderboard.clear_all();
});
afterEach(() => vi.unstubAllGlobals());

// test/leaderboard.test.ts

describe("Leaderboard", () => {

    describe("calculate_score", () => {
        describe("time_trial mode", () => {
            it("should calculate score from time with no gates missed", () => {
                let stats = {time: 60, gates_missed: 0};
                let score = Leaderboard.calculate_score("time_trial", stats);
                // Expected: 1000000 - (60 * 1000) = 940000
                expect(score).toBe(940000);
            });

            it("should add penalty for missed gates", () => {
                let stats = {time: 60, gates_missed: 2};
                let score = Leaderboard.calculate_score("time_trial", stats);
                // Expected: 1000000 - ((60 + 2*3) * 1000) = 1000000 - 66000 = 934000
                expect(score).toBe(934000);
            });

            it("should give higher score for faster time", () => {
                let fast_stats = {time: 45, gates_missed: 0};
                let slow_stats = {time: 60, gates_missed: 0};
                let fast_score = Leaderboard.calculate_score("time_trial", fast_stats);
                let slow_score = Leaderboard.calculate_score("time_trial", slow_stats);
                expect(fast_score > slow_score, "Faster time should have higher score").toBeTruthy();
            });

            it("should penalize gate misses correctly (3 seconds each)", () => {
                let clean_stats = {time: 50, gates_missed: 0};
                let missed_stats = {time: 50, gates_missed: 1};
                let clean_score = Leaderboard.calculate_score("time_trial", clean_stats);
                let missed_score = Leaderboard.calculate_score("time_trial", missed_stats);
                // Difference should be 3000 (3 seconds * 1000)
                expect(clean_score - missed_score).toBe(3000);
            });

            it("should handle zero time", () => {
                let stats = {time: 0, gates_missed: 0};
                let score = Leaderboard.calculate_score("time_trial", stats);
                expect(score).toBe(1000000);
            });
        });

        describe("endless mode", () => {
            it("should calculate score from distance", () => {
                let stats = {distance: 5000};
                let score = Leaderboard.calculate_score("endless", stats);
                // Expected: floor(5000 / 10) = 500 meters
                expect(score).toBe(500);
            });

            it("should floor the result", () => {
                let stats = {distance: 5009};
                let score = Leaderboard.calculate_score("endless", stats);
                // Expected: floor(5009 / 10) = 500 meters
                expect(score).toBe(500);
            });

            it("should handle zero distance", () => {
                let stats = {distance: 0};
                let score = Leaderboard.calculate_score("endless", stats);
                expect(score).toBe(0);
            });

            it("should give higher score for longer distance", () => {
                let short_stats = {distance: 1000};
                let long_stats = {distance: 5000};
                let short_score = Leaderboard.calculate_score("endless", short_stats);
                let long_score = Leaderboard.calculate_score("endless", long_stats);
                expect(long_score > short_score, "Longer distance should have higher score").toBeTruthy();
            });
        });

        describe("unknown mode", () => {
            it("should return 0 for unknown mode", () => {
                let stats = {time: 60, distance: 5000};
                let score = Leaderboard.calculate_score("unknown_mode", stats);
                expect(score).toBe(0);
            });
        });
    });

    describe("format_score", () => {
        describe("time_trial mode", () => {
            it("should format score back to time", () => {
                // Score 940000 = time of 60 seconds
                let formatted = Leaderboard.format_score("time_trial", 940000);
                expect(formatted).toBe("1:00.00");
            });

            it("should format perfect score (0 seconds)", () => {
                let formatted = Leaderboard.format_score("time_trial", 1000000);
                expect(formatted).toBe("0:00.00");
            });

            it("should format with decimal seconds", () => {
                // Score 954800 = 1000000 - 45200 = time of 45.2 seconds
                let formatted = Leaderboard.format_score("time_trial", 954800);
                expect(formatted).toBe("0:45.20");
            });

            it("should format times over a minute", () => {
                // Score 910000 = time of 90 seconds = 1:30
                let formatted = Leaderboard.format_score("time_trial", 910000);
                expect(formatted).toBe("1:30.00");
            });
        });

        describe("endless mode", () => {
            it("should format distance in meters", () => {
                let formatted = Leaderboard.format_score("endless", 500);
                expect(formatted).toBe("500m");
            });

            it("should format zero distance", () => {
                let formatted = Leaderboard.format_score("endless", 0);
                expect(formatted).toBe("0m");
            });

            it("should format large distances", () => {
                let formatted = Leaderboard.format_score("endless", 12345);
                expect(formatted).toBe("12345m");
            });
        });

        describe("unknown mode", () => {
            it("should return score as string for unknown mode", () => {
                let formatted = Leaderboard.format_score("unknown", 12345);
                expect(formatted).toBe("12345");
            });
        });
    });

    describe("qualifies", () => {
        // Note: These tests work with the internal scores state
        // We test the logic rather than full integration

        it("should return true when leaderboard is empty", () => {
            // Clear scores first
            Leaderboard.clear_all();
            const [qualifies, rank] = Leaderboard.qualifies("time_trial", 100);
            expect(qualifies, "Should qualify when empty").toBeTruthy();
            expect(rank).toBe(1);
        });

        it("should return true when leaderboard is not full", () => {
            Leaderboard.clear_all();
            // Add a few scores
            Leaderboard.add("time_trial", "AAA", 900000);
            Leaderboard.add("time_trial", "BBB", 800000);

            const [qualifies, rank] = Leaderboard.qualifies("time_trial", 850000);
            expect(qualifies, "Should qualify when not full").toBeTruthy();
        });

        it("should track separate leaderboards per mode", () => {
            Leaderboard.clear_all();
            Leaderboard.add("time_trial", "AAA", 900000);

            // Endless should still be empty
            const [qualifies, rank] = Leaderboard.qualifies("endless", 100);
            expect(qualifies, "Should qualify for empty endless leaderboard").toBeTruthy();
            expect(rank).toBe(1);
        });
    });

});
