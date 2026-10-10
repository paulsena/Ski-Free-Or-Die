// src/gfx/sprites/variants.ts
// Palette-swap variants used in game, listed so the contact sheet shows them too.

import { Swap } from "../sprite_def";
import { GATE_SWAPS } from "./gate";
import { MEDAL_SWAPS } from "./ui";

// Cabin roofs: the base sprite has a pink roof (P/p); the blue variant swaps it.
export const CABIN_ROOF_BLUE: Swap = { P: "C", p: "c" };

export const SPRITE_VARIANTS: Record<string, Record<string, Swap>> = {
  cabin: { blue: CABIN_ROOF_BLUE },
  ui_medal: { silver: MEDAL_SWAPS[1]!, bronze: MEDAL_SWAPS[2]! },
  gate_pole: { passed: GATE_SWAPS.passed!, missed: GATE_SWAPS.missed!, flash: GATE_SWAPS.flash! },
};
