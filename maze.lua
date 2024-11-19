-- maze.lua

local Maze = {}
Maze.__index = Maze
local Enemy = require("enemy")
local Collision = require("collision")


function Maze.new()
    local self = setmetatable({}, Maze)
    self.walls = {}
    self.decorations = {}
    self.backgroundImage = love.graphics.newImage("assets/mazemap.png") -- Load the background map
    self.backgroundImage:setWrap("clamp", "clamp")
      self.zoomFactor = 2  -- Define the zoom factor here
    self:createMaze()
    return self
end


  

function Maze:createMaze()
    local wallThickness = 100  -- Main wall thickness
    local cornerRadius = 16     -- Radius for larger corner circles

    self.walls = {
        -- Main walls with slight overlap adjustment for the top-left
        { x = 84 - 8, y = 84 - wallThickness, width = 3968, height = wallThickness },  -- Top wall, extended slightly to the left
        { x = 84, y = 4128 - 92, width = 3960, height = wallThickness },  -- Bottom wall
        { x = 84 - wallThickness, y = 84 - 8, width = wallThickness, height = 3968 },  -- Left wall, extended slightly downward
        { x = 4128 - 92, y = 84, width = wallThickness, height = 3960 }  -- Right wall
    }

    -- Define circular boundaries positioned toward the center in each corner
    self.cornerCircles = {
        { x = 84 + cornerRadius + 8, y = 84 + cornerRadius + 8, radius = cornerRadius },  -- Top-left corner circle
        { x = 4128 - 92 - cornerRadius - 8, y = 84 + cornerRadius + 8, radius = cornerRadius },  -- Top-right corner circle
        { x = 84 + cornerRadius + 8, y = 4128 - 92 - cornerRadius - 8, radius = cornerRadius },  -- Bottom-left corner circle
        { x = 4128 - 92 - cornerRadius - 8, y = 4128 - 92 - cornerRadius - 8, radius = cornerRadius }  -- Bottom-right corner circle
    }
end



function checkPlayerWallCollision(player, walls, cornerCircles)
    local isColliding = false

    -- Check wall collisions
    for _, wall in ipairs(walls) do
        if Collision.checkRectangle(player.x, player.y, player.width, player.height,
                                    wall.x, wall.y, wall.width, wall.height) then
            isColliding = true
            -- Resolve collision by adjusting player's position
            resolveCollision(player, wall)
        end
    end

    -- Check collisions with corner circles
    for _, circle in ipairs(cornerCircles) do
        -- Calculate player's center
        local playerCenterX = player.x + player.width / 2
        local playerCenterY = player.y + player.height / 2
        local dx = playerCenterX - circle.x
        local dy = playerCenterY - circle.y
        local distance = math.sqrt(dx * dx + dy * dy)
        local radiusSum = circle.radius + player.width / 2

        -- If player is within the circle's radius, resolve collision
        if distance < radiusSum then
            isColliding = true
            -- Adjust player position to be just outside the circle
            if distance == 0 then
                dx, dy = 1, 0  -- Avoid division by zero
                distance = 1
            end
            local overlap = radiusSum - distance
            player.x = player.x + (dx / distance) * overlap
            player.y = player.y + (dy / distance) * overlap
        end
    end

-- Define symmetrical clamping boundaries with a 16-pixel buffer
local buffer = 16

local leftBoundary = 84 + buffer
local rightBoundary = 4128 - buffer - player.width
local topBoundary = 84 + buffer
local bottomBoundary = 4128 - buffer - player.height

-- Clamp player position
Collision.clampPosition(player, leftBoundary, rightBoundary, topBoundary, bottomBoundary)



    return isColliding
end







function Maze:spawnEnemy()
    local enemyTypes = {"goblin", "slime"}
    local enemyType = enemyTypes[math.random(#enemyTypes)]

    -- Use original coordinates
  local positions = {
        { x = math.random(116, 4128 - 148), y = 116 },
        { x = math.random(116, 4128 - 148), y = 4128 - 148 },
        { x = 116, y = math.random(116, 4128 - 148) },
        { x = 4128 - 148, y = math.random(116, 4128 - 148) }
    }
    local pos = positions[math.random(#positions)]

    table.insert(enemies, Enemy.new(enemyType, pos.x, pos.y, experience.level))
end

function Maze:draw()
    -- Draw background and walls
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.backgroundImage, 0, 0, 0, self.zoomFactor, self.zoomFactor)

    -- Draw walls
    for _, wall in ipairs(self.walls) do
        love.graphics.setColor(1, 0, 0, 0.5)  -- Semi-transparent red for walls
        love.graphics.rectangle("fill", wall.x, wall.y, wall.width, wall.height)
    end

    -- Draw corner circles for debugging
    for _, circle in ipairs(self.cornerCircles) do
        love.graphics.setColor(0, 0, 1, 0.5)  -- Semi-transparent blue for corner circles
        love.graphics.circle("fill", circle.x, circle.y, circle.radius)
    end
end


return Maze
