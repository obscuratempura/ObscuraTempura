-- enemy_group.lua

local Enemy = require("enemy")
local Collision = require("collision")
local Effects = require("effects")
local Abilities = require("abilities")

local EnemyGroup = {}
EnemyGroup.__index = EnemyGroup

-- Constructor for EnemyGroup
-- config: table containing group configurations
-- enemyType: string specifying the type of enemies in the group
-- groupSize: number of enemies in the group
-- speedFactor: multiplier for enemy speed
-- spawnDistance: distance from the player to spawn the group
-- spawnInterval: time between group spawns (optional)
function EnemyGroup.new(config, player, camera, zoomFactor)
    local self = setmetatable({}, EnemyGroup)
    self.player = player
    self.camera = camera
    self.zoomFactor = zoomFactor
    self.enemies = {}
    self.groupSize = config.groupSize or 8
    self.speedFactor = config.speedFactor or 1.5  -- Default speed multiplier
    self.spawnDistance = config.spawnDistance or 800  -- Default spawn distance from player
    self.enemyType = config.enemyType or "spirit"
    self.spawnInterval = config.spawnInterval or 30  -- Time between group spawns (optional)
    self.currentTarget = nil
    self.isMoving = false
    self:initGroup(config)
    return self
end

-- Initialize the group by spawning enemies off-screen
function EnemyGroup:initGroup(config)
    for i = 1, self.groupSize do
        local spawnPos = self:getOffScreenPosition()
        local enemyType = config.enemyTypeOverride and config.enemyTypeOverride[i] or self.enemyType
        local enemy = Enemy.new(enemyType, spawnPos.x, spawnPos.y, self.player.level, nil)
        enemy.speed = enemy.speed * self.speedFactor
        table.insert(self.enemies, enemy)
        table.insert(enemies, enemy)  -- Add to global enemies list
    end
    self:setNewTarget()
end

-- Get a random off-screen position based on camera bounds
function EnemyGroup:getOffScreenPosition()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local buffer = 100  -- Buffer to ensure enemies spawn completely off-screen

    local side = math.random(1, 4)  -- 1: top, 2: right, 3: bottom, 4: left
    local x, y

    if side == 1 then  -- Top
        x = self.player.x + math.random(-self.spawnDistance / 2, self.spawnDistance / 2)
        y = self.player.y - (screenHeight / 2 + buffer)
    elseif side == 2 then  -- Right
        x = self.player.x + (screenWidth / 2 + buffer)
        y = self.player.y + math.random(-self.spawnDistance / 2, self.spawnDistance / 2)
    elseif side == 3 then  -- Bottom
        x = self.player.x + math.random(-self.spawnDistance / 2, self.spawnDistance / 2)
        y = self.player.y + (screenHeight / 2 + buffer)
    else  -- Left
        x = self.player.x - (screenWidth / 2 + buffer)
        y = self.player.y + math.random(-self.spawnDistance / 2, self.spawnDistance / 2)
    end

    return {x = x, y = y}
end

-- Set a new target point opposite to the current position
function EnemyGroup:setNewTarget()
    self.currentTarget = self:getOffScreenPosition()
    self.isMoving = true
end

-- Update the group movement
function EnemyGroup:update(dt)
    if self.isMoving and self.currentTarget then
        for _, enemy in ipairs(self.enemies) do
            -- Calculate direction towards the target
            local dx = self.currentTarget.x - enemy.x
            local dy = self.currentTarget.y - enemy.y
            local distance = math.sqrt(dx * dx + dy * dy)

            if distance > 10 then  -- Threshold to consider as "reached"
                local dirX = dx / distance
                local dirY = dy / distance
                enemy.vx = dirX * enemy.speed
                enemy.vy = dirY * enemy.speed
            else
                -- Stop movement and set a new target
                enemy.vx = 0
                enemy.vy = 0
                self.isMoving = false
            end
        end
    else
        -- Wander randomly around the player
        for _, enemy in ipairs(self.enemies) do
            if math.random() < 0.02 then  -- 2% chance each frame to change direction
                local angle = math.random() * 2 * math.pi
                enemy.vx = math.cos(angle) * enemy.speed
                enemy.vy = math.sin(angle) * enemy.speed
            end

            -- Update position based on velocity
            enemy.x = enemy.x + enemy.vx * dt
            enemy.y = enemy.y + enemy.vy * dt

            -- Optional: Add boundary checks to prevent enemies from wandering too far
            local wanderRadius = 300
            local dx = enemy.x - self.player.x
            local dy = enemy.y - self.player.y
            local distance = math.sqrt(dx * dx + dy * dy)

            if distance > wanderRadius then
                -- Move back towards the player if too far
                local dirX = self.player.x - enemy.x
                local dirY = self.player.y - enemy.y
                local norm = math.sqrt(dirX * dirX + dirY * dirY)
                if norm > 0 then
                    enemy.vx = (dirX / norm) * enemy.speed
                    enemy.vy = (dirY / norm) * enemy.speed
                end
            end
        end

        -- Check if all enemies are outside the camera to set a new target
        local allOutside = true
        for _, enemy in ipairs(self.enemies) do
            if not self:isOutsideCamera(enemy.x, enemy.y) then
                allOutside = false
                break
            end
        end

        if allOutside then
            self:setNewTarget()
        end
    end

    -- Update each enemy in the group
    for _, enemy in ipairs(self.enemies) do
        enemy:update(dt, self.player, effects, enemies, damageNumbers, sounds, summonedEntities, Bonepit, self.zoomFactor, bosses)
    end
end

-- Check if a position is outside the camera view
function EnemyGroup:isOutsideCamera(x, y)
    local camX, camY = self.camera:getPosition()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local buffer = 50  -- Extra buffer to consider off-screen

    return x < camX - screenWidth / 2 - buffer or
           x > camX + screenWidth / 2 + buffer or
           y < camY - screenHeight / 2 - buffer or
           y > camY + screenHeight / 2 + buffer
end

-- Draw all enemies in the group
function EnemyGroup:draw()
    for _, enemy in ipairs(self.enemies) do
        enemy:draw()
    end
end

-- Remove the group and its enemies
function EnemyGroup:destroy()
    for _, enemy in ipairs(self.enemies) do
        -- Remove from global enemies list
        for i, existingEnemy in ipairs(enemies) do
            if existingEnemy == enemy then
                table.remove(enemies, i)
                break
            end
        end
    end
    self.enemies = {}
end

return EnemyGroup
