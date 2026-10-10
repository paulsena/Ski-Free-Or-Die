// src/entities/obstacle.lua
// Obstacle entities: trees, rocks, cabins
import { draw_sprite } from "../gfx/sprite";
import { CABIN_ROOF_BLUE } from "../gfx/sprites/variants";
import Utils from "../lib/utils";
export default class Obstacle {
    [key: string]: any;
    // Obstacle type definitions (scaled for 360x480 resolution)
    static TYPES: Record<string, any> = {
        small_tree: {
            width: 18,
            height: 24,
            collision_type: "slow", // Just slows down
            speed_penalty: 0.8, // 20% speed loss
            spawn_weight: 35 // Spawn probability weight
        },
        large_tree: {
            width: 28,
            height: 40,
            collision_type: "deflect", // Slows and deflects
            speed_penalty: 0.4, // 60% speed loss
            spawn_weight: 25
        },
        rock: {
            width: 24,
            height: 18,
            collision_type: "crash", // Full crash
            speed_penalty: 0,
            spawn_weight: 20
        },
        cabin: {
            width: 42,
            height: 36,
            collision_type: "crash", // Full crash
            speed_penalty: 0,
            spawn_weight: 10
        },
        snow_mound: {
            width: 30,
            height: 12,
            collision_type: "slow",
            speed_penalty: 0.9, // 10% speed loss
            spawn_weight: 10
        }
    };
    // Ordered list of type names for deterministic iteration
    static TYPE_ORDER = ["small_tree", "large_tree", "rock", "cabin", "snow_mound"];
    // Non-seeded constructor - uses fixed visual defaults for determinism.
    // WARNING: Do NOT use this function for deterministic gameplay (e.g., Weekly Time Trial).
    // Use Obstacle.new_seeded() or Obstacle.spawn_random_seeded() instead for reproducible runs.
    static new(x: number, y: number, obs_type?: any): Obstacle { return new Obstacle(x, y, obs_type); }
    constructor(x: number, y: number, obs_type?: any) {
        let type_def = Obstacle.TYPES[obs_type];
        if (!type_def) {
            obs_type = "small_tree";
            type_def = Obstacle.TYPES.small_tree;
        }
        Object.assign(this, {
            x: x,
            y: y,
            type: obs_type,
            width: type_def.width,
            height: type_def.height,
            collision_type: type_def.collision_type,
            speed_penalty: type_def.speed_penalty,
            // Fixed visual defaults (no random variation for determinism)
            scale: 1.0,
            flip: false
        });
    }
    static spawn_random(x: number, y: number) {
        // Weighted random selection (uses math.random - non-deterministic)
        let total_weight = 0;
        for (const type_name of Obstacle.TYPE_ORDER) {
            total_weight = total_weight + Obstacle.TYPES[type_name].spawn_weight;
        }
        let roll = Math.random() * total_weight;
        let cumulative = 0;
        for (const type_name of Obstacle.TYPE_ORDER) {
            cumulative = cumulative + Obstacle.TYPES[type_name].spawn_weight;
            if (roll <= cumulative) {
                return Obstacle.new(x, y, type_name);
            }
        }
        return Obstacle.new(x, y, "small_tree");
    }
    // Seeded version for deterministic generation
    static spawn_random_seeded(x: number, y: number, rng?: any) {
        // Weighted random selection using seeded RNG
        let total_weight = 0;
        for (const type_name of Obstacle.TYPE_ORDER) {
            total_weight = total_weight + Obstacle.TYPES[type_name].spawn_weight;
        }
        let roll = rng.random() * total_weight;
        let cumulative = 0;
        for (const type_name of Obstacle.TYPE_ORDER) {
            cumulative = cumulative + Obstacle.TYPES[type_name].spawn_weight;
            if (roll <= cumulative) {
                return Obstacle.new_seeded(x, y, type_name, rng);
            }
        }
        return Obstacle.new_seeded(x, y, "small_tree", rng);
    }
    // Seeded constructor for visual variations
    static new_seeded(x: number, y: number, obs_type?: any, rng?: any) {
        let type_def = Obstacle.TYPES[obs_type];
        if (!type_def) {
            obs_type = "small_tree";
            type_def = Obstacle.TYPES.small_tree;
        }
        let self = {
            x: x,
            y: y,
            type: obs_type,
            width: type_def.width,
            height: type_def.height,
            collision_type: type_def.collision_type,
            speed_penalty: type_def.speed_penalty,
            // Visual variation using seeded RNG
            scale: 0.9 + rng.random() * 0.2,
            flip: rng.random() > 0.5
        };
        return Object.assign(Object.create(Obstacle.prototype), self);
    }
    get_hitbox() {
        return {
            x: this.x - this.width / 2,
            y: this.y - this.height / 2,
            width: this.width,
            height: this.height
        };
    }
    check_collision(skier_hitbox?: any) {
        // Circle vs rectangle collision
        let hb = this.get_hitbox();
        let closest_x = Utils.clamp(skier_hitbox.x, hb.x, hb.x + hb.width);
        let closest_y = Utils.clamp(skier_hitbox.y, hb.y, hb.y + hb.height);
        return Utils.distance(skier_hitbox.x, skier_hitbox.y, closest_x, closest_y) < skier_hitbox.radius;
    }
    draw() {
        if (this.type === "small_tree") {
            this.draw_small_tree();
        }
        else if (this.type === "large_tree") {
            this.draw_large_tree();
        }
        else if (this.type === "rock") {
            this.draw_rock();
        }
        else if (this.type === "cabin") {
            this.draw_cabin();
        }
        else if (this.type === "snow_mound") {
            this.draw_snow_mound();
        }
    }
    draw_small_tree() {
        draw_sprite(this.scale >= 1.0 ? "small_tree_snowy" : "small_tree", this.x, this.y, this.flip);
    }
    draw_large_tree() {
        draw_sprite(this.scale >= 1.0 ? "large_tree_snowy" : "large_tree", this.x, this.y, this.flip);
    }
    draw_rock() {
        draw_sprite("rock", this.x, this.y, this.flip);
    }
    draw_cabin() {
        draw_sprite("cabin", this.x, this.y, this.flip, this.scale >= 1.0 ? CABIN_ROOF_BLUE : undefined);
    }
    draw_snow_mound() {
        draw_sprite("snow_mound", this.x, this.y, this.flip);
    }
}
