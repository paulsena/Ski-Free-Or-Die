import { describe, expect, it } from "vitest";
import { box_downsample, quantize_pixels, clean_isolated, erase_rects, type PixelImage } from "../tools/quantize";

function grayscale(width: number, height: number, values: number[]): PixelImage {
  return { width, height, data: Uint8Array.from(values.flatMap(value => [value, value, value, 255])) };
}

describe("palette quantization", () => {
  it("averages exact 2x2 blocks from 4x4 to 2x2", () => {
    const result = box_downsample(grayscale(4, 4, [0, 4, 20, 24, 8, 12, 28, 32, 40, 44, 60, 64, 48, 52, 68, 72]), 2, 2);
    expect(Array.from(result.data)).toEqual([6, 6, 6, 255, 26, 26, 26, 255, 46, 46, 46, 255, 66, 66, 66, 255]);
  });

  it("weights partial source pixels from 3x3 to 2x2", () => {
    const result = box_downsample(grayscale(3, 3, [0, 90, 0, 90, 180, 0, 0, 0, 0]), 2, 2);
    // Top-left weights: 1, 1/2, 1/2, 1/4; total area 9/4.
    expect(result.data[0]).toBeCloseTo(60, 10);
    expect(result.data[3]).toBeCloseTo(255, 10);
  });

  it("weights RGB by alpha and retains average coverage", () => {
    const result = box_downsample({ width: 2, height: 1, data: [255, 0, 0, 255, 0, 0, 255, 0] }, 1, 1);
    expect(Array.from(result.data)).toEqual([255, 0, 0, 127.5]);
    expect(quantize_pixels(result).keys).toEqual(["."]);
  });

  it("maps hot pink to P and black to K", () => {
    expect(quantize_pixels({ width: 2, height: 1, data: [255, 20, 147, 255, 0, 0, 0, 255] }).keys).toEqual(["P", "K"]);
  });

  it("respects the alpha threshold and palette restriction", () => {
    expect(quantize_pixels({ width: 3, height: 1, data: [0, 0, 0, 127, 0, 0, 0, 128, 255, 20, 147, 255] }, { palette: "K" }).keys).toEqual([".", "K", "K"]);
  });

  it("removes a lone pixel but keeps a 2x1 pair", () => {
    const keys = Array<string>(25).fill("K");
    keys[12] = "P";
    expect(clean_isolated({ width: 5, height: 5, keys }, 1).keys).toEqual(Array(25).fill("K"));
    keys[13] = "P";
    expect(clean_isolated({ width: 5, height: 5, keys }, 2).keys).toEqual(keys);
  });

  it("fills erased rectangles from each row's left neighbour", () => {
    const image = { width: 4, height: 2, keys: [..."KPYW", ..."MPYC"] };
    expect(erase_rects(image, [{ x: 1, y: 0, w: 2, h: 2 }]).keys).toEqual([..."KKKW", ..."MMMC"]);
    expect(image.keys).toEqual([..."KPYW", ..."MPYC"]);
  });

  it("skips overlapping erase regions and handles the left edge", () => {
    const image = { width: 5, height: 1, keys: [..."KPYWC"] };
    expect(erase_rects(image, [{ x: 2, y: 0, w: 2, h: 1 }, { x: 1, y: 0, w: 2, h: 1 }]).keys).toEqual([..."KKKKC"]);
    expect(erase_rects(image, [{ x: 0, y: 0, w: 2, h: 1 }]).keys).toEqual([..."..YWC"]);
  });
});
