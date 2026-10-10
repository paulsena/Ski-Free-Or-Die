// src/world/tile_generator.ts
// Generates tile sequences from seeds with pacing rules and difficulty curves

import TileData from "./tile_data";
import SeededRandom from "../lib/seeded_random";
import Obstacle from "../entities/obstacle";
import Gate from "../entities/gate";

export default class TileGenerator {
    // Course configuration
    static TIME_TRIAL_TILES = 20;      // Approximately 60-90 seconds of gameplay
    static ENDLESS_INITIAL_TILES = 10; // Initial tiles for endless mode

    // Difficulty phases (percent of course completion)
    static DIFFICULTY_PHASES = [
        {max_percent: 0.25, min_diff: 1, max_diff: 2, name: "warmup"},
        {max_percent: 0.50, min_diff: 2, max_diff: 3, name: "rising"},
        {max_percent: 0.75, min_diff: 3, max_diff: 4, name: "challenge"},
        {max_percent: 1.00, min_diff: 4, max_diff: 5, name: "climax"}
    ];

    // Set piece insertion points (tile indices for a 20-tile course)
    static SET_PIECE_POSITIONS = [8, 15]; // Midpoint and near end (one-based course positions)

    // Gate reachability: the skier's sharpest carve is 60 degrees (tan 60 = ~1.73 px across per px down).
    // Gates are placed so reaching the next one never needs more than this ratio, leaving headroom.
    static GATE_MAX_LATERAL_RATIO = 0.9;
    static GATE_LINE_MARGIN = 12;      // How far inside a gate's poles the skier is assumed to pass
    static GATE_CLEAR_X = 10;          // Extra obstacle-free width beyond each pole
    static GATE_CLEAR_ABOVE = 60;      // Obstacle-free run-in above the gate line
    static GATE_CLEAR_BELOW = 20;

    rng: SeededRandom;
    seed: number;
    mode: string;
    tiles: TileData[] = [];
    total_tiles_generated = 0;
    last_tile_difficulty = 0;
    hard_tile_count = 0; // Track consecutive hard tiles
    tiles_since_speed = 0; // Track tiles since last speed tile
    last_gate: {x: number; y: number} | undefined; // Previous gate, for reachability across tiles

    constructor(seed: number, mode?: string) {
        this.rng = SeededRandom.new(seed);
        this.seed = seed;
        this.mode = mode ?? "time_trial";
    }

    static new(seed: number, mode?: string): TileGenerator {
        return new TileGenerator(seed, mode);
    }

    // Reset generator to initial state
    reset(): void {
        this.rng.reset();
        this.tiles = [];
        this.total_tiles_generated = 0;
        this.last_tile_difficulty = 0;
        this.hard_tile_count = 0;
        this.tiles_since_speed = 0;
        this.last_gate = undefined;
    }

    // Generate a complete time trial course
    generate_time_trial_course(): TileData[] {
        this.reset();
        const num_tiles = TileGenerator.TIME_TRIAL_TILES;
        let y_position = 0;
        for (let i = 0; i < num_tiles; i++) {
            const progress = (i + 1) / num_tiles;
            const tile = this.generate_tile(progress, y_position, i + 1);
            this.tiles.push(tile);
            y_position = tile.y_end;
            this.total_tiles_generated = i + 1;
        }
        return this.tiles;
    }

    // Generate next tile for endless mode
    generate_next_endless_tile(y_position: number): TileData {
        this.total_tiles_generated = this.total_tiles_generated + 1;
        // Endless mode: difficulty keeps increasing
        // After 30 tiles, difficulty is maxed but density increases
        const effective_tile = Math.min(this.total_tiles_generated, 30);
        const progress = effective_tile / 30;
        const tile = this.generate_tile(progress, y_position, this.total_tiles_generated);
        this.tiles.push(tile);
        return tile;
    }

    // Generate a single tile based on progress and pacing rules
    generate_tile(progress: number, y_position: number, tile_index: number): TileData {
        // Determine difficulty phase
        const phase = this.get_difficulty_phase(progress);
        // Check for set piece positions
        if (this.is_set_piece_position(tile_index)) {
            return this.generate_set_piece_tile(y_position);
        }
        // Get valid templates based on difficulty and pacing rules
        const valid_templates = this.get_valid_templates(phase);
        // Select a template
        let template_name = this.rng.choose(valid_templates);
        if (template_name === undefined) template_name = "warmup"; // Fallback
        // Create the tile
        const tile = TileData.new(template_name, y_position);
        // Populate tile with content
        this.populate_tile(tile);
        // Update pacing state
        this.update_pacing_state(tile);
        return tile;
    }

    // Get difficulty phase for progress
    get_difficulty_phase(progress: number) {
        for (const phase of TileGenerator.DIFFICULTY_PHASES) {
            if (progress <= phase.max_percent) return phase;
        }
        return TileGenerator.DIFFICULTY_PHASES[TileGenerator.DIFFICULTY_PHASES.length - 1];
    }

    // Check if current tile index should be a set piece
    is_set_piece_position(tile_index: number): boolean {
        for (const pos of TileGenerator.SET_PIECE_POSITIONS) {
            if (tile_index === pos) return true;
        }
        return false;
    }

    // Generate a set piece tile
    generate_set_piece_tile(y_position: number): TileData {
        const set_pieces = ["cabin_chicane", "the_gauntlet", "ski_lift_alley", "spectator_row"];
        const set_piece_type = this.rng.choose(set_pieces)!;
        // Create a custom tile for set pieces
        const tile = Object.assign(Object.create(TileData.prototype), {
            template_name: "set_piece_" + set_piece_type,
            type: TileData.TileType.SET_PIECE,
            set_piece_type: set_piece_type,
            slope: TileData.SlopeIntensity.MODERATE,
            difficulty: 4,
            y_start: y_position,
            y_end: y_position + TileData.TILE_HEIGHT,
            obstacles: [],
            gates: []
        }) as TileData;
        // Populate with set piece content
        this.populate_set_piece(tile);
        return tile;
    }

    // Get valid templates based on pacing rules
    get_valid_templates(phase: {min_diff: number; max_diff: number; name: string}): string[] {
        const valid: string[] = [];
        const all_templates = TileData.get_templates_for_difficulty(phase.min_diff, phase.max_diff);
        for (const template_name of all_templates) {
            const template = TileData.TILE_TEMPLATES[template_name];
            // Pacing rule: No two hard tiles back-to-back
            if (template.difficulty >= 4 && this.hard_tile_count >= 1) continue;
            // Pacing rule: Speed tile after 2-3 technical tiles
            if (this.tiles_since_speed >= 3 && template.type !== TileData.TileType.SPEED) {
                // Force speed tile consideration
                if (this.rng.random() < 0.7) continue;
            }
            // Special handling for warmup phase - only warmup tiles
            if (phase.name === "warmup" && template.type !== TileData.TileType.WARMUP) {
                // Allow some easy slalom in warmup
                if (template.type !== TileData.TileType.SLALOM || template.difficulty > 2) continue;
            }
            valid.push(template_name);
        }
        // If no valid templates, add at least warmup
        if (valid.length === 0) valid.push("warmup");
        // Add speed tile option if we've had too many technical tiles
        if (this.tiles_since_speed >= 2 && !this.contains_template(valid, "speed")) valid.push("speed");
        return valid;
    }

    // Check if a template list contains a specific template
    contains_template(templates: string[], name: string): boolean {
        for (const t of templates) {
            if (t === name) return true;
        }
        return false;
    }

    // Update pacing state after generating a tile
    update_pacing_state(tile: TileData): void {
        this.last_tile_difficulty = tile.difficulty;
        // Track hard tile streaks
        if (tile.difficulty >= 4) this.hard_tile_count = this.hard_tile_count + 1;
        else this.hard_tile_count = 0;
        // Track tiles since speed
        if (tile.type === TileData.TileType.SPEED) this.tiles_since_speed = 0;
        else this.tiles_since_speed = this.tiles_since_speed + 1;
    }

    // Populate a tile with obstacles and gates
    populate_tile(tile: TileData): void {
        const half_width = TileData.TILE_WIDTH / 2;
        // Generate obstacles
        if (tile.obstacle_density != null && tile.obstacle_density > 0) {
            const num_obstacles = Math.floor(tile.obstacle_density * 10); // 0-10 obstacles per tile
            for (let i = 0; i < num_obstacles; i++) {
                const x = this.rng.random_float(-half_width * 0.9, half_width * 0.9);
                const y = tile.y_start + TileData.TRANSITION_ZONE +
                    this.rng.random_float(0, TileData.TILE_HEIGHT - 2 * TileData.TRANSITION_ZONE);
                // Choose obstacle type from template's allowed types
                let obs_type = "small_tree";
                if (tile.obstacle_types && tile.obstacle_types.length > 0) {
                    obs_type = this.rng.choose<string>(tile.obstacle_types)!;
                }
                tile.obstacles.push({type: obs_type, x: x, y: y});
            }
        }
        // Generate gates for slalom tiles
        if (tile.gate_count) {
            const [min_gates, max_gates] = tile.gate_count;
            let num_gates = this.rng.random_int(min_gates, max_gates);
            if (num_gates > 0) {
                const spacing = TileData.GATE_SPACING[tile.gate_spacing ?? "normal"] ?? 80;
                const start_y = tile.y_start + TileData.TRANSITION_ZONE + 20;
                const last_y = tile.y_end - TileData.TRANSITION_ZONE;
                // Never squeeze gates below their spacing; drop gates that don't fit instead
                const max_fit = Math.floor((last_y - start_y) / spacing) + 1;
                num_gates = Math.min(num_gates, max_fit);
                let alternate = this.rng.random_bool(); // Start left or right
                for (let i = 0; i < num_gates; i++) {
                    // Alternate gates left and right
                    const x_offset = half_width * 0.4;
                    let x = alternate ? -x_offset : x_offset;
                    alternate = !alternate;
                    // Add some random variation
                    x = x + this.rng.random_float(-20, 20);
                    const y = start_y + i * spacing;
                    x = this.clamp_gate_reachable(x, y);
                    tile.gates.push({x: x, y: y});
                    this.last_gate = {x: x, y: y};
                }
                this.clear_obstacles_near_gates(tile);
            }
        }
    }

    // Pull a gate toward the previous one so the skier can reach it from there
    clamp_gate_reachable(x: number, y: number): number {
        if (!this.last_gate) return x;
        const dy = y - this.last_gate.y;
        const slack = Gate.WIDTH - 2 * TileGenerator.GATE_LINE_MARGIN;
        const max_dx = slack + dy * TileGenerator.GATE_MAX_LATERAL_RATIO;
        return Math.max(this.last_gate.x - max_dx, Math.min(this.last_gate.x + max_dx, x));
    }

    // Remove obstacles sitting in a gate opening or right in front of it
    clear_obstacles_near_gates(tile: TileData): void {
        tile.obstacles = tile.obstacles.filter((obs: {x: number; y: number}) => {
            for (const gate of tile.gates) {
                const in_opening = Math.abs(obs.x - gate.x) <= Gate.WIDTH / 2 + TileGenerator.GATE_CLEAR_X;
                const near_line = obs.y > gate.y - TileGenerator.GATE_CLEAR_ABOVE && obs.y < gate.y + TileGenerator.GATE_CLEAR_BELOW;
                if (in_opening && near_line) return false;
            }
            return true;
        });
    }

    // Populate set piece tiles with handcrafted content
    populate_set_piece(tile: TileData): void {
        const half_width = TileData.TILE_WIDTH / 2;
        if (tile.set_piece_type === "cabin_chicane") {
            // Tight weave between cabins
            const positions = [
                {x: -40, y: tile.y_start + 60},
                {x: 40, y: tile.y_start + 120},
                {x: -30, y: tile.y_start + 180},
                {x: 50, y: tile.y_start + 240}
            ];
            for (const pos of positions) {
                tile.obstacles.push({type: "cabin", x: pos.x, y: pos.y});
            }
        } else if (tile.set_piece_type === "the_gauntlet") {
            // Dense obstacles with one clean line
            for (let i = 0; i < 20; i++) {
                const x = this.rng.random_float(-half_width * 0.9, half_width * 0.9);
                const y = tile.y_start + TileData.TRANSITION_ZONE +
                    this.rng.random_float(0, TileData.TILE_HEIGHT - 2 * TileData.TRANSITION_ZONE);
                // Leave a narrow path down the center
                if (Math.abs(x) > 25) {
                    const obs_type = this.rng.random_bool(0.6) ? "large_tree" : "rock";
                    tile.obstacles.push({type: obs_type, x: x, y: y});
                }
            }
        } else if (tile.set_piece_type === "ski_lift_alley") {
            // Poles in regular pattern (like ski lift poles)
            for (let i = 0; i <= 5; i++) {
                const y = tile.y_start + 40 + i * 50;
                tile.obstacles.push({type: "small_tree", x: -60, y: y});
                tile.obstacles.push({type: "small_tree", x: 60, y: y});
            }
        } else if (tile.set_piece_type === "spectator_row") {
            // No obstacles - just speed! The vibes tile.
            // Could add spectator sprites on the sides later
            tile.slope = TileData.SlopeIntensity.STEEP;
        }
    }

    // Get tile at Y position
    get_tile_at_y(y: number): TileData | undefined {
        for (const tile of this.tiles) {
            if (y >= tile.y_start && y < tile.y_end) return tile;
        }
        return undefined;
    }

    // Get slope multiplier at Y position
    get_slope_multiplier_at_y(y: number): number {
        const tile = this.get_tile_at_y(y);
        if (tile && tile.slope != null) return TileData.SLOPE_MULTIPLIERS[tile.slope] ?? 1.0;
        return 1.0;
    }

    // Get all tiles
    get_tiles(): TileData[] { return this.tiles; }

    // Get total world height (for finish line placement)
    get_total_height(): number {
        if (this.tiles.length === 0) return 0;
        return this.tiles[this.tiles.length - 1].y_end;
    }
}
