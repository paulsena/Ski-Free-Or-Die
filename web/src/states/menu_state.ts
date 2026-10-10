// src/states/menu_state.ts
// Main menu state with 80s retro aesthetic

import love from "../platform/love";
import StateManager from "../core/state_manager";
import Colors from "../colors";
import Config from "../core/config";
import Music from "../lib/music";
import { fill_px } from "../gfx/sprite";

const GAME_WIDTH = Config.GAME_WIDTH;
const GAME_HEIGHT = Config.GAME_HEIGHT;

// Background image
let background_image: any = null;

// Fonts
let menu_font: any = null;
let hint_font: any = null;

// Animation variables
let snow_particles: any[] = [];
let menu_selection = 1;
let menu_options = ["Time Trial", "Endless Mode", "High Scores"];

// Mouse wheel dead zone
let wheel_accumulator = 0;
const WHEEL_THRESHOLD = 2; // Number of wheel clicks needed to move selection

const MenuState: { [key: string]: any } = {
  enter() {
    menu_selection = 1;
    wheel_accumulator = 0;

    // Load background image
    if (!background_image) {
      background_image = love.graphics.newImage("images/title_screen.png");
      background_image.setFilter("nearest", "nearest");
    }

    // Create fonts
    if (!menu_font) {
      menu_font = love.graphics.newFont(16);
      hint_font = love.graphics.newFont(10);
    }

    // Initialize falling snow particles for overlay effect
    snow_particles = [];
    for (let i = 1; i <= 20; i += 1) {
      snow_particles.push({
        x: Math.floor(Math.random() * (GAME_WIDTH + 1)),
        y: Math.floor(Math.random() * (GAME_HEIGHT + 1)),
        speed: (15 + Math.floor(Math.random() * 21)),
        size: (1 + Math.floor(Math.random() * 2))
      });
    }

    // Play menu music
    Music.play("menu");
  },

  update(dt: number) {
    // Update snow particles
    for (const p of snow_particles) {
      p.y = p.y + p.speed * dt;
      p.x = p.x + Math.sin(p.y * 0.05) * 0.5;
      if (p.y > GAME_HEIGHT) {
        p.y = -5;
        p.x = Math.floor(Math.random() * (GAME_WIDTH + 1));
      }
    }
  },

  draw() {
    // Draw background image scaled to fit game window
    love.graphics.setColor(1, 1, 1);
    let img_width = background_image.getWidth();
    let img_height = background_image.getHeight();
    let scale_x = GAME_WIDTH / img_width;
    let scale_y = GAME_HEIGHT / img_height;
    love.graphics.draw(background_image, 0, 0, 0, scale_x, scale_y);

    // Draw subtle snow particles overlay
    for (const p of snow_particles) {
      fill_px("W", Math.round(p.x), Math.round(p.y), p.size, p.size);
    }

    // Draw menu options with drop shadows (positioned in lower portion of image)
    love.graphics.setFont(menu_font);
    let menu_start_y = 355;
    for (let i = 1; i <= menu_options.length; i++) {
      const option = menu_options[i - 1];
      let y = menu_start_y + (i - 1) * 28;
      let is_selected = (i === menu_selection);
      // Selection arrows sit just outside the (centered) option text
      let text_w = menu_font.getWidth(option);
      let arrow_l = Math.floor((GAME_WIDTH - text_w) / 2) - 18;
      let arrow_r = Math.floor((GAME_WIDTH + text_w) / 2) + 8;

      // Draw thick outline/shadow (multiple passes for bold shadow)
      love.graphics.setColor(0, 0, 0, 1);
      for (let ox = -2; ox <= 2; ox += 1) {
        for (let oy = -2; oy <= 2; oy += 1) {
          if (ox !== 0 || oy !== 0) {
            love.graphics.printf(option, ox, y + oy, GAME_WIDTH, "center");
          }
        }
      }

      // Draw selection arrows with outline
      if (is_selected) {
        love.graphics.setColor(0, 0, 0, 1);
        for (let ox = -2; ox <= 2; ox += 1) {
          for (let oy = -2; oy <= 2; oy += 1) {
            if (ox !== 0 || oy !== 0) {
              love.graphics.print(">", arrow_l + ox, y + oy);
              love.graphics.print("<", arrow_r + ox, y + oy);
            }
          }
        }
      }

      // Draw main text
      if (is_selected) {
        Colors.set(Colors.BRIGHT_YELLOW);
        love.graphics.print(">", arrow_l, y);
        love.graphics.print("<", arrow_r, y);
      } else {
        Colors.set(Colors.SNOW_WHITE);
      }
      love.graphics.printf(option, 0, y, GAME_WIDTH, "center");
    }

    // Draw controls hint on a solid ink bar (an outline would clog the 1x pixel font)
    love.graphics.setFont(hint_font);
    let hint_y = 457;
    fill_px("K", 0, hint_y - 4, GAME_WIDTH, 15);
    Colors.set(Colors.SNOW_WHITE);
    love.graphics.printf("Mouse: Steer | Click: Tuck | M: Mute", 0, hint_y, GAME_WIDTH, "center");
  },

  keypressed(key: string) {
    if (key === "up" || key === "w") {
      menu_selection = menu_selection - 1;
      if (menu_selection < 1) {
        menu_selection = menu_options.length;
      }
    } else if (key === "down" || key === "s") {
      menu_selection = menu_selection + 1;
      if (menu_selection > menu_options.length) {
        menu_selection = 1;
      }
    } else if (key === "return" || key === "space") {
      this.select_option();
    } else if (key === "m") {
      // Toggle mute
      if (Music.get_volume() > 0) {
        Music.set_volume(0);
      } else {
        Music.set_volume(0.7);
      }
    }
  },

  mousepressed(x: number, y: number, button: number) {
    if (button === 1) { // Left click

      // Check if click is on a menu item
      let menu_start_y = 355;
      let item_height = 28;
      let font_height = 16;
      for (let i = 1; i <= menu_options.length; i += 1) {
        let item_y = menu_start_y + (i - 1) * item_height;

        // Check if click is within this menu item's bounds
        if (y >= item_y && y <= item_y + font_height) {
          menu_selection = i;
          this.select_option();
          return;
        }
      }
    }
  },

  wheelmoved(x: number, y: number) {
    wheel_accumulator = wheel_accumulator + y;
    if (wheel_accumulator >= WHEEL_THRESHOLD) {
      // Scroll up
      menu_selection = menu_selection - 1;
      if (menu_selection < 1) {
        menu_selection = menu_options.length;
      }
      wheel_accumulator = 0;
    } else if (wheel_accumulator <= -WHEEL_THRESHOLD) {
      // Scroll down
      menu_selection = menu_selection + 1;
      if (menu_selection > menu_options.length) {
        menu_selection = 1;
      }
      wheel_accumulator = 0;
    }
  },

  select_option() {
    if (menu_selection === 1) {
      // Start Game (Time Trial)
      StateManager.switch("play", { mode: "time_trial" });
    } else if (menu_selection === 2) {
      // Endless Mode
      StateManager.switch("play", { mode: "endless" });
    } else if (menu_selection === 3) {
      // High Scores
      StateManager.switch("highscores");

    }
  },
};

export default MenuState;
