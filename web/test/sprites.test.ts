import { describe, it, expect } from "vitest";
import { PALETTE } from "../src/gfx/palette";
import { mirror, recolor, type Sprite } from "../src/gfx/sprite_def";
import SPRITES from "../src/gfx/sprites";
import { SPRITE_VARIANTS } from "../src/gfx/sprites/variants";

function assert_sprite(s: Sprite): void {
  expect(s.w).toBeGreaterThan(0);
  expect(s.rows.length).toBe(s.h);
  expect(s.ox).toBeGreaterThanOrEqual(0);
  expect(s.ox).toBeLessThan(s.w);
  expect(s.oy).toBeGreaterThanOrEqual(0);
  expect(s.oy).toBeLessThan(s.h);
  for (const row of s.rows) {
    expect(row.length).toBe(s.w);
    for (const key of row) {
      expect(key === "." || Object.hasOwn(PALETTE, key)).toBe(true);
    }
  }
}

describe("pixel-art palette", () => {
  for (const [key, hex] of Object.entries(PALETTE)) {
    it(`validates palette entry ${key}`, () => {
      expect(key.length).toBe(1);
      expect(hex).toMatch(/^#[0-9a-fA-F]{6}$/);
    });
  }
});

describe("sprite registry", () => {
  for (const [name, s] of Object.entries(SPRITES)) {
    it(`validates ${name}`, () => {
      assert_sprite(s);
    });

    it(`mirrors ${name} twice without changing it`, () => {
      expect(mirror(mirror(s))).toEqual(s);
    });
  }

  for (const [name, variants] of Object.entries(SPRITE_VARIANTS)) {
    for (const [variant_name, swap] of Object.entries(variants)) {
      it(`validates ${name}/${variant_name}`, () => {
        expect(Object.hasOwn(SPRITES, name)).toBe(true);
        for (const target of Object.values(swap)) {
          expect(Object.hasOwn(PALETTE, target)).toBe(true);
        }
        const s = recolor(SPRITES[name], swap);
        assert_sprite(s);
        expect(mirror(mirror(s))).toEqual(s);
      });
    }
  }
});
