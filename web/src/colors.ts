// src/colors.ts
// 80s "Windbreaker" color palette
// Every named color points at an entry in the locked pixel-art palette (gfx/palette.ts).

import love, { Color } from "./platform/love";
import { pal } from "./gfx/palette";

const Colors = {
  // Primary Palette
  HOT_PINK: pal("P") as Color, // #FF1493
  ELECTRIC_BLUE: pal("C") as Color, // #00FFFF
  BRIGHT_YELLOW: pal("Y") as Color, // #FFD700
  MINT_GREEN: pal("M") as Color, // #00FF7F
  SNOW_WHITE: pal("W") as Color, // #FFFAFA
  BLACK: pal("K") as Color, // #000000

  // Secondary Palette
  DEEP_PURPLE: pal("V") as Color, // #9400D3
  SUNSET_ORANGE: pal("O") as Color, // #FF4500
  SKY_BLUE: pal("A") as Color, // #87CEEB
  PINE_GREEN: pal("G") as Color, // #228B22
  ROCK_GRAY: pal("R") as Color, // #696969
  CABIN_BROWN: pal("N") as Color, // #8B4513

  // Darker variants for shadows/outlines
  DARK_PINE: pal("g") as Color, // Darker pine green
  DARK_BROWN: pal("n") as Color, // Darker cabin brown

  // UI Colors
  UI_PANEL_BG: pal("K", 0.8) as Color, // #000000CC
  UI_TEXT: pal("W") as Color, // White text

  // Gate States (assigned below)
  GATE_PENDING: [] as Color,
  GATE_PASSED: [] as Color,
  GATE_MISSED: [] as Color,

  // Slope/Snow colors
  SNOW: pal("S") as Color, // Main snow
  SNOW_SHADOW: pal("s") as Color, // Ski track shadows

  // Helper function to set the current draw color
  set(color: Color): void {
    love.graphics.setColor(color);
  },

  // Create a dimmed version of a color
  dim(color: Color, factor = 0.5): Color {
    return [color[0] * factor, color[1] * factor, color[2] * factor, color[3] ?? 1];
  },

  // Create a brighter version of a color
  bright(color: Color, factor = 1.3): Color {
    return [
      Math.min(1, color[0] * factor),
      Math.min(1, color[1] * factor),
      Math.min(1, color[2] * factor),
      color[3] ?? 1,
    ];
  },
};

Colors.GATE_PENDING = Colors.HOT_PINK;
Colors.GATE_PASSED = Colors.MINT_GREEN;
Colors.GATE_MISSED = Colors.ROCK_GRAY;

export default Colors;
