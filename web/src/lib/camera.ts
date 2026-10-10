// src/lib/camera.ts
// Simple 2D camera with follow behavior

import love from "../platform/love";

export default class Camera {
  x = 0;
  y = 0;
  target_x = 0;
  target_y = 0;
  offset_x = 0;
  offset_y = 0;
  smooth = 5; // Higher = faster follow
  shake_intensity = 0;
  shake_duration = 0;
  shake_timer = 0;
  shake_offset_x = 0;
  shake_offset_y = 0;

  static new(): Camera {
    return new Camera();
  }

  set_target(x: number, y: number): void {
    this.target_x = x;
    this.target_y = y;
  }

  set_offset(x: number, y: number): void {
    this.offset_x = x;
    this.offset_y = y;
  }

  update(dt: number): void {
    // Smooth follow
    const t = 1 - Math.exp(-this.smooth * dt);
    this.x = this.x + (this.target_x - this.x) * t;
    this.y = this.y + (this.target_y - this.y) * t;

    // Screen shake
    if (this.shake_timer > 0) {
      this.shake_timer -= dt;
      const progress = this.shake_timer / this.shake_duration;
      const intensity = this.shake_intensity * progress;
      this.shake_offset_x = (Math.random() * 2 - 1) * intensity;
      this.shake_offset_y = (Math.random() * 2 - 1) * intensity;
    } else {
      this.shake_offset_x = 0;
      this.shake_offset_y = 0;
    }
  }

  snap(): void {
    // Instantly move to target
    this.x = this.target_x;
    this.y = this.target_y;
  }

  shake(intensity: number, duration: number): void {
    this.shake_intensity = intensity;
    this.shake_duration = duration;
    this.shake_timer = duration;
  }

  apply(): void {
    // Apply camera transform
    love.graphics.push();
    love.graphics.translate(
      Math.round(-this.x + this.offset_x + this.shake_offset_x),
      Math.round(-this.y + this.offset_y + this.shake_offset_y),
    );
  }

  reset(): void {
    love.graphics.pop();
  }

  // Convert screen coords to world coords
  screen_to_world(sx: number, sy: number): [number, number] {
    return [sx + this.x - this.offset_x, sy + this.y - this.offset_y];
  }

  // Convert world coords to screen coords
  world_to_screen(wx: number, wy: number): [number, number] {
    return [wx - this.x + this.offset_x, wy - this.y + this.offset_y];
  }

  // Get visible world bounds
  get_visible_bounds(screen_width: number, screen_height: number): [number, number, number, number] {
    const [world_x, world_y] = this.screen_to_world(0, 0);
    return [world_x, world_y, screen_width, screen_height];
  }
}
