-- src/lib/sfx.lua
-- Procedural sound effects system for Ski Free Or Die
-- Uses shared audio synthesis primitives

local AudioSynthesis = require("src.lib.audio_synthesis")

local SFX = {}

-- Audio settings (from shared module)
local SAMPLE_RATE = AudioSynthesis.SAMPLE_RATE

-- Import waveform generators
local square_wave = AudioSynthesis.square_wave
local triangle_wave = AudioSynthesis.triangle_wave
local sawtooth_wave = AudioSynthesis.sawtooth_wave
local sine_wave = AudioSynthesis.sine_wave
local noise_wave = AudioSynthesis.noise_wave
local reset_noise = AudioSynthesis.reset_noise

-- Import envelope generators
local punchy_envelope = AudioSynthesis.punchy_envelope
local quick_envelope = AudioSynthesis.quick_envelope

-- Import sample helpers
local normalize_samples = AudioSynthesis.normalize_samples
local samples_to_sound_data = AudioSynthesis.samples_to_sound_data

-- SFX cache
local sfx_cache = {}
local is_initialized = false

-- Master volume for SFX
local master_volume = 0.5

-- Track active cloned sources to prevent memory accumulation
local active_sources = {}

-- Clean up finished audio sources to free memory
local function cleanup_finished_sources()
    for i = #active_sources, 1, -1 do
        local source = active_sources[i]
        if not source:isPlaying() then
            source:release()
            table.remove(active_sources, i)
        end
    end
end

--------------------------------------------------------------------------------
-- Sound effect generators
--------------------------------------------------------------------------------

-- Generate ski loop sound - whooshing/sliding noise with rhythm
local function generate_ski_loop()
    local duration = 1.0 -- 1 second loop
    local num_samples = math.floor(duration * SAMPLE_RATE)
    local samples = {}

    reset_noise()

    -- Create a rhythmic whooshing pattern
    for i = 1, num_samples do
        local t = (i - 1) / SAMPLE_RATE

        -- Low frequency oscillation for rhythm (simulates ski strokes)
        local rhythm_freq = 2.5 -- Hz
        local rhythm_phase = rhythm_freq * t
        local rhythm_amp = 0.5 + 0.5 * math.sin(rhythm_phase * 2 * math.pi)

        -- Filtered noise for snow sliding sound
        local noise = noise_wave()

        -- Low-pass filter simulation (simple averaging)
        local cutoff_mod = 0.3 + 0.4 * rhythm_amp
        local filtered = noise * cutoff_mod

        -- Add subtle low rumble
        local rumble_freq = 60 + 20 * rhythm_amp
        local rumble = sine_wave(rumble_freq * t) * 0.15

        -- Combine
        local sample = filtered * 0.7 + rumble

        -- Envelope for smooth looping
        local loop_fade = 1.0
        if t < 0.05 then
            loop_fade = t / 0.05
        elseif t > duration - 0.05 then
            loop_fade = (duration - t) / 0.05
        end

        samples[i] = sample * loop_fade * 0.5
    end

    normalize_samples(samples, 0.6)
    return samples_to_sound_data(samples)
end

-- Generate crash sound - big impact with noise burst
local function generate_crash()
    local duration = 0.4
    local num_samples = math.floor(duration * SAMPLE_RATE)
    local samples = {}

    reset_noise()

    for i = 1, num_samples do
        local t = (i - 1) / SAMPLE_RATE

        -- Impact thud (descending pitch)
        local thud_freq = 120 * math.exp(-t * 12) + 40
        local thud = sine_wave(thud_freq * t) * punchy_envelope(t, duration)

        -- Crash noise burst
        local noise = noise_wave()
        local noise_env = math.exp(-t * 8) -- Sharp decay
        local crash_noise = noise * noise_env

        -- High frequency "crunch"
        local crunch_freq = 800 + 400 * noise
        local crunch = square_wave(crunch_freq * t, 0.3) * noise_env * 0.3

        -- Mix: heavy on thud, with noise texture
        samples[i] = thud * 0.6 + crash_noise * 0.3 + crunch * 0.1
    end

    normalize_samples(samples, 0.95)
    return samples_to_sound_data(samples)
end

-- Generate gate pass sound - bright positive chirp
local function generate_gate_pass()
    local duration = 0.15
    local num_samples = math.floor(duration * SAMPLE_RATE)
    local samples = {}

    for i = 1, num_samples do
        local t = (i - 1) / SAMPLE_RATE

        -- Ascending chirp (sounds positive/successful)
        local start_freq = 800
        local end_freq = 1600
        local freq = start_freq + (end_freq - start_freq) * (t / duration)

        -- Use square wave for bright 8-bit sound
        local wave = square_wave(freq * t, 0.5)

        -- Quick punchy envelope
        local env = quick_envelope(t, duration)

        samples[i] = wave * env
    end

    normalize_samples(samples, 0.7)
    return samples_to_sound_data(samples)
end

-- Generate gate miss sound - negative descending buzz
local function generate_gate_miss()
    local duration = 0.25
    local num_samples = math.floor(duration * SAMPLE_RATE)
    local samples = {}

    for i = 1, num_samples do
        local t = (i - 1) / SAMPLE_RATE

        -- Descending buzz (sounds negative/bad)
        local start_freq = 400
        local end_freq = 120
        local freq = start_freq + (end_freq - start_freq) * (t / duration)

        -- Use sawtooth for harsher sound
        local wave = sawtooth_wave(freq * t)

        -- Slightly longer envelope with decay
        local env = quick_envelope(t, duration)

        samples[i] = wave * env
    end

    normalize_samples(samples, 0.7)
    return samples_to_sound_data(samples)
end

-- Generate tree hit sound - medium impact with wood-like tone
local function generate_tree_hit()
    local duration = 0.2
    local num_samples = math.floor(duration * SAMPLE_RATE)
    local samples = {}

    reset_noise()

    for i = 1, num_samples do
        local t = (i - 1) / SAMPLE_RATE

        -- Wood-like thump (mid-frequency impact)
        local thump_freq = 180 * math.exp(-t * 10) + 80
        local thump = sine_wave(thump_freq * t) * punchy_envelope(t, duration)

        -- Wood crack noise
        local noise = noise_wave() * 0.3
        local noise_env = math.exp(-t * 15)

        samples[i] = thump * 0.7 + noise * noise_env * 0.3
    end

    normalize_samples(samples, 0.75)
    return samples_to_sound_data(samples)
end

--------------------------------------------------------------------------------
-- Cache management
--------------------------------------------------------------------------------

local function get_or_generate_sfx(name)
    if sfx_cache[name] then
        return sfx_cache[name]
    end

    local sound_data = nil

    if name == "ski_loop" then
        sound_data = generate_ski_loop()
    elseif name == "crash" then
        sound_data = generate_crash()
    elseif name == "gate_pass" then
        sound_data = generate_gate_pass()
    elseif name == "gate_miss" then
        sound_data = generate_gate_miss()
    elseif name == "tree_hit" then
        sound_data = generate_tree_hit()
    else
        return nil
    end

    if sound_data then
        sfx_cache[name] = love.audio.newSource(sound_data, "static")

        -- Set looping only for ski loop
        if name == "ski_loop" then
            sfx_cache[name]:setLooping(true)
        end
    end

    return sfx_cache[name]
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

-- Initialize the SFX system
function SFX.load()
    if is_initialized then
        return true
    end

    local success, err = pcall(function()
        -- Pre-generate common sounds to avoid lag on first play
        get_or_generate_sfx("gate_pass")
        get_or_generate_sfx("gate_miss")
        is_initialized = true
    end)

    if not success then
        print("SFX system initialization warning: " .. tostring(err))
        return false
    end

    return true
end

-- Play a sound effect
-- @param sfx_name string: "ski_loop", "crash", "gate_pass", "gate_miss", "tree_hit"
-- @param volume number: optional volume override (0-1)
function SFX.play(sfx_name, volume)
    if not is_initialized then
        SFX.load()
    end

    local success, err = pcall(function()
        local source = get_or_generate_sfx(sfx_name)
        if source then
            -- Clean up finished sources before creating new ones
            cleanup_finished_sources()

            -- Clone the source for overlapping sounds (except ski_loop)
            local play_source = source
            if sfx_name ~= "ski_loop" then
                play_source = source:clone()
                -- Track the cloned source for later cleanup
                table.insert(active_sources, play_source)
            end

            local vol = volume or master_volume
            play_source:setVolume(vol)
            play_source:play()

            return play_source
        end
    end)

    if not success then
        print("SFX playback error: " .. tostring(err))
    end
end

-- Stop a looping sound (mainly for ski_loop)
function SFX.stop(sfx_name)
    local source = sfx_cache[sfx_name]
    if source then
        pcall(function()
            source:stop()
        end)
    end
end

-- Stop all sounds
function SFX.stop_all()
    -- Stop cached sources
    for name, source in pairs(sfx_cache) do
        pcall(function()
            source:stop()
        end)
    end

    -- Stop and release all active cloned sources
    for i = #active_sources, 1, -1 do
        pcall(function()
            active_sources[i]:stop()
            active_sources[i]:release()
        end)
        table.remove(active_sources, i)
    end
end

-- Set master volume for all SFX (0-1)
function SFX.set_volume(vol)
    master_volume = math.max(0, math.min(1, vol))
end

-- Get current volume
function SFX.get_volume()
    return master_volume
end

-- Pre-generate all sound effects (call during loading screen)
function SFX.preload_all()
    if not is_initialized then
        SFX.load()
    end

    local sounds = {"ski_loop", "crash", "gate_pass", "gate_miss", "tree_hit"}
    for _, sound in ipairs(sounds) do
        pcall(function()
            get_or_generate_sfx(sound)
        end)
    end
end

-- Clear the SFX cache (useful for memory management)
function SFX.clear_cache()
    SFX.stop_all()
    sfx_cache = {}
    active_sources = {}
end

return SFX
