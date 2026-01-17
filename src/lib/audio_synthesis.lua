-- src/lib/audio_synthesis.lua
-- Shared audio synthesis primitives for music and sound effects
-- Contains waveform generators, envelope functions, and sample utilities

local AudioSynthesis = {}

-- Audio constants
AudioSynthesis.SAMPLE_RATE = 44100
AudioSynthesis.BITS = 16
AudioSynthesis.CHANNELS = 1

--------------------------------------------------------------------------------
-- Noise state (module-level for consistency)
--------------------------------------------------------------------------------

local noise_seed = 12345

function AudioSynthesis.reset_noise()
    noise_seed = 12345
end

--------------------------------------------------------------------------------
-- Waveform generators
--------------------------------------------------------------------------------

-- Square wave - classic 8-bit lead sound
function AudioSynthesis.square_wave(phase, duty_cycle)
    duty_cycle = duty_cycle or 0.5
    return phase % 1 < duty_cycle and 1 or -1
end

-- Triangle wave - softer bass tones
function AudioSynthesis.triangle_wave(phase)
    local t = phase % 1
    return 4 * math.abs(t - 0.5) - 1
end

-- Sawtooth wave - bright, buzzy synth sounds
function AudioSynthesis.sawtooth_wave(phase)
    return 2 * (phase % 1) - 1
end

-- Sine wave - for smooth bass
function AudioSynthesis.sine_wave(phase)
    return math.sin(phase * 2 * math.pi)
end

-- Noise - for percussion/hi-hats (using deterministic pseudo-random)
function AudioSynthesis.noise_wave()
    noise_seed = (noise_seed * 1103515245 + 12345) % 2147483648
    return (noise_seed / 1073741824) - 1
end

-- Pulse wave with variable width (for 80s synth stabs)
function AudioSynthesis.pulse_wave(phase, width)
    width = width or 0.25
    return phase % 1 < width and 1 or -1
end

--------------------------------------------------------------------------------
-- Envelope generators (ADSR)
--------------------------------------------------------------------------------

function AudioSynthesis.adsr_envelope(t, duration, attack, decay, sustain, release)
    local attack_time = attack * duration
    local decay_time = decay * duration
    local release_time = release * duration

    if t < attack_time then
        return t / attack_time
    elseif t < attack_time + decay_time then
        local decay_progress = (t - attack_time) / decay_time
        return 1 - (1 - sustain) * decay_progress
    elseif t < duration - release_time then
        return sustain
    else
        local release_progress = (t - (duration - release_time)) / release_time
        return sustain * (1 - release_progress)
    end
end

-- Punchy envelope for bass/drums
function AudioSynthesis.punchy_envelope(t, duration)
    return AudioSynthesis.adsr_envelope(t, duration, 0.01, 0.15, 0.4, 0.2)
end

-- Synth stab envelope
function AudioSynthesis.stab_envelope(t, duration)
    return AudioSynthesis.adsr_envelope(t, duration, 0.02, 0.1, 0.7, 0.15)
end

-- Lead envelope with sustain
function AudioSynthesis.lead_envelope(t, duration)
    return AudioSynthesis.adsr_envelope(t, duration, 0.05, 0.1, 0.8, 0.1)
end

-- Snappy hi-hat envelope
function AudioSynthesis.hihat_envelope(t, duration)
    return AudioSynthesis.adsr_envelope(t, duration, 0.001, 0.05, 0.1, 0.2)
end

-- Quick envelope for SFX
function AudioSynthesis.quick_envelope(t, duration)
    return AudioSynthesis.adsr_envelope(t, duration, 0.001, 0.05, 0.3, 0.3)
end

--------------------------------------------------------------------------------
-- Sample conversion helpers
--------------------------------------------------------------------------------

-- Normalize samples to prevent clipping
function AudioSynthesis.normalize_samples(samples, target_peak)
    target_peak = target_peak or 0.9
    local max_val = 0
    for _, s in ipairs(samples) do
        max_val = math.max(max_val, math.abs(s))
    end

    if max_val > 0 then
        local scale = target_peak / max_val
        for i = 1, #samples do
            samples[i] = samples[i] * scale
        end
    end

    return samples
end

-- Convert float samples to SoundData
function AudioSynthesis.samples_to_sound_data(samples)
    local sound_data = love.sound.newSoundData(#samples, AudioSynthesis.SAMPLE_RATE, AudioSynthesis.BITS, AudioSynthesis.CHANNELS)

    for i = 1, #samples do
        local sample = samples[i]
        -- Clamp to [-1, 1]
        sample = math.max(-1, math.min(1, sample))
        sound_data:setSample(i - 1, sample)
    end

    return sound_data
end

return AudioSynthesis
