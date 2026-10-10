// src/gfx/sprites/gate.ts
// Slalom gate parts. Base color is hot pink (P/p/l); gate states are palette swaps
// (see GATE_SWAPS). The banner between poles is drawn with fill_px because gate width varies.

import { sprite, Swap } from "../sprite_def";

// Pole: anchor = pole center at the gate line (old pole spanned y-15..y+15, ball on top)
const pole_rows = [
  ".PPP..",
  "PlPPp.",
  "PlPPp.",
  ".ppp..",
];
for (let i = 0; i < 31; i++) pole_rows.push(".lPp..");
pole_rows.push(".sPpss", "..sss.");

const GATE_SPRITES = {
  gate_pole: sprite(2, 19, pole_rows),
  // Direction arrow above a pending gate; anchor = arrow tip
  gate_arrow: sprite(4, 5, [
    "yyyyyyyyy",
    "yYYYYYYYy",
    ".yYYYYYy.",
    "..yYYYy..",
    "...yYy...",
    "....y....",
  ]),
};

// Palette swaps for gate states (applied to pole + banner keys)
export const GATE_SWAPS: Record<string, Swap | undefined> = {
  pending: undefined,
  passed: { P: "M", p: "G", l: "W" },
  missed: { P: "R", p: "r", l: "L" },
  flash: { P: "W", p: "s", l: "W" },
};

export default GATE_SPRITES;
