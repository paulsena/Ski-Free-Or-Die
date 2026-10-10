// src/gfx/palette.ts
// Locked "80s Windbreaker" pixel-art palette.
// Every sprite pixel is one of these keys; "." is transparent.
// colors.ts maps its named colors onto these entries so the UI stays on-palette too.

export type PaletteKey = string;

// Single-character key -> hex color
export const PALETTE: Record<PaletteKey, string> = {
  // Outline
  K: "#000000", // black outline / ink

  // 80s neons
  P: "#ff1493", // hot pink
  p: "#a80d62", // pink shadow
  l: "#ff6ec7", // pink highlight
  C: "#00ffff", // electric blue
  c: "#0090b8", // electric blue shadow
  B: "#2f4fd8", // royal blue
  Y: "#ffd700", // bright yellow
  y: "#c27c00", // yellow shadow
  M: "#00ff7f", // mint green
  O: "#ff4500", // sunset orange
  V: "#9400d3", // deep purple

  // Snow ramp (white -> pale blue shadow -> blue-gray)
  W: "#fffafa", // snow white (highlights, yeti fur)
  S: "#f2f7ff", // snow (slope ground)
  s: "#d6e0ee", // snow shadow
  b: "#9aa8c8", // blue-gray (deep shadow, yeti fur shade)
  A: "#87ceeb", // sky blue

  // Night sky (UI backgrounds, title art)
  D: "#14132e", // night navy
  d: "#221f4c", // dusk indigo

  // Pine ramp
  g: "#0f4d1f", // dark pine
  G: "#228b22", // pine green
  j: "#5fcf4f", // light pine

  // Wood ramp
  n: "#592e0d", // dark brown
  N: "#8b4513", // cabin brown
  w: "#c0783a", // light wood

  // Rock ramp
  r: "#3e3e4a", // dark rock
  R: "#696969", // rock gray
  L: "#9a9aa8", // light rock

  // Skin
  F: "#ffd9b3", // skin
  f: "#d99a73", // skin shadow

  // Yeti eyes / mouth
  E: "#ff2a2a", // glowing red
  e: "#5a0000", // dark red (mouth)
};

export const TRANSPARENT = ".";

/** Parse "#rrggbb" into [r, g, b] bytes. */
export function hex_to_rgb(hex: string): [number, number, number] {
  const v = parseInt(hex.slice(1), 16);
  return [(v >> 16) & 255, (v >> 8) & 255, v & 255];
}

/** Palette entry as a LÖVE-style color [r, g, b, a] in 0..1. */
export function pal(key: PaletteKey, alpha = 1): number[] {
  const hex = PALETTE[key];
  if (!hex) throw new Error(`Unknown palette key '${key}'`);
  const [r, g, b] = hex_to_rgb(hex);
  return [r / 255, g / 255, b / 255, alpha];
}

/** Nearest palette key to an RGB color (squared distance, weighted for perceived brightness). */
export function nearest_key(r: number, g: number, b: number): PaletteKey {
  let best = "K";
  let best_d = Infinity;
  for (const key in PALETTE) {
    const [pr, pg, pb] = hex_to_rgb(PALETTE[key]);
    const d = 2 * (pr - r) ** 2 + 4 * (pg - g) ** 2 + 3 * (pb - b) ** 2;
    if (d < best_d) {
      best_d = d;
      best = key;
    }
  }
  return best;
}
