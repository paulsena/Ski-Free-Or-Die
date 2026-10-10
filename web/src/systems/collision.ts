// src/systems/collision.lua
// Collision detection and response system
import Utils from "../lib/utils";
const Collision = {
    // Check circle vs rectangle collision
    circle_rect(cx?: any, cy?: any, radius?: any, rx?: any, ry?: any, rw?: any, rh?: any) {
        let closest_x = Utils.clamp(cx, rx, rx + rw);
        let closest_y = Utils.clamp(cy, ry, ry + rh);
        let dist = Utils.distance(cx, cy, closest_x, closest_y);
        return dist < radius;
    },
    // Check circle vs circle collision
    circle_circle(x1: number, y1: number, r1: number, x2: number, y2: number, r2: number) {
        return Utils.distance(x1, y1, x2, y2) < r1 + r2;
    },
    // Check rectangle vs rectangle collision (AABB)
    rect_rect(x1: number, y1: number, w1: number, h1: number, x2: number, y2: number, w2: number, h2: number) {
        return x1 < x2 + w2 &&
            x2 < x1 + w1 &&
            y1 < y2 + h2 &&
            y2 < y1 + h1;
    },
    // Check skier collision against a list of obstacles
    // Returns the first obstacle collided with, or nil
    check_skier_obstacles(skier?: any, obstacles?: any) {
        let hitbox = skier.get_hitbox();
        for (const obs of obstacles) {
            if (obs.check_collision(hitbox)) {
                return obs;
            }
        }
        return undefined;
    },
    // Handle collision response between skier and obstacle
    resolve_obstacle_collision(skier?: any, obstacle?: any, camera?: any) {
        if (obstacle.collision_type === "slow") {
            // Just slow down
            skier.slow_down(obstacle.speed_penalty);
        }
        else if (obstacle.collision_type === "deflect") {
            // Slow down and deflect
            skier.slow_down(obstacle.speed_penalty);
            skier.deflect();
            if (camera) {
                camera.shake(2, 0.2);
            }
        }
        else if (obstacle.collision_type === "crash") {
            // Full crash
            skier.crash();
            if (camera) {
                camera.shake(4, 0.4);
            }
        }
    },
    // Check skier passing through gates
    // Returns number of gates passed and missed in this frame
    check_skier_gates(skier?: any, prev_y?: any, gates?: any): [
        number,
        number
    ] {
        let passed = 0;
        let missed = 0;
        for (const gate of gates) {
            let result = gate.check_pass(skier.x, skier.y, prev_y);
            if (result === "passed") {
                passed = passed + 1;
            }
            else if (result === "missed") {
                missed = missed + 1;
            }
        }
        return [passed, missed];
    },
    // Broad phase collision filtering
    // Returns only obstacles that are near the skier
    get_nearby_obstacles(skier?: any, obstacles?: any, radius?: any) {
        radius = radius ?? 100;
        let nearby = [] as any[];
        for (const obs of obstacles) {
            if (Utils.distance(skier.x, skier.y, obs.x, obs.y) < radius) {
                nearby.push(obs);
            }
        }
        return nearby;
    },
    // Get separation vector to push skier out of obstacle
    get_separation(skier_x: number, skier_y: number, skier_radius: number, obs?: any): [
        number,
        number
    ] {
        let hb = obs.get_hitbox();
        let closest_x = Utils.clamp(skier_x, hb.x, hb.x + hb.width);
        let closest_y = Utils.clamp(skier_y, hb.y, hb.y + hb.height);
        let dx = skier_x - closest_x;
        let dy = skier_y - closest_y;
        let dist = Math.sqrt(dx * dx + dy * dy);
        if (dist === 0) {
            return [1, 0]; // Default push direction
        }
        let overlap = skier_radius - dist;
        return [(dx / dist) * overlap, (dy / dist) * overlap];
    },
};
export default Collision;
