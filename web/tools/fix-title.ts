// tools/fix-title.ts
// Cleans the quantized 360x480 title screen: removes the AI-tool watermark sparkle at the
// bottom right. Run via `npm run title` (see package.json), which quantizes the original art first.
//   npx tsx tools/fix-title.ts <quantized.png> <out.png>

import { readFileSync, writeFileSync } from "node:fs";
import { PNG } from "pngjs";
const img = PNG.sync.read(readFileSync(process.argv[2]));
const set = (x: number, y: number, r: number, g: number, b: number) => { const i = (y * img.width + x) * 4; img.data[i] = r; img.data[i + 1] = g; img.data[i + 2] = b; img.data[i + 3] = 255; };
const get = (x: number, y: number) => { const i = (y * img.width + x) * 4; return [img.data[i], img.data[i + 1], img.data[i + 2]] as const; };
// Watermark sparkle sits on flat electric-blue sky: fill it
for (let y = 444; y <= 470; y++) for (let x = 333; x <= 350; x++) set(x, y, 0, 255, 255);
// Its left tip overlaps the gate pole: copy the pole rows from just above
for (let y = 452; y <= 462; y++) for (let x = 328; x <= 332; x++) { const [r, g, b] = get(x, 450); set(x, y, r, g, b); }
writeFileSync(process.argv[3], PNG.sync.write(img));
