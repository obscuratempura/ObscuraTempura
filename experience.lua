-- experience.lua

local Abilities = require("abilities")
local Effects = require("effects")
local Collision = require("collision")
local DamageNumber = require("damage_number")

local Experience = {}
Experience.__index = Experience

function Experience.new(player)
    local self = setmetatable({}, Experience)
    self.player = player
    self.currentExp = 0
    self.expToLevel = 80
    self.level = 1
    self.isLevelingUp = false
    self.upgradeOptions = {}
    self.maxedAbilities = {}

    return self
end

function Experience:addExperience(amount)
    self.currentExp = self.currentExp + amount
    if self.currentExp >= self.expToLevel then
        self:levelUp()
    end
end

function Experience:levelUp()
    self.level = self.level + 1
    self.currentExp = self.currentExp - self.expToLevel
    self.expToLevel = math.floor(self.expToLevel * 1.3)
    self.isLevelingUp = true
    self:generateUpgradeOptions()

    -- Show upgrade options in the UI (this assumes you have a UI system to handle this)
    if ui and ui.showUpgradeOptions then
        ui:showUpgradeOptions(self.upgradeOptions, function(selectedUpgrade)
          
            selectedUpgrade.apply()
            self.isLevelingUp = false
            --gamePaused = false  -- Ensure this line is executed
          
        end)
    else
       
    end
end

local function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

function Experience:update(dt)
  
end


function Experience:generateUpgradeOptions()
    local generalUpgrades = {
    { name = "Increase Attack Speed", 
      apply = function()
        Abilities.applyGeneralUpgrade("Increase Attack Speed", self.player.characters)
      end, 
      description = "Increases the attack speed of all characters.",
      class = "All" },

    { name = "Increase Attack Damage", 
      apply = function()
        Abilities.applyGeneralUpgrade("Increase Attack Damage", self.player.characters)
      end, 
      description = "Increases the damage dealt by all characters.",
      class = "All" },

   { name = "Increase Movement Speed", 
  apply = function()
    Abilities.applyGeneralUpgrade("Increase Movement Speed", self.player.characters)
  end, 
  description = "Increases movement speed of all characters.",
  class = "All" },


    { name = "Increase Attack Range", 
      apply = function()
        Abilities.applyGeneralUpgrade("Increase Attack Range", self.player.characters)
      end, 
      description = "Increases the attack range of all characters.",
      class = "All" }
}


 local uniqueAbilities = {
    { name = "Arrow Spread Shot", class = "Ranger", description = Abilities.abilityList["Arrow Spread Shot"].description,
      apply = function() Abilities.upgradeAbility(self.player.characters.ranger, "Arrow Spread Shot") end },
    { name = "Poison Shot", class = "Ranger", description = Abilities.abilityList["Poison Shot"].description,
      apply = function() Abilities.upgradeAbility(self.player.characters.ranger, "Poison Shot") end },
    { name = "Summon Wolf", class = "Ranger", description = Abilities.abilityList["Summon Wolf"].description,
      apply = function() Abilities.upgradeAbility(self.player.characters.ranger, "Summon Wolf") end },
    { name = "Explosive Fireballs", class = "Mage", description = Abilities.abilityList["Explosive Fireballs"].description,
      apply = function() Abilities.upgradeAbility(self.player.characters.mage, "Explosive Fireballs") end },
    { name = "Frost Explosion", class = "Mage", description = Abilities.abilityList["Frost Explosion"].description,
      apply = function() Abilities.upgradeAbility(self.player.characters.mage, "Frost Explosion") end },
    { name = "Chain Lightning", class = "Spearwarden", description = Abilities.abilityList["Chain Lightning"].description,
      apply = function() Abilities.upgradeAbility(self.player.characters.spearwarden, "Chain Lightning") end },
    { name = "Shield Throw", class = "Spearwarden", description = Abilities.abilityList["Shield Throw"].description,
      apply = function() Abilities.upgradeAbility(self.player.characters.spearwarden, "Shield Throw") end },
    { name = "Charged Spear Toss", class = "Spearwarden", description = Abilities.abilityList["Charged Spear Toss"].description,
      apply = function() Abilities.upgradeAbility(self.player.characters.spearwarden, "Charged Spear Toss") end },

}




    -- Exclude maxed abilities from upgrade options
    local filteredAbilities = {}
    for _, ability in ipairs(uniqueAbilities) do
        if not self.maxedAbilities[ability.name] then
            table.insert(filteredAbilities, ability)
        end
    end

    -- Shuffle both general upgrades and unique abilities
    shuffle(generalUpgrades)
    shuffle(filteredAbilities)

    -- Create a combined list of abilities with at least one unique ability
    local combinedOptions = {}

    -- Ensure at least one unique ability is included if there are any
    if #filteredAbilities > 0 then
        table.insert(combinedOptions, table.remove(filteredAbilities, 1))
    end

    -- Fill the rest of the combined options with general upgrades and remaining abilities
    local remainingSlots = 3 - #combinedOptions
    local allOptions = {}

    -- Add all remaining abilities and upgrades to the pool
    for _, ability in ipairs(filteredAbilities) do
        table.insert(allOptions, ability)
    end
    for _, upgrade in ipairs(generalUpgrades) do
        table.insert(allOptions, upgrade)
    end

    -- Shuffle the pool of remaining options
    shuffle(allOptions)

    -- Pick the remaining options
    for i = 1, math.min(remainingSlots, #allOptions) do
        table.insert(combinedOptions, allOptions[i])
    end

    -- Debug prints to see what options are being generated

    for _, option in ipairs(combinedOptions) do
        print(option.name)
    end

    -- Assign the final options
    self.upgradeOptions = combinedOptions
end



-- Function to apply the selected upgrade
function Experience:applySelectedUpgrade(selectedUpgrade)
    if selectedUpgrade then
    
        if selectedUpgrade.apply then
           
            selectedUpgrade.apply()
            gamePaused = false  -- Resume the game after the upgrade is applied
        else
          
        end
    else
      
    end

    -- Mark leveling up as complete
    self.isLevelingUp = false
    gamePaused = false  -- Ensure the game unpauses here

    -- Mark maxed abilities if they've reached max rank
    for _, char in pairs(self.player.characters) do
        for abilityName, ability in pairs(char.abilities) do
            if ability.rank and ability.rank >= 3 then
                self.maxedAbilities[abilityName] = true
            end
        end
    end
end



-- Upgrade function that also adds the ability to the character if it isn't there
function Abilities.upgradeAbility(character, abilityName)
    character.abilities = character.abilities or {}

    -- Find the ability definition
    local abilityDef = Abilities.abilityList[abilityName]
    if not abilityDef then
       
        return
    end

    -- Initialize or upgrade the ability
    local ability = character.abilities[abilityName]
    if not ability then
        character.abilities[abilityName] = {
            rank = 1,
            procChance = abilityDef.procChance,
            effect = abilityDef.effect  -- Set the effect function
        }
       
    elseif ability.rank < abilityDef.maxRank then
        ability.rank = ability.rank + 1
        ability.procChance = math.min(ability.procChance * 1.5, 0.9)
        ability.effect = abilityDef.effect  -- Ensure effect is assigned
      
    else
       
    end
end
return Experience
