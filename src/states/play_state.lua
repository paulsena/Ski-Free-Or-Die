-- src/states/play_state.lua
-- Main gameplay state - uses modular entity system

local Skier = require("src.entities.skier")
local Utils = require("src.lib.utils")
local Camera = require("src.lib.camera")
local Colors = require("src.colors")
local WorldManager = require("src.world.world_manager")
local Yeti = require("src.entities.yeti")
local Config = require("src.core.config")
local Music = require("src.lib.music")
local SFX = require("src.lib.sfx")
local Particles = require("src.systems.particles")
local Collision = require("src.systems.collision")
local Leaderboard = require("src.core.leaderboard")
local StateManager = require("src.core.state_manager")

local PlayState = {}

local GAME_WIDTH = Config.GAME_WIDTH
local GAME_HEIGHT = Config.GAME_HEIGHT

-- Collision detection radius for nearby obstacle checks
local COLLISION_CHECK_RADIUS = 50

function PlayState:enter(params)
    self.mode = params and params.mode or "trial"

    -- Initialize camera
    self.camera = Camera.new()
    self.camera:set_offset(GAME_WIDTH / 2, GAME_HEIGHT * 0.3)

    -- Initialize skier
    self.skier = Skier.new(0, 0)
    self.prev_skier_y = 0

    -- Initialize world with mode for tile-based generation
    local world_mode = self.mode == "endless" and "endless" or "time_trial"
    self.world = WorldManager.new(nil, world_mode)
    self.world:initial_spawn()

    -- Initialize game state
    self.elapsed_time = 0
    self.distance = 0
    self.gates_passed = 0
    self.gates_missed = 0
    self.is_paused = false
    self.is_finished = false

    -- Particles system
    self.particles = Particles.new()

    -- Endless mode specific - Yeti
    if self.mode == "endless" then
        self.yeti = Yeti.new()
    else
        self.yeti = nil
    end

    -- Track previous input for particles
    self.was_turning = false

    -- Snap camera to start position
    self.camera:set_target(self.skier.x, self.skier.y)
    self.camera:snap()

    -- Initialize audio
    SFX.load()

    -- Play gameplay music
    Music.play("gameplay")
end

function PlayState:exit()
    -- Stop all sound effects
    SFX.stop_all()
end

function PlayState:update(dt)
    if self.is_paused or self.is_finished then
        return
    end

    -- Update timer
    self.elapsed_time = self.elapsed_time + dt

    -- Store previous position for gate checking
    self.prev_skier_y = self.skier.y

    -- Handle input and update skier
    -- Pass skier's screen X position (center of game width) for mouse control
    local skier_screen_x = GAME_WIDTH / 2
    self.skier:handle_input(dt, skier_screen_x)
    self.skier:update(dt, self.world:get_slope_bounds())

    -- Update camera
    self.camera:set_target(self.skier.x, self.skier.y)
    self.camera:update(dt)

    -- Update world (spawning/despawning)
    self.world:update(dt, self.skier.y)

    -- Check collisions
    self:check_collisions()

    -- Check gates
    self:check_gates()

    -- Check finish line for time trial mode
    if self.mode == "time_trial" and self.world:check_finish(self.skier.y) then
        self:game_over("finished")
    end

    -- Update distance
    self.distance = self.skier.y

    -- Update particles
    self.particles:update(dt)

    -- Emit snow spray particles while skiing
    -- Check if turning based on skier position (not center = turning)
    local is_turning = self.skier.position ~= Skier.POS_CENTER
    if not self.skier.is_crashed then
        self.particles:emit_snow_spray(
            self.skier.x,
            self.skier.y,
            self.skier:get_angle(),
            self.skier.speed,
            is_turning
        )
    end
    self.was_turning = is_turning

    -- Endless mode: update yeti
    if self.yeti then
        local caught = self.yeti:update(dt, self.skier.speed, self.skier.is_crashed)
        if caught then
            self:game_over("caught")
        end
    end
end

function PlayState:check_collisions()
    if self.skier.is_crashed or self.skier.is_immune then
        return
    end

    local nearby = Collision.get_nearby_obstacles(
        self.skier,
        self.world:get_obstacles(),
        COLLISION_CHECK_RADIUS
    )

    local hit_obstacle = Collision.check_skier_obstacles(self.skier, nearby)
    if hit_obstacle then
        Collision.resolve_obstacle_collision(self.skier, hit_obstacle, self.camera)

        -- Emit particles and play sounds based on collision type
        if hit_obstacle.collision_type == "crash" then
            self.particles:emit_crash(self.skier.x, self.skier.y)
            SFX.play("crash")
        else
            -- Minor impact particles and sound
            self.particles:emit(self.skier.x, self.skier.y, "impact_snow", 5)
            SFX.play("tree_hit")
        end
    end
end

function PlayState:check_gates()
    local passed, missed = Collision.check_skier_gates(
        self.skier,
        self.prev_skier_y,
        self.world:get_gates()
    )

    self.gates_passed = self.gates_passed + passed
    self.gates_missed = self.gates_missed + missed

    -- Emit gate particles and play sounds
    if passed > 0 then
        self.particles:emit_gate_pass(self.skier.x, self.skier.y, true)
        SFX.play("gate_pass")
    end
    if missed > 0 then
        self.particles:emit_gate_pass(self.skier.x, self.skier.y, false)
        SFX.play("gate_miss")
    end
end

function PlayState:game_over(reason)
    self.is_finished = true
    self.game_over_reason = reason
    -- Play game over music
    Music.play("gameover")
end

function PlayState:draw()
    self.camera:apply()

    -- Draw slope/snow background
    self:draw_slope()

    -- Draw world objects (gates and obstacles)
    self.world:draw(self.skier.y)

    -- Draw particles (behind skier)
    self.particles:draw()

    -- Draw skier
    self.skier:draw()

    self.camera:reset()

    -- Draw yeti if in endless mode (in screen space, after camera reset)
    if self.yeti then
        self.yeti:draw(self.camera.y, GAME_HEIGHT)
    end

    -- Draw crash indicator (important gameplay feedback)
    if self.skier.is_crashed then
        Colors.set(Colors.HOT_PINK)
        local crash_text = "CRASHED!"
        if self.skier.crash_timer > 0 then
            crash_text = string.format("CRASHED! %.1f", self.skier.crash_timer)
        end
        love.graphics.printf(crash_text, 0, GAME_HEIGHT / 2 - 6, GAME_WIDTH, "center")
    end

    -- Draw yeti warning in endless mode
    if self.mode == "endless" then
        self:draw_yeti_warning()
    end

    -- Draw game over overlay
    if self.is_finished then
        self:draw_game_over()
    end

    -- Draw pause overlay
    if self.is_paused then
        self:draw_pause()
    end
end

function PlayState:draw_slope()
    local visible_top = self.camera.y - GAME_HEIGHT
    local visible_bottom = self.camera.y + GAME_HEIGHT

    -- Draw snow ground
    Colors.set(Colors.SNOW)
    love.graphics.rectangle("fill",
        -WorldManager.SLOPE_WIDTH - 50,
        visible_top,
        (WorldManager.SLOPE_WIDTH + 50) * 2,
        visible_bottom - visible_top + 200
    )

    -- Draw ski track marks (decorative)
    Colors.set(Colors.SNOW_SHADOW)
    local track_spacing = 40
    local track_start = math.floor(visible_top / track_spacing) * track_spacing

    for y = track_start, visible_bottom, track_spacing do
        love.graphics.line(-100, y, -95, y + 25)
        love.graphics.line(100, y, 95, y + 25)
    end

    -- Draw slope edge markers (rope lines)
    love.graphics.setColor(0.6, 0.5, 0.3, 0.6)
    love.graphics.rectangle("fill",
        -WorldManager.SLOPE_WIDTH - 5,
        visible_top,
        3,
        visible_bottom - visible_top + 200
    )
    love.graphics.rectangle("fill",
        WorldManager.SLOPE_WIDTH + 2,
        visible_top,
        3,
        visible_bottom - visible_top + 200
    )

    -- Draw slope markers (distance indicators)
    Colors.set(Colors.ROCK_GRAY)
    local marker_spacing = 100
    local marker_start = math.floor(visible_top / marker_spacing) * marker_spacing

    for y = marker_start, visible_bottom, marker_spacing do
        love.graphics.rectangle("fill", -WorldManager.SLOPE_WIDTH - 12, y - 2, 8, 4)
        love.graphics.rectangle("fill", WorldManager.SLOPE_WIDTH + 4, y - 2, 8, 4)
    end
end

function PlayState:draw_yeti_warning()
    if not self.yeti then
        return
    end

    -- Use Yeti's built-in danger overlay
    self.yeti:draw_danger_overlay(GAME_WIDTH, GAME_HEIGHT)

    local zone = self.yeti:get_danger_zone()

    if zone == "danger" or zone == "critical" then
        -- Warning text
        Colors.set(Colors.HOT_PINK)
        local flash = math.floor(self.elapsed_time * 4) % 2 == 0
        if flash then
            local text = zone == "critical" and "YETI ALMOST HERE!" or "YETI APPROACHING!"
            love.graphics.printf(text, 0, 20, GAME_WIDTH, "center")
        end
    end

    -- Yeti distance indicator
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", GAME_WIDTH - 60, 16, 56, 10)
    Colors.set(Colors.SNOW_WHITE)
    love.graphics.print(string.format("Yeti: %dm", math.floor(-self.yeti.distance / 10)), GAME_WIDTH - 58, 17)
end

function PlayState:draw_game_over()
    -- Overlay
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)

    -- Title
    if self.game_over_reason == "caught" then
        Colors.set(Colors.HOT_PINK)
        love.graphics.printf("EATEN BY YETI!", 0, 40, GAME_WIDTH, "center")
    elseif self.game_over_reason == "finished" then
        Colors.set(Colors.MINT_GREEN)
        love.graphics.printf("TIME TRIAL COMPLETE!", 0, 40, GAME_WIDTH, "center")
    else
        Colors.set(Colors.HOT_PINK)
        love.graphics.printf("RUN COMPLETE!", 0, 40, GAME_WIDTH, "center")
    end

    -- Stats
    Colors.set(Colors.SNOW_WHITE)
    local y = 65
    love.graphics.printf(string.format("Distance: %dm", math.floor(self.distance / 10)), 0, y, GAME_WIDTH, "center")
    y = y + 15
    love.graphics.printf(string.format("Time: %s", Utils.format_time(self.elapsed_time)), 0, y, GAME_WIDTH, "center")
    y = y + 15
    love.graphics.printf(string.format("Gates: %d passed, %d missed", self.gates_passed, self.gates_missed), 0, y, GAME_WIDTH, "center")
    y = y + 15

    if self.gates_missed > 0 then
        Colors.set(Colors.HOT_PINK)
        love.graphics.printf(string.format("Penalty: +%d seconds", self.gates_missed * 3), 0, y, GAME_WIDTH, "center")
        y = y + 15
    end

    Colors.set(Colors.BRIGHT_YELLOW)
    local final_time = self.elapsed_time + self.gates_missed * 3
    love.graphics.printf(string.format("Final Time: %s", Utils.format_time(final_time)), 0, y + 10, GAME_WIDTH, "center")

    -- Restart prompt
    Colors.set(Colors.MINT_GREEN)
    love.graphics.printf("ENTER: Continue | R: Restart | ESC: Menu", 0, GAME_HEIGHT - 25, GAME_WIDTH, "center")
end

function PlayState:draw_pause()
    -- Overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)

    -- Pause text
    Colors.set(Colors.BRIGHT_YELLOW)
    love.graphics.printf("PAUSED", 0, GAME_HEIGHT / 2 - 20, GAME_WIDTH, "center")

    Colors.set(Colors.SNOW_WHITE)
    love.graphics.printf("ESC: Resume", 0, GAME_HEIGHT / 2 + 5, GAME_WIDTH, "center")
    love.graphics.printf("R: Restart", 0, GAME_HEIGHT / 2 + 20, GAME_WIDTH, "center")
    Colors.set(Colors.HOT_PINK)
    love.graphics.printf("Q: Quit to Menu", 0, GAME_HEIGHT / 2 + 35, GAME_WIDTH, "center")
end

function PlayState:keypressed(key)
    if key == "r" then
        -- Restart
        self:enter({mode = self.mode})
    elseif (key == "p" or key == "escape") and not self.is_finished then
        self.is_paused = not self.is_paused
        -- Pause/resume music
        if self.is_paused then
            Music.pause()
        else
            Music.resume()
        end
    elseif key == "q" and self.is_paused then
        -- Quit to menu from pause screen
        StateManager.switch("menu")
    elseif key == "m" then
        -- Toggle mute
        if Music.get_volume() > 0 then
            Music.set_volume(0)
        else
            Music.set_volume(0.7)
        end
    elseif key == "return" and self.is_finished then
        -- Check for high score on enter
        self:check_high_score()
    end
end

function PlayState:check_high_score()
    -- Calculate score based on game mode
    local stats = {
        time = self.elapsed_time,
        distance = self.distance,
        gates_passed = self.gates_passed,
        gates_missed = self.gates_missed
    }

    local score = Leaderboard.calculate_score(self.mode, stats)
    local qualifies, rank = Leaderboard.qualifies(self.mode, score)

    if qualifies then
        -- Go to name entry screen
        StateManager.switch("name_entry", {
            mode = self.mode,
            score = score,
            rank = rank,
            stats = stats
        })
    else
        -- Just go to high scores screen
        StateManager.switch("highscores", {mode = self.mode})
    end
end

return PlayState
