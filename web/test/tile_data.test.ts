import { describe, it, expect } from "vitest";
import TileData from "../src/world/tile_data";

// test/tile_data.test.ts

describe("TileData", () => {

    describe("new", () => {
        it("should create tile from warmup template", () => {
            let tile = TileData.new("warmup", 0);
            expect(tile.template_name).toBe("warmup");
            expect(tile.type).toBe(TileData.TileType.WARMUP);
            expect(tile.slope).toBe(TileData.SlopeIntensity.GENTLE);
            expect(tile.difficulty).toBe(1);
        });

        it("should create tile from slalom_easy template", () => {
            let tile = TileData.new("slalom_easy", 0);
            expect(tile.type).toBe(TileData.TileType.SLALOM);
            expect(tile.variant).toBe(TileData.SlalomVariant.EASY);
            expect(tile.difficulty).toBe(2);
        });

        it("should create tile from slalom_hard template", () => {
            let tile = TileData.new("slalom_hard", 0);
            expect(tile.type).toBe(TileData.TileType.SLALOM);
            expect(tile.variant).toBe(TileData.SlalomVariant.HARD);
            expect(tile.difficulty).toBe(4);
        });

        it("should set y_start from position parameter", () => {
            let tile = TileData.new("warmup", 500);
            expect(tile.y_start).toBe(500);
        });

        it("should calculate y_end based on TILE_HEIGHT", () => {
            let tile = TileData.new("warmup", 500);
            expect(tile.y_end).toBe(500 + TileData.TILE_HEIGHT);
        });

        it("should initialize empty obstacles array", () => {
            let tile = TileData.new("warmup", 0);
            expect(tile.obstacles.length).toBe(0);
        });

        it("should initialize empty gates array", () => {
            let tile = TileData.new("warmup", 0);
            expect(tile.gates.length).toBe(0);
        });

        it("should error on unknown template", () => {
            expect(() => TileData.new("nonexistent_template", 0)).toThrow();
        });
    });

    describe("get_templates_for_difficulty", () => {
        it("should return warmup and speed for difficulty 1", () => {
            let templates = TileData.get_templates_for_difficulty(1, 1);
            // Difficulty 1 templates: warmup, speed
            expect(templates.length >= 2, "Should have at least 2 templates for difficulty 1").toBeTruthy();

            // Check that warmup is included
            let has_warmup = false;
            let has_speed = false;
            for (const name of templates) {
                if (name === "warmup") { has_warmup = true; }
                if (name === "speed") { has_speed = true; }
            }
            expect(has_warmup, "Should include warmup template").toBeTruthy();
            expect(has_speed, "Should include speed template").toBeTruthy();
        });

        it("should return slalom_easy for difficulty 2", () => {
            let templates = TileData.get_templates_for_difficulty(2, 2);

            let has_slalom_easy = false;
            for (const name of templates) {
                if (name === "slalom_easy") { has_slalom_easy = true; }
            }
            expect(has_slalom_easy, "Should include slalom_easy template").toBeTruthy();
        });

        it("should return multiple templates for difficulty range 3-4", () => {
            let templates = TileData.get_templates_for_difficulty(3, 4);
            // Difficulty 3: slalom_medium, obstacle_forest, ramp
            // Difficulty 4: slalom_hard, obstacle_rocks
            expect(templates.length >= 4, "Should have multiple templates for difficulty 3-4").toBeTruthy();
        });

        it("should return hardest templates for difficulty 5", () => {
            let templates = TileData.get_templates_for_difficulty(5, 5);

            let has_obstacle_mixed = false;
            for (const name of templates) {
                if (name === "obstacle_mixed") { has_obstacle_mixed = true; }
            }
            expect(has_obstacle_mixed, "Should include obstacle_mixed (difficulty 5)").toBeTruthy();
        });

        it("should return empty array for out-of-range difficulty", () => {
            let templates = TileData.get_templates_for_difficulty(99, 100);
            expect(templates.length).toBe(0);
        });

        it("should return all templates for wide difficulty range", () => {
            let templates = TileData.get_templates_for_difficulty(1, 5);
            // Count all templates in TILE_TEMPLATES
            let template_count = 0;
            for (const _ in TileData.TILE_TEMPLATES) {
                template_count = template_count + 1;
            }
            expect(templates.length).toBe(template_count);
        });
    });

    describe("get_templates_by_type", () => {
        it("should return slalom templates", () => {
            let templates = TileData.get_templates_by_type(TileData.TileType.SLALOM);
            // Should have easy, medium, hard
            expect(templates.length).toBe(3);
        });

        it("should return obstacle field templates", () => {
            let templates = TileData.get_templates_by_type(TileData.TileType.OBSTACLE_FIELD);
            // Should have forest, rocks, mixed
            expect(templates.length).toBe(3);
        });

        it("should return warmup templates", () => {
            let templates = TileData.get_templates_by_type(TileData.TileType.WARMUP);
            expect(templates.length).toBe(1);
        });

        it("should return empty array for unknown type", () => {
            let templates = TileData.get_templates_by_type("nonexistent_type");
            expect(templates.length).toBe(0);
        });
    });

    describe("get_slope_multiplier", () => {
        it("should return gentle multiplier for warmup tile", () => {
            let tile = TileData.new("warmup", 0);
            expect(Math.abs(0.85 - tile.get_slope_multiplier())).toBeLessThanOrEqual(0.001);
        });

        it("should return moderate multiplier for slalom_medium tile", () => {
            let tile = TileData.new("slalom_medium", 0);
            expect(Math.abs(1.0 - tile.get_slope_multiplier())).toBeLessThanOrEqual(0.001);
        });

        it("should return steep multiplier for speed tile", () => {
            let tile = TileData.new("speed", 0);
            expect(Math.abs(1.2 - tile.get_slope_multiplier())).toBeLessThanOrEqual(0.001);
        });
    });

    describe("contains_y", () => {
        it("should return true for y within tile", () => {
            let tile = TileData.new("warmup", 100);
            expect(tile.contains_y(200), "Should contain y=200 in tile starting at 100").toBeTruthy();
        });

        it("should return true for y at tile start", () => {
            let tile = TileData.new("warmup", 100);
            expect(tile.contains_y(100), "Should contain y at tile start").toBeTruthy();
        });

        it("should return false for y at tile end", () => {
            let tile = TileData.new("warmup", 100);
            // y_end is exclusive (uses < not <=)
            expect(!tile.contains_y(100 + TileData.TILE_HEIGHT), "Should not contain y at tile end").toBeTruthy();
        });

        it("should return false for y before tile", () => {
            let tile = TileData.new("warmup", 100);
            expect(!tile.contains_y(50), "Should not contain y before tile").toBeTruthy();
        });

        it("should return false for y after tile", () => {
            let tile = TileData.new("warmup", 100);
            expect(!tile.contains_y(600), "Should not contain y after tile").toBeTruthy();
        });
    });

    describe("is_transition_zone", () => {
        it("should return true for y near tile start", () => {
            let tile = TileData.new("warmup", 0);
            // Transition zone is first TRANSITION_ZONE pixels
            expect(tile.is_transition_zone(10), "Should be in transition zone near start").toBeTruthy();
        });

        it("should return true for y near tile end", () => {
            let tile = TileData.new("warmup", 0);
            // Transition zone is last TRANSITION_ZONE pixels
            let near_end = TileData.TILE_HEIGHT - 10;
            expect(tile.is_transition_zone(near_end), "Should be in transition zone near end").toBeTruthy();
        });

        it("should return false for y in middle of tile", () => {
            let tile = TileData.new("warmup", 0);
            let middle = TileData.TILE_HEIGHT / 2;
            expect(!tile.is_transition_zone(middle), "Should not be in transition zone in middle").toBeTruthy();
        });
    });

    describe("constants", () => {
        it("should have positive TILE_HEIGHT", () => {
            expect(TileData.TILE_HEIGHT > 0, "TILE_HEIGHT should be positive").toBeTruthy();
        });

        it("should have positive TILE_WIDTH", () => {
            expect(TileData.TILE_WIDTH > 0, "TILE_WIDTH should be positive").toBeTruthy();
        });

        it("should have TRANSITION_ZONE less than half TILE_HEIGHT", () => {
            expect(TileData.TRANSITION_ZONE < TileData.TILE_HEIGHT / 2, "TRANSITION_ZONE should be less than half TILE_HEIGHT").toBeTruthy();
        });

        it("should have valid gate spacing values", () => {
            expect(TileData.GATE_SPACING.wide > 0, "wide spacing should be positive").toBeTruthy();
            expect(TileData.GATE_SPACING.normal > 0, "normal spacing should be positive").toBeTruthy();
            expect(TileData.GATE_SPACING.tight > 0, "tight spacing should be positive").toBeTruthy();
            expect(TileData.GATE_SPACING.wide > TileData.GATE_SPACING.tight, "wide spacing should be greater than tight").toBeTruthy();
        });
    });

});
