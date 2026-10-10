import { fill_px } from "../gfx/sprite";
// src/systems/particles.lua
// Simple particle system for visual effects
//
// NOTE: This module intentionally uses non-seeded math.random() for all particle
// generation. Particles are purely cosmetic visual effects and do not affect
// gameplay state, collision, scoring, or deterministic replay. Using non-seeded
// RNG provides natural visual variety without impacting game reproducibility.
import Colors from "../colors";
import Utils from "../lib/utils";
// Minimum speed required to emit snow spray particles
let MIN_SPEED_FOR_SNOW_SPRAY = 30;
export default class Particles {
    [key: string]: any;
    // Particle types
    static TYPES: Record<string, any> = {
        snow_spray: {
            key: "s",
            lifetime: [0.3, 0.6],
            speed: [20, 60],
            size: [1, 3],
            gravity: 30,
            fade: true,
            color: Colors.SNOW_WHITE
        },
        impact_snow: {
            key: "s",
            lifetime: [0.4, 0.8],
            speed: [40, 100],
            size: [2, 4],
            gravity: 50,
            fade: true,
            color: Colors.SNOW
        },
        crash_debris: {
            key: "b",
            lifetime: [0.5, 1.0],
            speed: [30, 80],
            size: [1, 3],
            gravity: 80,
            fade: true,
            color: Colors.SNOW_WHITE
        },
        gate_sparkle: {
            key: "M",
            lifetime: [0.2, 0.5],
            speed: [20, 50],
            size: [2, 4],
            gravity: -20, // Float up
            fade: true,
            color: Colors.MINT_GREEN
        }
    };
    static new(): Particles { return new Particles(); }
    constructor() {
        Object.assign(this, {
            particles: [],
            max_particles: 200
        });
    }
    emit(x: number, y: number, particle_type?: any, count?: any, direction_min?: any, direction_max?: any) {
        let type_def = Particles.TYPES[particle_type];
        if (!type_def) {
            type_def = Particles.TYPES.snow_spray;
        }
        count = count ?? 5;
        direction_min = direction_min ?? 0;
        direction_max = direction_max ?? Math.PI * 2;
        for (let i = 1; i <= count; i++) {
            if (this.particles.length >= this.max_particles) {
                // Remove oldest particle
                this.particles.splice(1 - 1, 1);
            }
            let angle = direction_min + Math.random() * (direction_max - direction_min);
            let speed = type_def.speed[0] + Math.random() * (type_def.speed[1] - type_def.speed[0]);
            let lifetime = type_def.lifetime[0] + Math.random() * (type_def.lifetime[1] - type_def.lifetime[0]);
            let size = type_def.size[0] + Math.random() * (type_def.size[1] - type_def.size[0]);
            let particle = {
                x: x,
                y: y,
                vx: Math.cos(angle) * speed,
                vy: Math.sin(angle) * speed,
                size: size,
                lifetime: lifetime,
                max_lifetime: lifetime,
                gravity: type_def.gravity,
                fade: type_def.fade,
                key: type_def.key,
                color: type_def.color
            };
            this.particles.push(particle);
        }
    }
    emit_snow_spray(x: number, y: number, skier_angle: number, skier_speed: number, is_turning?: any) {
        if (skier_speed < MIN_SPEED_FOR_SNOW_SPRAY) {
            return;
        }
        // More particles when turning
        let count = is_turning ? 3 : 1;
        let speed_factor = skier_speed / 100;
        // Spray direction based on skier angle and turning
        let base_angle = Math.PI + Utils.deg_to_rad(skier_angle);
        let spray_spread = is_turning ? 0.6 : 0.3;
        for (let i = 1; i <= count; i++) {
            let angle = base_angle + (Math.random() - 0.5) * spray_spread;
            let speed = (20 + Math.random() * 40) * speed_factor;
            if (this.particles.length < this.max_particles) {
                this.particles.push({
                    x: x + (Math.random() - 0.5) * 6,
                    y: y + 8 + Math.random() * 4,
                    vx: Math.cos(angle) * speed,
                    vy: Math.sin(angle) * speed * 0.3,
                    size: 1 + Math.random() * 2,
                    lifetime: 0.3 + Math.random() * 0.3,
                    max_lifetime: 0.6,
                    gravity: 30,
                    fade: true,
                    key: "s",
                    color: Colors.SNOW_WHITE
                });
            }
        }
    }
    emit_crash(x: number, y: number) {
        // Big impact spray
        this.emit(x, y, "crash_debris", 15, 0, Math.PI * 2);
        // Some upward debris
        for (let i = 1; i <= 5; i++) {
            if (this.particles.length < this.max_particles) {
                this.particles.push({
                    x: x + (Math.random() - 0.5) * 10,
                    y: y,
                    vx: (Math.random() - 0.5) * 60,
                    vy: -40 - Math.random() * 40,
                    size: 2 + Math.random() * 2,
                    lifetime: 0.6 + Math.random() * 0.4,
                    max_lifetime: 1.0,
                    gravity: 100,
                    fade: true,
                    key: "s",
                    color: Colors.SNOW
                });
            }
        }
    }
    emit_gate_pass(x: number, y: number, passed?: any) {
        let color = passed ? Colors.MINT_GREEN : Colors.HOT_PINK;
        let count = passed ? 8 : 4;
        for (let i = 1; i <= count; i++) {
            if (this.particles.length < this.max_particles) {
                let angle = -Math.PI / 2 + (Math.random() - 0.5) * 1.2; // Mostly upward
                let speed = 30 + Math.random() * 40;
                this.particles.push({
                    x: x + (Math.random() - 0.5) * 30,
                    y: y,
                    vx: Math.cos(angle) * speed,
                    vy: Math.sin(angle) * speed,
                    size: 2 + Math.random() * 2,
                    lifetime: 0.3 + Math.random() * 0.3,
                    max_lifetime: 0.6,
                    gravity: -30,
                    fade: true,
                    key: passed ? "M" : "P",
                    color: color
                });
            }
        }
    }
    update(dt: number) {
        for (let i = this.particles.length - 1; i >= 0; i--) {
            let p = this.particles[i];
            // Apply gravity
            p.vy = p.vy + p.gravity * dt;
            // Update position
            p.x = p.x + p.vx * dt;
            p.y = p.y + p.vy * dt;
            // Update lifetime
            p.lifetime = p.lifetime - dt;
            // Remove dead particles
            if (p.lifetime <= 0) {
                this.particles.splice(i, 1);
            }
        }
    }
    draw() {
        for (const p of this.particles) {
            let sz = Math.max(1, Math.round(p.size * (p.fade ? p.lifetime / p.max_lifetime : 1) + 0.5));
            fill_px(p.key, Math.round(p.x - sz / 2), Math.round(p.y - sz / 2), sz, sz);
        }
    }
    clear() {
        this.particles = [];
    }
    get_count() {
        return this.particles.length;
    }
}
