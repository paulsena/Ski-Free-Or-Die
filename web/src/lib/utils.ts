// src/lib/utils.ts
// Common utility functions

const Utils = {
  // Clamp a value between min and max
  clamp(value: number, min: number, max: number): number {
    return Math.max(min, Math.min(max, value));
  },

  // Linear interpolation
  lerp(a: number, b: number, t: number): number {
    return a + (b - a) * t;
  },

  // Distance between two points
  distance(x1: number, y1: number, x2: number, y2: number): number {
    const dx = x2 - x1;
    const dy = y2 - y1;
    return Math.sqrt(dx * dx + dy * dy);
  },

  // Check if two circles overlap
  circles_collide(x1: number, y1: number, r1: number, x2: number, y2: number, r2: number): boolean {
    return Utils.distance(x1, y1, x2, y2) < r1 + r2;
  },

  // Check if two AABBs overlap
  aabb_collide(x1: number, y1: number, w1: number, h1: number, x2: number, y2: number, w2: number, h2: number): boolean {
    return x1 < x2 + w2 && x2 < x1 + w1 && y1 < y2 + h2 && y2 < y1 + h1;
  },

  // Check if point is inside rectangle
  point_in_rect(px: number, py: number, rx: number, ry: number, rw: number, rh: number): boolean {
    return px >= rx && px <= rx + rw && py >= ry && py <= ry + rh;
  },

  // Sign of a number (-1, 0, or 1)
  sign(x: number): number {
    return x > 0 ? 1 : x < 0 ? -1 : 0;
  },

  // Round to nearest integer
  round(x: number): number {
    return Math.floor(x + 0.5);
  },

  // Normalize an angle to [-pi, pi]
  normalize_angle(angle: number): number {
    while (angle > Math.PI) angle -= 2 * Math.PI;
    while (angle < -Math.PI) angle += 2 * Math.PI;
    return angle;
  },

  // Convert degrees to radians
  deg_to_rad(degrees: number): number {
    return (degrees * Math.PI) / 180;
  },

  // Convert radians to degrees
  rad_to_deg(radians: number): number {
    return (radians * 180) / Math.PI;
  },

  // Smooth damp (for smooth camera following, etc.) → [output, velocity]
  smooth_damp(current: number, target: number, velocity: number, smooth_time: number, dt: number): [number, number] {
    const omega = 2 / smooth_time;
    const x = omega * dt;
    const exp_factor = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x);
    const change = current - target;
    const temp = (velocity + omega * change) * dt;
    velocity = (velocity - omega * temp) * exp_factor;
    const output = target + (change + temp) * exp_factor;
    return [output, velocity];
  },

  // Format time as MM:SS.ms
  format_time(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds - Math.floor(seconds / 60) * 60;
    return `${String(mins).padStart(2, "0")}:${secs.toFixed(2).padStart(5, "0")}`;
  },

  // Deep copy a value
  deep_copy<T>(orig: T): T {
    if (orig === null || typeof orig !== "object") return orig;
    if (Array.isArray(orig)) return orig.map((v) => Utils.deep_copy(v)) as T;
    const copy: any = {};
    for (const k of Object.keys(orig)) copy[k] = Utils.deep_copy((orig as any)[k]);
    return copy;
  },

  // Serialize a value to a string (JSON on the web)
  serialize(tbl: unknown): string {
    return JSON.stringify(tbl);
  },

  // Deserialize a string back to a value
  deserialize<T = any>(str: string | null | undefined): T | null {
    if (!str) return null;
    try {
      return JSON.parse(str) as T;
    } catch (err) {
      console.warn("Deserialization error: " + String(err));
      return null;
    }
  },
};

export default Utils;
