-- conf.lua
-- Love2D configuration - runs before love.load

function love.conf(t)
    t.identity = "ski_free_or_die"
    t.version = "11.4"

    t.window.title = "Ski Free Or Die!"
    t.window.width = 960          -- 320 * 3
    t.window.height = 540         -- 180 * 3
    t.window.resizable = true
    t.window.minwidth = 320
    t.window.minheight = 180
    t.window.vsync = 1

    t.modules.joystick = false    -- Not using gamepads yet
    t.modules.physics = false     -- We'll do our own physics
end
