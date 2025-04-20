-- item.lua

local Item = {}
Item.__index = Item

--------------------------------------------------------------------------
-- 1) DEFINE AFFIX POOLS (all guaranteed to yield > 0)
--------------------------------------------------------------------------
-- Common affixes (pick from these for Common, Rare, Epic, Legendary)
local commonAffixes = {
    -- Attack damage for normal auto-attacks (flat)
    {
        key   = "attackDamageFlat",
        range = function()
            -- e.g. +3..+8 (always >= 3)
            return math.random(5, 20)
        end,
    },
    -- Max health
    {
        key   = "health",
        range = function()
            -- e.g. +30..+100 (never zero)
            return math.random(150, 350)
        end,
    },
    -- Attack speed (FLAT integer bonus, e.g. +5..+10)
    {
        key   = "attackSpeedPercent",
        range = function()
            -- random integer 5..10
            return math.random(50, 50)
        end,
    },
   
    {
        key   = "attackRange",
        range = function()
            return math.random(50, 55)
        end,
    },
 

    {
        key   = "critDamageBonus",
        range = function() return math.random(10, 25)end,
    },
       {
        key   = "armor",
        range = function() return math.random(50, 50) end,
    },

}

-- Epic affixes: each specifically boosts ability damage for a given class
local epicAffixes = {
    {
        key   = "grimReaperAbilityDamage",
        range = function()
            -- +5..+20, never zero
            return math.random(2, 5)
        end,
    },
    {
        key   = "emberfiendAbilityDamage",
        range = function()
            return math.random(2, 5)
        end,
    },
    {
        key   = "stormlichAbilityDamage",
        range = function()
            return math.random(2, 5)
        end,
    },

}

-- Legendary affix (placeholder: +500 Max Health)
local legendaryAffix = {
    key   = "legendaryMaxHealth",
    range = function()
        return 500
    end,
}

--------------------------------------------------------------------------
-- 2) HELPER: pick N unique random affixes from a pool
--------------------------------------------------------------------------
local function pickRandomAffixes(pool, count)
    local chosen = {}
    local usedIndices = {}
    local poolSize = #pool
    for _ = 1, count do
        if #usedIndices >= poolSize then
            break -- no more unique affixes to pick
        end
        local idx
        repeat
            idx = math.random(1, poolSize)
        until not usedIndices[idx]

        usedIndices[idx] = true
        table.insert(chosen, pool[idx])
    end
    return chosen
end

--------------------------------------------------------------------------
-- 3) MERGE AFFIXES INTO bonusEffect
--------------------------------------------------------------------------
local function buildBonusEffect(affixes)
    local result = {}
    for _, affix in ipairs(affixes) do
        local amount = affix.range() -- e.g. 3..8, or 5..10, etc.
        result[affix.key] = (result[affix.key] or 0) + amount
    end
    return result
end

--------------------------------------------------------------------------
-- 4) BASE ITEM DEFINITIONS (no built-in affixes)
--------------------------------------------------------------------------
local itemsByQuality = {
    Common = {
        { name = "Peasant's Cloth Piece",    slot = "chest", imagePath = "assets/chest_common.png" },
        { name = "Beggar's Robes",           slot = "chest", imagePath = "assets/chest_common2.png" },
        { name = "Farmer's Tunic",           slot = "chest", imagePath = "assets/chest_common3.png" },
        { name = "Common Woven Vest",        slot = "chest", imagePath = "assets/chest_common4.png" },
        { name = "Squire's Garb",            slot = "chest", imagePath = "assets/chest_common5.png" },
        { name = "Village Linen Jacket",     slot = "chest", imagePath = "assets/chest_common6.png" },
    },
    Rare = {
        { name = "Huntsman's Leather Armor", slot = "chest", imagePath = "assets/chest_rare.png" },
        { name = "Ranger's Cloak",           slot = "chest", imagePath = "assets/chest_rare2.png" },
        { name = "Mercenary's Plate",        slot = "chest", imagePath = "assets/chest_rare3.png" },
        { name = "Knight's Chainmail",       slot = "chest", imagePath = "assets/chest_rare4.png" },
        { name = "Scout's Reinforced Vest",  slot = "chest", imagePath = "assets/chest_rare5.png" },
        { name = "Duelist's Harness",        slot = "chest", imagePath = "assets/chest_rare6.png" },
    },
    Epic = {
        { name = "Shadowguard Chestplate",   slot = "chest", imagePath = "assets/chest_epic.png" },
        { name = "Dragonfire Mail",          slot = "chest", imagePath = "assets/chest_epic2.png" },
        { name = "Celestial Robes",          slot = "chest", imagePath = "assets/chest_epic3.png" },
        { name = "Stormcaller Armor",        slot = "chest", imagePath = "assets/chest_epic4.png" },
        { name = "Phoenix Wing Vestments",   slot = "chest", imagePath = "assets/chest_epic5.png" },
        { name = "Eternal Sentinel Garb",    slot = "chest", imagePath = "assets/chest_epic6.png" },
    },
    Legendary = {
        { name = "Titan's Embrace",          slot = "chest", imagePath = "assets/chest_legendary.png" },
        { name = "Archmage's Robe",          slot = "chest", imagePath = "assets/chest_legendary2.png" },
        { name = "Divine Aegis Plate",       slot = "chest", imagePath = "assets/chest_legendary3.png" },
        { name = "Celestial Dragon Armor",   slot = "chest", imagePath = "assets/chest_legendary4.png" },
        { name = "Infinity Guardian Chestpiece", slot = "chest", imagePath = "assets/chest_legendary5.png" },
        { name = "Mythic Sovereign Vest",    slot = "chest", imagePath = "assets/chest_legendary6.png" },
    }
}

--------------------------------------------------------------------------
-- 5) ITEM CONSTRUCTOR
--------------------------------------------------------------------------
function Item.new(name, slot, imagePath, bonusEffect)
    local self = setmetatable({}, Item)
    self.name       = name
    self.slot       = slot
    self.imagePath  = imagePath or "assets/chest_common.png"
    self.image      = love.graphics.newImage(self.imagePath)
    self.image:setFilter("nearest", "nearest")

    self.bonusEffect = bonusEffect or {}

    return self
end

--------------------------------------------------------------------------
-- 6) FACTORY FUNCTION: CREATE ITEM (RANDOM AFFIXES)
--------------------------------------------------------------------------
function Item.create(quality)
    local pool = itemsByQuality[quality]
    if not pool then
        pool = itemsByQuality["Common"]
        quality = "Common"
    end

    -- Randomly pick a base item
    local baseData  = pool[math.random(1, #pool)]
    local name      = baseData.name
    local slot      = baseData.slot
    local imagePath = baseData.imagePath

    -- Determine affix counts and build bonusEffect...
    local commonCount  = 0
    local epicCount    = 0
    local hasLegendary = false

    if quality == "Common" then
        commonCount = 1
    elseif quality == "Rare" then
        commonCount = 2
    elseif quality == "Epic" then
        commonCount = 2
        epicCount   = 1
    elseif quality == "Legendary" then
        commonCount  = 2
        epicCount    = 1
        hasLegendary = true
    end

    local chosenCommons = pickRandomAffixes(commonAffixes, commonCount)
    local bonusCommon   = buildBonusEffect(chosenCommons)
    local combined = {}
    for k, v in pairs(bonusCommon) do
        combined[k] = v
    end
    if epicCount > 0 then
        local chosenEpics = pickRandomAffixes(epicAffixes, epicCount)
        local bonusEpics  = buildBonusEffect(chosenEpics)
        for k, v in pairs(bonusEpics) do
            combined[k] = (combined[k] or 0) + v
        end
    end
    if hasLegendary then
        local key = legendaryAffix.key
        local val = legendaryAffix.range()
        combined[key] = (combined[key] or 0) + val
    end

    local newItem = Item.new(name, slot, imagePath, combined)

    newItem.quality = quality   -- <--- Set the quality here
    return newItem
end


--------------------------------------------------------------------------
-- 7) HELPER METHOD: APPLY AFFIXES TO PLAYER
--------------------------------------------------------------------------
function Item:applyAffixesToPlayer(player, isEquipping)
    if not player or not player.characters then return end
    local sign = (isEquipping and 1) or -1
    local bonus = self.bonusEffect or {}

   -- Bonus Health using diminishing returns to match takeDamage logic:
local rawBonusHealth = (bonus.health or 0) + (bonus.legendaryMaxHealth or 0)
if rawBonusHealth ~= 0 then
    local baseHealth = 330  -- Starting base health
    local constant = 1000   -- Tuning constant (adjust as needed)
    local effectiveBonusHealth = rawBonusHealth / (rawBonusHealth + constant) * baseHealth

    player.teamMaxHealth = player.teamMaxHealth + (sign * effectiveBonusHealth)
    if isEquipping then
        player._teamHealth = player._teamHealth + (sign * effectiveBonusHealth)
    else
        if player._teamHealth > player.teamMaxHealth then
            player._teamHealth = player.teamMaxHealth
        end
    end
end


  

    for _, char in pairs(player.characters) do
        -- +X flat damage
        char.damage = char.damage + sign * (bonus.attackDamageFlat or 0)
        
        -- Attack speed bonus
        if bonus.attackSpeedPercent and bonus.attackSpeedPercent > 0 then
            char.equipmentAttackSpeedBonusPercent = (char.equipmentAttackSpeedBonusPercent or 0) + (sign * bonus.attackSpeedPercent)
        end

    

        -- Attack range bonus
        if bonus.attackRange then
            char.equipmentAttackRangeBonus = (char.equipmentAttackRangeBonus or 0) + (sign * bonus.attackRange)
        end

        -- Class-specific ability damage bonus
        if char.type == "Grimreaper" and bonus.grimReaperAbilityDamage then
            char.grimReaperAbilityBonus = (char.grimReaperAbilityBonus or 0) + sign * bonus.grimReaperAbilityDamage
        elseif char.type == "Emberfiend" and bonus.emberfiendAbilityDamage then
            char.emberfiendAbilityBonus = (char.emberfiendAbilityBonus or 0) + sign * bonus.emberfiendAbilityDamage
        elseif char.type == "Stormlich" and bonus.stormlichAbilityDamage then
            char.stormlichAbilityBonus = (char.stormlichAbilityBonus or 0) + sign * bonus.stormlichAbilityDamage
        end

        -- Status duration bonus
        if bonus.statusDuration and bonus.statusDuration ~= 0 then
            char.statusDurationBonus = (char.statusDurationBonus or 0) + sign * bonus.statusDuration
        end
    end
end


return Item
