-- Tutorial.lua

local Tutorial = {}
local MapGenerator = require("map_generator")
local TileLoader   = require("tile_loader")
local Config       = require("config")
Tutorial.__index   = Tutorial

-- local Enemy        = require("enemy") -- No longer needed directly here
local EnemyPool    = require("enemyPool") -- <<< ADD THIS REQUIRE
local Collision    = require("collision")
local experience   = require("experience")
local GameState    = require("gameState")
local gameState    = GameState.new()
local Options      = require("options")
local EnemyGroup   = require("enemy_group")
local RandomItems  = require("random_items")
local ObjectManager = require("object_manager")  -- Cached here
local TriggerManager = require("trigger_manager")
local Soul = require("soul") -- Ensure Soul is required if not already

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

Tutorial.music = nil

-- >> ADDED: Property to store scripting flag
Tutorial.runScripting = true -- Default to true if not set otherwise
-- << END ADDED

--------------------------------------------------------------------------------
-- Helper function to get player character, to reduce duplication.
--------------------------------------------------------------------------------
function Tutorial:getPlayerChar()
    if player and player.characters then
        -- Always return Stormlich as the lead character
        return player.characters["Stormlich"]
    end
    return { x = 1000, y = 1000 }
end

--------------------------------------------------------------------------------
-- Additional constants and tweaks for the new spawn system
--------------------------------------------------------------------------------
local SPAWN_INTERVAL = 1.5        -- Spawn a new group every 1.5 seconds (was 3.0)
local SPAWN_GROUP_MIN = 3       -- Minimum group size
local SPAWN_GROUP_MAX = 5       -- Maximum group size
local SPAWN_DISTANCE_MIN = 300
local SPAWN_DISTANCE_MAX = 500

-- Timing thresholds for composition changes (in seconds)
local WEBBER_START_TIME = 120         -- After 2 minutes, add webber enemies
local WEBBER_INCREASE_INTERVAL = 120  -- Increase webber count every additional 2 minutes
local SPIDERV2_START_TIME = WEBBER_START_TIME + 120  -- spiderv2 start 2 minutes after webbers

-- (Optional: scaling/timer constants)
local TIME_SCALE_INTERVAL = 60
local TIME_SCALE_FACTOR   = 1.05

--------------------------------------------------------------------------------
-- Updated enemy group spawning function with enemy cap enforcement.
--------------------------------------------------------------------------------
function Tutorial:spawnEnemyGroup(groupComposition)
  local B = Config.boundaryMargin
  local W,H = Config.mapWidth, Config.mapHeight
  local PR = 8  -- player‐collision buffer
  for enemyType, count in pairs(groupComposition) do
    for i = 1, count do
      local p  = self:getPlayerChar()
      local ang= math.random()*2*math.pi
      local dist = math.random(SPAWN_DISTANCE_MIN, SPAWN_DISTANCE_MAX)
      local x = p.x + math.cos(ang)*dist
      local y = p.y + math.sin(ang)*dist
      -- clamp:
      x = math.max(B+PR, math.min(W-(B+PR), x))
      y = math.max(B+PR, math.min(H-(B+PR), y))
      -- Use EnemyPool.acquire
      table.insert(enemies, EnemyPool.acquire(enemyType, x, y, experience.level or 1))
    end
  end
end

--------------------------------------------------------------------------------
-- Updated determineGroupComposition function with new spawn logic.
--------------------------------------------------------------------------------
function Tutorial:determineGroupComposition()
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
        -- Only spiders spawn during the first minute
        composition["spider"] = groupSize
    elseif t < 120 then
        for i = 1, groupSize do
            if math_random() < 0.5 then
                addToComposition("spider")
            else
                addToComposition("webber")
            end
        end
    elseif t < 180 then
        for i = 1, groupSize do
            local roll = math_random(1, 3)
            if roll == 1 then
                addToComposition("spider")
            elseif roll == 2 then
                addToComposition("webber")
            else
                addToComposition("spiderv2")
            end
        end
    else
        for i = 1, groupSize do
            local roll = math_random(1, 4)
            if roll == 1 then
                addToComposition("spider")
            elseif roll == 2 then
                addToComposition("webber")
            elseif roll == 3 then
                addToComposition("spiderv2")
            else
                if countEnemyType("elite_spider") < 2 then
                    addToComposition("elite_spider")
                else
                    addToComposition("spider")
                end
            end
        end
    end

    return composition
end

--------------------------------------------------------------------------------
-- Add the special spawn group method:
function Tutorial:spawnSpecialGroup()
    local pChar = self:getPlayerChar()
    if not pChar then return end -- Safety check

    -- Define a central spawn point closer to the player
    local baseAngle = math_random() * 2 * math_pi -- Random direction from player
    local baseDistance = 250 -- Spawn the group center 100 units away (closer than SPAWN_DISTANCE_MIN)
    local groupCenterX = pChar.x + math_cos(baseAngle) * baseDistance
    local groupCenterY = pChar.y + math_sin(baseAngle) * baseDistance

    -- Spawn spiders around the group center with a small offset
    local spawnRadius = 40 -- Spawn spiders within this radius of the group center

    for i = 1, 7 do
        local offsetAngle = math_random() * 2 * math_pi
        local offsetDistance = math_random(0, spawnRadius)
        local posX = groupCenterX + math_cos(offsetAngle) * offsetDistance
        local posY = groupCenterY + math_sin(offsetAngle) * offsetDistance
        local xpLevel = (experience and experience.level) or 1

        -- Use EnemyPool.acquire
        local newEnemy = EnemyPool.acquire("spider", posX, posY, xpLevel, nil)
        table.insert(enemies, newEnemy)
    end
    print("[Tutorial] Spawned special spider group near player.") -- Debug print
end

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Tutorial.new(currentLevel) -- << REMOVED runScripting from parameters for now
    love.graphics.setBackgroundColor(0.086, 0.051, 0.074)
    local self = setmetatable({}, Tutorial)

    enemies = {}
    bosses  = {}
    self.objects = {}

    ObjectManager.loadAssets()

    if experienceGems then
        experienceGems = {}
    end
    if soulPickups then -- Clear souls from previous runs
        soulPickups = {}
    end
     if foodItems then -- Clear food from previous runs
        foodItems = {}
    end

    TileLoader.loadTiles()

    self.tileSize  = 16
    self.mapWidth  = 2064
    self.mapHeight = 2064

    -- generate map + hedge + spawn
    local mapData = MapGenerator.generateMap()
    self.tileMap = mapData.tiles
    self.trees   = mapData.trees

    -- expose for clamping later:
    Config.mapWidth       = mapData.width
    Config.mapHeight      = mapData.height
    Config.boundaryMargin = mapData.boundaryMargin

    self.spawnX = mapData.spawnX
    self.spawnY = mapData.spawnY

    -- place camera at spawn
    cameraX, cameraY = self.spawnX, self.spawnY
    -- your main game-logic should also place the player character here

    -- IMPORTANT: Ensure the actual player character (e.g., player.characters["Stormlich"])
    -- is ALSO positioned at (playerStartX, playerStartY) when the level loads.
    -- This positioning likely happens in your main game state loading logic,
    -- not directly within this Tutorial.new function.

    self.zoomFactor  = 2
    self.musicPath = "assets/sounds/music/spiderforest.wav"

    if gameState:getState() == "playing" and self.musicPath then
        self.music = playMusic(self.musicPath)
    end

    -- Fix RandomItems initialization for tutorial (minimal random spawning initially)
    self.randomItems = RandomItems.new({
        maxItems = 0, -- Don't spawn random items automatically initially
        spawnChance = 0, -- Disable random chance initially
        spawnInterval = 9999, -- Very long interval initially
        itemLifetime = 60, -- Give items decent lifetime if spawned manually (like the soul chest)
        statsSystem = statsSystem,
    })
    _G.randomItems = self.randomItems

    -- Make it globally accessible
    _G.randomItems = self.randomItems -- Use _G for clarity

    self.totalGameTimer = 0
    self.spawnTimer = 0
    self.timeScaleTimer = 0

    self.camera = {
        getPosition = function()
            return cameraX, cameraY
        end
    }

    self.fogImage = love.graphics.newImage("assets/fog.png")
    self.fogOffset = 0
    self.fogSpeed = 30

    self.enemyGroups       = {}
    self.enemyGroupConfigs = {}

    self.currentLevel = "tutorial" -- Explicitly set for the check in main.lua
    self.bossSpawned = false

    -- Instantiate the Trigger Manager with the gameState.
    self.triggerManager = TriggerManager.new(gameState)

    -- Tutorial sequence flags (initialize based on runScripting flag later)
    self.tutorialDialogTriggered = false
    self.specialSpawnTriggered = false
    self.autoAttackDialogTriggered = false
    self.levelUpExplanationTriggered = false -- NEW FLAG
    self.levelUpExplanationTriggerTime = -1 -- Time when level up explanation was triggered
    self.chestSpawnTriggered = false       -- NEW FLAG
    self.chestDialogTriggered = false      -- NEW FLAG
    self.randomSpawningActive = false -- <<< ADD THIS FLAG

    -- >> ADDED: Initialize runScripting (defaulting to true initially)
    self.runScripting = true -- Will be set by setScripting
    -- << END ADDED

    return self
end

-- >> ADDED: Method to set the scripting flag after creation
function Tutorial:setScripting(shouldRun)
    self.runScripting = shouldRun or false -- Ensure it's boolean, default false if nil
    print("[Tutorial] Scripting enabled:", self.runScripting)

    -- If scripting is disabled, immediately mark triggers as "done"
    if not self.runScripting then
        self.tutorialDialogTriggered = true
        self.specialSpawnTriggered = true -- Prevent special spawn
        self.autoAttackDialogTriggered = true
        -- Level up explanation is triggered by XP, leave it
        self.chestSpawnTriggered = true -- Prevent tutorial chest spawn
        self.chestDialogTriggered = true
        self.randomSpawningActive = true -- Enable random spawning immediately
        print("[Tutorial] Scripting disabled, skipping initial triggers and enabling random spawns.")
    end
end
-- << END ADDED

--------------------------------------------------------------------------------
-- update
--------------------------------------------------------------------------------
function Tutorial:update(dt)
    if Options.visible then
        Options.update(dt)
        return
    end
    -- Allow dialog advancement even if paused by level up screen
    -- if gameState.gamePaused or gameState.isLevelingUp then
    --     return
    -- end
    -- Check only for dialog pause
    if _G.dialog and _G.dialog.active then
        return -- Don't update game logic if dialog is showing
    end
    -- Also check for level up screen pause specifically for game logic updates
    if gameState.isLevelingUp then
        return
    end


    if self.fogImage then
        self.fogOffset = (self.fogOffset + dt * self.fogSpeed) % self.fogImage:getWidth()
    end

    self.totalGameTimer = self.totalGameTimer + dt
    self.timeScaleTimer = (self.timeScaleTimer or 0) + dt
    if self.timeScaleTimer >= TIME_SCALE_INTERVAL then
        self.timeScaleTimer = self.timeScaleTimer - TIME_SCALE_INTERVAL
        -- (Optional: Apply scaling logic here)
    end

    -- >> WRAPPED Tutorial Sequence in conditional block
    if self.runScripting then
        -- Sequence: Start Tutorial (Movement, Dash, Potion)
        if self.totalGameTimer >= 2 and not self.tutorialDialogTriggered then
            if self.triggerManager:try("startTutorial") then
                self.tutorialDialogTriggered = true
            end
        end

        -- Sequence: Spawn initial spiders
        if self.totalGameTimer >= 5 and not self.specialSpawnTriggered then
            self:spawnSpecialGroup()
            self.specialSpawnTriggered = true
        end

        -- Sequence: Auto Attack Explanation
        if self.totalGameTimer >= 8 and not self.autoAttackDialogTriggered then
             if self.triggerManager:try("autoAttack") then
                self.autoAttackDialogTriggered = true
             end
        end

       

        -- Sequence: Spawn Soul Chest & Explain Chests (Triggers a few seconds after level up explanation dialog finishes)
        -- Now relies on self.levelUpExplanationTriggered being set by experience.lua
        if self.levelUpExplanationTriggered and self.totalGameTimer >= self.levelUpExplanationTriggerTime + 3 then
            -- Spawn Chest (only once)
            if not self.chestSpawnTriggered then
                local pChar = self:getPlayerChar()
                if pChar then
                    -- Spawn further away at a random angle
                    local spawnDist = 150 -- Increased distance from 60/40 offset
                    local angle = math_random() * 2 * math_pi -- Random direction
                    local chestX = pChar.x + math_cos(angle) * spawnDist
                    local chestY = pChar.y + math_sin(angle) * spawnDist
                    self.randomItems:spawnSoulChest(chestX, chestY, 4) -- Use calculated position
                    self.chestSpawnTriggered = true
                end
            end
            -- Trigger Chest Dialog (only once, right after spawning, if no other dialog is active)
            if self.chestSpawnTriggered and not self.chestDialogTriggered and not (_G.dialog and _G.dialog.active) then
                 if self.triggerManager:try("chestExplanation") then
                    self.chestDialogTriggered = true
                 end
            end
        end

        -- Enable and update random item spawning after 30 seconds (only if scripting)
        if self.totalGameTimer >= 30 then
            if not self.randomSpawningActive then
                print("[Tutorial] Enabling random item spawning (Scripting Mode).")
                self.randomItems.spawnChance = 0.6
                self.randomItems.spawnInterval = 7
                self.randomItems.itemLifetime = 25
                self.randomItems.maxItems = 4
                self.randomSpawningActive = true
                self.randomItems.spawnTimer = self.randomItems.spawnInterval
            end
        end
    else -- If not running scripting
         -- Ensure random spawning is active immediately
         if not self.randomSpawningActive then
             print("[Tutorial] Enabling random item spawning (Non-Scripting Mode).")
             self.randomItems.spawnChance = 0.6
             self.randomItems.spawnInterval = 7
             self.randomItems.itemLifetime = 25
             self.randomItems.maxItems = 4
             self.randomSpawningActive = true
             self.randomItems.spawnTimer = self.randomItems.spawnInterval
         end
    end
    -- << END WRAPPED Block

    -- Update random items ONLY if active (handles both modes now)
    if self.randomSpawningActive and self.randomItems then
         self.randomItems:update(dt)
    end

    -- Regular enemy group spawns (start immediately if not scripting, after 30s if scripting)
    local canSpawnRegular = (not self.runScripting) or (self.runScripting and self.totalGameTimer >= 30)
    if canSpawnRegular then
        self.spawnTimer = self.spawnTimer + dt
        if self.spawnTimer >= SPAWN_INTERVAL then
            self.spawnTimer = self.spawnTimer - SPAWN_INTERVAL
            local composition = self:determineGroupComposition()
            self:spawnEnemyGroup(composition)
        end
    end

    -- Update random items (mainly for lifetime countdown and floating text)
    -- Note: Collision check happens in main.lua's handleCollisions
    -- if self.randomItems then
    --     self.randomItems:update(dt) -- This update is now handled in main.lua's "Dialog-Independent Updates"
    -- end

    for _, enemy in ipairs(enemies) do
        enemy:update(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities, self, self.zoomFactor, bosses)
    end

    -- Boss spawn (delayed if scripting, maybe sooner if not?)
    local bossSpawnTime = self.runScripting and 40 or 15 -- Spawn boss sooner if not scripting
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
            -- Trigger the boss explanation dialog ONLY if scripting
            if self.runScripting then
                self.triggerManager:try("bossExplanation")
            end
        end
    end

    if player and player.characters and self.trees and not player.hasteBuff then
        for _, tree in ipairs(self.trees) do
            for _, char in pairs(player.characters) do
                ObjectManager.handleCollision(tree, char)
            end
        end
    end

    -- fadeTransition update is handled in main.lua
    -- fadeTransition.update(dt)
end

--------------------------------------------------------------------------------
-- keypressed
--------------------------------------------------------------------------------
function Tutorial:keypressed(key)
    if Options.visible then
        Options.keypressed(key)
        return
    end
    if key == "escape" then
        Options.load()
        return
    end

    -- Manual test key ("t") will trigger the "startTutorial" dialog.
    if key == "t" then
        if not self.triggerManager:try("startTutorial") then
            -- fallback manual dialog test if needed:
            dialog:start({ { speaker = "Test", text = "This is a manual test dialog triggered by T." } })
        end
    end
end

--------------------------------------------------------------------------------
-- draw
--------------------------------------------------------------------------------
function Tutorial:draw(cameraZoom)
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

function Tutorial:isCompleted()
    return false
end

--------------------------------------------------------------------------------
return Tutorial

