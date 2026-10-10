// src/states/play_state.ts
// Main gameplay state - uses modular entity system

import love from "../platform/love";
import { fill_px } from "../gfx/sprite";
import Skier from "../entities/skier";
import Utils from "../lib/utils";
import Camera from "../lib/camera";
import Colors from "../colors";
import WorldManager from "../world/world_manager";
import Yeti from "../entities/yeti";
import Config from "../core/config";
import Music from "../lib/music";
import SFX from "../lib/sfx";
import Particles from "../systems/particles";
import Collision from "../systems/collision";
import Leaderboard from "../core/leaderboard";
import StateManager from "../core/state_manager";

const GAME_WIDTH = Config.GAME_WIDTH;
const GAME_HEIGHT = Config.GAME_HEIGHT;

// Collision detection radius for nearby obstacle checks
const COLLISION_CHECK_RADIUS = 50;

const PlayState: { [key: string]: any } = {
  enter(params: any) {
    this.mode = params?.mode ?? "trial";

    // Initialize camera
    this.camera = Camera.new();
    this.camera.set_offset(GAME_WIDTH / 2, GAME_HEIGHT * 0.3);

    // Initialize skier
    this.skier = Skier.new(0, 0);
    this.prev_skier_y = 0;

    // Initialize world with mode for tile-based generation
    let world_mode = this.mode === "endless" ? "endless" : "time_trial";
    this.world = WorldManager.new(undefined, world_mode);
    this.world.initial_spawn();

    // Initialize game state
    this.elapsed_time = 0;
    this.distance = 0;
    this.gates_passed = 0;
    this.gates_missed = 0;
    this.is_paused = false;
    this.is_finished = false;

    // Particles system
    this.particles = Particles.new();

    // Endless mode specific - Yeti
    if (this.mode === "endless") {
      this.yeti = Yeti.new();
    } else {
      this.yeti = null;
    }

    // Track previous input for particles
    this.was_turning = false;

    // Snap camera to start position
    this.camera.set_target(this.skier.x, this.skier.y);
    this.camera.snap();

    // Initialize audio
    SFX.load();

    // Play gameplay music
    Music.play("gameplay");
  },

  exit() {
    // Stop all sound effects
    SFX.stop_all();
  },

  update(dt: number) {
    if (this.is_paused || this.is_finished) {
      return;
    }

    // Update timer
    this.elapsed_time = this.elapsed_time + dt;

    // Store previous position for gate checking
    this.prev_skier_y = this.skier.y;

    // Handle input and update skier
    // Pass skier's screen X position (center of game width) for mouse control
    let skier_screen_x = GAME_WIDTH / 2;
    this.skier.handle_input(dt, skier_screen_x);
    this.skier.update(dt, this.world.get_slope_bounds());

    // Update camera
    this.camera.set_target(this.skier.x, this.skier.y);
    this.camera.update(dt);

    // Update world (spawning/despawning)
    this.world.update(dt, this.skier.y);

    // Check collisions
    this.check_collisions();

    // Check gates
    this.check_gates();

    // Check finish line for time trial mode
    if (this.mode === "time_trial" && this.world.check_finish(this.skier.y)) {
      this.game_over("finished");
    }

    // Update distance
    this.distance = this.skier.y;

    // Update particles
    this.particles.update(dt);

    // Emit snow spray particles while skiing
    // Check if turning based on skier position (not center = turning)
    let is_turning = this.skier.position !== Skier.POS_CENTER;
    if (!this.skier.is_crashed) {
      this.particles.emit_snow_spray(this.skier.x, this.skier.y, this.skier.get_angle(), this.skier.speed, is_turning);
    }
    this.was_turning = is_turning;

    // Endless mode: update yeti
    if (this.yeti) {
      let caught = this.yeti.update(dt, this.skier.speed, this.skier.is_crashed);
      if (caught) {
        this.game_over("caught");
      }
    }
  },

  check_collisions() {
    if (this.skier.is_crashed || this.skier.is_immune) {
      return;
    }
    let nearby = Collision.get_nearby_obstacles(this.skier, this.world.get_obstacles(), COLLISION_CHECK_RADIUS);
    let hit_obstacle = Collision.check_skier_obstacles(this.skier, nearby);
    if (hit_obstacle) {
      Collision.resolve_obstacle_collision(this.skier, hit_obstacle, this.camera);

      // Emit particles and play sounds based on collision type
      if (hit_obstacle.collision_type === "crash") {
        this.particles.emit_crash(this.skier.x, this.skier.y);
        SFX.play("crash");
      } else {
        // Minor impact particles and sound
        this.particles.emit(this.skier.x, this.skier.y, "impact_snow", 5);
        SFX.play("tree_hit");
      }
    }
  },

  check_gates() {
    const [passed, missed] = Collision.check_skier_gates(this.skier, this.prev_skier_y, this.world.get_gates());
    this.gates_passed = this.gates_passed + passed;
    this.gates_missed = this.gates_missed + missed;

    // Emit gate particles and play sounds
    if (passed > 0) {
      this.particles.emit_gate_pass(this.skier.x, this.skier.y, true);
      SFX.play("gate_pass");
    }
    if (missed > 0) {
      this.particles.emit_gate_pass(this.skier.x, this.skier.y, false);
      SFX.play("gate_miss");
    }
  },

  game_over(reason: string) {
    this.is_finished = true;
    this.game_over_reason = reason;

    // Play game over music
    Music.play("gameover");
  },

  draw() {
    this.camera.apply();

    // Draw slope/snow background
    this.draw_slope();

    // Draw world objects (gates and obstacles)
    this.world.draw(this.skier.y);

    // Draw particles (behind skier)
    this.particles.draw();

    // Draw skier
    this.skier.draw();
    this.camera.reset();

    // Draw yeti if in endless mode (in screen space, after camera reset)
    if (this.yeti) {
      this.yeti.draw(this.camera.y, GAME_HEIGHT);
    }

    // Draw crash indicator (important gameplay feedback)
    if (this.skier.is_crashed) {
      Colors.set(Colors.HOT_PINK);
      let crash_text = "CRASHED!";
      if (this.skier.crash_timer > 0) {
        crash_text = `CRASHED! ${(this.skier.crash_timer).toFixed(1)}`;
      }
      love.graphics.printf(crash_text, 0, GAME_HEIGHT / 2 - 6, GAME_WIDTH, "center");
    }

    // Draw yeti warning in endless mode
    if (this.mode === "endless") {
      this.draw_yeti_warning();
    }

    // Draw game over overlay
    if (this.is_finished) {
      this.draw_game_over();
    }

    // Draw pause overlay
    if (this.is_paused) {
      this.draw_pause();
    }
  },

  draw_slope() {
    let visible_top = this.camera.y - GAME_HEIGHT;
    let visible_bottom = this.camera.y + GAME_HEIGHT;

    // Draw snow ground
    fill_px("S", -WorldManager.SLOPE_WIDTH - 50, visible_top, (WorldManager.SLOPE_WIDTH + 50) * 2, visible_bottom - visible_top + 200);

    // Draw ski track marks (decorative)
    let track_spacing = 40;
    let track_start = Math.floor(visible_top / track_spacing) * track_spacing;
    for (let y = track_start; y <= visible_bottom; y += track_spacing) {
      for (let row = 0; row <= 25; row++) {
        let left_x = Math.round(-100 + 5 * row / 25);
        let right_x = Math.round(100 - 5 * row / 25);
        fill_px("s", left_x, y + row, 1, 1);
        fill_px("s", left_x + 3, y + row, 1, 1);
        fill_px("s", right_x, y + row, 1, 1);
        fill_px("s", right_x + 3, y + row, 1, 1);
      }
    }

    // Draw slope edge markers (rope lines)
    fill_px("w", -WorldManager.SLOPE_WIDTH - 5, visible_top, 3, visible_bottom - visible_top + 200);
    fill_px("w", WorldManager.SLOPE_WIDTH + 2, visible_top, 3, visible_bottom - visible_top + 200);

    // Draw slope markers (distance indicators)
    let marker_spacing = 100;
    let marker_start = Math.floor(visible_top / marker_spacing) * marker_spacing;
    for (let y = marker_start; y <= visible_bottom; y += marker_spacing) {
      fill_px("R", -WorldManager.SLOPE_WIDTH - 12, y - 2, 8, 4);
      fill_px("R", WorldManager.SLOPE_WIDTH + 4, y - 2, 8, 4);
    }
  },

  draw_yeti_warning() {
    if (!this.yeti) {
      return;
    }

    // Use Yeti's built-in danger overlay
    this.yeti.draw_danger_overlay(GAME_WIDTH, GAME_HEIGHT);
    let zone = this.yeti.get_danger_zone();
    if (zone === "danger" || zone === "critical") {
      // Warning text
      Colors.set(Colors.HOT_PINK);
      let flash = Math.floor(this.elapsed_time * 4) % 2 === 0;
      if (flash) {
        let text = zone === "critical" ? "YETI ALMOST HERE!" : "YETI APPROACHING!";
        love.graphics.printf(text, 0, 20, GAME_WIDTH, "center");
      }
    }

    // Yeti distance indicator
    love.graphics.setColor(0, 0, 0, 0.6);
    love.graphics.rectangle("fill", GAME_WIDTH - 60, 16, 56, 10);
    Colors.set(Colors.SNOW_WHITE);
    love.graphics.print(`Yeti: ${Math.floor(-this.yeti.distance / 10)}m`, GAME_WIDTH - 58, 17);
  },

  draw_game_over() {
    // Overlay
    love.graphics.setColor(0, 0, 0, 0.8);
    love.graphics.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT);

    // Title
    if (this.game_over_reason === "caught") {
      Colors.set(Colors.HOT_PINK);
      love.graphics.printf("EATEN BY YETI!", 0, 40, GAME_WIDTH, "center");
    } else if (this.game_over_reason === "finished") {
      Colors.set(Colors.MINT_GREEN);
      love.graphics.printf("TIME TRIAL COMPLETE!", 0, 40, GAME_WIDTH, "center");
    } else {
      Colors.set(Colors.HOT_PINK);
      love.graphics.printf("RUN COMPLETE!", 0, 40, GAME_WIDTH, "center");
    }

    // Stats
    Colors.set(Colors.SNOW_WHITE);
    let y = 65;
    love.graphics.printf(`Distance: ${Math.floor(this.distance / 10)}m`, 0, y, GAME_WIDTH, "center");
    y = y + 15;
    love.graphics.printf(`Time: ${Utils.format_time(this.elapsed_time)}`, 0, y, GAME_WIDTH, "center");
    y = y + 15;
    love.graphics.printf(`Gates: ${this.gates_passed} passed, ${this.gates_missed} missed`, 0, y, GAME_WIDTH, "center");
    y = y + 15;
    if (this.gates_missed > 0) {
      Colors.set(Colors.HOT_PINK);
      love.graphics.printf(`Penalty: +${this.gates_missed * 3} seconds`, 0, y, GAME_WIDTH, "center");
      y = y + 15;
    }
    Colors.set(Colors.BRIGHT_YELLOW);
    let final_time = this.elapsed_time + this.gates_missed * 3;
    love.graphics.printf(`Final Time: ${Utils.format_time(final_time)}`, 0, y + 10, GAME_WIDTH, "center");

    // Restart prompt
    Colors.set(Colors.MINT_GREEN);
    love.graphics.printf("ENTER: Continue | R: Restart | ESC: Menu", 0, GAME_HEIGHT - 25, GAME_WIDTH, "center");
  },

  draw_pause() {
    // Overlay
    love.graphics.setColor(0, 0, 0, 0.7);
    love.graphics.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT);

    // Pause text
    Colors.set(Colors.BRIGHT_YELLOW);
    love.graphics.printf("PAUSED", 0, GAME_HEIGHT / 2 - 20, GAME_WIDTH, "center");
    Colors.set(Colors.SNOW_WHITE);
    love.graphics.printf("ESC: Resume", 0, GAME_HEIGHT / 2 + 5, GAME_WIDTH, "center");
    love.graphics.printf("R: Restart", 0, GAME_HEIGHT / 2 + 20, GAME_WIDTH, "center");
    Colors.set(Colors.HOT_PINK);
    love.graphics.printf("Q: Quit to Menu", 0, GAME_HEIGHT / 2 + 35, GAME_WIDTH, "center");
  },

  keypressed(key: string) {
    if (key === "r") {
      // Restart
      this.enter({ mode: this.mode });
    } else if ((key === "p" || key === "escape") && !this.is_finished) {
      this.is_paused = !this.is_paused;

      // Pause/resume music
      if (this.is_paused) {
        Music.pause();
      } else {
        Music.resume();
      }
    } else if (key === "q" && this.is_paused) {
      // Quit to menu from pause screen
      StateManager.switch("menu");
    } else if (key === "m") {
      // Toggle mute
      if (Music.get_volume() > 0) {
        Music.set_volume(0);
      } else {
        Music.set_volume(0.7);
      }
    } else if (key === "return" && this.is_finished) {
      // Check for high score on enter
      this.check_high_score();
    }
  },

  check_high_score() {
    // Calculate score based on game mode
    let stats = {
      time: this.elapsed_time,
      distance: this.distance,
      gates_passed: this.gates_passed,
      gates_missed: this.gates_missed
    };
    let score = Leaderboard.calculate_score(this.mode, stats);
    const [qualifies, rank] = Leaderboard.qualifies(this.mode, score);
    if (qualifies) {
      // Go to name entry screen
      StateManager.switch("name_entry", {
        mode: this.mode,
        score: score,
        rank: rank,
        stats: stats
      });
    } else {
      // Just go to high scores screen
      StateManager.switch("highscores", { mode: this.mode });
    }
  },
};

export default PlayState;
