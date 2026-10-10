import love from "../platform/love";
// src/entities/skier.lua
// Player-controlled skier entity with physics
import { draw_sprite } from "../gfx/sprite";
import Utils from "../lib/utils";
// Sprite per steering position (0-6); left positions are drawn mirrored
const SKIER_POSE: Record<number, string> = {
    1: "skier_sharp",
    2: "skier_gentle",
    3: "skier_center",
    4: "skier_gentle",
    5: "skier_sharp",
};
export default class Skier {
    [key: string]: any;
    // Discrete positions (like original SkiFree)
    // Each position maps to an angle and can have a sprite assigned
    static POSITIONS = [
        { name: "FULL_LEFT", angle: -90, speed_mult: 0 }, // 1: Full stop left (perpendicular)
        { name: "FAR_LEFT", angle: -60, speed_mult: 1.0 }, // 2: Sharp left (geometry only)
        { name: "LEFT", angle: -30, speed_mult: 1.0 }, // 3: Gentle left (geometry only)
        { name: "CENTER", angle: 0, speed_mult: 1.0 }, // 4: Straight down (full speed)
        { name: "RIGHT", angle: 30, speed_mult: 1.0 }, // 5: Gentle right (geometry only)
        { name: "FAR_RIGHT", angle: 60, speed_mult: 1.0 }, // 6: Sharp right (geometry only)
        { name: "FULL_RIGHT", angle: 90, speed_mult: 0 }, // 7: Full stop right (perpendicular)
    ];
    // Position index constants for easy reference
    static POS_FULL_LEFT = 0;
    static POS_FAR_LEFT = 1;
    static POS_LEFT = 2;
    static POS_CENTER = 3;
    static POS_RIGHT = 4;
    static POS_FAR_RIGHT = 5;
    static POS_FULL_RIGHT = 6;
    // Physics constants (scaled for 360x480 resolution)
    static BASE_SPEED = 140; // Base downhill speed (pixels/sec)
    static MAX_SPEED = 320; // Maximum speed
    static TUCK_SPEED_BONUS = 0.30; // 30% speed increase when tucking
    static CRASH_DURATION = 1.0; // Recovery time after crash
    static IMMUNITY_DURATION = 1.0; // Immunity time after crash recovery
    static HITBOX_RADIUS = 8; // Forgiving collision radius (scaled)
    static DEFLECT_VX_FACTOR = 0.8; // How much X velocity reverses on deflect
    // Mouse control settings (zone thresholds in pixels from center)
    static ZONE_CENTER = 30; // 0-30px = straight (position 4) - smaller deadzone
    static ZONE_GENTLE = 80; // 31-80px = gentle turn (position 3/5)
    static ZONE_SHARP = 140; // 81-140px = sharp turn (position 2/6)
    // 141px+ = full brake turn (position 1/7)
    // Speed interpolation factor for smooth acceleration/deceleration
    static SPEED_LERP_FACTOR = 4;
    static STOP_LERP_FACTOR = 3; // Deceleration when stopping (inertia)
    static STOPPED_THRESHOLD = 5; // Speed below which skier is considered stopped
    static SIDEWAYS_PUSH_SPEED = 60; // Speed of cross-country style sideways push
    static new(x?: any, y?: any): Skier { return new Skier(x, y); }
    constructor(x?: any, y?: any) {
        Object.assign(this, {
            x: x ?? 0,
            y: y ?? 0,
            vx: 0,
            vy: Skier.BASE_SPEED,
            position: Skier.POS_CENTER, // Current position index (0-6)
            speed: Skier.BASE_SPEED,
            is_tucking: false,
            is_crashed: false,
            crash_timer: 0,
            is_immune: false,
            immunity_timer: 0,
            is_stopped: false, // True when speed is below threshold
            is_sliding: false, // True when decelerating from full turn (sliding downhill)
            is_pushing: false, // True during sideways push animation
            // Animation state
            anim_timer: 0,
            ski_spread: 1
        });
    }
    get_position_data() {
        return Skier.POSITIONS[this.position];
    }
    get_angle() {
        return this.get_position_data().angle;
    }
    handle_input(dt: number, skier_screen_x: number) {
        if (this.is_crashed) {
            return;
        }
        // Tuck state - mouse button or keyboard
        this.is_tucking = love.mouse.isDown(1) || love.mouse.isDown(2) ||
            love.keyboard.isDown("down") ||
            love.keyboard.isDown("s") ||
            love.keyboard.isDown("lshift") ||
            love.keyboard.isDown("rshift");
        // Get mouse position in game coordinates
        let [mouse_x, _] = love.getGameMousePosition();
        // Calculate offset from skier's screen position
        let offset = mouse_x - skier_screen_x;
        let abs_offset = Math.abs(offset);
        // Map offset to position using explicit zone thresholds
        let new_position: number;
        if (abs_offset <= Skier.ZONE_CENTER) {
            // Center zone - go straight
            new_position = Skier.POS_CENTER;
        }
        else if (abs_offset <= Skier.ZONE_GENTLE) {
            // Gentle turn zone
            new_position = offset > 0 ? Skier.POS_RIGHT : Skier.POS_LEFT;
        }
        else if (abs_offset <= Skier.ZONE_SHARP) {
            // Sharp turn zone
            new_position = offset > 0 ? Skier.POS_FAR_RIGHT : Skier.POS_FAR_LEFT;
        }
        else {
            // Full brake turn zone
            new_position = offset > 0 ? Skier.POS_FULL_RIGHT : Skier.POS_FULL_LEFT;
        }
        this.position = new_position;
        // Check for sideways push when sliding/stopped and facing sideways
        this.is_pushing = false;
        if (this.is_sliding || this.is_stopped) {
            if (this.position === Skier.POS_FULL_LEFT && love.keyboard.isDown("a")) {
                this.is_pushing = true;
                this.push_direction = -1; // Push left
            }
            else if (this.position === Skier.POS_FULL_RIGHT && love.keyboard.isDown("d")) {
                this.is_pushing = true;
                this.push_direction = 1; // Push right
            }
        }
    }
    move_position(delta: number) {
        this.position = Utils.clamp(this.position + delta, 0, Skier.POSITIONS.length - 1);
    }
    update(dt: number, slope_bounds?: any) {
        // Update animation timer
        this.anim_timer = this.anim_timer + dt;
        // Handle crash recovery
        if (this.is_crashed) {
            this.crash_timer = this.crash_timer - dt;
            if (this.crash_timer <= 0) {
                this.is_crashed = false;
                this.is_immune = true;
                this.immunity_timer = Skier.IMMUNITY_DURATION;
                this.speed = Skier.BASE_SPEED * 0.5;
                this.position = Skier.POS_CENTER;
                this.is_stopped = false;
                this.is_sliding = false;
            }
            return;
        }
        // Handle immunity countdown
        if (this.is_immune) {
            this.immunity_timer = this.immunity_timer - dt;
            if (this.immunity_timer <= 0) {
                this.is_immune = false;
            }
        }
        // Get current position data
        let pos_data = this.get_position_data();
        let angle = pos_data.angle;
        let speed_mult = pos_data.speed_mult;
        // Calculate target speed based on position and tuck
        let target_speed = Skier.BASE_SPEED * speed_mult;
        if (this.is_tucking && speed_mult > 0) {
            target_speed = target_speed * (1 + Skier.TUCK_SPEED_BONUS);
        }
        // Check if we're in a full turn (stopping) position
        let is_full_turn = (this.position === Skier.POS_FULL_LEFT || this.position === Skier.POS_FULL_RIGHT);
        // Use different lerp factor when decelerating to stop (inertia)
        let lerp_factor = Skier.SPEED_LERP_FACTOR;
        if (target_speed < this.speed && target_speed === 0) {
            lerp_factor = Skier.STOP_LERP_FACTOR;
        }
        // Accelerate/decelerate towards target speed
        this.speed = Utils.lerp(this.speed, target_speed, dt * lerp_factor);
        this.speed = Utils.clamp(this.speed, 0, Skier.MAX_SPEED);
        // Update stopped and sliding states
        this.is_stopped = this.speed < Skier.STOPPED_THRESHOLD;
        this.is_sliding = is_full_turn && !this.is_stopped && this.speed > 0;
        // Calculate velocity
        if (this.is_sliding) {
            // Sliding: move straight down the mountain (inertia)
            this.vx = 0;
            this.vy = this.speed;
        }
        else {
            // Normal movement: based on angle
            let angle_rad = Utils.deg_to_rad(angle);
            this.vx = Math.sin(angle_rad) * this.speed;
            this.vy = Math.cos(angle_rad) * this.speed;
        }
        // Apply sideways push if pushing (cross-country style)
        // This adds to any existing velocity (can push while sliding)
        if (this.is_pushing) {
            this.vx = this.vx + this.push_direction * Skier.SIDEWAYS_PUSH_SPEED;
        }
        // Apply velocity
        this.x = this.x + this.vx * dt;
        this.y = this.y + this.vy * dt;
        // Clamp X position to slope bounds
        if (slope_bounds) {
            this.x = Utils.clamp(this.x, slope_bounds.min_x, slope_bounds.max_x);
        }
        // Subtle ski animation
        if (!this.is_tucking) {
            this.ski_spread = 1 + Math.sin(this.anim_timer * 3) * 0.1;
        }
        else {
            this.ski_spread = 0.3;
        }
    }
    crash() {
        if (!this.is_crashed) {
            this.is_crashed = true;
            this.crash_timer = Skier.CRASH_DURATION;
            this.speed = 0;
        }
    }
    slow_down(factor: number) {
        this.speed = this.speed * factor;
    }
    deflect() {
        this.vx = -this.vx * Skier.DEFLECT_VX_FACTOR;
        // Move position towards center on deflect
        if (this.position < Skier.POS_CENTER) {
            this.position = Math.min(this.position + 2, Skier.POS_CENTER);
        }
        else if (this.position > Skier.POS_CENTER) {
            this.position = Math.max(this.position - 2, Skier.POS_CENTER);
        }
    }
    get_hitbox() {
        return {
            x: this.x,
            y: this.y,
            radius: Skier.HITBOX_RADIUS
        };
    }
    draw() {
        // Flash effect during immunity (blink on/off rapidly)
        let visible = true;
        if (this.is_immune) {
            visible = Math.floor(this.anim_timer * 10) % 2 === 0;
        }
        if (visible) {
            if (this.is_crashed) {
                this.draw_crashed();
            }
            else if (this.position === Skier.POS_FULL_LEFT) {
                this.draw_side_view("left");
            }
            else if (this.position === Skier.POS_FULL_RIGHT) {
                this.draw_side_view("right");
            }
            else {
                this.draw_normal();
            }
        }
    }
    // Side view for the full-stop positions (skis across the slope)
    draw_side_view(direction?: any) {
        // direction: "left" or "right" (sprites face right; left is mirrored)
        let name = this.is_tucking ? "skier_side_tuck" : "skier_side";
        draw_sprite(name, this.x, this.y, direction === "left");
    }
    draw_normal() {
        // One sprite per steering position; left positions mirror the right ones
        let name = SKIER_POSE[this.position] ?? "skier_center";
        if (this.is_tucking) {
            name = name + "_tuck";
        }
        draw_sprite(name, this.x, this.y, this.position < Skier.POS_CENTER);
    }
    draw_crashed() {
        // Two frames so the dizzy stars circle
        let frame = Math.floor(this.anim_timer * 8) % 2 === 0 ? "skier_crash_1" : "skier_crash_2";
        draw_sprite(frame, this.x, this.y);
    }
}
