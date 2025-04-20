-- gameState.lua
local GameState = {}
GameState.__index = GameState

local instance = nil

function GameState.new()
    if instance then
        return instance
    end

    local self = setmetatable({}, GameState)
    self.currentState = "logo"  -- Initially start at logo
    self.gamePaused = false
    self.isLevelingUp = false
    instance = self
    return self
end


function GameState.getInstance()
    return GameState.new()
end



function GameState:setState(state)
    self.currentState = state
end

function GameState:getState()
    return self.currentState
end

function GameState:togglePause()
    self.gamePaused = not self.gamePaused
end

function GameState:setPause(state)
    self.gamePaused = state
end

function GameState:toggleLevelingUp()
    self.isLevelingUp = not self.isLevelingUp
end

function GameState:setLevelingUp(state)
    self.isLevelingUp = state
end



return GameState
