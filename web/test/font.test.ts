import { describe, it, expect, vi } from "vitest";
import { GLYPHS, GLYPH_W, GLYPH_H, get_glyph, measure, draw_text } from "../src/gfx/font";
import love, { Font } from "../src/platform/love";

function make_context(transform = { a: 1, b: 0, c: 0, d: 1, e: 0, f: 0 }) {
  return {
    getTransform: () => transform,
    save: vi.fn(), restore: vi.fn(), setTransform: vi.fn(),
    fillRect: vi.fn(), translate: vi.fn(), rotate: vi.fn(), scale: vi.fn(),
    fillStyle: "#abc", strokeStyle: "", lineWidth: 1,
  };
}

describe("bitmap font", () => {
  it("covers printable ASCII with valid 5x7 glyphs", () => {
    for (let code = 32; code <= 126; code++) {
      const ch = String.fromCharCode(code);
      expect(Object.hasOwn(GLYPHS, ch)).toBe(true);
      expect(get_glyph(ch)).toHaveLength(GLYPH_H);
    }
    for (const glyph of [...Object.values(GLYPHS), ...["I", "2", "3", "6", "9"].map((ch) => get_glyph(ch, "name_entry"))]) {
      expect(glyph).toHaveLength(GLYPH_H);
      for (const row of glyph) {
        expect(row).toHaveLength(GLYPH_W);
        expect(row).toMatch(/^[#.]{5}$/);
      }
    }
  });

  it("measures advances without trailing spacing", () => {
    expect(measure("", 1)).toBe(0);
    expect(measure("AB", 1)).toBe(11);
    expect(measure("AB", 2)).toBe(22);
    expect(measure("A☃B", 1)).toBe(17);
  });

  it("measures LÖVE fonts without a DOM", () => {
    expect(new Font(12).getWidth("AB")).toBe(measure("AB", 1));
    expect(new Font(16).getWidth("AB")).toBe(measure("AB", 2));
    expect(new Font(13).scale).toBe(1);
    expect(new Font(14).scale).toBe(2);
    expect(new Font(12).getHeight()).toBe(9);
    expect(new Font(16).getHeight()).toBe(18);
    expect(new Font(12).getWidth("A\nAB")).toBe(11);
  });

  it("preserves the original screen-specific shapes", () => {
    expect(get_glyph("I")[0]).toBe(".###.");
    expect(get_glyph("I", "name_entry")[0]).toBe("#####");
    expect(get_glyph("m")[2]).toBe("##.##");
    expect(get_glyph("d")[3]).toBe("#..##");
  });

  it("snaps fractional transforms and merges horizontal pixel runs", () => {
    const ctx = make_context({ a: 1.5, b: 0, c: 0, d: 2, e: 0.25, f: 0.75 });
    draw_text(ctx as unknown as CanvasRenderingContext2D, "AB", 1, 1, 1);
    expect(ctx.setTransform).toHaveBeenCalledWith(1, 0, 0, 1, 0, 0);
    expect(ctx.fillRect.mock.calls[0]).toEqual([4, 3, 6, 2]);
    expect(ctx.fillRect.mock.calls).toContainEqual([14, 3, 8, 2]);
    for (const rect of ctx.fillRect.mock.calls) expect(rect.every(Number.isInteger)).toBe(true);
    expect(ctx.fillStyle).toBe("#abc");
    expect(ctx.restore).toHaveBeenCalledOnce();
  });

  it("keeps rotated text under the existing transform", () => {
    const ctx = make_context({ a: 0, b: 1, c: -1, d: 0, e: 0.5, f: 0.5 });
    draw_text(ctx as unknown as CanvasRenderingContext2D, "A", 0, 0, 2);
    expect(ctx.setTransform).not.toHaveBeenCalled();
    expect(ctx.fillRect.mock.calls[0]).toEqual([2, 0, 6, 2]);
  });

  it("renders unknown characters as blank advances", () => {
    const ctx = make_context();
    draw_text(ctx as unknown as CanvasRenderingContext2D, "☃A", 0, 0, 1);
    expect(ctx.fillRect.mock.calls[0]).toEqual([7, 0, 3, 1]);
    expect(get_glyph("☃")).toEqual(get_glyph(" "));
  });

  it("prints newlines and aligns wrapped lines with the current color", () => {
    const ctx = make_context();
    love.graphics._init({ getContext: () => ctx } as unknown as HTMLCanvasElement);
    love.graphics.setFont(love.graphics.newFont(16));
    expect(love.graphics.getFont().scale).toBe(2);
    love.graphics.setColor(1, 0, 0, 0.5);
    love.graphics.print("A\nB", 10, 20, 0.5, 2, 3);
    expect(ctx.translate).toHaveBeenCalledWith(10, 20);
    expect(ctx.rotate).toHaveBeenCalledWith(0.5);
    expect(ctx.scale).toHaveBeenCalledWith(2, 3);
    expect(ctx.fillStyle).toBe("rgba(255,0,0,0.5)");
    expect(ctx.fillRect.mock.calls).toContainEqual([0, 18, 8, 2]);
    ctx.fillRect.mockClear();
    love.graphics.printf("A B", 0, 0, 12, "right");
    expect(ctx.fillRect.mock.calls[0]).toEqual([4, 0, 6, 2]);
    expect(ctx.fillRect.mock.calls).toContainEqual([2, 18, 8, 2]);
  });
});
