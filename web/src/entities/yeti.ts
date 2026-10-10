import love from "../platform/love";
// src/entities/yeti.lua
// The dreaded Yeti that chases players in endless mode
import { draw_sprite } from "../gfx/sprite";
import Utils from "../lib/utils";
// Run cycle frames (the mid pose is shared) and the eye-glow palette swap
const YETI_RUN_FRAMES = ["yeti_run_1", "yeti_run_2", "yeti_run_3", "yeti_run_2"];
const EYE_GLOW = { E: "O" };
export default class Yeti {
    [key: string]: any;
    // Yeti constants (scaled for 360x480 resolution)
    static BASE_SPEED = 70; // Base speed (slightly slower than skier)
    static SPEED_INCREASE_RATE = 0.01; // Speed increase per second
    static CATCH_DISTANCE = 30; // Distance at which yeti catches player
    static START_DISTANCE = -300; // Starting distance behind player (closer for more tension)
    static BOOST_ON_CRASH = 1.5; // Speed multiplier when player crashes
    static WIDTH = 36;
    static HEIGHT = 48;
    // Yeti danger zones (scaled for 360x480 resolution)
    static ZONE_SAFE = 500; // Beyond this, player is safe
    static ZONE_WARNING = 350; // Warning zone starts here
    static ZONE_DANGER = 150; // Danger zone starts here
    static ZONE_CRITICAL = 75; // Critical zone - about to catch
    static new(): Yeti { return new Yeti(); }
    constructor() {
        Object.assign(this, {
            distance: Yeti.START_DISTANCE, // Distance behind player (negative)
            speed_multiplier: 1.0,
            elapsed_time: 0,
            anim_timer: 0,
            // Animation state
            frame: 1,
            arm_swing: 0,
            is_lunging: false,
            lunge_timer: 0
        });
    }
    reset() {
        this.distance = Yeti.START_DISTANCE;
        this.speed_multiplier = 1.0;
        this.elapsed_time = 0;
        this.anim_timer = 0;
        this.is_lunging = false;
    }
    update(dt: number, skier_speed: number, is_skier_crashed?: any) {
        this.elapsed_time = this.elapsed_time + dt;
        this.anim_timer = this.anim_timer + dt;
        // Gradually increase speed over time
        this.speed_multiplier = 1.0 + this.elapsed_time * Yeti.SPEED_INCREASE_RATE;
        // Calculate yeti speed
        let yeti_speed = Yeti.BASE_SPEED * this.speed_multiplier;
        // Speed boost when player crashes
        if (is_skier_crashed) {
            yeti_speed = yeti_speed * Yeti.BOOST_ON_CRASH;
        }
        // Update distance relative to player
        let relative_speed = yeti_speed - skier_speed;
        this.distance = this.distance + relative_speed * dt;
        // Arm swing animation
        this.arm_swing = Math.sin(this.anim_timer * 6) * 0.4;
        // Lunge animation when very close
        if (this.distance > -Yeti.ZONE_CRITICAL && !this.is_lunging) {
            this.is_lunging = true;
            this.lunge_timer = 0;
        }
        if (this.is_lunging) {
            this.lunge_timer = this.lunge_timer + dt;
            if (this.lunge_timer > 0.5) {
                this.is_lunging = false;
            }
        }
        // Check if caught
        return this.distance >= -Yeti.CATCH_DISTANCE;
    }
    get_danger_zone() {
        let abs_dist = -this.distance;
        if (abs_dist > Yeti.ZONE_SAFE) {
            return "safe";
        }
        else if (abs_dist > Yeti.ZONE_WARNING) {
            return "warning";
        }
        else if (abs_dist > Yeti.ZONE_DANGER) {
            return "danger";
        }
        else {
            return "critical";
        }
    }
    get_danger_intensity() {
        // Returns 0-1 based on how close yeti is
        let abs_dist = Math.max(0, -this.distance);
        return 1 - Utils.clamp(abs_dist / Yeti.ZONE_SAFE, 0, 1);
    }
    draw(camera_y: number, screen_height: number) {
        // Only draw if yeti is close enough to be visible
        if (this.distance < -350) {
            return;
        }
        // Calculate screen position (yeti appears at top of screen when close)
        let yeti_y = camera_y + this.distance;
        let screen_y = yeti_y - (camera_y - screen_height * 0.7);
        // Only draw if on screen
        if (screen_y < -50 || screen_y > screen_height + 50) {
            return;
        }
        // Center yeti horizontally on screen (180 = GAME_WIDTH / 2)
        let screen_x = 180;
        // Apply lunge effect: a forward hop toward the skier (pixel art isn't scaled)
        let hop = 0;
        if (this.is_lunging) {
            let t = this.lunge_timer / 0.5;
            hop = Math.round(Math.sin(t * Math.PI) * 6);
        }
        this.draw_yeti(screen_x, screen_y + hop);
    }
    draw_yeti(x: number, y: number) {
        let frame: string;
        if (this.is_lunging) {
            frame = this.lunge_timer < 0.25 ? "yeti_lunge_1" : "yeti_lunge_2";
        }
        else {
            // Run cycle follows the arm swing phase (sin(anim_timer * 6))
            let phase = Math.floor(this.anim_timer * 6 / (Math.PI / 2)) % 4;
            frame = YETI_RUN_FRAMES[phase];
        }
        // Eye glow effect: eyes flicker between red and orange
        let swap = Math.floor(this.anim_timer * 4) % 2 === 0 ? EYE_GLOW : undefined;
        draw_sprite(frame, x, y, false, swap);
    }
    // Draw danger vignette effect
    draw_danger_overlay(screen_width: number, screen_height: number) {
        let intensity = this.get_danger_intensity();
        if (intensity < 0.1) {
            return;
        }
        let zone = this.get_danger_zone();
        let [r, g, b] = [0.8, 0, 0];
        if (zone === "warning") {
            [r, g, b] = [0.8, 0.4, 0];
        }
        else if (zone === "critical") {
            // Pulsing red for critical
            let pulse = 0.5 + Math.sin(this.anim_timer * 8) * 0.5;
            r = 1 * pulse;
        }
        let alpha = intensity * 0.4;
        // Vignette effect on edges
        love.graphics.setColor(r, g, b, alpha);
        // Top edge
        love.graphics.rectangle("fill", 0, 0, screen_width, 12);
        // Bottom edge
        love.graphics.rectangle("fill", 0, screen_height - 12, screen_width, 12);
        // Left edge
        love.graphics.rectangle("fill", 0, 0, 12, screen_height);
        // Right edge
        love.graphics.rectangle("fill", screen_width - 12, 0, 12, screen_height);
    }
}
