-- src/core/state_manager.lua
-- Simple game state machine

local StateManager = {}

local current_state = nil
local current_state_name = nil
local states = {}

function StateManager.register(name, state)
    states[name] = state
end

function StateManager.switch(name, ...)
    if current_state and current_state.exit then
        current_state:exit()
    end

    current_state = states[name]
    current_state_name = name

    if current_state and current_state.enter then
        current_state:enter(...)
    end
end

function StateManager.update(dt)
    if current_state and current_state.update then
        current_state:update(dt)
    end
end

function StateManager.draw()
    if current_state and current_state.draw then
        current_state:draw()
    end
end

function StateManager.keypressed(key)
    if current_state and current_state.keypressed then
        current_state:keypressed(key)
    end
end

function StateManager.keyreleased(key)
    if current_state and current_state.keyreleased then
        current_state:keyreleased(key)
    end
end

function StateManager.get_current()
    return current_state
end

function StateManager.get_current_name()
    return current_state_name
end

return StateManager
