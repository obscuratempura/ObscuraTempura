local Level2 = {}
Level2.__index = Level2

function Level2.new()
    local self = setmetatable({}, Level2)
    self.walls = {}
    self.decorations = {}
    self.winConditionMet = false  -- A flag to track if the win condition is met
    self.playerPosition = {x = 200, y = 200}  -- Example starting position
    self.goal = {x = 3800, y = 3800, radius = 50}  -- Example goal position (end of the level)
    
    self:createBonepit()
    self:generateDecorations()
    return self
end

function Level2:createBonepit()
    -- Define the outer walls only for a large open space
    self.walls = {}

    -- Outer boundaries (4000x4000 play area)
    table.insert(self.walls, { x = 0, y = 0, width = 4000, height = 20 }) -- Top wall
    table.insert(self.walls, { x = 0, y = 3980, width = 4000, height = 20 }) -- Bottom wall
    table.insert(self.walls, { x = 0, y = 0, width = 20, height = 4000 }) -- Left wall
    table.insert(self.walls, { x = 3980, y = 0, width = 20, height = 4000 }) -- Right wall
end

function Level2:generateDecorations()
    self.decorations = {}
    local numDecorations = 500 -- Adjust the number for density

    local types = {"grass", "flower", "rock"}

    for i = 1, numDecorations do
        local decorationType = types[math.random(#types)]
        local x = math.random(40, 3960)
        local y = math.random(40, 3960)
        table.insert(self.decorations, { type = decorationType, x = x, y = y })
    end
end

function Level2:checkWinCondition()
    -- Check if player has reached the goal
    local dx = self.playerPosition.x - self.goal.x
    local dy = self.playerPosition.y - self.goal.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    if distance < self.goal.radius then
        self.winConditionMet = true
        print("Win condition met!")
    end
end

function Level2:update(dt)
    -- Example player movement (to be updated based on player input)
    -- self.playerPosition.x = self.playerPosition.x + playerSpeed * dt

    -- Check for win condition
    self:checkWinCondition()

    -- If win condition is met, exit to overworld
    if self.winConditionMet then
        gameState = "overworld"
        print("Returning to overworld...")
    end
end

function Level2:draw()
    -- Draw  Bonepit walls
    love.graphics.setColor(0.5, 0.5, 0.5)
    for _, wall in ipairs(self.walls) do
        love.graphics.rectangle("fill", wall.x, wall.y, wall.width, wall.height)
    end

    -- Draw decorations
    for _, deco in ipairs(self.decorations) do
        if deco.type == "grass" then
            love.graphics.setColor(0.0, 0.8, 0.0)
            love.graphics.rectangle("fill", deco.x, deco.y, 5, 5)
        elseif deco.type == "flower" then
            love.graphics.setColor(1.0, 0.0, 1.0)
            love.graphics.circle("fill", deco.x, deco.y, 3)
        elseif deco.type == "rock" then
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.polygon("fill", deco.x, deco.y, deco.x + 5, deco.y + 3, deco.x + 3, deco.y + 7, deco.x - 2, deco.y + 5)
        end
    end

    -- Draw the goal (example: a glowing circle)
    love.graphics.setColor(0, 1, 0)
    love.graphics.circle("fill", self.goal.x, self.goal.y, self.goal.radius)

    -- Draw the player (example: a red circle)
    love.graphics.setColor(1, 0, 0)
    love.graphics.circle("fill", self.playerPosition.x, self.playerPosition.y, 20)
end

return Level2
