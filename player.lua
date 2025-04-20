--Player.lua
local Projectiles = require("projectile")
local Projectile = Projectiles.Projectile
local Config = require("config")
local Abilities = require("abilities")
local Collision = require("collision")
local Effects = require("effects")
local DamageNumber = require("damage_number")
local Bonepit = require("bonepit")
local Sprites = require("sprites")
local Link = require("link")
local talentSystem = require("talentSystem")
local experience = require("experience")
local ObjectManager = require("object_manager")
local performanceMetrics = {
    lastUpdate = 0,
    updateTimes = {},
    spikesDetected = 0,
    projectileCount = 0,
    effectCount = 0
}

local GrimreaperSpriteSheet = love.graphics.newImage("assets/grimreaper.png")
GrimreaperSpriteSheet:setFilter("nearest", "nearest")

local StormlichSpriteSheet = love.graphics.newImage("assets/stormlich.png")
StormlichSpriteSheet:setFilter("nearest", "nearest")

local EmberfiendSpriteSheet = love.graphics.newImage("assets/emberfiend.png")
EmberfiendSpriteSheet:setFilter("nearest", "nearest")

local Player = {}
Player.__index = Player

local sounds = {
    playerAttack = {
        Grimreaper = love.audio.newSource("/assets/sounds/effects/Grimreaper_attack.wav", "static"),
        Emberfiend = love.audio.newSource("/assets/sounds/effects/emberfiend_attack.wav", "static"),
        Stormlich = love.audio.newSource("/assets/sounds/effects/Stormlich_attack.wav", "static"),
    },
    statusEffect = {
        ignite = love.audio.newSource("/assets/sounds/effects/ignite.wav", "static"),
        poison = love.audio.newSource("/assets/sounds/effects/poison.wav", "static"),
    },
    ability = {
        necroticBreath = love.audio.newSource("/assets/sounds/effects/necroticbreath.wav", "static"),
        summon_goyle = love.audio.newSource("/assets/sounds/effects/summon_goyle.wav", "static"),
        summon_goyle2 = love.audio.newSource("/assets/sounds/effects/summon_goyle2.wav", "static"),
        explosion = love.audio.newSource("/assets/sounds/effects/explosion.wav", "static"),
        storm_arc = love.audio.newSource("/assets/sounds/effects/storm_arc.wav", "static"),
        Hellblast = love.audio.newSource("/assets/sounds/effects/freezinghellblast.wav", "static"),
        zephyrShield = love.audio.newSource("/assets/sounds/effects/zephyr_shield.wav", "static"),
        infernalRain = love.audio.newSource("/assets/sounds/effects/infernalrain.wav", "static"),
        blizzard = love.audio.newSource("/assets/sounds/effects/blizzard.wav", "static"),
    },
    -- New link expire sounds:
    hasteLinkExpire = love.audio.newSource("assets/sounds/effects/haste_link.wav", "static"),
    healLinkExpire = love.audio.newSource("assets/sounds/effects/heal_link.wav", "static"),
    summonLinkExpire = love.audio.newSource("assets/sounds/effects/summon_link.wav", "static"),
}

for _, sound in pairs(sounds.playerAttack) do
    sound:setVolume(0.1)
end
for _, sound in pairs(sounds.ability) do
    sound:setVolume(5)
end

local function profile(name, threshold, func)
  local startTime = love.timer.getTime()
  func()
  local elapsed = love.timer.getTime() - startTime
  if elapsed > (threshold or 0.001) then
    print(string.format("[PROFILE] %s took %.5f seconds", name, elapsed))
  end
end

local function updateAnimation(char, dt, force)
    if not char.animation then return end
    if force then
        char.animation.frame = char.animation.frame % char.animation.frames + 1
        char.animation.timer = 0
    else
        char.animation.timer = char.animation.timer + dt
        if char.animation.timer >= char.animation.interval then
            char.animation.timer = 0
            char.animation.frame = char.animation.frame % char.animation.frames + 1
        end
    end
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

function Player.new(statsSystem, existingEquipment)
    local self = setmetatable({}, Player)
    
    -- Basic player properties
    self.x = 2000
    self.y = 2000
    self.damageFlashTimer = 0
    self.baseTeamMaxHealth = 330  -- store your starting max health here
    self.teamMaxHealth = self.baseTeamMaxHealth
    self._teamHealth = self.teamMaxHealth
    self.statsSystem = statsSystem
    self.baseSpeed = 87.5        -- was 50    ×1.75
    self.equipmentSpeedBonus = 0
    self.talentSpeedBonus = 0
    self.hasteBonus = 0
    self.magneticBonus = 0
    self.statusEffects = {}
    self.leechOverflow = 0
    self.bloodSlimeExists = false
    self.sounds = sounds
    
    self.equipment = existingEquipment or ((Overworld and Overworld.equipment) or { equipped = { chest = nil } })

    -- Set up your characters
    self.characters = {
        Grimreaper = {
            x = self.x, y = self.y, type = "Grimreaper",
            width = 16, height = 16, attackSpeed = 0.75, baseAttackSpeed = 0.75,
            attackTimer = 0, damage = 10, baseDamage = 10,
            attackRange = 140, baseAttackRange = 140, speed = 87.5, baseSpeed = 87.5,
            abilities = {}, radius = 20, statusEffects = {},
            owner = self, damageFlashTimer = 0,
            spriteSheet = GrimreaperSpriteSheet,
            animation = { frame = 1, timer = 0, interval = 0.4, frames = 3 },
            isFacingRight = true,
            bounceOffset = 0, bounceTimer = 0,
            formationOffset = { x = 0, y = -22 },
            pullRange = 50, basePullRange = 50,
            grimReaperAbilityBonus = 0, grimReaperAbilityBonusPercent = 0,
        },
        Emberfiend = {
            x = self.x, y = self.y, type = "Emberfiend",
            width = 16, height = 16, attackSpeed = 1, baseAttackSpeed = 1,
            attackTimer = 0, damage = 18, baseDamage = 18,
            attackRange = 120, baseAttackRange = 120, speed = 87.5, baseSpeed = 87.5,
            abilities = {}, radius = 20, statusEffects = {},
            owner = self, damageFlashTimer = 0,
            spriteSheet = EmberfiendSpriteSheet,
            animation = { frame = 1, timer = 0, interval = 0.4, frames = 3 },
            isFacingRight = true,
            bounceOffset = 0, bounceTimer = 0,
            formationOffset = { x = -22, y = 22 },
            pullRange = 50, basePullRange = 50,
            emberfiendAbilityBonus = 0, emberfiendAbilityBonusPercent = 0,
        },
        Stormlich = {
            x = self.x, y = self.y, type = "Stormlich",
            width = 16, height = 16, attackSpeed = 1.5, baseAttackSpeed = 1.5,
            attackTimer = 0, damage = 13, baseDamage = 13,
            attackRange = 110, baseAttackRange = 105, speed = 87.5, baseSpeed = 87.5,
            abilities = {}, radius = 20, statusEffects = {},
            owner = self, damageFlashTimer = 0,
            spriteSheet = StormlichSpriteSheet,
            animation = { frame = 1, timer = 0, interval = 0.4, frames = 3 },
            isFacingRight = true,
            bounceOffset = 0, bounceTimer = 0,
            formationOffset = { x = 22, y = 22 },
            pullRange = 50, basePullRange = 50,
            stormlichAbilityBonus = 0, stormlichAbilityBonusPercent = 0,
        },
    }
    


  self.uiLinks = {}         -- existing positive link pool
self.negativeLinks = {}   -- enemy negative links
self.abilityLinksPool = {}  -- NEW: pool for ability links from upgrades



  self.positionHistory = {}  -- each element will be { x, y }
  self.historyDelay = 0.1     -- delay (in seconds) between snapshots
  self.historyTimer = 0       -- accumulator timer

    -- Initialize collections for entities and abilities
    self.summonedEntities = {}
    self.projectiles = {}
    self.damageNumbers = {}
    self.abilities = {}

    -- Apply talents first so that talent‐derived properties are set
    talentSystem.applyTalentsToPlayer(self)
    
    -- Now initialize abilities (which may rely on talent values)
    self:initializeAbilities()
    self.experience = experience.new(self)
    -- Dash variables, potion variables, etc.
    self.isDashing = false
    self.dashDuration = 0.3
    self.dashTimer = 0
    self.dashSpeed = 300
    self.dashCooldown = 0
    self.maxDashCooldown = 15
    self.startOffsets = {}
    self.endOffsets = {}
    self.dashFormationFactor = 0.2
    self.slowMultiplier = 1 
    self.potionCharge = 1

    local baseKillsNeeded = 20
    local killsReduced = self.alchemistBonus or 0
    local finalKillsNeeded = math.max(baseKillsNeeded - killsReduced, 1)
    self.potionFillPerKill = 1 / finalKillsNeeded
    
    local dashReduction = self.dashCooldownReduction or 0
    self.maxDashCooldown = math.max(0, 15 - dashReduction)

    self.maxDashCharges = 1
    if self.hasTwinSteps then
        self.maxDashCharges = 2
    end
    self.currentDashCharges = self.maxDashCharges
    
    local totalSpeedBonus = self.equipmentSpeedBonus + self.talentSpeedBonus + self.hasteBonus
    for _, char in pairs(self.characters) do
        char.speed = char.baseSpeed + self.equipmentSpeedBonus + self.talentSpeedBonus + (self.hasteBonus * 0.2)

    end
    
    self.arcaneEchoChance = 0
    self.spacePressed = false
    self.baseCritChance = 1
  
    self.foodConsumptionCount = 0
    self.foodConsumptionTimer = 0
    self.foodComaTextTimer = 0
    
    for _, char in pairs(self.characters) do
        char.vitalSurgeParticles = {}
    end

    self:recalculateStats()
    self:updateAvailableReels()
    self.linkTimer = 0
    self.linkLifetime = 0          -- NEW: Initialize link lifetime

    return setmetatable(self, Player)
end

function Player:updateAvailableReels()
  if self.experience.level >= 10 then
    self.availableAbilityLinks = 3
  elseif self.experience.level >= 3 then
    self.availableAbilityLinks = 2
  elseif self.experience.level >= 2 then
    self.availableAbilityLinks = 1
  else
    self.availableAbilityLinks = 0
  end
end



function Player:takeDamage(amount, ...)
    local effectiveDamage = amount * (100 / (self.armor + 100))
  
    self._teamHealth = math.max(self._teamHealth - effectiveDamage, 0)
end


function Player:initializeAbilities()
   local abilityToggles = {
    Grimreaper = {
        { name = "Phantom Fright", enabled = false },
        { name = "Necrotic Breath", enabled = false },
        { name = "Unholy Ground", enabled = false },
        { name = "Summon Goyle", enabled = false },
        { name = "Necrotic Burst", enabled = false },
    },
    Emberfiend = {
        { name = "Molten Orbs", enabled = false },
        { name = "Hellblast", enabled = false },
        { name = "Infernal Rain", enabled = false },
        { name = "Flame Burst", enabled = false },
        { name = "Infernal Sacrifice", enabled = false },
    },
    Stormlich = {
        { name = "Blizzard", enabled = false },
        { name = "Storm Arc", enabled = false },
        { name = "Discharge", enabled = false },
        { name = "Zephyr Shield", enabled = false },
    },
    General = {
        { name = "Increase Attack Speed", enabled = false },
        { name = "Increase Attack Damage", enabled = false },
        { name = "Increase Attack Range", enabled = false },
        { name = "Increase Max Health", enabled = false },
        { name = "Increase Pull Range", enabled = false },
        { name = "Experience Heal", enabled = false },
      
    },
}

    
   
      -- If "Goyle’s Awakening" talent is at Rank 3, force Unholy Ground to be enabled.
    if self.goylesAwakeningRank and self.goylesAwakeningRank == 3 then
        for _, ability in ipairs(abilityToggles["Grimreaper"]) do
            if ability.name == "Unholy Ground" then
                ability.enabled = true
            end
        end
    end
    
    if self.frozenFuryRank and self.frozenFuryRank == 3 then
    for _, ability in ipairs(abilityToggles["Stormlich"]) do
        if ability.name == "Blizzard" then
            ability.enabled = true
        end
    end
end

if self.emberLegacy and self.emberLegacy == 3 then
    for _, ability in ipairs(abilityToggles["Emberfiend"]) do
        if ability.name == "Infernal Sacrifice" then
            ability.enabled = true
        end
    end
end



   for charName, char in pairs(self.characters) do
        if abilityToggles[charName] then
            for _, ability in ipairs(abilityToggles[charName]) do
                if ability.enabled then
                    Abilities.upgradeAbility(char, ability.name)
                end
            end
        end
    end

-- Existing block for player-level abilities (class == nil)
for abilityName, abilityDef in pairs(Abilities.abilityList) do
    if not abilityDef.class then
        Abilities.upgradeAbility(self, abilityName)
    end
end

-- NEW: Process General upgrades via toggles
if abilityToggles.General then
    for _, upgrade in ipairs(abilityToggles.General) do
        if upgrade.enabled then
            Abilities.upgradeGeneralAbility(self, upgrade.name)
        end
    end
end



  


end

function Player:addPotionCharge(amount)
    self.potionCharge = math.min(1, self.potionCharge + amount)
  
end

function Player:usePotion()
    if self.potionCharge >= 1 then
        local healPercent = self.herbalInfusionActive and 0.50 or 0.25
        -- Heal by directly updating _teamHealth
        self._teamHealth = math.min(
            self._teamHealth + (self.teamMaxHealth * healPercent),
            self.teamMaxHealth
        )
        self.potionCharge = 0
        if self.hasWitchsDraught then
            self:applyRandomPotionBuff()
        end
        if self.statsSystem and self.statsSystem.addPotionUsed then
            self.statsSystem:addPotionUsed()
        end
    end
end


   function Player:applyStatusEffect(char, effectName, duration, value)
    if char then
        -- [Character-level status effect code – unchanged]
        if not char.statusEffects[effectName] then
            if effectName == "Fury" then
                char.oldAttackSpeed = char.attackSpeed
                char.attackSpeed = char.attackSpeed * value
            end
        else
            if effectName == "Fury" then
                char.statusEffects[effectName].timer = 0
                char.statusEffects[effectName].duration = duration
            end
        end
        if effectName == "Poison" or effectName == "Regen" then
            char.statusEffects[effectName] = {
                timer = 0,
                duration = duration,
                damagePerSecond = value or 0
            }
        else
            char.statusEffects[effectName] = {
                timer = 0,
                duration = duration,
                value = value or 0
            }
        end
    else
        -- Player-level effects
        if not self.statusEffects[effectName] then
            if effectName == "Haste" then
                self.hasteBonus = self.hasteBonus + value
             
            elseif effectName == "Slow" then
                self.slowMultiplier = self.slowMultiplier * value
                self.slowMultiplier = math.max(self.slowMultiplier, 0.2)
           
            elseif effectName == "Magnetic" then
                self.magneticBonus = (self.magneticBonus or 0) + value
              
            end
        else
            if effectName == "Haste" then
                self.statusEffects["Haste"].timer = 0
                self.statusEffects["Haste"].duration = duration
          
            elseif effectName == "Slow" then
                self.statusEffects["Slow"].timer = 0
                self.statusEffects["Slow"].duration = duration
        
            elseif effectName == "Magnetic" then
                self.statusEffects["Magnetic"].timer = 0
                self.statusEffects["Magnetic"].duration = duration
             
            end
        end

        -- For Ignite, include a damagePerSecond field so that updatePlayerStatusEffects can do arithmetic on it.
        if effectName == "Ignite" then
            self.statusEffects[effectName] = {
                timer = 0,
                duration = duration,
                value = value or 0,
                damagePerSecond = value or 0  -- Here, 'value' is the DPS you want (3 DPS in your case)
            }
        else
            self.statusEffects[effectName] = {
                timer = 0,
                duration = duration,
                value = value or 0
            }
        end
    end
end


local sqrt = math.sqrt
local random = math.random
local floor = math.floor

-- Optimized draw: cache spriteSheet dimensions and create quad per-character using cached values.
function Player:draw(cameraX, cameraY, cameraZoom)
    local scaleFactor = 2
    local sortedCharacters = {}
    for _, char in pairs(self.characters) do
        table.insert(sortedCharacters, char)
        if not char._sheetDims then
            char._sheetDims = { char.spriteSheet:getDimensions() }
        end
    end
    table.sort(sortedCharacters, function(a, b)
        return a.y < b.y
    end)
  
    for _, char in ipairs(sortedCharacters) do
        if not self:isDefeated() then
            local dims = char._sheetDims
            local quad = love.graphics.newQuad(
                (char.animation.frame - 1) * char.width, 0,
                char.width, char.height, dims[1], dims[2]
            )
            love.graphics.push()
            love.graphics.translate(char.x, char.y + char.bounceOffset)
            local scaleX = (char.isFacingRight and 1 or -1) * scaleFactor
            love.graphics.draw(char.spriteSheet, quad, 0, 0, 0, scaleX, scaleFactor, char.width/2, char.height/2)
            love.graphics.pop()
        end
    end
  
    self:drawLinkExpireParticles()
  
    for _, proj in ipairs(self.projectiles) do
        proj:draw()
    end

    for _, dmgNum in ipairs(self.damageNumbers) do
        dmgNum:draw(cameraX, cameraY, cameraZoom)
    end
end


function Player:updateMovement(dt)
    local fadeTransition = require("fadeTransition")
    if (fadeTransition.active) then return end
    
    -- Initialize movement direction variables
    self.moveDirectionX = 0
    self.moveDirectionY = 0
    
    local maxDt = 0.016 -- Cap at ~60fps
    dt = math.min(dt, maxDt)
    
    -- Calculate movement based on input
    if love.keyboard.isDown("w") then 
        self.moveDirectionY = -1
    elseif love.keyboard.isDown("s") then 
        self.moveDirectionY = 1
    end
    
    if love.keyboard.isDown("a") then
        self.moveDirectionX = -1
    elseif love.keyboard.isDown("d") then
        self.moveDirectionX = 1
    end

    -- <<< ADD THIS BLOCK: Check for Clovis curse and invert controls >>>
    if self.statusEffects["Clovis"] then
        self.moveDirectionX = -self.moveDirectionX
        self.moveDirectionY = -self.moveDirectionY
    end
    -- <<< END OF ADDED BLOCK >>>
    
    -- Normalize diagonal movement
    if self.moveDirectionX ~= 0 and self.moveDirectionY ~= 0 then
        local length = math.sqrt(self.moveDirectionX * self.moveDirectionX + self.moveDirectionY * self.moveDirectionY)
        self.moveDirectionX = self.moveDirectionX / length
        self.moveDirectionY = self.moveDirectionY / length
    end

    local totalSpeed = (self.baseSpeed + (self.equipmentSpeedBonus or 0) + (self.talentSpeedBonus or 0) + (self.hasteBonus or 0)) * (self.slowMultiplier or 1)
    local finalSpeed = self.isDashing and (self.dashSpeed or 300) or totalSpeed

    -- Store current position for all characters
    for _, char in pairs(self.characters) do
        char.lastX = char.x
        char.lastY = char.y
    end

    -- Calculate potential new position
    local dx = self.moveDirectionX * finalSpeed * dt
    local dy = self.moveDirectionY * finalSpeed * dt
    local newX = self.x + dx
    local newY = self.y + dy

    -- Collision check for leader (Stormlich)
    local blocked = false
    if currentLevel and currentLevel.trees then
        for _, tree in ipairs(currentLevel.trees) do
            -- Check collision for leader first
            local leader = self.characters["Stormlich"]
            if leader then
                local wouldCollide = ObjectManager.handleCollision(tree, {
                    x = newX,
                    y = newY,
                    lastX = leader.x,
                    lastY = leader.y,
                    radius = 8
                })
                if wouldCollide then
                    blocked = true
                    break
                end
            end
        end
    end

    -- Only update positions if no collision
    if not blocked then
        self.x = newX
        self.y = newY
        

  
    end
    

    -- Update animation states
    local isMoving = math.abs(self.moveDirectionX) > 0 or math.abs(self.moveDirectionY) > 0
    if isMoving then
        for _, char in pairs(self.characters) do
            -- Adjust facing direction based on the *original* input before potential inversion
            local originalMoveX = self.moveDirectionX
            if self.statusEffects["Clovis"] then
                 originalMoveX = -originalMoveX -- Invert back to check original intent
            end
            if originalMoveX ~= 0 then -- Only change facing if there was horizontal input
                 char.isFacingRight = originalMoveX > 0
            end
            updateAnimation(char, dt)
        end
    end

    -- Rest of the existing movement code...
    self:updatePositionHistory(dt)
end

-- Helper function to update position history
function Player:updatePositionHistory(dt)
    self.historyTimer = (self.historyTimer or 0) + dt
    if self.historyTimer >= 0.1 then
        table.insert(self.positionHistory, 1, {x = self.x, y = self.y})
        self.historyTimer = 0
        
        while #self.positionHistory > 50 do
            table.remove(self.positionHistory)
        end
    end
end



function Player:isDefeated()
    return self._teamHealth <= 0
end

function Player:updateAttacks(char, dt, enemies, effects, bosses)
    char.attackTimer = char.attackTimer + dt
    if char.attackTimer >= (1 / char.attackSpeed) then
        char.attackTimer = 0
        local bossTargets = {}
        local enemyTargets = {}
        for _, boss in ipairs(bosses) do
            if not boss.isDead and boss.targetable then  -- Add targetable check
                table.insert(bossTargets, boss)
            end
        end
        for _, enemy in ipairs(enemies) do
            if not enemy.isDead and enemy.targetable then  -- Add targetable check
                table.insert(enemyTargets, enemy)
            end
        end
        local function distanceSquared(a, b)
            local dx = a.x - b.x
            local dy = a.y - b.y
            return dx * dx + dy * dy
        end
        table.sort(bossTargets, function(a, b)
            return distanceSquared(char, a) < distanceSquared(char, b)
        end)
        table.sort(enemyTargets, function(a, b)
            return distanceSquared(char, a) < distanceSquared(char, b)
        end)
        local allTargets = {}
        for _, boss in ipairs(bossTargets) do
            table.insert(allTargets, boss)
        end
        for _, enemy in ipairs(enemyTargets) do
            table.insert(allTargets, enemy)
        end
        for _, target in ipairs(allTargets) do
            if self:isInRange(char, target) then
                self:attack(char, target, effects, self.summonedEntities, enemies, sounds, self.damageNumbers)
                break
            end
        end
    end
end



function Player:updateStatusEffects(char, dt)
    if char then
        -- Update Character's Status Effects
        for effectName, effect in pairs(char.statusEffects) do
            effect.timer = effect.timer + dt
            if effect.timer >= effect.duration then
                if effectName == "Fury" and char.oldAttackSpeed then
                    char.attackSpeed = char.oldAttackSpeed
                    char.oldAttackSpeed = nil
                end
                char.statusEffects[effectName] = nil
            else
             if effectName == "Poison" then
    if not (self.isDashing and self.hasShadowsGrace) then
        self._teamHealth = self._teamHealth - effect.damagePerSecond * dt
    end
elseif effectName == "Regen" then
    self._teamHealth = math.min(
        self._teamHealth + effect.damagePerSecond * dt,
        self.teamMaxHealth
    )
end

                -- Handle other character-level effects if needed
            end
        end
    end
    -- Player's status effects are no longer handled here
end

function Player:updatePlayerStatusEffects(dt)
  for effectName, effect in pairs(self.statusEffects) do
    effect.timer = effect.timer + dt
    if effect.timer >= effect.duration then
      if effectName == "Haste" then
        self.hasteBonus = self.hasteBonus - effect.value
        if self.hasteBonus < 0 then self.hasteBonus = 0 end
      elseif effectName == "Slow" then
        self.slowMultiplier = self.slowMultiplier / effect.value
        self.slowMultiplier = math.min(self.slowMultiplier, 1)
      elseif effectName == "Magnetic" then
        self.magneticBonus = self.magneticBonus - effect.value
        if self.magneticBonus < 0 then self.magneticBonus = 0 end
      end
      self.statusEffects[effectName] = nil
    else
      if effectName == "Poison" or effectName == "Ignite" then
        local dps = effect.damagePerSecond or 0
        self:takeDamage(dps * dt)
      end
    end
  end
end




function Player:isInRange(char, enemy)
    if enemy.isDead then
        return false
    end
    local range = char.attackRange
    local dx = char.x - enemy.x
    local dy = char.y - enemy.y
    local distanceSquared = dx * dx + dy * dy
    return distanceSquared < range * range
end




function Player:update(dt, enemies, effects, BonepitZoom)
  local overallStart = love.timer.getTime()

  -- ====================================================
  -- UI Links & Current Link Updates
  -- ====================================================
  profile("Player:Update UI Links", 0.001, function()
    self.linkTimer = self.linkTimer + dt
    if self.linkTimer >= 8 then  -- spawn one link every 8 seconds
      self.linkTimer = self.linkTimer - 8
      self:spawnNewLink()
    end

    self:updateLinks(dt)
    
    if self.currentLink and self.linkNodes then
      local nodeA = self.characters[self.linkNodes.nodeA]
      local nodeB = self.characters[self.linkNodes.nodeB]
      if nodeA and nodeB then
        self.currentLink.x = (nodeA.x + nodeB.x) / 2
        self.currentLink.y = (nodeA.y + nodeB.y) / 2
      end
    end

    if self.currentLink then
      self.linkLifetime = self.linkLifetime - dt
      if self.linkLifetime <= 0 then
        local expiredLink = self.currentLink
        self.currentLink = nil
        expiredLink:onExpire(self)
        self.restoreLink = true
        self.linkRestoreTimer = 0
      end
    end

    if self.restoreLink then
      local restoreDuration = 1
      self.linkRestoreTimer = self.linkRestoreTimer + dt
      local t = math.min(self.linkRestoreTimer / restoreDuration, 1)
      self.extraGap = lerp(self.extraGap, 0, t)
      if t == 1 then
        self.restoreLink = false
      end
    end
  end)

  -- ====================================================
  -- Vital Surge Update (Particles & Timer)
  -- ====================================================
  profile("Player:Update Vital Surge", 0.001, function()
    if self.vitalSurgeActive then
        self.vitalSurgeActive = self.vitalSurgeActive - dt
        if self.vitalSurgeActive <= 0 then
            self.vitalSurgeActive = nil
            for _, char in pairs(self.characters) do
                char.vitalSurgeParticles = {}
            end
        end
    end

    if self.vitalSurgeActive then
        for _, char in pairs(self.characters) do
            char.vitalSurgeParticles = char.vitalSurgeParticles or {}
            local numToSpawn = 1  -- Always spawn 1 particle per frame per character
            for i = 1, numToSpawn do
                local particle = {
                    x = char.x + math.random(-char.width/2, char.width/2),
                    y = char.y + char.height/2,
                    speed = math.random(30, 60),
                    lifetime = 0.5,
                    age = 0,
                    colorShift = math.random() * math.pi * 2
                }
                table.insert(char.vitalSurgeParticles, particle)
            end

            for i = #char.vitalSurgeParticles, 1, -1 do
                local p = char.vitalSurgeParticles[i]
                p.age = p.age + dt
                p.y = p.y - p.speed * dt  -- move upward
                if p.age >= p.lifetime then
                    table.remove(char.vitalSurgeParticles, i)
                end
            end
        end
    end
end)

  -- ====================================================
  -- Movement & Status Effects (WASD Movement)
  -- ====================================================
  profile("Player:Update Movement & Status", 0.001, function()
    self:updateMovement(dt)  -- This is your original WASD movement & collision code
    self:updatePlayerStatusEffects(dt)
    for _, char in pairs(self.characters) do
      if char.linkExpireParticles then
        for i = #char.linkExpireParticles, 1, -1 do
          local p = char.linkExpireParticles[i]
          p.age = p.age + dt
          p.offsetX = (p.offsetX or 0) + (p.vx or 0) * dt
          p.offsetY = (p.offsetY or 0) + (p.vy or 0) * dt
          if p.age >= p.lifetime then
            table.remove(char.linkExpireParticles, i)
          end
        end
      end
    end
  end)

  -- ====================================================
  -- Potion & Dash Input Handling
  -- ====================================================
  profile("Player:Update Input (Potion & Dash)", 0.001, function()
    if love.keyboard.isDown("e") and self.potionCharge >= 1 then
      self:usePotion()
    end

    if love.keyboard.isDown("space") and not self.spacePressed and not self.isDashing and self.currentDashCharges > 0 then
      self.isDashing = true
      self.dashTimer = 0
      self.currentDashCharges = self.currentDashCharges - 1
      if self.currentDashCharges <= 0 then
        self.dashCooldown = self.maxDashCooldown
      end
      self.startOffsets = {}
      self.endOffsets = {}
      for name, char in pairs(self.characters) do
        self.startOffsets[name] = { x = char.formationOffset.x, y = char.formationOffset.y }
        self.endOffsets[name] = {
          x = char.formationOffset.x * self.dashFormationFactor,
          y = char.formationOffset.y * self.dashFormationFactor
        }
      end
      self.spacePressed = true
    elseif not love.keyboard.isDown("space") then
      self.spacePressed = false
    end

    if self.foodConsumptionTimer > 0 then
      self.foodConsumptionTimer = self.foodConsumptionTimer - dt
      if self.foodConsumptionTimer <= 0 then
        self.foodConsumptionCount = 0
      end
    end
    if self.foodComaTextTimer > 0 then
      self.foodComaTextTimer = self.foodComaTextTimer - dt
    end
  end)

  -- ====================================================
  -- Dash & Formation Updates
  -- ====================================================
  profile("Player:Update Dash & Formation", 0.001, function()
    if self.isDashing then
      self.dashTimer = self.dashTimer + dt
      local t = math.min(self.dashTimer / self.dashDuration, 1)
      for name, char in pairs(self.characters) do
        local sx, sy = self.startOffsets[name].x, self.startOffsets[name].y
        local ex, ey = self.endOffsets[name].x, self.endOffsets[name].y
        char.formationOffset.x = lerp(sx, ex, t)
        char.formationOffset.y = lerp(sy, ey, t)
      end
      if self.dashTimer >= self.dashDuration then
        self.isDashing = false
        self.dashTimer = 0
        self.restoreFormation = true
        self.restoreTimer = 0
      end
    else
      if self.dashCooldown > 0 then
        self.dashCooldown = self.dashCooldown - dt
        if self.dashCooldown < 0 then
          self.dashCooldown = 0
          self.currentDashCharges = self.maxDashCharges
        end
      end
    end

    if self.restoreFormation then
      self.restoreTimer = self.restoreTimer + dt
      local restoreDuration = 0.3
      local t = math.min(self.restoreTimer / restoreDuration, 1)
      for name, char in pairs(self.characters) do
        local sx, sy = char.formationOffset.x, char.formationOffset.y
        local ox, oy = self.startOffsets[name].x, self.startOffsets[name].y
        char.formationOffset.x = lerp(sx, ox, t)
        char.formationOffset.y = lerp(sy, oy, t)
      end
      if t == 1 then
        self.restoreFormation = false
      end
    end
  end)

  -- ====================================================
-- Characters, Projectiles & Damage Numbers Updates (Chain-follow Code)
-- ====================================================
profile("Player:Update Characters & Attacks", 0.001, function()
  for _, char in pairs(self.characters) do
    local formationOrder = {"Stormlich", "Grimreaper", "Emberfiend"}
    self.formationOrder = formationOrder

    local partyMoving = (math.abs(self.moveDirectionX) > 0 or math.abs(self.moveDirectionY) > 0)

    -- Leader: always follow the player's position.
    local leader = self.characters[formationOrder[1]]
    leader.x = self.x
    leader.y = self.y
    if partyMoving then
      leader.rotation = math.atan2(self.moveDirectionY, self.moveDirectionX)
      leader.isFacingRight = (self.moveDirectionX >= 0)
      updateAnimation(leader, dt)
    end

    local gap = 30
    local baseCatchUpSpeed = 30
    local effectiveCatchUpSpeed = self.isDashing and (baseCatchUpSpeed * 2) or baseCatchUpSpeed

    for i = 2, #formationOrder do
      local prev = self.characters[formationOrder[i-1]]
      local curr = self.characters[formationOrder[i]]

      local dx = prev.x - curr.x
      local dy = prev.y - curr.y
      local distance = math.sqrt(dx * dx + dy * dy)

      if distance > gap then
        local excess = distance - gap
        local moveAmount = excess * effectiveCatchUpSpeed
        curr.x = curr.x + (dx / distance) * moveAmount * dt
        curr.y = curr.y + (dy / distance) * moveAmount * dt

        -- Smoothly adjust rotation toward the direction from curr to prev.
        local targetRot = math.atan2(dy, dx)
        local diff = (targetRot - (curr.rotation or targetRot) + math.pi) % (2 * math.pi) - math.pi
        local baseRotSpeed = 5
        local effectiveRotSpeed = self.isDashing and (baseRotSpeed * 3) or baseRotSpeed
        curr.rotation = (curr.rotation or targetRot) + diff * dt * effectiveRotSpeed
        curr.isFacingRight = (dx >= 0)
      end

      if partyMoving then
        updateAnimation(curr, dt)
      end
    end
  end
end)

  -- ====================================================
  -- Characters, Projectiles & Damage Numbers Updates (End Section)
  -- ====================================================
  profile("Player:Update Projectiles & Damage Numbers", 0.001, function()
    for _, char in pairs(self.characters) do
        if not self:isDefeated() then
            char.lastX = char.x
            char.lastY = char.y
            Abilities.updateCooldowns(char, dt)
            self:updateAttacks(char, dt, enemies, effects, bosses)
            self:updateStatusEffects(char, dt)
        end
    end
    for _, char in pairs(self.characters) do
        if char.damageFlashTimer > 0 then
            char.damageFlashTimer = char.damageFlashTimer - dt
            if char.damageFlashTimer < 0 then char.damageFlashTimer = 0 end
        end
    end
    for i = #self.projectiles, 1, -1 do
        local proj = self.projectiles[i]
        proj:update(dt, effects, enemies, self.damageNumbers)
        if proj.isDead then
            table.remove(self.projectiles, i)
        end
    end
    for i = #self.damageNumbers, 1, -1 do
        local dmgNum = self.damageNumbers[i]
        dmgNum:update(dt)
        if dmgNum.isDead then
            table.remove(self.damageNumbers, i)
        end
    end
end)
  
  local overallElapsed = love.timer.getTime() - overallStart
  if overallElapsed > 0.001 then
    print(string.format("[PROFILE] Player:update took %.5f seconds", overallElapsed))
  end

  -- Add this section to process pending abilities
  if self.pendingAbilityActivations then
  local currentTime = love.timer.getTime()
  
  -- Ensure lastAbilityCastTime is initialized
  if not self.lastAbilityCastTime then
    self.lastAbilityCastTime = currentTime - 1.0  -- force immediate processing of the first event
  end
  
  -- Sort by scheduled time
  table.sort(self.pendingAbilityActivations, function(a, b)
    return a.scheduledTime < b.scheduledTime
  end)
  
  -- Process only one event per frame if delay has passed
  for i = 1, #self.pendingAbilityActivations do
    local event = self.pendingAbilityActivations[i]
    if currentTime >= event.scheduledTime and (currentTime - self.lastAbilityCastTime >= 1.0) then
      -- Find the character with this ability
      for _, char in pairs(self.characters) do
        if char.abilities and char.abilities[event.abilityName] then
          -- Find nearest enemy for targeting
          local nearestEnemy = nil
          local minDist = math.huge
          for _, enemy in ipairs(enemies) do
            if not enemy.isDead then
              local dx = enemy.x - char.x
              local dy = enemy.y - char.y
              local dist = math.sqrt(dx * dx + dy * dy)
              if dist < minDist then
                minDist = dist
                nearestEnemy = enemy
              end
            end
          end
          
          if event.enhanced and char.abilities[event.abilityName].enhancedEffect then
            char.abilities[event.abilityName].enhancedEffect(
              char, 
              nearestEnemy, 
              effects, 
              sounds, 
              self.summonedEntities, 
              enemies, 
              self.damageNumbers,
              event.powerMultiplier
            )
          else
            char.abilities[event.abilityName].effect(
              char, 
              nearestEnemy, 
              effects, 
              sounds, 
              self.summonedEntities, 
              enemies, 
              self.damageNumbers,
              event.powerMultiplier
            )
          end
          
          -- Record the time of this cast
          self.lastAbilityCastTime = currentTime
          break
        end
      end
      
      -- Remove only this ability event and exit the loop
      table.remove(self.pendingAbilityActivations, i)
      break
    end
  end
end
end

-- Helper function to check if a character has any unlocked abilities
function Player:hasUnlockedAbilities(charType)
  if not self.characters[charType] then return false end
  local char = self.characters[charType]
  
  -- Check if abilities table exists and has any entries
  if not char.abilities then return false end
  
  -- Count actual abilities (not just empty tables)
  local count = 0
  for abilityName, ability in pairs(char.abilities) do
    if ability.effect then -- Only count abilities that have an effect function
      count = count + 1
    end
  end
  
  return count > 0
end

function Player:spawnNewLink()
  local LinkModule = require("link")
  local LinkPool = require("LinkPool")
  
  -- 1. Create the buff (positive) link.
  local positiveLinkType
  local r = math.random()
  if r < 0.5 then
    positiveLinkType = "grey"
  elseif r < 0.7 then
    positiveLinkType = "haste"
  elseif r < 0.9 then
    positiveLinkType = "heal"
  else
    positiveLinkType = "summon"
  end
  local buffLink = LinkPool.getLink({x = 0, y = 0}, {x = 0, y = 0}, nil, nil, positiveLinkType)
  buffLink.lifetime = 4
  buffLink.negative = false

  -- 2. Clear and insert the buff link as the first element.
  self.uiLinks = {}
  table.insert(self.uiLinks, buffLink)
  
  -- 3. Roll ability links based on availableAbilityLinks count
  self.lastRolledAbilityLinks = {}  -- clear previous roll result
  local numAbilities = math.min(self.availableAbilityLinks or 0, 3)
  
  if (numAbilities > 0) then
    -- Create a filtered list of available character types based on unlocked abilities
    local availableTypes = {}
    
    -- Only add types that actually have unlocked abilities
    if self:hasUnlockedAbilities("Stormlich") then
      table.insert(availableTypes, "stormlich")
    end
    if self:hasUnlockedAbilities("Emberfiend") then
      table.insert(availableTypes, "emberfiend")
    end
    if self:hasUnlockedAbilities("Grimreaper") then
      table.insert(availableTypes, "grimreaper")
    end
    
    -- Only add joker if player has at least 2 ability slots
    if numAbilities >= 2 and #availableTypes > 0 then
      table.insert(availableTypes, "joker")
    end
    
    -- Only spawn ability links if we have available types
    if #availableTypes > 0 then
      for i = 1, numAbilities do
        -- Choose a random ability type from available ones
        local chosenType = availableTypes[math.random(#availableTypes)]
        
        local abilityLink = LinkPool.getLink({x = 0, y = 0}, {x = 0, y = 0}, nil, nil, chosenType)
        abilityLink.lifetime = 4
        abilityLink.negative = false
        
        table.insert(self.uiLinks, abilityLink)
        table.insert(self.lastRolledAbilityLinks, abilityLink.type)
      end
    end
  end
end

local function dist(a, b)
  return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
end

function Player:updateLinks(dt)
  for i = #self.uiLinks, 1, -1 do
    local link = self.uiLinks[i]
    link.lifetime = link.lifetime - dt
    if link.lifetime <= 0 then
      link:onExpire(self)
      table.remove(self.uiLinks, i)
    end
  end
end






function Player:attack(char, enemy, effects, summonedEntities, enemies, sounds, damageNumbers)
    if enemy.isDead then
        return
    end
    
     if not enemy.targetable then
        return  -- Do not attack if the enemy is not targetable
    end

    char.sprite = char.attackSprite
    char.attackSpriteTimer = 0.1

    local abilities = char.abilities
    local projCount = 1
    local spreadAngle = 0
    local useAbility = false
    local damageMultiplier = 1




    -- **Step 2: Handle Projectile Creation**
    for i = 0, projCount - 1 do
        local angleBetween = projCount > 1 and spreadAngle / (projCount - 1) or 0
        local baseAngle = math.atan2(enemy.y - char.y, enemy.x - char.x) - (spreadAngle / 2)
        local angle = baseAngle + i * angleBetween
        local projRange = char.attackRange
        local targetX = char.x + math.cos(angle) * projRange
        local targetY = char.y + math.sin(angle) * projRange
        
         local finalDamage = char.damage * damageMultiplier


      
        local proj = Projectile.new(
    char.x,             -- #1
    char.y,             -- #2
    targetX,            -- #3
    targetY,            -- #4
    char.type,          -- #5
    finalDamage,        -- #6 (damage)
    char.abilities,     -- #7 (abilities)
    char,               -- #8 (owner)
    char.attackRange,   -- #9
    effects,            -- #10 (globalEffects)
    enemies,            -- #11 (globalEnemies)
    sounds,             -- #12
    summonedEntities,   -- #13
    damageNumbers       -- #14
    -- [options if needed]    -- #15
)

        proj.type = char.type
        proj.hasTrail = true
        proj.sourceType = char.type

        -- Define the onHit function with correct damageNumbers reference
      proj.onHit = function(self, target)
            local player = self.owner.owner
            
            -- HARROWING INSTINCTS: check for crit
            local harrowingBonus = player.hasHarrowingInstincts 
                                   and (player.harrowingInstinctStacks * 0.01) 
                                   or 0
       local totalCritChance = player.baseCritChance + (player.talentCritChanceBonus or 0) + (player.equipmentCritChanceBonus or 0) + harrowingBonus


            local isCrit = (math.random() * 100 < totalCritChance)

            -- Possibly boost finalDamage for crit
            local hitDamage = self.damage
            if isCrit then
                local bonus   = (player.critDamageBonus or 0)
                local critMult = 2 + bonus
                hitDamage = hitDamage * critMult
            end

            -- Apply the damage
            target:takeDamage(
                hitDamage,
                self.damageNumbers,
                effects,
                self.sourceType,
                player,
                "projectile",
                isCrit
            )

            -- HARROWING INSTINCTS: stacks/fear logic
            if player.hasHarrowingInstincts then
                if isCrit then
                    player.harrowingInstinctStacks = 0
                    player:triggerHarrowingFear(target, enemies)
                else
                    if player.harrowingInstinctStacks < (player.harrowingInstinctMaxStacks or 10) then
                        player.harrowingInstinctStacks = player.harrowingInstinctStacks + 1
                    end
                end
            end

            -- Apply any additional onHit effects from abilities
            Abilities.applyEffects(
                self, target, player, 
                enemies, effects, sounds,
                self.owner.summonedEntities, 
                damageNumbers, "projectile"
            )
        end
        
   if char.alwaysIgnite then 
    local igniteEffect = Effects.new("ignite", enemy.x, enemy.y, nil, nil, char, enemy)
    igniteEffect.baseDPS = 25  -- set to your desired DPS override
    table.insert(effects, igniteEffect)
    if sounds and sounds.statusEffect and sounds.statusEffect.Ignite then
        sounds.statusEffect.Ignite:play()
    end
end


        -- Insert the projectile into our player's projectile table
        table.insert(self.projectiles, proj)


if self.hasLeechingEssence and finalDamage > 0 then
    local healAmount = finalDamage * (self.leechingEssencePercent or 0)
    local oldHP = self.teamHealth
    self.teamHealth = math.min(
        self.teamHealth + healAmount,
        self.teamMaxHealth
    )
    
    -- Overheal leftover
    local healedActual = self.teamHealth - oldHP
    local leftover = healAmount - healedActual
    if leftover > 0 then
        self.leechOverflow = (self.leechOverflow or 0) + leftover
      
        if self.leechOverflow >= 25 then
      
            self.leechOverflow = 0
            local ability = self.abilities["Summon BloodSlime"] -- Corrected access
            if ability and ability.effect then
                -- Corrected parameter order: char, enemy, effects, sounds, summonedEntities, enemies, damageNumbers, proj
                ability.effect(self, nil, effects, sounds, self.summonedEntities, enemies, self.damageNumbers, nil)
              
                -- **No need to set bloodSlimeExists flag**
            else
             
            end
        end
    end
end

        --------------------------------------------------------------------
        -- *** ARCANE ECHO: Immediately fire a second projectile if it procs ***
        --------------------------------------------------------------------
                
  if (self.arcaneEchoChance or 0) > 0 
   and (self.arcaneEchoCooldown or 0) <= 0 then

    if math.random() < self.arcaneEchoChance then
   
 
        -- Create a small white circle image programmatically
        local size = 4
        local imageData = love.image.newImageData(size, size)
        imageData:mapPixel(function(x, y, r, g, b, a)
            local centerX, centerY = size / 2, size / 2
            local dx, dy = x - centerX + 0.5, y - centerY + 0.5
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance <= size / 2 then
                return 1, 1, 1, 1 -- White
            else
                return 1, 1, 1, 0 -- Transparent
            end
        end)
        local whiteCircleImage = love.graphics.newImage(imageData)

        -- Create the ParticleSystem using the programmatically created white circle
        local particleSystem = love.graphics.newParticleSystem(whiteCircleImage, 500)
        particleSystem:setParticleLifetime(0.5, 1) -- Lifetime of each particle
        particleSystem:setEmissionRate(1000) -- High emission rate for dense trail
        particleSystem:setSizeVariation(0.5) -- Some size variation
        particleSystem:setSizes(0.05) -- Small particles
        particleSystem:setSpeed(50, 100) -- Particle speed
        particleSystem:setSpread(math.pi * 2) -- Emit in all directions
        particleSystem:setDirection(0) -- Direction doesn't matter with full spread
        particleSystem:setLinearAcceleration(-20, -20, 20, 20) -- Slight acceleration variation
        particleSystem:setColors(1, 0, 1, 1, 1, 0, 1, 0) -- Fade from pink to transparent
        particleSystem:setEmissionArea("uniform", math.pi * 2, 0, 0) -- Fixed the fourth argument to be a number
        particleSystem:emit(5) -- Emit particles continuously for dense trail

      -- Calculate direction
        local direction = math.atan2(targetY - char.y, targetX - char.x)

        -- Offset distance to prevent immediate collision
        local offsetDistance = 20  -- Adjust as needed based on game scale
        local echoStartX = char.x + math.cos(direction) * offsetDistance
        local echoStartY = char.y + math.sin(direction) * offsetDistance

        -- Create the "echo" projectile with offset position
        local echoProj = Projectile.new(
            echoStartX,
            echoStartY,
            targetX,
            targetY,
            "ArcaneEcho",       -- Unique type for Echo
            char.damage * damageMultiplier,
            abilities,
            char,
            char.attackRange,
            effects,
            enemies,
            sounds,
            summonedEntities,
            damageNumbers,
            {
                color = {1, 0, 1, 1},  -- Pink color with full opacity
                particleSystem = particleSystem
            }
        )

        -- Assign the onHit function with local player alias
        echoProj.onHit = function(self, target)
            local player = self.owner.owner -- Local alias to maintain compatibility
            
            -- Debug: Confirm onHit is called and player is correctly referenced
           
    
            local totalCritChance = player.baseCritChance + (player.critChanceBonus or 0)
            local isCrit = (math.random() < totalCritChance)
            local finalDamage = self.damage

            if isCrit then
                local bonus = (player.critDamageBonus or 0) -- e.g., 0.25, 0.50, or 0.75
                local critMult = 2 + bonus                 -- e.g., rank1 -> 2.25×, rank2 -> 2.50×
                finalDamage = finalDamage * critMult
               
            end

            -- Debug: Show damage calculation
          

            -- Apply damage
            target:takeDamage(
                finalDamage,                  -- Damage dealt
                self.damageNumbers,           -- Table tracking damage numbers
                effects,                      -- Effects table
                self.sourceType,              -- Type of source (e.g., "fireball", "arrow")
                player,                       -- Owner of the projectile (player character)
                "projectile",                 -- Attack type
                isCrit                        -- Critical hit flag
            )

            -- Apply any additional effects
            Abilities.applyEffects(
                self, 
                target, 
                player, 
                enemies, 
                effects, 
                sounds, 
                player.summonedEntities, 
                damageNumbers, 
                "projectile"
            )
        end

        echoProj.hasTrail = true
        echoProj.sourceType = char.type

    

        -- Insert the echo projectile
        table.insert(self.projectiles, echoProj)
    end
end



                -- **Step 3: Handle Projectile-Based Abilities**
                for abilityName, ability in pairs(abilities) do
                    if ability and ability.procChance and ability.effect and ability.attackType == "projectile" then
                        if math.random() < ability.procChance then
                            ability.effect(char, enemy, effects, sounds, summonedEntities, enemies, damageNumbers, proj)
                            useAbility = true
                        end
                    end
                end
            end

    -- **Step 4: Play Attack Sound**
    if sounds and sounds.playerAttack and sounds.playerAttack[char.type] then
        sounds.playerAttack[char.type]:play()
    end
end



function Player:applyAbilityEffects(proj, enemy, enemies, effects)
    Abilities.applyEffects(proj, enemy, proj.owner, enemies, effects, sounds, self.summonedEntities, self.damageNumbers, "projectile")
end



function Player:applyRandomPotionBuff()
    local effectRoll = math.random(1, 3)
    local bonusDuration = self.ritualFeastBonus or 0  -- If Ritual Feast is also active
    local baseDuration = 10  -- Same as in food
    local totalDuration = baseDuration + bonusDuration

    if effectRoll == 1 then
        addDamageNumber(self.x, self.y - 10, "Regen", {0,1,0})
        Abilities.applyRegen(self, totalDuration, 0.25)
    elseif effectRoll == 2 then
        addDamageNumber(self.x, self.y - 10, "Haste", {1,1,0})
        Abilities.applyHaste(self, totalDuration, 25)
    elseif effectRoll == 3 then
        addDamageNumber(self.x, self.y - 10, "Fury", {1,0,0})
        Abilities.applyFury(self, totalDuration, 2)
    end
end

function Player:triggerHarrowingFear(target, enemies)
    if not target or not enemies then return end

    local fearRadius = 100
    local fearDuration = 3
    local maxTargets = 3
    local found = {}

    for _, e in ipairs(enemies) do
        if not e.isDead then
            local dx = e.x - target.x
            local dy = e.y - target.y
            if (dx * dx + dy * dy) <= (fearRadius * fearRadius) then
                table.insert(found, e)
            end
        end
    end

    -- Sort by closest
    table.sort(found, function(a, b)
        local dA = (a.x - target.x)^2 + (a.y - target.y)^2
        local dB = (b.x - target.x)^2 + (b.y - target.y)^2
        return dA < dB
    end)

    -- Fear up to 3
    for i = 1, math.min(maxTargets, #found) do
        local e = found[i]
        e.statusEffects = e.statusEffects or {}
        e.statusEffects["fear"] = {
            timer = 0,
            duration = fearDuration,
            -- mark them as fleeing in their AI
        }
    end

    -- Spawn the fearExplosion visual effect
    if Effects and Effects.new then
        local fearExp = Effects.new("fearExplosion", target.x, target.y, nil, nil, nil, nil, effects, 100, nil, enemies, damageNumbers, 1.5)
        table.insert(effects, fearExp)
    end

    -- (Optional) spawn a purple “fear explosion” effect:
    if Effects and Effects.spawnExplosion then
        Effects.spawnExplosion(target.x, target.y, "fearExplosion")
    end
end


function Player:getStatsData()
  local stats = {}
  for charName, char in pairs(self.characters) do
    stats[charName] = {
      baseAttackRange  = char.baseAttackRange or 0,
      attackRange      = char.attackRange or 0,
      baseAttackSpeed  = char.baseAttackSpeed or 0,
      attackSpeed      = char.attackSpeed or 0,
      baseDamage       = char.baseDamage or 0,
      damage           = char.damage or 0,

      abilityBonus     = (char[charName.."AbilityBonus"] or 0)
    }
  end
local totalPR, count = 0, 0
for _, char in pairs(self.characters) do
    totalPR = totalPR + (char.pullRange or 0)
    count = count + 1
end
local avgPullRange = count > 0 and math.floor(totalPR / count) or 0

stats.global = {
    baseSpeed       = self.baseSpeed or 0,
    totalSpeed      = self.baseSpeed + (self.equipmentSpeedBonus or 0) + (self.talentSpeedBonus or 0) + (self.hasteBonus or 0),
    pullRange       = self.PullRange or 0,
    teamHealth      = self._teamHealth or 0,
    teamMaxHealth   = self.teamMaxHealth or 0,
    critChance      = self.baseCritChance + (self.critChanceBonus or 0),
    critDamage      = 2 + (self.critDamageBonus or 0),  -- default multiplier 2
   
}

  return stats
end

function Player:recalculateStats()
  print("[DEBUG recalcStats] Called at time " .. love.timer.getTime())
   print("[recalcStats] Equipment:", self.equipment, 
          "Chest Item:", self.equipment and self.equipment.equipped and self.equipment.equipped.chest and self.equipment.equipped.chest.name or "none")
    -- Reset base stats
    self.teamMaxHealth = self.baseTeamMaxHealth
    self._teamHealth = self.teamMaxHealth  
    self.equipmentSpeedBonus = 0
    self.critDamageBonus = 0
    self.armor = 0

    -- Reset per‑character bonus fields:
    for _, char in pairs(self.characters) do
        char.equipmentAttackRangeBonus = 0
        char.equipmentAttackSpeedBonusPercent = 0
        char.equipmentFlatDamage = 0
        char.grimReaperAbilityBonus = 0
        char.emberfiendAbilityBonus = 0
        char.stormlichAbilityBonus = 0
        char.statusDurationBonus = 0
    end

    -- If an item is equipped, sum its bonusEffect values:
    if self.equipment and self.equipment.equipped and self.equipment.equipped.chest then
        local item = self.equipment.equipped.chest
        
        -- Health bonus (common & legendary)
        local extraHP = (item.bonusEffect.health or 0) + (item.bonusEffect.legendaryMaxHealth or 0)
        self.teamMaxHealth = self.teamMaxHealth + extraHP
        self._teamHealth = self._teamHealth + extraHP

        -- Armor bonus
        if item.bonusEffect.armor then  
            self.armor = self.armor + item.bonusEffect.armor
        end

        -- Movement speed bonus (applied to player)
        if item.bonusEffect.movementSpeed then
            self.equipmentSpeedBonus = self.equipmentSpeedBonus + item.bonusEffect.movementSpeed
        end

        -- Critical damage bonus
        if item.bonusEffect.critDamageBonus then
            self.critDamageBonus = self.critDamageBonus + item.bonusEffect.critDamageBonus
        end

        -- Apply per‑character bonuses:
        for _, char in pairs(self.characters) do
            if item.bonusEffect.attackRange then
                char.equipmentAttackRangeBonus = char.equipmentAttackRangeBonus + item.bonusEffect.attackRange
            end
            if item.bonusEffect.attackSpeedPercent then
                char.equipmentAttackSpeedBonusPercent = char.equipmentAttackSpeedBonusPercent + item.bonusEffect.attackSpeedPercent
            end
            if item.bonusEffect.attackDamageFlat then
                char.equipmentFlatDamage = char.equipmentFlatDamage + item.bonusEffect.attackDamageFlat
            end

            -- Class‑specific ability damage bonuses
            if char.type == "Grimreaper" and item.bonusEffect.grimReaperAbilityDamage then
                char.grimReaperAbilityBonus = char.grimReaperAbilityBonus + item.bonusEffect.grimReaperAbilityDamage
            elseif char.type == "Emberfiend" and item.bonusEffect.emberfiendAbilityDamage then
                char.emberfiendAbilityBonus = char.emberfiendAbilityBonus + item.bonusEffect.emberfiendAbilityDamage
            elseif char.type == "Stormlich" and item.bonusEffect.stormlichAbilityDamage then
                char.stormlichAbilityBonus = char.stormlichAbilityBonus + item.bonusEffect.stormlichAbilityDamage
            end

            -- Status duration bonus (if applicable)
            if item.bonusEffect.statusDuration then
                char.statusDurationBonus = char.statusDurationBonus + item.bonusEffect.statusDuration
            end
        end
    end

    -- Apply talents that may adjust stats further:
    talentSystem.applyTalentsToPlayer(self)

    -- Recalculate each character's final stats:
    for _, char in pairs(self.characters) do
        char.attackRange = char.baseAttackRange + (char.equipmentAttackRangeBonus or 0)
        char.attackSpeed = char.baseAttackSpeed * (1 + ((char.equipmentAttackSpeedBonusPercent or 0) / 100))
        char.damage = (char.baseDamage + (char.equipmentFlatDamage or 0)) * (self.attackDamageMultiplier or 1)
        -- Optionally, add movement speed to the player overall:
        char.speed = char.baseSpeed + self.equipmentSpeedBonus + self.talentSpeedBonus + self.hasteBonus
    end
end


function Player:registerFoodConsumption()
    if self.foodConsumptionTimer <= 0 then
        self.foodConsumptionCount = 1
        self.foodConsumptionTimer = 5  -- start a 5‑sec window
    else
        self.foodConsumptionCount = self.foodConsumptionCount + 1
    end
    if self.foodConsumptionCount >= 4 then
        -- Apply Slow debuff for 5 seconds (e.g., multiplier 0.75)
        self:applyStatusEffect(nil, "Slow", 5, 0.75)
        -- Show FOOD COMA using addDamageNumber (like your other effects)
        addDamageNumber(self.x, self.y - 10, "FOOD COMA", {1, 1, 1})
        -- Reset the food consumption counter/timer
        self.foodConsumptionCount = 0
        self.foodConsumptionTimer = 0
    end
end

function Player:addLink(linkType, lifetime, isNegative)
local LinkModule = require("link")
 local LinkPool = require("LinkPool")
local newLink = LinkPool.getLink({x = 0, y = 0}, {x = 0, y = 0}, nil, nil, linkType)

  newLink.lifetime = lifetime or 4
  newLink.negative = isNegative or false
  
  local maxLinks = 5
  if newLink.negative then
    if #self.negativeLinks < maxLinks then
      table.insert(self.negativeLinks, newLink)
    else
      local index = math.random(#self.negativeLinks)
      local oldLink = self.negativeLinks[index]
      oldLink:onExpire(self)
      self.negativeLinks[index] = newLink
    end
  else
    if #self.uiLinks < maxLinks then
      table.insert(self.uiLinks, newLink)
    else
      local index = math.random(#self.uiLinks)
      local oldLink = self.uiLinks[index]
      oldLink:onExpire(self)
      self.uiLinks[index] = newLink
    end
  end
end


-- NEW: Update enemy negative links
function Player:updateNegativeLinks(dt)
  for i = #self.negativeLinks, 1, -1 do
    local link = self.negativeLinks[i]
    link.lifetime = link.lifetime - dt
    if link.lifetime <= 0 then
      link:onExpire(self)
      table.remove(self.negativeLinks, i)
    end
  end
end

-- NEW: Draw enemy negative links in the UI link bar.
-- For example, draw them to the left of positive links (or with a distinct offset)
function Player:drawNegativeLinks()
  local screenW = love.graphics.getWidth()
  local sampleImg = love.graphics.newImage("assets/greylink.png")
  sampleImg:setFilter("nearest", "nearest")
  local spriteWidth = sampleImg:getWidth() * 2  -- drawn 2× scaled
  local spacing = spriteWidth + 10
  local totalWidth = (#self.negativeLinks) * spacing
  -- Place negative links on the left side of the screen (or adjust as needed)
  local startX = 20  -- for example, 20 pixels from the left edge
  local y = 20  -- fixed top margin
  for i, link in ipairs(self.negativeLinks) do
      link.x = startX + (i - 1) * spacing + spriteWidth / 2
      link.y = y + spriteWidth / 2
      link:draw()
  end
end

function Player:triggerLinkExpireEffect(linkType)
  -- Only trigger for non-gray links.
  if linkType == "grey" then
    return
  end

  local effectColor, sound
  if linkType == "haste" then
    effectColor = {1, 1, 0, 1}    -- Yellow for haste
    sound = self.sounds and self.sounds.hasteLinkExpire
  elseif linkType == "heal" then
    effectColor = {0, 1, 0, 1}    -- Green for heal
    sound = self.sounds and self.sounds.healLinkExpire
  elseif linkType == "summon" then
    effectColor = {0.5, 0, 0.5, 1}  -- Purple for summon
    sound = self.sounds and self.sounds.summonLinkExpire
  else
    return
  end

  if sound then
    sound:play()
  end

  -- Use a cached particle config so we do not re-create new data every frame.
  if not self._linkExpireParticleConfig then
    self._linkExpireParticleConfig = {
      lifetime = 1,
      numParticles = 5,
      vxRange = {-5, 5},
      vyRange = {-10, -5},
      fixedColor = effectColor,
    }
  else
    -- Update color in the cached config if necessary.
    self._linkExpireParticleConfig.fixedColor = effectColor
  end

  -- Create particles only once per link expiration.
  for _, char in pairs(self.characters) do
    char.linkExpireParticles = char.linkExpireParticles or {}
    for i = 1, self._linkExpireParticleConfig.numParticles do
      local particle = {
        offsetX = 0,
        offsetY = 0,
        lifetime = self._linkExpireParticleConfig.lifetime,
        age = 0,
        fixedColor = self._linkExpireParticleConfig.fixedColor,
        vx = math.random(self._linkExpireParticleConfig.vxRange[1], self._linkExpireParticleConfig.vxRange[2]),
        vy = math.random(self._linkExpireParticleConfig.vyRange[1], self._linkExpireParticleConfig.vyRange[2])
      }
      table.insert(char.linkExpireParticles, particle)
    end
  end
end


function Player:drawLinkExpireParticles()
  local startOffsetY = 10      -- Start the effect 10 pixels lower on the player's position
  local spreadFactor = 1.5     -- Increase horizontal spread of the particles
  for _, char in pairs(self.characters) do
    if char.linkExpireParticles then
      love.graphics.push()
      for _, p in ipairs(char.linkExpireParticles) do
        local alpha = 1 - (p.age / p.lifetime)
        local r, g, b = unpack(p.fixedColor)
        love.graphics.setColor(r, g, b, alpha)
        local drawX = char.x + ((p.offsetX or 0) * spreadFactor)
        local drawY = char.y + startOffsetY + (p.offsetY or 0)
        love.graphics.line(drawX, drawY, drawX, drawY - 6)
      end
      love.graphics.pop()
      love.graphics.setColor(1, 1, 1, 1)
    end
  end
end




return Player