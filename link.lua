local Link = {}
Link.__index = Link

local Abilities = require("abilities")

-- Preload link assets.
local images = {
  grey           = love.graphics.newImage("assets/greylink.png"),
  haste          = love.graphics.newImage("assets/hastelink.png"),
  heal           = love.graphics.newImage("assets/heallink.png"),
  summon         = love.graphics.newImage("assets/summonlink.png"),
  emberfiend     = love.graphics.newImage("assets/emberfiendlink.png"),
  stormlich      = love.graphics.newImage("assets/stormlichlink.png"),
  grimreaper     = love.graphics.newImage("assets/grimreaperlink.png"),
  joker          = love.graphics.newImage("assets/jokerlink.png"), -- New joker image
}
for key, img in pairs(images) do
  img:setFilter("nearest", "nearest")
end

-- Helper function to get unlocked abilities for a specific class
local function getUnlockedAbilitiesFor(classType)
  local abilities = {}
  -- This should integrate with your existing ability system
  if classType == "Stormlich" then
    -- Get Stormlich abilities
    abilities = {"Storm Arc", "Discharge", "Zephyr Shield", "Blizzard"}
  elseif classType == "Emberfiend" then  
    -- Get Emberfiend abilities
    abilities = {"Molten Orbs", "Hellblast", "Infernal Rain", "Flame Burst"}
  elseif classType == "Grimreaper" then
    -- Get Grimreaper abilities  
    abilities = {"Phantom Fright", "Necrotic Breath", "Unholy Ground", "Summon Goyle"}
  end
  return abilities
end

-- Helper function to get all unlocked abilities across classes
local function getUnlockedAbilitiesForJoker()
  local allAbilities = {}
  
  -- Get abilities from each class
  local stormlichAbilities = getUnlockedAbilitiesFor("Stormlich")
  local emberfiendAbilities = getUnlockedAbilitiesFor("Emberfiend") 
  local grimreaperAbilities = getUnlockedAbilitiesFor("Grimreaper")
  
  -- Combine all abilities
  for _, ability in ipairs(stormlichAbilities) do
    table.insert(allAbilities, {name = ability, class = "Stormlich"})
  end
  for _, ability in ipairs(emberfiendAbilities) do
    table.insert(allAbilities, {name = ability, class = "Emberfiend"})
  end
  for _, ability in ipairs(grimreaperAbilities) do
    table.insert(allAbilities, {name = ability, class = "Grimreaper"}) 
  end
  
  return allAbilities
end

-- First, update the resolveAbility function to always treat abilities as repeatable
local function resolveAbility(linkType, abilityList, comboOutcome)
  local result = {
    abilities = {},
    powerMultipliers = {}
  }

  -- Helper function to add an ability with power multiplier
  local function addAbility(ability, powerMult)
    table.insert(result.abilities, ability)
    table.insert(result.powerMultipliers, powerMult)
  end

  -- Count jokers in the combo
  local jokerCount = 0
  for _, link in ipairs(comboOutcome) do
    if link.type == "joker" then
      jokerCount = jokerCount + 1
    end
  end

  -- Always use the first available ability as our base
  local baseAbility = abilityList[1]
  if not baseAbility then return result end

  if #comboOutcome == 1 then
    -- Single match - cast once at base power
    addAbility(baseAbility, 1.0)
    
  elseif #comboOutcome == 2 then
    if jokerCount == 0 and comboOutcome[1].type == comboOutcome[2].type then
      -- Two same-class links: Cast twice with increased power
      addAbility(baseAbility, 1.0)
      addAbility(baseAbility, 1.2)

    elseif jokerCount == 1 then
      -- One class + one joker: Cast twice with higher power
      addAbility(baseAbility, 1.0)
      addAbility(baseAbility, 1.3)

    elseif jokerCount == 2 then
      -- Two jokers: Cast twice with enhanced power
      addAbility(baseAbility, 1.2)
      addAbility(baseAbility, 1.2)
    end
    
  elseif #comboOutcome == 3 then
    if jokerCount == 0 and comboOutcome[1].type == comboOutcome[2].type 
       and comboOutcome[2].type == comboOutcome[3].type then
      -- Three same-class links: Cast three times with increasing power
      addAbility(baseAbility, 1.0)
      addAbility(baseAbility, 1.2)
      addAbility(baseAbility, 1.5)

    elseif jokerCount == 1 then
      -- Two same class + one joker
      addAbility(baseAbility, 1.2)
      addAbility(baseAbility, 1.2)
      addAbility(baseAbility, 1.4)

    elseif jokerCount == 2 then
      -- One class + two jokers
      addAbility(baseAbility, 1.3)
      addAbility(baseAbility, 1.3)
      addAbility(baseAbility, 1.3)

    elseif jokerCount == 3 then
      -- Three jokers
      addAbility(baseAbility, 1.2)
      addAbility(baseAbility, 1.2)
      addAbility(baseAbility, 1.2)
    end
  end
  
  return result
end

function Link.new(posA, posB, nodeA, nodeB, linkType)
  local self = setmetatable({}, Link)
  self.x = (posA.x + posB.x) / 2
  self.y = (posA.y + posB.y) / 2
  self.nodeA = nodeA
  self.nodeB = nodeB
  self.type = linkType or "grey"
  return self
end

--- Modified Link:onExpire to enforce class-based 3-of-a-kind enhanced casts
function Link:onExpire(player)
  local Abilities            = require("abilities")
  local LinkPool             = require("LinkPool")
  local currentTime          = love.timer.getTime()
  local delayBetweenCasts    = 1.0
  local combo                = player.currentLinkCombo or { self }

  -- Map link types to character class names
  local classMap = { stormlich = "Stormlich", emberfiend = "Emberfiend", grimreaper = "Grimreaper" }
  local className = classMap[self.type]

  -- 1) Strict 3-of-a-kind for a class: pick one random ability and fire its enhanced effect
  if className and #combo == 3 then
      local strictMatch = true
      for _, link in ipairs(combo) do
          if link.type ~= self.type then
              strictMatch = false
              break
          end
      end
      if strictMatch then
          -- Choose a random ability from this class's pool
          local pool = getUnlockedAbilitiesFor(className)
          if #pool > 0 then
              local choice = pool[love.math.random(#pool)]
              player.pendingAbilityActivations = player.pendingAbilityActivations or {}
              table.insert(player.pendingAbilityActivations, {
                  scheduledTime   = currentTime,
                  abilityName     = choice,
                  character       = player.characters[className],
                  enhanced        = true,
                  powerMultiplier = 1.5,
              })
          end
          player:triggerLinkExpireEffect(self.type)
          return LinkPool.releaseLink(self)
      end
  end

  -- 2) Catch any ability-specific link
  for abilityName, def in pairs(Abilities.abilityList) do
      if def.linkType == self.type then
          local char = player.characters[def.class.name]
          if char then
              local single = {{ name = abilityName, effect = def.effect, enhancedEffect = def.enhancedEffect }}
              local resolution = resolveAbility(self.type, single, combo)
              player.pendingAbilityActivations = player.pendingAbilityActivations or {}
              for i, _ in ipairs(resolution.abilities) do
                  table.insert(player.pendingAbilityActivations, {
                      scheduledTime   = currentTime + (i-1) * delayBetweenCasts,
                      abilityName     = abilityName,
                      character       = char,
                      enhanced        = (resolution.powerMultipliers[i] or 1) > 1,
                      powerMultiplier = resolution.powerMultipliers[i] or 1,
                  })
              end
          end
          player:triggerLinkExpireEffect(self.type)
          return LinkPool.releaseLink(self)
      end
  end

  -- 3) Existing buff & generic-class logic
  if self.type == "haste" then
      player:applyStatusEffect(nil, "Haste", 5, 25)
  elseif self.type == "heal" then
      local healAmount = 0.10 * player.teamMaxHealth
      player._teamHealth = math.min(player._teamHealth + healAmount, player.teamMaxHealth)
  elseif self.type == "summon" then
      require("abilities").summongoyle(player, 10, 60, 1, player.summonedEntities, _G.enemies, _G.effects, _G.damageNumbers)
  elseif self.type == "joker" or className then
      -- Determine casting character
      local castingChar
      if self.type == "joker" then
          for _, c in ipairs({"Stormlich","Emberfiend","Grimreaper"}) do
              if player:hasUnlockedAbilities(c) then
                  castingChar = player.characters[c]
                  break
              end
          end
      else
          castingChar = player.characters[className]
      end
      if castingChar then
          -- Pick the first available ability in that character's pool
          for name, ab in pairs(castingChar.abilities) do
              if ab.effect then
                  local single = {{ name = name, effect = ab.effect, enhancedEffect = ab.enhancedEffect }}
                  local resolution = resolveAbility(self.type, single, combo)
                  player.pendingAbilityActivations = player.pendingAbilityActivations or {}
                  for i, _ in ipairs(resolution.abilities) do
                      table.insert(player.pendingAbilityActivations, {
                          scheduledTime   = currentTime + (i-1) * delayBetweenCasts,
                          abilityName     = name,
                          character       = castingChar,
                          enhanced        = (resolution.powerMultipliers[i] or 1) > 1,
                          powerMultiplier = resolution.powerMultipliers[i] or 1,
                      })
                  end
                  break
              end
          end
      end
  end

  -- Trigger link effect and release back to pool
  player:triggerLinkExpireEffect(self.type)
  return LinkPool.releaseLink(self)
end

function Link:draw(scale)
  scale = scale or 2
  local img = images.grey
  if self.type == "moltenorbslink" or self.type == "infernalrainlink" or self.type == "flameburstlink" then
    img = images.emberfiend
  elseif self.type == "necroticbreathlink" or self.type == "necroticburstlink" or self.type == "unholygroundlink" then
    img = images.grimreaper
  elseif self.type == "stormarclink" or self.type == "dischargelink" or self.type == "zephyrshieldlink" then
    img = images.stormlich
  else
    img = images[self.type] or images.grey
  end
  love.graphics.draw(img, self.x, self.y, 0, scale, scale, img:getWidth()/2, img:getHeight()/2)
end

return Link
