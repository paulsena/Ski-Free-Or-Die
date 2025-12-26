-- Love2D Configuration for Ski Free Or Die!
function love.conf(t)
    t.title = "Ski Free Or Die!"
    t.version = "11.4"  -- Love2D version
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = true
    t.window.vsync = 1

    -- 80s aesthetic - we'll use pixel-perfect rendering
    t.window.minwidth = 400
    t.window.minheight = 300

    -- Modules
    t.modules.audio = true
    t.modules.data = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false  -- We'll use custom physics
    t.modules.sound = true
    t.modules.system = true
    t.modules.timer = true
    t.modules.touch = true
    t.modules.video = false
    t.modules.window = true
    t.modules.thread = true
end
