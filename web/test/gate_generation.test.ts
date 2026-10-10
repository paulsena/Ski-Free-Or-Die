import { describe, it, expect } from "vitest";
import TileGenerator from "../src/world/tile_generator";
import TileData from "../src/world/tile_data";
import Gate from "../src/entities/gate";

// test/gate_generation.test.ts

// Sharpest carving angle the skier can hold (60 degrees)
const SKIER_MAX_RATIO = Math.tan(Math.PI / 3);

function all_gates(tiles: TileData[]) {
    const gates: {x: number; y: number; spacing: number}[] = [];
    for (const tile of tiles) {
        for (const g of tile.gates) gates.push({...g, spacing: TileData.GATE_SPACING[tile.gate_spacing ?? "normal"]});
    }
    return gates;
}

function check_reachable(gates: {x: number; y: number}[]) {
    for (let i = 1; i < gates.length; i++) {
        const a = gates[i - 1], b = gates[i];
        const dy = b.y - a.y;
        // Lateral travel needed if the skier threads both gates as close to each other as possible
        const needed = Math.max(0, Math.abs(b.x - a.x) - (Gate.WIDTH - 2 * TileGenerator.GATE_LINE_MARGIN));
        expect(dy).toBeGreaterThan(0);
        expect(needed / dy).toBeLessThanOrEqual(TileGenerator.GATE_MAX_LATERAL_RATIO + 1e-9);
        expect(TileGenerator.GATE_MAX_LATERAL_RATIO).toBeLessThan(SKIER_MAX_RATIO);
    }
}

describe("Gate generation", () => {
    it("keeps every consecutive gate pair reachable in time trial courses", () => {
        for (let seed = 1; seed <= 300; seed++) {
            const tiles = TileGenerator.new(seed).generate_time_trial_course();
            check_reachable(all_gates(tiles));
        }
    });

    it("keeps every consecutive gate pair reachable in endless mode", () => {
        for (let seed = 1; seed <= 100; seed++) {
            const gen = TileGenerator.new(seed, "endless");
            let y = 0;
            for (let i = 0; i < 50; i++) y = gen.generate_next_endless_tile(y).y_end;
            check_reachable(all_gates(gen.get_tiles()));
        }
    });

    it("never squeezes gates closer than their tile's spacing", () => {
        for (let seed = 1; seed <= 300; seed++) {
            for (const tile of TileGenerator.new(seed).generate_time_trial_course()) {
                const spacing = TileData.GATE_SPACING[tile.gate_spacing ?? "normal"];
                for (let i = 1; i < tile.gates.length; i++) {
                    expect(tile.gates[i].y - tile.gates[i - 1].y).toBeGreaterThanOrEqual(spacing);
                }
                for (const g of tile.gates) expect(g.y).toBeLessThanOrEqual(tile.y_end - TileData.TRANSITION_ZONE);
            }
        }
    });

    it("keeps gate openings clear of obstacles", () => {
        for (let seed = 1; seed <= 300; seed++) {
            for (const tile of TileGenerator.new(seed).generate_time_trial_course()) {
                for (const g of tile.gates) {
                    for (const o of tile.obstacles) {
                        const blocking = Math.abs(o.x - g.x) <= Gate.WIDTH / 2 && Math.abs(o.y - g.y) < 20;
                        expect(blocking).toBe(false);
                    }
                }
            }
        }
    });
});
