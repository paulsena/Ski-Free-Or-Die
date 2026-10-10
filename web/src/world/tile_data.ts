// src/world/tile_data.ts
// Tile data structures for procedural generation

export default class TileData {
    [key: string]: any;

    // Tile type enumeration
    static TileType = {
        WARMUP: "warmup",
        SLALOM: "slalom",
        OBSTACLE_FIELD: "obstacle_field",
        SPEED: "speed",
        RAMP: "ramp",
        CHOICE: "choice",
        SET_PIECE: "set_piece"
    };

    // Slope intensity enumeration
    static SlopeIntensity = {
        GENTLE: "gentle",
        MODERATE: "moderate",
        STEEP: "steep"
    };

    // Slope intensity multipliers (affects skier speed)
    static SLOPE_MULTIPLIERS: Record<string, number> = {
        gentle: 0.85,
        moderate: 1.0,
        steep: 1.2
    };

    // Tile dimension constants (scaled for 360x480 resolution)
    static TILE_HEIGHT = 400;          // Vertical length of each tile (roughly 3-5 seconds of skiing)
    static TILE_WIDTH = 340;           // Width of skiable area (slightly less than screen width)
    static TRANSITION_ZONE = 50;       // Safe zone at tile edges (no obstacles)

    // Slalom variants
    static SlalomVariant = {
        EASY: "easy",
        MEDIUM: "medium",
        HARD: "hard"
    };

    // Obstacle field variants
    static ObstacleFieldVariant = {
        FOREST_RUN: "forest_run",
        ROCK_GARDEN: "rock_garden",
        MIXED_HAZARD: "mixed_hazard"
    };

    // Set piece types (handcrafted memorable sections)
    static SetPieceType = {
        CABIN_CHICANE: "cabin_chicane",
        THE_GAUNTLET: "the_gauntlet",
        SKI_LIFT_ALLEY: "ski_lift_alley",
        SPECTATOR_ROW: "spectator_row"
    };

    // Tile definition templates
    // These define constraints for procedural content within tiles
    // Keep Lua source key order: template iteration feeds RNG selection.
    static TILE_TEMPLATES: Record<string, any> = {
        // Warmup tiles
        warmup: {
            type: TileData.TileType.WARMUP,
            slope: TileData.SlopeIntensity.GENTLE,
            difficulty: 1,
            obstacle_density: 0.2,         // Low density
            obstacle_types: ["small_tree"],
            gate_count: [0, 1],            // Range: 0-1 gates
            gate_spacing: "wide"
        },

        // Slalom variants
        slalom_easy: {
            type: TileData.TileType.SLALOM,
            variant: TileData.SlalomVariant.EASY,
            slope: TileData.SlopeIntensity.GENTLE,
            difficulty: 2,
            obstacle_density: 0.0,
            obstacle_types: [],
            gate_count: [2, 3],
            gate_spacing: "wide"
        },
        slalom_medium: {
            type: TileData.TileType.SLALOM,
            variant: TileData.SlalomVariant.MEDIUM,
            slope: TileData.SlopeIntensity.MODERATE,
            difficulty: 3,
            obstacle_density: 0.3,
            obstacle_types: ["small_tree"],
            gate_count: [3, 4],
            gate_spacing: "normal"
        },
        slalom_hard: {
            type: TileData.TileType.SLALOM,
            variant: TileData.SlalomVariant.HARD,
            slope: TileData.SlopeIntensity.STEEP,
            difficulty: 4,
            obstacle_density: 0.5,
            obstacle_types: ["small_tree", "large_tree"],
            gate_count: [4, 5],
            gate_spacing: "tight"
        },

        // Obstacle field variants
        obstacle_forest: {
            type: TileData.TileType.OBSTACLE_FIELD,
            variant: TileData.ObstacleFieldVariant.FOREST_RUN,
            slope: TileData.SlopeIntensity.MODERATE,
            difficulty: 3,
            obstacle_density: 0.7,
            obstacle_types: ["small_tree", "large_tree"],
            gate_count: [0, 0]
        },
        obstacle_rocks: {
            type: TileData.TileType.OBSTACLE_FIELD,
            variant: TileData.ObstacleFieldVariant.ROCK_GARDEN,
            slope: TileData.SlopeIntensity.MODERATE,
            difficulty: 4,
            obstacle_density: 0.5,
            obstacle_types: ["rock"],
            gate_count: [0, 0]
        },
        obstacle_mixed: {
            type: TileData.TileType.OBSTACLE_FIELD,
            variant: TileData.ObstacleFieldVariant.MIXED_HAZARD,
            slope: TileData.SlopeIntensity.STEEP,
            difficulty: 5,
            obstacle_density: 0.8,
            obstacle_types: ["small_tree", "large_tree", "rock", "cabin"],
            gate_count: [0, 0]
        },

        // Speed tiles (breathing room)
        speed: {
            type: TileData.TileType.SPEED,
            slope: TileData.SlopeIntensity.STEEP,
            difficulty: 1,
            obstacle_density: 0.1,
            obstacle_types: ["small_tree"],
            gate_count: [0, 0]
        },

        // Ramp tile (future use)
        ramp: {
            type: TileData.TileType.RAMP,
            slope: TileData.SlopeIntensity.MODERATE,
            difficulty: 3,
            obstacle_density: 0.2,
            obstacle_types: ["small_tree"],
            gate_count: [0, 0],
            has_ramp: true
        }
    };

    // Gate spacing constants (scaled for 360x480 resolution)
    static GATE_SPACING: Record<string, number> = {
        wide: 120,      // Easy: lots of room
        normal: 100,    // Medium: moderate challenge
        tight: 75       // Hard: precision required
    };


    // Create a new tile instance from a template
    constructor(template_name: string, y_position: number) {
        const template = TileData.TILE_TEMPLATES[template_name];
        if (!template) {
            throw new Error("Unknown tile template: " + String(template_name));
        }
        this.template_name = template_name;
        this.type = template.type;
        this.variant = template.variant;
        this.slope = template.slope;
        this.difficulty = template.difficulty;
        this.obstacle_density = template.obstacle_density;
        this.obstacle_types = template.obstacle_types;
        this.gate_count = template.gate_count;
        this.gate_spacing = template.gate_spacing;
        this.has_ramp = template.has_ramp;

        // Position in world
        this.y_start = y_position;
        this.y_end = y_position + TileData.TILE_HEIGHT;

        // Generated content (filled by tile_generator)
        this.obstacles = [];
        this.gates = [];
    }

    static new(template_name: string, y_position: number): TileData {
        return new TileData(template_name, y_position);
    }

    // Get the slope speed multiplier for this tile
    get_slope_multiplier(): number {
        return TileData.SLOPE_MULTIPLIERS[this.slope] ?? 1.0;
    }

    // Check if a Y position is within this tile
    contains_y(y: number): boolean {
        return y >= this.y_start && y < this.y_end;
    }

    // Check if Y is in the transition zone (top or bottom edges)
    is_transition_zone(y: number): boolean {
        const rel_y = y - this.y_start;
        return rel_y < TileData.TRANSITION_ZONE || rel_y > (TileData.TILE_HEIGHT - TileData.TRANSITION_ZONE);
    }

    // Get available templates for a given difficulty range
    static get_templates_for_difficulty(min_diff: number, max_diff: number): string[] {
        const templates: string[] = [];
        // Lua pairs(): preserve source key order because this list feeds RNG decisions.
        for (const name in TileData.TILE_TEMPLATES) {
            const template = TileData.TILE_TEMPLATES[name];
            if (template.difficulty >= min_diff && template.difficulty <= max_diff) {
                templates.push(name);
            }
        }
        return templates;
    }

    // Get templates by type
    static get_templates_by_type(tile_type: string): string[] {
        const templates: string[] = [];
        // Lua pairs(): preserve the templates' source key order.
        for (const name in TileData.TILE_TEMPLATES) {
            const template = TileData.TILE_TEMPLATES[name];
            if (template.type === tile_type) templates.push(name);
        }
        return templates;
    }
}
