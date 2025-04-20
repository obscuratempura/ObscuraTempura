-- SpiderForest.lua (Fast version of the spider level)

local SpiderForest = {}
local MapGenerator = require("map_generator")
local TileLoader   = require("tile_loader")
local Config       = require("config")
SpiderForest.__index   = SpiderForest

local EnemyPool    = require("enemyPool") -- <<< ADD THIS REQUIRE
local Collision    = require("collision")
local experience   = require("experience")
local GameState    = require("gameState")
local gameState    = GameState.new()
local Options      = require("options")
local EnemyGroup   = require("enemy_group")
local RandomItems  = require("random_items")
local ObjectManager = require("object_manager")
local Soul = require("soul") -- Ensure Soul is required

local fadeTransition = require("fadeTransition")
-- Cache global math functions and Love graphics getters.
local math_random   = math.random
local math_cos      = math.cos
local math_sin      = math.sin
local math_pi       = math.pi
local math_floor    = math.floor
local loveGetWidth  = love.graphics.getWidth
local loveGetHeight = love.graphics.getHeight

local promptFont   = love.graphics.newFont("fonts/gothic.ttf", 24)
local smallerFont  = love.graphics.newFont("fonts/gothic.ttf", 40)
local arrowImage   = love.graphics.newImage("assets/arrow.png")
local colorPalette = {
    {1, 1, 0, 1},
    {0, 1, 1, 1},
    {1, 0, 1, 1},
    {1, 0.5, 0, 1},
    {0.5, 0, 1, 1},
}

enemies = enemies or {}
bosses  = bosses or {}

SpiderForest.music = nil

--------------------------------------------------------------------------------
-- Helper function to get player character, to reduce duplication.
--------------------------------------------------------------------------------
function SpiderForest:getPlayerChar()
    if player and player.characters then
        -- Always return Stormlich as the lead character
        return player.characters["Stormlich"]
    end
    return { x = 1000, y = 1000 }
end

--------------------------------------------------------------------------------
-- Constants and tweaks for the new spawn system
--------------------------------------------------------------------------------
local SPAWN_INTERVAL = 1.5        -- Spawn a new group every 1.5 seconds
local SPAWN_GROUP_MIN = 3       -- Minimum group size
local SPAWN_GROUP_MAX = 5       -- Maximum group size
local SPAWN_DISTANCE_MIN = 300
local SPAWN_DISTANCE_MAX = 500

-- Timing thresholds for composition changes (in seconds) - Kept for variety
local WEBBER_START_TIME = 120
local WEBBER_INCREASE_INTERVAL = 120
local SPIDERV2_START_TIME = WEBBER_START_TIME + 120

local TIME_SCALE_INTERVAL = 60
local TIME_SCALE_FACTOR   = 1.05

--------------------------------------------------------------------------------
-- Enemy group spawning function
--------------------------------------------------------------------------------
function SpiderForest:spawnEnemyGroup(groupComposition)
    for enemyType, count in pairs(groupComposition) do
        for i = 1, count do
            local pChar    = self:getPlayerChar()
            local angle    = math_random() * 2 * math_pi
            local distance = math_random(SPAWN_DISTANCE_MIN, SPAWN_DISTANCE_MAX)
            local posX     = pChar.x + math_cos(angle) * distance
            local posY     = pChar.y + math_sin(angle) * distance
            local xpLevel  = (experience and experience.level) or 1

            -- Use EnemyPool.acquire
            local newEnemy = EnemyPool.acquire(enemyType, posX, posY, xpLevel, nil)
            table.insert(enemies, newEnemy)
        end
    end
end

--------------------------------------------------------------------------------
-- Determine group composition based on time (Kept for variety)
--------------------------------------------------------------------------------
function SpiderForest:determineGroupComposition()
    local groupSize = math_random(SPAWN_GROUP_MIN, SPAWN_GROUP_MAX)
    local composition = {}
    local t = self.totalGameTimer

    local function addToComposition(enemyType)
        composition[enemyType] = (composition[enemyType] or 0) + 1
    end

    local function countEnemyType(enemyType)
        local count = 0
        for _, enemy in ipairs(enemies) do
            if enemy.type == enemyType then
                count = count + 1
            end
        end
        return count
    end

    if t < 60 then
        composition["spider"] = groupSize
    elseif t < 120 then
        for i = 1, groupSize do
            if math_random() < 0.5 then addToComposition("spider") else addToComposition("webber") end
        end
    elseif t < 180 then
        for i = 1, groupSize do
            local roll = math_random(1, 3)
            if roll == 1 then addToComposition("spider") elseif roll == 2 then addToComposition("webber") else addToComposition("spiderv2") end
        end
    else
        for i = 1, groupSize do
            local roll = math_random(1, 4)
            if roll == 1 then addToComposition("spider")
            elseif roll == 2 then addToComposition("webber")
            elseif roll == 3 then addToComposition("spiderv2")
            else
                if countEnemyType("elite_spider") < 2 then addToComposition("elite_spider") else addToComposition("spider") end
            end
        end
    end

    return composition
end

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function SpiderForest.new()
    love.graphics.setBackgroundColor(0.086, 0.051, 0.074)
    local self = setmetatable({}, SpiderForest)

    enemies = {}
    bosses  = {}
    self.objects = {}

    ObjectManager.loadAssets()

    if experienceGems then experienceGems = {} end
    if soulPickups then soulPickups = {} end
    if foodItems then foodItems = {} end

    TileLoader.loadTiles()
    local mapData = MapGenerator.generateMap()
    self.tileMap = mapData.tiles
    self.trees = mapData.trees

    self.tileSize    = 16
    self.mapWidth    = 2064
    self.mapHeight   = 2064
    self.zoomFactor  = 2
    self.musicPath = "assets/sounds/music/spiderforest.wav"

    if gameState:getState() == "playing" and self.musicPath then
        self.music = playMusic(self.musicPath)
    end

    -- Initialize RandomItems - enable spawning immediately
    self.randomItems = RandomItems.new({
        maxItems = 4,
        spawnChance = 0.6,
        spawnInterval = 7,
        itemLifetime = 25,
        statsSystem = statsSystem,
    })
    _G.randomItems = self.randomItems
    self.randomItems.spawnTimer = self.randomItems.spawnInterval -- Start timer immediately

    self.totalGameTimer = 0
    self.spawnTimer = 0 -- Start spawn timer immediately
    self.timeScaleTimer = 0

    self.camera = {
        getPosition = function() return cameraX, cameraY end
    }

    self.fogImage = love.graphics.newImage("assets/fog.png")
    self.fogOffset = 0
    self.fogSpeed = 30

    self.enemyGroups       = {}
    self.enemyGroupConfigs = {}

    self.currentLevel = "spiderforest" -- Identify this level
    self.bossSpawned = false

    -- No TriggerManager or tutorial flags needed

    return self
end

-- No setScripting method needed

--------------------------------------------------------------------------------
-- update
--------------------------------------------------------------------------------
function SpiderForest:update(dt)
    if Options.visible then
        Options.update(dt)
        return
    end
    -- Check only for dialog pause (though unlikely in this version)
    if _G.dialog and _G.dialog.active then return end
    -- Check for level up screen pause
    if gameState.isLevelingUp then return end

    if self.fogImage then
        self.fogOffset = (self.fogOffset + dt * self.fogSpeed) % self.fogImage:getWidth()
    end

    self.totalGameTimer = self.totalGameTimer + dt
    self.timeScaleTimer = (self.timeScaleTimer or 0) + dt
    if self.timeScaleTimer >= TIME_SCALE_INTERVAL then
        self.timeScaleTimer = self.timeScaleTimer - TIME_SCALE_INTERVAL
        -- (Optional: Apply scaling logic here)
    end

    -- REMOVED Tutorial Sequence Logic

    -- Update random items (enabled from start)
    if self.randomItems then
         self.randomItems:update(dt)
    end

    -- Regular enemy group spawns (start immediately)
    self.spawnTimer = self.spawnTimer + dt
    if self.spawnTimer >= SPAWN_INTERVAL then
        self.spawnTimer = self.spawnTimer - SPAWN_INTERVAL
        local composition = self:determineGroupComposition()
        self:spawnEnemyGroup(composition)
    end

    for _, enemy in ipairs(enemies) do
        enemy:update(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities, self, self.zoomFactor, bosses)
    end

    -- Boss spawn at 5 seconds
    local bossSpawnTime = 5
    if self.totalGameTimer >= bossSpawnTime and not self.bossSpawned then
        local pChar = self:getPlayerChar()
        if pChar then
            local bossX = pChar.x + 150
            local bossY = pChar.y
            local xpLevel = (_G.experience and _G.experience.level) or 1
            -- Use EnemyPool.acquire
            local kristoffBoss = EnemyPool.acquire("kristoff", bossX, bossY, xpLevel, nil)
            kristoffBoss.spawnState = "active"
            table.insert(bosses, kristoffBoss)
            self.bossSpawned = true
            -- No boss explanation dialog needed
        end
    end

    if player and player.characters and self.trees and not player.hasteBuff then
        for _, tree in ipairs(self.trees) do
            for _, char in pairs(player.characters) do
                ObjectManager.handleCollision(tree, char)
            end
        end
    end
end

--------------------------------------------------------------------------------
-- keypressed
--------------------------------------------------------------------------------
function SpiderForest:keypressed(key)
    if Options.visible then
        Options.keypressed(key)
        return
    end
    if key == "escape" then
        Options.load()
        return
    end
    -- Removed test key 't'
end

--------------------------------------------------------------------------------
-- draw (Identical to original Tutorial:draw)
--------------------------------------------------------------------------------
function SpiderForest:draw(cameraZoom)
    cameraZoom = cameraZoom or 1
    local tileSize = self.tileSize or 16
    local screenWidth = loveGetWidth() / cameraZoom
    local screenHeight = loveGetHeight() / cameraZoom
    local scaleFactor = self.zoomFactor or 2

    local tileCountX = self.mapWidth / tileSize
    local tileCountY = self.mapHeight / tileSize

    love.graphics.setColor(1,1,1,1)
    local cx, cy = self.camera:getPosition()
    local startX = math_floor(cx / (tileSize * scaleFactor)) - 1
    local startY = math_floor(cy / (tileSize * scaleFactor)) - 1
    local endX = startX + math.ceil(screenWidth / (tileSize * scaleFactor)) + 2
    local endY = startY + math.ceil(screenHeight / (tileSize * scaleFactor)) + 2

    for y = startY, endY do
        local wy = ((y - 1) % tileCountY) + 1
        local tileRow = self.tileMap[wy]
        for x = startX, endX do
            local wx = ((x - 1) % tileCountX) + 1
            local tileID = tileRow[wx]
            local tile = TileLoader.tiles[tileID]
            local dx = (x - 1) * tileSize * scaleFactor
            local dy = (y - 1) * tileSize * scaleFactor
            if tile then
                love.graphics.draw(tile.image, tile.quad, dx, dy, 0, scaleFactor, scaleFactor)
            else
                love.graphics.setColor(1,0,1)
                love.graphics.rectangle("fill", dx, dy, tileSize * scaleFactor, tileSize * scaleFactor)
                love.graphics.setColor(1,1,1)
            end
        end
    end

    for _, tree in ipairs(self.trees) do
        local treeType = tree.type
        local treeDef = ObjectManager.definitions[treeType]
        if treeDef then
            local scale = treeDef.scale or 1
            love.graphics.draw(
                treeDef.image,
                tree.x - (treeDef.visualWidth * scale)/2,
                tree.y - (treeDef.visualHeight * scale)/2,
                0,
                scale,
                scale
            )
        end
    end

    for _, e in ipairs(enemies) do
        e:draw()
    end

    if self.randomItems then
        self.randomItems:draw()
    end

    love.graphics.push()
    love.graphics.origin()
    if self.fogImage then
        local fogWidth = self.fogImage:getWidth()
        local fogHeight = self.fogImage:getHeight()
        for y = 0, loveGetHeight(), fogHeight do
            for x = 0, loveGetWidth(), fogWidth do
                love.graphics.setColor(1, 1, 1, 0.3)
                love.graphics.draw(self.fogImage, x - self.fogOffset, y)
            end
        end
        love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.pop()

    if Options.visible then
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.origin()
        local popupW, popupH = 600, 400
        local popupX = (loveGetWidth() - popupW) / 2
        local popupY = (loveGetHeight() - popupH) / 2
        Options.draw(popupX, popupY, popupW, popupH, promptFont, colorPalette, arrowImage)
    end

    fadeTransition.draw()
end

function SpiderForest:isCompleted()
    -- Completion logic remains the same (e.g., boss defeated, timer, etc.)
    -- For now, assuming it's not time-based or needs specific conditions.
    return false
end

--------------------------------------------------------------------------------
return SpiderForest
