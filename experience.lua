-- experience.lua

local Abilities = require("abilities")
local Effects = require("effects")
local Collision = require("collision")
local DamageNumber = require("damage_number")
local GameState = require("gameState")
local gameState = GameState.new()

local abilityMilestones = require("abilities_config")
local milestoneLevels = { [1] = true, [5] = true, [9] = true, [11] = true }

local Experience = {}
Experience.__index = Experience

-- Shuffle function for randomizing upgrade picks
local function shuffle(tbl)
    if not tbl or type(tbl) ~= "table" then
        return {}
    end
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

-- Returns the chance (as a decimal) an ability of a given milestone appears,
-- based on the player's current level.
local function getAbilityChance(milestone, playerLevel, unlockBonus)
    unlockBonus = unlockBonus or 0
    if milestone == 1 then
        return 1.0
    elseif milestone == 5 then
        return (playerLevel >= 5) and 1.0 or (0.05 + unlockBonus)
    elseif milestone == 8 then
        if playerLevel >= 8 then
            return 1.0
        elseif playerLevel >= 5 then
            return 0.05 + unlockBonus
        else
            return 0.03 + unlockBonus
        end
    elseif milestone == 10 then
        if playerLevel >= 10 then
            return 1.0
        elseif playerLevel >= 8 then
            return 0.05 + unlockBonus
        elseif playerLevel >= 5 then
            return 0.03 + unlockBonus
        else
            return 0.01 + unlockBonus
        end
    end
    return 0
end

local function createHealingBubble(x, y, healAmount, lifetime, vy)
    local bubble = {}
    bubble.x = x
    bubble.y = y
    bubble.lifetime = lifetime or 1.0  -- use provided lifetime, default to 1.0 sec
    bubble.timer = 0
    bubble.vy = vy or -30       -- use provided upward speed, default to -30
    bubble.alpha = 1
    bubble.healAmount = healAmount

    function bubble:update(dt)
        self.timer = self.timer + dt
        self.y = self.y + self.vy * dt
        self.alpha = 1 - (self.timer / self.lifetime)
        if self.timer >= self.lifetime then
            self.isDead = true
        end
    end

    function bubble:draw()
        love.graphics.setColor(1, 0, 0, self.alpha)
        love.graphics.circle("fill", self.x, self.y, 5)
        love.graphics.setColor(1, 1, 1, 1)
    end

    return bubble
end


-- Helper to generate milestone upgrade options from abilityMilestones
function Experience:generateMilestoneUpgradeOptions()
    local pool = {}

    -- 1) If we have an exact config for this level, just use that
    if abilityMilestones[self.level] then
        for _, a in ipairs(abilityMilestones[self.level]) do
            pool[#pool+1] = { name = a.name, class = a.class, milestone = self.level }
        end

    else
        -- 2) Otherwise gather everything from earlier milestones
        for lvl, list in pairs(abilityMilestones) do
            if lvl < self.level then
                for _, a in ipairs(list) do
                    pool[#pool+1] = { name = a.name, class = a.class, milestone = lvl }
                end
            end
        end
    end

    -- 3) Shuffle & pick up to 3
    shuffle(pool)
    local options = {}
    for i = 1, math.min(3, #pool) do
        options[#options+1] = pool[i]
    end

    return options
end

function Experience:generateMilestoneUpgradeOptions()
    local pool = {}

    -- 1) If we have an exact config for this level, just use that
    if abilityMilestones[self.level] then
        for _, a in ipairs(abilityMilestones[self.level]) do
            pool[#pool+1] = { name = a.name, class = a.class, milestone = self.level }
        end

    else
        -- 2) Otherwise gather everything from earlier milestones
        for lvl, list in pairs(abilityMilestones) do
            if lvl < self.level then
                for _, a in ipairs(list) do
                    pool[#pool+1] = { name = a.name, class = a.class, milestone = lvl }
                end
            end
        end
    end

    -- 3) Shuffle & pick up to 3
    shuffle(pool)
    local options = {}
    for i = 1, math.min(3, #pool) do
        options[#options+1] = pool[i]
    end

    return options
end

function Experience:generateGeneralUpgradeOptions()
    local pool = {}
    -- Pull from Abilities.generalUpgrades, skip any already maxed
    for name, def in pairs(Abilities.generalUpgrades) do
        if not self.maxedAbilities[name] then
            pool[#pool+1] = {
                name        = name,
                class       = "General",
                description = def.description or "No description available.",
                milestone   = nil
            }
        end
    end
    shuffle(pool)
    return pool
end

-- Constructor
function Experience.new(player, triggerManager, levelInstance) -- Add levelInstance parameter
    local self = setmetatable({}, Experience)
    self.player = player
    self.triggerManager = triggerManager -- Store it
    self.levelInstance = levelInstance -- Store the current level instance (e.g., tutorial)
    self.currentExp = 0
    self.expToLevel = 40
    self.level = 1
    self.upgradeOptions = {}
    self.maxedAbilities = {}

    -- Load level-up sounds
    self.levelUpSoundPath  = "assets/sounds/effects/levelup.mp3"
    self.levelUp2SoundPath = "assets/sounds/effects/levelup2.mp3"

    local function loadSound(path)
        if love.filesystem.getInfo(path) then
            local s = love.audio.newSource(path, "static")
            s:setVolume(1.0)
            return s
        else
            return nil
        end
    end

    self.levelUpSound  = loadSound(self.levelUpSoundPath)
    self.levelUp2Sound = loadSound(self.levelUp2SoundPath)

    return self
end


function Experience:addExperience(amount)
    local xpAmount = amount
    self.currentExp = self.currentExp + xpAmount

 if (self.player.experienceHealChance or 0) > 0 and math.random() < self.player.experienceHealChance then
    print("DEBUG: Experience Heal triggered!")
    local healAmount = 1
    -- Only heal current health (do NOT increase max health)
    self.player._teamHealth = math.min(self.player._teamHealth + healAmount, self.player.teamMaxHealth)
    
    -- Spawn between 3 and 6 healing bubbles with a shorter lifetime and faster upward speed
    local numBubbles = math.random(3, 6)
    for i = 1, numBubbles do
        local bubble = createHealingBubble(self.player.x, self.player.y, healAmount, 0.5, -45)
        table.insert(_G.effects, bubble)
    end

    -- 50% chance to play the heal chime sound
    if math.random() < 0.5 then
        local healChime = love.audio.newSource("assets/sounds/effects/healchime.wav", "static")
        healChime:setVolume(1.0)
        healChime:play()
    end
end



    while self.currentExp >= self.expToLevel do
        self:levelUp()
    end
end



function Experience:levelUp()
    self.level = self.level + 1
    self.currentExp = self.currentExp - self.expToLevel

    if self.level == 2 then
        self.expToLevel = 60
    elseif self.level == 3 then
        self.expToLevel = 80
    else
        self.expToLevel = math.floor(80 * math.pow(1.5, self.level - 3))
    end

    if self.player.vitalSurgeChance and self.player.vitalSurgeChance > 0 then
        if math.random() < self.player.vitalSurgeChance then
            Abilities.applyHaste(self.player, 5, 20)
            Abilities.applyFury(self.player, 5, 2)
            Abilities.applyRegen(self.player, 5, 0.05)
            self.player.vitalSurgeActive = 5
        end
    end

    -- Alternate upgrade pool: now even levels → milestone (ability choices),
    -- odd levels → general (passives)
    local upgradeType = (self.level % 2 == 0) and "milestone" or "general"

    local upgradeOptions = (upgradeType == "milestone") and self:generateMilestoneUpgradeOptions() or self:generateGeneralUpgradeOptions()

    -- Build uniform upgrade option table (3 options)
    local finalOptions = {}
    local exp = self  -- capture the Experience object for the closure
    for i = 1, math.min(3, #upgradeOptions) do
        local ability = upgradeOptions[i]
        finalOptions[i] = {
            name = ability.name,
            class = ability.class,
            description = ability.description or (Abilities.abilityList[ability.name] and Abilities.abilityList[ability.name].description) or "No description available.",
            milestone = ability.milestone,
            apply = function()
                if ability.class == "General" then
                    if ability.name == "Increase Max Health" or 
                       ability.name == "Increase Pull Range" or 
                       ability.name == "Experience Heal" or 
                       ability.name == "Increase Status Effect Damage" then
                        print("[DEBUG] Applying", ability.name, "to player")
                        Abilities.generalUpgrades[ability.name].effect(exp.player)
                    else
                        -- <<< replace the `{` here with `do`
                        for key, char in pairs(exp.player.characters) do
                            print("[DEBUG] Before upgrade", ability.name, "for character", key)
                            Abilities.generalUpgrades[ability.name].effect(char)
                            print("[DEBUG] After upgrade", ability.name, "for character", key)
                        end  -- <<< matching end for the loop
                    end
                else
                    local c = exp.player.characters[ability.class]
                    if c then
                        print("[DEBUG] Applying upgrade", ability.name, "to class", ability.class)
                        Abilities.upgradeAbility(c, ability.name)
                        -- Add the ability's link to the pool if it isn't already there.
                        local abilityDef = Abilities.abilityList[ability.name]
                        if abilityDef and abilityDef.linkType then
                            if not exp.player.abilityLinksPool then
                                exp.player.abilityLinksPool = {}
                            end
                            local alreadyExists = false
                            for _, entry in ipairs(exp.player.abilityLinksPool) do
                                if entry.linkType == abilityDef.linkType then
                                    alreadyExists = true
                                    break
                                end
                            end
                            if not alreadyExists then
                                table.insert(exp.player.abilityLinksPool, { linkType = abilityDef.linkType, lifetime = 4 })
                            end
                        end
                    end
                end
            end
        }
    end

    while #finalOptions < 3 do
        table.insert(finalOptions, {
            name = "No Upgrade Available",
            description = "No additional upgrades available at this time.",
            apply = function() end
        })
    end
    self.upgradeOptions = finalOptions
    
    -- Update the available reels on the player and the UI.
    if self.player.updateAvailableReels then
        self.player:updateAvailableReels()
    end
    if ui and ui.updateAvailableReels then
        ui:updateAvailableReels()
    end

    if ui and ui.showUpgradeOptions then
        gameState:setPause(true)
        gameState:setLevelingUp(true)

        if upgradeType == "milestone" then
            if self.levelUpSound then
                self.levelUpSound:stop()
                self.levelUpSound:play()
            end
        else
            if self.levelUp2Sound then
                self.levelUp2Sound:stop()
                self.levelUp2Sound:play()
            end
        end

        if ui.startCandyCelebration then
            ui:startCandyCelebration()
        end

        ui:showUpgradeOptions(self.upgradeOptions, function(selectedUpgrade)
            if selectedUpgrade.apply then
                selectedUpgrade.apply()
            end

            local character = self.player.characters[selectedUpgrade.class]
            local ability = character and character.abilities[selectedUpgrade.name]
            if ability and ability.rank >= ability.maxRank then
                self.maxedAbilities[selectedUpgrade.name] = true
            end

            -- record it for the pause menu
            self.player.pickedAbilities = self.player.pickedAbilities or {}
            table.insert(self.player.pickedAbilities, selectedUpgrade.name)

            if ui.stopCandyCelebration then
                ui:stopCandyCelebration()
            end

            gameState:setPause(false)
            gameState:setLevelingUp(false)

            -- *** TRIGGER CHECK AND FLAG SETTING ***
            -- Check if level is 2 and trigger the explanation dialog
            if exp.level == 2 and exp.triggerManager then
                -- Try to trigger the dialog. TriggerManager prevents re-firing.
                local triggered = exp.triggerManager:try("levelUpExplanation")

                -- If the dialog was successfully triggered AND we have a level instance (tutorial), set its flags
                if triggered and exp.levelInstance and exp.levelInstance.currentLevel == "tutorial" then
                    exp.levelInstance.levelUpExplanationTriggered = true
                    -- Use the level instance's timer if available, otherwise fallback (though it should exist)
                    exp.levelInstance.levelUpExplanationTriggerTime = exp.levelInstance.totalGameTimer or love.timer.getTime()
                    print("[Experience] Set tutorial flags for chest spawn.")
                end
            end
            -- *** END TRIGGER CHECK ***

        end, upgradeType)
    else
        gameState:setPause(false)
        gameState:setLevelingUp(false)
    end
end


function Experience:triggerBonusUpgrades()
    local bonusOptions = self:getBonusUpgradeOptions()
    if ui and #bonusOptions > 0 then
        gameState:setPause(true)
        gameState:setLevelingUp(true)

        if self.levelUp2Sound then
            self.levelUp2Sound:stop()
            self.levelUp2Sound:play()
        end

        if ui.startCandyCelebration then
            ui:startCandyCelebration()
        end

        ui:showUpgradeOptions(bonusOptions, function(selectedBonusUpgrade)
            for _, character in pairs(self.player.characters) do
                local bonusDef = Abilities.generalUpgrades[selectedBonusUpgrade.name]
                if bonusDef and bonusDef.effect then
                    bonusDef.effect(character)
                end
            end

            self.maxedAbilities[selectedBonusUpgrade.name] = true

            if ui.stopCandyCelebration then
                ui:stopCandyCelebration()
            end

            gameState:setPause(false)
            gameState:setLevelingUp(false)
            print("Bonus upgrade applied:", selectedBonusUpgrade.name)
        end, "bonus")
    else
        gameState:setPause(false)
        gameState:setLevelingUp(false)
    end
end

function Experience:getBonusUpgradeOptions()
    local bonusOptions = {}
    for name, upgrade in pairs(Abilities.generalUpgrades) do
        if not self.maxedAbilities[name] then
            table.insert(bonusOptions, upgrade)
        end
    end

    shuffle(bonusOptions)

    local finalBonusOptions = {}
    for i = 1, math.min(3, #bonusOptions) do
        finalBonusOptions[i] = bonusOptions[i]
    end

    local fallbackUpgrade = {
        name = "No Upgrade Available",
        description = "No additional upgrades available at this time.",
        apply = function(character) end
    }

    while #finalBonusOptions < 3 do
        table.insert(finalBonusOptions, fallbackUpgrade)
    end

    return finalBonusOptions
end

-- (Optional) If you wish to use the older generation method for ability options:
function Experience:generateUpgradeOptions()
    local function getAvailableAbilities()
        local abilities = {}
        for milestoneLevel, abilityList in pairs(abilityMilestones) do
            local chance = getAbilityChance(milestoneLevel, self.level, self.player.abilityUnlockBonus or 0)
            for _, ability in ipairs(abilityList) do
                if math.random() < chance then
                    ability.milestone = milestoneLevel
                    table.insert(abilities, ability)
                end
            end
        end
        return abilities
    end

    local available = getAvailableAbilities()
    local pools = { Grimreaper = {}, Emberfiend = {}, Stormlich = {} }
    for _, ability in ipairs(available) do
        if not self.maxedAbilities[ability.name] then
            if pools[ability.class] then
                local item = {
                    name = ability.name,
                    class = ability.class,
                    milestone = ability.milestone,
                    description = ability.description or (Abilities.abilityList[ability.name] and Abilities.abilityList[ability.name].description) or "No description.",
                    apply = function()
                        local c = self.player.characters[ability.class]
                        if c then
                            Abilities.upgradeAbility(c, ability.name)
                        end
                    end
                }
                table.insert(pools[ability.class], item)
            end
        end
    end

    local upgradeOptions = {}
    for class, list in pairs(pools) do
        shuffle(list)
        if #list > 0 then
            table.insert(upgradeOptions, list[1])
        end
    end

    while #upgradeOptions < 3 do
        local done = false
        for class, list in pairs(pools) do
            if #list > 1 then
                table.insert(upgradeOptions, list[2])
                done = true
                break
            end
        end
        if not done then break end
    end

    local fallback = {
        name = "No Upgrade Available",
        description = "No additional upgrades available at this time.",
        apply = function() print("No upgrade applied.") end
    }

    while #upgradeOptions < 3 do
        table.insert(upgradeOptions, fallback)
    end

    self.upgradeOptions = upgradeOptions
end

return Experience
