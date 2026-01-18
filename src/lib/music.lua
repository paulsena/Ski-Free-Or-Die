-- src/lib/music.lua
-- Procedural 80s chiptune music synthesis system
-- Think OutRun, California Games, Top Gear SNES vibes

local AudioSynthesis = require("src.lib.audio_synthesis")

local Music = {}

-- Audio settings (from shared module)
local SAMPLE_RATE = AudioSynthesis.SAMPLE_RATE

-- Import waveform generators
local square_wave = AudioSynthesis.square_wave
local triangle_wave = AudioSynthesis.triangle_wave
local sawtooth_wave = AudioSynthesis.sawtooth_wave
local sine_wave = AudioSynthesis.sine_wave
local noise_wave = AudioSynthesis.noise_wave
local pulse_wave = AudioSynthesis.pulse_wave
local reset_noise = AudioSynthesis.reset_noise

-- Import envelope generators
local adsr_envelope = AudioSynthesis.adsr_envelope
local punchy_envelope = AudioSynthesis.punchy_envelope
local stab_envelope = AudioSynthesis.stab_envelope
local lead_envelope = AudioSynthesis.lead_envelope
local hihat_envelope = AudioSynthesis.hihat_envelope

-- Import sample helpers
local normalize_samples = AudioSynthesis.normalize_samples
local samples_to_sound_data = AudioSynthesis.samples_to_sound_data

-- Music state
local current_source = nil
local current_track = nil
local master_volume = 0.4
local is_initialized = false

-- Note frequencies (A4 = 440Hz tuning)
local NOTES = {
    C2 = 65.41, D2 = 73.42, E2 = 82.41, F2 = 87.31, G2 = 98.00, A2 = 110.00, B2 = 123.47,
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

            -- Kick on 1 and 3
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

-- Generate awards ceremony theme - triumphant, Olympic-style fanfare with SNES/C64 vibes
local function generate_awards_theme()
    local bpm = 120
    local beat_duration = 60 / bpm
    local bar_duration = beat_duration * 4
    local loop_bars = 8

    local total_samples = math.floor(loop_bars * bar_duration * SAMPLE_RATE)

    -- Initialize channels
    local trumpet_samples = {}
    local brass_samples = {}
    local strings_samples = {}
    local bass_samples = {}
    local drums_samples = {}

    for i = 1, total_samples do
        trumpet_samples[i] = 0
        brass_samples[i] = 0
        strings_samples[i] = 0
        bass_samples[i] = 0
        drums_samples[i] = 0
    end

    reset_noise()

    -- Triumphant chord progression (C major - F major - G major - C major)
    local chords = {
        {NOTES.C4, NOTES.E4, NOTES.G4},  -- C major
        {NOTES.C4, NOTES.E4, NOTES.G4},  -- C major
        {NOTES.F3, NOTES.A3, NOTES.C4},  -- F major
        {NOTES.F3, NOTES.A3, NOTES.C4},  -- F major
        {NOTES.G3, NOTES.B3, NOTES.D4},  -- G major
        {NOTES.G3, NOTES.B3, NOTES.D4},  -- G major
        {NOTES.C4, NOTES.E4, NOTES.G4},  -- C major
        {NOTES.C4, NOTES.E4, NOTES.G4},  -- C major (resolution)
    }

    -- Bass line - root notes
    local bass_notes = {
        NOTES.C3, NOTES.C3, NOTES.F2, NOTES.F2,
        NOTES.G2, NOTES.G2, NOTES.C3, NOTES.C3
    }

    -- Olympic-style fanfare melody (inspired by awards ceremonies)
    local melody = {
        -- Bar 1-2: Fanfare opening
        {NOTES.C5, 0.75}, {NOTES.E5, 0.25}, {NOTES.G5, 1.0}, {NOTES.E5, 0.5}, {NOTES.G5, 0.5}, {NOTES.C6, 1.0},
        {NOTES.G5, 0.5}, {NOTES.E5, 0.5}, {NOTES.C5, 0.5}, {NOTES.E5, 0.5}, {NOTES.G5, 1.0}, {NOTES.REST, 0.5}, {NOTES.G5, 0.5},
        -- Bar 3-4: Response
        {NOTES.F5, 0.75}, {NOTES.A5, 0.25}, {NOTES.C6, 1.0}, {NOTES.A5, 0.5}, {NOTES.F5, 0.5}, {NOTES.A5, 1.0},
        {NOTES.G5, 0.5}, {NOTES.F5, 0.5}, {NOTES.E5, 0.5}, {NOTES.D5, 0.5}, {NOTES.C5, 1.0}, {NOTES.REST, 1.0},
        -- Bar 5-6: Build up
        {NOTES.G5, 0.5}, {NOTES.A5, 0.5}, {NOTES.B5, 0.5}, {NOTES.C6, 0.5}, {NOTES.D6, 1.0}, {NOTES.B5, 0.5}, {NOTES.G5, 0.5},
        {NOTES.D6, 0.5}, {NOTES.C6, 0.5}, {NOTES.B5, 0.5}, {NOTES.A5, 0.5}, {NOTES.G5, 1.5}, {NOTES.REST, 0.5},
        -- Bar 7-8: Triumphant finale
        {NOTES.E5, 0.5}, {NOTES.G5, 0.5}, {NOTES.C6, 1.0}, {NOTES.E6, 1.0}, {NOTES.C6, 0.5}, {NOTES.G5, 0.5},
        {NOTES.C6, 2.0}, {NOTES.REST, 2.0}
    }

    -- Generate bass
    for bar = 0, loop_bars - 1 do
        local bar_start = bar * bar_duration
        local bass_note = bass_notes[bar + 1]

        -- Whole notes for bass
        local note_start = math.floor(bar_start * SAMPLE_RATE)
        local note = generate_note(bass_note, bar_duration * 0.9, SAMPLE_RATE, sine_wave, lead_envelope, 0.4)

        for j, s in ipairs(note) do
            local idx = note_start + j
            if idx >= 1 and idx <= total_samples then
                bass_samples[idx] = bass_samples[idx] + s
            end
        end
    end

    -- Generate string pads (sustained chords)
    for bar = 0, loop_bars - 1 do
        local bar_start = bar * bar_duration
        local chord = chords[bar + 1]

        for _, freq in ipairs(chord) do
            local note_start = math.floor(bar_start * SAMPLE_RATE)
            local note = generate_note(freq, bar_duration * 0.95, SAMPLE_RATE, triangle_wave, lead_envelope, 0.2)

            for j, s in ipairs(note) do
                local idx = note_start + j
                if idx >= 1 and idx <= total_samples then
                    strings_samples[idx] = strings_samples[idx] + s
                end
            end
        end
    end

    -- Generate brass stabs (punchier chords on beats)
    for bar = 0, loop_bars - 1 do
        local bar_start = bar * bar_duration
        local chord = chords[bar + 1]

        -- Brass hits on beats 1 and 3
        for beat = 0, 1 do
            local beat_start = bar_start + beat * 2 * beat_duration
            for _, freq in ipairs(chord) do
                local note_start = math.floor(beat_start * SAMPLE_RATE)
                local note = generate_note(freq * 2, beat_duration * 0.9, SAMPLE_RATE, pulse_wave, stab_envelope, 0.25, {width = 0.3})

                for j, s in ipairs(note) do
                    local idx = note_start + j
                    if idx >= 1 and idx <= total_samples then
                        brass_samples[idx] = brass_samples[idx] + s
                    end
                end
            end
        end
    end

    -- Generate triumphant trumpet melody
    local melody_time = 0
    for _, note_data in ipairs(melody) do
        local freq = note_data[1]
        local duration = note_data[2] * beat_duration
        local note_start = math.floor(melody_time * SAMPLE_RATE)

        if freq > 0 then
            -- Use sawtooth for trumpet-like brightness
            local note = generate_note(freq, duration * 0.9, SAMPLE_RATE, sawtooth_wave, lead_envelope, 0.35)

            for j, s in ipairs(note) do
                local idx = note_start + j
                if idx >= 1 and idx <= total_samples then
                    trumpet_samples[idx] = trumpet_samples[idx] + s
                end
            end
        end

        melody_time = melody_time + duration
    end

    -- Generate ceremonial drums
    for bar = 0, loop_bars - 1 do
        local bar_start = bar * bar_duration

        for beat = 0, 3 do
            local beat_start = bar_start + beat * beat_duration

            -- Snare on beats 2 and 4
            if beat == 1 or beat == 3 then
                local snare_start = math.floor(beat_start * SAMPLE_RATE)
                local snare_len = math.floor(beat_duration * 0.15 * SAMPLE_RATE)

                reset_noise()
                for j = 1, snare_len do
                    local t = (j - 1) / SAMPLE_RATE
                    local env = punchy_envelope(t, beat_duration * 0.15)
                    local body = sine_wave(220 * t) * 0.3
                    local noise = noise_wave() * 0.7
                    local idx = snare_start + j
                    if idx >= 1 and idx <= total_samples then
                        drums_samples[idx] = drums_samples[idx] + (body + noise) * env * 0.3
                    end
                end
            end

            -- Kick on beat 1
            if beat == 0 then
                local kick_start = math.floor(beat_start * SAMPLE_RATE)
                local kick_len = math.floor(beat_duration * 0.2 * SAMPLE_RATE)

                for j = 1, kick_len do
                    local t = (j - 1) / SAMPLE_RATE
                    local freq = 90 * math.exp(-t * 35) + 45
                    local phase = freq * t
                    local env = punchy_envelope(t, beat_duration * 0.2)
                    local idx = kick_start + j
                    if idx >= 1 and idx <= total_samples then
                        drums_samples[idx] = drums_samples[idx] + sine_wave(phase) * env * 0.4
                    end
                end
            end

            -- Cymbal crashes on important moments (bar 1, 5, 7)
            if beat == 0 and (bar == 0 or bar == 4 or bar == 6) then
                local cymbal_start = math.floor(beat_start * SAMPLE_RATE)
                local cymbal_len = math.floor(beat_duration * 2 * SAMPLE_RATE)

                reset_noise()
                for j = 1, cymbal_len do
                    local t = (j - 1) / SAMPLE_RATE
                    local env = math.exp(-t * 2)
                    local idx = cymbal_start + j
                    if idx >= 1 and idx <= total_samples then
                        drums_samples[idx] = drums_samples[idx] + noise_wave() * env * 0.2
                    end
                end
            end
        end
    end

    -- Mix all channels
    local mixed = {}
    for i = 1, total_samples do
        mixed[i] = trumpet_samples[i] + brass_samples[i] + strings_samples[i] + bass_samples[i] + drums_samples[i]
    end

    -- Add subtle reverb for grandeur
    mixed = add_delay(mixed, 0.18, 0.3, 0.25)

    -- Normalize
    normalize_samples(mixed, 0.85)

    return samples_to_sound_data(mixed)
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
    elseif name == "awards" then
        sound_data = generate_awards_theme()
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
-- @param track_name string: "menu", "gameplay", "gameover", or "awards"
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

-- Pre-generate all tracks (call during loading screen if you have one)
function Music.preload_all()
    if not is_initialized then
        Music.load()
    end

    local tracks = {"menu", "gameplay", "gameover", "awards"}
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
