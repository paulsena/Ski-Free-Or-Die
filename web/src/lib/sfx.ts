// src/lib/sfx.ts
// Procedural sound effects system for Ski Free Or Die
// Uses shared audio synthesis primitives

import love, { type Source, type SoundData } from "../platform/love";
import AudioSynthesis from "./audio_synthesis";

// Audio settings (from shared module)
const SAMPLE_RATE = AudioSynthesis.SAMPLE_RATE;

// Import waveform generators
const square_wave = AudioSynthesis.square_wave;
const triangle_wave = AudioSynthesis.triangle_wave;
const sawtooth_wave = AudioSynthesis.sawtooth_wave;
const sine_wave = AudioSynthesis.sine_wave;
const noise_wave = AudioSynthesis.noise_wave;
const reset_noise = AudioSynthesis.reset_noise;

// Import envelope generators
const punchy_envelope = AudioSynthesis.punchy_envelope;
const quick_envelope = AudioSynthesis.quick_envelope;

// Import sample helpers
const normalize_samples = AudioSynthesis.normalize_samples;
const samples_to_sound_data = AudioSynthesis.samples_to_sound_data;

// SFX cache
let sfx_cache: Record<string, Source> = Object.create(null);
let is_initialized = false;

// Master volume for SFX
let master_volume = 0.5;

// Track active cloned sources to prevent memory accumulation
let active_sources: Source[] = [];

// Clean up finished audio sources to free memory
function cleanup_finished_sources(): void {
    for (let i = active_sources.length - 1; i >= 0; i--) {
        const source = active_sources[i];
        if (!source.isPlaying()) {
            // The WebAudio shim has no release(); dropping the reference permits GC.
            active_sources.splice(i, 1);
        }
    }
}

//------------------------------------------------------------------------------
// Sound effect generators
//------------------------------------------------------------------------------

// Generate ski loop sound - whooshing/sliding noise with rhythm
function generate_ski_loop() {
    let duration = 1.0; // 1 second loop
    let num_samples = Math.floor(duration * SAMPLE_RATE);
    let samples: number[] = [];

    reset_noise();

    // Create a rhythmic whooshing pattern
    for (let i = 0; i < num_samples; i++) {
        let t = i / SAMPLE_RATE;

        // Low frequency oscillation for rhythm (simulates ski strokes)
        let rhythm_freq = 2.5; // Hz
        let rhythm_phase = rhythm_freq * t;
        let rhythm_amp = 0.5 + 0.5 * Math.sin(rhythm_phase * 2 * Math.PI);

        // Filtered noise for snow sliding sound
        let noise = noise_wave();

        // Low-pass filter simulation (simple averaging)
        let cutoff_mod = 0.3 + 0.4 * rhythm_amp;
        let filtered = noise * cutoff_mod;

        // Add subtle low rumble
        let rumble_freq = 60 + 20 * rhythm_amp;
        let rumble = sine_wave(rumble_freq * t) * 0.15;

        // Combine
        let sample = filtered * 0.7 + rumble;

        // Envelope for smooth looping
        let loop_fade = 1.0;
        if (t < 0.05) {
            loop_fade = t / 0.05;
        } else if (t > duration - 0.05) {
            loop_fade = (duration - t) / 0.05;
        }

        samples[i] = sample * loop_fade * 0.5;
    }

    normalize_samples(samples, 0.6);
    return samples_to_sound_data(samples);
}

// Generate crash sound - big impact with noise burst
function generate_crash() {
    let duration = 0.4;
    let num_samples = Math.floor(duration * SAMPLE_RATE);
    let samples: number[] = [];

    reset_noise();

    for (let i = 0; i < num_samples; i++) {
        let t = i / SAMPLE_RATE;

        // Impact thud (descending pitch)
        let thud_freq = 120 * Math.exp(-t * 12) + 40;
        let thud = sine_wave(thud_freq * t) * punchy_envelope(t, duration);

        // Crash noise burst
        let noise = noise_wave();
        let noise_env = Math.exp(-t * 8); // Sharp decay
        let crash_noise = noise * noise_env;

        // High frequency "crunch"
        let crunch_freq = 800 + 400 * noise;
        let crunch = square_wave(crunch_freq * t, 0.3) * noise_env * 0.3;

        // Mix: heavy on thud, with noise texture
        samples[i] = thud * 0.6 + crash_noise * 0.3 + crunch * 0.1;
    }

    normalize_samples(samples, 0.95);
    return samples_to_sound_data(samples);
}

// Generate gate pass sound - bright positive chirp
function generate_gate_pass() {
    let duration = 0.15;
    let num_samples = Math.floor(duration * SAMPLE_RATE);
    let samples: number[] = [];

    for (let i = 0; i < num_samples; i++) {
        let t = i / SAMPLE_RATE;

        // Ascending chirp (sounds positive/successful)
        let start_freq = 800;
        let end_freq = 1600;
        let freq = start_freq + (end_freq - start_freq) * (t / duration);

        // Use square wave for bright 8-bit sound
        let wave = square_wave(freq * t, 0.5);

        // Quick punchy envelope
        let env = quick_envelope(t, duration);

        samples[i] = wave * env;
    }

    normalize_samples(samples, 0.7);
    return samples_to_sound_data(samples);
}

// Generate gate miss sound - negative descending buzz
function generate_gate_miss() {
    let duration = 0.25;
    let num_samples = Math.floor(duration * SAMPLE_RATE);
    let samples: number[] = [];

    for (let i = 0; i < num_samples; i++) {
        let t = i / SAMPLE_RATE;

        // Descending buzz (sounds negative/bad)
        let start_freq = 400;
        let end_freq = 120;
        let freq = start_freq + (end_freq - start_freq) * (t / duration);

        // Use sawtooth for harsher sound
        let wave = sawtooth_wave(freq * t);

        // Slightly longer envelope with decay
        let env = quick_envelope(t, duration);

        samples[i] = wave * env;
    }

    normalize_samples(samples, 0.7);
    return samples_to_sound_data(samples);
}

// Generate tree hit sound - medium impact with wood-like tone
function generate_tree_hit() {
    let duration = 0.2;
    let num_samples = Math.floor(duration * SAMPLE_RATE);
    let samples: number[] = [];

    reset_noise();

    for (let i = 0; i < num_samples; i++) {
        let t = i / SAMPLE_RATE;

        // Wood-like thump (mid-frequency impact)
        let thump_freq = 180 * Math.exp(-t * 10) + 80;
        let thump = sine_wave(thump_freq * t) * punchy_envelope(t, duration);

        // Wood crack noise
        let noise = noise_wave() * 0.3;
        let noise_env = Math.exp(-t * 15);

        samples[i] = thump * 0.7 + noise * noise_env * 0.3;
    }

    normalize_samples(samples, 0.75);
    return samples_to_sound_data(samples);
}

//------------------------------------------------------------------------------
// Cache management
//------------------------------------------------------------------------------

function get_or_generate_sfx(name: string): Source | undefined {
    if (sfx_cache[name]) {
        return sfx_cache[name];
    }

    let sound_data: SoundData | null = null;

    if (name === "ski_loop") {
        sound_data = generate_ski_loop();
    } else if (name === "crash") {
        sound_data = generate_crash();
    } else if (name === "gate_pass") {
        sound_data = generate_gate_pass();
    } else if (name === "gate_miss") {
        sound_data = generate_gate_miss();
    } else if (name === "tree_hit") {
        sound_data = generate_tree_hit();
    } else {
        return undefined;
    }

    if (sound_data) {
        sfx_cache[name] = love.audio.newSource(sound_data, "static");

        // Set looping only for ski loop
        if (name === "ski_loop") {
            sfx_cache[name].setLooping(true);
        }
    }

    return sfx_cache[name];
}

//------------------------------------------------------------------------------
// Public API
//------------------------------------------------------------------------------

const SFX = {
    // Initialize the SFX system
    load(): boolean {
        if (is_initialized) {
            return true;
        }

        try {
            // Pre-generate common sounds to avoid lag on first play
            get_or_generate_sfx("gate_pass");
            get_or_generate_sfx("gate_miss");
            is_initialized = true;
        } catch (err) {
            console.log("SFX system initialization warning: " + String(err));
            return false;
        }

        return true;
    },

    // Play a sound effect
    // @param sfx_name string: "ski_loop", "crash", "gate_pass", "gate_miss", "tree_hit"
    // @param volume number: optional volume override (0-1)
    play(sfx_name: string, volume?: number): void {
        if (!is_initialized) {
            SFX.load();
        }

        try {
            const source = get_or_generate_sfx(sfx_name);
            if (source) {
                // Clean up finished sources before creating new ones
                cleanup_finished_sources();

                // Clone the source for overlapping sounds (except ski_loop)
                let play_source = source;
                if (sfx_name !== "ski_loop") {
                    play_source = source.clone();
                    // Track the cloned source for later cleanup
                    active_sources.push(play_source);
                }

                const vol = volume ?? master_volume;
                play_source.setVolume(vol);
                play_source.play();
                // Lua returns the source only inside pcall; SFX.play returns nothing.
            }
        } catch (err) {
            console.log("SFX playback error: " + String(err));
        }
    },

    // Stop a looping sound (mainly for ski_loop)
    stop(sfx_name: string): void {
        const source = sfx_cache[sfx_name];
        if (source) {
            try {
                source.stop();
            } catch { /* pcall */ }
        }
    },

    // Stop all sounds
    stop_all(): void {
        // Stop cached sources
        for (const name in sfx_cache) {
            const source = sfx_cache[name];
            try {
                source.stop();
            } catch { /* pcall */ }
        }

        // Stop and release all active cloned sources
        for (let i = active_sources.length - 1; i >= 0; i--) {
            try {
                active_sources[i].stop();
                // Dropping the reference replaces LÖVE's explicit release().
            } catch { /* pcall */ }
            active_sources.splice(i, 1);
        }
    },

    // Set master volume for all SFX (0-1)
    set_volume(vol: number): void {
        master_volume = Math.max(0, Math.min(1, vol));
    },

    // Get current volume
    get_volume(): number {
        return master_volume;
    },

    // Pre-generate all sound effects (call during loading screen)
    preload_all(): void {
        if (!is_initialized) {
            SFX.load();
        }

        const sounds = ["ski_loop", "crash", "gate_pass", "gate_miss", "tree_hit"];
        for (const sound of sounds) {
            try {
                get_or_generate_sfx(sound);
            } catch { /* pcall */ }
        }
    },

    // Clear the SFX cache (useful for memory management)
    clear_cache(): void {
        SFX.stop_all();
        sfx_cache = Object.create(null);
        active_sources = [];
    },
};

export default SFX;
