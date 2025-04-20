-- Bonepit.lua

local Bonepit = {}
local MapGenerator = require("map_generator")
local TileLoader = require("tile_loader")
local Config = require("config")
Bonepit.__index = Bonepit

local Enemy = require("enemy")
local Collision = require("collision")
local experience = require("experience")
local GameState = require("gameState")
local gameState = GameState.new()
local Options = require("options")
local EnemyGroup = require("enemy_group")  -- Updated require

local promptFont = love.graphics.newFont("fonts/gothic.ttf", 24)
local smallerFont = love.graphics.newFont("fonts/gothic.ttf", 40)
local arrowImage = love.graphics.newImage("assets/arrow.png")
local colorPalette = {
    {1, 1, 0, 1},
    {0, 1, 1, 1},
    {1, 0, 1, 1},
    {1, 0.5, 0, 1},
    {0.5, 0, 1, 1},
}

enemies = enemies or {}
bosses = bosses or {}

Bonepit.music = nil

-- Survival-based constants
local SURVIVAL_TIME = 300
local ENEMY_SCALE_FACTOR = 1.10
local TIME_SCALE_INTERVAL = 60
local TIME_SCALE_FACTOR = 1.05

-- Special enemy spawn settings
local OSSKAR_INITIAL_SPAWN_TIME = 60
local OSSKAR_RESPAWN_DELAY = 60
local pumpkin_SPAWN_INTERVAL = 30

-- Constructor
function Bonepit.new(currentLevel)
    love.graphics.setBackgroundColor(0.086, 0.051, 0.074)
    local self = setmetatable({}, Bonepit)

    enemies = {}
    bosses = {}
    if experienceGems then
        experienceGems = {}
    end

    TileLoader.loadTiles()
    self.tileMap = MapGenerator.generateMap()
    self.tileSize = 16
    self.mapWidth = 2064
    self.mapHeight = 2064
    self.zoomFactor = 2
    self.musicPath = "assets/sounds/music/echoes_in_the_mist.mp3"

    self.music = nil
    if gameState:getState() == "playing" and self.musicPath then
        self.music = playMusic(self.musicPath)
        
   
    end

    self.totalGameTimer   = 0
    self.waveTimer        = 0
    self.currentWave      = 1
    self.waveActive       = false
    self.enemiesToSpawn   = {}

    self.timeScaleTimer   = 0

    self.gameTimer        = 0
    self.survivalTimer    = 0
    self.survivalConditionMet = false
    
    self.SURVIVAL_TIME = SURVIVAL_TIME

    self.osskarExists         = false
    self.firstOsskarSpawned   = false
    self.osskarRespawnTimer   = 0
    self.pumpkinTimer        = 0

    -- Initialize camera
    self.camera = {
        getPosition = function()
            return cameraX, cameraY  -- Replace with your actual camera position variables
        end
    }

    -- Initialize enemy groups list
    self.enemyGroups = {}
    -- Note: spawnInterval is now managed per group via direct configuration

    -- Set current level
    self.currentLevel = currentLevel or "bonepit"  -- Default to "bonepit" if not specified

    -- Define enemy group configurations directly within Bonepit.lua
    self.enemyGroupConfigs = {
        -- Example configurations for different waves or scenarios
        {
            enemyType = "spirit",
            groupSize = 8,
            speedFactor = 1.5,
            spawnDistance = 800,
            spawnInterval = 30,  -- seconds
        },
    
    }

    -- Begin wave #1
    self:beginWave(self.currentWave)

    -- Initialize group spawn timers
    self.groupSpawnTimers = {}
    for _, groupConfig in ipairs(self.enemyGroupConfigs) do
        self.groupSpawnTimers[_] = 0  -- Initialize spawn timers for each group
    end

    return self
end

-- Music control
function Bonepit:stopMusic()
    if self.music then
        self.music:stop()
        self.music = nil
        
    end
end

-- Helper: find first alive player char
function Bonepit:getAlivePlayer()
    if player and not player:isDefeated() then
        for _, char in pairs(player.characters) do
            return char
        end
    end
    return nil
end

-- Begin a wave
function Bonepit:beginWave(waveIndex)
    self.waveActive = true
    local baseEnemiesToSpawn = 5
    local waveMultiplier = math.min(1 + (waveIndex * 0.1), 3) -- Gradually ramp up to max 3x
    self.enemiesToSpawn = {}

    for i = 1, math.floor(baseEnemiesToSpawn * waveMultiplier) do
        local eType = "spider"
        if waveIndex % 5 == 0 then
            eType = "spirit"
        end
        if waveIndex >= 12 and math.random() < 0.1 then
            eType = "pumpkin"
        end
        table.insert(self.enemiesToSpawn, eType)
    end

  
end


-- Spawn an enemy offscreen
function Bonepit:spawnEnemiesOffScreen(enemyType)
    local targetPlayer = self:getAlivePlayer()
    if not targetPlayer then 
      
        return
    end

    local angle    = math.random() * 2 * math.pi
    local distance = math.random(300, 600)
    local posX     = targetPlayer.x + math.cos(angle) * distance
    local posY     = targetPlayer.y + math.sin(angle) * distance

   local newEnemy = Enemy.new(enemyType, posX, posY, experience.level, nil)
   newEnemy.type = enemyType -- Assign type to the enemy

    if enemyType == "Osskar" then
        self.osskarExists = true
        newEnemy.onDeath = function()
            self.osskarExists = false
            self.osskarRespawnTimer = OSSKAR_RESPAWN_DELAY
           
        end
    elseif enemyType == "pumpkin" then
        newEnemy.onDeath = function()
           
        end
    end

    local waveScale = 1.0 + (self.currentWave * 0.05) -- Adjusted scaling
    newEnemy.health   = newEnemy.health   * waveScale
    newEnemy.maxHealth= newEnemy.maxHealth* waveScale
    newEnemy.damage   = newEnemy.damage   * waveScale
    newEnemy.speed    = newEnemy.speed    * waveScale
    
    table.insert(enemies, newEnemy)
end

-- Trigger survival condition
function Bonepit:triggerSurvivalCondition()
    if not self.survivalConditionMet then
        self.survivalConditionMet = true
        
        self:increaseEnemyStatsByFactor(ENEMY_SCALE_FACTOR)
        self:spawnHugeWave()
    end
end

function Bonepit:increaseEnemyStatsByFactor(factor)
    for _, enemy in ipairs(enemies) do
        if not enemy.isDead and enemy.health > 0 then
            enemy.health   = enemy.health   * factor
            enemy.maxHealth= enemy.maxHealth* factor
            enemy.damage   = enemy.damage   * factor
            enemy.speed    = enemy.speed    * factor
        end
    end
   
end

function Bonepit:spawnHugeWave()
    local hordeSize = 60
    for i = 1, hordeSize do
        self:spawnEnemiesOffScreen("spider")
    end
   
end

-- Spawn special enemies
function Bonepit:spawnSpecialEnemy(enemyType)
    self:spawnEnemiesOffScreen(enemyType)
   
end

-- Spawn enemy group based on configuration
function Bonepit:spawnEnemyGroup(groupConfig)
    local player = self:getAlivePlayer()
    if not player then
        
        return
    end

    local newGroup = EnemyGroup.new(groupConfig, player, self.camera, self.zoomFactor)
    table.insert(self.enemyGroups, newGroup)
   
end

-- Update
function Bonepit:update(dt)
    if Options.visible then
        Options.update(dt)
        return
    end
    if gameState.gamePaused or gameState.isLevelingUp then
        return
    end

    self.totalGameTimer = self.totalGameTimer + dt
    self.waveTimer      = self.waveTimer + dt
    self.survivalTimer  = self.survivalTimer + dt
    self.pumpkinTimer  = self.pumpkinTimer + dt
    self.timeScaleTimer = (self.timeScaleTimer or 0) + dt

    -- Time-based scaling for future spawns
    if self.timeScaleTimer >= TIME_SCALE_INTERVAL then
        self.timeScaleTimer = self.timeScaleTimer - TIME_SCALE_INTERVAL
        self.futureSpawnFactor = (self.futureSpawnFactor or 1) * TIME_SCALE_FACTOR
       
    end

    -- Waves
    if self.waveTimer >= 10 then
        self.waveTimer = self.waveTimer - 10
        self.currentWave = self.currentWave + 1
        self:beginWave(self.currentWave)
        
    end

    -- Osskar respawn logic
    if not self.osskarExists and self.firstOsskarSpawned and self.osskarRespawnTimer > 0 then
        self.osskarRespawnTimer = self.osskarRespawnTimer - dt
        if self.osskarRespawnTimer <= 0 then
            self:spawnSpecialEnemy("Osskar")
        end
    end

    -- First Osskar spawn
    if (not self.osskarExists) and (not self.firstOsskarSpawned) and (self.totalGameTimer >= OSSKAR_INITIAL_SPAWN_TIME) then
        self:spawnSpecialEnemy("Osskar")
        self.firstOsskarSpawned = true
       
    end

    -- pumpkin spawns
  if self.pumpkinTimer >= pumpkin_SPAWN_INTERVAL then
    self.pumpkinTimer = self.pumpkinTimer - pumpkin_SPAWN_INTERVAL
    if self:getpumpkinCount() < 4 then
        self:spawnSpecialEnemy("pumpkin")

        
    end
end

    -- 15-minute survival check
    if (not self.survivalConditionMet) and (self.survivalTimer >= SURVIVAL_TIME) then
        self:triggerSurvivalCondition()
    end

    -- Spawn queued wave enemies
   if self.waveActive and #self.enemiesToSpawn > 0 then
    if self.gameTimer >= 1 then
        self.gameTimer = self.gameTimer - 1
        local eType = table.remove(self.enemiesToSpawn, 1)
        self:spawnEnemiesOffScreen(eType)
    else
        self.gameTimer = self.gameTimer + dt
    end
elseif self.waveActive and #self.enemiesToSpawn == 0 then
    self.waveActive = false
   
end

-- If no active wave, spawn enemy groups at intervals
if not self.waveActive and self.groupSpawnTimers then
    for index, groupConfig in ipairs(self.enemyGroupConfigs) do
        self.groupSpawnTimers[index] = self.groupSpawnTimers[index] + dt
        if self.groupSpawnTimers[index] >= groupConfig.spawnInterval then
            self.groupSpawnTimers[index] = self.groupSpawnTimers[index] - groupConfig.spawnInterval
            self:spawnEnemyGroup(groupConfig)
        end
    end
end

    -- Update all enemies
    for _, enemy in ipairs(enemies) do
       enemy:update(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities, Bonepit, self.zoomFactor, bosses)
    end

    -- Handle enemy group spawning based on group configurations
    for index, groupConfig in ipairs(self.enemyGroupConfigs) do
        if self.groupSpawnTimers[index] == nil then
            self.groupSpawnTimers[index] = 0
        end
        self.groupSpawnTimers[index] = self.groupSpawnTimers[index] + dt
        if self.groupSpawnTimers[index] >= groupConfig.spawnInterval then
            self.groupSpawnTimers[index] = self.groupSpawnTimers[index] - groupConfig.spawnInterval
            self:spawnEnemyGroup(groupConfig)
        end
    end

    -- Update all enemy groups
    for _, group in ipairs(self.enemyGroups) do
        group:update(dt)
    end

    -- Remove empty enemy groups
    for i = #self.enemyGroups, 1, -1 do
        local group = self.enemyGroups[i]
        if #group.enemies == 0 then
            group:destroy()
            table.remove(self.enemyGroups, i)
           
        end
    end
end

-- Key input
function Bonepit:keypressed(key)
    if Options.visible then
        Options.keypressed(key)
        return
    end
    if key == "escape" then
        Options.load()
        
    end
end

-- Drawing
function Bonepit:draw(cameraZoom)
    cameraZoom = cameraZoom or 1
    local tileSize = self.tileSize or 16
    local screenWidth = love.graphics.getWidth() / cameraZoom
    local screenHeight= love.graphics.getHeight() / cameraZoom
    local scaleFactor= 2

    love.graphics.setColor(1, 1, 1, 1)

    local cameraX, cameraY = self.camera:getPosition()

    local startX = math.floor(cameraX / (tileSize * scaleFactor)) - 1
    local startY = math.floor(cameraY / (tileSize * scaleFactor)) - 1
    local endX   = startX + math.ceil(screenWidth /(tileSize * scaleFactor)) + 2
    local endY   = startY + math.ceil(screenHeight/(tileSize * scaleFactor)) + 2

    for y = startY, endY do
        for x = startX, endX do
            local wrappedX = ((x - 1) % (self.mapWidth / tileSize)) + 1
            local wrappedY = ((y - 1) % (self.mapHeight / tileSize)) + 1
            local tileID = self.tileMap[wrappedY][wrappedX]
            local tile = TileLoader.tiles[tileID]
            if tile then
                local drawX = (x-1)*tileSize*scaleFactor
                local drawY = (y-1)*tileSize*scaleFactor
                love.graphics.draw(tile.image, tile.quad,
                                   drawX, drawY, 0, scaleFactor, scaleFactor)
            else
                love.graphics.setColor(1,0,1)
                love.graphics.rectangle("fill",(x-1)*tileSize*scaleFactor,(y-1)*tileSize*scaleFactor,
                                        tileSize*scaleFactor,tileSize*scaleFactor)
                love.graphics.setColor(1,1,1)
            end
        end
    end

    -- Draw enemies
    for _, enemy in ipairs(enemies) do
        enemy:draw()
    end

    -- Draw bosses if needed
    for _, boss in ipairs(bosses) do
        boss:draw()
    end

    -- Draw enemy groups
    for _, group in ipairs(self.enemyGroups) do
        group:draw()
    end

    -- Draw options if open
    if Options.visible then
        love.graphics.push()
        love.graphics.origin()
        local popupW, popupH = 600, 400
        local popupX = (love.graphics.getWidth()-popupW)/2
        local popupY = (love.graphics.getHeight()-popupH)/2
        Options.draw(popupX, popupY, popupW, popupH, promptFont, colorPalette, arrowImage)

        love.graphics.pop()
    end
end


function Bonepit:getpumpkinCount()
    local count = 0
    for _, enemy in ipairs(enemies) do
        if enemy.type == "pumpkin" and not enemy.isDead then
            count = count + 1
        end
    end
    return count
end




-- Add this method to determine if the level is completed
function Bonepit:isCompleted()
    -- Define your level completion logic here.
    
    -- Example: Boss defeated
    if self.boss and self.boss.isDead then
        return true
    end

    -- Example: Survived for a set time
    if self.survivalTimer and self.survivalTimer >= self.SURVIVAL_TIME then
        return true
    end

    -- If neither condition is met, the level is not yet completed
    return false
end




return Bonepit
