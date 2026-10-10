// src/gfx/sprite_def.ts
// Sprite format (pure data helpers, no DOM) shared by the game, the tests and tools/.

import { PaletteKey } from "./palette";

export interface Sprite {
  w: number;
  h: number;
  ox: number; // anchor x (column)
  oy: number; // anchor y (row)
  rows: string[]; // h strings of w palette keys
}

/** Palette swap: source key -> replacement key, e.g. { P: "M" } recolors pink to mint. */
export type Swap = Record<PaletteKey, PaletteKey>;

/** Build a sprite from rows; w/h come from the grid. */
export function sprite(ox: number, oy: number, rows: string[]): Sprite {
  return { w: rows[0]?.length ?? 0, h: rows.length, ox, oy, rows };
}

/** Mirror a sprite horizontally (the anchor column mirrors too). */
export function mirror(s: Sprite): Sprite {
  return {
    w: s.w,
    h: s.h,
    ox: s.w - 1 - s.ox,
    oy: s.oy,
    rows: s.rows.map((r) => r.split("").reverse().join("")),
  };
}

/** Apply a palette swap to the rows of a sprite. */
export function recolor(s: Sprite, swap?: Swap): Sprite {
  if (!swap) return s;
  return { ...s, rows: s.rows.map((r) => r.replace(/./g, (k) => swap[k] ?? k)) };
}

export function swap_id(swap?: Swap): string {
  if (!swap) return "";
  return Object.keys(swap)
    .sort()
    .map((k) => k + swap[k])
    .join("");
}
