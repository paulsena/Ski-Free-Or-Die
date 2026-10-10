import { describe, it, expect } from "vitest";
import { readFileSync } from "node:fs";
import { PNG } from "pngjs";
import { PALETTE } from "../src/gfx/palette";

describe("title screen", () => {
  it("is native 360x480 and uses only palette colors", () => {
    const img = PNG.sync.read(readFileSync(new URL("../public/images/title_screen.png", import.meta.url)));
    expect([img.width, img.height]).toEqual([360, 480]);
    const allowed = new Set(Object.values(PALETTE).map((h) => h.toLowerCase()));
    const off = new Set<string>();
    for (let i = 0; i < img.data.length; i += 4) {
      const hex = "#" + [0, 1, 2].map((k) => img.data[i + k].toString(16).padStart(2, "0")).join("");
      if (img.data[i + 3] === 255 && !allowed.has(hex)) off.add(hex);
    }
    expect([...off]).toEqual([]);
  });
});
