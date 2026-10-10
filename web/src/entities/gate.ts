// src/entities/gate.lua
// Slalom gate entities
import { draw_sprite, fill_px } from "../gfx/sprite";
import { GATE_SWAPS } from "../gfx/sprites/gate";
import Utils from "../lib/utils";
export default class Gate {
    [key: string]: any;
    // Gate dimensions (scaled for 360x480 resolution)
    static WIDTH = 75; // Default gate width
    static PENALTY = 3; // Seconds added for missed gate
    static new(x: number, y: number, width?: any, direction?: any): Gate { return new Gate(x, y, width, direction); }
    constructor(x: number, y: number, width?: any, direction?: any) {
        Object.assign(this, {
            x: x,
            y: y,
            width: width ?? Gate.WIDTH,
            direction: direction ?? "center", // "left", "right", "center"
            state: "pending", // "pending", "passed", "missed"
            anim_timer: 0,
            flash_timer: 0
        });
    }
    get_trigger_zone() {
        return {
            x: this.x - this.width / 2,
            y: this.y - 8,
            width: this.width,
            height: 16
        };
    }
    check_pass(skier_x: number, skier_y: number, prev_y: number) {
        // Only check if still pending
        if (this.state !== "pending") {
            return undefined;
        }
        // Check if skier crossed the gate line
        if (prev_y < this.y && skier_y >= this.y) {
            // Check if within gate width
            if (Math.abs(skier_x - this.x) <= this.width / 2) {
                this.state = "passed";
                this.flash_timer = 0.5;
                return "passed";
            }
            else {
                this.state = "missed";
                this.flash_timer = 0.5;
                return "missed";
            }
        }
        return undefined;
    }
    update(dt: number) {
        this.anim_timer = this.anim_timer + dt;
        if (this.flash_timer > 0) {
            this.flash_timer = this.flash_timer - dt;
        }
    }
    draw() {
        let pole_height = 30; // Scaled for 360x480
        let banner_height = 9; // Scaled for 360x480
        // Determine palette swap based on state (base sprite colors are the pending pink)
        let swap = GATE_SWAPS[this.state];
        // Flash effect when state just changed
        if (this.flash_timer > 0 && Math.floor(this.flash_timer * 10) % 2 === 0) {
            swap = GATE_SWAPS.flash;
        }
        let key = (k: string) => swap?.[k] ?? k;
        let left = Math.round(this.x - this.width / 2);
        let right = Math.round(this.x + this.width / 2);
        let top = Math.round(this.y - pole_height / 2);
        // Banner between poles: alternating stripes with a darker top/bottom edge
        let stripe_width = (right - left) / 5;
        for (let i = 0; i <= 4; i++) {
            let x0 = left + Math.round(i * stripe_width);
            let x1 = left + Math.round((i + 1) * stripe_width);
            fill_px(i % 2 === 0 ? "W" : key("P"), x0, top, x1 - x0, banner_height);
        }
        fill_px(key("p"), left, top, right - left, 1);
        fill_px(key("p"), left, top + banner_height - 1, right - left, 1);
        // Poles (with ball tops) over the banner ends
        draw_sprite("gate_pole", left, this.y, false, swap);
        draw_sprite("gate_pole", right, this.y, false, swap);
        // Direction arrow indicator (bobs above pending gates)
        if (this.state === "pending") {
            let arrow_y = this.y - pole_height - 8 + Math.round(Math.sin(this.anim_timer * 4) * 2);
            draw_sprite("gate_arrow", this.x, arrow_y);
        }
    }
    // Create a sequence of gates for slalom sections
    static create_slalom_sequence(start_y: number, count: number, spacing: number, slope_width: number) {
        let gates = [] as any[];
        let alternating = Math.random() > 0.5;
        for (let i = 1; i <= count; i++) {
            let y = start_y + (i - 1) * spacing;
            let x_offset: any;
            if (alternating) {
                // Alternating left/right pattern
                if (i % 2 === 1) {
                    x_offset = -slope_width * 0.3;
                }
                else {
                    x_offset = slope_width * 0.3;
                }
            }
            else {
                // Random positions with constraints
                x_offset = (Math.random() - 0.5) * slope_width * 0.6;
            }
            let gate = Gate.new(x_offset, y);
            gates.push(gate);
        }
        return gates;
    }
}
