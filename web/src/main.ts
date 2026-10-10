// src/main.ts
// Ski Free Or Die! - Entry point (port of main.lua)
// 80s-themed downhill skiing game

import love, {
  Canvas,
  loveKeyName,
  loveMouseButton,
  preloadImages,
  setQuitHandler,
  unlockAudio,
} from "./platform/love";
import StateManager from "./core/state_manager";
import Colors from "./colors";
import Config from "./core/config";
import SidebarHUD from "./ui/sidebar_hud";
import Skier from "./entities/skier";
import PlayState from "./states/play_state";
import MenuState from "./states/menu_state";
import HighScoresState from "./states/highscores_state";
import NameEntryState from "./states/name_entry_state";
import Leaderboard from "./core/leaderboard";

// Game constants (loaded from Config)
const GAME_WIDTH = Config.GAME_WIDTH;
const GAME_HEIGHT = Config.GAME_HEIGHT;

// Speed display conversion (roughly: 1 mph ≈ 5.9 pixels/sec at this scale)
const PIXELS_PER_SEC_TO_MPH = 0.17;

// Images loaded before the game starts (newImage() is synchronous)
const IMAGES = [
  "images/title_screen.png",
  "images/hud_sidebar_background_left.png",
  "images/hud_sidebar_background_right.png",
];

// Canvas for pixel-perfect rendering
let canvas: Canvas;
let screenEl: HTMLCanvasElement;

function get_layout(): { scale: number; offset_x: number; offset_y: number } {
  const w = love.graphics.getWidth();
  const h = love.graphics.getHeight();
  const scale = Math.min(w / GAME_WIDTH, h / GAME_HEIGHT);
  return {
    scale,
    offset_x: (w - GAME_WIDTH * scale) / 2,
    offset_y: (h - GAME_HEIGHT * scale) / 2,
  };
}

// Convert window mouse coordinates to game coordinates (accounting for letterboxing/scaling)
love.getGameMousePosition = (): [number, number] => {
  const [mx, my] = love.mouse.getPosition();
  const { scale, offset_x, offset_y } = get_layout();
  return [(mx - offset_x) / scale, (my - offset_y) / scale];
};

love.getGameDimensions = (): [number, number] => [GAME_WIDTH, GAME_HEIGHT];

function load(): void {
  canvas = love.graphics.newCanvas(GAME_WIDTH, GAME_HEIGHT);

  StateManager.register("menu", MenuState);
  StateManager.register("play", PlayState);
  StateManager.register("highscores", HighScoresState);
  StateManager.register("name_entry", NameEntryState);

  // Initialize leaderboard system
  Leaderboard.init();

  // Start in menu state
  StateManager.switch("menu");
}

function update(dt: number): void {
  // Cap delta time to prevent physics issues on slow frames
  dt = Math.min(dt, 1 / 30);
  StateManager.update(dt);
}

function draw(): void {
  // Draw to canvas at native resolution
  love.graphics.setCanvas(canvas);
  love.graphics.origin();
  love.graphics.clear(Colors.SKY_BLUE);

  StateManager.draw();

  love.graphics.setCanvas();
  love.graphics.origin();

  // Scale canvas to window with letterboxing
  const { scale, offset_x, offset_y } = get_layout();

  love.graphics.setColor(0.05, 0.05, 0.1);
  love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight());

  love.graphics.setColor(1, 1, 1);
  love.graphics.draw(canvas, offset_x, offset_y, 0, scale, scale);

  // Draw sidebar HUD in letterbox areas (only during play state)
  if (StateManager.get_current_name() === "play" && offset_x > 50) {
    const state: any = StateManager.get_current();

    // Build HUD state table from play state
    const raw_speed = state.skier ? state.skier.speed : 0;
    const hud_state = {
      elapsed_time: state.elapsed_time || 0,
      speed_mph: raw_speed * PIXELS_PER_SEC_TO_MPH,
      speed_ratio: raw_speed / Skier.MAX_SPEED,
      gates_passed: state.gates_passed || 0,
      gates_missed: state.gates_missed || 0,
      distance: state.distance || 0,
      is_tucking: state.skier ? state.skier.is_tucking : false,
      is_crashed: state.skier ? state.skier.is_crashed : false,
      mode: state.mode || "trial",
    };

    const window_width = love.graphics.getWidth();
    const window_height = love.graphics.getHeight();

    // Left sidebar (Arcade) and Right sidebar (California Games)
    SidebarHUD.draw(0, offset_x, window_width - offset_x, offset_x, window_height, hud_state);
  }
}

//------------------------------------------------------------------------------
// Browser glue: window sizing, input events, main loop
//------------------------------------------------------------------------------

function resize(): void {
  screenEl.width = Math.floor(window.innerWidth);
  screenEl.height = Math.floor(window.innerHeight);
  love.graphics._ctx().imageSmoothingEnabled = false;
}

function to_window_coords(clientX: number, clientY: number): [number, number] {
  const rect = screenEl.getBoundingClientRect();
  return [
    ((clientX - rect.left) * screenEl.width) / rect.width,
    ((clientY - rect.top) * screenEl.height) / rect.height,
  ];
}

function keypressed(key: string): void {
  if (key === "escape" && StateManager.get_current_name() === "menu") {
    // No quitting a browser tab; ignore like a no-op
    return;
  }
  StateManager.keypressed(key);
}

function bind_input(): void {
  window.addEventListener("keydown", (e) => {
    unlockAudio();
    const key = loveKeyName(e);
    if (!key) return;
    // Keep arrows/space/tab from scrolling or moving focus
    if (["up", "down", "left", "right", "space", "tab", "backspace"].includes(key)) e.preventDefault();
    if (e.repeat) return;
    love.keyboard._press(key);
    keypressed(key);
  });
  window.addEventListener("keyup", (e) => {
    const key = loveKeyName(e);
    if (!key) return;
    love.keyboard._release(key);
    StateManager.keyreleased(key);
  });
  window.addEventListener("blur", () => love.keyboard._clear());

  screenEl.addEventListener("contextmenu", (e) => e.preventDefault());
  window.addEventListener("mousemove", (e) => {
    const [x, y] = to_window_coords(e.clientX, e.clientY);
    love.mouse._move(x, y);
  });
  screenEl.addEventListener("mousedown", (e) => {
    unlockAudio();
    const [x, y] = to_window_coords(e.clientX, e.clientY);
    love.mouse._move(x, y);
    const button = loveMouseButton(e.button);
    love.mouse._press(button);
    const [gx, gy] = love.getGameMousePosition();
    StateManager.mousepressed(gx, gy, button);
  });
  window.addEventListener("mouseup", (e) => love.mouse._release(loveMouseButton(e.button)));
  screenEl.addEventListener(
    "wheel",
    (e) => {
      e.preventDefault();
      // LÖVE reports wheel "clicks": positive y = scroll up
      StateManager.wheelmoved(0, -Math.sign(e.deltaY));
    },
    { passive: false },
  );

  // Touch: one finger steers (acts as the mouse position), a second finger tucks
  // (acts as holding the left mouse button). A tap clicks menu items.
  const on_touch = (e: TouchEvent) => {
    e.preventDefault();
    unlockAudio();
    const touches = e.touches;
    if (touches.length > 0) {
      const [x, y] = to_window_coords(touches[0].clientX, touches[0].clientY);
      love.mouse._move(x, y);
    }
    if (touches.length >= 2) love.mouse._press(1);
    else love.mouse._release(1);
  };
  screenEl.addEventListener("touchstart", (e) => {
    on_touch(e);
    if (e.touches.length === 1) {
      const [gx, gy] = love.getGameMousePosition();
      StateManager.mousepressed(gx, gy, 1);
    }
  }, { passive: false });
  screenEl.addEventListener("touchmove", on_touch, { passive: false });
  screenEl.addEventListener("touchend", on_touch, { passive: false });
  screenEl.addEventListener("touchcancel", on_touch, { passive: false });
}

async function boot(): Promise<void> {
  screenEl = document.getElementById("screen") as HTMLCanvasElement;
  love.graphics._init(screenEl);
  resize();
  window.addEventListener("resize", resize);
  setQuitHandler(() => StateManager.switch("menu"));

  await preloadImages(IMAGES);
  load();

  // Dev-only hook for driving the game from the console / review screenshots
  if (import.meta.env.DEV) (window as any).__game = { StateManager, love };
  bind_input();

  let last = performance.now();
  const frame = (now: number) => {
    const dt = (now - last) / 1000;
    last = now;
    update(dt);
    draw();
    requestAnimationFrame(frame);
  };
  requestAnimationFrame(frame);
}

void boot();
