// src/states/name_entry_state.ts
// Arcade-style name entry screen for high scores

import love from "../platform/love";
import { get_glyph } from "../gfx/font";
import { draw_sprite, fill_px } from "../gfx/sprite";
import { nearest_key } from "../gfx/palette";
import StateManager from "../core/state_manager";
import Colors from "../colors";
import Config from "../core/config";
import Leaderboard from "../core/leaderboard";
import Music from "../lib/music";

const GAME_WIDTH = Config.GAME_WIDTH;
const GAME_HEIGHT = Config.GAME_HEIGHT;

// Entry state
let entry_data: any = null; // {mode, score, rank}
let player_name = "";
let max_name_length = 8;
let cursor_pos = 1;
let char_selector_index = 1;
let blink_timer = 0;

// Character set for selection (arcade style - uppercase letters, numbers, some symbols)
let charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .-_";

// Animation
let star_particles: any[] = [];
let flash_timer = 0;

// Blocky retro font rendering
function draw_blocky_char(char: string, x: number, y: number, size: number, color: any) {
  size = size ?? 3;
  color = color ?? Colors.SNOW_WHITE;
  const color_key = nearest_key(color[0] * 255, color[1] * 255, color[2] * 255);

  const pattern = get_glyph(char, "name_entry");

  // Draw the character pixel by pixel
  for (let row = 0; row < 7; row++) {
    for (let col = 0; col < 5; col++) {
      if (pattern[row][col] === "#") {
        fill_px(color_key, x + col * size, y + row * size, size - 1, // Small gap between pixels
          size - 1, color[3] ?? 1);
      }
    }
  }
}

// Draw a blocky string
function draw_blocky_string(text: string, x: number, y: number, size: number, color: any, spacing?: number) {
  spacing = spacing ?? 1;
  let char_width = 5 * size + spacing;
  for (let i = 0; i < text.length; i++) {
    let char = text.substring(i, i + 1);
    draw_blocky_char(char, x + i * char_width, y, size, color);
  }
}

// Get width of a blocky string
function get_blocky_string_width(text: string, size: number, spacing?: number) {
  spacing = spacing ?? 1;
  let char_width = 5 * size + spacing;
  return text.length * char_width - spacing;
}

const NameEntryState: { [key: string]: any } = {
  enter(params: any) {
    entry_data = params ?? {};
    player_name = "";
    cursor_pos = 1;
    char_selector_index = 1;
    blink_timer = 0;
    flash_timer = 0;

    // Create star particles for celebration
    star_particles = [];
    for (let i = 1; i <= 50; i += 1) {
      star_particles.push({
        x: Math.floor(Math.random() * (GAME_WIDTH + 1)),
        y: Math.floor(Math.random() * (GAME_HEIGHT + 1)),
        vx: (-30 + Math.floor(Math.random() * 61)),
        vy: (-30 + Math.floor(Math.random() * 61)),
        size: (1 + Math.floor(Math.random() * 3)),
        color: ([Colors.HOT_PINK, Colors.ELECTRIC_BLUE, Colors.BRIGHT_YELLOW, Colors.MINT_GREEN])[Math.floor(Math.random() * 4)],
        life: (2 + Math.floor(Math.random() * 4))
      });
    }

    // Play awards music
    Music.play("awards");
  },

  exit() {
  },

  update(dt: number) {
    blink_timer = blink_timer + dt;
    flash_timer = flash_timer + dt;

    // Update star particles
    for (let i = star_particles.length - 1; i >= 0; i--) {
      let p = star_particles[i];
      p.x = p.x + p.vx * dt;
      p.y = p.y + p.vy * dt;
      p.life = p.life - dt;
      if (p.life <= 0) {
        star_particles.splice(i, 1);
      }
    }
  },

  draw() {
    // Background
    fill_px("D", 0, 0, GAME_WIDTH, GAME_HEIGHT);

    // Draw star particles
    for (const p of star_particles) {
      let alpha = Math.min(1, p.life / 2);
      fill_px(nearest_key(p.color[0] * 255, p.color[1] * 255, p.color[2] * 255), p.x, p.y, p.size, p.size, alpha);
    }

    // Title with flash
    let title_y = 20;
    let title_colors = [Colors.HOT_PINK, Colors.ELECTRIC_BLUE, Colors.BRIGHT_YELLOW];
    let title_color = title_colors[Math.floor(flash_timer * 3) % 3];
    let title_text = "NEW HIGH SCORE!";
    let title_width = get_blocky_string_width(title_text, 2, 2);
    draw_blocky_string(title_text, (GAME_WIDTH - title_width) / 2, title_y, 2, title_color, 2);

    // Rank display
    Colors.set(Colors.MINT_GREEN);
    let rank_text = `RANK #${entry_data.rank ?? 1}`;
    love.graphics.printf(rank_text, 0, title_y + 30, GAME_WIDTH, "center");

    // Score display
    Colors.set(Colors.BRIGHT_YELLOW);
    let score_text = Leaderboard.format_score(entry_data.mode, entry_data.score);
    love.graphics.printf(score_text, 0, title_y + 45, GAME_WIDTH, "center");

    // Instructions
    Colors.set(Colors.SNOW_WHITE);
    love.graphics.printf("ENTER YOUR NAME", 0, 85, GAME_WIDTH, "center");

    // Name entry display
    let name_y = 105;
    let char_size = 4;
    let char_spacing = 3;
    let total_name_width = max_name_length * (5 * char_size + char_spacing);
    let name_start_x = (GAME_WIDTH - total_name_width) / 2;

    // Draw name slots
    for (let i = 1; i <= max_name_length; i += 1) {
      let char_x = name_start_x + (i - 1) * (5 * char_size + char_spacing);

      // Draw the character or underscore
      let char = " ";
      if (i <= player_name.length) {
        char = player_name.substring(i - 1, i);
      }
      let char_color = Colors.SNOW_WHITE;
      if (i === cursor_pos) {
        char_color = Colors.BRIGHT_YELLOW;
      }
      if (char === " " && i <= cursor_pos) {
        // Draw blinking underscore for current position
        if (Math.floor(blink_timer * 2) % 2 === 0) {
          draw_blocky_char("_", char_x, name_y, char_size, char_color);
        }
      } else {
        draw_blocky_char(char, char_x, name_y, char_size, char_color);
      }
    }

    // Character selector (only for current position)
    if (cursor_pos <= max_name_length) {
      let selector_y = name_y + 45;
      let current_char = charset.substring(char_selector_index - 1, char_selector_index);

      // Up arrow
      draw_sprite("ui_arrow_up", GAME_WIDTH / 2, selector_y - 15);

      // Selected character
      let sel_char_width = get_blocky_string_width(current_char, 5, 3);
      draw_blocky_char(current_char, (GAME_WIDTH - 5 * 5) / 2, selector_y, 5, Colors.HOT_PINK);

      // Down arrow
      draw_sprite("ui_arrow_down", GAME_WIDTH / 2, selector_y + 50);
    }

    // Controls
    Colors.set(Colors.SNOW_WHITE);
    love.graphics.printf("UP/DOWN: Select Character", 0, GAME_HEIGHT - 50, GAME_WIDTH, "center");
    love.graphics.printf("LEFT/RIGHT: Move Cursor", 0, GAME_HEIGHT - 38, GAME_WIDTH, "center");
    love.graphics.printf("ENTER: Confirm  |  BACKSPACE: Delete", 0, GAME_HEIGHT - 26, GAME_WIDTH, "center");
  },

  keypressed(key: string) {
    if (key === "up") {
      // Previous character
      char_selector_index = char_selector_index - 1;
      if (char_selector_index < 1) {
        char_selector_index = charset.length;
      }
    } else if (key === "down") {
      // Next character
      char_selector_index = char_selector_index + 1;
      if (char_selector_index > charset.length) {
        char_selector_index = 1;
      }
    } else if (key === "left") {
      // Move cursor left
      if (cursor_pos > 1) {
        cursor_pos = cursor_pos - 1;

        // Update selector to match current character
        if (cursor_pos <= player_name.length) {
          let char = player_name.substring(cursor_pos - 1, cursor_pos);

          // Lua string.find treats "." as a pattern matching the first character.
          char_selector_index = char === "." ? 1 : Math.max(1, charset.indexOf(char) + 1);
        }
      }
    } else if (key === "right") {
      // Move cursor right
      if (cursor_pos < max_name_length && cursor_pos <= player_name.length + 1) {
        cursor_pos = cursor_pos + 1;

        // Update selector to match current character
        if (cursor_pos <= player_name.length) {
          let char = player_name.substring(cursor_pos - 1, cursor_pos);

          // Lua string.find treats "." as a pattern matching the first character.
          char_selector_index = char === "." ? 1 : Math.max(1, charset.indexOf(char) + 1);
        }
      }
    } else if (key === "return" || key === "space") {
      // Add current character
      if (cursor_pos <= max_name_length) {
        let char = charset.substring(char_selector_index - 1, char_selector_index);
        if (cursor_pos <= player_name.length) {
          // Replace character
          player_name = player_name.substring(0, cursor_pos - 1) + char + player_name.substring(cursor_pos);
        } else {
          // Append character
          player_name = player_name + char;
        }

        // Move to next position
        if (cursor_pos < max_name_length) {
          cursor_pos = cursor_pos + 1;
        }
      }
    } else if (key === "backspace" || key === "delete") {
      // Delete character
      if (player_name.length > 0 && cursor_pos > 1) {
        player_name = player_name.substring(0, cursor_pos - 2) + player_name.substring(cursor_pos - 1);
        cursor_pos = cursor_pos - 1;
      } else if (player_name.length > 0 && cursor_pos === 1) {
        player_name = player_name.substring(1);
      }
    } else if (key === "escape") {
      // Submit with default name if empty
      if (player_name.length === 0) {
        player_name = "AAA";
      }
      this.submit_score();
    }

    // Check if we have a complete name and user presses enter on last char
    if (key === "return" && player_name.length >= 3) {
      // Allow submission
      this.submit_score();
    }
  },

  submit_score() {
    // Trim whitespace from name
    let trimmed_name = player_name.replace(/^[ \f\n\r\t\v]+/, "").replace(/[ \f\n\r\t\v]+$/, "");
    if (trimmed_name.length < 1) {
      trimmed_name = "ANON";
    }

    // Add to leaderboard
    Leaderboard.add(entry_data.mode, trimmed_name, entry_data.score);

    // Go to high scores screen
    StateManager.switch("highscores", { mode: entry_data.mode, from_entry: true });
  },
};

export default NameEntryState;
