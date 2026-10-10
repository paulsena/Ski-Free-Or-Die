// src/core/config.ts
// Centralized game configuration

const Config = {
  // Display settings (3:4 portrait ratio for vertical skiing view)
  GAME_WIDTH: 360,
  GAME_HEIGHT: 480,
  SCALE: 3,
  SIDEBAR_WIDTH: 400,
  // Physics (scaled for 360x480 resolution)
  BASE_SPEED: 140,
  MAX_SPEED: 320,

  // Weekly seed (would be fetched from server in production)
  WEEKLY_SEED: 20251225, // Christmas 2025!

  // Difficulty settings
  DIFFICULTY_INCREASE_RATE: 0.5, // Per 5000 pixels
  MAX_DIFFICULTY: 2.0,

  // Yeti settings (scaled for 360x480 resolution)
  YETI_START_DISTANCE: 600,
  YETI_BASE_SPEED: 100,
  YETI_SPEED_INCREASE_RATE: 0.01,

  // Gate settings (scaled for 360x480 resolution)
  GATE_PENALTY: 3, // Seconds added for missed gate
  GATE_WIDTH: 75,

  // Spawn settings (scaled for 360x480 resolution)
  SPAWN_AHEAD: 550,
  DESPAWN_BEHIND: 300,

  // Get a deterministic seed for the current week
  get_weekly_seed(date: Date = new Date()): number {
    // In production, this would fetch from a server
    // For now, use a simple formula based on date (matches os.date("*t").yday)
    const year = date.getFullYear();
    const start = new Date(year, 0, 1);
    const day_of_year = Math.floor((date.getTime() - start.getTime()) / 86400000) + 1;
    const week = Math.ceil(day_of_year / 7);
    return year * 100 + week;
  },
};

export default Config;
