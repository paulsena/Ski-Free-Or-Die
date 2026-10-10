// src/platform/love.ts
// Minimal LÖVE (love2d) API shim on top of Canvas 2D + WebAudio.
// Ported game code calls `love.graphics.*` etc. exactly like the Lua version,
// so module ports stay close to line-for-line translations.

import { draw_text, measure, GLYPH_H } from "../gfx/font";

export type Color = number[]; // [r, g, b, a?] in 0..1, same as LÖVE tables
export type DrawMode = "fill" | "line";

//------------------------------------------------------------------------------
// Drawables
//------------------------------------------------------------------------------

export class Image {
  el: HTMLImageElement;
  constructor(el: HTMLImageElement) { this.el = el; }
  getWidth(): number { return this.el.naturalWidth; }
  getHeight(): number { return this.el.naturalHeight; }
  getDimensions(): [number, number] { return [this.getWidth(), this.getHeight()]; }
  setFilter(_min?: string, _mag?: string): void { /* always nearest */ }
}

export class Canvas {
  el: HTMLCanvasElement;
  ctx: CanvasRenderingContext2D;
  constructor(w: number, h: number) {
    this.el = document.createElement("canvas");
    this.el.width = w;
    this.el.height = h;
    this.ctx = this.el.getContext("2d")!;
    this.ctx.imageSmoothingEnabled = false;
  }
  getWidth(): number { return this.el.width; }
  getHeight(): number { return this.el.height; }
  getDimensions(): [number, number] { return [this.el.width, this.el.height]; }
  setFilter(_min?: string, _mag?: string): void { /* always nearest */ }
}

export class Font {
  size: number;
  scale: number;
  constructor(size: number) {
    this.size = size;
    this.scale = size <= 13 ? 1 : Math.max(2, Math.round(size / 8));
  }
  getWidth(text: string): number {
    return Math.max(...String(text).split("\n").map((line) => measure(line, this.scale)));
  }
  getHeight(): number { return (GLYPH_H + 2) * this.scale; }
}

let _measure: CanvasRenderingContext2D | null = null;
function measureCtx(): CanvasRenderingContext2D {
  if (!_measure) _measure = document.createElement("canvas").getContext("2d")!;
  return _measure;
}

type Drawable = Image | Canvas;

//------------------------------------------------------------------------------
// Graphics state
//------------------------------------------------------------------------------

let screen: HTMLCanvasElement;
let screenCtx: CanvasRenderingContext2D;
let ctx: CanvasRenderingContext2D;
let color: Color = [1, 1, 1, 1];
let lineWidth = 1;
let font: Font;
const images = new Map<string, HTMLImageElement>();

function cssColor(c: Color): string {
  const r = Math.round(clamp01(c[0]) * 255);
  const g = Math.round(clamp01(c[1]) * 255);
  const b = Math.round(clamp01(c[2]) * 255);
  const a = c[3] === undefined ? 1 : clamp01(c[3]);
  return `rgba(${r},${g},${b},${a})`;
}

function clamp01(v: number): number {
  return v < 0 ? 0 : v > 1 ? 1 : v;
}

function applyStyle(): void {
  const css = cssColor(color);
  ctx.fillStyle = css;
  ctx.strokeStyle = css;
  ctx.lineWidth = lineWidth;
}

function finish(mode: DrawMode): void {
  applyStyle();
  if (mode === "fill") ctx.fill();
  else ctx.stroke();
}

function flatten(args: any[]): number[] {
  if (args.length === 1 && Array.isArray(args[0])) return args[0];
  return args as number[];
}

function wrapLines(text: string, limit: number, f: Font): string[] {
  const out: string[] = [];
  for (const para of String(text).split("\n")) {
    const words = para.split(" ");
    let line = "";
    for (const word of words) {
      const candidate = line === "" ? word : line + " " + word;
      if (line !== "" && f.getWidth(candidate) > limit) {
        out.push(line);
        line = word;
      } else {
        line = candidate;
      }
    }
    out.push(line);
  }
  return out;
}

export const graphics = {
  //--- setup (called by main.ts) ---
  _init(el: HTMLCanvasElement): void {
    screen = el;
    screenCtx = el.getContext("2d")!;
    screenCtx.imageSmoothingEnabled = false;
    ctx = screenCtx;
    font = new Font(12);
  },

  getWidth(): number { return screen.width; },
  getHeight(): number { return screen.height; },
  getDimensions(): [number, number] { return [screen.width, screen.height]; },

  setDefaultFilter(_min?: string, _mag?: string): void { /* nearest everywhere */ },

  //--- color / state ---
  setColor(r: number | Color, g?: number, b?: number, a?: number): void {
    if (Array.isArray(r)) color = [r[0], r[1], r[2], r[3] === undefined ? 1 : r[3]];
    else color = [r, g!, b!, a === undefined ? 1 : a];
  },
  getColor(): [number, number, number, number] {
    return [color[0], color[1], color[2], color[3] ?? 1];
  },
  setLineWidth(w: number): void { lineWidth = w; },
  getLineWidth(): number { return lineWidth; },
  setBlendMode(mode: string): void {
    ctx.globalCompositeOperation = mode === "add" ? "lighter" : mode === "multiply" ? "multiply" : "source-over";
  },

  clear(r?: number | Color, g?: number, b?: number, a?: number): void {
    const c: Color = Array.isArray(r) ? r : r === undefined ? [0, 0, 0, 0] : [r, g!, b!, a ?? 1];
    ctx.save();
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.globalCompositeOperation = "source-over";
    ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
    if ((c[3] ?? 1) > 0) {
      ctx.fillStyle = cssColor(c);
      ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height);
    }
    ctx.restore();
  },

  //--- transforms (push/pop only save the transform, like LÖVE's default) ---
  push(): void { ctx.save(); },
  pop(): void { ctx.restore(); },
  translate(x: number, y: number): void { ctx.translate(x, y); },
  rotate(angle: number): void { ctx.rotate(angle); },
  scale(sx: number, sy?: number): void { ctx.scale(sx, sy ?? sx); },
  origin(): void { ctx.setTransform(1, 0, 0, 1, 0, 0); },

  //--- primitives ---
  rectangle(mode: DrawMode, x: number, y: number, w: number, h: number, rx?: number, ry?: number): void {
    ctx.beginPath();
    if (rx && rx > 0) ctx.roundRect(x, y, w, h, Math.min(rx, ry ?? rx));
    else ctx.rect(x, y, w, h);
    finish(mode);
  },

  polygon(mode: DrawMode, ...args: any[]): void {
    const v = flatten(args);
    if (v.length < 6) return;
    ctx.beginPath();
    ctx.moveTo(v[0], v[1]);
    for (let i = 2; i < v.length; i += 2) ctx.lineTo(v[i], v[i + 1]);
    ctx.closePath();
    finish(mode);
  },

  line(...args: any[]): void {
    const v = flatten(args);
    if (v.length < 4) return;
    ctx.beginPath();
    ctx.moveTo(v[0], v[1]);
    for (let i = 2; i < v.length; i += 2) ctx.lineTo(v[i], v[i + 1]);
    applyStyle();
    ctx.stroke();
  },

  points(...args: any[]): void {
    const v = flatten(args);
    applyStyle();
    for (let i = 0; i < v.length; i += 2) ctx.fillRect(Math.floor(v[i]), Math.floor(v[i + 1]), 1, 1);
  },

  circle(mode: DrawMode, x: number, y: number, r: number): void {
    if (r <= 0) return;
    ctx.beginPath();
    ctx.arc(x, y, r, 0, Math.PI * 2);
    finish(mode);
  },

  ellipse(mode: DrawMode, x: number, y: number, rx: number, ry?: number): void {
    const ryv = ry ?? rx;
    if (rx <= 0 || ryv <= 0) return;
    ctx.beginPath();
    ctx.ellipse(x, y, rx, ryv, 0, 0, Math.PI * 2);
    finish(mode);
  },

  // arc(mode, x, y, r, a1, a2) or arc(mode, arctype, x, y, r, a1, a2)
  arc(mode: DrawMode, ...args: any[]): void {
    let arctype = "pie";
    if (typeof args[0] === "string") arctype = args.shift();
    const [x, y, r, a1, a2] = args as number[];
    ctx.beginPath();
    if (arctype === "pie") ctx.moveTo(x, y);
    ctx.arc(x, y, r, a1, a2, a2 < a1);
    if (arctype !== "open") ctx.closePath();
    finish(mode);
  },

  //--- text ---
  newFont(size?: number): Font { return new Font(size ?? 12); },
  setFont(f: Font): void { font = f; },
  getFont(): Font { return font; },

  print(text: any, x: number, y: number, r = 0, sx = 1, sy?: number): void {
    ctx.save();
    ctx.translate(x, y);
    if (r) ctx.rotate(r);
    if (sx !== 1 || (sy ?? sx) !== 1) ctx.scale(sx, sy ?? sx);
    applyStyle();
    const lh = font.getHeight();
    String(text).split("\n").forEach((ln, i) => draw_text(ctx, ln, 0, i * lh, font.scale));
    ctx.restore();
  },

  printf(text: any, x: number, y: number, limit: number, align: string = "left", r = 0, sx = 1, sy?: number): void {
    ctx.save();
    ctx.translate(x, y);
    if (r) ctx.rotate(r);
    if (sx !== 1 || (sy ?? sx) !== 1) ctx.scale(sx, sy ?? sx);
    applyStyle();
    const lh = font.getHeight();
    wrapLines(String(text), limit, font).forEach((ln, i) => {
      const w = font.getWidth(ln);
      let ox = 0;
      if (align === "center") ox = Math.floor((limit - w) / 2);
      else if (align === "right") ox = limit - w;
      draw_text(ctx, ln, ox, i * lh, font.scale);
    });
    ctx.restore();
  },

  //--- images & canvases ---
  newImage(path: string): Image {
    const el = images.get(path);
    if (!el) throw new Error(`love.graphics.newImage: '${path}' was not preloaded`);
    return new Image(el);
  },

  newCanvas(w?: number, h?: number): Canvas {
    return new Canvas(w ?? screen.width, h ?? screen.height);
  },

  setCanvas(c?: Canvas | null): void {
    ctx = c ? c.ctx : screenCtx;
  },

  draw(d: Drawable, x = 0, y = 0, r = 0, sx = 1, sy?: number, ox = 0, oy = 0): void {
    ctx.save();
    ctx.translate(x, y);
    if (r) ctx.rotate(r);
    ctx.scale(sx, sy ?? sx);
    ctx.globalAlpha = color[3] ?? 1;
    ctx.drawImage(d.el, -ox, -oy);
    ctx.restore();
  },

  // Raw context access for platform code
  _ctx(): CanvasRenderingContext2D { return ctx; },
};

/** Load images up front so newImage() can stay synchronous like LÖVE. */
export async function preloadImages(paths: string[]): Promise<void> {
  await Promise.all(
    paths.map(
      (p) =>
        new Promise<void>((resolve) => {
          const el = new window.Image();
          el.onload = () => { images.set(p, el); resolve(); };
          el.onerror = () => { console.warn(`Failed to load image ${p}`); resolve(); };
          el.src = import.meta.env.BASE_URL + p;
        }),
    ),
  );
}

//------------------------------------------------------------------------------
// Input
//------------------------------------------------------------------------------

const keysDown = new Set<string>();
const mouseButtons = new Set<number>();
let mouseX = 0;
let mouseY = 0;

/** Map a DOM KeyboardEvent to a LÖVE key name. */
export function loveKeyName(e: KeyboardEvent): string | null {
  const code = e.code;
  if (code.startsWith("Key")) return code.slice(3).toLowerCase();
  if (code.startsWith("Digit")) return code.slice(5);
  if (code.startsWith("Numpad") && /\d$/.test(code)) return "kp" + code.slice(6);
  const map: Record<string, string> = {
    ArrowLeft: "left", ArrowRight: "right", ArrowUp: "up", ArrowDown: "down",
    ShiftLeft: "lshift", ShiftRight: "rshift", ControlLeft: "lctrl", ControlRight: "rctrl",
    AltLeft: "lalt", AltRight: "ralt", Space: "space", Enter: "return", NumpadEnter: "kpenter",
    Escape: "escape", Backspace: "backspace", Tab: "tab", Delete: "delete",
    Minus: "-", Equal: "=", Period: ".", Comma: ",", Slash: "/",
  };
  return map[code] ?? null;
}

export const keyboard = {
  isDown(...keys: string[]): boolean { return keys.some((k) => keysDown.has(k)); },
  _press(k: string): void { keysDown.add(k); },
  _release(k: string): void { keysDown.delete(k); },
  _clear(): void { keysDown.clear(); },
};

export const mouse = {
  isDown(...buttons: number[]): boolean { return buttons.some((b) => mouseButtons.has(b)); },
  getPosition(): [number, number] { return [mouseX, mouseY]; },
  getX(): number { return mouseX; },
  getY(): number { return mouseY; },
  _move(x: number, y: number): void { mouseX = x; mouseY = y; },
  _press(b: number): void { mouseButtons.add(b); },
  _release(b: number): void { mouseButtons.delete(b); },
};

/** DOM button index (0 left, 1 middle, 2 right) → LÖVE button (1 left, 2 right, 3 middle). */
export function loveMouseButton(domButton: number): number {
  return domButton === 0 ? 1 : domButton === 2 ? 2 : domButton === 1 ? 3 : domButton + 1;
}

//------------------------------------------------------------------------------
// Audio
//------------------------------------------------------------------------------

let audioCtx: AudioContext | null = null;
let masterGain: GainNode | null = null;

function getAudioCtx(): AudioContext | null {
  if (audioCtx) return audioCtx;
  const AC = window.AudioContext || (window as any).webkitAudioContext;
  if (!AC) return null;
  audioCtx = new AC();
  masterGain = audioCtx.createGain();
  masterGain.connect(audioCtx.destination);
  return audioCtx;
}

/** Browsers start audio suspended until a user gesture; main.ts calls this on input. */
export function unlockAudio(): void {
  const ac = getAudioCtx();
  if (ac && ac.state === "suspended") void ac.resume();
}

export class SoundData {
  samples: Float32Array;
  sampleRate: number;
  constructor(count: number, sampleRate = 44100, _bits = 16, _channels = 1) {
    this.samples = new Float32Array(count);
    this.sampleRate = sampleRate;
  }
  setSample(i: number, v: number): void { this.samples[i] = v; }
  getSample(i: number): number { return this.samples[i]; }
  getSampleCount(): number { return this.samples.length; }
  getDuration(): number { return this.samples.length / this.sampleRate; }
}

export class Source {
  data: SoundData;
  private buffer: AudioBuffer | null = null;
  private node: AudioBufferSourceNode | null = null;
  private gain: GainNode | null = null;
  private volume = 1;
  private looping = false;
  private playing = false;
  private startedAt = 0;
  private offset = 0; // seconds into the buffer when paused

  constructor(data: SoundData) { this.data = data; }

  private ensureBuffer(ac: AudioContext): AudioBuffer {
    if (!this.buffer) {
      this.buffer = ac.createBuffer(1, Math.max(1, this.data.samples.length), this.data.sampleRate);
      this.buffer.copyToChannel(this.data.samples as Float32Array<ArrayBuffer>, 0);
    }
    return this.buffer;
  }

  play(): boolean {
    const ac = getAudioCtx();
    if (!ac || !masterGain) return false;
    if (this.playing) return true;
    const node = ac.createBufferSource();
    node.buffer = this.ensureBuffer(ac);
    node.loop = this.looping;
    const gain = ac.createGain();
    gain.gain.value = this.volume;
    node.connect(gain).connect(masterGain);
    node.onended = () => {
      if (this.node === node) {
        this.playing = false;
        this.node = null;
        this.offset = 0;
      }
    };
    const dur = this.data.getDuration();
    node.start(0, dur > 0 ? this.offset % dur : 0);
    this.startedAt = ac.currentTime - this.offset;
    this.node = node;
    this.gain = gain;
    this.playing = true;
    return true;
  }

  private halt(): void {
    if (this.node) {
      const n = this.node;
      this.node = null;
      n.onended = null;
      try { n.stop(); } catch { /* already stopped */ }
    }
    this.playing = false;
  }

  stop(): void { this.halt(); this.offset = 0; }

  pause(): void {
    if (!this.playing || !audioCtx) return;
    this.offset = audioCtx.currentTime - this.startedAt;
    this.halt();
  }

  isPlaying(): boolean { return this.playing; }
  setVolume(v: number): void { this.volume = v; if (this.gain) this.gain.gain.value = v; }
  getVolume(): number { return this.volume; }
  setLooping(l: boolean): void { this.looping = l; if (this.node) this.node.loop = l; }
  isLooping(): boolean { return this.looping; }
  clone(): Source {
    const s = new Source(this.data);
    s.buffer = this.buffer;
    s.volume = this.volume;
    s.looping = this.looping;
    return s;
  }
}

export const sound = {
  newSoundData(count: number, sampleRate?: number, bits?: number, channels?: number): SoundData {
    return new SoundData(count, sampleRate, bits, channels);
  },
};

export const audio = {
  newSource(data: SoundData, _type?: string): Source { return new Source(data); },
  setVolume(v: number): void { getAudioCtx(); if (masterGain) masterGain.gain.value = v; },
  stop(): void { /* sources are stopped individually by sfx/music modules */ },
};

//------------------------------------------------------------------------------
// Filesystem (localStorage-backed)
//------------------------------------------------------------------------------

const FS_PREFIX = "ski_free_or_die/";

export const filesystem = {
  write(name: string, data: string): boolean {
    try { localStorage.setItem(FS_PREFIX + name, data); return true; } catch { return false; }
  },
  read(name: string): string | null {
    try { return localStorage.getItem(FS_PREFIX + name); } catch { return null; }
  },
  getInfo(name: string): { type: "file"; size: number } | null {
    const d = filesystem.read(name);
    return d === null ? null : { type: "file", size: d.length };
  },
  remove(name: string): boolean {
    try { localStorage.removeItem(FS_PREFIX + name); return true; } catch { return false; }
  },
};

//------------------------------------------------------------------------------
// Timer / event
//------------------------------------------------------------------------------

const t0 = performance.now();

export const timer = {
  getTime(): number { return (performance.now() - t0) / 1000; },
};

export const event = {
  // There is no "quit" in a browser tab; main.ts may hook this.
  quit(): void { onQuit(); },
};

let onQuit: () => void = () => {};
export function setQuitHandler(fn: () => void): void { onQuit = fn; }

//------------------------------------------------------------------------------
// The `love` namespace, plus game-dimension helpers main.lua exposed globally
//------------------------------------------------------------------------------

export const love = {
  graphics,
  keyboard,
  mouse,
  audio,
  sound,
  filesystem,
  timer,
  event,
  // Set by main.ts (mirrors love.getGameDimensions / love.getGameMousePosition in main.lua)
  getGameDimensions: (): [number, number] => [360, 480],
  getGameMousePosition: (): [number, number] => [0, 0],
};

export default love;
