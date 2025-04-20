-- Abilities.lua
local Abilities = {}
local Effects = require("effects")
local Collision = require("collision")
local ZephyrShield = require "zephyr_shield"

local goyleImage = love.graphics.newImage("assets/goyle.png")
goyleImage:setFilter("nearest", "nearest")  -- Ensure pixelated scaling


local goyleFrames = {
    love.graphics.newQuad(0, 0, 16, 16, goyleImage:getDimensions()),
    love.graphics.newQuad(16, 0, 16, 16, goyleImage:getDimensions()),
    love.graphics.newQuad(32, 0, 16, 16, goyleImage:getDimensions())
}

local bloodslimeImage = love.graphics.newImage("assets/bloodslime.png")
bloodslimeImage:setFilter("nearest", "nearest")  -- Ensure pixelated scaling


local bloodslimeFrames = {
    love.graphics.newQuad(0, 0, 16, 16, bloodslimeImage:getDimensions()),
    love.graphics.newQuad(16, 0, 16, 16, bloodslimeImage:getDimensions()),
    love.graphics.newQuad(32, 0, 16, 16, bloodslimeImage:getDimensions())
}


local phantomImage = love.graphics.newImage("assets/phantom.png")
phantomImage:setFilter("nearest", "nearest")
local phantomFrames = {
    love.graphics.newQuad(0, 0, 16, 16, phantomImage:getDimensions()),
    love.graphics.newQuad(16, 0, 16, 16, phantomImage:getDimensions()),
    love.graphics.newQuad(32, 0, 16, 16, phantomImage:getDimensions())
}

local firelingImage = love.graphics.newImage("assets/fireling.png")
firelingImage:setFilter("nearest", "nearest")  -- Ensure pixelated scaling

local firelingFrames = {
    love.graphics.newQuad(0, 0, 16, 16, firelingImage:getDimensions()),
    love.graphics.newQuad(16, 0, 16, 16, firelingImage:getDimensions()),
    love.graphics.newQuad(32, 0, 16, 16, firelingImage:getDimensions()),
    love.graphics.newQuad(48, 0, 16, 16, firelingImage:getDimensions())
}

local elementalImage = love.graphics.newImage("assets/elemental.png")
elementalImage:setFilter("nearest", "nearest")
local elementalFrames = {
    love.graphics.newQuad(0, 0, 16, 16, elementalImage:getDimensions()),
    love.graphics.newQuad(16, 0, 16, 16, elementalImage:getDimensions()),
    love.graphics.newQuad(32, 0, 16, 16, elementalImage:getDimensions())
}

local shieldImage = love.graphics.newImage("assets/shield_throw.png")
shieldImage:setFilter("nearest", "nearest")
local DamageNumber = require("damage_number")

local function scalingFactor(rank, baseFactor)
    return 1 + baseFactor * rank / (1 + rank)
end


-- Function to update cooldown timers for a character
function Abilities.updateCooldowns(character, dt)
    if not character.abilities then return end
    for abilityName, ability in pairs(character.abilities) do
        -- Decrement cooldown
        if ability.cooldownTimer and ability.cooldownTimer > 0 then
            ability.cooldownTimer = ability.cooldownTimer - dt
            if ability.cooldownTimer < 0 then
                ability.cooldownTimer = 0
            end
        end

      
    end
end



-- Define status effects
-- abilities.lua

Abilities.statusEffects = {
    Poison = { name = "Poison", duration = 15, damagePerSecond = 3 },
    Ignite = { name = "Ignite", duration = 5, damagePerSecond = 10 },
    Shock =  { name = "Shock", duration = 2 },
    Fear =  { name = "Fear", duration = 5 },
   Haste = { name = "Haste", duration = 5, speedBonus = 25 }, -- Base speed bonus added 
    Fury = { name = "Fury", duration = 5, attackSpeedMultiplier = 2 }, -- Ensure Fury is also defined
    Madness = { name = "Madness", duration = 5 },
}


-- Define all abilities here
Abilities.abilityList = {
  
["Phantom Fright"] = {
    name = "Phantom Fright",
    linkType = "phantomfrightlink",
    attackType = "projectile",
    rank = 1,
    maxRank = 3,
    class = { name = "Grimreaper", color = {0.678, 0.047, 0.910} },
    description = "Attacks summon a phantom minion whose strikes instill Fear and Poison.",
    cooldown = 0,
    cooldownTimer = 0,
    effect = function(char, enemy, effects, sounds, summonedEntities, enemies, damageNumbers, proj)
        if not enemy then
      return
    end
      local ability = char.abilities["Phantom Fright"]
      local rank = ability.rank or 1
      local duration = 10 + (rank - 1) * 2
      local speed = 60 + (rank - 1) * 10
      local multiplier = (rank == 1 and 1.3) or (rank == 2 and 1.5) or 1.7
      -- Always summon the phantom when activated via link.
      Abilities.summonPhantom(char, duration, speed, multiplier, char.owner.summonedEntities, enemies, effects, damageNumbers)
      local phantomSound = love.audio.newSource("assets/sounds/effects/summon_phantom.wav", "static")
      phantomSound:setVolume(1)
      phantomSound:play()
    end,
  },

 ["Necrotic Breath"] = {
  name = "Necrotic Breath",
  linkType = "necroticbreathlink",
  attackType = "projectile",
  rank = 1,
  maxRank = 5,
  class = { name = "Grimreaper", color = {0.678, 0.047, 0.910} },
  description = "Breathe a cone of necrotic flames that damage all enemies in its path. (Triggered via its link.)",
  effect = function(char, enemy, effects, sounds, summonedEntities, enemies, proj)
      if not enemy then
      return
    end
    -- Normal effect
    local closestEnemy, minDist = nil, math.huge
    for _, e in ipairs(enemies) do
      local dx = e.x - char.x
      local dy = e.y - char.y
      local dist = math.sqrt(dx * dx + dy * dy)
      if dist < minDist then
        minDist = dist
        closestEnemy = e
      end
    end
    if not closestEnemy then return end
    local dx = closestEnemy.x - char.x
    local dy = closestEnemy.y - char.y
    local angle = math.atan2(dy, dx)
    local ability = char.abilities["Necrotic Breath"]
    local rank = ability.rank or 1
    -- Base damage scales with a 15% multiplier per rank.
    local baseDamage = char.damage * (1 + 0.15 * rank)
    local finalDamage = Abilities.calculateFinalDamage(char, baseDamage)
    local coneAngle = math.rad(30)
    local numFlames = 8
    -- Use a reduced range (for a short, concentrated breath)
    local flameRange = 150 * 0.25
    local flameSpeed = 250
    for i = 1, numFlames do
      local angleOffset = (love.math.random() - 0.1) * coneAngle
      local flameAngle = angle + angleOffset
      local flameDirX = math.cos(flameAngle)
      local flameDirY = math.sin(flameAngle)
      local flame = Effects.new("necrotic_flame", char.x, char.y,
                                  char.x + flameDirX * flameRange,
                                  char.y + flameDirY * flameRange)
      flame.damage = finalDamage
      flame.speed = flameSpeed
      flame.scale = 1
      flame.impactRadius = 15
      flame.enemies = enemies
      flame.effects = effects
      flame.onHitEnemy = function(targetEnemy)
        targetEnemy:takeDamage(finalDamage, flame.damageNumbers, effects, "Grimreaper", nil, "ability")
        -- Low chance to poison (15% chance)
        if math.random() < 0.15 then
          Abilities.applyPoison(targetEnemy, rank, effects, sounds, char)
        end
        -- Chain-of-the-Reaper talent bonus (if any)
        local chainedTargets = {}
        if char.owner and char.owner.chainOfTheReaperRank and char.owner.chainOfTheReaperRank > 0 then
          local talentRank = char.owner.chainOfTheReaperRank
          local procChance = (talentRank == 1 and 0.20) or (talentRank == 2 and 0.30) or 0.40
          if math.random() < procChance then
            local bonusMultiplier = (talentRank == 1 and 0.15) or (talentRank == 2 and 0.20) or 0.25
            local numBolts = (talentRank == 3 and 3) or 2
            for j = 1, numBolts do
              local newTarget = Abilities.findNewTarget(targetEnemy, enemies)
              if newTarget and not chainedTargets[newTarget] then
                chainedTargets[newTarget] = true
                local chainEffect = Effects.new("necrotic_chain", targetEnemy.x, targetEnemy.y, newTarget.x, newTarget.y)
                chainEffect.color = {0.6, 0.0, 0.6, 1}
                table.insert(effects, chainEffect)
                local bonusDamage = finalDamage * bonusMultiplier
                newTarget:takeDamage(bonusDamage, nil, effects, "necrotic_chain", nil, "ability")
              end
            end
          end
        end
      end
      table.insert(effects, flame)
    end
    if sounds.ability.necroticBreath then
      sounds.ability.necroticBreath:play()
    end
  end,
  enhancedEffect = function(char, enemy, effects, sounds, summonedEntities, enemies, damageNumbers)
      if not enemy then
      return
    end
    -- Enhanced version triggered when 3+ Necrotic Breath links are present.
    -- In this version the cone is widened, more flames are emitted, and bonus chaining occurs.
    local closestEnemy, minDist = nil, math.huge
    for _, e in ipairs(enemies) do
      local dx = e.x - char.x
      local dy = e.y - char.y
      local dist = math.sqrt(dx * dx + dy * dy)
      if dist < minDist then
        minDist = dist
        closestEnemy = e
      end
    end
    if not closestEnemy then return end
    local dx = closestEnemy.x - char.x
    local dy = closestEnemy.y - char.y
    local angle = math.atan2(dy, dx)
    local ability = char.abilities["Necrotic Breath"]
    local rank = ability.rank or 1
    local baseDamage = char.damage * (1 + 0.15 * rank)
    local finalDamage = Abilities.calculateFinalDamage(char, baseDamage)
    -- Enhanced: widen the cone and increase the number of flames.
    local coneAngle = math.rad(180)   -- Widened cone
    local numFlames = 16             -- Double the number of flames
    -- Also increase the range of each flame for a more dramatic effect.
    local flameRange = 150 * 0.5
    local flameSpeed = 250
    for i = 1, numFlames do
      local angleOffset = ((i - 0.5) / numFlames - 0.5) * coneAngle
      local flameAngle = angle + angleOffset
      local flameDirX = math.cos(flameAngle)
      local flameDirY = math.sin(flameAngle)
      local flame = Effects.new("necrotic_flame", char.x, char.y,
                                  char.x + flameDirX * flameRange,
                                  char.y + flameDirY * flameRange)
      flame.damage = finalDamage
      flame.speed = flameSpeed
      flame.scale = 1.2  -- Slightly larger visuals
      flame.impactRadius = 15
      flame.enemies = enemies
      flame.effects = effects
      flame.onHitEnemy = function(targetEnemy)
        targetEnemy:takeDamage(finalDamage, flame.damageNumbers, effects, "Grimreaper", nil, "ability")
        -- In the enhanced version, increase the poison proc chance to 30%
        if math.random() < 0.30 then
          Abilities.applyPoison(targetEnemy, rank, effects, sounds, char)
        end
        -- Additionally, if the player has the Chain-of-the-Reaper talent,
        -- chain to every enemy in range (no limit) with a higher bonus damage.
        local chainedTargets = {}
        if char.owner and char.owner.chainOfTheReaperRank and char.owner.chainOfTheReaperRank > 0 then
          local talentRank = char.owner.chainOfTheReaperRank
          local procChance = (talentRank == 1 and 0.25) or (talentRank == 2 and 0.35) or 0.45
          if math.random() < procChance then
            local bonusMultiplier = (talentRank == 1 and 0.20) or (talentRank == 2 and 0.25) or 0.30
            -- Instead of a fixed number of bolts, chain to every enemy in range.
            for _, potentialTarget in ipairs(enemies) do
              if potentialTarget and not potentialTarget.isDead and potentialTarget ~= targetEnemy then
                local ddx = potentialTarget.x - targetEnemy.x
                local ddy = potentialTarget.y - targetEnemy.y
                if (ddx * ddx + ddy * ddy) <= (150 * 150) then  -- 150px chain range
                  if not chainedTargets[potentialTarget] then
                    chainedTargets[potentialTarget] = true
                    local chainEffect = Effects.new("necrotic_chain", targetEnemy.x, targetEnemy.y, potentialTarget.x, potentialTarget.y)
                    chainEffect.color = {0.6, 0.0, 0.6, 1}
                    table.insert(effects, chainEffect)
                    local bonusDamage = finalDamage * bonusMultiplier
                    potentialTarget:takeDamage(bonusDamage, nil, effects, "necrotic_chain", nil, "ability")
                  end
                end
              end
            end
          end
        end
      end
      table.insert(effects, flame)
    end
    if sounds.ability.necroticBreath then
      sounds.ability.necroticBreath:play()
    end
  end,
},




  ["Unholy Ground"] = {
    name = "Unholy Ground",
    linkType = "unholygroundlink",
    attackType = "projectile",
    rank = 1,
    maxRank = 3,
    class = { name = "Grimreaper", color = {0.678, 0.047, 0.910} },
    description = "Creates unholy ground that damages enemies and summons goyles upon their death. (Triggered via its link.)",
    cooldown = 0,
    cooldownTimer = 0,
    effect = function(char, enemy, effects, sounds, summonedEntities, enemies, damageNumbers, proj)
        if not enemy then
      return
    end
      local ability = char.abilities["Unholy Ground"]
      local rank = ability.rank or 1
      if rank == 1 then ability.cooldown = 15 elseif rank == 2 then ability.cooldown = 12 elseif rank == 3 then ability.cooldown = 10 end
      if ability.cooldownTimer > 0 then return end
      ability.cooldownTimer = ability.cooldown
      local baseDamage = 10 + rank * 3 
      local finalDamage = Abilities.calculateFinalDamage(char, baseDamage)
      if char.owner.goylesAwakeningRank and char.owner.goylesAwakeningRank >= 2 then
        finalDamage = finalDamage * 1.2
      end
      local radius = (rank >= 2) and 120 or 100
      local poolDuration = (rank == 1 and 10) or (rank == 2 and 12) or 15
      local ground = Effects.new("unholy_ground", enemy.x, enemy.y, nil, nil, char.owner, nil, effects, radius, finalDamage, enemies, damageNumbers)
      ground.stacks = 1
      ground.duration = poolDuration
      ground.lifetime = poolDuration
      ground.baseDuration = poolDuration
      ground.damagePerSecond = finalDamage
      ground.owner = char
      ground.talentHolder = char.owner
      table.insert(effects, ground)
      if sounds.ability.corrosiveCloud then
        sounds.ability.corrosiveCloud:play()
      end
    end,
  },

  ["Necrotic Burst"] = {
    name = "Necrotic Burst",
    linkType = "necroticburstlink",
    attackType = "projectile",  -- ← changed
    rank = 1,
    maxRank = 3,
    class = { name = "Grimreaper", color = {0.678, 0.047, 0.910} },
    description = "Releases necrotic tendrils that poison nearby enemies. (Triggered via its link.)",
    effect = function(char, enemy, effects, sounds, summonedEntities, enemies, damageNumbers)
        if not enemy then return end
        local ability = char.abilities["Necrotic Burst"]
        local rank = ability.rank or 1

        -- no more cooldown check

        local dischargeRange = 300
        local validEnemies = {}
        for _, e in ipairs(enemies) do
            if not e.isDead then
                local dx, dy = e.x - char.x, e.y - char.y
                if dx*dx + dy*dy <= dischargeRange*dischargeRange then
                    table.insert(validEnemies, e)
                end
            end
        end
        if #validEnemies == 0 then return end
  
        table.sort(validEnemies, function(a, b)
            local da = (a.x - char.x)^2 + (a.y - char.y)^2
            local db = (b.x - char.x)^2 + (b.y - char.y)^2
            return da < db
        end)
        -- scale tendril count by rank
        local numTendrils = 2 * rank + 2
        numTendrils = math.min(numTendrils, #validEnemies)
        for i = 1, numTendrils do
            local tgt = validEnemies[i]
            local tendril = Effects.new("necrotic_tendrils", char.x, char.y, tgt.x, tgt.y)
            tendril.rank = rank
            tendril.target = tgt
            tendril.onHitEnemy = function(target)
                Abilities.applyPoison(target, rank, effects, sounds, char)
            end
            table.insert(effects, tendril)
        end
    end,
    enhancedEffect = function(char, _, effects, sounds, summonedEntities, enemies, damageNumbers)
    local ability = char.abilities["Necrotic Burst"]
    local rank    = ability.rank or 1
    local baseDamage = char.damage * (1 + 0.10 * rank)
    local finalDamage = Abilities.calculateFinalDamage(char, baseDamage)
    local range = 300
    local numDirs = 8
    local chainRange = 100
    for i = 0, numDirs-1 do
      local angle = (i / numDirs) * 2 * math.pi
      local tx = char.x + math.cos(angle) * range
      local ty = char.y + math.sin(angle) * range
      local tendril = Effects.new("necrotic_tendrils", char.x, char.y, tx, ty)
      tendril.damage = finalDamage
      tendril.onHitEnemy = function(target)
        -- single extra chain
        local next = Abilities.findNewTarget(target, enemies)
        if next and (target.x-next.x)^2+(target.y-next.y)^2 <= chainRange^2 then
          next:takeDamage(finalDamage * 0.75, damageNumbers, effects, "necrotic_chain", nil, "ability")
          table.insert(effects, Effects.new("necrotic_chain", target.x, target.y, next.x, next.y))
        end
      end
      table.insert(effects, tendril)
    end
    if sounds.ability.necroticBreath then sounds.ability.necroticBreath:play() end
  end,
  },
  

  ["Infernal Rain"] = {
    name = "Infernal Rain",
    linkType = "infernalrainlink",
    attackType = "projectile",
    rank = 1,
    maxRank = 3,
    class = { name = "Emberfiend", color = {1, 0, 0} },
    description = "Calls down a swarm of meteors on a target area. (Triggered via its link.)",
    effect = function(char, enemy, effects, sounds, summonedEntities, enemies, proj)
        if not enemy then
      return
    end
      local ability = char.abilities["Infernal Rain"]
      local rank = ability.rank or 1
      local baseDamagePerMeteor = char.damage * (1 + 0.2 * rank)
      local finalDamagePerMeteor = Abilities.calculateFinalDamage(char, baseDamagePerMeteor)
      local numberOfMeteors = 5 + rank
      local meteorInterval = 0.5
      local meteorRadius = 50
      local areaX, areaY = enemy.x, enemy.y
      local infernalRain = Effects.new("meteor_swarm", areaX, areaY, nil, nil, nil, nil, effects, meteorRadius, finalDamagePerMeteor, enemies, DamageNumber)
      infernalRain.damagePerMeteor = finalDamagePerMeteor
      infernalRain.impactRadius = meteorRadius
      infernalRain.numberOfMeteors = numberOfMeteors
      infernalRain.meteorInterval = meteorInterval
      infernalRain.enemies = enemies
      table.insert(effects, infernalRain)
      if sounds.ability.infernalRain then sounds.ability.infernalRain:play() end
    end,
  },

  ["Flame Burst"] = {
    name = "Flame Burst",
    linkType = "flameburstlink",
    attackType = "projectile",  -- ← changed
    rank = 1,
    maxRank = 3,
    class = { name = "Emberfiend", color = {1, 0, 0} },
    description = "Bursts flames, igniting all enemies hit. (Triggered via its link.)",
    effect = function(char, enemy, effects, sounds, summonedEntities, enemies, damageNumbers)
        if not enemy then return end
        local ability = char.abilities["Flame Burst"]
        local rank = ability.rank or 1

        -- no more cooldown check

        local baseDamage = char.damage * (1 + 0.10 * rank)
        local finalDamage = Abilities.calculateFinalDamage(char, baseDamage)
        -- scale waveCount by rank
        local waveCount = 3 * rank + 2
        local angleStep = (2 * math.pi) / waveCount

        for i = 0, waveCount - 1 do
            local angle = i * angleStep
            local projRange = 300
            local tx = char.x + math.cos(angle) * projRange
            local ty = char.y + math.sin(angle) * projRange
            local wave = Effects.new("flame_wave", char.x, char.y, tx, ty)
            wave.damage   = finalDamage
            wave.scale    = 4.0
            wave.enemies  = enemies
            wave.effects  = effects
            wave.source   = char
            table.insert(effects, wave)
        end
    end,
    enhancedEffect = function(char, _, effects, sounds, summonedEntities, enemies, damageNumbers)
    local ability = char.abilities["Flame Burst"]
    local rank    = ability.rank or 1
    local baseDamage = char.damage * (1 + 0.10 * rank)
    local finalDamage = Abilities.calculateFinalDamage(char, baseDamage)
    local circleDuration = 5
    local orbitRadius = 100 + 20 * rank
    -- spawn a circling shield of flame orbs
    local circle = Effects.new("flame_circle", char.x, char.y, nil, nil, char, nil, effects, orbitRadius, finalDamage, enemies, damageNumbers, circleDuration)
    circle.rank = rank
    table.insert(effects, circle)
    -- after duration, it will auto‐explode outward (see effects.lua)
    if sounds.ability.flameBurst then sounds.ability.flameBurst:play() end
  end,
  },


  ["Blizzard"] = {
    name = "Blizzard",
    linkType = "blizzardlink",
    attackType = "projectile",
    rank = 1,
    maxRank = 3,
    class = { name = "Stormlich", color = {239/255, 158/255, 78/255, 1} },
    description = "Creates a blizzard that damages enemies and shatters dead foes into frozen shards. (Triggered via its link.)",
    cooldown = 0,
    cooldownTimer = 0,
    effect = function(char, enemy, effects, sounds, summonedEntities, enemies, damageNumbers, proj)
        if not enemy then
      return
    end
      local Projectiles = require("projectile")
      local Projectile = Projectiles.Projectile
      local ability = char.abilities["Blizzard"]
      local rank = ability.rank or 1
      local baseDamage = 15 + (rank * 8)
      local finalDamage = Abilities.calculateFinalDamage(char, baseDamage)
      local proj = Projectile.new(char.x, char.y, enemy.x, enemy.y, char.type, finalDamage, char.abilities, char)
      proj.onHit = function(self, target)
        if target then
          local frostField = Effects.new("frost_field", target.x, target.y, nil, nil, nil, target, effects, 50, nil, enemies)
          frostField.duration = 5
          frostField.blizzardOwner = char
          table.insert(effects, frostField)
          local blizzardData = {
            x = target.x,
            y = target.y,
            radius = 50,
            duration = 5,
            timer = 0,
            baseDamageTick = 25,
            effects = effects,
            enemies = enemies,
            damageNumbers = damageNumbers,
            blizzardOwner = char,
          }
          char.activeBlizzards = char.activeBlizzards or {}
          table.insert(char.activeBlizzards, blizzardData)
        end
      end
      if sounds.ability.blizzard then sounds.ability.blizzard:play() end
      table.insert(char.owner.projectiles, proj)
    end,
  },

  ["Storm Arc"] = {
    name = "Storm Arc",
    linkType = "stormarclink",
    attackType = "projectile",
    rank = 1,
    maxRank = 5,
    class = { name = "Stormlich", color = {1, 0.780, 0} },
    description = "Unleashes a chaining bolt of lightning. (Triggered via its link.)",
    effect = function(char, enemy, effects, sounds, summonedEntities, enemies, damageNumbers)
        if not enemy then
      return
    end
        local Projectiles = require("projectile")
        local Projectile = Projectiles.Projectile
        local ability = char.abilities["Storm Arc"]
        local rank = ability.rank or 1
        local baseMinDamage = 2 + (rank - 1) * 4      
        local baseMaxDamage = 25 + (rank - 1) * 8   
        local finalMinDamage = Abilities.calculateFinalDamage(char, baseMinDamage)
        local finalMaxDamage = Abilities.calculateFinalDamage(char, baseMaxDamage)
        local randDamage = math.random() * (finalMaxDamage - finalMinDamage) + finalMinDamage
        local projRange = ability.attackRange or 210
        local proj = Projectile.new(char.x, char.y, enemy.x, enemy.y, char.type, randDamage, char.abilities, char, projRange, effects, enemies, sounds, summonedEntities, damageNumbers)
        proj.type = "storm_arc"
        proj.color = {1, 0.85, 0.2}  -- normal color
        proj.endColor = {1, 1, 0.9}
        proj.segments = 6
        proj.onHit = function(self, target)
            if target then
               target:takeDamage(randDamage, damageNumbers, effects, "storm_arc", nil, "ability")
                -- Chain the lightning to additional enemies.
                Abilities.stormarc(target, randDamage, enemies, effects, damageNumbers, char)
                table.insert(effects, Effects.new("storm_arc", self.x, self.y, target.x, target.y))
                if sounds.ability.storm_arc then sounds.ability.storm_arc:play() end
                -- Talent: Flaming Arc applies Ignite.
                if char.owner and char.owner.flamingArcRank and char.owner.flamingArcRank > 0 then
                    local talentRank = char.owner.flamingArcRank
                    local igniteChance = (talentRank == 1 and 0.10) or (talentRank == 2 and 0.20) or 0.30
                    if math.random() < igniteChance then
                        local customDuration = 3
                        local customDPS = randDamage * 0.1
                        local igniteEffect = { name = "Ignite", duration = customDuration, damagePerSecond = customDPS, timer = 0 }
                        target:applyStatusEffect(igniteEffect)
                        table.insert(effects, Effects.new("ignite", target.x, target.y, nil, nil, char, target))
                        if sounds.statusEffect and sounds.statusEffect.Ignite then
                            sounds.statusEffect.Ignite:play()
                        end
                    end
                end
            end
        end
        table.insert(char.owner.projectiles, proj)
    end,
    enhancedEffect = function(char, enemy, effects, sounds, summonedEntities, enemies, damageNumbers)
          if not enemy then
      return
    end
        local Projectiles = require("projectile")
        local Projectile = Projectiles.Projectile
        local ability = char.abilities["Storm Arc"]
        local rank = ability.rank or 1
        local baseMinDamage = 2 + (rank - 1) * 4      
        local baseMaxDamage = 25 + (rank - 1) * 8   
        local finalMinDamage = Abilities.calculateFinalDamage(char, baseMinDamage)
        local finalMaxDamage = Abilities.calculateFinalDamage(char, baseMaxDamage)
        local randDamage = math.random() * (finalMaxDamage - finalMinDamage) + finalMinDamage
        local projRange = ability.attackRange or 210
        local proj = Projectile.new(char.x, char.y, enemy.x, enemy.y, char.type, randDamage, char.abilities, char, projRange, effects, enemies, sounds, summonedEntities, damageNumbers)
        proj.type = "storm_arc"
        proj.color = {0.5, 0.8, 1}    -- light blue for enhanced version
        proj.endColor = {0.8, 0.9, 1}
        proj.segments = 30           -- enhanced chain: 30 segments (visual indicator)
        proj.onHit = function(self, target)
            if target then
                -- Chain with no limit by passing math.huge as maxChains (if your stormarc function supports it)
                Abilities.stormarc(target, randDamage, enemies, effects, damageNumbers, char, math.huge)
                table.insert(effects, Effects.new("storm_arc_enhanced", self.x, self.y, target.x, target.y))
                if sounds.ability.storm_arc then sounds.ability.storm_arc:play() end
                -- Talent: Flaming Arc applies Ignite in enhanced version as well.
                if char.owner and char.owner.flamingArcRank and char.owner.flamingArcRank > 0 then
                    local talentRank = char.owner.flamingArcRank
                    local igniteChance = (talentRank == 1 and 0.10) or (talentRank == 2 and 0.20) or 0.30
                    if math.random() < igniteChance then
                        local customDuration = 3
                        local customDPS = randDamage * 0.1
                        local igniteEffect = { name = "Ignite", duration = customDuration, damagePerSecond = customDPS, timer = 0 }
                        target:applyStatusEffect(igniteEffect)
                        table.insert(effects, Effects.new("ignite", target.x, target.y, nil, nil, char, target))
                        if sounds.statusEffect and sounds.statusEffect.Ignite then
                            sounds.statusEffect.Ignite:play()
                        end
                    end
                end
            end
        end
        table.insert(char.owner.projectiles, proj)
    end,
},



["Discharge"] = {
    name = "Discharge",
    linkType = "dischargelink",
    attackType = "instant",
    rank = 1,
    maxRank = 3,
    class = { name = "Stormlich", color = {1, 0.780, 0} },
    description = "Sends out multiple rapid lightning jolts from the caster. Kills trigger additional jolts.", -- Updated description
    effect = function(char, enemy, effects, sounds, summonedEntities, enemies, damageNumbers)
        -- Always cast from the character's position
        local castOriginX, castOriginY = char.x, char.y

        -- The 'enemy' parameter (passed during recursion) is no longer used for origin,
        -- but we keep it in the signature for consistency with the recursive call.

        local ability = char.abilities["Discharge"]
        if not ability then return end -- Safety check
        local rank = ability.rank or 1

        local baseDamage = 10 + (rank * 2)
        local finalDamage = Abilities.calculateFinalDamage(char, baseDamage)
        local numJolts = rank + 2
        local dischargeRange = 100 -- Range from the cast origin (the character)

        local validEnemies = {}
        for _, e in ipairs(enemies) do
            if not e.isDead then
                local dx, dy = e.x - castOriginX, e.y - castOriginY -- Check range from origin (character)
                if dx*dx + dy*dy <= dischargeRange*dischargeRange then
                    table.insert(validEnemies, e)
                end
            end
        end

        -- Limit jolts to available valid enemies
        numJolts = math.min(numJolts, #validEnemies)

        for i = 1, numJolts do
            if #validEnemies == 0 then break end
            local idx = math.random(#validEnemies)
            local tgt = validEnemies[idx]

            -- Spawn the visual jolt from the origin (character) to the target
            local jolt = Effects.new("discharge_jolt", castOriginX, castOriginY, tgt.x, tgt.y)
            table.insert(effects, jolt)

            -- Apply immediate damage
            local hpBefore = tgt.health -- Store health before damage
            tgt:takeDamage(finalDamage, damageNumbers, effects, "Stormlich", nil, "ability")
            if sounds.ability.lightningFork then sounds.ability.lightningFork:play() end

            -- Check if this jolt killed the target
            if tgt.isDead and hpBefore > 0 then
                -- RECURSIVE CALL: Cast again. It will use char.x, char.y as origin again.
                -- Pass the killed target 'tgt' as the 'enemy' parameter, though it's not used for origin.
                ability.effect(char, tgt, effects, sounds, summonedEntities, enemies, damageNumbers)
            end

            -- Remove that target from subsequent random picks for *this* cast instance
            table.remove(validEnemies, idx)
        end
    end,
    enhancedEffect = function(char, _, effects, sounds, summonedEntities, enemies, damageNumbers)
      -- Enhanced effect should also originate from the character
      local ability = char.abilities["Discharge"]
      local rank    = ability.rank or 1
      local baseDamage = 10 + (rank * 3)
      local finalDamage = Abilities.calculateFinalDamage(char, baseDamage)
      local numJolts   = rank + 3
      local range      = 120 -- Range from the character

      local valid = {}
      for _, e in ipairs(enemies) do
        if not e.isDead and (e.x-char.x)^2+(e.y-char.y)^2 <= range*range then
          table.insert(valid, e)
        end
      end

      numJolts = math.min(numJolts, #valid)
      for i=1, numJolts do
        if #valid==0 then break end
        local idx = math.random(#valid)
        local tgt = table.remove(valid, idx)

        -- Spawn jolt from character to target
        local jolt = Effects.new("discharge_jolt", char.x, char.y, tgt.x, tgt.y)
        jolt.damage = finalDamage
        jolt.onHitEnemy = function(hit)
          local chained=0
          for _, e2 in ipairs(enemies) do
            if chained<3 and not e2.isDead and e2~=hit then
              local dx,dy = e2.x-hit.x, e2.y-hit.y
              -- Chain range check from the hit enemy
              if dx*dx+dy*dy <= range*range then
                e2:takeDamage(finalDamage*0.8, damageNumbers, effects, "discharge_chain", nil, "ability")
                table.insert(effects, Effects.new("jolt_chain", hit.x, hit.y, e2.x, e2.y))
                chained = chained + 1
              end
            end
          end
        end
        table.insert(effects, jolt)
        tgt:takeDamage(finalDamage, damageNumbers, effects, "Stormlich", nil, "ability")
      end
      if sounds.ability.lightningFork then sounds.ability.lightningFork:play() end
    end,
},



  ["Zephyr Shield"] = {
    name = "Zephyr Shield",
    linkType = "zephyrshieldlink",
    attackType = "projectile",
    rank = 1,
    maxRank = 3,
    class = { name = "Stormlich", color = {1, 0.780, 0} },
    description = "Throws a returning shield that damages enemies along its path. (Triggered via its link.)",
    effect = function(char, enemy, effects, sounds, summonedEntities, enemies, proj)
        if not enemy then
      return
    end
      local ability = char.abilities["Zephyr Shield"]
      local rank = ability.rank or 1
      local baseDamage = char.damage * (1 + 0.2 * rank)
      local finalDamage = Abilities.calculateFinalDamage(char, baseDamage)
      local damageMultiplier = 1.0 + (0.1 * rank)
      local duration = 3 + rank
      local speed = 300 + (rank * 20)
      Abilities.throwShieldBoomerang(char, damageMultiplier, duration, effects, enemies)
      if sounds.ability.zephyrShield then sounds.ability.zephyrShield:play() end
    end,
  },
    
["ExplodingMadness"] = {
    name = "ExplodingMadness",
    attackType = "instant",
    procChance = 1.0,
    rank = 1,
    maxRank = 1,
    description = "Deals no damage, but applies Madness to enemies in a small radius.",

    -- 2) The 'effect' function does the actual logic:
    effect = function(char, x, y, radius, enemies, effects, sounds, damageNumbers)
        if not enemy then
      return
    end
        -- Safety checks for nil
        enemies = enemies or {}
        effects = effects or {}
        damageNumbers = damageNumbers or {}

        -- A) Apply Madness to enemies within radius
        for _, enemy in ipairs(enemies) do
            if not enemy.isDead then
                local dx = enemy.x - x
                local dy = enemy.y - y
                if (dx * dx + dy * dy) <= (radius * radius) then
                    Abilities.applyMadness(enemy, 5, effects, sounds)
                end
            end
        end

        -- B) Spawn the visual effect
        table.insert(effects, Effects.new(
            "explodingmadness",
            x,
            y,
            nil, nil,         -- targetX, targetY
            nil, nil,         -- ownerType, attachedTo
            effects,
            radius,
            nil,              -- damagePerMeteor
            enemies,
            damageNumbers
        ))

        -- C) Optionally play a sound
        if sounds and sounds.ability and sounds.ability.explodingmadness then
            sounds.ability.explodingmadness:play()
        end
    end,
},

  
     


   

      ["Summon Goyle"] = {
    name = "Summon Goyle",
    procChance = 0.25,
    attackType = "projectile",
    rank = 1,
    maxRank = 3,
    class = { name = "Grimreaper", color = {155/255, 76/255, 99/255, 1} },
    description = "Attacks have a chance to summon a goyle for a limited time.",
    effect = function(char, enemy, effects, sounds, summonedEntities, enemies, damageNumbers, proj)
        if not enemy then
      return
    end
      local ability = char.abilities["Summon Goyle"]
      local rank = ability.rank or 1
      local duration = 12 + (rank - 1) * 2    -- 12, 14, 16 seconds
      local speed = 60 + (rank - 1) * 10        -- 60, 70, 80 px/s
      local damageMultiplier = (rank == 1 and .02) or (rank == 2 and .04) or .06
      summonedEntities = summonedEntities or {}
      Abilities.summongoyle(char, duration, speed, damageMultiplier, char.owner.summonedEntities, enemies, effects, damageNumbers, false)
      if math.random() < 0.5 then
        if sounds.ability.summon_goyle then sounds.ability.summon_goyle:play() end
      else
        if sounds.ability.summon_goyle2 then sounds.ability.summon_goyle2:play() end
      end
      table.insert(effects, Effects.new("summon_goyle", char.x, char.y))
    end,
  },
    
   ["Summon BloodSlime"] = {
    name = "Summon BloodSlime",
    procChance = 1,
    attackType = "projectile",
    rank = 1,
    maxRank = 1,
    class = nil,
    description = "Attacks have a chance to summon a Blood Slime for a limited time.",
    effect = function(char, enemy, effects, sounds, summonedEntities, enemies, damageNumbers, proj)
        if not enemy then
      return
    end
        local ability = char.abilities["Summon BloodSlime"]
        local duration = 10 + ability.rank * 2
        local speed = 60 + (ability.rank - 1) * 24
        local damageMultiplier = 5 + (ability.rank * 0.1)

        summonedEntities = summonedEntities or {}

        -- Pass 'summonedEntities' directly without accessing 'char.owner'
        Abilities.summonbloodslime(char, duration, speed, damageMultiplier, summonedEntities, enemies, effects, damageNumbers)

        if math.random() < 0.5 then
            if sounds.ability.summon_bloodslime then
                sounds.ability.summon_bloodslime:play()
            end
        else
            if sounds.ability.summon_bloodslime2 then
                sounds.ability.summon_bloodslime2:play()
            end
        end

        table.insert(effects, Effects.new("summon_bloodslime", char.x, char.y))
    end
},


    

["Molten Orbs"] = {
  name = "Molten Orbs",
  attackType = "projectile",
  rank = 1,
  maxRank = 5,
  class = { name = "Emberfiend", color = {173/255, 64/255, 48/255, 1} },
  description = "Shoots a fireball that explodes on impact with a chance to ignite enemies. (Triggers only when its link expires.)",
  linkType = "moltenorbslink",
  effect = function(char, enemy, effects, sounds, summonedEntities, enemies, damageNumbers)
    
      if not enemy then
      return
    end
    
    local Projectiles = require("projectile")
    local Projectile = Projectiles.Projectile

    local ability = char.abilities["Molten Orbs"]
    local rank = ability.rank or 1
    local baseDamage = char.damage * (1 + 0.15 * rank)
    local finalDamage = Abilities.calculateFinalDamage(char, baseDamage)
    local currentProcChance = 0.05 + 0.01 * (rank - 1)
    local projRange = ability.attackRange or 210

    local proj = Projectile.new(char.x, char.y, enemy.x, enemy.y,
                                 char.type, finalDamage, char.abilities, char,
                                 projRange, effects, enemies, sounds, summonedEntities, damageNumbers)
    proj.color = {1, 0.3, 0}  -- Fiery orange
    proj.image = nil  -- Using vector graphics
    proj.fireTrail = {}
    proj.fireTrailFrequency = 0.05
    proj.fireTrailTimer = 0

    local originalUpdate = Projectile.update
    proj.update = function(self, dt, effects, enemies, damageNumbers)
      if originalUpdate then originalUpdate(self, dt, effects, enemies, damageNumbers) end
      self.fireTrailTimer = self.fireTrailTimer + dt
      if self.fireTrailTimer >= self.fireTrailFrequency then
        self.fireTrailTimer = 0
        table.insert(self.fireTrail, {
          x = self.x - self.velX * dt,
          y = self.y - self.velY * dt,
          lifetime = 1.0,
          size = math.random(2, 4),
          alpha = 1,
          color = {1, 0.5, 0, 1},
        })
      end
      for i = #self.fireTrail, 1, -1 do
        local particle = self.fireTrail[i]
        particle.lifetime = particle.lifetime - dt
        if particle.lifetime <= 0 then
          table.remove(self.fireTrail, i)
        else
          particle.alpha = particle.lifetime / 1.0
        end
      end
    end

    local originalDraw = Projectile.draw
    proj.draw = function(self)
      for _, particle in ipairs(self.fireTrail) do
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], particle.alpha)
        love.graphics.circle("fill", self.x, self.y, particle.size)
      end
      love.graphics.setColor(self.color)
      love.graphics.circle("fill", self.x, self.y, 10)
      love.graphics.setColor(1, 1, 1, 1)
    end

    proj.onHit = function(self, target)
      if not target then return end
      local explosionRadius = 75 + (5 * rank)
      Abilities.areaDamage(target.x, target.y, explosionRadius, finalDamage, enemies, damageNumbers, effects, "Emberfiend")
      table.insert(effects, Effects.new("explosion", target.x, target.y))
      if sounds.ability.explosion then sounds.ability.explosion:play() end

      if math.random() < currentProcChance then
        for _, enemy in ipairs(enemies) do
          local dx = enemy.x - target.x
          local dy = enemy.y - target.y
          if math.sqrt(dx * dx + dy * dy) <= explosionRadius then
            local bonus = char.owner.statusEffectDamageBonus or 0
            enemy:applyStatusEffect({
                name = "Ignite",
                duration = 5,
                damagePerSecond = 15 + bonus,
                timer = 0,
            })
            table.insert(effects, Effects.new("ignite", enemy.x, enemy.y, nil, nil, char, enemy))
            if sounds and sounds.statusEffect and sounds.statusEffect.Ignite then
              sounds.statusEffect.Ignite:play()
            end
          end
        end
      end

      -- Ember Summoning talent integration:
      if char.owner and char.owner.emberSummoningRank and char.owner.emberSummoningRank > 0 then
        local talentRank = char.owner.emberSummoningRank
        local summonChance = (talentRank == 1 and 0.15) or (talentRank == 2 and 0.25) or 0.35
        if math.random() < summonChance then
          local numMinions = talentRank
          local minionDuration = 5
          local minionSpeed = 60 + (talentRank - 1) * 20
          local damageMultiplier = 1 + (talentRank - 1) * 0.5
          for i = 1, numMinions do
            Abilities.summonfireling(char, minionDuration, minionSpeed, damageMultiplier,
                                      char.owner.summonedEntities, enemies, effects, damageNumbers)
          end
        end
      end
    end

    table.insert(char.owner.projectiles, proj)
  end,
  enhancedEffect = function(char, enemy, effects, sounds, summonedEntities, enemies, damageNumbers)
    
      if not enemy then
      return
    end
    -- Enhanced Molten Orbs: The projectile is more visually striking, has an increased explosion radius,
    -- and spawns a ring of mini-explosions around the impact.
    local Projectiles = require("projectile")
    local Projectile = Projectiles.Projectile

    local ability = char.abilities["Molten Orbs"]
    local rank = ability.rank or 1
    local baseDamage = char.damage * (1 + 0.15 * rank)
    local finalDamage = Abilities.calculateFinalDamage(char, baseDamage)
    local currentProcChance = 0.05 + 0.01 * (rank - 1)
    local projRange = ability.attackRange or 210

    local proj = Projectile.new(char.x, char.y, enemy.x, enemy.y,
                                 char.type, finalDamage, char.abilities, char,
                                 projRange, effects, enemies, sounds, summonedEntities, damageNumbers)
    proj.type = "molten_orbs_enhanced"
    proj.color = {1, 0.7, 0.3}    -- Brighter, more intense orange
    proj.endColor = {1, 0.9, 0.6}
    proj.segments = 10
    proj.onHit = function(self, target)
      if not target then return end
      local explosionRadius = 75 + (10 * rank)  -- Increased explosion radius for enhanced version
      Abilities.areaDamage(target.x, target.y, explosionRadius, finalDamage, enemies, damageNumbers, effects, "Emberfiend")
      table.insert(effects, Effects.new("explosion", target.x, target.y))
      if sounds.ability.explosion then sounds.ability.explosion:play() end

      -- Enhanced secondary effect: spawn a ring of mini-explosions that chain to every enemy in range.
      local numMiniExplosions = 6 + rank
      local miniRadius = explosionRadius * 0.5
      for i = 1, numMiniExplosions do
        local angle = (i / numMiniExplosions) * 2 * math.pi
        local miniX = target.x + math.cos(angle) * miniRadius
        local miniY = target.y + math.sin(angle) * miniRadius
        local miniExplosion = Effects.new("explosion", miniX, miniY, nil, nil, "Emberfiend", nil, effects, explosionRadius * 0.5, finalDamage * 0.5, enemies, damageNumbers)
        table.insert(effects, miniExplosion)
      end

      -- Ember Summoning talent integration remains similar:
      if char.owner and char.owner.emberSummoningRank and char.owner.emberSummoningRank > 0 then
        local talentRank = char.owner.emberSummoningRank
        local summonChance = (talentRank == 1 and 0.15) or (talentRank == 2 and 0.25) or 0.35
        if math.random() < summonChance then
          local numMinions = talentRank
          local minionDuration = 5
          local minionSpeed = 60 + (talentRank - 1) * 20
          local damageMultiplier = 1 + (talentRank - 1) * 0.5
          for i = 1, numMinions do
            Abilities.summonfireling(char, minionDuration, minionSpeed, damageMultiplier,
                                      char.owner.summonedEntities, enemies, effects, damageNumbers)
          end
        end
      end
    end
    table.insert(char.owner.projectiles, proj)
  end,
},


["Infernal Sacrifice"] = {
    name = "Infernal Sacrifice",
    linkType = "infernalsacrificelink",     -- ensure your Link:onExpire will catch this
    attackType = "passive",
    rank = 1,
    maxRank = 1,
    class = { name = "Emberfiend", color = {1, 0.3, 0} },
    description = "Summons a Fire Elemental to fight for you.",
    effect = function(char, enemy, effects, sounds, summonedEntities, enemies, damageNumbers)
        local ability = char.abilities["Infernal Sacrifice"]
        -- scale parameters by rank if you want, or hard‑code defaults
        local duration         = 15 + (ability.rank - 1) * 5
        local speed            = 100 + (ability.rank - 1) * 20
        local damageMultiplier = 1.0
        -- summonElemental(owner, duration, speed, damageMultiplier, summonedEntities, enemies, effects, damageNumbers)
        Abilities.summonElemental(char, duration, speed, damageMultiplier,
                                  char.owner.summonedEntities, enemies, effects, damageNumbers)
    end,
},


  
  ------------------------------------------------------------------------------
  -- Hellblast
  ------------------------------------------------------------------------------
  ["Hellblast"] = {
    name = "Hellblast",
    procChance = 1.0,  -- Always procs on autoattack explosion
    chainChances = {0.75, 0.50, 0.25, 0.10, 0.05},
    attackType = "projectile",
    rank = 1,
    maxRank = 3,
    class = { name = "Emberfiend", color = {1, 0, 0} },
    description = "Autoattacks now explode, dealing AOE damage. Enemy kills can trigger additional blasts.",
    effect = function(char, enemy, effects, sounds, summonedEntities, enemies, damageNumbers, proj)
        if not enemy then
      return
    end
      if not proj then return end
      local ability = char.abilities["Hellblast"]
      if not ability then return end
      local rank = ability.rank
      local baseDamage = 10 + (5 * rank)  -- 15, 20, or 25
      local finalDamage = Abilities.calculateFinalDamage(char, baseDamage)
      proj.damage = proj.damage + (5 * rank)

      local function triggerHellblastChain(index, previousDamage)
        if index > #ability.chainChances then return end
        local chance = ability.chainChances[index]
        if math.random() < chance then
          local damageReductionFactor = 1 - (0.2 * index)
          local chainDamage = math.max(previousDamage * damageReductionFactor, finalDamage * 0.1)
          local newTarget = Abilities.findNewTarget(char, enemies)
          if newTarget then
            Abilities.applyEffects(proj, newTarget, char, enemies, effects, sounds, summonedEntities, damageNumbers, "projectile")
          end
        end
      end

      local originalOnHit = proj.onHit
      proj.onHit = function(self, target)
        if originalOnHit then originalOnHit(self, target) end
        if target then
          local kills = Abilities.areaDamage(target.x, target.y, 60 + (10 * rank), finalDamage, enemies, damageNumbers, effects, "Emberfiend")
          table.insert(effects, Effects.new("hellblast", target.x, target.y, target.x, target.y))
          if sounds.ability.pyroclasticsurge then sounds.ability.pyroclasticsurge:play() end
          if kills > 0 and not self.hasTriggeredChaining then
            self.hasTriggeredChaining = true
            triggerHellblastChain(1, finalDamage)
          end
        end
      end

      proj.color = {1, 0.5, 0}
    end,
  },

  
  


  ["Elemental Rain"] = {
    name = "Elemental Rain",
    procChance = 1.0,
    attackType = "projectile",
    rank = 1,
    maxRank = 1,
    class = { name = "Emberfiend", color = {1, 0, 0} },
    description = "Upon death, the elemental throws out 3 fire bombs randomly.",
    effect = function(char, enemy, effects, sounds, summonedEntities, enemies, damageNumbers)
          if not enemy then
      return
    end
        local numBombs = 3
        for i = 1, numBombs do
            local angle = math.random() * 2 * math.pi
            local travelDistance = math.random(80, 120)  -- random travel distance
            local targetX = char.x + travelDistance * math.cos(angle)
            local targetY = char.y + travelDistance * math.sin(angle)
            -- Create a fire bomb effect (similar to your Fire Bomb ability)
            local firebomb = Effects.new("firebomb_projectile", char.x, char.y, targetX, targetY, "Fire Elemental", nil, effects, 0, 0, enemies, damageNumbers)
            firebomb.damage = char.damage * 1.2
            firebomb.lifetime = 0.8
            firebomb.g = 200
            local dx = targetX - char.x
            local dy = targetY - char.y
            firebomb.vx = dx / firebomb.lifetime
            firebomb.vy = (dy / firebomb.lifetime) - 0.5 * firebomb.g * firebomb.lifetime
            firebomb.onImpact = function(self, impactX, impactY)
                local explosion = Effects.new("explosion", impactX, impactY, nil, nil, "Fire Elemental", nil, effects, 50, 0, enemies, damageNumbers)
                explosion.damage = firebomb.damage
                table.insert(effects, explosion)
                local burnPatch = Effects.new("burn_patch", impactX, impactY, nil, nil, "Fire Elemental", nil, effects, 50, 0, enemies, damageNumbers, 5)
                local talentMultiplier = 1
                if char.emberLegacy and char.emberLegacy >= 1 then
                    talentMultiplier = 2
                end
                burnPatch.damagePerTick = 5 * talentMultiplier
                burnPatch.tickInterval = 0.5
                table.insert(effects, burnPatch)
            end
           if char.owner and char.owner.projectiles then
    table.insert(char.owner.projectiles, firebomb)
end

        end
        if sounds.ability.infernalRain then
           
            sounds.ability.infernalRain:play()
        end
     
    end,
},


["Chest Ignition"] = {
    name = "Chest Ignition",
    attackType = "instant",  -- triggered immediately when the trap is activated
    procChance = 1.0,
    rank = 1,
    maxRank = 1,
    class = nil,  -- not associated with any character class
    description = "A cursed chest trap that bursts into flames—hitting nearby enemies and igniting the player for 15 seconds.",
    effect = function(player, effects, enemies, sounds)
        local baseDamage = (player.damage or 10) * (1 + 0.2 * 1)  -- fixed since rank=1
        local finalDamage = Abilities.calculateFinalDamage(player, baseDamage)
        local waveCount = 10
        local angleStep = (2 * math.pi) / waveCount

        for i = 0, waveCount - 1 do
            local angle = i * angleStep
            local projRange = 300  -- adjust range as needed
            local targetX = player.x + math.cos(angle) * projRange
            local targetY = player.y + math.sin(angle) * projRange

            local wave = Effects.new("flame_wave", player.x, player.y, targetX, targetY)
            wave.damage = finalDamage
            wave.scale = 4.0
            wave.enemies = enemies
            wave.effects = effects
            table.insert(effects, wave)
        end

        -- Apply Ignite to the player:
        player:applyStatusEffect(nil, "Ignite", 15, 3)

        if sounds and sounds.statusEffect and sounds.statusEffect.Ignite then
            sounds.statusEffect.Ignite:play()
        end
    end,
},

  

 
 ["Fire Bomb"] = {
    name = "Fire Bomb",
    procChance = 1.0,
    attackType = "projectile",
    rank = 1,
    maxRank = 1,
    class = { name = "Elemental", color = {1, 0.5, 0} },
    description = "Tosses a fire bomb that arcs from the summon’s position. On impact it explodes and leaves behind a burning patch.",
    cooldown = 4,
    cooldownTimer = 0,
    effect = function(elemental, enemy, effects, sounds, summonedEntities, enemies, damageNumbers, proj)
        if not enemy then
      return
    end
        -- Determine starting position
        local startX, startY = elemental.x, elemental.y
        local targetX, targetY

        if enemy then
            local dx = enemy.x - elemental.x
            local dy = enemy.y - elemental.y
            local distance = math.sqrt(dx * dx + dy * dy)
            local minDistance = 100  -- Minimum travel distance for the projectile

            if distance < minDistance then
                local angle = math.atan2(dy, dx)
                targetX = elemental.x + minDistance * math.cos(angle)
                targetY = elemental.y + minDistance * math.sin(angle)
            else
                targetX, targetY = enemy.x, enemy.y
            end
        else
            targetX, targetY = elemental.x + 100, elemental.y
        end

        -- Create the fire bomb projectile effect.
        local firebomb = Effects.new("firebomb_projectile", startX, startY, targetX, targetY, "Fire Elemental", nil, effects, 0, 0, enemies, damageNumbers)
        firebomb.damage = elemental.damage * 1.2

        firebomb.lifetime = 0.8  -- Flight time (seconds)
        firebomb.g = 200         -- Gravity constant for the arc

        local dx = targetX - startX
        local dy = targetY - startY
        firebomb.vx = dx / firebomb.lifetime
        firebomb.vy = (dy / firebomb.lifetime) - 0.5 * firebomb.g * firebomb.lifetime

        -- Define what happens on impact:
        firebomb.onImpact = function(self, impactX, impactY)
            -- Create explosion effect.
            local explosion = Effects.new("explosion", impactX, impactY, nil, nil, "Fire Elemental", nil, effects, 50, 0, enemies, damageNumbers)
            explosion.damage = firebomb.damage
            table.insert(effects, explosion)
            
            -- Create a burning patch that lasts 5 seconds and deals 5 damage per tick.
            local burnPatch = Effects.new("burn_patch", impactX, impactY, nil, nil, "Fire Elemental", nil, effects, 50, 0, enemies, damageNumbers, 5)
            -- Use Ember's Legacy talent: if emberLegacy is at least 1, double the damage per tick.
            local talentMultiplier = 1
            if elemental.emberLegacy and elemental.emberLegacy >= 1 then
                talentMultiplier = 2
            end
            burnPatch.damagePerTick = 5 * talentMultiplier
            burnPatch.tickInterval = 0.5  -- Tick every 0.5 seconds
            table.insert(effects, burnPatch)
        end

        table.insert(elemental.projectiles, firebomb)
    end,
},





}



Abilities.generalUpgrades = {
 ["Increase Attack Speed"] = {
    name = "Increase Attack Speed",
    class = "General",
    description = "Boost your attack speed by 10%. Can be upgraded up to 5 times.",
    effect = function(characters)
        characters.attackSpeedUpgradeCount = characters.attackSpeedUpgradeCount or 0
        if characters.attackSpeedUpgradeCount < 5 then
            characters.baseAttackSpeed = characters.baseAttackSpeed * 1.15  -- update base attack speed
            characters.attackSpeedUpgradeCount = characters.attackSpeedUpgradeCount + 1
            -- Immediately update the derived attack speed stat:
            if characters.attackSpeed then
                characters.attackSpeed = characters.baseAttackSpeed
            end
        end
    end
},


 ["Increase Attack Damage"] = {
    name = "Increase Attack Damage",
    class = "General",
    description = "Enhance your attack damage by 10%. Can be upgraded up to 5 times.",
    effect = function(characters)
        characters.attackDamageUpgradeCount = characters.attackDamageUpgradeCount or 0
        if characters.attackDamageUpgradeCount < 5 then
            characters.baseDamage = characters.baseDamage * 1.15  -- update base damage
            characters.attackDamageUpgradeCount = characters.attackDamageUpgradeCount + 1
            -- Immediately update the derived damage stat:
            if characters.damage then
                characters.damage = (characters.baseDamage + (characters.equipmentFlatDamage or 0)) * (characters.owner and characters.owner.attackDamageMultiplier or 1)
            end
        end
    end
},


  ["Increase Attack Range"] = {
    name = "Increase Attack Range",
    class = "General",
    description = "Extend your attack range by 10%. Can be upgraded up to 5 times.",
    effect = function(characters)
        characters.attackRangeUpgradeCount = characters.attackRangeUpgradeCount or 0
        if characters.attackRangeUpgradeCount < 5 then
            characters.baseAttackRange = characters.baseAttackRange * 1.15  -- update base attack range
            characters.attackRangeUpgradeCount = characters.attackRangeUpgradeCount + 1
            -- Immediately update the derived attack range stat:
            if characters.attackRange then
                characters.attackRange = characters.baseAttackRange
            end
        end
    end
},

["Increase Max Health"] = {
    name = "Increase Max Health",
    class = "General",
    description = "Increase your maximum health by 10% per upgrade (up to 5 times).",
    maxRank = 5,
    effect = function(player)
        player.maxHealthUpgradeCount = player.maxHealthUpgradeCount or 0
        if player.maxHealthUpgradeCount < 5 then
            local factor = 1.15
            player.baseTeamMaxHealth = math.floor(player.baseTeamMaxHealth * factor)
            player.teamMaxHealth = math.floor(player.teamMaxHealth * factor)
            player._teamHealth = math.floor(player._teamHealth * factor)
            player.maxHealthUpgradeCount = player.maxHealthUpgradeCount + 1
            print("[DEBUG] Max Health upgraded: baseTeamMaxHealth=" .. player.baseTeamMaxHealth)
        end
    end
},

  ["Increase Pull Range"] = {
    name = "Increase Pull Range",
    class = "General",
    description = "Increase your pull range by 10%. Can be upgraded up to 5 times.",
    effect = function(characters)
        characters.pullRangeUpgradeCount = characters.pullRangeUpgradeCount or 0
        if characters.pullRangeUpgradeCount < 5 then
            -- 'characters' here is the player object, which contains a table 'characters'
            for _, char in pairs(characters.characters) do
                char.pullRange = char.pullRange * 1.15
                char.basePullRange = char.basePullRange * 1.15
            end
            characters.pullRangeUpgradeCount = characters.pullRangeUpgradeCount + 1
        end
    end
  },
  
["Experience Heal"] = {
    name = "Experience Heal",
    class = "General",  
    description = "When you gain experience, there's a 20% chance to heal by 1 (Each upgrade increases this chance by 20%.)",
    maxRank = 5,
    rank = 0,
    effect = function(characters)
        characters.experienceHealChance = (characters.experienceHealChance or 0) + 0.2
    end
},






}

function Abilities.spawnFrozenShards(x, y, owner, enemies, effects, damageNumbers)
    local numShards = 12
    local shardSpeed = 200   -- adjust as needed
    local shardDamage = 10   -- light damage value
    local shardRadius = 20   -- medium area
    for i = 1, numShards do
         local angle = (2 * math.pi / numShards) * i
         local shard = Effects.new("frozen_shard", x, y,
             x + math.cos(angle) * shardRadius,
             y + math.sin(angle) * shardRadius,
             owner.type, owner, effects, shardRadius, shardDamage, enemies, damageNumbers)
         shard.speed = shardSpeed
         shard.piercing = true
         shard.onHitEnemy = function(target)
             -- Do the shard’s normal damage
             target:takeDamage(shardDamage, damageNumbers, effects, "FrozenShard", nil, "piercing")
    
             -- 50% chance to spawn a bonus Blizzard (base frost_field effect)
             if math.random() < 0.1 then  
                 -- Spawn the visual effect (frost_field)
                 local bonusField = Effects.new("frost_field", target.x, target.y, nil, nil, owner, nil, effects, 50, nil, enemies, damageNumbers)
                 bonusField.duration = 5  -- Fixed duration for the bonus effect
                 bonusField.blizzardOwner = owner
                 table.insert(effects, bonusField)
        
                 -- Also create a simple BlizzardData object that applies damage over time
               local bonusBlizzardData = {
  x = target.x,
  y = target.y,
  radius = 50,           -- Fixed radius
  duration = 5,          -- Fixed duration (seconds)
  timer = 0,
  damagePerSecond = 20,  -- Fixed DPS (adjust as desired)
  effects = effects,
  enemies = enemies,
  damageNumbers = damageNumbers,
  blizzardOwner = owner,
  isBonus = true,  -- Mark this blizzard as a bonus
}
owner.activeBlizzards = owner.activeBlizzards or {}
table.insert(owner.activeBlizzards, bonusBlizzardData)

        
                 if _G.sounds and _G.sounds.ability and _G.sounds.ability.blizzard then
                     _G.sounds.ability.blizzard:play()
                 end
             end
         end  -- Close the anonymous function
         table.insert(effects, shard)
    end  -- Close the for-loop
end






-- Area Stun function
function Abilities.areaStun(x, y, radius, damage, stunDuration, enemies, effects, damageNumbers)
    for _, enemy in ipairs(enemies) do
        local dx = enemy.x - x
        local dy = enemy.y - y
        if dx * dx + dy * dy <= radius * radius then
            -- Apply damage
            enemy:takeDamage(damage, damageNumbers, effects, "stun", nil, "ability")

            -- Apply status effect for stun or freeze
            local stunEffect = {
                name = "Frozen", -- Or "Stun" if applicable
                duration = stunDuration
            }
            enemy:applyStatusEffect(stunEffect)

            -- Add visual effect for stun/freeze
            table.insert(effects, Effects.new("freeze", enemy.x, enemy.y))
        end
    end
end








function Abilities.upgradeAbility(character, abilityName)
    character.abilities = character.abilities or {}
    local abilityDef = Abilities.abilityList[abilityName]
    if not abilityDef then return end
    local ability = character.abilities[abilityName]
    if not ability then
        character.abilities[abilityName] = {
            rank = 1,
            procChance = abilityDef.procChance,
            attackType = abilityDef.attackType,
            class = abilityDef.class,
            description = abilityDef.description,
           linkType = abilityDef.linkType,  -- Add this line to copy the linkType
            effect = abilityDef.effect,
            cooldown = abilityDef.cooldown or 0,
            cooldownTimer = abilityDef.cooldownTimer or 0,
            maxRank = abilityDef.maxRank,
            damageBonus = abilityDef.damageBonus or 0,
            chainChances = abilityDef.chainChances,
        }
    elseif ability.rank < abilityDef.maxRank then
        ability.rank = ability.rank + 1
        if ability.procChance then
            ability.procChance = math.min(ability.procChance * 1.5, 0.9)
       
        end
        ability.effect = abilityDef.effect
        ability.damageBonus = (ability.damageBonus or 0) + (abilityDef.damageBonus or 0)
       if abilityDef.cooldown then
            local baseCooldown = abilityDef.cooldown
            ability.cooldown = baseCooldown * scalingFactor(ability.rank, 0.1)
        end
        if abilityDef.cooldownTimer then
            ability.cooldownTimer = abilityDef.cooldownTimer
        end
        if abilityDef.chainChances then
            ability.chainChances = abilityDef.chainChances
        end
    end
end


function Abilities.upgradeGeneralAbility(character, upgradeName)
    local upgrade = Abilities.generalUpgrades[upgradeName]
    if not upgrade then return end
    character.generalUpgradeCounts = character.generalUpgradeCounts or {}
    local count = character.generalUpgradeCounts[upgradeName] or 0
    if count < 5 then
        upgrade.effect(character)
        character.generalUpgradeCounts[upgradeName] = count + 1
    end
end

function Abilities.summonbloodslime(owner, duration, speed, damageMultiplier, summonedEntities, enemies, effects, damageNumbers)
    if not summonedEntities and not owner.summonedEntities then
        owner.summonedEntities = {}
    end

    summonedEntities = summonedEntities or owner.summonedEntities
    -- Ensure summonedEntities is a table
    summonedEntities = summonedEntities or {}

    local bloodslime = {
        type = "BloodSlime",
        x = owner.x,
        y = owner.y,
        vx = 0,
        vy = 0,
        damage = 50,

        health = 50,
        duration = duration,
        speed = speed * 2,      -- Adjust speed as needed
        attackRange = 35,
        attackCooldown = 1,
        attackTimer = 0,
        isDead = false,
        lifeTimer = 0,
        collisionRadius = 15,
        dashMinRange = 25,         -- Minimum distance to trigger dash
        dashMaxRange = 50,         -- Maximum distance to trigger dash
        dashSpeed = speed * 5,     -- Speed during dash
        isDashing = false,
        dashCooldown = 5,          -- Dash cooldown
        dashTimer = 0,             -- Timer to track dash cooldown
        dashDuration = 0.2,        -- Duration of the dash
        dashTimeElapsed = 0,       -- Time elapsed during the dash
        enemyPrevPos = {},         -- To store enemy's previous position
        image = bloodslimeImage,    -- Load the bloodslime image
        lastDirection = "left",     -- Default last direction
        angleToTarget = 0,          -- To track angle towards target
        damageNumbers = damageNumbers,
        enemies = enemies,
        effects = effects,
        hasExploded = false,            -- New Flag to Track Explosion

        animation = {
            currentFrame = 1,
            frameTimer = 0,
            frameDuration = 0.2,  -- Time per frame
            totalFrames = #bloodslimeFrames
        }
    }

    -- Define the calculateSeparation method (fixed implementation)
    bloodslime.calculateSeparation = function(self, enemies)
        local desiredSeparation = 30  -- Minimum distance to maintain from other enemies
        local steerX, steerY = 0, 0
        local count = 0

        for _, enemy in ipairs(enemies) do
            -- Avoid separating from self or dead enemies
            if enemy ~= self and not enemy.isDead then
                local dx = self.x - enemy.x
                local dy = self.y - enemy.y
                local distance = math.sqrt(dx * dx + dy * dy)

                if distance > 0 and distance < desiredSeparation then
                    -- Calculate the vector away from the neighbor
                    steerX = steerX + (dx / distance)
                    steerY = steerY + (dy / distance)
                    count = count + 1
                end
            end
        end

        if count > 0 then
            -- Average the separation vectors
            steerX = steerX / count
            steerY = steerY / count

            -- Normalize the vector
            local magnitude = math.sqrt(steerX * steerX + steerY * steerY)
            if magnitude > 0 then
                steerX = steerX / magnitude
                steerY = steerY / magnitude

                -- Scale the steering force
                local maxSeparationForce = 100  -- Adjust this value as needed
                steerX = steerX * maxSeparationForce
                steerY = steerY * maxSeparationForce
            else
                steerX, steerY = 0, 0
            end
        else
            steerX, steerY = 0, 0
        end

        return steerX, steerY
    end

    -- Update function for the bloodslime
    bloodslime.update = function(self, dt, enemies, effects, summonedEntities)
        -- Update lifetime timer
        self.lifeTimer = self.lifeTimer + dt

        -- Trigger Explosion at (duration - 0.5) seconds
         if not self.hasExploded and self.lifeTimer >= self.duration then
          

            -- Define explosion parameters
            local explosionRadius = 100  -- Adjust based on game balance
            local explosionDamage = 20  -- Adjust based on game balance

            -- **Trigger Area Damage Explosion**
            -- Assuming `Effects.new` handles "explosion" type appropriately
            local bloodExplosion = Effects.new(
                "bloodexplosion",
                self.x,
                self.y,
                nil,               -- targetX not needed for explosion
                nil,               -- targetY not needed for explosion
                nil,               -- ownerType if applicable
                nil,               -- attachedTo if applicable
                effects,           -- effects list to add any sub-effects
                explosionRadius,   -- impactRadius
                explosionDamage,   -- damagePerMeteor (assuming it's reused)
                enemies,           -- enemies list
                damageNumbers,     -- damageNumbers
                0.3                -- duration as per your effect's default
            )
            table.insert(effects, bloodExplosion)

        

            -- Mark as Exploded to Prevent Multiple Explosions
            self.hasExploded = true
        end

        -- Check for Death after Explosion
        if self.lifeTimer >= self.duration then
            self.isDead = true
            return
        end

        -- [Rest of the existing update logic]
        -- Update attack and dash timers
        self.attackTimer = self.attackTimer + dt
        self.dashTimer = self.dashTimer + dt

        -- Update animation frame
        self.animation.frameTimer = self.animation.frameTimer + dt
        if self.animation.frameTimer >= self.animation.frameDuration then
            self.animation.frameTimer = 0
            self.animation.currentFrame = self.animation.currentFrame % self.animation.totalFrames + 1
        end

        -- Store previous position before movement
        self.prevX = self.x
        self.prevY = self.y

        -- Find the closest enemy
        local closestEnemy, closestDist = nil, math.huge
        for _, enemy in ipairs(enemies) do
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < closestDist then
                closestEnemy = enemy
                closestDist = dist
            end
        end

        -- Desired velocity
        local desiredVx, desiredVy = 0, 0

        if closestEnemy then
            -- Calculate the angle to the enemy
            self.angleToTarget = math.atan2(closestEnemy.y - self.y, closestEnemy.x - self.x)

            local dx = closestEnemy.x - self.x
            local dy = closestEnemy.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist <= self.attackRange then
                -- Attack the enemy if cooldown has elapsed
                if self.attackTimer >= self.attackCooldown then
                    -- Ensure the enemy is still alive and valid
                    if not closestEnemy.isDead then
                        closestEnemy:takeDamage(
                            self.damage,         -- damage
                            damageNumbers,       -- damageNumbers
                            effects,             -- effects
                            "blood_explosion",        -- sourceType
                            nil,                 -- sourceCharacter (optional)
                            "ability"            -- attackType
                        )

                        self.attackTimer = 0  -- Reset attack cooldown

                        -- Add the bite effect
                        table.insert(effects, Effects.new("bloodslimebite", closestEnemy.x, closestEnemy.y))
                    end
                end
            elseif dist >= self.dashMinRange and dist <= self.dashMaxRange and self.dashTimer >= self.dashCooldown then
                -- Start dashing
                self.isDashing = true
                self.dashTimeElapsed = 0

                -- Set velocity towards enemy at dash speed
                local dashDirX = dx / dist
                local dashDirY = dy / dist
                self.vx = dashDirX * self.dashSpeed
                self.vy = dashDirY * self.dashSpeed
            else
                -- Move towards the enemy at normal speed
                desiredVx = (dx / dist) * self.speed
                desiredVy = (dy / dist) * self.speed
            end
        else
            -- No enemy found, stop moving
            desiredVx = 0
            desiredVy = 0
        end

       
      -- Apply Separation Steering using the new helper:
local sepX, sepY = Abilities.calculateSeparation(self, summonedEntities, 40, 50)
local separationInfluence = 0.1  -- Adjust influence as needed
desiredVx = desiredVx + sepX * separationInfluence
desiredVy = desiredVy + sepY * separationInfluence


        -- Set the velocity directly for immediate responsiveness
       local smoothing = 5  -- Adjust this value as needed (higher = snappier, lower = smoother)
self.vx = self.vx + (desiredVx - self.vx) * dt * smoothing
self.vy = self.vy + (desiredVy - self.vy) * dt * smoothing


        -- Update position
        self.x = self.x + self.vx * dt
        self.y = self.y + self.vy * dt

        -- Reset dashing state if necessary
        if self.isDashing then
            self.dashTimeElapsed = self.dashTimeElapsed + dt
            if self.dashTimeElapsed >= self.dashDuration then
                self.isDashing = false
                self.dashTimer = 0  -- Reset dash cooldown
            end
        end
    end

    -- Draw function for the bloodslime with rotation based on angleToTarget
    bloodslime.draw = function(self)
        if not self.isDead then
            if not self.image then
               
                return
            end
            local scaleX = 2  -- Adjust size scaling as needed
            local scaleY = 2
            local quad = bloodslimeFrames[self.animation.currentFrame]

            -- Flip horizontally based on whether the bloodslime should face right or left
            if math.cos(self.angleToTarget) > 0 then
                scaleX = -scaleX  -- Flip horizontally if facing right
            end

            love.graphics.draw(
                self.image, quad, self.x, self.y, 0, scaleX, scaleY,
                8, 8 -- Offset by half frame width/height (16x16 sprite)
            )
           
        end
    end

    -- Insert the bloodslime into the summoned entities
    table.insert(summonedEntities, bloodslime)
 
end



function Abilities.summongoyle(owner, duration, speed, damageMultiplier, summonedEntities, enemies, effects, damageNumbers)
  -- Ensure summonedEntities exists on the owner
  if not summonedEntities and not owner.summonedEntities then
    owner.summonedEntities = {}
  end
  summonedEntities = summonedEntities or owner.summonedEntities
  summonedEntities = summonedEntities or {}

  local goyle = {
    x = owner.x,
    y = owner.y,
    vx = 0,
    vy = 0,
    damage = 15,  -- reduced damage from 25 to 15
    health = 50,
    duration = duration,
    speed = speed * 2,
    attackRange = 35,
    attackCooldown = 1,
    attackTimer = 0,
    isDead = false,
    lifeTimer = 0,
    collisionRadius = 15,
    dashMinRange = 25,
    dashMaxRange = 50,
    dashSpeed = speed * 5,
    isDashing = false,
    dashCooldown = 5,
    dashTimer = 0,
    dashDuration = 0.2,
    dashTimeElapsed = 0,
    enemyPrevPos = {},
    image = goyleImage,
    lastDirection = "right",
    angleToTarget = 0,
    damageNumbers = damageNumbers,
    enemies = enemies,
    effects = effects,
    animation = {
      currentFrame = 1,
      frameTimer = 0,
      frameDuration = 0.2,
      totalFrames = #goyleFrames
    },
    detectionRange = 150,        -- Reduced detection range
    followOffset = { x = 30, y = 20 },  -- Offset relative to owner so it's not directly on top
    wanderTarget = nil,          -- Will store a target position when wandering
    wanderWaitTimer = 0,         -- Timer to wait at a wander target
    wanderWaitDuration = 1,      -- Wait 1 second at a wander target before picking a new one
    wanderRadius = 40            -- Wander target is chosen within 40px of the follow target
  }

  -- Calculate separation steering to avoid clustering with other summons.
  goyle.calculateSeparation = function(self, entities)
    local desiredSeparation = 30
    local steerX, steerY = 0, 0
    local count = 0
    for _, other in ipairs(entities) do
      if other ~= self then
        local dx = self.x - other.x
        local dy = self.y - other.y
        local distance = math.sqrt(dx * dx + dy * dy)
        if distance > 0 and distance < desiredSeparation then
          steerX = steerX + (dx / distance)
          steerY = steerY + (dy / distance)
          count = count + 1
        end
      end
    end
    if count > 0 then
      steerX = steerX / count
      steerY = steerY / count
      local magnitude = math.sqrt(steerX * steerX + steerY * steerY)
      if magnitude > 0 then
        steerX = (steerX / magnitude) * 100
        steerY = (steerY / magnitude) * 100
      else
        steerX, steerY = 0, 0
      end
    else
      steerX, steerY = 0, 0
    end
    return steerX, steerY
  end

  -- Update function for the goyle.
  goyle.update = function(self, dt, enemies, effects, summonedEntities)
    -- Update lifetime
    self.lifeTimer = self.lifeTimer + dt
    if self.lifeTimer >= self.duration then
      self.isDead = true
      return
    end

    self.attackTimer = self.attackTimer + dt
    self.dashTimer = self.dashTimer + dt

    -- Update animation timer
    self.animation.frameTimer = self.animation.frameTimer + dt
    if self.animation.frameTimer >= self.animation.frameDuration then
      self.animation.frameTimer = 0
      self.animation.currentFrame = (self.animation.currentFrame % self.animation.totalFrames) + 1
    end

    -- Store previous position
    self.prevX = self.x
    self.prevY = self.y

    -- Look for the closest enemy
    local closestEnemy, closestDist = nil, math.huge
    for _, enemy in ipairs(enemies) do
      local dx = enemy.x - self.x
      local dy = enemy.y - self.y
      local dist = math.sqrt(dx * dx + dy * dy)
      if dist < closestDist then
        closestEnemy = enemy
        closestDist = dist
      end
    end

    local desiredVx, desiredVy = 0, 0

    if closestEnemy and closestDist <= self.detectionRange then
      -- If an enemy is detected within range, pursue it.
      self.angleToTarget = math.atan2(closestEnemy.y - self.y, closestEnemy.x - self.x)
      local dx = closestEnemy.x - self.x
      local dy = closestEnemy.y - self.y
      local dist = math.sqrt(dx * dx + dy * dy)
      if dist <= self.attackRange then
        if self.attackTimer >= self.attackCooldown then
          if not closestEnemy.isDead then
            closestEnemy:takeDamage(self.damage, damageNumbers, effects, "Grimreaper", nil, "ability")
            self.attackTimer = 0
            table.insert(effects, Effects.new("goylebite", closestEnemy.x, closestEnemy.y))
          end
        end
      elseif dist >= self.dashMinRange and dist <= self.dashMaxRange and self.dashTimer >= self.dashCooldown then
        self.isDashing = true
        self.dashTimeElapsed = 0
        local dashDirX = dx / dist
        local dashDirY = dy / dist
        self.vx = dashDirX * self.dashSpeed
        self.vy = dashDirY * self.dashSpeed
      else
        desiredVx = (dx / dist) * self.speed
        desiredVy = (dy / dist) * self.speed
      end
      -- When an enemy is detected, clear any wander target.
      self.wanderTarget = nil
      self.wanderWaitTimer = 0
    else
      -- No enemy detected: follow the owner at an offset and wander around.
      if owner then
        local followTargetX = owner.x + self.followOffset.x
        local followTargetY = owner.y + self.followOffset.y

        if not self.wanderTarget then
          -- Pick a random wander target around the follow target.
          local randomOffsetX = math.random(-self.wanderRadius, self.wanderRadius)
          local randomOffsetY = math.random(-self.wanderRadius, self.wanderRadius)
          self.wanderTarget = { x = followTargetX + randomOffsetX, y = followTargetY + randomOffsetY }
        end

        local dx = self.wanderTarget.x - self.x
        local dy = self.wanderTarget.y - self.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist > 5 then
          desiredVx = (dx / dist) * self.speed
          desiredVy = (dy / dist) * self.speed
        else
          -- Arrived at wander target; wait for a moment.
          self.wanderWaitTimer = self.wanderWaitTimer + dt
          if self.wanderWaitTimer >= self.wanderWaitDuration then
            self.wanderTarget = nil  -- Pick a new target after waiting.
            self.wanderWaitTimer = 0
          end
          -- When waiting, slow down movement.
          desiredVx = 0
          desiredVy = 0
        end
      end
    end

    -- Apply separation steering.
    local sepX, sepY = self.calculateSeparation(self, summonedEntities)
    local separationInfluence = 0.1
    desiredVx = desiredVx + sepX * separationInfluence
    desiredVy = desiredVy + sepY * separationInfluence

    local smoothing = 5
    self.vx = self.vx + (desiredVx - self.vx) * dt * smoothing
    self.vy = self.vy + (desiredVy - self.vy) * dt * smoothing

    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    if math.abs(self.vx) > 0.1 or math.abs(self.vy) > 0.1 then
      self.angleToTarget = math.atan2(self.vy, self.vx)
    end

    if self.isDashing then
      self.dashTimeElapsed = self.dashTimeElapsed + dt
      if self.dashTimeElapsed >= self.dashDuration then
        self.isDashing = false
        self.dashTimer = 0
      end
    end
  end

  -- Draw function for the goyle.
  goyle.draw = function(self)
    if not self.isDead then
      if not self.image then return end
      local scaleX = 2
      local scaleY = 2
      local quad = goyleFrames[self.animation.currentFrame]
      if self.vx < 0 then
        scaleX = -2
      else
        scaleX = 2
      end
      love.graphics.draw(self.image, quad, self.x, self.y, 0, scaleX, scaleY, 8, 8)
    end
  end

  table.insert(summonedEntities, goyle)
end





function Abilities.applyPoison(target, rank, effects, sounds, char)
    if not target.statusEffects then
        target.statusEffects = {}
    end

    local bonus = (char and char.owner and char.owner.statusEffectDamageBonus) or 0

    if target.statusEffects["Poison"] then
        local poison = target.statusEffects["Poison"]
        poison.stacks = (poison.stacks or 1) + 1
        poison.timer = 0  -- Reset timer on reapplication

        if poison.stacks >= 3 then
            -- When stacks hit 3, trigger a poison explosion.
            -- Damage is based on the poison DPS * 5 and scaled only by the general bonus.
            local explosionDamage = poison.damagePerSecond * 5 * bonus
            Abilities.areaDamage(target.x, target.y, 50, explosionDamage, _G.enemies, nil, effects)
            table.insert(effects, Effects.new("poison_explosion", target.x, target.y))
            target.statusEffects["Poison"] = nil  -- Remove poison after explosion
        end
        return
    end

    local baseDPS = Abilities.statusEffects.Poison.damagePerSecond or 3
    local scaledDPS = baseDPS + bonus  -- Use only the general bonus here

    local baseDuration = Abilities.statusEffects.Poison.duration or 15
    local statusBonus = (char and char.statusDurationBonus) or 0
    local duration = baseDuration + statusBonus

    local poisonEffect = {
        name = "Poison",
        duration = duration,
        damagePerSecond = scaledDPS,
        timer = 0,
        tickTimer = 0,
        stacks = 1
    }

    target:applyStatusEffect(poisonEffect)
    table.insert(effects, Effects.new("poison", target.x, target.y, nil, nil, char, target))

    if sounds and sounds.statusEffects and sounds.statusEffects.Poison then
        sounds.statusEffects.Poison:play()
    end
end








function Abilities.splashEffect(x, y, effects, color)
    local splash = Effects.new("splash", x, y, color)
    table.insert(effects, splash)
end



function Abilities.areaDamage(x, y, radius, damage, enemies, damageNumbers, effects, sourceType)
    local affectedEnemies = {}
    for _, enemy in ipairs(enemies) do
        if math.sqrt((enemy.x - x)^2 + (enemy.y - y)^2) <= radius then
            if not enemy.isDamaged then  -- Prevent duplicate damage
                table.insert(affectedEnemies, enemy)
                enemy.isDamaged = true  -- Mark enemy as damaged
            end
        end
    end

    local killCount = 0  -- Initialize kill count

    -- Apply damage and generate one damage number per enemy
    for _, enemy in ipairs(affectedEnemies) do
        enemy:takeDamage(damage, damageNumbers, effects, "explosion", nil, "aoe")

        if enemy.isDead then
            killCount = killCount + 1
        end
    end

    -- Reset the isDamaged flag after applying damage
    for _, enemy in ipairs(affectedEnemies) do
        enemy.isDamaged = false
    end

    return killCount  -- Return the number of enemies killed
end



-- Storm Arc function
function Abilities.stormarc(enemy, damage, enemies, effects, damageNumbers, char, maxChains)
    maxChains = maxChains or 5  -- default: 5 chains
    local chainRange = 125
    local chainedEnemies = { [enemy] = true }

    local function chain(currentEnemy, chainsLeft)
        if chainsLeft <= 0 then return end
        for _, nextEnemy in ipairs(enemies) do
            if not chainedEnemies[nextEnemy] then
                local dx = nextEnemy.x - currentEnemy.x
                local dy = nextEnemy.y - currentEnemy.y
                if dx * dx + dy * dy <= chainRange * chainRange then
                    nextEnemy:takeDamage(
                        damage,             -- damage
                        damageNumbers,      -- damageNumbers table
                        effects,            -- effects table
                        "storm_arc",        -- source type
                        nil,                -- source character (optional)
                        "aoe"               -- attack type
                    )
                    table.insert(effects, Effects.new("storm_arc", currentEnemy.x, currentEnemy.y, nextEnemy.x, nextEnemy.y))
                    chainedEnemies[nextEnemy] = true

                    chain(nextEnemy, chainsLeft - 1)
                    break  -- Only chain to one new enemy per recursion step
                end
            end
        end
    end

    chain(enemy, maxChains)
end

function Abilities.throwShieldBoomerang(owner, damageMultiplier, duration, effects, enemies, damageNumbers)
    duration = duration or 3 -- Default duration if not provided

    -- Find the closest enemy
    local closestEnemy = nil
    local minDist = math.huge
    for _, enemy in ipairs(enemies) do
        local dx = enemy.x - owner.x
        local dy = enemy.y - owner.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < minDist then
            closestEnemy = enemy
            minDist = dist
        end
    end

    if closestEnemy then
        local shield = {
            x = owner.x,
            y = owner.y,
            speed = 300,
            radius = 25,
            maxDistance = 150,
            traveledDistance = 0,
           
             damage = owner.damage * damageMultiplier,
            direction = math.atan2(closestEnemy.y - owner.y, closestEnemy.x - owner.x),
            returning = false,
            startX = owner.x,
            startY = owner.y,
            timer = 0,
            duration = duration,
            isDead = false,
            rotation = 0,
            rotationSpeed = 10,
            shieldGraphic = ZephyrShield:new(owner.x, owner.y, 0),
            particles = {} -- Initialize particles table
        }

        -- Update function for the shield
        shield.update = function(self, dt)
            self.timer = self.timer + dt
            if self.isDead then return end

            -- Update the procedural shield
            self.shieldGraphic.x = self.x
            self.shieldGraphic.y = self.y
            self.shieldGraphic.rotation = self.shieldGraphic.rotation + math.rad(self.rotationSpeed) * dt
            self.shieldGraphic:update(dt)

            -- Shield movement logic
            if not self.returning then
                local dx = math.cos(self.direction) * self.speed * dt
                local dy = math.sin(self.direction) * self.speed * dt
                self.x = self.x + dx
                self.y = self.y + dy
                self.traveledDistance = self.traveledDistance + math.sqrt(dx * dx + dy * dy)

                if self.traveledDistance >= self.maxDistance then
                    self.returning = true
                end
            else
                local dx = owner.x - self.x
                local dy = owner.y - self.y
                local distToOwner = math.sqrt(dx * dx + dy * dy)
                if distToOwner < self.speed * dt then
                    self.isDead = true
                else
                    self.x = self.x + (dx / distToOwner) * self.speed * dt
                    self.y = self.y + (dy / distToOwner) * self.speed * dt
                end
            end

            -- Damage enemies on contact
            for _, enemy in ipairs(enemies) do
                local dx = enemy.x - self.x
                local dy = enemy.y - self.y
                if math.sqrt(dx * dx + dy * dy) <= self.radius then
           enemy:takeDamage(
    self.damage,
    damageNumbers,
    effects,
    "Stormlich",  
    nil,
    "aoe"
)

                end
            end

            -- Particle generation (retain your existing particle code here)
            -- ...
            -- [Insert the particle generation and update code from your previous implementation]
        end

        -- Draw function for the shield
        shield.draw = function(self)
            -- Draw the procedural shield
            self.shieldGraphic:draw()

            -- Draw particles (retain your existing particle drawing code here)
            for _, p in ipairs(self.particles) do
                love.graphics.setColor(p.color)
                love.graphics.circle("fill", p.x, p.y, p.size)
            end
        end

        -- Add the shield to the effects list
        table.insert(effects, shield)
    end
end



function Abilities.applyEffects(proj, enemy, attacker, enemies, effects, sounds, summonedEntities, damageNumbers, attackType)
    -- Ensure 'effects' is always a table
    effects = effects or {}
    enemies = enemies or {}

    -- Determine the abilities based on attack type
    local abilities = attacker and attacker.abilities
    if not abilities then return end

    -- Iterate over abilities and apply relevant ones based on attack type
    for abilityName, ability in pairs(abilities) do
        if ability.attackType == attackType then
            -- Check if the ability is not on cooldown
            if ability.cooldownTimer <= 0 then
                -- Check proc chance
                if math.random() < ability.procChance then
                    if ability.effect then
                        -- Pass the projectile to the effect function
                        if attackType == "damageTaken" then
                            ability.effect(attacker, effects, enemies, sounds, nil, nil, damageNumbers, proj)
                        else
                            ability.effect(attacker, enemy, effects, sounds, summonedEntities, enemies, damageNumbers, proj)
                        end
                    end
                end

              
            end
        end
    end
end


function Abilities.applyUnholyGroundDamage(effect, enemies, summonedEntities, sounds, damageNumbers)
    local radius = effect.radius
    local damagePerSecond = effect.damagePerSecond
    local owner = effect.owner
   local rank = 1
    if owner.abilities and owner.abilities["Unholy Ground"] then
    rank = owner.abilities["Unholy Ground"].rank or 1
    end

    -- Get the talent rank for "Goyle’s Awakening"; if not present, default to 0.
    local goyleTalent = owner.goylesAwakeningRank or 0

    -- If talent rank is 2 or higher, boost damage by 20%.
    if goyleTalent >= 2 then
        damagePerSecond = damagePerSecond * 1.2
    end

    for _, enemy in ipairs(enemies) do
        if enemy and not enemy.isDead then
            local dx = enemy.x - effect.x
            local dy = enemy.y - effect.y
            if dx * dx + dy * dy <= radius * radius then
                local oldHP = enemy.health
                enemy:takeDamage(damagePerSecond, damageNumbers, effects, "Grimreaper", nil, "damageOverTime")
                
                if enemy.isDead and oldHP > 0 then
                    -- Only summon a Goyle if the talent is active (rank ≥ 1)
                    if goyleTalent >= 1 then
                        local overrideRank = 1  -- Use fixed parameters for talent-driven summoning
                        local duration = 10 + overrideRank * 2
                        local speed = 120 + (overrideRank - 1) * 24
                        local damageMultiplier = 5 + (overrideRank * 0.1)
                        
                        Abilities.summongoyle(owner, duration, speed, damageMultiplier, summonedEntities, enemies, effects, damageNumbers)
                        table.insert(effects, Effects.new("summon_goyle", owner.x, owner.y))
                    end
                end
            end
        end
    end
end


function Abilities.applyRegen(player, duration, fraction)
    local totalHealing = fraction * player.teamMaxHealth
    local regenHPS = totalHealing / duration
    for _, char in pairs(player.characters) do
        player:applyStatusEffect(char, "Regen", duration, regenHPS)
    end
end

function Abilities.applyBlizzardDamage(field, enemies, summonedEntities, sounds, damageNumbers)
  local radius = field.radius
  -- Use the base diminishing damage value
  local baseDamage = field.baseDamageTick or 0
  local owner = field.blizzardOwner

  -- Apply talent multiplier only for damage calculation
  local frozenFuryRank = (owner.owner and owner.owner.frozenFuryRank) or 0
  local effectiveDamage = baseDamage
  if frozenFuryRank >= 1 then
    effectiveDamage = baseDamage * 1.2
  end

  for _, enemy in ipairs(enemies) do
    if enemy and not enemy.isDead then
      local dx = enemy.x - field.x
      local dy = enemy.y - field.y
      if dx * dx + dy * dy <= radius * radius then
        enemy:takeDamage(effectiveDamage, damageNumbers, field.effects, "Stormlich", nil, "damageOverTime")
        if enemy.isDead then
          if frozenFuryRank >= 1 and not field.isBonus and math.random() < 0.4 then
            Abilities.spawnFrozenShards(field.x, field.y, owner, enemies, field.effects, damageNumbers)
            table.insert(field.effects, Effects.new("frozen_shard", owner.x, owner.y))
          end
        end
      end
    end
  end

  -- Decrease the base damage for the next tick (diminishing damage)
  field.baseDamageTick = baseDamage - 5

  -- If the base damage is now 0 or less, expire the effect immediately.
  if field.baseDamageTick <= 0 then
    field.duration = 0
  end
end



    


function Abilities.updateBlizzards(char, dt)
  if not char.activeBlizzards then return end
  for i = #char.activeBlizzards, 1, -1 do
    local field = char.activeBlizzards[i]
    field.timer = field.timer + dt
    if field.timer >= 1 then
      field.timer = field.timer - 1
      Abilities.applyBlizzardDamage(field, _G.enemies, nil, _G.sounds, nil)
    end
    field.duration = field.duration - dt
    if field.duration <= 0 then
      table.remove(char.activeBlizzards, i)
    end
  end
end





function Abilities.applyHaste(player, duration, speedBonus)
    if not player.statusEffects["Haste"] then
        player.statusEffects["Haste"] = {
            timer = 0,
            duration = duration,
            value = speedBonus
        }
        player.hasteBonus = player.hasteBonus + speedBonus  -- use a larger value (e.g., 25)
    else
        player.statusEffects["Haste"].timer = 0
        player.statusEffects["Haste"].duration = duration
    end
end




function Abilities.applyFury(player, duration, value)
    for _, char in pairs(player.characters) do
        player:applyStatusEffect(char, "Fury", duration, value)
    end
end


-- abilities.lua
function Abilities.sanguineFrenzyExplosion(x, y, radius, damage, effects, player, damageNumbers, enemies, sounds)
    -- Basic validations
    if not enemies then
        enemies = _G.enemies or {}
    end
    if not effects then
        effects = {}
    end
    if not damageNumbers then
        damageNumbers = {}
    end

    -- Apply Madness status effect to enemies within radius
    for _, enemy in ipairs(enemies) do
        local dx = enemy.x - x
        local dy = enemy.y - y
        if dx * dx + dy * dy <= radius * radius then
            Abilities.applyMadness(enemy, 5.0, effects, sounds)  -- duration of 5 seconds
        end
    end

    -- Optionally, spawn visual effect for explosion
    table.insert(effects, Effects.new("explodingmadness", x, y, nil, nil, nil, nil, effects, radius, nil, enemies, damageNumbers))

    if sounds and sounds.ability and sounds.ability.explodingmadness then
        sounds.ability.explodingmadness:play()
    end

    if player and player.hasSanguineFrenzy then
        if not player.sanguineFrenzyCooldown then
            player.sanguineFrenzyCooldown = true
            player.sanguineFrenzyCooldownTimer = 15
            
        end
    end

   
end


-- Actually apply the madness effect to a single enemy
function Abilities.applyMadness(enemy, duration, effects, sounds)
    if not enemy.statusEffects then enemy.statusEffects = {} end
    if enemy.statusEffects["Madness"] then return end

    enemy.statusEffects["Madness"] = {
        name = "Madness",
        duration = duration,
        timer = 0
    }

  table.insert(effects, Effects.new("madness", enemy.x, enemy.y, nil, nil, nil, enemy, effects))


    if sounds and sounds.statusEffects and sounds.statusEffects.Madness then
        sounds.statusEffects.Madness:play()
    end
end



function Abilities.calculateFinalDamage(char, baseDamage, rank)
    local classBonus = 0
    if char.type == "Grimreaper" then
        classBonus = (char.grimReaperAbilityBonus or 0)
    elseif char.type == "Emberfiend" then
        classBonus = (char.emberfiendAbilityBonus or 0)
    elseif char.type == "Stormlich" then
        classBonus = (char.stormlichAbilityBonus or 0)
    end

    -- Now simply add the flat bonus to the base damage.
    local finalDamage = baseDamage + classBonus
    return finalDamage
end



function Abilities.findNewTarget(char, enemies)
    local closestEnemy = nil
    local minDist = math.huge
    for _, enemy in ipairs(enemies) do
        if not enemy.isDead and enemy ~= char then
            local dx = enemy.x - char.x
            local dy = enemy.y - char.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < minDist then
                minDist = dist
                closestEnemy = enemy
            end
        end
    end
    return closestEnemy
end

function Abilities.summonPhantom(owner, duration, speed, damageMultiplier, summonedEntities, enemies, effects, damageNumbers)
    if not summonedEntities and not owner.summonedEntities then
        owner.summonedEntities = {}
    end
    summonedEntities = summonedEntities or owner.summonedEntities
    summonedEntities = summonedEntities or {}

    local phantom = {
        x = owner.x,
        y = owner.y,
        vx = 0,
        vy = 0,
        damage = 20,  -- adjust as needed
        health = 40,
        duration = duration,
        speed = speed * .5,
        attackRange = 35,
        attackCooldown = 1,
        attackTimer = 0,
        isDead = false,
        lifeTimer = 0,
        collisionRadius = 15,
        dashMinRange = 25,
        dashMaxRange = 50,
        dashSpeed = speed * 2,
        isDashing = false,
        dashCooldown = 5,
        dashTimer = 0,
        dashDuration = 0.5,
        dashTimeElapsed = 0,
        enemyPrevPos = {},
        image = phantomImage,  -- use phantom asset
        lastDirection = "left",
        angleToTarget = 0,
        damageNumbers = damageNumbers,
        enemies = enemies,
        effects = effects,
        animation = {
            currentFrame = 1,
            frameTimer = 0,
            frameDuration = 0.2,
            totalFrames = #phantomFrames
        }
    }

    phantom.calculateSeparation = function(self, enemies)
        local desiredSeparation = 30
        local steerX, steerY = 0, 0
        local count = 0
        for _, enemy in ipairs(enemies) do
            if enemy ~= self and not enemy.isDead then
                local dx = self.x - enemy.x
                local dy = self.y - enemy.y
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance > 0 and distance < desiredSeparation then
                    steerX = steerX + (dx / distance)
                    steerY = steerY + (dy / distance)
                    count = count + 1
                end
            end
        end
        if count > 0 then
            steerX = steerX / count
            steerY = steerY / count
            local magnitude = math.sqrt(steerX * steerX + steerY * steerY)
            if magnitude > 0 then
                steerX = (steerX / magnitude) * 100
                steerY = (steerY / magnitude) * 100
            else
                steerX, steerY = 0, 0
            end
        end
        return steerX, steerY
    end

    phantom.update = function(self, dt, enemies, effects, summonedEntities)
        self.lifeTimer = self.lifeTimer + dt
        if self.lifeTimer >= self.duration then
            self.isDead = true
            return
        end

        self.attackTimer = self.attackTimer + dt
        self.dashTimer = self.dashTimer + dt

        self.animation.frameTimer = self.animation.frameTimer + dt
        if self.animation.frameTimer >= self.animation.frameDuration then
            self.animation.frameTimer = self.animation.frameTimer % self.animation.totalFrames + 1
        end

        self.prevX = self.x
        self.prevY = self.y

        local closestEnemy, closestDist = nil, math.huge
        for _, enemy in ipairs(enemies) do
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < closestDist then
                closestEnemy = enemy
                closestDist = dist
            end
        end

        local desiredVx, desiredVy = 0, 0
        if closestEnemy then
            self.angleToTarget = math.atan2(closestEnemy.y - self.y, closestEnemy.x - self.x)
            local dx = closestEnemy.x - self.x
            local dy = closestEnemy.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist <= self.attackRange then
                if self.attackTimer >= self.attackCooldown then
                    if not closestEnemy.isDead then
                        closestEnemy:takeDamage(self.damage, damageNumbers, effects, "Grimreaper", nil, "ability")

                        self.attackTimer = 0
                        table.insert(effects, Effects.new("phantom_bite", closestEnemy.x, closestEnemy.y))
                        -- Add chance to apply Fear (30% chance)
                        if math.random() < 0.3 then
                            closestEnemy:applyStatusEffect({ name = "Fear", duration = 3 })
                        end
                        -- Add chance to apply Poison (30% chance; using your applyPoison function)
                        if math.random() < 0.3 then
                            Abilities.applyPoison(closestEnemy, 1, effects, nil, owner)
                        end
                    end
                end
            elseif dist >= self.dashMinRange and dist <= self.dashMaxRange and self.dashTimer >= self.dashCooldown then
                self.isDashing = true
                self.dashTimeElapsed = 0
                local dashDirX = dx / dist
                local dashDirY = dy / dist
                self.vx = dashDirX * self.dashSpeed
                self.vy = dashDirY * self.dashSpeed
            else
                desiredVx = (dx / dist) * self.speed
                desiredVy = (dy / dist) * self.speed
            end
        else
            desiredVx = 0
            desiredVy = 0
        end

-- Apply Separation Steering using the new helper:
local sepX, sepY = Abilities.calculateSeparation(self, summonedEntities, 40, 50)
local separationInfluence = 0.1  -- Adjust influence as needed
desiredVx = desiredVx + sepX * separationInfluence
desiredVy = desiredVy + sepY * separationInfluence


-- Smooth the velocity:
local smoothing = 5  -- adjust as needed
self.vx = self.vx + (desiredVx - self.vx) * dt * smoothing
self.vy = self.vy + (desiredVy - self.vy) * dt * smoothing

-- Update position:
self.x = self.x + self.vx * dt
self.y = self.y + self.vy * dt

-- *** NEW: Store last horizontal direction if movement is significant ***
if math.abs(self.vx) > 0.1 then
    if self.vx > 0 then
        self.lastFacing = "right"
    else
        self.lastFacing = "left"
    end
end

        if self.isDashing then
            self.dashTimeElapsed = self.dashTimeElapsed + dt
            if self.dashTimeElapsed >= self.dashDuration then
                self.isDashing = false
                self.dashTimer = 0
            end
        end
    end

     phantom.draw = function(self)
    if not self.isDead then
        if not self.image then return end
        local scaleX, scaleY = 2, 2
        local quad = phantomFrames[self.animation.currentFrame]
        -- *** NEW: Use lastFacing to determine sprite flip ***
        local facing = self.lastFacing or "right"  -- default to "right"
        if facing == "right" then
            scaleX = 2    -- no flip; sprite faces right by default
        else
            scaleX = -2   -- flip horizontally if facing left
        end
        local floatOffset = math.sin(self.lifeTimer * 2) * 2
        love.graphics.draw(
            self.image, quad, self.x, self.y + floatOffset, 0, scaleX, scaleY,
            8, 8
        )
    end
end



    table.insert(summonedEntities, phantom)
end

function Abilities.handleInfernalSacrificeKill(emberfiend, effects, enemies, damageNumbers, sounds)
 
  
  if not emberfiend.infernalSacrificeChance then
    emberfiend.infernalSacrificeChance = 0.05
   
  end
  
  
  
  if math.random() < emberfiend.infernalSacrificeChance then
   
    local duration = 10     -- adjust as needed
    local speed = 100       -- adjust as needed
    local damageMultiplier = 1.0
  if not _G.player.summonedEntities then
  _G.player.summonedEntities = {}
 
end
Abilities.summonElemental(emberfiend, duration, speed, damageMultiplier, _G.player.summonedEntities, enemies, effects, damageNumbers)

    emberfiend.infernalSacrificeChance = 0.05

  else
    emberfiend.infernalSacrificeChance = emberfiend.infernalSacrificeChance + 0.05
   
  end
end


function Abilities.summonfireling(owner, duration, speed, damageMultiplier, summonedEntities, enemies, effects, damageNumbers)
    if not summonedEntities and not owner.summonedEntities then
        owner.summonedEntities = {}
    end
    summonedEntities = summonedEntities or owner.summonedEntities
    summonedEntities = summonedEntities or {}

    local fireling = {
        type = "Fireling",
        x = owner.x,
        y = owner.y,
        vx = 0,
        vy = 0,
        damage = 10 * damageMultiplier,  -- Base damage scaled by talent
        health = 30,
        duration = duration,
        speed = speed * 2,      -- Adjust as needed
        attackRange = 35,
        attackCooldown = 1,
        attackTimer = 0,
        isDead = false,
        lifeTimer = 0,
        collisionRadius = 15,
        image = firelingImage,
        animation = {
            currentFrame = 1,
            frameTimer = 0,
            frameDuration = 0.2,  -- Time per frame
            totalFrames = #firelingFrames
        },
        angleToTarget = 0,
        damageNumbers = damageNumbers,
        enemies = enemies,
        effects = effects,
        lastFacing = "right",  -- Default facing right
        -- New properties for trail effect:
        fireTrail = {},
        fireTrailTimer = 0,
        fireTrailFrequency = 0.1  -- Adjust the frequency (in seconds) as desired
    }

    fireling.update = function(self, dt, enemies, effects, summonedEntities)
        self.lifeTimer = self.lifeTimer + dt
        if self.lifeTimer >= self.duration then
            self.isDead = true
            return
        end

        self.attackTimer = self.attackTimer + dt

        self.animation.frameTimer = self.animation.frameTimer + dt
        if self.animation.frameTimer >= self.animation.frameDuration then
            self.animation.frameTimer = 0
            self.animation.currentFrame = (self.animation.currentFrame % self.animation.totalFrames) + 1
        end

        local closestEnemy, closestDist = nil, math.huge
        for _, enemy in ipairs(enemies) do
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < closestDist then
                closestEnemy = enemy
                closestDist = dist
            end
        end

        if closestEnemy then
            self.angleToTarget = math.atan2(closestEnemy.y - self.y, closestEnemy.x - self.x)
            local dx = closestEnemy.x - self.x
            local dy = closestEnemy.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist <= self.attackRange then
                if self.attackTimer >= self.attackCooldown then
                    if not closestEnemy.isDead then
                        closestEnemy:takeDamage(self.damage, damageNumbers, effects, "fireling", nil, "ability")
                        self.attackTimer = 0
                        table.insert(effects, Effects.new("fireling_bite", closestEnemy.x, closestEnemy.y))
                    end
                end
                -- Once within attack range, stop moving
                self.vx = 0
                self.vy = 0
            else
                local desiredVx = (dx / dist) * self.speed
                local desiredVy = (dy / dist) * self.speed
                self.vx = desiredVx
                self.vy = desiredVy
            end

            -- Update lastFacing based on current horizontal velocity
            if self.vx ~= 0 then
                self.lastFacing = (self.vx > 0) and "right" or "left"
            end
        else
            self.vx, self.vy = 0, 0
        end

        -- Update position
        self.x = self.x + self.vx * dt
        self.y = self.y + self.vy * dt

        -- Trail effect update:
        self.fireTrailTimer = self.fireTrailTimer + dt
        if self.fireTrailTimer >= self.fireTrailFrequency then
            self.fireTrailTimer = 0
            -- Add a new trail particle at the current position:
            table.insert(self.fireTrail, {
                x = self.x,
                y = self.y,
                lifetime = .7,  -- lifetime in seconds
                alpha = 1,
                size = math.random(.5, 1),
                color = {1, 0.5, 0, 1}  -- fiery orange color
            })
        end
        -- Update and fade out trail particles:
        for i = #self.fireTrail, 1, -1 do
            local particle = self.fireTrail[i]
            particle.lifetime = particle.lifetime - dt
            particle.alpha = particle.lifetime / 1.0  -- fade proportionally
            if particle.lifetime <= 0 then
                table.remove(self.fireTrail, i)
            end
        end
    end

    fireling.draw = function(self)
        if not self.isDead then
            -- First, draw the fire trail particles:
            for _, particle in ipairs(self.fireTrail) do
                love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], particle.alpha)
                love.graphics.circle("fill", particle.x, particle.y, particle.size)
            end

                 -- Reset color to white before drawing the sprite:
            love.graphics.setColor(1, 1, 1, 1)
              
            local scaleX = 2
            local quad = firelingFrames[self.animation.currentFrame]
            -- Use the stored lastFacing property to flip the sprite horizontally.
            if self.lastFacing == "left" then
                scaleX = -2
            else
                scaleX = 2
            end
            love.graphics.draw(self.image, quad, self.x, self.y, 0, scaleX, 2, 8, 8)
        end
    end

    table.insert(summonedEntities, fireling)
end

-- NEW: Separation helper for summons
function Abilities.calculateSeparation(entity, entities, desiredSeparation, maxForce)
    desiredSeparation = desiredSeparation or 40  -- Increase to reduce stacking
    maxForce = maxForce or 50                    -- Maximum repulsion force
    local steerX, steerY = 0, 0
    local count = 0

    for _, other in ipairs(entities) do
        if other ~= entity and not other.isDead then
            local dx = entity.x - other.x
            local dy = entity.y - other.y
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance > 0 and distance < desiredSeparation then
                steerX = steerX + (dx / distance)
                steerY = steerY + (dy / distance)
                count = count + 1
            end
        end
    end

    if count > 0 then
        steerX = steerX / count
        steerY = steerY / count
        local mag = math.sqrt(steerX * steerX + steerY * steerY)
        if mag > 0 then
            steerX = (steerX / mag) * maxForce
            steerY = (steerY / mag) * maxForce
        end
    end

    return steerX, steerY
end



function Abilities.summonElemental(owner, duration, speed, damageMultiplier, summonedEntities, enemies, effects, damageNumbers)
    if not summonedEntities and not owner.summonedEntities then
        owner.summonedEntities = {}
    end
    summonedEntities = summonedEntities or owner.summonedEntities

    local elemental = {
        type = "Fire Elemental",
        x = owner.x,
        y = owner.y,
        vx = 0,
        vy = 0,
        damage = 30,    -- base damage
        health = 60,
        duration = duration,  -- ensure this is set to a value > 0 (e.g., 15)
        speed = speed * 2,
        attackRange = 35,
        attackCooldown = 1,
        attackTimer = 0,
        isDead = false,
        lifeTimer = 0,
        collisionRadius = 15,
        dashMinRange = 25,
        dashMaxRange = 50,
        dashSpeed = speed * 5,
        isDashing = false,
        dashCooldown = 5,
        dashTimer = 0,
        dashDuration = 0.2,
        dashTimeElapsed = 0,
        enemyPrevPos = {},
        image = elementalImage,
        lastDirection = "right",
        angleToTarget = 0,
        damageNumbers = damageNumbers,
        enemies = enemies,
        effects = effects,
        animation = {
            currentFrame = 1,
            frameTimer = 0,
            frameDuration = 0.2,
            totalFrames = #elementalFrames
        },
        abilities = {},
        projectiles = {}
    }
    elemental.emberLegacy = owner.emberLegacy or 0
    Abilities.upgradeAbility(elemental, "Fire Bomb")

    -- Talent bonus for emberLegacy >= 1
    if (owner.emberLegacy or 0) >= 1 then
        elemental.duration = elemental.duration + 5
        elemental.damage = elemental.damage * 2
    end

    -- Update function
  elemental.update = function(self, dt, enemies, effects, summonedEntities, sounds, damageNumbers)
    Abilities.updateCooldowns(self, dt)
    self.lifeTimer = self.lifeTimer + dt

    -- If the elemental is talented (emberLegacy>=2) and we’re at the death moment…
    if (self.emberLegacy or 0) >= 2 and self.lifeTimer >= (self.duration - .5) and not self.hasCasted then
        -- Trigger extra volley once at 1 second before expiration
        for i = 1, 5 do
            local angle = math.random() * 2 * math.pi
            local travelDistance = math.random(80, 120)
            local targetX = self.x + travelDistance * math.cos(angle)
            local targetY = self.y + travelDistance * math.sin(angle)
            local firebomb = Effects.new("firebomb_projectile", self.x, self.y, targetX, targetY, "Fire Elemental", nil, effects, 0, 0, enemies, damageNumbers)
            firebomb.damage = self.damage * 1.2
            firebomb.lifetime = 0.8
            firebomb.g = 200
            local dx = targetX - self.x
            local dy = targetY - self.y
            firebomb.vx = dx / firebomb.lifetime
            firebomb.vy = (dy / firebomb.lifetime) - 0.5 * firebomb.g * firebomb.lifetime
            firebomb.onImpact = function(fb, impactX, impactY)
                local expl = Effects.new("explosion", impactX, impactY, nil, nil, "Fire Elemental", nil, effects, 50, 0, enemies, damageNumbers)
                expl.damage = fb.damage
                table.insert(effects, expl)
                local burnPatch = Effects.new("burn_patch", impactX, impactY, nil, nil, "Fire Elemental", nil, effects, 50, 0, enemies, damageNumbers, 5)
                local talentMultiplier = (self.emberLegacy or 0) >= 1 and 2 or 1
                burnPatch.damagePerTick = 5 * talentMultiplier
                burnPatch.tickInterval = 0.5
                table.insert(effects, burnPatch)
            end
            table.insert(effects, firebomb)
            if self.owner and self.owner.projectiles then
                table.insert(self.owner.projectiles, firebomb)
            end
        end
        self.hasCasted = true
    end

    -- Now, if still alive normally…
    if self.lifeTimer < self.duration then
        -- Normal movement/attack behavior
        self.attackTimer = self.attackTimer + dt
        self.dashTimer = self.dashTimer + dt
        self.animation.frameTimer = self.animation.frameTimer + dt
        if self.animation.frameTimer >= self.animation.frameDuration then
            self.animation.frameTimer = 0
            self.animation.currentFrame = (self.animation.currentFrame % self.animation.totalFrames) + 1
        end
        self.prevX = self.x
        self.prevY = self.y

        local target, closestDist = nil, math.huge
        for _, enemy in ipairs(enemies) do
            if not enemy.isDead then
                local dx = enemy.x - self.x
                local dy = enemy.y - self.y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist < closestDist then
                    closestDist = dist
                    target = enemy
                end
            end
        end

        local desiredVx, desiredVy = 0, 0
        if target then
            self.angleToTarget = math.atan2(target.y - self.y, target.x - self.x)
            local dx = target.x - self.x
            local dy = target.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if self.abilities and self.abilities["Fire Bomb"] then
                local fireBomb = self.abilities["Fire Bomb"]
                if fireBomb.cooldownTimer <= 0 then
                    fireBomb.effect(self, target, effects, sounds, summonedEntities, enemies, damageNumbers)
                    fireBomb.cooldownTimer = fireBomb.cooldown
                elseif dist <= self.attackRange then
                    if self.attackTimer >= self.attackCooldown then
                        if not target.isDead then
                            target:takeDamage(self.damage, damageNumbers, effects, "Fire Elemental", nil, "ability")
                            self.attackTimer = 0
                            table.insert(effects, Effects.new("elemental_bite", target.x, target.y))
                        end
                    end
                else
                    desiredVx = (dx / dist) * self.speed
                    desiredVy = (dy / dist) * self.speed
                end
            end
        else
            desiredVx, desiredVy = 0, 0
        end

        if summonedEntities then
            local sepX, sepY = Abilities.calculateSeparation(self, summonedEntities, 40, 50)
            local separationInfluence = 0.1
            desiredVx = desiredVx + sepX * separationInfluence
            desiredVy = desiredVy + sepY * separationInfluence
        end

        local smoothing = 5
        self.vx = self.vx + (desiredVx - self.vx) * dt * smoothing
        self.vy = self.vy + (desiredVy - self.vy) * dt * smoothing
        self.x = self.x + self.vx * dt
        self.y = self.y + self.vy * dt

        if self.isDashing then
            self.dashTimeElapsed = self.dashTimeElapsed + dt
            if self.dashTimeElapsed >= self.dashDuration then
                self.isDashing = false
                self.dashTimer = 0
            end
        end

        for i = #self.projectiles, 1, -1 do
            local proj = self.projectiles[i]
            if proj and proj.update then
                proj:update(dt)
                if proj.isDead then
                    table.remove(self.projectiles, i)
                end
            end
        end

    else
        -- After duration + a short delay, mark as dead.
        if self.lifeTimer >= self.duration + 0.5 then
            self.isDead = true
            return
        end
    end
end


    elemental.draw = function(self)
        if not self.isDead then
            local scaleX = 2
            local scaleY = 2
            local quad = elementalFrames[self.animation.currentFrame]
            scaleX = self.vx < 0 and -2 or 2
            love.graphics.draw(self.image, quad, self.x, self.y, 0, scaleX, scaleY, 8, 8)
            for _, proj in ipairs(self.projectiles) do
                if proj and proj.draw then
                    proj:draw()
                end
            end
        end
    end

    table.insert(summonedEntities, elemental)
    return elemental
end





return Abilities