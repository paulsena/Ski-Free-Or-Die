// src/core/leaderboard.ts
// Arcade-style high score tracking and persistence

import love from "../platform/love";
import Utils from "../lib/utils";

const SAVE_FILE = "highscores.dat";
const MAX_SCORES = 10;

type ScoreEntry = {name: string; score: number; mode: string; is_new: boolean; timestamp: number};

// Structure: { name = "ABC", score = 12345, mode = "time_trial" or "endless", is_new = false }
const scores: Record<string, ScoreEntry[]> = {
    time_trial: [],
    endless: []
};

//------------------------------------------------------------------------------
// Helper functions
//------------------------------------------------------------------------------

// Calculate score for time trial mode (lower is better, so invert)
// Score = 1000000 - (time_in_seconds * 1000)
function calculate_time_trial_score(time: number, gates_missed: number): number {
    const total_time = time + (gates_missed * 3);
    // Lower time = higher score
    return Math.floor(1000000 - (total_time * 1000));
}

// Calculate score for endless mode (higher distance is better)
function calculate_endless_score(distance: number): number {
    // Distance in pixels / 10 = meters
    return Math.floor(distance / 10);
}

// Sort scores in descending order (higher = better)
function sort_scores(mode_scores: ScoreEntry[]): void {
    mode_scores.sort((a, b) => b.score - a.score);
}

//------------------------------------------------------------------------------
// Persistence
//------------------------------------------------------------------------------

// Save scores to file
function save_scores(): boolean {
    try {
        const save_data = {
            version: 1,
            time_trial: scores.time_trial,
            endless: scores.endless
        };
        const serialized = Utils.serialize(save_data);
        love.filesystem.write(SAVE_FILE, serialized);
        return true;
    } catch (result) {
        console.log("Failed to save high scores: " + String(result));
        return false;
    }
}

// Load scores from file
function load_scores(): void {
    if (!love.filesystem.getInfo(SAVE_FILE)) {
        // No save file yet, use empty scores
        return;
    }
    try {
        const data = love.filesystem.read(SAVE_FILE);
        const save_data = Utils.deserialize(data);
        if (save_data && save_data.version === 1) {
            scores.time_trial = save_data.time_trial === false ? [] : (save_data.time_trial ?? []);
            scores.endless = save_data.endless === false ? [] : (save_data.endless ?? []);
        }
    } catch (result) {
        console.log("Failed to load high scores: " + String(result));
    }
}

//------------------------------------------------------------------------------
// Public API
//------------------------------------------------------------------------------

const Leaderboard = {
    // Initialize the leaderboard system
    init(): void { load_scores(); },

    // Check if a score qualifies for the leaderboard
    // @param mode string: "time_trial" or "endless"
    // @param score number: the calculated score
    // @return boolean, number: (qualifies, rank) - rank is 1-10 if qualifies, nil otherwise
    qualifies(mode: string, score: number): [boolean, number | undefined] {
        const mode_scores = scores[mode];
        if (mode_scores.length < MAX_SCORES) {
            // Not full yet, always qualifies
            return [true, mode_scores.length + 1];
        }
        // Check if score beats the lowest score
        if (score > mode_scores[MAX_SCORES - 1].score) {
            // Find the rank
            for (const [i, entry] of mode_scores.entries()) {
                if (score > entry.score) return [true, i + 1];
            }
        }
        return [false, undefined];
    },

    // Add a score to the leaderboard
    // @param mode string: "time_trial" or "endless"
    // @param name string: player initials/name (max 3-8 chars)
    // @param score number: the calculated score
    // @return number: rank (1-10) where the score was inserted
    add(mode: string, name: string, score: number): number | undefined {
        const mode_scores = scores[mode];
        // Create new entry
        const entry = {name: name, score: score, mode: mode, is_new: true, timestamp: Math.floor(Date.now() / 1000)};
        // Insert into list
        mode_scores.push(entry);
        // Sort
        sort_scores(mode_scores);
        // Trim to MAX_SCORES
        while (mode_scores.length > MAX_SCORES) mode_scores.pop();
        // Find rank
        let rank: number | undefined;
        for (const [i, e] of mode_scores.entries()) {
            if (e === entry) {
                rank = i + 1;
                break;
            }
        }
        // Save to disk
        save_scores();
        return rank;
    },

    // Get all scores for a mode
    // @param mode string: "time_trial" or "endless"
    // @return table: array of score entries
    get_scores(mode: string): ScoreEntry[] { return scores[mode]; },

    // Clear the "is_new" flag from all scores (call when leaving high score screen)
    clear_new_flags(): void {
        for (const mode in scores) {
            const mode_scores = scores[mode];
            for (const entry of mode_scores) entry.is_new = false;
        }
    },

    // Calculate score from game stats
    // @param mode string: "time_trial" or "endless"
    // @param stats table: {time, distance, gates_passed, gates_missed, ...}
    // @return number: the calculated score
    calculate_score(mode: string, stats: any): number {
        if (mode === "time_trial") return calculate_time_trial_score(stats.time, stats.gates_missed);
        else if (mode === "endless") return calculate_endless_score(stats.distance);
        return 0;
    },

    // Get a human-readable score display
    // @param mode string: "time_trial" or "endless"
    // @param score number: the score value
    // @return string: formatted score string
    format_score(mode: string, score: number): string {
        if (mode === "time_trial") {
            // Convert back to time
            const time_seconds = (1000000 - score) / 1000;
            const minutes = Math.floor(time_seconds / 60);
            const seconds = time_seconds - Math.floor(time_seconds / 60) * 60;
            return `${minutes}:${seconds.toFixed(2).padStart(5, "0")}`;
        } else if (mode === "endless") {
            return `${score}m`;
        }
        return String(score);
    },

    // Clear all scores (for debugging/testing)
    clear_all(): void {
        scores.time_trial = [];
        scores.endless = [];
        save_scores();
    },

    // Populate with dummy data for testing
    add_test_data(): void {
        // Time trial scores (times in seconds)
        const test_times = [
            {name: "ACE", time: 45.2, gates_missed: 0},
            {name: "BOB", time: 48.5, gates_missed: 1},
            {name: "CAT", time: 52.0, gates_missed: 0},
            {name: "DAN", time: 55.8, gates_missed: 2},
            {name: "EVE", time: 58.3, gates_missed: 1}
        ];
        for (const entry of test_times) {
            const score = calculate_time_trial_score(entry.time, entry.gates_missed);
            Leaderboard.add("time_trial", entry.name, score);
        }
        // Endless mode scores (distances in meters)
        const test_distances = [
            {name: "ZEN", distance: 5000},
            {name: "YAK", distance: 4200},
            {name: "WAX", distance: 3800},
            {name: "VIK", distance: 3200},
            {name: "UFO", distance: 2800}
        ];
        for (const entry of test_distances) Leaderboard.add("endless", entry.name, entry.distance);
    }
};

export default Leaderboard;
