-- Love2D configuration - runs before love.load

local Config = require("src.core.config")

function love.conf(t)
    t.identity = "ski_free_or_die"
    t.version = "11.4"

    t.window.title = "Ski Free Or Die!"
    t.window.width = Config.GAME_WIDTH * Config.SCALE + (Config.SIDEBAR_WIDTH * 2)
    t.window.height = Config.GAME_HEIGHT * Config.SCALE
    t.window.resizable = true
    t.window.minwidth = Config.GAME_WIDTH
    t.window.minheight = Config.GAME_HEIGHT
    t.window.vsync = 1

    t.modules.joystick = false -- Not using gamepads yet
    t.modules.physics = false  -- We'll do our own physics
end
