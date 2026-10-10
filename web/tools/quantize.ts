// npx tsx tools/quantize.ts <in.png> <out.png> [options]
import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { PNG } from "pngjs";
import { PALETTE, hex_to_rgb } from "../src/gfx/palette";

export interface PixelImage { width: number; height: number; data: ArrayLike<number> }
export interface KeyImage { width: number; height: number; keys: string[] }
export interface Rect { x: number; y: number; w: number; h: number }

function positive_integer(value: number): boolean {
  return Number.isSafeInteger(value) && value > 0;
}

function validate_image(image: PixelImage | KeyImage): void {
  if (!positive_integer(image.width) || !positive_integer(image.height)) throw new Error("Invalid image size");
  const length = "data" in image ? image.data.length / 4 : image.keys.length;
  if (length !== image.width * image.height) throw new Error("Image buffer size mismatch");
}

/** Exact overlap-area box filter, with RGB weighted by source alpha. */
export function box_downsample(source: PixelImage, width: number, height: number): PixelImage {
  validate_image(source);
  if (!positive_integer(width) || !positive_integer(height)) throw new Error("Invalid output size");
  const data = new Float64Array(width * height * 4);
  const sx = source.width / width, sy = source.height / height;
  for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
    const left = x * sx, right = (x + 1) * sx;
    const top = y * sy, bottom = (y + 1) * sy;
    let alpha = 0, r = 0, g = 0, b = 0;
    for (let iy = Math.floor(top); iy < Math.min(source.height, Math.ceil(bottom)); iy++) {
      for (let ix = Math.floor(left); ix < Math.min(source.width, Math.ceil(right)); ix++) {
        const area = (Math.min(right, ix + 1) - Math.max(left, ix)) *
          (Math.min(bottom, iy + 1) - Math.max(top, iy));
        const i = (iy * source.width + ix) * 4;
        const weight = area * source.data[i + 3];
        alpha += weight;
        r += weight * source.data[i]; g += weight * source.data[i + 1]; b += weight * source.data[i + 2];
      }
    }
    const i = (y * width + x) * 4;
    if (alpha > 0) { data[i] = r / alpha; data[i + 1] = g / alpha; data[i + 2] = b / alpha; }
    data[i + 3] = alpha / (sx * sy);
  }
  return { width, height, data };
}

function lab(r: number, g: number, b: number): number[] {
  const linear = (v: number) => {
    v = Math.max(0, Math.min(255, v)) / 255;
    return v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
  };
  r = linear(r); g = linear(g); b = linear(b);
  const f = (v: number) => v > (6 / 29) ** 3 ? Math.cbrt(v) : v / (3 * (6 / 29) ** 2) + 4 / 29;
  const x = f((0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047);
  const y = f(0.2126729 * r + 0.7151522 * g + 0.0721750 * b);
  const z = f((0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883);
  return [116 * y - 16, 500 * (x - y), 200 * (y - z)];
}

const BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]];

/** Choose minimum deltaE76 (squared distance has the same minimum). */
export function quantize_pixels(source: PixelImage, options: { palette?: string; dither?: number } = {}): KeyImage {
  validate_image(source);
  const dither = options.dither ?? 0;
  if (!Number.isFinite(dither) || dither < 0 || dither > 1) throw new Error("Dither must be in 0..1");
  const candidates = [...new Set(options.palette ?? Object.keys(PALETTE).join(""))];
  if (!candidates.length || candidates.some(key => !Object.hasOwn(PALETTE, key))) throw new Error("Invalid palette keys");
  const colors = candidates.map(key => lab(...hex_to_rgb(PALETTE[key])));
  const keys = new Array<string>(source.width * source.height);
  for (let y = 0; y < source.height; y++) for (let x = 0; x < source.width; x++) {
    const pixel = y * source.width + x, i = pixel * 4;
    if (source.data[i + 3] < 128) { keys[pixel] = "."; continue; }
    const offset = (BAYER[y % 4][x % 4] / 16 - 0.5) * dither * 48;
    const color = lab(source.data[i] + offset, source.data[i + 1] + offset, source.data[i + 2] + offset);
    let best = 0, distance = Infinity;
    colors.forEach((candidate, index) => {
      const d = candidate.reduce((sum, v, channel) => sum + (v - color[channel]) ** 2, 0);
      if (d < distance) { distance = d; best = index; }
    });
    keys[pixel] = candidates[best];
  }
  return { width: source.width, height: source.height, keys };
}

/** Each pass reads the previous pass, so traversal order cannot change the result. */
export function clean_isolated(image: KeyImage, passes = 0): KeyImage {
  validate_image(image);
  if (!Number.isSafeInteger(passes) || passes < 0) throw new Error("Clean passes must be a nonnegative integer");
  let keys = image.keys.slice();
  for (let pass = 0; pass < passes; pass++) {
    const next = keys.slice();
    for (let y = 0; y < image.height; y++) for (let x = 0; x < image.width; x++) {
      const i = y * image.width + x, counts = new Map<string, number>();
      for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
        if ((!dx && !dy) || x + dx < 0 || x + dx >= image.width || y + dy < 0 || y + dy >= image.height) continue;
        const key = keys[(y + dy) * image.width + x + dx];
        counts.set(key, (counts.get(key) ?? 0) + 1);
      }
      if (!counts.has(keys[i])) for (const [key, count] of counts) if (count >= 6) next[i] = key;
    }
    keys = next;
  }
  return { ...image, keys };
}

/** Skip all requested erase regions when finding a left-hand source; absent sources become transparent. */
export function erase_rects(image: KeyImage, rects: readonly Rect[]): KeyImage {
  validate_image(image);
  const erased = new Uint8Array(image.keys.length), keys = image.keys.slice();
  for (const rect of rects) {
    validate_rect(rect);
    for (let y = Math.max(0, rect.y); y < Math.min(image.height, rect.y + rect.h); y++) {
      for (let x = Math.max(0, rect.x); x < Math.min(image.width, rect.x + rect.w); x++) erased[y * image.width + x] = 1;
    }
  }
  for (let y = 0; y < image.height; y++) {
    let left = ".";
    for (let x = 0; x < image.width; x++) {
      const i = y * image.width + x;
      if (erased[i]) keys[i] = left;
      else left = image.keys[i];
    }
  }
  return { ...image, keys };
}

function validate_rect(rect: Rect): void {
  if (!Number.isSafeInteger(rect.x) || !Number.isSafeInteger(rect.y) || !positive_integer(rect.w) || !positive_integer(rect.h)) {
    throw new Error("Rect must be x,y,w,h integers with positive width and height");
  }
}

function parse_rect(value: string): Rect {
  const parts = value.split(",").map(Number);
  if (parts.length !== 4 || value.split(",").some(part => !part.trim())) throw new Error("Expected x,y,w,h");
  const [x, y, w, h] = parts, rect = { x, y, w, h };
  validate_rect(rect);
  return rect;
}

function main(args: string[]): void {
  const [input, output, ...flags] = args;
  if (!input || !output || input.startsWith("--") || output.startsWith("--")) {
    throw new Error("Usage: npx tsx tools/quantize.ts <in.png> <out.png> [--crop x,y,w,h] [--size WxH] [--palette KEYS] [--dither N] [--clean K] [--erase x,y,w,h] [--rows out.ts --name NAME --anchor ox,oy]");
  }
  let crop: Rect | undefined, size: number[] | undefined, palette: string | undefined;
  let dither = 0, clean = 0, rows_file: string | undefined, name = "quantized_sprite", anchor = [0, 0];
  const rects: Rect[] = [];
  for (let i = 0; i < flags.length; i += 2) {
    const flag = flags[i], value = flags[i + 1];
    if (value === undefined || value.startsWith("--")) throw new Error(`Missing value for ${flag}`);
    switch (flag) {
      case "--crop": crop = parse_rect(value); break;
      case "--size":
        if (!/^\d+x\d+$/i.test(value)) throw new Error("Size must be WxH");
        size = value.toLowerCase().split("x").map(Number); break;
      case "--palette": palette = value; break;
      case "--dither": dither = Number(value); break;
      case "--clean": clean = Number(value); break;
      case "--erase": rects.push(parse_rect(value)); break;
      case "--rows": rows_file = value; break;
      case "--name":
        if (!/^[A-Za-z_$][\w$]*$/.test(value)) throw new Error("Name must be a TypeScript identifier");
        name = value; break;
      case "--anchor":
        if (!/^-?\d+,-?\d+$/.test(value)) throw new Error("Anchor must be ox,oy integers");
        anchor = value.split(",").map(Number);
        if (!anchor.every(Number.isSafeInteger)) throw new Error("Invalid anchor");
        break;
      default: throw new Error(`Unknown option ${flag}`);
    }
  }
  let source: PixelImage = PNG.sync.read(readFileSync(input));
  if (crop) {
    if (crop.x < 0 || crop.y < 0 || crop.x + crop.w > source.width || crop.y + crop.h > source.height) throw new Error("Crop is outside source image");
    const data = new Uint8Array(crop.w * crop.h * 4);
    for (let y = 0; y < crop.h; y++) for (let x = 0; x < crop.w; x++) {
      for (let channel = 0; channel < 4; channel++) data[(y * crop.w + x) * 4 + channel] = source.data[((y + crop.y) * source.width + x + crop.x) * 4 + channel];
    }
    source = { width: crop.w, height: crop.h, data };
  }
  if (size) source = box_downsample(source, size[0], size[1]);
  const image = erase_rects(clean_isolated(quantize_pixels(source, { palette, dither }), clean), rects);
  const png = new PNG({ width: image.width, height: image.height });
  const counts = new Map<string, number>();
  image.keys.forEach((key, pixel) => {
    const i = pixel * 4;
    if (key === ".") { png.data.fill(0, i, i + 4); return; }
    const rgb = hex_to_rgb(PALETTE[key]);
    png.data[i] = rgb[0]; png.data[i + 1] = rgb[1]; png.data[i + 2] = rgb[2]; png.data[i + 3] = 255;
    counts.set(key, (counts.get(key) ?? 0) + 1);
  });
  writeFileSync(output, PNG.sync.write(png));
  if (rows_file) {
    const rows = Array.from({ length: image.height }, (_, y) => image.keys.slice(y * image.width, (y + 1) * image.width).join(""));
    writeFileSync(rows_file, `import { sprite } from '../sprite_def';\n\nexport const ${name} = sprite(${anchor[0]}, ${anchor[1]}, [\n${rows.map(row => `  ${JSON.stringify(row)},`).join("\n")}\n]);\n`);
  }
  console.log(`${image.width}x${image.height}, ${counts.size} distinct keys used; top 10: ${[...counts].sort((a, b) => b[1] - a[1]).slice(0, 10).map(([key, count]) => `${key}: ${count}`).join(", ") || "none"}`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try { main(process.argv.slice(2)); }
  catch (error) { console.error(error instanceof Error ? error.message : String(error)); process.exitCode = 1; }
}
