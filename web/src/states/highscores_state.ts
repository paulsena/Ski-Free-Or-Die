// src/states/highscores_state.ts
// High scores / leaderboard display with retro arcade styling

import love from "../platform/love";
import { draw_sprite, fill_px } from "../gfx/sprite";
import { nearest_key, pal } from "../gfx/palette";
import { MEDAL_SWAPS } from "../gfx/sprites/ui";
import StateManager from "../core/state_manager";
import Colors from "../colors";
import Config from "../core/config";
import Leaderboard from "../core/leaderboard";
import Music from "../lib/music";

const GAME_WIDTH = Config.GAME_WIDTH;
const GAME_HEIGHT = Config.GAME_HEIGHT;

// State
let current_mode = "time_trial";
let mode_selection = 1;
let scroll_offset = 0;
let flash_timer = 0;
let podium_animation = 0;
let came_from_entry = false;

// Medal colors for top 3
let medal_colors = [
  Colors.BRIGHT_YELLOW, // Gold
  pal("L"), // Silver
  pal("w") // Bronze
];

// Floating sparkles for top scores
let sparkles: any[] = [];

const HighScoresState: { [key: string]: any } = {
  enter(params: any) {
    params = params ?? {};
    current_mode = params.mode ?? "time_trial";
    mode_selection = current_mode === "time_trial" ? 1 : 2;
    came_from_entry = params.from_entry ?? false;
    scroll_offset = 0;
    flash_timer = 0;
    podium_animation = 0;

    // Create sparkles for celebration
    sparkles = [];
    for (let i = 1; i <= 30; i += 1) {
      sparkles.push({
        x: Math.floor(Math.random() * (GAME_WIDTH + 1)),
        y: Math.floor(Math.random() * (GAME_HEIGHT / 2 + 1)),
        vx: (-10 + Math.floor(Math.random() * 21)),
        vy: (-20 + Math.floor(Math.random() * 21)),
        size: (1 + Math.floor(Math.random() * 2)),
        life: (3 + Math.floor(Math.random() * 4)),
        max_life: (3 + Math.floor(Math.random() * 4))
      });
    }

    // Always play awards music on high scores screen
    Music.play("awards");
  },

  exit() {
    // Clear new flags when leaving
    Leaderboard.clear_new_flags();
  },

  update(dt: number) {
    flash_timer = flash_timer + dt;
    podium_animation = Math.min(podium_animation + dt * 2, 1);

    // Update sparkles
    for (let i = sparkles.length - 1; i >= 0; i--) {
      let s = sparkles[i];
      s.x = s.x + s.vx * dt;
      s.y = s.y + s.vy * dt;
      s.vy = s.vy + 30 * dt; // Gravity
      s.life = s.life - dt;
      if (s.life <= 0) {
        sparkles.splice(i, 1);
      }
    }

    // Continuously spawn new sparkles if coming from entry
    if (came_from_entry && Math.random() < 0.3) {
      sparkles.push({
        x: Math.floor(Math.random() * (GAME_WIDTH + 1)),
        y: 0,
        vx: (-10 + Math.floor(Math.random() * 21)),
        vy: (-20 + Math.floor(Math.random() * 21)),
        size: (1 + Math.floor(Math.random() * 2)),
        life: (3 + Math.floor(Math.random() * 4)),
        max_life: (3 + Math.floor(Math.random() * 4))
      });
    }
  },

  draw() {
    // Background palette bands with a 2x2 Bayer transition
    const bayer = [[0, 2], [3, 1]];
    for (let y = 0; y <= GAME_HEIGHT; y += 1) {
      let t = y / GAME_HEIGHT;
      if (t < 0.45) {
        fill_px("D", 0, y, GAME_WIDTH, 1);
      } else if (t >= 0.65) {
        fill_px("d", 0, y, GAME_WIDTH, 1);
      } else {
        let density = Math.min(4, 1 + Math.floor((t - 0.45) / 0.05));
        fill_px(density === 4 ? "d" : "D", 0, y, GAME_WIDTH, 1);
        if (density < 4) {
          for (let x = 0; x < GAME_WIDTH; x += 1) {
            if (bayer[y % 2][x % 2] < density) {
              fill_px("d", x, y, 1, 1);
            }
          }
        }
      }
    }

    // Draw sparkles
    for (const s of sparkles) {
      let alpha = Math.min(1, s.life / 2);
      let color_idx = (Math.floor(flash_timer * 4 + s.x) - Math.floor(Math.floor(flash_timer * 4 + s.x) / 4) * 4);
      let color = ([Colors.HOT_PINK, Colors.ELECTRIC_BLUE, Colors.BRIGHT_YELLOW, Colors.MINT_GREEN])[color_idx];
      fill_px(nearest_key(color[0] * 255, color[1] * 255, color[2] * 255), s.x, s.y, s.size, s.size, alpha);
    }

    // Title
    Colors.set(Colors.BRIGHT_YELLOW);
    love.graphics.printf("HIGH SCORES", 0, 10, GAME_WIDTH, "center");

    // Mode tabs
    this.draw_mode_tabs();

    // Leaderboard
    this.draw_leaderboard();

    // Controls
    Colors.set(Colors.SNOW_WHITE);
    love.graphics.printf("TAB: Switch Mode  |  ESC: Back to Menu", 0, GAME_HEIGHT - 14, GAME_WIDTH, "center");
  },

  draw_mode_tabs() {
    let tab_y = 25;
    let tab_width = 80;
    let tab_height = 12;
    let tab_spacing = 10;
    let total_width = tab_width * 2 + tab_spacing;
    let start_x = (GAME_WIDTH - total_width) / 2;
    let modes = ["time_trial", "endless"];
    let labels = ["TIME TRIAL", "ENDLESS"];
    for (let i = 1; i <= 2; i += 1) {
      let tab_x = start_x + (i - 1) * (tab_width + tab_spacing);
      let is_selected = (mode_selection === i);

      // Tab background
      fill_px(is_selected ? "P" : "r", tab_x, tab_y, tab_width, tab_height, is_selected ? 1 : 0.8);

      // Tab border
      fill_px("W", tab_x, tab_y, tab_width, 1);
      fill_px("W", tab_x, tab_y + tab_height - 1, tab_width, 1);
      fill_px("W", tab_x, tab_y + 1, 1, tab_height - 2);
      fill_px("W", tab_x + tab_width - 1, tab_y + 1, 1, tab_height - 2);

      // Tab label
      if (is_selected) {
        Colors.set(Colors.BLACK);
      } else {
        Colors.set(Colors.SNOW_WHITE);
      }
      love.graphics.printf(labels[i - 1], tab_x, tab_y + 2, tab_width, "center");
    }
  },

  draw_leaderboard() {
    let scores = Leaderboard.get_scores(current_mode);
    let start_y = 50;
    let line_height = 14;

    // Header
    Colors.set(Colors.ELECTRIC_BLUE);
    love.graphics.print("RANK", 20, start_y);
    love.graphics.print("NAME", 80, start_y);
    love.graphics.print("SCORE", GAME_WIDTH - 100, start_y);

    // Separator line
    fill_px("R", 10, Math.round(start_y + 10), GAME_WIDTH - 20, 1);

    // Scores
    let list_start_y = start_y + 15;
    if (scores.length === 0) {
      // No scores yet
      Colors.set(Colors.ROCK_GRAY);
      love.graphics.printf("NO SCORES YET", 0, list_start_y + 30, GAME_WIDTH, "center");
      love.graphics.printf("BE THE FIRST!", 0, list_start_y + 45, GAME_WIDTH, "center");
    } else {
      for (let i = 0; i < scores.length; i++) {
        const entry = scores[i];
        let y = list_start_y + i * line_height;
        let is_new = entry.is_new ?? false;
        let rank = i + 1;

        // Highlight new entries
        if (is_new) {
          let flash = Math.floor(flash_timer * 3) % 2 === 0;
          if (flash) {
            fill_px("M", 10, y - 2, GAME_WIDTH - 20, line_height - 2);
          }
        }

        // Medal/rank display
        if (rank <= 3) {
          // Top 3 get medals with podium animation
          // Animated entrance for top 3
          let scale = 1;
          if (podium_animation < 1) {
            scale = Math.min(1, podium_animation * (4 - rank));
          }

          // Draw medal sprite
          if (scale > 0.35) {
            draw_sprite("ui_medal", 35 + (1 - scale) * 5, y + 5, false, MEDAL_SWAPS[rank - 1]);
          }

          // Medal number
          Colors.set(Colors.BLACK);
          love.graphics.printf(String(rank), 30 + (1 - scale) * 5, y + 1, 10, "center");
        } else {
          // Regular rank number
          if (is_new) {
            Colors.set(Colors.BLACK);
          } else {
            Colors.set(Colors.ROCK_GRAY);
          }
          love.graphics.printf(`${String(rank).padStart(2, " ")}`, 20, y, 30, "left");
        }

        // Name
        if (is_new) {
          Colors.set(Colors.BLACK);
        } else if (rank <= 3) {
          Colors.set(medal_colors[rank - 1]);
        } else {
          Colors.set(Colors.SNOW_WHITE);
        }
        love.graphics.print(entry.name, 80, y);

        // Score
        let score_text = Leaderboard.format_score(current_mode, entry.score);
        let score_x = GAME_WIDTH - 100;
        if (is_new) {
          Colors.set(Colors.BLACK);
        } else if (rank <= 3) {
          Colors.set(medal_colors[rank - 1]);
        } else {
          Colors.set(Colors.ELECTRIC_BLUE);
        }
        love.graphics.print(score_text, score_x, y);

        // Trophy for #1
        if (rank === 1 && podium_animation >= 0.5) {
          let trophy_x = GAME_WIDTH - 25;
          let trophy_y = y + 2;

          // Animate trophy with bounce
          let bounce = Math.abs(Math.sin(flash_timer * 4)) * 2;

          // Trophy
          draw_sprite("ui_trophy", trophy_x, Math.round(trophy_y - bounce));
        }
      }
    }
  },

  keypressed(key: string) {
    if (key === "escape") {
      StateManager.switch("menu");
    } else if (key === "tab") {
      // Switch between modes
      mode_selection = mode_selection === 1 ? 2 : 1;
      current_mode = mode_selection === 1 ? "time_trial" : "endless";
      podium_animation = 0; // Reset animation
    } else if (key === "left") {
      mode_selection = 1;
      current_mode = "time_trial";
      podium_animation = 0;
    } else if (key === "right") {
      mode_selection = 2;
      current_mode = "endless";
      podium_animation = 0;
    }
  },
};

export default HighScoresState;
