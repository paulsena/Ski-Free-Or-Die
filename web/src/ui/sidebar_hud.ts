// src/ui/sidebar_hud.ts
// California Games style sidebar HUD
// Left: Decorative 80s ski art | Right: Game stats

import love from "../platform/love";
import { get_glyph } from "../gfx/font";
import Colors from "../colors";
import Utils from "../lib/utils";

// Background images (loaded on first use)
let bg_left: any = null;
let bg_right: any = null;

// Load background images
function load_images() {
  if (!bg_left) {
    bg_left = love.graphics.newImage("images/hud_sidebar_background_left.png");
    bg_left.setFilter("nearest", "nearest"); // Pixel-perfect scaling
  }
  if (!bg_right) {
    bg_right = love.graphics.newImage("images/hud_sidebar_background_right.png");
    bg_right.setFilter("nearest", "nearest");
  }
}

// Blocky pixel font - each letter is a 5x7 grid of pixels
const BLOCK_SIZE = 4; // Size of each "pixel" in the blocky font

// Draw a single blocky character
function draw_block_char(char: string, x: number, y: number, size: number, color: any, shadow_color: any) {
  const pattern = get_glyph(char);
  size = size ?? BLOCK_SIZE;

  // Draw shadow first
  if (shadow_color) {
    love.graphics.setColor(shadow_color);
    for (let row = 0; row < 7; row++) {
      for (let col = 0; col < 5; col++) {
        if (pattern[row][col] === "#") {
          love.graphics.rectangle("fill", x + col * size + 2, y + row * size + 2, size, size);
        }
      }
    }
  }

  // Draw main character
  love.graphics.setColor(color);
  for (let row = 0; row < 7; row++) {
    for (let col = 0; col < 5; col++) {
      if (pattern[row][col] === "#") {
        love.graphics.rectangle("fill", x + col * size, y + row * size, size, size);
      }
    }
  }
  return 6 * size; // Character width + spacing
}

// Draw blocky text string
function draw_block_text(text: string, x: number, y: number, size: number, color: any, shadow_color: any, centered_width?: number) {
  size = size ?? BLOCK_SIZE;
  let char_width = 6 * size;
  let total_width = text.length * char_width;
  if (centered_width != null) {
    x = x + (centered_width - total_width) / 2;
  }
  for (let i = 0; i < text.length; i++) {
    let char = text.substring(i, i + 1);
    draw_block_char(char, x + i * char_width, y, size, color, shadow_color);
  }
}

// Draw detailed mountain range
function draw_mountains(x: number, y: number, width: number, height: number) {
  // Back mountains (darker, further away)
  love.graphics.setColor(0.12, 0.12, 0.18, 1);
  let back_peaks = [
    x, y + height,
    x + width * 0.15, y + height * 0.3,
    x + width * 0.3, y + height * 0.6,
    x + width * 0.45, y + height * 0.15,
    x + width * 0.6, y + height * 0.5,
    x + width * 0.75, y + height * 0.25,
    x + width * 0.9, y + height * 0.45,
    x + width, y + height,
  ];
  love.graphics.polygon("fill", back_peaks);

  // Front mountains (lighter, closer)
  love.graphics.setColor(0.18, 0.18, 0.25, 1);
  let front_peaks = [
    x, y + height,
    x + width * 0.1, y + height * 0.5,
    x + width * 0.25, y + height * 0.2,
    x + width * 0.4, y + height * 0.55,
    x + width * 0.55, y + height * 0.1,
    x + width * 0.7, y + height * 0.4,
    x + width * 0.85, y + height * 0.25,
    x + width, y + height * 0.5,
    x + width, y + height,
  ];
  love.graphics.polygon("fill", front_peaks);

  // Snow caps
  love.graphics.setColor(0.9, 0.92, 0.95, 0.8);

  // Peak 1
  love.graphics.polygon("fill", x + width * 0.25, y + height * 0.2, x + width * 0.22, y + height * 0.32, x + width * 0.28, y + height * 0.32);

  // Peak 2 (main peak)
  love.graphics.polygon("fill", x + width * 0.55, y + height * 0.1, x + width * 0.50, y + height * 0.25, x + width * 0.60, y + height * 0.25);

  // Peak 3
  love.graphics.polygon("fill", x + width * 0.85, y + height * 0.25, x + width * 0.82, y + height * 0.35, x + width * 0.88, y + height * 0.35);
}

// Draw pine tree silhouette
function draw_pine_tree(x: number, y: number, height: number, color: any) {
  love.graphics.setColor(color);
  let width = height * 0.6;

  // Tree layers (triangles stacked)
  for (let i = 0; i <= 2; i += 1) {
    let layer_y = y + i * (height * 0.25);
    let layer_height = height * 0.4;
    let layer_width = width * (1 - i * 0.2);
    love.graphics.polygon("fill", x, layer_y + layer_height, x + layer_width / 2, layer_y, x + layer_width, layer_y + layer_height);
  }

  // Trunk
  love.graphics.rectangle("fill", x + width * 0.35, y + height * 0.85, width * 0.3, height * 0.15);
}

// Draw 80s style sun with gradient stripes
function draw_80s_sun(x: number, y: number, radius: number) {
  // Sun circle segments (gradient effect)
  let colors = [
    [1, 0.2, 0.6, 1], // Hot pink
    [1, 0.4, 0.2, 1], // Orange
    [1, 0.7, 0, 1], // Yellow-orange
    [1, 0.85, 0.2, 1], // Yellow
  ];
  for (let i = colors.length - 1; i >= 0; i--) {
    love.graphics.setColor(colors[i]);
    let segment_radius = radius * ((i + 1) / colors.length);
    love.graphics.circle("fill", x, y, segment_radius);
  }

  // Horizontal stripe cutouts (80s aesthetic)
  love.graphics.setColor(0.02, 0.02, 0.05, 1);
  for (let stripe = 1; stripe <= 5; stripe += 1) {
    let stripe_y = y + stripe * (radius * 0.15);
    let stripe_width = Math.sqrt(radius * radius - (stripe * radius * 0.15) ** 2) * 2;
    if (stripe_width > 0) {
      love.graphics.rectangle("fill", x - stripe_width / 2, stripe_y, stripe_width, 3);
    }
  }
}

// Draw skier silhouette doing a trick
function draw_skier_silhouette(x: number, y: number, scale: number) {
  love.graphics.setColor(0.1, 0.1, 0.15, 1);
  scale = scale ?? 1;

  // Body (leaning forward in tuck)
  love.graphics.ellipse("fill", x, y, 8 * scale, 12 * scale);

  // Head
  love.graphics.circle("fill", x + 6 * scale, y - 10 * scale, 5 * scale);

  // Skis (crossed/jumping)
  love.graphics.setLineWidth(3 * scale);
  love.graphics.line(x - 15 * scale, y + 8 * scale, x + 20 * scale, y + 15 * scale);
  love.graphics.line(x - 12 * scale, y + 15 * scale, x + 18 * scale, y + 5 * scale);
  love.graphics.setLineWidth(1);

  // Poles
  love.graphics.setLineWidth(2 * scale);
  love.graphics.line(x - 5 * scale, y - 5 * scale, x - 18 * scale, y + 20 * scale);
  love.graphics.line(x + 8 * scale, y - 5 * scale, x + 22 * scale, y + 15 * scale);
  love.graphics.setLineWidth(1);
}

// Draw falling snow particles
function draw_snow_particles(x: number, width: number, height: number, time: number) {
  love.graphics.setColor(1, 1, 1, 0.6);
  let seed = 12345;
  for (let i = 1; i <= 20; i += 1) {
    seed = (seed * 1103515245 + 12345) % 2147483648;
    let px = x + (seed % width);
    seed = (seed * 1103515245 + 12345) % 2147483648;
    let base_y = seed % height;
    let py = (base_y + time * 30 * (1 + (i % 3) * 0.3)) % height;
    let size = 2 + (i % 3);
    love.graphics.rectangle("fill", px, py, size, size);
  }
}

// Draw 80s geometric pattern
function draw_80s_pattern(x: number, y: number, width: number, height: number) {
  // Diagonal lines
  love.graphics.setColor(Colors.HOT_PINK[0], Colors.HOT_PINK[1], Colors.HOT_PINK[2], 0.15);
  love.graphics.setLineWidth(2);
  for (let i = 0; i <= 10; i += 1) {
    let offset = i * 25;
    love.graphics.line(x + offset, y, x, y + offset);
    love.graphics.line(x + width - offset, y + height, x + width, y + height - offset);
  }

  // Triangle accents
  love.graphics.setColor(Colors.ELECTRIC_BLUE[0], Colors.ELECTRIC_BLUE[1], Colors.ELECTRIC_BLUE[2], 0.1);
  love.graphics.polygon("fill", x + 20, y + height - 80, x + 50, y + height - 40, x + 80, y + height - 80);
  love.graphics.setLineWidth(1);
}

// Draw ski lodge silhouette
function draw_lodge(x: number, y: number, width: number, height: number) {
  love.graphics.setColor(0.08, 0.08, 0.12, 1);

  // Main building
  love.graphics.rectangle("fill", x, y + height * 0.4, width, height * 0.6);

  // Peaked roof
  love.graphics.polygon("fill", x - 5, y + height * 0.4, x + width / 2, y, x + width + 5, y + height * 0.4);

  // Chimney
  love.graphics.rectangle("fill", x + width * 0.7, y - 10, width * 0.15, height * 0.3);

  // Windows (lit up)
  love.graphics.setColor(1, 0.9, 0.5, 0.7);
  love.graphics.rectangle("fill", x + width * 0.15, y + height * 0.55, width * 0.2, height * 0.2);
  love.graphics.rectangle("fill", x + width * 0.45, y + height * 0.55, width * 0.2, height * 0.2);
  love.graphics.rectangle("fill", x + width * 0.3, y + height * 0.8, width * 0.25, height * 0.15);
}

// Draw the left sidebar (Decorative art)

const SidebarHUD: { [key: string]: any } = {
  draw_left(x: number, width: number, height: number) {
    load_images();

    // Background fill (in case image doesn't cover everything)
    love.graphics.setColor(0.02, 0.02, 0.05, 1);
    love.graphics.rectangle("fill", x, 0, width, height);

    // Draw background image scaled to fit width
    if (bg_left) {
      let img_width = bg_left.getWidth();
      let img_height = bg_left.getHeight();
      let scale = width / img_width;

      // Center vertically if scaled image is shorter than sidebar
      let scaled_height = img_height * scale;
      let y_offset = (height - scaled_height) / 2;
      if (y_offset < 0) {
        y_offset = 0;
      }
      love.graphics.setColor(1, 1, 1, 1);
      love.graphics.draw(bg_left, x, y_offset, 0, scale, scale);
    }

    // Title text overlay
    draw_block_text("SKI", x, 450, 5, Colors.HOT_PINK, [0, 0, 0, 1], width);
    draw_block_text("FREE", x, 495, 5, Colors.ELECTRIC_BLUE, [0, 0, 0, 1], width);
    draw_block_text("OR", x, 540, 4, Colors.BRIGHT_YELLOW, [0, 0, 0, 1], width);
    draw_block_text("DIE", x, 575, 5, Colors.MINT_GREEN, [0, 0, 0, 1], width);

    // Insert Coin at bottom
    draw_block_text("INSERT", x, height - 90, 3, Colors.ELECTRIC_BLUE, [0, 0, 0, 1], width);
    draw_block_text("COIN", x, height - 55, 3, Colors.HOT_PINK, [0, 0, 0, 1], width);
  },

  // Draw the right sidebar (Stats)
  draw_right(x: number, width: number, height: number, state: any) {
    load_images();

    // Background fill
    love.graphics.setColor(0.02, 0.02, 0.05, 1);
    love.graphics.rectangle("fill", x, 0, width, height);

    // Draw background image scaled to fit width
    if (bg_right) {
      let img_width = bg_right.getWidth();
      let img_height = bg_right.getHeight();
      let scale = width / img_width;

      // Center vertically if scaled image is shorter than sidebar
      let scaled_height = img_height * scale;
      let y_offset = (height - scaled_height) / 2;
      if (y_offset < 0) {
        y_offset = 0;
      }
      love.graphics.setColor(1, 1, 1, 1);
      love.graphics.draw(bg_right, x, y_offset, 0, scale, scale);
    }
    let y = 120;

    // GROUP 1: Time, Penalty, Gates
    // TIME
    draw_block_text("TIME", x, y, 4, Colors.SNOW_WHITE, [0, 0, 0, 1], width);
    y = y + 35;
    let total_time = state.elapsed_time + (state.gates_missed ?? 0) * 3;
    draw_block_text(Utils.format_time(total_time), x, y, 5, Colors.HOT_PINK, [0, 0, 0, 1], width);
    y = y + 60;

    // TOTAL PENALTY
    draw_block_text("PENALTY", x, y, 3, Colors.SNOW_WHITE, [0, 0, 0, 1], width);
    y = y + 28;
    let penalty_seconds = (state.gates_missed ?? 0) * 3;
    let penalty_color = penalty_seconds > 0 ? Colors.HOT_PINK : Colors.SNOW_WHITE;
    draw_block_text(`+${penalty_seconds}s`, x, y, 4, penalty_color, [0, 0, 0, 1], width);
    y = y + 55;

    // GATES
    draw_block_text("GATES", x, y, 4, Colors.SNOW_WHITE, [0, 0, 0, 1], width);
    y = y + 35;
    draw_block_text(`${state.gates_passed ?? 0}`, x, y, 5, Colors.MINT_GREEN, [0, 0, 0, 1], width);
    y = y + 90;

    // GROUP 2: Speed, Distance (bigger space before this group)
    // SPEED (MPH)
    draw_block_text("SPEED", x, y, 4, Colors.SNOW_WHITE, [0, 0, 0, 1], width);
    y = y + 35;
    let speed_color = Colors.ELECTRIC_BLUE;
    if (state.speed_ratio && state.speed_ratio > 0.8) {
      speed_color = Colors.BRIGHT_YELLOW;
    }
    draw_block_text(`${(state.speed_mph ?? 0).toFixed(0)}`, x, y, 5, speed_color, [0, 0, 0, 1], width);
    y = y + 45;
    draw_block_text("MPH", x, y, 3, Colors.SNOW_WHITE, [0, 0, 0, 1], width);
    y = y + 60;

    // DISTANCE
    draw_block_text("DIST", x, y, 4, Colors.SNOW_WHITE, [0, 0, 0, 1], width);
    y = y + 35;
    draw_block_text(`${Math.floor((state.distance ?? 0) / 10)}m`, x, y, 5, Colors.ELECTRIC_BLUE, [0, 0, 0, 1], width);
    y = y + 60;

    // TUCK indicator
    if (state.is_tucking) {
      // Flashing effect
      if (Math.floor(love.timer.getTime() * 4) % 2 === 0) {
        draw_block_text("TUCK", x, y, 5, Colors.BRIGHT_YELLOW, [0, 0, 0, 1], width);
      }
    }

    // Mode indicator at bottom
    let mode_text = state.mode === "endless" ? "ENDLESS" : "TRIAL";
    draw_block_text(mode_text, x, height - 50, 3, Colors.MINT_GREEN, [0, 0, 0, 1], width);
  },

  // Main draw function
  draw(left_x: number, left_width: number, right_x: number, right_width: number, window_height: number, state: any) {
    SidebarHUD.draw_left(left_x, left_width, window_height);
    SidebarHUD.draw_right(right_x, right_width, window_height, state);
  },
};

export default SidebarHUD;
