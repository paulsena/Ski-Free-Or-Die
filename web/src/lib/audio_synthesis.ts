// src/lib/audio_synthesis.ts
// Shared audio synthesis primitives for music and sound effects
// Contains waveform generators, envelope functions, and sample utilities

import love from "../platform/love";

type Samples = number[] | Float32Array;

//------------------------------------------------------------------------------
// Noise state (module-level for consistency)
//------------------------------------------------------------------------------

let noise_seed = 12345;

const AudioSynthesis = {
    // Audio constants
    SAMPLE_RATE: 44100,
    BITS: 16,
    CHANNELS: 1,

    reset_noise(): void {
        noise_seed = 12345;
    },

    //------------------------------------------------------------------------------
    // Waveform generators
    //------------------------------------------------------------------------------

    // Square wave - classic 8-bit lead sound
    square_wave(phase: number, duty_cycle = 0.5): number {
        return phase - Math.floor(phase) < duty_cycle ? 1 : -1;
    },

    // Triangle wave - softer bass tones
    triangle_wave(phase: number): number {
        const t = phase - Math.floor(phase);
        return 4 * Math.abs(t - 0.5) - 1;
    },

    // Sawtooth wave - bright, buzzy synth sounds
    sawtooth_wave(phase: number): number {
        return 2 * (phase - Math.floor(phase)) - 1;
    },

    // Sine wave - for smooth bass
    sine_wave(phase: number): number {
        return Math.sin(phase * 2 * Math.PI);
    },

    // Noise - for percussion/hi-hats (using deterministic pseudo-random)
    noise_wave(): number {
        noise_seed = (noise_seed * 1103515245 + 12345) % 2147483648;
        return (noise_seed / 1073741824) - 1;
    },

    // Pulse wave with variable width (for 80s synth stabs)
    pulse_wave(phase: number, width = 0.25): number {
        return phase - Math.floor(phase) < width ? 1 : -1;
    },

    //------------------------------------------------------------------------------
    // Envelope generators (ADSR)
    //------------------------------------------------------------------------------

    adsr_envelope(t: number, duration: number, attack: number, decay: number, sustain: number, release: number): number {
        const attack_time = attack * duration;
        const decay_time = decay * duration;
        const release_time = release * duration;

        if (t < attack_time) {
            return t / attack_time;
        } else if (t < attack_time + decay_time) {
            const decay_progress = (t - attack_time) / decay_time;
            return 1 - (1 - sustain) * decay_progress;
        } else if (t < duration - release_time) {
            return sustain;
        } else {
            const release_progress = (t - (duration - release_time)) / release_time;
            return sustain * (1 - release_progress);
        }
    },

    // Punchy envelope for bass/drums
    punchy_envelope(t: number, duration: number): number {
        return AudioSynthesis.adsr_envelope(t, duration, 0.01, 0.15, 0.4, 0.2);
    },

    // Synth stab envelope
    stab_envelope(t: number, duration: number): number {
        return AudioSynthesis.adsr_envelope(t, duration, 0.02, 0.1, 0.7, 0.15);
    },

    // Lead envelope with sustain
    lead_envelope(t: number, duration: number): number {
        return AudioSynthesis.adsr_envelope(t, duration, 0.05, 0.1, 0.8, 0.1);
    },

    // Snappy hi-hat envelope
    hihat_envelope(t: number, duration: number): number {
        return AudioSynthesis.adsr_envelope(t, duration, 0.001, 0.05, 0.1, 0.2);
    },

    // Quick envelope for SFX
    quick_envelope(t: number, duration: number): number {
        return AudioSynthesis.adsr_envelope(t, duration, 0.001, 0.05, 0.3, 0.3);
    },

    //------------------------------------------------------------------------------
    // Sample conversion helpers
    //------------------------------------------------------------------------------

    // Normalize samples to prevent clipping
    normalize_samples<T extends Samples>(samples: T, target_peak = 0.9): T {
        let max_val = 0;
        for (const s of samples) {
            max_val = Math.max(max_val, Math.abs(s));
        }

        if (max_val > 0) {
            const scale = target_peak / max_val;
            for (let i = 0; i < samples.length; i++) {
                samples[i] = samples[i] * scale;
            }
        }

        return samples;
    },

    // Convert float samples to SoundData
    samples_to_sound_data(samples: Samples) {
        const sound_data = love.sound.newSoundData(samples.length, AudioSynthesis.SAMPLE_RATE, AudioSynthesis.BITS, AudioSynthesis.CHANNELS);

        for (let i = 0; i < samples.length; i++) {
            let sample = samples[i];
            // Clamp to [-1, 1]
            sample = Math.max(-1, Math.min(1, sample));
            sound_data.setSample(i, sample);
        }

        return sound_data;
    },
};

export default AudioSynthesis;
