// src/gfx/sprites/ui.ts
// Small UI icons for the menu, name entry and high score screens.

import { sprite, Swap } from "../sprite_def";

const UI_SPRITES = {
  // Name-entry character selector arrows; anchor = arrow tip
  ui_arrow_up: sprite(5, 0, [
    ".....K.....",
    "....KCK....",
    "...KCCcK...",
    "..KCCCCcK..",
    ".KCCCCCCcK.",
    "KCCCCCCCCcK",
    "KKKKKKKKKKK",
  ]),
  ui_arrow_down: sprite(5, 6, [
    "KKKKKKKKKKK",
    "KCCCCCCCCcK",
    ".KCCCCCCcK.",
    "..KCCCCcK..",
    "...KCCcK...",
    "....KcK....",
    ".....K.....",
  ]),
  // Rank medal (gold); silver/bronze are palette swaps. Anchor = center
  ui_medal: sprite(6, 6, [
    "....KKKKK....",
    "..KKYYYYYKK..",
    ".KYWYYYYYYyK.",
    ".KYWYYYYYYyK.",
    "KYYYYYYYYYYyK",
    "KYYYYYYYYYYyK",
    "KYYYYYYYYYYyK",
    "KYYYYYYYYYYyK",
    "KYYYYYYYYYyyK",
    ".KYYYYYYYyyK.",
    ".KyYYYYYyyyK.",
    "..KKyyyyyKK..",
    "....KKKKK....",
  ]),
  // New-high-score trophy; anchor = top-left (matches the old polygon origin)
  ui_trophy: sprite(0, 0, [
    "KKKKKKKKKK",
    "KYWYYYYyyK",
    "KYYYYYYYyK",
    ".KYYYYYyK.",
    "..KYYYyK..",
    "...KYyK...",
    "...KYyK...",
    "..KYYYyK..",
    ".KKKKKKKK.",
  ]),
};

export const MEDAL_SWAPS: (Swap | undefined)[] = [
  undefined, // gold
  { Y: "L", y: "R", W: "W" }, // silver
  { Y: "O", y: "n", W: "w" }, // bronze
];

export default UI_SPRITES;
