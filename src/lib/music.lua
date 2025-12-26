-- src/lib/music.lua
-- Procedural 80s chiptune music synthesis system
-- Think OutRun, California Games, Top Gear SNES vibes

local Music = {}

-- Audio settings
local SAMPLE_RATE = 44100
local BITS = 16
local CHANNELS = 1

-- Music state
local current_source = nil
local current_track = nil
local master_volume = 0.7
local is_initialized = false

-- Note frequencies (A4 = 440Hz tuning)
local NOTES = {
    C3 = 130.81, D3 = 146.83, E3 = 164.81, F3 = 174.61, G3 = 196.00, A3 = 220.00, B3 = 246.94,
    C4 = 261.63, D4 = 293.66, E4 = 329.63, F4 = 349.23, G4 = 392.00, A4 = 440.00, B4 = 493.88,
    C5 = 523.25, D5 = 587.33, E5 = 659.26, F5 = 698.46, G5 = 783.99, A5 = 880.00, B5 = 987.77,
    C6 = 1046.50, D6 = 1174.66, E6 = 1318.51,
    REST = 0
}

-- Add sharp/flat notes
NOTES["C#3"] = 138.59; NOTES["D#3"] = 155.56; NOTES["F#3"] = 185.00; NOTES["G#3"] = 207.65; NOTES["A#3"] = 233.08
NOTES["C#4"] = 277.18; NOTES["D#4"] = 311.13; NOTES["F#4"] = 369.99; NOTES["G#4"] = 415.30; NOTES["A#4"] = 466.16
NOTES["C#5"] = 554.37; NOTES["D#5"] = 622.25; NOTES["F#5"] = 739.99; NOTES["G#5"] = 830.61; NOTES["A#5"] = 932.33

--------------------------------------------------------------------------------
-- Waveform generators
--------------------------------------------------------------------------------

-- Square wave - classic 8-bit lead sound
local function square_wave(phase, duty_cycle)
    duty_cycle = duty_cycle or 0.5
    return phase % 1 < duty_cycle and 1 or -1
end

-- Triangle wave - softer bass tones
local function triangle_wave(phase)
    local t = phase % 1
    return 4 * math.abs(t - 0.5) - 1
end

-- Sawtooth wave - bright, buzzy synth sounds
local function sawtooth_wave(phase)
    return 2 * (phase % 1) - 1
end

-- Noise - for percussion/hi-hats (using deterministic pseudo-random)
local noise_seed = 12345
local function noise_wave()
    noise_seed = (noise_seed * 1103515245 + 12345) % 2147483648
    return (noise_seed / 1073741824) - 1
end

-- Reset noise seed for consistent playback
local function reset_noise()
    noise_seed = 12345
end

-- Pulse wave with variable width (for 80s synth stabs)
local function pulse_wave(phase, width)
    width = width or 0.25
    return phase % 1 < width and 1 or -1
end

-- Sine wave - for smooth bass
local function sine_wave(phase)
    return math.sin(phase * 2 * math.pi)
end

--------------------------------------------------------------------------------
-- Envelope generators (ADSR)
--------------------------------------------------------------------------------

local function adsr_envelope(t, duration, attack, decay, sustain, release)
    local attack_time = attack * duration
    local decay_time = decay * duration
    local release_time = release * duration
    local sustain_time = duration - attack_time - decay_time - release_time

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
local function punchy_envelope(t, duration)
    return adsr_envelope(t, duration, 0.01, 0.15, 0.4, 0.2)
end

-- Synth stab envelope
local function stab_envelope(t, duration)
    return adsr_envelope(t, duration, 0.02, 0.1, 0.7, 0.15)
end

-- Lead envelope with sustain
local function lead_envelope(t, duration)
    return adsr_envelope(t, duration, 0.05, 0.1, 0.8, 0.1)
end

-- Snappy hi-hat envelope
local function hihat_envelope(t, duration)
    return adsr_envelope(t, duration, 0.001, 0.05, 0.1, 0.2)
end

--------------------------------------------------------------------------------
-- Sound synthesis helpers
--------------------------------------------------------------------------------

-- Generate a note with a specific waveform
local function generate_note(freq, duration, samples_per_sec, wave_func, envelope_func, volume, extra_params)
    volume = volume or 1.0
    extra_params = extra_params or {}

    local samples = {}
    local num_samples = math.floor(duration * samples_per_sec)

    for i = 1, num_samples do
        local t = (i - 1) / samples_per_sec
        local phase = freq * t
        local envelope = envelope_func(t, duration)
        local sample = 0

        if freq > 0 then
            sample = wave_func(phase, extra_params.width or extra_params.duty) * envelope * volume
        end

        table.insert(samples, sample)
    end

    return samples
end

-- Mix multiple sample arrays together
local function mix_samples(...)
    local arrays = {...}
    local max_len = 0
    for _, arr in ipairs(arrays) do
        max_len = math.max(max_len, #arr)
    end

    local result = {}
    for i = 1, max_len do
        local sum = 0
        for _, arr in ipairs(arrays) do
            sum = sum + (arr[i] or 0)
        end
        result[i] = sum
    end

    return result
end

-- Append samples to an array
local function append_samples(dest, src)
    for _, sample in ipairs(src) do
        table.insert(dest, sample)
    end
end

-- Normalize samples to prevent clipping
local function normalize_samples(samples, target_peak)
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

-- Add reverb/delay effect
local function add_delay(samples, delay_time, decay, mix)
    delay_time = delay_time or 0.1
    decay = decay or 0.3
    mix = mix or 0.3

    local delay_samples = math.floor(delay_time * SAMPLE_RATE)
    local result = {}

    for i = 1, #samples do
        local delayed = 0
        if i > delay_samples then
            delayed = samples[i - delay_samples] * decay
        end
        result[i] = samples[i] + delayed * mix
    end

    return result
end

-- Convert float samples to SoundData
local function samples_to_sound_data(samples)
    local sound_data = love.sound.newSoundData(#samples, SAMPLE_RATE, BITS, CHANNELS)

    for i = 1, #samples do
        local sample = samples[i]
        -- Clamp to [-1, 1]
        sample = math.max(-1, math.min(1, sample))
        sound_data:setSample(i - 1, sample)
    end

    return sound_data
end

--------------------------------------------------------------------------------
-- Track generators
--------------------------------------------------------------------------------

-- Generate menu theme - chill but energetic, synth arpeggios
local function generate_menu_theme()
    local bpm = 110
    local beat_duration = 60 / bpm
    local bar_duration = beat_duration * 4
    local loop_bars = 8

    local total_samples = math.floor(loop_bars * bar_duration * SAMPLE_RATE)

    -- Initialize all channels
    local bass_samples = {}
    local lead_samples = {}
    local pad_samples = {}
    local arp_samples = {}
    local drums_samples = {}

    for i = 1, total_samples do
        bass_samples[i] = 0
        lead_samples[i] = 0
        pad_samples[i] = 0
        arp_samples[i] = 0
        drums_samples[i] = 0
    end

    reset_noise()

    -- Chord progression (Am - F - C - G pattern in A minor)
    local chords = {
        {NOTES.A3, NOTES.C4, NOTES.E4}, -- Am
        {NOTES.F3, NOTES.A3, NOTES.C4}, -- F
        {NOTES.C4, NOTES.E4, NOTES.G4}, -- C
        {NOTES.G3, NOTES.B3, NOTES.D4}, -- G
        {NOTES.A3, NOTES.C4, NOTES.E4}, -- Am
        {NOTES.F3, NOTES.A3, NOTES.C4}, -- F
        {NOTES.E3, NOTES.G3, NOTES.B3}, -- Em
        {NOTES.E3, NOTES.G3, NOTES.B3}, -- Em (resolve)
    }

    -- Bass line - root notes on beat 1 and 3
    local bass_notes = {
        NOTES.A3, NOTES.F3, NOTES.C3, NOTES.G3,
        NOTES.A3, NOTES.F3, NOTES.E3, NOTES.E3
    }

    for bar = 0, loop_bars - 1 do
        local bar_start = bar * bar_duration
        local bass_note = bass_notes[bar + 1] / 2 -- One octave lower

        -- Bass on beats 1 and 3
        for beat = 0, 1 do
            local note_start = math.floor((bar_start + beat * 2 * beat_duration) * SAMPLE_RATE)
            local note = generate_note(bass_note, beat_duration * 0.9, SAMPLE_RATE, triangle_wave, punchy_envelope, 0.5)

            for j, s in ipairs(note) do
                local idx = note_start + j
                if idx >= 1 and idx <= total_samples then
                    bass_samples[idx] = bass_samples[idx] + s
                end
            end
        end

        -- Arpeggiated chord pattern (16th notes)
        local chord = chords[bar + 1]
        local arp_pattern = {1, 2, 3, 2, 1, 3, 2, 3, 1, 2, 3, 2, 1, 3, 2, 1} -- 16 steps per bar
        local sixteenth = beat_duration / 4

        for step = 0, 15 do
            local note_idx = arp_pattern[step + 1]
            local freq = chord[note_idx]
            local note_start = math.floor((bar_start + step * sixteenth) * SAMPLE_RATE)
            local note = generate_note(freq * 2, sixteenth * 0.7, SAMPLE_RATE, pulse_wave, stab_envelope, 0.25, {width = 0.25})

            for j, s in ipairs(note) do
                local idx = note_start + j
                if idx >= 1 and idx <= total_samples then
                    arp_samples[idx] = arp_samples[idx] + s
                end
            end
        end

        -- Simple pad chords (held notes)
        for _, freq in ipairs(chord) do
            local note_start = math.floor(bar_start * SAMPLE_RATE)
            local note = generate_note(freq, bar_duration * 0.95, SAMPLE_RATE, sine_wave, lead_envelope, 0.15)

            for j, s in ipairs(note) do
                local idx = note_start + j
                if idx >= 1 and idx <= total_samples then
                    pad_samples[idx] = pad_samples[idx] + s
                end
            end
        end

        -- Drums: kick on 1/3, hi-hat on 8ths
        for beat = 0, 3 do
            local beat_start = bar_start + beat * beat_duration

            -- Hi-hat on every 8th note
            for eighth = 0, 1 do
                local hh_start = math.floor((beat_start + eighth * beat_duration / 2) * SAMPLE_RATE)
                local hh_len = math.floor(beat_duration * 0.05 * SAMPLE_RATE)

                reset_noise()
                for j = 1, hh_len do
                    local t = (j - 1) / SAMPLE_RATE
                    local env = hihat_envelope(t, beat_duration * 0.05)
                    local idx = hh_start + j
                    if idx >= 1 and idx <= total_samples then
                        drums_samples[idx] = drums_samples[idx] + noise_wave() * env * 0.15
                    end
                end
            end

            -- Kick on beats 1 and 3
            if beat == 0 or beat == 2 then
                local kick_start = math.floor(beat_start * SAMPLE_RATE)
                local kick_len = math.floor(beat_duration * 0.15 * SAMPLE_RATE)

                for j = 1, kick_len do
                    local t = (j - 1) / SAMPLE_RATE
                    local freq = 80 * math.exp(-t * 30) + 40
                    local phase = freq * t
                    local env = punchy_envelope(t, beat_duration * 0.15)
                    local idx = kick_start + j
                    if idx >= 1 and idx <= total_samples then
                        drums_samples[idx] = drums_samples[idx] + sine_wave(phase) * env * 0.4
                    end
                end
            end
        end
    end

    -- Lead melody (bars 5-8 only for variation)
    local melody = {
        -- Bar 5
        {NOTES.E5, 0.5}, {NOTES.D5, 0.25}, {NOTES.C5, 0.25}, {NOTES.A4, 0.5}, {NOTES.REST, 0.5},
        -- Bar 6
        {NOTES.C5, 0.5}, {NOTES.D5, 0.25}, {NOTES.E5, 0.25}, {NOTES.F5, 0.5}, {NOTES.E5, 0.5},
        -- Bar 7
        {NOTES.D5, 0.5}, {NOTES.C5, 0.25}, {NOTES.B4, 0.25}, {NOTES.A4, 0.5}, {NOTES.REST, 0.5},
        -- Bar 8
        {NOTES.B4, 0.25}, {NOTES.C5, 0.25}, {NOTES.D5, 0.5}, {NOTES.E5, 1.0},
    }

    local melody_start_time = 4 * bar_duration
    local melody_time = 0

    for _, note_data in ipairs(melody) do
        local freq = note_data[1]
        local duration = note_data[2] * beat_duration
        local note_start = math.floor((melody_start_time + melody_time) * SAMPLE_RATE)

        if freq > 0 then
            local note = generate_note(freq, duration * 0.9, SAMPLE_RATE, square_wave, lead_envelope, 0.3, {duty = 0.5})

            for j, s in ipairs(note) do
                local idx = note_start + j
                if idx >= 1 and idx <= total_samples then
                    lead_samples[idx] = lead_samples[idx] + s
                end
            end
        end

        melody_time = melody_time + duration
    end

    -- Mix all channels
    local mixed = {}
    for i = 1, total_samples do
        mixed[i] = bass_samples[i] + lead_samples[i] + pad_samples[i] + arp_samples[i] + drums_samples[i]
    end

    -- Add subtle delay effect
    mixed = add_delay(mixed, 0.15, 0.25, 0.2)

    -- Normalize
    normalize_samples(mixed, 0.85)

    return samples_to_sound_data(mixed)
end

-- Generate gameplay theme - high energy, driving beat
local function generate_gameplay_theme()
    local bpm = 140
    local beat_duration = 60 / bpm
    local bar_duration = beat_duration * 4
    local loop_bars = 8

    local total_samples = math.floor(loop_bars * bar_duration * SAMPLE_RATE)

    -- Initialize channels
    local bass_samples = {}
    local lead_samples = {}
    local arp_samples = {}
    local drums_samples = {}

    for i = 1, total_samples do
        bass_samples[i] = 0
        lead_samples[i] = 0
        arp_samples[i] = 0
        drums_samples[i] = 0
    end

    reset_noise()

    -- Driving chord progression (E minor power chord feel)
    local bass_pattern = {
        NOTES.E3, NOTES.E3, NOTES.G3, NOTES.A3,
        NOTES.E3, NOTES.E3, NOTES.D3, NOTES.D3
    }

    -- Power chord notes for arpeggios
    local chord_roots = {
        {NOTES.E4, NOTES.G4, NOTES.B4},
        {NOTES.E4, NOTES.G4, NOTES.B4},
        {NOTES.G4, NOTES.B4, NOTES.D5},
        {NOTES.A4, NOTES.C5, NOTES.E5},
        {NOTES.E4, NOTES.G4, NOTES.B4},
        {NOTES.E4, NOTES.G4, NOTES.B4},
        {NOTES.D4, NOTES.F4, NOTES.A4},
        {NOTES.D4, NOTES.F4, NOTES.A4}
    }

    for bar = 0, loop_bars - 1 do
        local bar_start = bar * bar_duration
        local bass_note = bass_pattern[bar + 1] / 2

        -- Driving 8th note bass
        for eighth = 0, 7 do
            local note_start = math.floor((bar_start + eighth * beat_duration / 2) * SAMPLE_RATE)
            local note = generate_note(bass_note, beat_duration * 0.4, SAMPLE_RATE, sawtooth_wave, punchy_envelope, 0.45)

            for j, s in ipairs(note) do
                local idx = note_start + j
                if idx >= 1 and idx <= total_samples then
                    bass_samples[idx] = bass_samples[idx] + s
                end
            end
        end

        -- Fast arpeggios (16th notes)
        local chord = chord_roots[bar + 1]
        local arp_pattern = {1, 2, 3, 2, 1, 3, 2, 3, 1, 2, 3, 2, 1, 2, 3, 1}
        local sixteenth = beat_duration / 4

        for step = 0, 15 do
            local note_idx = arp_pattern[step + 1]
            local freq = chord[note_idx]
            local note_start = math.floor((bar_start + step * sixteenth) * SAMPLE_RATE)
            local note = generate_note(freq, sixteenth * 0.6, SAMPLE_RATE, pulse_wave, stab_envelope, 0.22, {width = 0.125})

            for j, s in ipairs(note) do
                local idx = note_start + j
                if idx >= 1 and idx <= total_samples then
                    arp_samples[idx] = arp_samples[idx] + s
                end
            end
        end

        -- Drums: driving beat
        for beat = 0, 3 do
            local beat_start = bar_start + beat * beat_duration

            -- Hi-hats on 16th notes
            for sixteenth_beat = 0, 3 do
                local hh_start = math.floor((beat_start + sixteenth_beat * beat_duration / 4) * SAMPLE_RATE)
                local hh_len = math.floor(beat_duration * 0.03 * SAMPLE_RATE)

                -- Accent on 8ths
                local accent = (sixteenth_beat % 2 == 0) and 0.2 or 0.1

                reset_noise()
                for j = 1, hh_len do
                    local t = (j - 1) / SAMPLE_RATE
                    local env = hihat_envelope(t, beat_duration * 0.03)
                    local idx = hh_start + j
                    if idx >= 1 and idx <= total_samples then
                        drums_samples[idx] = drums_samples[idx] + noise_wave() * env * accent
                    end
                end
            end

            -- Kick on 1 and 3, and on the "and" of 2 and 4
            local kick_beats = {0, 1.5, 2, 3.5}
            for _, kick_offset in ipairs(kick_beats) do
                if beat + kick_offset / 4 < 4 then
                    local actual_beat = beat + (kick_offset % 1) * 0.5
                    if kick_offset == 0 or kick_offset == 1.5 or kick_offset == 2 or kick_offset == 3.5 then
                        local is_on_beat = (beat == 0 or beat == 2) and (kick_offset % 2 == 0)
                        if is_on_beat or (kick_offset == 1.5 or kick_offset == 3.5) then
                            -- Simplified: kick on 1, 2-and, 3, 4-and
                        end
                    end
                end
            end

            -- Simplified kick pattern: 1, 2-and, 3, 4-and
            if beat == 0 or beat == 2 then
                local kick_start = math.floor(beat_start * SAMPLE_RATE)
                local kick_len = math.floor(beat_duration * 0.12 * SAMPLE_RATE)

                for j = 1, kick_len do
                    local t = (j - 1) / SAMPLE_RATE
                    local freq = 100 * math.exp(-t * 40) + 45
                    local phase = freq * t
                    local env = punchy_envelope(t, beat_duration * 0.12)
                    local idx = kick_start + j
                    if idx >= 1 and idx <= total_samples then
                        drums_samples[idx] = drums_samples[idx] + sine_wave(phase) * env * 0.5
                    end
                end
            end

            -- Snare on 2 and 4
            if beat == 1 or beat == 3 then
                local snare_start = math.floor(beat_start * SAMPLE_RATE)
                local snare_len = math.floor(beat_duration * 0.1 * SAMPLE_RATE)

                reset_noise()
                for j = 1, snare_len do
                    local t = (j - 1) / SAMPLE_RATE
                    local env = punchy_envelope(t, beat_duration * 0.1)
                    -- Mix noise with a pitched body
                    local body = sine_wave(200 * t) * 0.4
                    local noise = noise_wave() * 0.6
                    local idx = snare_start + j
                    if idx >= 1 and idx <= total_samples then
                        drums_samples[idx] = drums_samples[idx] + (body + noise) * env * 0.35
                    end
                end
            end
        end
    end

    -- Epic lead melody for gameplay excitement
    local melody = {
        -- Bar 1-2: Opening riff
        {NOTES.E5, 0.25}, {NOTES.G5, 0.25}, {NOTES.A5, 0.5}, {NOTES.G5, 0.25}, {NOTES.E5, 0.25}, {NOTES.D5, 0.5},
        {NOTES.E5, 0.25}, {NOTES.G5, 0.25}, {NOTES.A5, 0.25}, {NOTES.B5, 0.25}, {NOTES.A5, 0.5}, {NOTES.REST, 0.5},
        -- Bar 3-4: Response
        {NOTES.G5, 0.5}, {NOTES.A5, 0.25}, {NOTES.G5, 0.25}, {NOTES.E5, 0.5}, {NOTES.D5, 0.5},
        {NOTES.E5, 1.0}, {NOTES.REST, 0.5}, {NOTES.D5, 0.25}, {NOTES.E5, 0.25},
        -- Bar 5-6: Climb
        {NOTES.E5, 0.25}, {NOTES.F5, 0.25}, {NOTES.G5, 0.5}, {NOTES.A5, 0.5}, {NOTES.B5, 0.5},
        {NOTES.C6, 0.5}, {NOTES.B5, 0.25}, {NOTES.A5, 0.25}, {NOTES.G5, 0.5}, {NOTES.REST, 0.5},
        -- Bar 7-8: Resolution
        {NOTES.A5, 0.5}, {NOTES.G5, 0.25}, {NOTES.E5, 0.25}, {NOTES.D5, 0.5}, {NOTES.E5, 0.5},
        {NOTES.E5, 1.5}, {NOTES.REST, 0.5},
    }

    local melody_time = 0
    for _, note_data in ipairs(melody) do
        local freq = note_data[1]
        local duration = note_data[2] * beat_duration
        local note_start = math.floor(melody_time * SAMPLE_RATE)

        if freq > 0 then
            local note = generate_note(freq, duration * 0.85, SAMPLE_RATE, square_wave, lead_envelope, 0.35, {duty = 0.5})

            for j, s in ipairs(note) do
                local idx = note_start + j
                if idx >= 1 and idx <= total_samples then
                    lead_samples[idx] = lead_samples[idx] + s
                end
            end
        end

        melody_time = melody_time + duration
    end

    -- Mix all channels
    local mixed = {}
    for i = 1, total_samples do
        mixed[i] = bass_samples[i] + lead_samples[i] + arp_samples[i] + drums_samples[i]
    end

    -- Add delay
    mixed = add_delay(mixed, 0.12, 0.2, 0.15)

    -- Normalize
    normalize_samples(mixed, 0.85)

    return samples_to_sound_data(mixed)
end

-- Generate game over theme - slower, minor key, melancholic but still 80s
local function generate_gameover_theme()
    local bpm = 80
    local beat_duration = 60 / bpm
    local bar_duration = beat_duration * 4
    local loop_bars = 4

    local total_samples = math.floor(loop_bars * bar_duration * SAMPLE_RATE)

    local samples = {}
    for i = 1, total_samples do
        samples[i] = 0
    end

    reset_noise()

    -- Sad descending melody
    local melody = {
        {NOTES.E5, 1.0}, {NOTES.D5, 1.0}, {NOTES.C5, 1.0}, {NOTES.B4, 1.0},
        {NOTES.A4, 1.0}, {NOTES.G4, 1.0}, {NOTES.A4, 2.0},
        {NOTES.E4, 1.0}, {NOTES.F4, 0.5}, {NOTES.E4, 0.5}, {NOTES.D4, 1.0}, {NOTES.E4, 1.0},
    }

    -- Pad chords
    local chords = {
        {NOTES.A3, NOTES.C4, NOTES.E4},
        {NOTES.G3, NOTES.B3, NOTES.D4},
        {NOTES.A3, NOTES.C4, NOTES.E4},
        {NOTES.E3, NOTES.G3, NOTES.B3},
    }

    -- Generate pads
    for bar = 0, loop_bars - 1 do
        local bar_start = bar * bar_duration
        local chord = chords[bar + 1]

        for _, freq in ipairs(chord) do
            local note_start = math.floor(bar_start * SAMPLE_RATE)
            local note = generate_note(freq, bar_duration * 0.95, SAMPLE_RATE, triangle_wave, lead_envelope, 0.2)

            for j, s in ipairs(note) do
                local idx = note_start + j
                if idx >= 1 and idx <= total_samples then
                    samples[idx] = samples[idx] + s
                end
            end
        end

        -- Slow bass
        local bass_freq = chord[1] / 2
        local bass_start = math.floor(bar_start * SAMPLE_RATE)
        local bass = generate_note(bass_freq, bar_duration * 0.8, SAMPLE_RATE, sine_wave, punchy_envelope, 0.35)

        for j, s in ipairs(bass) do
            local idx = bass_start + j
            if idx >= 1 and idx <= total_samples then
                samples[idx] = samples[idx] + s
            end
        end
    end

    -- Generate melody
    local melody_time = 0
    for _, note_data in ipairs(melody) do
        local freq = note_data[1]
        local duration = note_data[2] * beat_duration
        local note_start = math.floor(melody_time * SAMPLE_RATE)

        if freq > 0 then
            local note = generate_note(freq, duration * 0.9, SAMPLE_RATE, square_wave, lead_envelope, 0.3, {duty = 0.5})

            for j, s in ipairs(note) do
                local idx = note_start + j
                if idx >= 1 and idx <= total_samples then
                    samples[idx] = samples[idx] + s
                end
            end
        end

        melody_time = melody_time + duration
    end

    -- Add reverb-like delay
    samples = add_delay(samples, 0.25, 0.35, 0.3)

    normalize_samples(samples, 0.8)

    return samples_to_sound_data(samples)
end

--------------------------------------------------------------------------------
-- Track cache
--------------------------------------------------------------------------------

local track_cache = {}

local function get_or_generate_track(name)
    if track_cache[name] then
        return track_cache[name]
    end

    local sound_data = nil

    if name == "menu" then
        sound_data = generate_menu_theme()
    elseif name == "gameplay" then
        sound_data = generate_gameplay_theme()
    elseif name == "gameover" then
        sound_data = generate_gameover_theme()
    else
        return nil
    end

    if sound_data then
        track_cache[name] = love.audio.newSource(sound_data, "static")
        track_cache[name]:setLooping(true)
    end

    return track_cache[name]
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

-- Initialize the music system
function Music.load()
    if is_initialized then
        return true
    end

    local success, err = pcall(function()
        -- Pre-generate tracks in background (or on first play)
        -- For now, we generate on first play to reduce load time
        is_initialized = true
    end)

    if not success then
        print("Music system initialization warning: " .. tostring(err))
        return false
    end

    return true
end

-- Play a music track
-- @param track_name string: "menu", "gameplay", or "gameover"
function Music.play(track_name)
    if not is_initialized then
        Music.load()
    end

    -- Don't restart if same track is playing
    if current_track == track_name and current_source and current_source:isPlaying() then
        return
    end

    -- Stop current music
    Music.stop()

    local success, err = pcall(function()
        local source = get_or_generate_track(track_name)
        if source then
            source:setVolume(master_volume)
            source:play()
            current_source = source
            current_track = track_name
        end
    end)

    if not success then
        print("Music playback error: " .. tostring(err))
    end
end

-- Stop current music
function Music.stop()
    if current_source then
        local success, _ = pcall(function()
            current_source:stop()
        end)
        current_source = nil
        current_track = nil
    end
end

-- Pause current music
function Music.pause()
    if current_source then
        pcall(function()
            current_source:pause()
        end)
    end
end

-- Resume paused music
function Music.resume()
    if current_source then
        pcall(function()
            current_source:play()
        end)
    end
end

-- Set master volume (0-1)
function Music.set_volume(vol)
    master_volume = math.max(0, math.min(1, vol))
    if current_source then
        pcall(function()
            current_source:setVolume(master_volume)
        end)
    end
end

-- Get current volume
function Music.get_volume()
    return master_volume
end

-- Check if music is playing
function Music.is_playing()
    if current_source then
        local success, playing = pcall(function()
            return current_source:isPlaying()
        end)
        return success and playing
    end
    return false
end

-- Get current track name
function Music.get_current_track()
    return current_track
end

-- Fade out current music over duration seconds
function Music.fade_out(duration)
    duration = duration or 1.0
    -- Note: This would need to be called in an update loop
    -- For now, just stop
    Music.stop()
end

-- Pre-generate all tracks (call during loading screen if you have one)
function Music.preload_all()
    if not is_initialized then
        Music.load()
    end

    local tracks = {"menu", "gameplay", "gameover"}
    for _, track in ipairs(tracks) do
        pcall(function()
            get_or_generate_track(track)
        end)
    end
end

-- Clear the track cache (useful for memory management)
function Music.clear_cache()
    Music.stop()
    for name, source in pairs(track_cache) do
        pcall(function()
            source:stop()
        end)
    end
    track_cache = {}
end

return Music
