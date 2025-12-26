-- Ski Free Or Die! - Love2D Implementation
-- 80s-themed downhill skiing game

-- Color palette (80s aesthetic)
local COLORS = {
    hotPink = {1, 0.2, 0.6},
    electricBlue = {0.1, 0.6, 1},
    brightYellow = {1, 0.9, 0.2},
    mintGreen = {0.2, 1, 0.6},
    white = {1, 1, 1},
    snow = {0.95, 0.97, 1},
    darkBlue = {0.1, 0.1, 0.3},
}

-- Game state
local game = {
    state = "playing",  -- "menu", "playing", "gameover"
    scrollY = 0,
    scrollSpeed = 150,
    distance = 0,
}

-- Player state
local player = {
    x = 400,
    y = 150,
    width = 20,
    height = 30,
    vx = 0,
    vy = 0,
    angle = 0,
    isTucking = false,
    maxSpeed = 400,
    acceleration = 300,
    turnSpeed = 200,
    friction = 0.98,
}

-- Obstacles
local obstacles = {}
local obstacleTypes = {"tree", "rock", "cabin"}

-- Gates for slalom
local gates = {}
local gatesPassed = 0
local gatesMissed = 0

-- Spawn timer
local spawnTimer = 0
local spawnInterval = 1.5

function love.load()
    -- Set up pixel-perfect rendering
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Set background color (snow)
    love.graphics.setBackgroundColor(COLORS.snow)

    -- Initialize random seed
    math.randomseed(os.time())

    -- Spawn initial obstacles
    for i = 1, 5 do
        spawnObstacle(math.random(50, 750), 300 + i * 150)
    end

    -- Spawn initial gates
    for i = 1, 3 do
        spawnGate(400 + math.random(-200, 200), 400 + i * 250)
    end
end

function love.update(dt)
    if game.state ~= "playing" then return end

    -- Handle input
    handleInput(dt)

    -- Update player physics
    updatePlayer(dt)

    -- Scroll the world
    game.scrollY = game.scrollY + game.scrollSpeed * dt
    game.distance = game.distance + game.scrollSpeed * dt

    -- Increase scroll speed over time (progressive difficulty)
    game.scrollSpeed = math.min(400, 150 + game.distance / 500)

    -- Update obstacles
    updateObstacles(dt)

    -- Update gates
    updateGates(dt)

    -- Spawn new obstacles
    spawnTimer = spawnTimer + dt
    if spawnTimer >= spawnInterval then
        spawnTimer = 0
        spawnObstacle(math.random(50, 750), 700)
        if math.random() < 0.3 then
            spawnGate(math.random(100, 700), 700)
        end
    end

    -- Check collisions
    checkCollisions()
end

function handleInput(dt)
    -- Left/Right movement
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        player.vx = player.vx - player.turnSpeed * dt
        player.angle = math.max(-0.5, player.angle - 2 * dt)
    elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        player.vx = player.vx + player.turnSpeed * dt
        player.angle = math.min(0.5, player.angle + 2 * dt)
    else
        -- Return to neutral angle
        player.angle = player.angle * 0.95
    end

    -- Tuck (speed boost, less control)
    player.isTucking = love.keyboard.isDown("down") or love.keyboard.isDown("s")

    -- Slow down (more control)
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        player.vy = player.vy - player.acceleration * 0.5 * dt
    end
end

function updatePlayer(dt)
    -- Apply gravity/slope acceleration
    local accel = player.isTucking and player.acceleration * 1.5 or player.acceleration
    player.vy = player.vy + accel * dt

    -- Apply friction (more when not tucking)
    local fric = player.isTucking and 0.995 or player.friction
    player.vx = player.vx * fric
    player.vy = player.vy * fric

    -- Clamp speed
    local speed = math.sqrt(player.vx^2 + player.vy^2)
    if speed > player.maxSpeed then
        local scale = player.maxSpeed / speed
        player.vx = player.vx * scale
        player.vy = player.vy * scale
    end

    -- Update position
    player.x = player.x + player.vx * dt
    player.y = player.y + (player.vy - game.scrollSpeed) * dt

    -- Keep player on screen
    player.x = math.max(player.width/2, math.min(800 - player.width/2, player.x))
    player.y = math.max(50, math.min(400, player.y))
end

function spawnObstacle(x, y)
    local obs = {
        x = x,
        y = y,
        type = obstacleTypes[math.random(#obstacleTypes)],
        width = 30,
        height = 40,
    }
    table.insert(obstacles, obs)
end

function spawnGate(x, y)
    local gate = {
        x = x,
        y = y,
        width = 80,
        passed = false,
        missed = false,
    }
    table.insert(gates, gate)
end

function updateObstacles(dt)
    for i = #obstacles, 1, -1 do
        local obs = obstacles[i]
        obs.y = obs.y - game.scrollSpeed * dt

        -- Remove off-screen obstacles
        if obs.y < -50 then
            table.remove(obstacles, i)
        end
    end
end

function updateGates(dt)
    for i = #gates, 1, -1 do
        local gate = gates[i]
        gate.y = gate.y - game.scrollSpeed * dt

        -- Check if player passed through gate
        if not gate.passed and not gate.missed then
            if gate.y < player.y then
                if math.abs(player.x - gate.x) < gate.width / 2 then
                    gate.passed = true
                    gatesPassed = gatesPassed + 1
                else
                    gate.missed = true
                    gatesMissed = gatesMissed + 1
                end
            end
        end

        -- Remove off-screen gates
        if gate.y < -50 then
            table.remove(gates, i)
        end
    end
end

function checkCollisions()
    for _, obs in ipairs(obstacles) do
        if checkAABB(player.x - player.width/2, player.y - player.height/2,
                     player.width, player.height,
                     obs.x - obs.width/2, obs.y - obs.height/2,
                     obs.width, obs.height) then
            -- Collision! Game over
            game.state = "gameover"
        end
    end
end

function checkAABB(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x2 < x1 + w1 and
           y1 < y2 + h2 and y2 < y1 + h1
end

function love.draw()
    -- Draw ski tracks (decorative)
    drawSkiTracks()

    -- Draw gates
    for _, gate in ipairs(gates) do
        drawGate(gate)
    end

    -- Draw obstacles
    for _, obs in ipairs(obstacles) do
        drawObstacle(obs)
    end

    -- Draw player
    drawPlayer()

    -- Draw UI
    drawUI()

    -- Draw game over screen
    if game.state == "gameover" then
        drawGameOver()
    end
end

function drawSkiTracks()
    love.graphics.setColor(0.85, 0.88, 0.92)
    -- Simple decorative lines
    for i = 0, 10 do
        local y = (i * 80 - game.scrollY % 80)
        love.graphics.line(100, y, 120, y + 60)
        love.graphics.line(680, y, 700, y + 60)
    end
end

function drawPlayer()
    love.graphics.push()
    love.graphics.translate(player.x, player.y)
    love.graphics.rotate(player.angle)

    -- Body (hot pink jacket!)
    love.graphics.setColor(COLORS.hotPink)
    love.graphics.rectangle("fill", -8, -12, 16, 20, 3, 3)

    -- Head
    love.graphics.setColor(1, 0.85, 0.7)
    love.graphics.circle("fill", 0, -18, 8)

    -- Skis (electric blue)
    love.graphics.setColor(COLORS.electricBlue)
    if player.isTucking then
        -- Tucked position - skis together
        love.graphics.rectangle("fill", -3, 5, 6, 25, 2, 2)
    else
        -- Normal stance - skis apart
        love.graphics.rectangle("fill", -10, 5, 5, 25, 2, 2)
        love.graphics.rectangle("fill", 5, 5, 5, 25, 2, 2)
    end

    love.graphics.pop()
end

function drawObstacle(obs)
    if obs.type == "tree" then
        -- Tree trunk
        love.graphics.setColor(0.4, 0.25, 0.1)
        love.graphics.rectangle("fill", obs.x - 4, obs.y, 8, 20)
        -- Tree foliage (mint green)
        love.graphics.setColor(COLORS.mintGreen)
        love.graphics.polygon("fill",
            obs.x, obs.y - 25,
            obs.x - 18, obs.y + 5,
            obs.x + 18, obs.y + 5)
    elseif obs.type == "rock" then
        love.graphics.setColor(0.5, 0.5, 0.55)
        love.graphics.polygon("fill",
            obs.x, obs.y - 15,
            obs.x + 15, obs.y + 10,
            obs.x - 15, obs.y + 10)
    elseif obs.type == "cabin" then
        -- Cabin body
        love.graphics.setColor(0.6, 0.35, 0.15)
        love.graphics.rectangle("fill", obs.x - 20, obs.y - 10, 40, 30)
        -- Roof
        love.graphics.setColor(0.3, 0.15, 0.05)
        love.graphics.polygon("fill",
            obs.x, obs.y - 30,
            obs.x - 25, obs.y - 10,
            obs.x + 25, obs.y - 10)
        -- Door
        love.graphics.setColor(COLORS.brightYellow)
        love.graphics.rectangle("fill", obs.x - 5, obs.y + 5, 10, 15)
    end
end

function drawGate(gate)
    if gate.passed then
        love.graphics.setColor(COLORS.mintGreen)
    elseif gate.missed then
        love.graphics.setColor(COLORS.hotPink)
    else
        love.graphics.setColor(COLORS.brightYellow)
    end

    -- Left pole
    love.graphics.rectangle("fill", gate.x - gate.width/2 - 3, gate.y - 20, 6, 40)
    -- Right pole
    love.graphics.rectangle("fill", gate.x + gate.width/2 - 3, gate.y - 20, 6, 40)
    -- Banner
    love.graphics.rectangle("fill", gate.x - gate.width/2, gate.y - 18, gate.width, 8)
end

function drawUI()
    -- Background bar
    love.graphics.setColor(COLORS.darkBlue[1], COLORS.darkBlue[2], COLORS.darkBlue[3], 0.8)
    love.graphics.rectangle("fill", 0, 0, 800, 40)

    -- Distance
    love.graphics.setColor(COLORS.white)
    love.graphics.print(string.format("Distance: %dm", math.floor(game.distance / 10)), 20, 10)

    -- Gates
    love.graphics.setColor(COLORS.mintGreen)
    love.graphics.print(string.format("Gates: %d", gatesPassed), 200, 10)

    -- Missed gates (penalty)
    love.graphics.setColor(COLORS.hotPink)
    love.graphics.print(string.format("Missed: %d (+%ds)", gatesMissed, gatesMissed * 3), 320, 10)

    -- Speed indicator
    local speed = math.sqrt(player.vx^2 + player.vy^2)
    love.graphics.setColor(COLORS.electricBlue)
    love.graphics.print(string.format("Speed: %.0f", speed), 520, 10)

    -- Tuck indicator
    if player.isTucking then
        love.graphics.setColor(COLORS.brightYellow)
        love.graphics.print("TUCKING!", 680, 10)
    end
end

function drawGameOver()
    -- Overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, 800, 600)

    -- Game over text
    love.graphics.setColor(COLORS.hotPink)
    love.graphics.printf("GAME OVER!", 0, 200, 800, "center")

    love.graphics.setColor(COLORS.white)
    love.graphics.printf(string.format("Distance: %dm", math.floor(game.distance / 10)), 0, 250, 800, "center")
    love.graphics.printf(string.format("Gates Passed: %d", gatesPassed), 0, 280, 800, "center")
    love.graphics.printf(string.format("Time Penalty: +%d seconds", gatesMissed * 3), 0, 310, 800, "center")

    love.graphics.setColor(COLORS.mintGreen)
    love.graphics.printf("Press SPACE to restart", 0, 380, 800, "center")
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    if game.state == "gameover" and key == "space" then
        -- Restart game
        game.state = "playing"
        game.scrollY = 0
        game.scrollSpeed = 150
        game.distance = 0
        player.x = 400
        player.y = 150
        player.vx = 0
        player.vy = 0
        player.angle = 0
        obstacles = {}
        gates = {}
        gatesPassed = 0
        gatesMissed = 0
        spawnTimer = 0

        -- Spawn initial content
        for i = 1, 5 do
            spawnObstacle(math.random(50, 750), 300 + i * 150)
        end
        for i = 1, 3 do
            spawnGate(400 + math.random(-200, 200), 400 + i * 250)
        end
    end
end
