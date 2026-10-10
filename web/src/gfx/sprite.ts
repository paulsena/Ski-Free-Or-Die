// src/gfx/sprite.ts
// Palette-indexed pixel sprites: format, baking to offscreen canvases, and crisp drawing.
//
// A sprite is a grid of palette keys (see gfx/palette.ts). `ox, oy` is the anchor: the pixel
// that lands on the entity's (x, y). Sprites are baked once per (palette swap, flip) to a canvas
// and blitted at integer device coordinates, so they stay crisp under the fractional camera.

import love from "../platform/love";
import { PALETTE, TRANSPARENT, PaletteKey } from "./palette";
import { Sprite, Swap, mirror, recolor, swap_id } from "./sprite_def";
import SPRITES from "./sprites";

//------------------------------------------------------------------------------
// Baking
//------------------------------------------------------------------------------

const baked = new Map<string, HTMLCanvasElement>();

/** Draw a sprite once to an offscreen canvas (one fillRect per horizontal run of a color). */
export function bake(s: Sprite): HTMLCanvasElement {
  const el = document.createElement("canvas");
  el.width = Math.max(1, s.w);
  el.height = Math.max(1, s.h);
  const ctx = el.getContext("2d")!;
  for (let y = 0; y < s.h; y++) {
    const row = s.rows[y];
    let x = 0;
    while (x < s.w) {
      const k = row[x];
      let run = 1;
      while (x + run < s.w && row[x + run] === k) run++;
      if (k !== TRANSPARENT) {
        ctx.fillStyle = PALETTE[k];
        ctx.fillRect(x, y, run, 1);
      }
      x += run;
    }
  }
  return el;
}

function get_baked(name: string, flip: boolean, swap?: Swap): [HTMLCanvasElement, Sprite] {
  const base = SPRITES[name];
  if (!base) throw new Error(`Unknown sprite '${name}'`);
  const s = flip ? mirror(base) : base;
  const id = `${name}|${flip ? 1 : 0}|${swap_id(swap)}`;
  let el = baked.get(id);
  if (!el) {
    el = bake(recolor(s, swap));
    baked.set(id, el);
  }
  return [el, s];
}

/** Bake every registered sprite up front (avoids first-use hitches). */
export function bake_all(): void {
  for (const name in SPRITES) get_baked(name, false);
}

//------------------------------------------------------------------------------
// Drawing
//------------------------------------------------------------------------------

/** Current transform applied to (x, y), rounded to a whole device pixel. */
function device_point(ctx: CanvasRenderingContext2D, x: number, y: number): [number, number] {
  const m = ctx.getTransform();
  return [Math.round(m.a * x + m.c * y + m.e), Math.round(m.b * x + m.d * y + m.f)];
}

/**
 * Draw a registered sprite with its anchor at (x, y) in the current coordinate space.
 * Only the translation of the current transform is used, so the pixels are never
 * scaled, rotated or smoothed.
 */
export function draw_sprite(name: string, x: number, y: number, flip_x = false, swap?: Swap, alpha = 1): void {
  const ctx = love.graphics._ctx();
  const [el, s] = get_baked(name, flip_x, swap);
  const [dx, dy] = device_point(ctx, x, y);
  ctx.save();
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.globalAlpha = alpha;
  ctx.drawImage(el, dx - s.ox, dy - s.oy);
  ctx.restore();
}

/** Fill an axis-aligned block of one palette color, snapped to whole device pixels. */
export function fill_px(key: PaletteKey, x: number, y: number, w: number, h: number, alpha = 1): void {
  if (w <= 0 || h <= 0) return;
  const ctx = love.graphics._ctx();
  const [x0, y0] = device_point(ctx, x, y);
  const [x1, y1] = device_point(ctx, x + w, y + h);
  ctx.save();
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.globalAlpha = alpha;
  ctx.fillStyle = PALETTE[key];
  ctx.fillRect(Math.min(x0, x1), Math.min(y0, y1), Math.max(1, Math.abs(x1 - x0)), Math.max(1, Math.abs(y1 - y0)));
  ctx.restore();
}

export { SPRITES };
export type { Sprite, Swap };
