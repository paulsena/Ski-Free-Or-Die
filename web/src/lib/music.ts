// src/lib/music.ts
// Procedural 80s chiptune music synthesis system
// Think OutRun, California Games, Top Gear SNES vibes

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
const pulse_wave = AudioSynthesis.pulse_wave;
const reset_noise = AudioSynthesis.reset_noise;

// Import envelope generators
const adsr_envelope = AudioSynthesis.adsr_envelope;
const punchy_envelope = AudioSynthesis.punchy_envelope;
const stab_envelope = AudioSynthesis.stab_envelope;
const lead_envelope = AudioSynthesis.lead_envelope;
const hihat_envelope = AudioSynthesis.hihat_envelope;

// Import sample helpers
const normalize_samples = AudioSynthesis.normalize_samples;
const samples_to_sound_data = AudioSynthesis.samples_to_sound_data;

// Music state
let current_source: Source | null = null;
let current_track: string | null = null;
let master_volume = 0.4;
let is_initialized = false;

// Note frequencies (A4 = 440Hz tuning)
const NOTES: Record<string, number> = {
    C2: 65.41, D2: 73.42, E2: 82.41, F2: 87.31, G2: 98.00, A2: 110.00, B2: 123.47,
    C3: 130.81, D3: 146.83, E3: 164.81, F3: 174.61, G3: 196.00, A3: 220.00, B3: 246.94,
    C4: 261.63, D4: 293.66, E4: 329.63, F4: 349.23, G4: 392.00, A4: 440.00, B4: 493.88,
    C5: 523.25, D5: 587.33, E5: 659.26, F5: 698.46, G5: 783.99, A5: 880.00, B5: 987.77,
    C6: 1046.50, D6: 1174.66, E6: 1318.51,
    REST: 0
};

// Add sharp/flat notes
NOTES["C#3"] = 138.59; NOTES["D#3"] = 155.56; NOTES["F#3"] = 185.00; NOTES["G#3"] = 207.65; NOTES["A#3"] = 233.08;
NOTES["C#4"] = 277.18; NOTES["D#4"] = 311.13; NOTES["F#4"] = 369.99; NOTES["G#4"] = 415.30; NOTES["A#4"] = 466.16;
NOTES["C#5"] = 554.37; NOTES["D#5"] = 622.25; NOTES["F#5"] = 739.99; NOTES["G#5"] = 830.61; NOTES["A#5"] = 932.33;


//------------------------------------------------------------------------------
// Sound synthesis helpers
//------------------------------------------------------------------------------

// Generate a note with a specific waveform
function generate_note(freq: number, duration: number, samples_per_sec: number,
    wave_func: (phase: number, width?: number) => number,
    envelope_func: (t: number, duration: number) => number,
    volume = 1.0, extra_params: { width?: number; duty?: number } = {}): number[] {
    const samples: number[] = [];
    const num_samples = Math.floor(duration * samples_per_sec);

    for (let i = 0; i < num_samples; i++) {
        const t = i / samples_per_sec;
        const phase = freq * t;
        const envelope = envelope_func(t, duration);
        let sample = 0;

        if (freq > 0) {
            sample = wave_func(phase, extra_params.width ?? extra_params.duty) * envelope * volume;
        }

        samples.push(sample);
    }

    return samples;
}

// Mix multiple sample arrays together
function mix_samples(...arrays: number[][]): number[] {
    let max_len = 0;
    for (const arr of arrays) {
        max_len = Math.max(max_len, arr.length);
    }

    const result: number[] = [];
    for (let i = 0; i < max_len; i++) {
        let sum = 0;
        for (const arr of arrays) {
            sum = sum + (arr[i] ?? 0);
        }
        result[i] = sum;
    }

    return result;
}

// Append samples to an array
function append_samples(dest: number[], src: number[]): void {
    for (const sample of src) {
        dest.push(sample);
    }
}

// Add reverb/delay effect
function add_delay(samples: number[], delay_time = 0.1, decay = 0.3, mix = 0.3): number[] {
    const delay_samples = Math.floor(delay_time * SAMPLE_RATE);
    const result: number[] = [];

    for (let i = 0; i < samples.length; i++) {
        let delayed = 0;
        if (i >= delay_samples) {
            delayed = samples[i - delay_samples] * decay;
        }
        result[i] = samples[i] + delayed * mix;
    }

    return result;
}

//------------------------------------------------------------------------------
// Track generators
//------------------------------------------------------------------------------

// Generate menu theme - chill but energetic, synth arpeggios
function generate_menu_theme() {
    let bpm = 110;
    let beat_duration = 60 / bpm;
    let bar_duration = beat_duration * 4;
    let loop_bars = 8;

    let total_samples = Math.floor(loop_bars * bar_duration * SAMPLE_RATE);

    // Initialize all channels
    let bass_samples: number[] = [];
    let lead_samples: number[] = [];
    let pad_samples: number[] = [];
    let arp_samples: number[] = [];
    let drums_samples: number[] = [];

    for (let i = 0; i < total_samples; i++) {
        bass_samples[i] = 0;
        lead_samples[i] = 0;
        pad_samples[i] = 0;
        arp_samples[i] = 0;
        drums_samples[i] = 0;
    }

    reset_noise();

    // Chord progression (Am - F - C - G pattern in A minor)
    const chords = [
        [NOTES.A3, NOTES.C4, NOTES.E4], // Am
        [NOTES.F3, NOTES.A3, NOTES.C4], // F
        [NOTES.C4, NOTES.E4, NOTES.G4], // C
        [NOTES.G3, NOTES.B3, NOTES.D4], // G
        [NOTES.A3, NOTES.C4, NOTES.E4], // Am
        [NOTES.F3, NOTES.A3, NOTES.C4], // F
        [NOTES.E3, NOTES.G3, NOTES.B3], // Em
        [NOTES.E3, NOTES.G3, NOTES.B3], // Em (resolve)
    ];

    // Bass line - root notes on beat 1 and 3
    const bass_notes = [
        NOTES.A3, NOTES.F3, NOTES.C3, NOTES.G3,
        NOTES.A3, NOTES.F3, NOTES.E3, NOTES.E3
    ];

    for (let bar = 0; bar <= loop_bars - 1; bar++) {
        let bar_start = bar * bar_duration;
        let bass_note = bass_notes[bar] / 2; // One octave lower

        // Bass on beats 1 and 3
        for (let beat = 0; beat <= 1; beat++) {
            let note_start = Math.floor((bar_start + beat * 2 * beat_duration) * SAMPLE_RATE);
            let note = generate_note(bass_note, beat_duration * 0.9, SAMPLE_RATE, triangle_wave, punchy_envelope, 0.5);

            for (let j = 0; j < note.length; j++) {
                const s = note[j];
                let idx = note_start + j;
                if (idx >= 0 && idx < total_samples) {
                    bass_samples[idx] = bass_samples[idx] + s;
                }
            }
        }

        // Arpeggiated chord pattern (16th notes)
        let chord = chords[bar];
        const arp_pattern = [1, 2, 3, 2, 1, 3, 2, 3, 1, 2, 3, 2, 1, 3, 2, 1]; // 16 steps per bar
        let sixteenth = beat_duration / 4;

        for (let step = 0; step <= 15; step++) {
            let note_idx = arp_pattern[step];
            let freq = chord[note_idx - 1];
            let note_start = Math.floor((bar_start + step * sixteenth) * SAMPLE_RATE);
            let note = generate_note(freq * 2, sixteenth * 0.7, SAMPLE_RATE, pulse_wave, stab_envelope, 0.25, {width: 0.25});

            for (let j = 0; j < note.length; j++) {
                const s = note[j];
                let idx = note_start + j;
                if (idx >= 0 && idx < total_samples) {
                    arp_samples[idx] = arp_samples[idx] + s;
                }
            }
        }

        // Simple pad chords (held notes)
        for (const freq of chord) {
            let note_start = Math.floor(bar_start * SAMPLE_RATE);
            let note = generate_note(freq, bar_duration * 0.95, SAMPLE_RATE, sine_wave, lead_envelope, 0.15);

            for (let j = 0; j < note.length; j++) {
                const s = note[j];
                let idx = note_start + j;
                if (idx >= 0 && idx < total_samples) {
                    pad_samples[idx] = pad_samples[idx] + s;
                }
            }
        }

        // Drums: kick on 1/3, hi-hat on 8ths
        for (let beat = 0; beat <= 3; beat++) {
            let beat_start = bar_start + beat * beat_duration;

            // Hi-hat on every 8th note
            for (let eighth = 0; eighth <= 1; eighth++) {
                let hh_start = Math.floor((beat_start + eighth * beat_duration / 2) * SAMPLE_RATE);
                let hh_len = Math.floor(beat_duration * 0.05 * SAMPLE_RATE);

                reset_noise();
                for (let j = 0; j < hh_len; j++) {
                    let t = j / SAMPLE_RATE;
                    let env = hihat_envelope(t, beat_duration * 0.05);
                    let idx = hh_start + j;
                    if (idx >= 0 && idx < total_samples) {
                        drums_samples[idx] = drums_samples[idx] + noise_wave() * env * 0.15;
                    }
                }
            }

            // Kick on beats 1 and 3
            if (beat === 0 || beat === 2) {
                let kick_start = Math.floor(beat_start * SAMPLE_RATE);
                let kick_len = Math.floor(beat_duration * 0.15 * SAMPLE_RATE);

                for (let j = 0; j < kick_len; j++) {
                    let t = j / SAMPLE_RATE;
                    let freq = 80 * Math.exp(-t * 30) + 40;
                    let phase = freq * t;
                    let env = punchy_envelope(t, beat_duration * 0.15);
                    let idx = kick_start + j;
                    if (idx >= 0 && idx < total_samples) {
                        drums_samples[idx] = drums_samples[idx] + sine_wave(phase) * env * 0.4;
                    }
                }
            }
        }
    }

    // Lead melody (bars 5-8 only for variation)
    const melody = [
        // Bar 5
        [NOTES.E5, 0.5], [NOTES.D5, 0.25], [NOTES.C5, 0.25], [NOTES.A4, 0.5], [NOTES.REST, 0.5],
        // Bar 6
        [NOTES.C5, 0.5], [NOTES.D5, 0.25], [NOTES.E5, 0.25], [NOTES.F5, 0.5], [NOTES.E5, 0.5],
        // Bar 7
        [NOTES.D5, 0.5], [NOTES.C5, 0.25], [NOTES.B4, 0.25], [NOTES.A4, 0.5], [NOTES.REST, 0.5],
        // Bar 8
        [NOTES.B4, 0.25], [NOTES.C5, 0.25], [NOTES.D5, 0.5], [NOTES.E5, 1.0],
    ];

    let melody_start_time = 4 * bar_duration;
    let melody_time = 0;

    for (const note_data of melody) {
        let freq = note_data[0];
        let duration = note_data[1] * beat_duration;
        let note_start = Math.floor((melody_start_time + melody_time) * SAMPLE_RATE);

        if (freq > 0) {
            let note = generate_note(freq, duration * 0.9, SAMPLE_RATE, square_wave, lead_envelope, 0.3, {duty: 0.5});

            for (let j = 0; j < note.length; j++) {
                const s = note[j];
                let idx = note_start + j;
                if (idx >= 0 && idx < total_samples) {
                    lead_samples[idx] = lead_samples[idx] + s;
                }
            }
        }

        melody_time = melody_time + duration;
    }

    // Mix all channels
    let mixed: number[] = [];
    for (let i = 0; i < total_samples; i++) {
        mixed[i] = bass_samples[i] + lead_samples[i] + pad_samples[i] + arp_samples[i] + drums_samples[i];
    }

    // Add subtle delay effect
    mixed = add_delay(mixed, 0.15, 0.25, 0.2);

    // Normalize
    normalize_samples(mixed, 0.85);

    return samples_to_sound_data(mixed);
}

// Generate gameplay theme - high energy, driving beat
function generate_gameplay_theme() {
    let bpm = 140;
    let beat_duration = 60 / bpm;
    let bar_duration = beat_duration * 4;
    let loop_bars = 8;

    let total_samples = Math.floor(loop_bars * bar_duration * SAMPLE_RATE);

    // Initialize channels
    let bass_samples: number[] = [];
    let lead_samples: number[] = [];
    let arp_samples: number[] = [];
    let drums_samples: number[] = [];

    for (let i = 0; i < total_samples; i++) {
        bass_samples[i] = 0;
        lead_samples[i] = 0;
        arp_samples[i] = 0;
        drums_samples[i] = 0;
    }

    reset_noise();

    // Driving chord progression (E minor power chord feel)
    const bass_pattern = [
        NOTES.E3, NOTES.E3, NOTES.G3, NOTES.A3,
        NOTES.E3, NOTES.E3, NOTES.D3, NOTES.D3
    ];

    // Power chord notes for arpeggios
    const chord_roots = [
        [NOTES.E4, NOTES.G4, NOTES.B4],
        [NOTES.E4, NOTES.G4, NOTES.B4],
        [NOTES.G4, NOTES.B4, NOTES.D5],
        [NOTES.A4, NOTES.C5, NOTES.E5],
        [NOTES.E4, NOTES.G4, NOTES.B4],
        [NOTES.E4, NOTES.G4, NOTES.B4],
        [NOTES.D4, NOTES.F4, NOTES.A4],
        [NOTES.D4, NOTES.F4, NOTES.A4]
    ];

    for (let bar = 0; bar <= loop_bars - 1; bar++) {
        let bar_start = bar * bar_duration;
        let bass_note = bass_pattern[bar] / 2;

        // Driving 8th note bass
        for (let eighth = 0; eighth <= 7; eighth++) {
            let note_start = Math.floor((bar_start + eighth * beat_duration / 2) * SAMPLE_RATE);
            let note = generate_note(bass_note, beat_duration * 0.4, SAMPLE_RATE, sawtooth_wave, punchy_envelope, 0.45);

            for (let j = 0; j < note.length; j++) {
                const s = note[j];
                let idx = note_start + j;
                if (idx >= 0 && idx < total_samples) {
                    bass_samples[idx] = bass_samples[idx] + s;
                }
            }
        }

        // Fast arpeggios (16th notes)
        let chord = chord_roots[bar];
        const arp_pattern = [1, 2, 3, 2, 1, 3, 2, 3, 1, 2, 3, 2, 1, 2, 3, 1];
        let sixteenth = beat_duration / 4;

        for (let step = 0; step <= 15; step++) {
            let note_idx = arp_pattern[step];
            let freq = chord[note_idx - 1];
            let note_start = Math.floor((bar_start + step * sixteenth) * SAMPLE_RATE);
            let note = generate_note(freq, sixteenth * 0.6, SAMPLE_RATE, pulse_wave, stab_envelope, 0.22, {width: 0.125});

            for (let j = 0; j < note.length; j++) {
                const s = note[j];
                let idx = note_start + j;
                if (idx >= 0 && idx < total_samples) {
                    arp_samples[idx] = arp_samples[idx] + s;
                }
            }
        }

        // Drums: driving beat
        for (let beat = 0; beat <= 3; beat++) {
            let beat_start = bar_start + beat * beat_duration;

            // Hi-hats on 16th notes
            for (let sixteenth_beat = 0; sixteenth_beat <= 3; sixteenth_beat++) {
                let hh_start = Math.floor((beat_start + sixteenth_beat * beat_duration / 4) * SAMPLE_RATE);
                let hh_len = Math.floor(beat_duration * 0.03 * SAMPLE_RATE);

                // Accent on 8ths
                let accent = (sixteenth_beat % 2 === 0) ? 0.2 : 0.1;

                reset_noise();
                for (let j = 0; j < hh_len; j++) {
                    let t = j / SAMPLE_RATE;
                    let env = hihat_envelope(t, beat_duration * 0.03);
                    let idx = hh_start + j;
                    if (idx >= 0 && idx < total_samples) {
                        drums_samples[idx] = drums_samples[idx] + noise_wave() * env * accent;
                    }
                }
            }

            // Kick on 1 and 3
            if (beat === 0 || beat === 2) {
                let kick_start = Math.floor(beat_start * SAMPLE_RATE);
                let kick_len = Math.floor(beat_duration * 0.12 * SAMPLE_RATE);

                for (let j = 0; j < kick_len; j++) {
                    let t = j / SAMPLE_RATE;
                    let freq = 100 * Math.exp(-t * 40) + 45;
                    let phase = freq * t;
                    let env = punchy_envelope(t, beat_duration * 0.12);
                    let idx = kick_start + j;
                    if (idx >= 0 && idx < total_samples) {
                        drums_samples[idx] = drums_samples[idx] + sine_wave(phase) * env * 0.5;
                    }
                }
            }

            // Snare on 2 and 4
            if (beat === 1 || beat === 3) {
                let snare_start = Math.floor(beat_start * SAMPLE_RATE);
                let snare_len = Math.floor(beat_duration * 0.1 * SAMPLE_RATE);

                reset_noise();
                for (let j = 0; j < snare_len; j++) {
                    let t = j / SAMPLE_RATE;
                    let env = punchy_envelope(t, beat_duration * 0.1);
                    // Mix noise with a pitched body
                    let body = sine_wave(200 * t) * 0.4;
                    let noise = noise_wave() * 0.6;
                    let idx = snare_start + j;
                    if (idx >= 0 && idx < total_samples) {
                        drums_samples[idx] = drums_samples[idx] + (body + noise) * env * 0.35;
                    }
                }
            }
        }
    }

    // Epic lead melody for gameplay excitement
    const melody = [
        // Bar 1-2: Opening riff
        [NOTES.E5, 0.25], [NOTES.G5, 0.25], [NOTES.A5, 0.5], [NOTES.G5, 0.25], [NOTES.E5, 0.25], [NOTES.D5, 0.5],
        [NOTES.E5, 0.25], [NOTES.G5, 0.25], [NOTES.A5, 0.25], [NOTES.B5, 0.25], [NOTES.A5, 0.5], [NOTES.REST, 0.5],
        // Bar 3-4: Response
        [NOTES.G5, 0.5], [NOTES.A5, 0.25], [NOTES.G5, 0.25], [NOTES.E5, 0.5], [NOTES.D5, 0.5],
        [NOTES.E5, 1.0], [NOTES.REST, 0.5], [NOTES.D5, 0.25], [NOTES.E5, 0.25],
        // Bar 5-6: Climb
        [NOTES.E5, 0.25], [NOTES.F5, 0.25], [NOTES.G5, 0.5], [NOTES.A5, 0.5], [NOTES.B5, 0.5],
        [NOTES.C6, 0.5], [NOTES.B5, 0.25], [NOTES.A5, 0.25], [NOTES.G5, 0.5], [NOTES.REST, 0.5],
        // Bar 7-8: Resolution
        [NOTES.A5, 0.5], [NOTES.G5, 0.25], [NOTES.E5, 0.25], [NOTES.D5, 0.5], [NOTES.E5, 0.5],
        [NOTES.E5, 1.5], [NOTES.REST, 0.5],
    ];

    let melody_time = 0;
    for (const note_data of melody) {
        let freq = note_data[0];
        let duration = note_data[1] * beat_duration;
        let note_start = Math.floor(melody_time * SAMPLE_RATE);

        if (freq > 0) {
            let note = generate_note(freq, duration * 0.85, SAMPLE_RATE, square_wave, lead_envelope, 0.35, {duty: 0.5});

            for (let j = 0; j < note.length; j++) {
                const s = note[j];
                let idx = note_start + j;
                if (idx >= 0 && idx < total_samples) {
                    lead_samples[idx] = lead_samples[idx] + s;
                }
            }
        }

        melody_time = melody_time + duration;
    }

    // Mix all channels
    let mixed: number[] = [];
    for (let i = 0; i < total_samples; i++) {
        mixed[i] = bass_samples[i] + lead_samples[i] + arp_samples[i] + drums_samples[i];
    }

    // Add delay
    mixed = add_delay(mixed, 0.12, 0.2, 0.15);

    // Normalize
    normalize_samples(mixed, 0.85);

    return samples_to_sound_data(mixed);
}

// Generate game over theme - slower, minor key, melancholic but still 80s
function generate_gameover_theme() {
    let bpm = 80;
    let beat_duration = 60 / bpm;
    let bar_duration = beat_duration * 4;
    let loop_bars = 4;

    let total_samples = Math.floor(loop_bars * bar_duration * SAMPLE_RATE);

    let samples: number[] = [];
    for (let i = 0; i < total_samples; i++) {
        samples[i] = 0;
    }

    reset_noise();

    // Sad descending melody
    const melody = [
        [NOTES.E5, 1.0], [NOTES.D5, 1.0], [NOTES.C5, 1.0], [NOTES.B4, 1.0],
        [NOTES.A4, 1.0], [NOTES.G4, 1.0], [NOTES.A4, 2.0],
        [NOTES.E4, 1.0], [NOTES.F4, 0.5], [NOTES.E4, 0.5], [NOTES.D4, 1.0], [NOTES.E4, 1.0],
    ];

    // Pad chords
    const chords = [
        [NOTES.A3, NOTES.C4, NOTES.E4],
        [NOTES.G3, NOTES.B3, NOTES.D4],
        [NOTES.A3, NOTES.C4, NOTES.E4],
        [NOTES.E3, NOTES.G3, NOTES.B3],
    ];

    // Generate pads
    for (let bar = 0; bar <= loop_bars - 1; bar++) {
        let bar_start = bar * bar_duration;
        let chord = chords[bar];

        for (const freq of chord) {
            let note_start = Math.floor(bar_start * SAMPLE_RATE);
            let note = generate_note(freq, bar_duration * 0.95, SAMPLE_RATE, triangle_wave, lead_envelope, 0.2);

            for (let j = 0; j < note.length; j++) {
                const s = note[j];
                let idx = note_start + j;
                if (idx >= 0 && idx < total_samples) {
                    samples[idx] = samples[idx] + s;
                }
            }
        }

        // Slow bass
        let bass_freq = chord[0] / 2;
        let bass_start = Math.floor(bar_start * SAMPLE_RATE);
        let bass = generate_note(bass_freq, bar_duration * 0.8, SAMPLE_RATE, sine_wave, punchy_envelope, 0.35);

        for (let j = 0; j < bass.length; j++) {
            const s = bass[j];
            let idx = bass_start + j;
            if (idx >= 0 && idx < total_samples) {
                samples[idx] = samples[idx] + s;
            }
        }
    }

    // Generate melody
    let melody_time = 0;
    for (const note_data of melody) {
        let freq = note_data[0];
        let duration = note_data[1] * beat_duration;
        let note_start = Math.floor(melody_time * SAMPLE_RATE);

        if (freq > 0) {
            let note = generate_note(freq, duration * 0.9, SAMPLE_RATE, square_wave, lead_envelope, 0.3, {duty: 0.5});

            for (let j = 0; j < note.length; j++) {
                const s = note[j];
                let idx = note_start + j;
                if (idx >= 0 && idx < total_samples) {
                    samples[idx] = samples[idx] + s;
                }
            }
        }

        melody_time = melody_time + duration;
    }

    // Add reverb-like delay
    samples = add_delay(samples, 0.25, 0.35, 0.3);

    normalize_samples(samples, 0.8);

    return samples_to_sound_data(samples);
}

// Generate awards ceremony theme - triumphant, Olympic-style fanfare with SNES/C64 vibes
function generate_awards_theme() {
    let bpm = 120;
    let beat_duration = 60 / bpm;
    let bar_duration = beat_duration * 4;
    let loop_bars = 8;

    let total_samples = Math.floor(loop_bars * bar_duration * SAMPLE_RATE);

    // Initialize channels
    let trumpet_samples: number[] = [];
    let brass_samples: number[] = [];
    let strings_samples: number[] = [];
    let bass_samples: number[] = [];
    let drums_samples: number[] = [];

    for (let i = 0; i < total_samples; i++) {
        trumpet_samples[i] = 0;
        brass_samples[i] = 0;
        strings_samples[i] = 0;
        bass_samples[i] = 0;
        drums_samples[i] = 0;
    }

    reset_noise();

    // Triumphant chord progression (C major - F major - G major - C major)
    const chords = [
        [NOTES.C4, NOTES.E4, NOTES.G4], // C major
        [NOTES.C4, NOTES.E4, NOTES.G4], // C major
        [NOTES.F3, NOTES.A3, NOTES.C4], // F major
        [NOTES.F3, NOTES.A3, NOTES.C4], // F major
        [NOTES.G3, NOTES.B3, NOTES.D4], // G major
        [NOTES.G3, NOTES.B3, NOTES.D4], // G major
        [NOTES.C4, NOTES.E4, NOTES.G4], // C major
        [NOTES.C4, NOTES.E4, NOTES.G4], // C major (resolution)
    ];

    // Bass line - root notes
    const bass_notes = [
        NOTES.C3, NOTES.C3, NOTES.F2, NOTES.F2,
        NOTES.G2, NOTES.G2, NOTES.C3, NOTES.C3
    ];

    // Olympic-style fanfare melody (inspired by awards ceremonies)
    const melody = [
        // Bar 1-2: Fanfare opening
        [NOTES.C5, 0.75], [NOTES.E5, 0.25], [NOTES.G5, 1.0], [NOTES.E5, 0.5], [NOTES.G5, 0.5], [NOTES.C6, 1.0],
        [NOTES.G5, 0.5], [NOTES.E5, 0.5], [NOTES.C5, 0.5], [NOTES.E5, 0.5], [NOTES.G5, 1.0], [NOTES.REST, 0.5], [NOTES.G5, 0.5],
        // Bar 3-4: Response
        [NOTES.F5, 0.75], [NOTES.A5, 0.25], [NOTES.C6, 1.0], [NOTES.A5, 0.5], [NOTES.F5, 0.5], [NOTES.A5, 1.0],
        [NOTES.G5, 0.5], [NOTES.F5, 0.5], [NOTES.E5, 0.5], [NOTES.D5, 0.5], [NOTES.C5, 1.0], [NOTES.REST, 1.0],
        // Bar 5-6: Build up
        [NOTES.G5, 0.5], [NOTES.A5, 0.5], [NOTES.B5, 0.5], [NOTES.C6, 0.5], [NOTES.D6, 1.0], [NOTES.B5, 0.5], [NOTES.G5, 0.5],
        [NOTES.D6, 0.5], [NOTES.C6, 0.5], [NOTES.B5, 0.5], [NOTES.A5, 0.5], [NOTES.G5, 1.5], [NOTES.REST, 0.5],
        // Bar 7-8: Triumphant finale
        [NOTES.E5, 0.5], [NOTES.G5, 0.5], [NOTES.C6, 1.0], [NOTES.E6, 1.0], [NOTES.C6, 0.5], [NOTES.G5, 0.5],
        [NOTES.C6, 2.0], [NOTES.REST, 2.0]
    ];

    // Generate bass
    for (let bar = 0; bar <= loop_bars - 1; bar++) {
        let bar_start = bar * bar_duration;
        let bass_note = bass_notes[bar];

        // Whole notes for bass
        let note_start = Math.floor(bar_start * SAMPLE_RATE);
        let note = generate_note(bass_note, bar_duration * 0.9, SAMPLE_RATE, sine_wave, lead_envelope, 0.4);

        for (let j = 0; j < note.length; j++) {
            const s = note[j];
            let idx = note_start + j;
            if (idx >= 0 && idx < total_samples) {
                bass_samples[idx] = bass_samples[idx] + s;
            }
        }
    }

    // Generate string pads (sustained chords)
    for (let bar = 0; bar <= loop_bars - 1; bar++) {
        let bar_start = bar * bar_duration;
        let chord = chords[bar];

        for (const freq of chord) {
            let note_start = Math.floor(bar_start * SAMPLE_RATE);
            let note = generate_note(freq, bar_duration * 0.95, SAMPLE_RATE, triangle_wave, lead_envelope, 0.2);

            for (let j = 0; j < note.length; j++) {
                const s = note[j];
                let idx = note_start + j;
                if (idx >= 0 && idx < total_samples) {
                    strings_samples[idx] = strings_samples[idx] + s;
                }
            }
        }
    }

    // Generate brass stabs (punchier chords on beats)
    for (let bar = 0; bar <= loop_bars - 1; bar++) {
        let bar_start = bar * bar_duration;
        let chord = chords[bar];

        // Brass hits on beats 1 and 3
        for (let beat = 0; beat <= 1; beat++) {
            let beat_start = bar_start + beat * 2 * beat_duration;
            for (const freq of chord) {
                let note_start = Math.floor(beat_start * SAMPLE_RATE);
                let note = generate_note(freq * 2, beat_duration * 0.9, SAMPLE_RATE, pulse_wave, stab_envelope, 0.25, {width: 0.3});

                for (let j = 0; j < note.length; j++) {
                    const s = note[j];
                    let idx = note_start + j;
                    if (idx >= 0 && idx < total_samples) {
                        brass_samples[idx] = brass_samples[idx] + s;
                    }
                }
            }
        }
    }

    // Generate triumphant trumpet melody
    let melody_time = 0;
    for (const note_data of melody) {
        let freq = note_data[0];
        let duration = note_data[1] * beat_duration;
        let note_start = Math.floor(melody_time * SAMPLE_RATE);

        if (freq > 0) {
            // Use sawtooth for trumpet-like brightness
            let note = generate_note(freq, duration * 0.9, SAMPLE_RATE, sawtooth_wave, lead_envelope, 0.35);

            for (let j = 0; j < note.length; j++) {
                const s = note[j];
                let idx = note_start + j;
                if (idx >= 0 && idx < total_samples) {
                    trumpet_samples[idx] = trumpet_samples[idx] + s;
                }
            }
        }

        melody_time = melody_time + duration;
    }

    // Generate ceremonial drums
    for (let bar = 0; bar <= loop_bars - 1; bar++) {
        let bar_start = bar * bar_duration;

        for (let beat = 0; beat <= 3; beat++) {
            let beat_start = bar_start + beat * beat_duration;

            // Snare on beats 2 and 4
            if (beat === 1 || beat === 3) {
                let snare_start = Math.floor(beat_start * SAMPLE_RATE);
                let snare_len = Math.floor(beat_duration * 0.15 * SAMPLE_RATE);

                reset_noise();
                for (let j = 0; j < snare_len; j++) {
                    let t = j / SAMPLE_RATE;
                    let env = punchy_envelope(t, beat_duration * 0.15);
                    let body = sine_wave(220 * t) * 0.3;
                    let noise = noise_wave() * 0.7;
                    let idx = snare_start + j;
                    if (idx >= 0 && idx < total_samples) {
                        drums_samples[idx] = drums_samples[idx] + (body + noise) * env * 0.3;
                    }
                }
            }

            // Kick on beat 1
            if (beat === 0) {
                let kick_start = Math.floor(beat_start * SAMPLE_RATE);
                let kick_len = Math.floor(beat_duration * 0.2 * SAMPLE_RATE);

                for (let j = 0; j < kick_len; j++) {
                    let t = j / SAMPLE_RATE;
                    let freq = 90 * Math.exp(-t * 35) + 45;
                    let phase = freq * t;
                    let env = punchy_envelope(t, beat_duration * 0.2);
                    let idx = kick_start + j;
                    if (idx >= 0 && idx < total_samples) {
                        drums_samples[idx] = drums_samples[idx] + sine_wave(phase) * env * 0.4;
                    }
                }
            }

            // Cymbal crashes on important moments (bar 1, 5, 7)
            if (beat === 0 && (bar === 0 || bar === 4 || bar === 6)) {
                let cymbal_start = Math.floor(beat_start * SAMPLE_RATE);
                let cymbal_len = Math.floor(beat_duration * 2 * SAMPLE_RATE);

                reset_noise();
                for (let j = 0; j < cymbal_len; j++) {
                    let t = j / SAMPLE_RATE;
                    let env = Math.exp(-t * 2);
                    let idx = cymbal_start + j;
                    if (idx >= 0 && idx < total_samples) {
                        drums_samples[idx] = drums_samples[idx] + noise_wave() * env * 0.2;
                    }
                }
            }
        }
    }

    // Mix all channels
    let mixed: number[] = [];
    for (let i = 0; i < total_samples; i++) {
        mixed[i] = trumpet_samples[i] + brass_samples[i] + strings_samples[i] + bass_samples[i] + drums_samples[i];
    }

    // Add subtle reverb for grandeur
    mixed = add_delay(mixed, 0.18, 0.3, 0.25);

    // Normalize
    normalize_samples(mixed, 0.85);

    return samples_to_sound_data(mixed);
}

//------------------------------------------------------------------------------
// Track cache
//------------------------------------------------------------------------------

let track_cache: Record<string, Source> = Object.create(null);

function get_or_generate_track(name: string): Source | undefined {
    if (track_cache[name]) {
        return track_cache[name];
    }

    let sound_data: SoundData | null = null;

    if (name === "menu") {
        sound_data = generate_menu_theme();
    } else if (name === "gameplay") {
        sound_data = generate_gameplay_theme();
    } else if (name === "gameover") {
        sound_data = generate_gameover_theme();
    } else if (name === "awards") {
        sound_data = generate_awards_theme();
    } else {
        return undefined;
    }

    if (sound_data) {
        track_cache[name] = love.audio.newSource(sound_data, "static");
        track_cache[name].setLooping(true);
    }

    return track_cache[name];
}

//------------------------------------------------------------------------------
// Public API
//------------------------------------------------------------------------------

const Music = {
    // Initialize the music system
    load(): boolean {
        if (is_initialized) {
            return true;
        }

        try {
            // Pre-generate tracks in background (or on first play)
            // For now, we generate on first play to reduce load time
            is_initialized = true;
        } catch (err) {
            console.log("Music system initialization warning: " + String(err));
            return false;
        }

        return true;
    },

    // Play a music track
    // @param track_name string: "menu", "gameplay", "gameover", or "awards"
    play(track_name: string): void {
        if (!is_initialized) {
            Music.load();
        }

        // Don't restart if same track is playing
        if (current_track === track_name && current_source && current_source.isPlaying()) {
            return;
        }

        // Stop current music
        Music.stop();

        try {
            const source = get_or_generate_track(track_name);
            if (source) {
                source.setVolume(master_volume);
                source.play();
                current_source = source;
                current_track = track_name;
            }
        } catch (err) {
            console.log("Music playback error: " + String(err));
        }
    },

    // Stop current music
    stop(): void {
        if (current_source) {
            try {
                current_source.stop();
            } catch { /* pcall */ }
            current_source = null;
            current_track = null;
        }
    },

    // Pause current music
    pause(): void {
        if (current_source) {
            try {
                current_source.pause();
            } catch { /* pcall */ }
        }
    },

    // Resume paused music
    resume(): void {
        if (current_source) {
            try {
                current_source.play();
            } catch { /* pcall */ }
        }
    },

    // Set master volume (0-1)
    set_volume(vol: number): void {
        master_volume = Math.max(0, Math.min(1, vol));
        if (current_source) {
            try {
                current_source.setVolume(master_volume);
            } catch { /* pcall */ }
        }
    },

    // Get current volume
    get_volume(): number {
        return master_volume;
    },

    // Check if music is playing
    is_playing(): boolean {
        if (current_source) {
            try {
                return current_source.isPlaying();
            } catch {
                return false;
            }
        }
        return false;
    },

    // Get current track name
    get_current_track(): string | null {
        return current_track;
    },

    // Pre-generate all tracks (call during loading screen if you have one)
    preload_all(): void {
        if (!is_initialized) {
            Music.load();
        }

        const tracks = ["menu", "gameplay", "gameover", "awards"];
        for (const track of tracks) {
            try {
                get_or_generate_track(track);
            } catch { /* pcall */ }
        }
    },

    // Clear the track cache (useful for memory management)
    clear_cache(): void {
        Music.stop();
        for (const name in track_cache) {
            const source = track_cache[name];
            try {
                source.stop();
            } catch { /* pcall */ }
        }
        track_cache = Object.create(null);
    },
};

export default Music;
