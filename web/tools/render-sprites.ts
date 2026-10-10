// tools/render-sprites.ts
// Renders every registered sprite to a labelled PNG contact sheet for review.
//   npx tsx tools/render-sprites.ts [filter]   ->  tools/out/contact-sheet.png
// Each sprite is shown at 1x (on snow) and 4x (on snow, with the anchor pixel marked),
// plus any palette-swap variants listed in VARIANTS.

import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { PNG } from "pngjs";
import { PALETTE, TRANSPARENT, hex_to_rgb } from "../src/gfx/palette";
import { Sprite, recolor } from "../src/gfx/sprite_def";
import SPRITES from "../src/gfx/sprites";
import { SPRITE_VARIANTS } from "../src/gfx/sprites/variants";
import { get_glyph, GLYPH_H, ADVANCE } from "../src/gfx/font";

const OUT = join(dirname(fileURLToPath(import.meta.url)), "out");
const ZOOM = Number(process.env.ZOOM ?? 4);
const PAD = 6;
const BG = hex_to_rgb(PALETTE.S);
const SHEET_BG: [number, number, number] = [40, 36, 56];
const MAX_W = 1400;

type RGB = [number, number, number];

const filter = process.argv[2];
const entries: [string, Sprite][] = [];
for (const name in SPRITES) {
  if (filter && !name.includes(filter)) continue;
  entries.push([name, SPRITES[name]]);
  for (const [vname, swap] of Object.entries(SPRITE_VARIANTS[name] ?? {})) {
    entries.push([`${name}:${vname}`, recolor(SPRITES[name], swap)]);
  }
}

// Layout: one cell per sprite = label, then 1x and 4x side by side
const LABEL_H = GLYPH_H + 4;
const cells = entries.map(([name, s]) => {
  const w = Math.max(name.length * ADVANCE, s.w + PAD + s.w * ZOOM + 2) + PAD * 2;
  const h = LABEL_H + s.h * ZOOM + 2 + PAD * 2;
  return { name, s, w, h, x: 0, y: 0 };
});
let cx = PAD, cy = PAD, row_h = 0, sheet_w = 0;
for (const c of cells) {
  if (cx + c.w > MAX_W && cx > PAD) { cx = PAD; cy += row_h + PAD; row_h = 0; }
  c.x = cx; c.y = cy;
  cx += c.w + PAD; row_h = Math.max(row_h, c.h); sheet_w = Math.max(sheet_w, cx);
}
const sheet_h = cy + row_h + PAD;

const png = new PNG({ width: Math.max(1, sheet_w), height: Math.max(1, sheet_h) });
function px(x: number, y: number, [r, g, b]: RGB): void {
  if (x < 0 || y < 0 || x >= png.width || y >= png.height) return;
  const i = (y * png.width + x) * 4;
  png.data[i] = r; png.data[i + 1] = g; png.data[i + 2] = b; png.data[i + 3] = 255;
}
function rect(x: number, y: number, w: number, h: number, c: RGB): void {
  for (let j = 0; j < h; j++) for (let i = 0; i < w; i++) px(x + i, y + j, c);
}
function text(s: string, x: number, y: number, c: RGB): void {
  for (const ch of s) {
    const g = get_glyph(ch);
    if (g) g.forEach((row: string, j: number) => [...row].forEach((k, i) => { if (k === "#") px(x + i, y + j, c); }));
    x += ADVANCE;
  }
}
function blit(s: Sprite, x: number, y: number, z: number): void {
  rect(x, y, s.w * z, s.h * z, BG);
  s.rows.forEach((row, j) => [...row].forEach((k, i) => {
    if (k !== TRANSPARENT) rect(x + i * z, y + j * z, z, z, hex_to_rgb(PALETTE[k]));
  }));
}

rect(0, 0, png.width, png.height, SHEET_BG);
for (const c of cells) {
  text(c.name, c.x, c.y, [255, 230, 120]);
  const y0 = c.y + LABEL_H;
  blit(c.s, c.x, y0, 1);
  const zx = c.x + c.s.w + PAD;
  rect(zx - 1, y0 - 1, c.s.w * ZOOM + 2, c.s.h * ZOOM + 2, [0, 0, 0]);
  blit(c.s, zx, y0, ZOOM);
  // anchor marker: magenta corners around the anchor pixel at 4x
  const ax = zx + c.s.ox * ZOOM, ay = y0 + c.s.oy * ZOOM;
  for (const [dx, dy] of [[0, 0], [ZOOM - 1, 0], [0, ZOOM - 1], [ZOOM - 1, ZOOM - 1]]) px(ax + dx, ay + dy, [255, 0, 255]);
}

mkdirSync(OUT, { recursive: true });
const file = join(OUT, filter ? `contact-sheet-${filter}.png` : "contact-sheet.png");
writeFileSync(file, PNG.sync.write(png));
console.log(`${entries.length} sprites -> ${file}`);
