// src/world/world_manager.ts
// Manages world generation, obstacles, gates, and cleanup
// Uses tile-based procedural generation for deterministic courses

import Obstacle from "../entities/obstacle";
import Gate from "../entities/gate";
import SeededRandom from "../lib/seeded_random";
import TileData from "./tile_data";
import TileGenerator from "./tile_generator";
import Config from "../core/config";
import love from "../platform/love";
import Colors from "../colors";
import { fill_px } from "../gfx/sprite";

// Visible area calculations based on camera offset (skier at 30% from top)
const VISIBLE_ABOVE = Config.GAME_HEIGHT * 0.3 + 50; // Extra buffer for tall sprites
const VISIBLE_BELOW = Config.GAME_HEIGHT * 0.7 + 50; // Extra buffer

export default class WorldManager {
    // World constants
    static SLOPE_WIDTH = 150; // Half-width of the skiable area
    static SPAWN_AHEAD = Config.SPAWN_AHEAD; // How far ahead to spawn content
    static DESPAWN_BEHIND = Config.DESPAWN_BEHIND; // How far behind to despawn content

    obstacles: Obstacle[] = [];
    gates: Gate[] = [];
    mode: string;
    seed: number;
    // Tile generator for procedural content
    tile_generator: TileGenerator;
    // Separate RNG for visual variations
    visual_rng: SeededRandom;
    // Track spawned tiles to avoid re-spawning
    spawned_tile_indices: Record<number, boolean> = {};
    // Current tile index for endless mode
    next_tile_y = 0;
    // Statistics
    total_obstacles_spawned = 0;
    total_gates_spawned = 0;
    // Course finish line position (for time trial)
    finish_line_y: number | undefined;

    constructor(seed?: number, mode?: string) {
        seed = seed ?? Config.get_weekly_seed();
        mode = mode ?? "time_trial";
        this.mode = mode;
        this.seed = seed;
        this.tile_generator = TileGenerator.new(seed, mode);
        this.visual_rng = SeededRandom.new(seed + 12345);
    }

    static new(seed?: number, mode?: string): WorldManager {
        return new WorldManager(seed, mode);
    }

    reset(): void {
        this.obstacles = [];
        this.gates = [];
        this.spawned_tile_indices = {};
        this.next_tile_y = 0;
        this.total_obstacles_spawned = 0;
        this.total_gates_spawned = 0;
        this.finish_line_y = undefined;
        // Reset generators to same seed for identical runs
        this.tile_generator.reset();
        this.visual_rng.reset();
        // Generate fresh course
        if (this.mode === "time_trial") this.generate_time_trial_course();
        else this.generate_initial_endless_tiles();
    }

    // Generate a complete time trial course
    generate_time_trial_course(): void {
        const tiles = this.tile_generator.generate_time_trial_course();
        // Spawn all tile content
        for (const [idx, tile] of tiles.entries()) this.spawn_tile_content(tile, idx);
        // Set finish line at end of course
        this.finish_line_y = this.tile_generator.get_total_height();
    }

    // Generate initial tiles for endless mode
    generate_initial_endless_tiles(): void {
        const initial_count = TileGenerator.ENDLESS_INITIAL_TILES;
        this.next_tile_y = 0;
        for (let i = 0; i < initial_count; i++) {
            const tile = this.tile_generator.generate_next_endless_tile(this.next_tile_y);
            this.spawn_tile_content(tile, i);
            this.next_tile_y = tile.y_end;
        }
    }

    // Initial spawn (called when game starts)
    initial_spawn(): void {
        if (this.mode === "time_trial") this.generate_time_trial_course();
        else this.generate_initial_endless_tiles();
    }

    update(dt: number, camera_y: number): void {
        // For endless mode, generate more tiles as needed
        if (this.mode === "endless") {
            while (this.next_tile_y < camera_y + WorldManager.SPAWN_AHEAD) {
                const tile_idx = this.tile_generator.get_tiles().length;
                const tile = this.tile_generator.generate_next_endless_tile(this.next_tile_y);
                this.spawn_tile_content(tile, tile_idx);
                this.next_tile_y = tile.y_end;
            }
        }
        // Update all gates
        for (const gate of this.gates) gate.update(dt);
        // Despawn content behind camera
        this.cleanup(camera_y);
    }

    // Spawn obstacles and gates from a tile definition
    spawn_tile_content(tile: TileData, tile_idx: number): void {
        // Avoid re-spawning tiles
        if (this.spawned_tile_indices[tile_idx]) return;
        this.spawned_tile_indices[tile_idx] = true;
        // Spawn obstacles defined in the tile
        for (const obs_def of tile.obstacles) {
            const obstacle = Obstacle.new_seeded(obs_def.x, obs_def.y, obs_def.type, this.visual_rng);
            this.obstacles.push(obstacle);
            this.total_obstacles_spawned = this.total_obstacles_spawned + 1;
        }
        // Spawn gates defined in the tile
        for (const gate_def of tile.gates) {
            const gate = Gate.new(gate_def.x, gate_def.y);
            this.gates.push(gate);
            this.total_gates_spawned = this.total_gates_spawned + 1;
        }
    }

    cleanup(camera_y: number): void {
        const despawn_y = camera_y - WorldManager.DESPAWN_BEHIND;
        // Remove obstacles behind camera
        for (let i = this.obstacles.length - 1; i >= 0; i--) {
            if (this.obstacles[i].y < despawn_y) this.obstacles.splice(i, 1);
        }
        // Remove gates behind camera
        for (let i = this.gates.length - 1; i >= 0; i--) {
            if (this.gates[i].y < despawn_y) this.gates.splice(i, 1);
        }
    }

    // Get slope speed multiplier at a Y position
    get_slope_multiplier(y: number): number {
        return this.tile_generator.get_slope_multiplier_at_y(y);
    }

    // Get current tile at Y position
    get_tile_at_y(y: number): TileData | undefined {
        return this.tile_generator.get_tile_at_y(y);
    }

    get_slope_bounds() {
        return {min_x: -WorldManager.SLOPE_WIDTH, max_x: WorldManager.SLOPE_WIDTH};
    }

    // Get finish line Y position (for time trial mode)
    get_finish_line_y(): number | undefined { return this.finish_line_y; }

    // Check if player has crossed finish line
    check_finish(skier_y: number): boolean {
        if (this.mode === "time_trial" && this.finish_line_y != null) {
            return skier_y >= this.finish_line_y;
        }
        return false;
    }

    draw(camera_y: number): void {
        const visible_top = camera_y - VISIBLE_ABOVE;
        const visible_bottom = camera_y + VISIBLE_BELOW;
        // Draw tile backgrounds/indicators (optional, for debugging)
        // this.draw_tile_debug(camera_y);
        // Draw finish line if in view (time trial mode)
        if (this.finish_line_y != null && this.finish_line_y > visible_top && this.finish_line_y < visible_bottom) {
            this.draw_finish_line();
        }
        // Draw gates (behind other objects)
        for (const gate of this.gates) {
            if (gate.y > visible_top && gate.y < visible_bottom) gate.draw();
        }
        // Draw obstacles sorted by Y for proper overlap
        const sorted_obstacles: Obstacle[] = [];
        for (const obs of this.obstacles) {
            if (obs.y > visible_top && obs.y < visible_bottom) sorted_obstacles.push(obs);
        }
        sorted_obstacles.sort((a, b) => a.y - b.y);
        for (const obs of sorted_obstacles) obs.draw();
    }

    draw_finish_line(): void {
        const x_left = -WorldManager.SLOPE_WIDTH;
        const x_right = WorldManager.SLOPE_WIDTH;
        const y = this.finish_line_y!;
        // Checkered pattern finish line
        const checker_size = 10;
        const num_checkers = Math.ceil((x_right - x_left) / checker_size);
        for (let i = 0; i < num_checkers; i++) {
            const x = x_left + i * checker_size;
            // Alternating black and white
            fill_px(i % 2 === 0 ? "K" : "W", x, y - 5, checker_size, 10);
        }
        fill_px("P", x_left, y - 6, x_right - x_left, 1);
        fill_px("P", x_left, y + 5, x_right - x_left, 1);
        // "FINISH" text
        Colors.set(Colors.BRIGHT_YELLOW);
        love.graphics.printf("FINISH", x_left, y - 25, x_right - x_left, "center");
    }

    // Debug visualization of tiles
    draw_tile_debug(camera_y: number): void {
        const tiles = this.tile_generator.get_tiles();
        for (const tile of tiles) {
            if (tile.y_end > camera_y - 100 && tile.y_start < camera_y + 200) {
                // Draw tile boundary
                love.graphics.setColor(1, 1, 1, 0.1);
                love.graphics.rectangle("line", -WorldManager.SLOPE_WIDTH, tile.y_start,
                    WorldManager.SLOPE_WIDTH * 2, TileData.TILE_HEIGHT);
                // Label tile type
                love.graphics.setColor(1, 1, 1, 0.3);
                love.graphics.print(tile.template_name ?? tile.type, -WorldManager.SLOPE_WIDTH + 5, tile.y_start + 5);
            }
        }
    }

    // Get all obstacles for collision checking
    get_obstacles(): Obstacle[] { return this.obstacles; }
    // Get all gates for pass checking
    get_gates(): Gate[] { return this.gates; }
    // Get tile generator for external access
    get_tile_generator(): TileGenerator { return this.tile_generator; }
}
