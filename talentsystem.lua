-- talentSystem.lua
local talentSystem = {}
talentSystem.__index = talentSystem

--------------------------------------------------------------------------------
-- UTILITY: createTalent
--------------------------------------------------------------------------------
local function createTalent(params)
    -- Safeguard any missing fields:
    local t = {
        id          = params.id or 0,
        tab         = params.tab or "General",
        name        = params.name or "(Unnamed Talent)",
        description = params.description or "",
        maxRank     = params.maxRank or 0,
        currentRank = params.currentRank or 0,  -- default to 0
        baseValue   = params.baseValue or 0,
        soulsReq    = params.soulsReq or 1,     -- default = 1
        iconPath    = params.iconPath or nil,

        -- returns the numeric "bonus" from the talent
        getValue = function(self)
            -- again, just in case:
            local rank = self.currentRank or 0
            local base = self.baseValue or 0
            return rank * base
        end
    }
    return t
end

--------------------------------------------------------------------------------
-- 1. TALENT TABLE
--    Use createTalent() for *all* talents (including placeholders)
--------------------------------------------------------------------------------
local talents = {
    ----------------------------------------
    -- General tab (IDs 1..16)
    ----------------------------------------
  createTalent{
    id=1, 
    tab="General",
    name="Blessing of Abundance",
    description="The earth’s magic flows freely. Food drops are more plentiful by 1% per rank.",
    maxRank=5,
    baseValue=0.01,  -- 1% per rank
    soulsReq=1,
    iconPath = "assets/talent1.png"
},
    createTalent{
    id=2, 
    tab="General",
    name="Windwalk",
    description="Step with the swiftness of the spirits. Reduces dash cooldown by 1s per rank.",
    maxRank=5,
    baseValue=1,    -- Each rank grants a 1s reduction
    soulsReq=1,      -- Soul level requirement, adjust as needed
    iconPath = "assets/talent2.png"
},
    createTalent{
    id=3, 
    tab="General",
    name="Alchemist's Touch",
    description="The art of potions is bestowed. The Potion refills faster by 2% per rank.",
    maxRank=5,
    baseValue=1,
    soulsReq=1,
    iconPath = "assets/talent3.png"
},
    createTalent{
    id=4, 
    tab="General",
    name="Purity of the Harvest",
    description="The crops are cleansed by ritual—food is never poisonous again.",
    maxRank=1,
    baseValue=1,
    soulsReq=5,
    iconPath = "assets/talent4.png"
},

    createTalent{
    id=5, 
    tab="General",
    name="Twin Steps",
    description="Dance between realms. Gain an additional dash charge.",
    maxRank=1,
    baseValue=1,
    soulsReq=5,
    iconPath = "assets/talent5.png"
},

    createTalent{
    id=6,
    tab="General",
    name="Herbal Infusion",
    description="Healing herbs amplify their magic. Potions heal 25% more.",
    maxRank=1,
    baseValue=1,
    soulsReq=5,
    iconPath = "assets/talent6.png"
},

    createTalent{
    id=7,
    tab="General",
    name="Ritual Feast",
    description="The sacred meal lingers. Positive food buffs last 5s longer.",
    maxRank=1,
    baseValue=5,   
    soulsReq=10,
    iconPath = "assets/talent7.png"
},
    createTalent{
    id=8,
    tab="General",
    name="Shadow's Grace",
    description="Cloaked in the veil of night—take no damage while dashing.",
    maxRank=1,
    baseValue=1,
    soulsReq=10,
    iconPath = "assets/talent8.png"
},
    createTalent{
    id=9,
    tab="General",
    name="Witch’s Draught",
    description="Every potion is a brew of power—gain a random food buff each time you drink.",
    maxRank=1,
    baseValue=1,
    soulsReq=10,  -- Adjust if needed
    iconPath = "assets/talent9.png"
},

 

    ----------------------------------------
    -- Combat tab (IDs 17..32)
    ----------------------------------------
    createTalent{
        id=17, tab="Combat",
        name="Windborne Stride",
        description="The winds guide every step. Movement speed is increased by 10 per rank.",
        maxRank=3,
        baseValue=10,
        soulsReq=1,
        iconPath = "assets/talent10.png"
        
    },
    createTalent{
        id=18, tab="Combat",
        name="Ethereal Reach",
        description="Attacks extend like shadowed tendrils. Attack range is increased by 20 per rank.",
        maxRank=3,
        baseValue=20,
        soulsReq=1,
        iconPath = "assets/talent11.png"
    },
    createTalent{
        id=19, 
        tab="Combat",
        name="Cursed Edge",
        description="Strikes carry a hex of ruin—critical strikes deal additional damage by 50% each rank.",
        maxRank=3,
        baseValue=0.25,  -- +0.25x crit damage each rank
        soulsReq=1,
        iconPath = "assets/talent12.png"
},
-- In your talents table:
        createTalent{
            id=20, 
            tab="Combat",
            name="Feral Swiftness",
            description="Hands move with the speed of a wild spirit. Autoattacks are faster by 1% per rank.",
            maxRank=3,
            baseValue=0.1,  -- 1% per rank
            soulsReq=5,
            iconPath = "assets/talent13.png"
},

        createTalent{
            id=21, 
            tab="Combat",
            name="Arcane Echoes",
            description="When an attack deals damage, there is a chance to immediately fire again by 2% per rank.",
            maxRank=3,
            baseValue=0.02,  -- 1% chance per rank
            soulsReq=5,
            iconPath = "assets/talent14.png"
        },


        createTalent{
            id=22, tab="Combat",
            name="Critical Strike",
            description="Increases critical hit chance by 1% per rank.",
            maxRank=5,
            baseValue=1,  -- 1% per rank
            soulsReq=5,
            iconPath = "assets/talent15.png"
        },
    
           createTalent{
        id = 23,
        tab = "Combat",
        name = "Leeching Essence",
        description = "Every strike drinks the essence of your enemies, healing for 1% of the damage dealt. When health is full, the leeching essence gathers into a Blood Slime. The Blood Slime fights and explodes upon expiration.",
        maxRank = 1,
        baseValue = 0.05, -- 1% leech
        soulsReq = 10,
        iconPath = "assets/talent16.png"
    },
      createTalent{
        id = 24,
        tab = "Combat",
        name = "Harrowing Instincts",
        description = "Each strike sharpens predatory focus, increasing critical strike chance by 2% (stacking up to 10). After landing a critical hit, enemies near the target flee for 3s. Crit also resets stacks.",
        maxRank = 1,
        baseValue = 1,
        soulsReq = 10,
        iconPath = "assets/talent17.png"
      
    },
    
      createTalent{
        id = 25,
        tab = "Combat",
        name = "Sanguine Frenzy",
        description = "When slaying an enemy with an autoattack, their blood erupts in a damaging AoE. Enemies caught are cursed with madness for 5s, attacking each other. Occurs once every 15s.",
        maxRank = 1,
        baseValue = 0.1,
        soulsReq = 10,
        iconPath = "assets/talent18.png"
        
    },



    ----------------------------------------
    -- Abilities tab (IDs 33..48)
    ----------------------------------------
     createTalent{
    id = 35, 
    tab = "Abilities",
    name = "Unified Ability Boost",
    description = "Increases ability damage for all characters by 5 per rank.",
    maxRank = 5,
    baseValue = 5,  -- Flat bonus of 5 per rank
    soulsReq = 1,
    iconPath = "assets/talent19.png"  -- Use an appropriate icon (or omit)
  },


 createTalent{
        id = 36, 
        tab = "Abilities",
        name = "Accelerated Ability Unlock",
        description = "Increases the chance for higher-level abilities to appear in upgrade choices by 1% per rank.",
        maxRank = 3,
        baseValue = 0.01,  -- 1% per rank
        soulsReq = 1,
        iconPath = "assets/talent20.png"  -- Replace with your asset path
    },
    
    createTalent{
    id = 37, 
    tab = "Abilities",
    name = "Vital Surge",
    description = "Grants a chance on level up to gain Haste, Fury and Regen status effects by 25% per rank.",
    maxRank = 3,
    baseValue = .25,  -- 10% chance per rank
    soulsReq = 1,
    iconPath = "assets/talent21.png"  -- use an appropriate icon
},

    createTalent{
        id = 38,
        tab = "Abilities",
        name = "Necrotic Chain",
        description = "When Necrotic Breath deals damage, there's a chance to trigger a necrotic arc that chains to a nearby enemies.",
        maxRank = 3,
        baseValue = 0.1,  -- (baseValue not used directly here)
        soulsReq = 5,
        iconPath = "assets/talent22.png"
},

createTalent{
    id = 39,
    tab = "Abilities",
    name = "Flaming Arc",
    description = "Each time Storm Arc damages an enemy, it has a chance to ignite enemies.",
    maxRank = 3,
    baseValue = 0.1,  -- (This baseValue is just a placeholder; we use the rank directly below)
    soulsReq = 5,
    iconPath = "assets/talent23.png"
},

-- In the Abilities tab section, after the Flaming Arc entry (ID 39):
createTalent{
    id = 40,
    tab = "Abilities",
    name = "Ember Summoning",
    description = "When Molten Orbs explodes, there's a chance to summon Firelings that attack enemies for a short time.",
    maxRank = 3,
    baseValue = 0.15,  -- Not used directly
    soulsReq = 5,
    iconPath = "assets/talent24.png"
},
createTalent{
    id = 41,
    tab = "Abilities",
    name = "Goyle’s Awakening",
    description = "Rank 1: When an enemy dies from Unholy Ground's damage, a Goyle is summoned (100% chance). Rank 2: Unholy Ground’s damage is increased by 20%. Rank 3: Start each run with Unholy Ground at Rank 1.",
    maxRank = 3,
    baseValue = 1,  
    soulsReq = 10,
    iconPath = "assets/talent25.png"
},
createTalent{
    id = 42, 
    tab = "Abilities",
    name = "Frozen Fury",
    description = "Rank 1: When an enemy dies from Blizzard's damage, it shatters into 12 shards, which pierce and deal light damage in a medium radius.\nRank 2: When a shard deals damage, there is a small chance to trigger another Blizzard.\nRank 3: Start each run with Rank 1 of Blizzard.",
    maxRank = 3,
    baseValue = 1,
    soulsReq = 10,
    iconPath = "assets/talent26.png"
},

createTalent{
    id = 43, 
    tab = "Abilities",
    name = "Ember's Legacy",
    description = table.concat({
      "Rank 1 – The Elemental lasts 5 extra seconds and all its attacks deal 100% more damage.",
      "Rank 2 – The Elemental now explodes upon death tossing out many firebombs around him.",
      "Rank 3 – Start each run with Rank 1 of Infernal Sacrifice."
    }, "\n"),
    maxRank = 3,
    baseValue = 10, 
    soulsReq = 1,
    iconPath = "assets/talent27.png"  -- adjust the asset path as needed
},


}


--------------------------------------------------------------------------------
-- 2. GET / LOOKUP
--------------------------------------------------------------------------------
function talentSystem.getAllTalents()
    return talents
end

function talentSystem.getTalentByID(id)
    for _, t in ipairs(talents) do
        if t.id == id then
            return t
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- 2a. getDynamicDescription(t)
--------------------------------------------------------------------------------
function talentSystem.getDynamicDescription(t)
    return t.description or "(No Description)"
end


--------------------------------------------------------------------------------
-- 3. SPEND TALENT POINT
--------------------------------------------------------------------------------
function talentSystem.spendPoint(talentID, availablePoints, playerSoulsLevel)
  

    local t = talentSystem.getTalentByID(talentID)
    if not t then
        return false, "Talent not found"
    end

    -- Check souls level
    if playerSoulsLevel and playerSoulsLevel < t.soulsReq then
        return false, ("Requires Souls Level " .. t.soulsReq)
    end

    -- Check rank
    if (t.currentRank or 0) >= (t.maxRank or 0) then
        return false, "Already at max rank!"
    end

    -- Check points
    if availablePoints <= 0 then
        return false, "Not enough talent points."
    end

    -- OK, increment rank
    t.currentRank = (t.currentRank or 0) + 1
    return true
end

--------------------------------------------------------------------------------
-- 4. APPLY TALENTS TO THE PLAYER
--------------------------------------------------------------------------------
function talentSystem.applyTalentsToPlayer(player)
    if not player or not player.characters then return end



    -- Reset player-wide talent-derived fields
    player.hasLeechingEssence = false
    player.leechingEssencePercent = 0
    player.hasHarrowingInstincts = false
    player.harrowingInstinctStacks = 0
    player.harrowingInstinctMaxStacks = 10
    player.talentCritChanceBonus = 0
    player.hasSanguineFrenzy = false
    player.sanguineFrenzyCooldown = false
    player.sanguineFrenzyCooldownTimer = 0

    local totalSpeed = 0
    local totalRange = 0
    local totalDamage = 0
    local totalCritChance = 0
    local totalFoodDropBonus = 0
    local dashCooldownReduction = 0
    local alchemistBonus = 0
    local attackSpeedBonusMult = 0

    -- *** Calculate the unified ability bonus first ***
    local unifiedBonus = 0
    for _, t in ipairs(talentSystem.getAllTalents()) do
        if t.name == "Unified Ability Boost" then
            unifiedBonus = (t.currentRank or 0) * t.baseValue
            break
        end
    end

    -- Process each talent and store the necessary data on the player.
    for _, t in ipairs(talentSystem.getAllTalents()) do
        if t.name == "Blessing of Abundance" then
            totalFoodDropBonus = totalFoodDropBonus + ((t.currentRank or 0) * (t.baseValue or 0))
        elseif t.name == "Ethereal Reach" then
            totalRange = totalRange + ((t.currentRank or 0) * (t.baseValue or 0))
        elseif t.name == "Brutal Blows" then
            totalDamage = totalDamage + ((t.currentRank or 0) * (t.baseValue or 0))
        elseif t.name == "Critical Strike" then
            totalCritChance = totalCritChance + ((t.currentRank or 0) * (t.baseValue or 0))
          
        elseif t.name == "Windwalk" then
            dashCooldownReduction = dashCooldownReduction + ((t.currentRank or 0) * (t.baseValue or 0))
        elseif t.name == "Windborne Stride" then
            totalSpeed = totalSpeed + ((t.currentRank or 0) * (t.baseValue or 0))
        elseif t.name == "Alchemist's Touch" then
            alchemistBonus = alchemistBonus + ((t.currentRank or 0) * (t.baseValue or 0))
        elseif t.name == "Purity of the Harvest" then
            if (t.currentRank or 0) > 0 then
                player.noPoisonFood = true
            end
        elseif t.name == "Twin Steps" then
            if (t.currentRank or 0) > 0 then
                player.hasTwinSteps = true
            end
        elseif t.name == "Herbal Infusion" then
            if (t.currentRank or 0) > 0 then
                player.herbalInfusionActive = true
            end
        elseif t.name == "Ritual Feast" then
            if (t.currentRank or 0) > 0 then
                player.ritualFeastBonus = t.baseValue
            end
        elseif t.name == "Shadow's Grace" then
            if (t.currentRank or 0) > 0 then
                player.hasShadowsGrace = true
            end
        elseif t.name == "Witch’s Draught" then
            if (t.currentRank or 0) > 0 then
                player.hasWitchsDraught = true
            end
        elseif t.name == "Cursed Edge" then
            if (t.currentRank or 0) > 0 then
                player.critDamageBonus = (player.critDamageBonus or 0) + ((t.currentRank or 0) * (t.baseValue or 0))
            end
        elseif t.name == "Feral Swiftness" then
            attackSpeedBonusMult = attackSpeedBonusMult + ((t.currentRank or 0) * (t.baseValue or 0))
        elseif t.name == "Arcane Echoes" then
            if (t.currentRank or 0) > 0 then
                player.arcaneEchoChance = (t.currentRank or 0) * (t.baseValue or 0)
            end
        elseif t.name == "Leeching Essence" then
            if (t.currentRank or 0) > 0 then
                player.hasLeechingEssence = true
                player.leechingEssencePercent = t.baseValue
            end
        elseif t.name == "Harrowing Instincts" then
            if (t.currentRank or 0) > 0 then
                player.hasHarrowingInstincts = true
            end
        elseif t.name == "Sanguine Frenzy" then
            if (t.currentRank or 0) > 0 then
                player.hasSanguineFrenzy = true
                player.sanguineFrenzyCooldown = false
            end
        elseif t.name == "Accelerated Ability Unlock" then
            player.abilityUnlockBonus = (t.currentRank or 0) * (t.baseValue or 0)
        elseif t.name == "Vital Surge" then
            player.vitalSurgeChance = (t.currentRank or 0) * (t.baseValue or 0)
        elseif t.name == "Chain of the Reaper" then
            player.chainOfTheReaperRank = t.currentRank or 0
        elseif t.name == "Flaming Arc" then
            player.flamingArcRank = t.currentRank or 0
        elseif t.name == "Ember Summoning" then
            player.emberSummoningRank = t.currentRank or 0
        elseif t.name == "Goyle’s Awakening" then
            player.goylesAwakeningRank = t.currentRank or 0
        elseif t.name == "Frozen Fury" then
            player.frozenFuryRank = t.currentRank or 0
        elseif t.name == "Ember's Legacy" then
            player.emberLegacy = t.currentRank or 0

    end
    end

    player.talentCritChanceBonus = totalCritChance
  

    player.dashCooldownReduction = dashCooldownReduction
    player.alchemistBonus = alchemistBonus
    player.talentSpeedBonus = totalSpeed
    player.talentCritChanceBonus = totalCritChance
    talentSystem.foodDropBonus = totalFoodDropBonus

    for _, char in pairs(player.characters) do
        if char.type == "Grimreaper" then
            char.grimReaperAbilityBonus = (char.grimReaperAbilityBonus or 0) + unifiedBonus
        elseif char.type == "Emberfiend" then
            char.emberfiendAbilityBonus = (char.emberfiendAbilityBonus or 0) + unifiedBonus
        elseif char.type == "Stormlich" then
            char.stormlichAbilityBonus = (char.stormlichAbilityBonus or 0) + unifiedBonus
        end
    end

    for _, char in pairs(player.characters) do
        char.attackRange = char.baseAttackRange + (char.equipmentAttackRangeBonus or 0) + totalRange
        char.damage = char.baseDamage + (char.equipmentFlatDamage or 0) + totalDamage
        local equipASBonus = (char.equipmentAttackSpeedBonusPercent or 0) / 100
        char.attackSpeed = char.baseAttackSpeed * (1 + equipASBonus + attackSpeedBonusMult)
  
    
     if char.type == "Emberfiend" then
        char.emberLegacy = player.emberLegacy or 0
  
    end
end
    -- If the player has "Goyle’s Awakening" talent at Rank 3, force Unholy Ground to start at Rank 1.
    if player.goylesAwakeningRank and player.goylesAwakeningRank == 3 then
        for _, char in pairs(player.characters) do
            if char.abilities and char.abilities["Unholy Ground"] then
                char.abilities["Unholy Ground"].rank = math.max(1, char.abilities["Unholy Ground"].rank)
            end
        end
    end
  if player.frozenFuryRank and player.frozenFuryRank == 3 then
    for _, char in pairs(player.characters) do
        if char.abilities and char.abilities["Blizzard"] then
            char.abilities["Blizzard"].rank = math.max(1, char.abilities["Blizzard"].rank)
        end
    end
end

end



function talentSystem.getCurrentFoodDropChance()
    -- Base food drop chance is 5%
    local baseChance = 0.02
    -- Add the accumulated bonus from talents
    local bonusChance = (talentSystem.foodDropBonus or 0)
    return baseChance + bonusChance  
end

function talentSystem.updateTalents(player, dt)
    if player.hasSanguineFrenzy and player.sanguineFrenzyCooldown then
        player.sanguineFrenzyCooldownTimer = player.sanguineFrenzyCooldownTimer - dt
        if player.sanguineFrenzyCooldownTimer <= 0 then
            player.sanguineFrenzyCooldown = false
            player.sanguineFrenzyCooldownTimer = 0
            
        end
    end

  
end


return talentSystem
