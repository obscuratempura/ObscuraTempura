--Enemy.lua

local Collision = require("collision")
local Effects = require("effects")
local Abilities = require("abilities")

local Projectiles = require("projectile")
local EnemyProjectile = Projectiles.EnemyProjectile
local Sprites = require("sprites")
local DEFAULT_RADIUS = 10  -- Define a safe default radius
local RandomItems  = require("random_items")
local GameState = require("gameState")  -- Require the gameState module
local gameState = GameState.new()        -- Get the singleton instance
local BossAbilities = require("bossAbilities")

local sqrt = math.sqrt
local atan2 = math.atan2
local random = math.random
local cos = math.cos
local sin = math.sin

local STATES = {
  ATTACK = "attack",
  WANDER = "wander",
  RETREAT = "retreating",
  INVULNERABLE = "invulnerable"
}


local Enemy = {}
Enemy.__index = Enemy

local function profileSection(name, callback, threshold)
  local startTime = love.timer.getTime()
  callback()
  local elapsed = love.timer.getTime() - startTime
  if elapsed > (threshold or 0.003) then  -- 3ms threshold
    print(string.format("[PROFILE] %s took %.5f seconds", name, elapsed))
  end
end


-- Function to get a random enemy type
function Enemy.randomType()
    local enemyTypes = {"spider", "skeleton", "bat", "pumpkin", "spirit", "mage_enemy", "viper"}
    return enemyTypes[math.random(#enemyTypes)]
end

function Enemy:determineBehavior()
  
    if self.type == "webber" then
        return "webber"
    elseif self.type == "elite_spider" then
        return "elite_spider"
    elseif self.type == "vampire_boss" then
        return "teleport"
    elseif self.type == "mage_enemy" then
        return "teleport_ranged"
    elseif self.type == "beholder" then
        return "beholder_ranged"
    elseif self.type == "spirit" then
        return "wander_and_attack"
    elseif self.type == "pumpkin" then
        return "bounce_explode"
    elseif self.type == "skitter_spider" then
        return "skitter_around"
    
    else
        return "aggressive"
    end
end

-- NEW: Reset method to initialize or re-initialize an enemy instance
function Enemy:reset(type, x, y, playerLevel, level)
    self.type = type
    self.x = x or 0
    self.y = y or 0
    self.prevX = x
    self.prevY = y
    self.health = 50  -- Base health (will be overridden by type)
    self.maxHealth = self.health
    self.vx = 0
    self.vy = 0
    self.damage = 10  -- Default damage (will be overridden by type)
    self.radius = 10  -- Default radius (will be overridden by type)
    self.experience = 5 -- Default experience (will be overridden by type)

    self.statusEffects = {} -- Clear existing effects
    self.projectiles = {}   -- Clear existing projectiles
    self.lastDirection = "left"
    self.timers = {}        -- Clear existing timers
    self.flashTimer = 0
    self.attackTimer = 0
    self.attackSpeed = 1    -- Default attack speed (will be overridden by type)
    self.activeParticles = {} -- Clear existing particles

    self.behavior = self:determineBehavior()
    self.target = nil
    self.runSpeedMultiplier = 1.5
    self.state = STATES.ATTACK
    self.color = {1, 1, 1} -- Default color (will be overridden by type)

    if type == "web" then
        self.drawPriority = 0
        self.targetable = false
    else
        self.drawPriority = 2
        self.targetable = true
    end

    -- Reset colors table (it's constant, but good practice if it could change)
    self.colors = {
        darkRedBrown = {86/255, 33/255, 42/255, 1},
        deepPurple = {67/255, 33/255, 66/255, 1},
        grayishPurple = {95/255, 87/255, 94/255, 1},
        mutedTeal = {77/255, 102/255, 96/255, 1},
        rustRed = {173/255, 64/255, 48/255, 1},
        mutedBrick = {144/255, 75/255, 65/255, 1},
        darkRose = {155/255, 76/255, 99/255, 1},
        mutedOliveGreen = {149/255, 182/255, 102/255, 1},
        peachyOrange = {231/255, 155/255, 124/255, 1},
        warmGray = {166/255, 153/255, 152/255, 1},
        paleYellow = {246/255, 242/255, 195/255, 1},
        darkTeal = {47/255, 61/255, 58/255, 1},
        orangeGold = {239/255, 158/255, 78/255, 1},
        pastelMint = {142/255, 184/255, 158/255, 1},
        smokyBlue = {70/255, 85/255, 95/255, 1},
        burntSienna = {233/255, 116/255, 81/255, 1},
        sageGreen = {148/255, 163/255, 126/255, 1},
        dustyLavender = {174/255, 160/255, 189/255, 1},
        mustardYellow = {218/255, 165/255, 32/255, 1},
        terraCotta = {226/255, 114/255, 91/255, 1},
        charcoalGray = {54/255, 69/255, 79/255, 1},
        blushPink = {222/255, 173/255, 190/255, 1},
        forestGreen = {34/255, 85/255, 34/255, 1},
        midnightBlue = {25/255, 25/255, 112/255, 1}
    }

    -- Initialize enemy-specific attributes based on type
    -- (This large block of type checks remains the same)
    if type == "spider" then
        self.speed = 6
        self.health = 30
        self.maxHealth = self.health
        self.damage = 4
        self.experience = 6
        self.radius = 20
        self.attackSpeed = 1
        self.attackRange = 60
        self.meleeRange = self.radius + 25
        self.spriteHeight = 16
    elseif type == "spiderv2" then
        self.speed = 9
        self.health = 60
        self.maxHealth = self.health
        self.damage = 3
        self.experience = 8
        self.radius = 20
        self.attackSpeed = 1
        self.attackRange = 60
        self.meleeRange = self.radius + 25
        self.spriteHeight = 16
        self.isDashing = false
        self.dashAttackCooldown = 3
        self.dashAttackTimer = 0
        self.dashDuration = 0.5
        self.dashSpeed = 12
        self.dashState = "idle"
        self.dashDirX = 0 -- Reset dash direction
        self.dashDirY = 0
        self.retreatDirX = 0 -- Reset retreat direction
        self.retreatDirY = 0
    elseif type == "webber" then
        self.speed = 9
        self.health = 40
        self.maxHealth = self.health
        self.damage = 2
        self.experience = 15
        self.radius = 20
        self.attackSpeed = 0.22
        self.projectileCooldown = 5 -- Reset cooldown
        self.webCooldown = 1 -- Reset cooldown
        self.webTimer = 0
        self.projectiles = {} -- Ensure projectiles are cleared
        self.webberState = STATES.ATTACK
        self.attackRange = 175
        self.safeDistance = 150
        self.webs = {} -- Clear webs table
        self.spriteHeight = 16
    elseif type == "kristoff" then
        self.speed = 6
        self.health = 2000
        self.maxHealth = 2000
        self.damage = 25
        self.experience = 500
        self.radius = 30
        self.attackSpeed = 0.5
        self.attackRange = 50
        self.behavior = "aggressive" -- Reset behavior if needed
        self.bombCooldown = 10
        self.bombTimer = 0
        self.bossPhase = 1
        self.bossTimer = 0
        self.collisionWidth = 32
        self.collisionHeight = 32
        self.collisionOffsetY = 32
        self.drawPriority = 3
        self.spriteHeight = 16
        self.collisionBottomOffset = 2
        self.bossDeathHandled = false -- Reset death flag
        self.webLunge = nil -- Reset ability state
    elseif type == "skitter_spider" then
        self.speed = 29
        self.health = 5
        self.maxHealth = self.health
        self.damage = 1
        self.experience = 2
        self.radius = 8
        self.attackSpeed = 1
        self.attackRange = 50
        self.meleeRange = self.radius + 15 + 10
        self.skitterState = "patrol"
        self.pauseTimer = 0
        self.route = {}
        self.currentWaypoint = 1
        self.spriteHeight = 16
    elseif type == "elite_spider" then
        self.health = 500
        self.maxHealth = 500
        self.damage = 6
        self.speed = 8
        self.radius = 20
        self.experience = 100
        self.attackRange = 150
        self.behavior = "elite_spider"
        self.projectiles = {} -- Ensure projectiles are cleared
        self.spriteHeight = 32
        -- Reset elite spider specific timers/state
        self.spreadTimer = 0
        self.spreadChargeTimer = 5
        self.buffTimer = 20
        self.buffDuration = 0
        self.flashingColor = nil
        self.spreadRoundsRemaining = nil
        self.spreadRoundCooldown = nil
        self.storedTripleAngle = nil
    elseif type == "mimic" then
        self.speed = 8
        self.health = 150
        self.maxHealth = self.health
        self.damage = 3
        self.experience = 10
        self.radius = 10
        self.attackSpeed = 1
        self.attackRange = 40
        self.meleeRange = self.radius + 15 + 10
        self.slowCooldown = 0
        self.behavior = "aggressive"
        self.animation = Sprites.animations.mimic -- Re-assign animation if needed
        if self.animation then -- Ensure animation exists before setting properties
             self.animation.speed = 1
             self.animation.timer = 0
        end
        self.spriteHeight = 16
    elseif type == "pumpkin" then
        self.speed = 6
        self.health = 100
        self.maxHealth = self.health
        self.damage = 50
        self.experience = 7
        self.radius = 16
        self.explosionRange = 50
        self.attackSpeed = 1
        self.hopTimer = 0
        self.hopInterval = 3
        self.isHopping = false
        self.hopDuration = 1
        self.hopElapsed = 0
        self.hopSpeed = 200
        self.hopHeight = 20
        self.originalY = y or self.y -- Use the new y
        self.spriteHeight = 16
        self.hopDirectionX = 0 -- Reset hop direction
        self.hopDirectionY = 0
    elseif type == "skeleton" then
        self.speed = 10
        self.health = 225
        self.maxHealth = self.health
        self.damage = 17
        self.experience = 10
        self.radius = 20
        self.attackSpeed = 1
        self.spriteHeight = 16
    elseif type == "bat" then
        self.speed = 25
        self.health = 100
        self.maxHealth = self.health
        self.damage = 12
        self.experience = 5
        self.radius = 20
        self.attackSpeed = 1
        self.spriteHeight = 16
    elseif type == "Osskar" then
        self.speed = 8
        self.health = 500
        self.maxHealth = self.health
        self.damage = 25
        self.radius = 24
        self.color = {1, 0, 0, 1} -- Reset color
        self.attackSpeed = 1
        self.experience = 25
        self.dashCooldown = 5
        self.dashTimer = 0
        self.isDashing = false
        self.dashTelegraphDuration = 0.5
        self.dashTelegraphTimer = 0
        self.dashDamage = 75
        self.dashSpeed = 400
        self.dashDistance = 300 -- Reset original distance
        self.originalSpeed = self.speed -- Store new original speed
        self.dashDirectionX = 0
        self.dashDirectionY = 0
        self.isTelegraphingDash = false
        self.spriteHeight = 32
        self.clonesSpawned = false -- Reset clone flag
        self.isClone = false -- Assume not a clone unless specified later
        self.isEnraged = false -- Reset enraged state
        self.savedRadius = nil -- Clear saved radius
        self.savedSpeedForTelegraph = nil -- Clear saved speed
        self.dashTelegraphEffectSpawned = false -- Reset telegraph effect flag
    elseif type == "spirit" then
        self.speed = 10
        self.health = 100
        self.maxHealth = self.health
        self.damage = 10
        self.experience = 5
        self.radius = 10
        self.attackSpeed = 0.5
        self.attackRange = 100
        self.spriteHeight = 16
        self.wanderAngle = nil -- Reset wander angle
    elseif type == "beholder" then
        self.speed = 13
        self.health = 350
        self.maxHealth = self.health
        self.damage = 15
        self.radius = 16
        self.color = {0.5, 0.5, 1, 1} -- Reset color
        self.attackSpeed = 1
        self.spriteHeight = 16
        self.experience = 10
        self.attackRange = 600
        self.attackState = "idle"
        self.attackTimer = 0
        self.telegraphTimer = 0
        self.telegraphDuration = 1.5
        self.rayDuration = 0.2
        self.rayCooldown = 5.0
        self.projectiles = {} -- Ensure projectiles are cleared
        self.behavior = self:determineBehavior() -- Reset behavior
        self.storedRayAngle = nil -- Reset stored ray info
        self.storedRayEndX = nil
        self.storedRayEndY = nil
        -- Note: Aura effect might need special handling if added in 'new'
        -- If Effects.new adds to a global 'effects' table, it might be okay.
        -- If it adds to self.effects, it needs clearing/re-adding.
    elseif type == "web" then
        self.speed = 0
        self.health = 5
        self.maxHealth = self.health
        self.damage = 0
        self.experience = 0
        self.radius = 10
        self.type = "web" -- Ensure type is set correctly
        self.color = {0, 0, 0, 0.5}
        self.webHealthTimer = 1
        self.drawPriority = 0 -- Ensure draw priority is set
        self.targetable = false -- Ensure targetable is set
    else
        -- Handle unknown enemy types (reset to defaults)
        self.speed = 15
        self.health = 50
        self.maxHealth = self.health
        self.damage = 5
        self.experience = 5
        self.radius = 15
        self.color = {1, 1, 1, 1}
        self.spriteHeight = 16 -- Default sprite height
        self.attackSpeed = 1 -- Default attack speed
        self.behavior = "aggressive" -- Default behavior
        self.state = STATES.ATTACK -- Default state
    end

    -- Set originalSpeed and originalAttackSpeed unconditionally after type specifics:
    self.originalSpeed = self.speed
    self.originalAttackSpeed = self.attackSpeed

    -- Reset other state variables
    self.isInRange = false
    self.onDeath = nil
    self.isDead = false
    self.remove = false
    self.isDying = false
    self.deathAnimationTimer = 0
    self.deathHandled = false
    self.spawnState = "dormant" -- Or "active" depending on your logic
    self.isHit = false
    self.isShocked = false
    self.isFrozen = false
    self.isStunned = false
    self.fearFlashTimer = 0
    self.fearFlashState = false
    self.isMadnessSpeedBoosted = false
    self.madnessVisualApplied = false
    self.windUpTimer = nil
    self.originalSpeedWindup = nil
    self.isPooled = false -- Flag to indicate if it's currently in the pool

    -- Reset animation timers if applicable
    if self.animation and self.animation.timer then
        self.animation.timer = 0
    end
    -- Reset death animation if applicable
    if self.deathAnimation and self.deathAnimation.reset then
         self.deathAnimation:reset()
    end

    -- Ensure BossAbilities is available if needed for Kristoff reset
    if type == "kristoff" and BossAbilities and BossAbilities.resetKristoffState then
         BossAbilities.resetKristoffState(self)
    end
    print(string.format("Enemy Reset: Type=%s, Experience=%s, deathHandled=%s", self.type, tostring(self.experience), tostring(self.deathHandled))) -- Updated DEBUG
    return self -- Return self for chaining if needed, though not used in Enemy.new
end


function Enemy.new(type, x, y, playerLevel, level)
    local self = setmetatable({}, Enemy)
    -- Call the reset method to perform all initialization
    self:reset(type, x, y, playerLevel, level)
    return self
end

function Enemy:findNearestEnemy(enemies)
    local nearest, minDist = nil, math.huge
    for _, e in pairs(enemies) do
        if e ~= self and not e.isDead and e.targetable then
            local dx = e.x - self.x
            local dy = e.y - self.y
            local distSq = dx*dx + dy*dy
            if distSq < minDist then
                nearest = e
                minDist = distSq
            end
        end
    end
    if not nearest then return nil, math.huge end
    return nearest, math.sqrt(minDist)
end

function Enemy:handleState(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities, spawnEnemyFunc)
    if self.behavior == "webber" then
        self:performAttackBehavior(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities, spawnEnemyFunc)
    else
        if self.state == STATES.ATTACK then
            -- NEW: if type is "spiderv2", call the new update function.
            if self.type == "spiderv2" then
                self:updateSpiderv2(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities)
            else
                self:performAttackBehavior(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities)
            end
        elseif self.state == STATES.WANDER then
            self:wanderBehavior(dt, player)
        elseif self.state == STATES.RETREAT then
            self:performRetreatBehavior(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities)
        end
    end
end





function Enemy:performAttackBehavior(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities, spawnEnemyFunc)
 
   if self.type == "spider" then
    local dist, closestChar = self:getDistanceToPlayer(player)
    if closestChar and dist < (self.meleeRange or 40) then
        -- Use an attack timer to limit attack frequency.
        if self.attackTimer < (1 / self.attackSpeed) then
            self.attackTimer = self.attackTimer + dt
        else
            self.attackTimer = 0
            player:takeDamage(self.damage)
            local slashEffect = Effects.new("goylebite", closestChar.x, closestChar.y, self.x, self.y, nil, nil, effects)
            table.insert(effects, slashEffect)
        end
    else
        self:chaseNearestCharacter(dt, player, effects, sounds, summonedEntities)
    end
    return 

    elseif self.behavior == "aggressive" then
        self:chaseNearestCharacter(dt, player, effects, sounds, summonedEntities)
    elseif self.behavior == "elite_spider" then
        self:updateEliteSpider(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities)
    elseif self.behavior == "ranged" then
        self:rangedAttack(dt, player)
    elseif self.behavior == "teleport" then
        self:updateVampireBoss(dt, player, effects, enemies, damageNumbers, sounds)
    elseif self.behavior == "teleport_ranged" then
        self:updateMageEnemy(dt, player, effects, enemies)
    elseif self.behavior == "beholder_ranged" then
        self:updateBeholder(dt, player, effects, enemies, damageNumbers, sounds)
    elseif self.behavior == "wander_and_attack" then
        self:wanderAndAttack(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities)
    elseif self.behavior == "bounce_explode" then
        self:updatePumpkin(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities)
    elseif self.behavior == "skitter_around" then
        self:updateSkitterSpider(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities)
    elseif self.behavior == "webber" then
        self:updateWebber(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities, spawnEnemyFunc)
    end
end



function Enemy:updatePumpkin(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities)
    -- **Handle Hopping Behavior**
    if not self.isHopping then
        -- Increment the hop timer
        self.hopTimer = self.hopTimer + dt

        -- Check if it's time to hop
        if self.hopTimer >= self.hopInterval then
            -- Reset the hop timer
            self.hopTimer = 0

            -- Get the closest character (player)
            local dist, closestChar = self:getDistanceToPlayer(player)
            if closestChar then
                -- Calculate direction towards the player
                local dx = closestChar.x - self.x
                local dy = closestChar.y - self.y
                local distance = math.sqrt(dx * dx + dy * dy)

                if distance > 0 then
                    self.hopDirectionX = dx / distance
                    self.hopDirectionY = dy / distance
                    self.isHopping = true
                    self.hopElapsed = 0
                end
            end
        end
    else
        -- **During Hopping**
        self.hopElapsed = self.hopElapsed + dt

        if self.hopElapsed <= self.hopDuration then
            -- Move horizontally toward the player
            self.x = self.x + self.hopDirectionX * self.hopSpeed * dt

            -- **Inverted Sine Wave for Upward Hop**
            self.y = self.originalY - math.sin((self.hopElapsed / self.hopDuration) * math.pi) * self.hopHeight
        else
            -- **End of Hop**
            self.isHopping = false
            self.y = self.originalY  -- Reset to original Y position
        end
    end

    -- **Check for Explosion Near Player**
    local dist, closestChar = self:getDistanceToPlayer(player)
    if closestChar and dist < self.explosionRange then
        -- **Explode and Deal Damage**
      player:takeDamage(self.damage)

        -- **Trigger Explosion Effects**
        table.insert(effects, Effects.new("hellblast", self.x, self.y))
        
        -- **Play Explosion Sound**
        if sounds and sounds.ability and sounds.ability.explosion then
            sounds.ability.explosion:play()
        else
           
        end

        -- **Mark for Removal**
        self.isDead = true
        self.remove = true
    end
end

function Enemy:wanderAndAttack(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities)
    local distanceToPlayer, closestChar = self:getDistanceToPlayer(player)
    
    if distanceToPlayer <= self.attackRange then
        self:performMeleeAttack(dt, player, effects, sounds, summonedEntities)
    else
        -- Instead of cardinal directions, pick a random angle for wandering.
        if not self.wanderAngle or math.random() < 0.02 then
            self.wanderAngle = math.random() * 2 * math.pi
        end
        self.vx = math.cos(self.wanderAngle) * self.speed
        self.vy = math.sin(self.wanderAngle) * self.speed

        self.x = self.x + self.vx * dt
        self.y = self.y + self.vy * dt
    end
end

-- Function to apply status effects to the enemy
function Enemy:applyStatusEffect(effect)
    -- Make Osskar immune to "Shock," "Frozen," and "Fear"
    if self.type == "Osskar"
       and (effect.name == "Shock" or effect.name == "Frozen" or effect.name == "Fear") then
        return
    end
    if self.type == "kristoff" and (effect.name == "Poison" or effect.name == "Fear" or effect.name == "Stun") then
        return  -- Ignore these effects
    end
    -- If the effect is new, initialize; else refresh
    if not self.statusEffects[effect.name] then
        self.statusEffects[effect.name] = {
            duration = effect.duration,
            damagePerSecond = effect.damagePerSecond or 0,
            timer = 0,
            tickTimer = 0
        }
    else
        local existingEffect = self.statusEffects[effect.name]
        existingEffect.duration = math.max(existingEffect.duration, effect.duration)
        existingEffect.damagePerSecond = math.max(
            existingEffect.damagePerSecond,
            effect.damagePerSecond or existingEffect.damagePerSecond
        )
    end

    -- Set booleans for specific effects
    if effect.name == "Shock" then
        self.isShocked = true
    elseif effect.name == "Frozen" then
        self.isFrozen = true
    elseif effect.name == "Stun" then
        self.isStunned = true
     elseif effect.name == "Madness" then
   
    table.insert(effects, Effects.new(
        "madness",
        self.x,
        self.y,
        nil,          -- targetX
        nil,          -- targetY
        nil,          -- ownerType
        self,         -- attachedTo
        effects,      -- effects table
        nil,          -- impactRadius
        nil,          -- damagePerMeteor
        enemies,            -- enemies table
        damageNumbers,      -- damageNumbers table
        duration or 5.0     -- duration (optional)
    ))

    end
end

function Enemy:update(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities, Bonepit, zoomFactor, bosses, spawnEnemyFunc)
  local getTime = love.timer.getTime  -- localize function
  local startTime = getTime()  -- start profiling timer

  profileSection("Enemy: Activation/Despawning", function()
    local activationDistance = 200
    local despawnDistance = 400
    local distance, _ = self:getDistanceToPlayer(player)
    if distance > despawnDistance then
      self.remove = true
      return
    end
    if self.spawnState == "dormant" then
      if distance < activationDistance then
        self.spawnState = "active"
      else
        return
      end
    elseif self.spawnState == "active" then
      if distance > despawnDistance then
        self.remove = true
        return
      end
    end
  end, 0.003)

  profileSection("Enemy: Particles Update", function()
    self:updateParticles(dt)
  end, 0.003)

  profileSection("Enemy: Dying Animation", function()
    if self.isDying then
      if self.deathAnimation and self.deathAnimation.update then -- Check if animation exists
            self.deathAnimation:update(dt)
            self.deathAnimationTimer = self.deathAnimationTimer + dt
            -- Calculate total duration more safely
            local totalDuration = 0
            if self.deathAnimation.numFrames and self.deathAnimation.frameDuration then
               totalDuration = self.deathAnimation.numFrames * self.deathAnimation.frameDuration
            end

            if self.deathAnimationTimer >= totalDuration and totalDuration > 0 then
                -- Animation finished
                self.isDying = false -- Stop dying state
                self.remove = true -- Now mark for removal
                if self.type == "kristoff" and not self.bossDeathHandled then
                    self.bossDeathHandled = true
                    -- gameState:setState("scoreScreen") -- Consider moving state changes elsewhere if needed
                    -- showScoreScreen()
                end
            end
        else
             -- If isDying is true but there's no animation, mark for removal immediately
             self.isDying = false
             self.remove = true
        end
        return -- Don't process further updates while dying
    end
  end, 0.003)

  if gameState.gamePaused or gameState.isLevelingUp then return end

  profileSection("Enemy: Ensure Speed", function()
    if not self.speed then self.speed = self.originalSpeed or 15 end
  end, 0.003)

  if self.type == "Osskar" then
    profileSection("Enemy: Update Osskar Dash", function()
      self:updateOsskarDash(dt, player, effects, damageNumbers, sounds)
    end, 0.003)
  end

  if self.type == "mimic" then
    profileSection("Enemy: Update Mimic SlowCooldown", function()
      self.slowCooldown = math.max(0, self.slowCooldown - dt)
    end, 0.003)
  end

  if self.isDead then
    profileSection("Enemy: Dead Particles Update", function()
      self:updateParticles(dt)
      if #self.activeParticles == 0 then self.remove = true end
    end, 0.003)
    return
  end

  if self.type == "web" then
    profileSection("Enemy: Web-specific Handling", function()
      if player and player.characters then
        for _, char in pairs(player.characters) do
          local pdx = char.x - self.x
          local pdy = char.y - self.y
          local pDist = math.sqrt(pdx * pdx + pdy * pdy)
          if pDist <= (self.radius + char.radius) then
            local slowDuration = 5
            local slowValue = 0.75
            player:applyStatusEffect(nil, "Slow", slowDuration, slowValue)
            self.remove = true
          end
        end
      end
      self.webHealthTimer = self.webHealthTimer - dt
      if self.webHealthTimer <= 0 then
        self.webHealthTimer = 1
        self.health = self.health - 1
        if self.health <= 0 then self.remove = true end
      end
      return
    end, 0.003)
  end

  if self.type == "kristoff" then
    profileSection("Enemy: Kristoff Boss Update", function()
      -- Pass the spawnEnemyFunc argument
      BossAbilities.updateKristoff(self, dt, player, effects, enemies, damageNumbers, sounds, summonedEntities, spawnEnemyFunc)
    end, 0.003)
  end

  profileSection("Enemy: Timers Update", function()
    self.attackTimer = self.attackTimer + dt
    if not self.radius then self.radius = DEFAULT_RADIUS end
    self.prevX, self.prevY = self.x, self.y
    for i = #self.timers, 1, -1 do
      local timer = self.timers[i]
      timer.timeLeft = timer.timeLeft - dt
      if timer.timeLeft <= 0 then
        timer.action()
        table.remove(self.timers, i)
      end
    end
  end, 0.003)

  if not self.x or not self.y then return end

  if self.animation then
    profileSection("Enemy: Animation Timer Update", function()
      self.animation.timer = self.animation.timer + dt * self.animation.speed
    end, 0.003)
  end

  if self.flashTimer > 0 then
    profileSection("Enemy: Flash Timer Update", function()
      self.flashTimer = self.flashTimer - dt
      if self.flashTimer < 0 then self.flashTimer = 0 end
    end, 0.003)
  end

  profileSection("Enemy: Status Effects Processing", function()
    local shouldSkipUpdates = false
    for effectName, effect in pairs(self.statusEffects or {}) do
      effect.timer = effect.timer + dt
      if effect.timer >= effect.duration then
        self.statusEffects[effectName] = nil
        if effectName == "Shock" then self.isShocked = false
        elseif effectName == "Frozen" then self.isFrozen = false
        elseif effectName == "Stun" then self.isStunned = false end
      else
        if (effectName == "Poison" or effectName == "Ignite" or effectName == "Corrosive Poison") and effect.damagePerSecond then
          if not effect.tickTimer then effect.tickTimer = 0 end
          effect.tickTimer = effect.tickTimer + dt
          if effect.tickTimer >= 1 then
            effect.tickTimer = effect.tickTimer - 1
            self:takeDamage(effect.damagePerSecond, damageNumbers, effects, nil, nil, "damageOverTime")
            table.insert(effects, Effects.new(effectName, self.x, self.y))
            if sounds and sounds.statusEffect and sounds.statusEffect[effectName] then
              sounds.statusEffect[effectName]:play()
            end
          end
          if effectName == "Frozen" or effectName == "Stun" then shouldSkipUpdates = true end
        end
        if effectName == "Frozen" or effectName == "Stun" then shouldSkipUpdates = true end
      end
    end
    if self.isFrozen or self.isStunned then return end
  end, 0.003)

  profileSection("Enemy: Fear Status Processing", function()
    if self.statusEffects["Fear"] then
      local fearEffect = self.statusEffects["Fear"]
      fearEffect.timer = fearEffect.timer + dt
      if fearEffect.timer >= fearEffect.duration then
        self.statusEffects["Fear"] = nil
      else
        local distanceToPlayer, closestChar = self:getDistanceToPlayer(player)
        if closestChar then
          local dx = self.x - closestChar.x
          local dy = self.y - closestChar.y
          local dist = math.sqrt(dx * dx + dy * dy)
          if dist > 0 then
            local fearRunSpeed = self.speed * (self.runSpeedMultiplier or 1.5)
            self.vx = (dx / dist) * fearRunSpeed
            self.vy = (dy / dist) * fearRunSpeed
            self.x = self.x + self.vx * dt
            self.y = self.y + self.vy * dt
          end
        end
        self.fearFlashTimer = (self.fearFlashTimer or 0) + dt
        if self.fearFlashTimer >= 0.1 then
          self.fearFlashTimer = 0
          self.fearFlashState = not self.fearFlashState
        end
        return
      end
    end
  end, 0.003)

  profileSection("Enemy: Madness Status Processing", function()
    if self.statusEffects["Madness"] then
      local madness = self.statusEffects["Madness"]
      madness.timer = madness.timer + dt
      if madness.timer >= madness.duration then
        self.statusEffects["Madness"] = nil
        if self.isMadnessSpeedBoosted then
          self.speed = self.originalSpeed
          self.isMadnessSpeedBoosted = false
        end
      else
        if not self.isMadnessSpeedBoosted then
          self.speed = (self.originalSpeed or 15) * 5
          self.isMadnessSpeedBoosted = true
        end
        local target, dist = self:findNearestEnemy(enemies)
        if target then
          local dx = target.x - self.x
          local dy = target.y - self.y
          local distance = math.sqrt(dx * dx + dy * dy)
          if distance > (self.radius + target.radius + 10) then
            local dirX = dx / distance
            local dirY = dy / distance
            self.vx = dirX * self.speed
            self.vy = dirY * self.speed
            self.x = self.x + self.vx * dt
            self.y = self.y + self.vy * dt
          else
            target:takeDamage(self.damage, damageNumbers, effects, "sanguine_frenzy", nil, "attack")
          end
        end
        if not self.madnessVisualApplied then
          self.madnessVisualApplied = true
          table.insert(effects, Effects.new("madness", self.x, self.y, self.radius))
        end
        return
      end
    end
  end, 0.003)

  profileSection("Enemy: Handle State", function()
    self:handleState(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities, spawnEnemyFunc)
  end, 0.003)

   profileSection("Enemy: Update Projectiles", function()
    -- Pass the spawnEnemyFunc argument
    self:updateProjectiles(dt, player, enemies, effects, spawnEnemyFunc)
  end, 0.003)


  if self.behavior ~= "webber" then
    profileSection("Enemy: Additional Behavior", function()
      if self.behavior == "aggressive" then
        self:chaseNearestCharacter(dt, player, effects, sounds, summonedEntities, enemies)
      elseif self.behavior == "ranged" then
        self:rangedAttack(dt, player)
      end
    end, 0.003)
  end

  if self:getCollisionLayer() == "Normal" then
    profileSection("Enemy: Separation Calculation", function()
      local sepX, sepY = self:calculateSeparation(enemies)
      local separationInfluence = 0.1
      self.vx = self.vx + sepX * separationInfluence
      self.vy = self.vy + sepY * separationInfluence
    end, 0.003)
  end

  profileSection("Enemy: Direction Update", function()
    local dx = self.x - (self.prevX or self.x)
    if dx > 0 then
      self.lastDirection = "right"
    elseif dx < 0 then
      self.lastDirection = "left"
    end
    self.prevX, self.prevY = self.x, self.y
  end, 0.003)

  profileSection("Enemy: Speed Capping", function()
    local maxSpeed = 300
    local currentSpeed = math.sqrt(self.vx * self.vx + self.vy * self.vy)
    if currentSpeed > maxSpeed then
      self.vx = (self.vx / currentSpeed) * maxSpeed
      self.vy = (self.vy / currentSpeed) * maxSpeed
    end
  end, 0.003)

  profileSection("Enemy: Movement Collision", function()
    local candidateX = self.x + self.vx * dt
    local candidateY = self.y + self.vy * dt
    if currentLevel and currentLevel.objects then
      local blocked = false
      for _, obj in ipairs(currentLevel.objects) do
        local width = self.radius * 2
        local height = self.radius * 2
        if Collision.checkObjectCollision(obj, candidateX, candidateY, width, height) then
          blocked = true
          break
        end
      end
      if not blocked then
        self.x = candidateX
        self.y = candidateY
      end
    else
      self.x = candidateX
      self.y = candidateY
    end
  end, 0.003)

  local elapsed = getTime() - startTime
  if elapsed > 0.001 then
    print(string.format("[PROFILE] Enemy:update (%s) took %.5f seconds", self.type, elapsed))
  end
end



function Enemy:move(dt, player)
    if self.x and self.y and player.x and player.y then
        -- Calculate the direction from the enemy to the player.
        local dx = player.x - self.x
        local dy = player.y - self.y

        -- Calculate the distance to the player.
        local distance = math.sqrt(dx * dx + dy * dy)

        -- Always set angleToTarget (even if not moving).
        self.angleToTarget = math.atan2(dy, dx) or 0

        if distance > 0 then
            -- Calculate candidate new position toward the player.
            local candidateX = self.x + (dx / distance) * self.speed * dt
            local candidateY = self.y + (dy / distance) * self.speed * dt

            if currentLevel then
                local blocked = false

                -- Check collision with static objects.
                if currentLevel.objects then
                    for _, obj in ipairs(currentLevel.objects) do
                        local width = self.radius * 2
                        local height = self.radius * 2
                        if Collision.checkObjectCollision(obj, candidateX, candidateY, width, height) then
                            blocked = true
                            break
                        end
                    end
                end

                -- Check collision with trees.
                if not blocked and currentLevel.trees then
                    for _, tree in ipairs(currentLevel.trees) do
                        -- Use tree width/height (or fallback to collisionData if available).
                        local treeWidth = tree.width or (tree.collisionData and tree.collisionData.w) or (tree.image and tree.image:getWidth()) or 0
                        local treeHeight = tree.height or (tree.collisionData and tree.collisionData.h) or (tree.image and tree.image:getHeight()) or 0
                        if Collision.checkObjectCollision(tree, candidateX, candidateY, self.radius * 2, self.radius * 2) then
                            blocked = true
                            break
                        end
                    end
                end

                if not blocked then
                    self.x = candidateX
                    self.y = candidateY
                end
            else
                self.x = candidateX
                self.y = candidateY
            end
        end
    end
end

function Enemy:moveTowardsPlayer(dt, player)
    local _, closestChar = self:getDistanceToPlayer(player)
    if closestChar then
        local dx = closestChar.x - self.x
        local dy = closestChar.y - self.y
        local distance = math.sqrt(dx^2 + dy^2)
        if distance > 0 then
            local dirX = dx / distance
            local dirY = dy / distance
           self.vx = dirX * self.speed
self.vy = dirY * self.speed

        end
    end
end

function Enemy:performMeleeAttack(dt, player, effects, sounds, summonedEntities)
    effects = effects or {}
    
    -- Only proceed if in ATTACK state
    if self.state ~= STATES.ATTACK then
        return
    end

    local meleeRange = self.meleeRange or 40

    -- Validate player data
    if not player or not player.characters or player:isDefeated() then
        return
    end

    -- Find the closest character among player characters
    local closestCharacter, closestDistance = nil, math.huge
    for _, char in pairs(player.characters) do
        local dx = char.x - self.x
        local dy = char.y - self.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < closestDistance then
            closestCharacter = char
            closestDistance = dist
        end
    end

    if not closestCharacter then 
        return 
    end

    if closestDistance <= meleeRange then
        -- If in melee range, start (or continue) wind‑up
        if not self.windUpTimer then
            self.windUpTimer = 0.5  -- 0.5-second wind‑up delay
            self.originalSpeedWindup = self.speed
            self.speed = self.speed * 0.3  -- slow down to 30%
            return  -- Wait until wind‑up timer finishes
        else
            self.windUpTimer = self.windUpTimer - dt
            if self.windUpTimer > 0 then
                return  -- Still in wind‑up phase; do not attack yet
            end
            -- Wind‑up complete: restore speed and clear timer
            self.speed = self.originalSpeedWindup or self.speed
            self.windUpTimer = nil
        end

        -- Check the attack cooldown
        if self.attackTimer < (1 / self.attackSpeed) then
            return
        end
        self.attackTimer = 0

        -- Execute the attack
        player:takeDamage(self.damage)
        closestCharacter.damageFlashTimer = 0.1
        local slashEffect = Effects.new("slash", closestCharacter.x, closestCharacter.y, self.x, self.y, nil, nil, effects)
        table.insert(effects, slashEffect)
        if sounds and sounds.enemyAttack and sounds.enemyAttack.slash then
            sounds.enemyAttack.slash:play()
        end

        if self.type == "mimic" and self.slowCooldown <= 0 then
            local slowDuration = 2      -- slow effect lasts 2 seconds
            local slowValue = 0.75      -- 25% speed reduction
            player:applyStatusEffect(nil, "Slow", slowDuration, slowValue)
            self.slowCooldown = 5       -- Reset slow effect cooldown
        end
    else
        -- Not in melee range: ensure wind-up state is cleared and speed is restored
        self.windUpTimer = nil
        if self.originalSpeedWindup then
            self.speed = self.originalSpeedWindup
            self.originalSpeedWindup = nil
        end
    end
end


function Enemy:getCollisionLayer()
  if self.type == "Osskar" then
    return "Osskar"
  elseif self.type == "web" then
    return "Web"  -- Put webs on a separate layer
  elseif self.type == "kristoff" then
    return "Boss"
  end
  if self.isFrozen or self.isShocked or self.isStunned or (self.statusEffects and self.statusEffects["Fear"]) then
    return "CC"
  end
  return "Normal"
end

function Enemy:getCollisionData()
  if self.type == "kristoff" then
    -- tiny, centered hit‑circle
    local smallRadius = 12    -- adjust up/down as needed
    return self.x, self.y, smallRadius
  elseif self.type == "elite_spider" then
    local w, h = self.collisionWidth or 32, self.collisionHeight or 32
    local cx = self.x + w * 0.5
    local cy = self.y + h * 0.5
    local cr = math.sqrt((w*0.5)^2 + (h*0.5)^2)
    return cx, cy, cr
  else
    return self.x, self.y, self.radius
  end
end



function Enemy:getBottom()
  if self.type == "web" then
    return -10000  -- Always at the back
  end
  -- Use the spriteHeight for all other enemies.
  -- You can also include a collisionBottomOffset if you want a small adjustment.
  return self.y + (self.spriteHeight or 16) - (self.collisionBottomOffset or 0)
end











function Enemy:rangedAttack(dt, player)
    if self.state ~= STATES.ATTACK then
        return  -- Only perform ranged attacks in ATTACK state
    end
    
    local distanceToPlayer, closestChar = self:getDistanceToPlayer(player)
    if not closestChar then return end  -- Exit if no valid target

    -- Define behavior thresholds
    local safeDistance = 150  -- Distance to start running away
    local attackRange = self.attackRange or 200  -- Range to attack

    if distanceToPlayer <= safeDistance then
        if self.type == "mage_enemy" then
            self:teleportAwayFromPlayer(closestChar)
        else
            -- Run away logic
            self:runAwayFromPlayer(dt, closestChar)
        end
    elseif distanceToPlayer > attackRange then
        -- Move into range to attack
        self:moveTowardsTarget(dt, closestChar, attackRange - 10)
    else
        -- Attack logic
        if self.attackTimer >= (1 / self.attackSpeed) then
            self.attackTimer = 0  -- Reset attack timer after attacking

            -- Create the spit projectile without statusEffect
            local proj = EnemyProjectile:new(self.x, self.y, closestChar.x, closestChar.y, self.damage, {
                attackRange = attackRange,
                speed = 200,
                radius = 5,
                -- statusEffect = nil,  -- Removed or set to a default value if needed
            })
            table.insert(self.projectiles, proj)
        end
    end

    -- Update projectiles
    self:updateProjectiles(dt, player)
end




function Enemy:runAwayFromPlayer(dt, player)
    local dx = self.x - player.x
    local dy = self.y - player.y
    local distance = math.sqrt(dx * dx + dy * dy)

    if distance < self.safeDistance then  -- Ensure Webber runs only if too close
        local runSpeed = self.speed * (self.runSpeedMultiplier or 1.5)
        local dirX = dx / distance
        local dirY = dy / distance

        -- Set velocities to flee
        self.vx = dirX * runSpeed
        self.vy = dirY * runSpeed
    else
        -- Optionally, stop fleeing if not too close
        self.vx = 0
        self.vy = 0
    end
end







function Enemy:moveTowardsTarget(dt, target, stopDistance)
    local dx = target.x - self.x
    local dy = target.y - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance > stopDistance then
        local dirX = dx / distance
        local dirY = dy / distance
        self.vx = dirX * self.speed
        self.vy = dirY * self.speed
    else
        -- Optionally, stop moving if within stopDistance
        self.vx = 0
        self.vy = 0
    end
end



function Enemy:teleportAwayFromPlayer(player)
    local teleportDistance = 200
    local angle = math.random() * 2 * math.pi
    local dx = math.cos(angle) * teleportDistance
    local dy = math.sin(angle) * teleportDistance

    -- Update positions without clamping
    self.x = self.x + dx
    self.y = self.y + dy
    
end

function Enemy:performRetreatBehavior(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities)
    -- Utilize the existing runAwayFromPlayer method
    self:runAwayFromPlayer(dt, player)

    -- Additional retreat-specific behaviors
    if self.webCooldown <= 0 then
        self:dropWeb(effects, enemies, sounds, spawnEnemyFunc)
        self.webCooldown = 10  -- Reset cooldown after dropping a web
    end
end



function Enemy:updateProjectiles(dt, player, enemies, effects, spawnEnemyFunc) -- <<< Add spawnEnemyFunc argument
    if not self.projectiles then 
        return 
    end

    local liveProjectiles = {}
    for i = 1, #self.projectiles do
        local proj = self.projectiles[i]
        
        if proj.type == "webbomb" then
            if proj.animation then
                proj.animation:update(dt)
            end
            proj.age = proj.age + dt
            proj.vy = proj.vy + proj.gravity * dt
            proj.x = proj.x + proj.vx * dt
            proj.y = proj.y + proj.vy * dt

            if player and player.characters then
                for _, char in pairs(player.characters) do
                    local dx = char.x - proj.x
                    local dy = char.y - proj.y
                    local radSum = proj.radius + char.radius
                    if (dx * dx + dy * dy) <= (radSum * radSum) then
                        proj.isDead = true
                        break
                    end
                end
            end

            if proj.age < proj.lifetime and not proj.isDead then
                table.insert(liveProjectiles, proj)
            else
                -- Use the passed spawnEnemyFunc (EnemyPool.acquire)
                if spawnEnemyFunc then
                    for _ = 1, 5 do
                        local angle = random() * 2 * math.pi
                        local spawnVx = cos(angle) * 100
                        local spawnVy = sin(angle) * 100
                        -- Use spawnEnemyFunc here
                        local skitter = spawnEnemyFunc("skitter_spider", proj.x, proj.y, 1, nil)
                        skitter.vx = spawnVx
                        skitter.vy = spawnVy
                        table.insert(enemies, skitter)
                    end
                end
                table.insert(effects, Effects.new("explosion", proj.x, proj.y))
            end

        else
            local dx = proj.targetX - proj.x
            local dy = proj.targetY - proj.y
            local distSq = dx * dx + dy * dy
            if distSq < 4 then
                proj.isDead = true
            else
                local invS = proj.speed / sqrt(distSq)
                proj.x = proj.x + dx * invS * dt
                proj.y = proj.y + dy * invS * dt
            end

            if not proj.isDead then
                table.insert(liveProjectiles, proj)
            end
        end
    end
    self.projectiles = liveProjectiles
end


function Enemy:getDistanceToPlayer(player)
  if not player or not player.characters then
    return math.huge, nil
  end
  local closestDistanceSq = math.huge
  local closestChar = nil
  for _, char in pairs(player.characters) do
    if not player:isDefeated() then
      local dx = char.x - self.x
      local dy = char.y - self.y
      local distSq = dx * dx + dy * dy
      if distSq < closestDistanceSq then
        closestDistanceSq = distSq
        closestChar = char
      end
    end
  end
  return sqrt(closestDistanceSq), closestChar
end





function Enemy:chaseNearestCharacter(dt, player, effects, sounds, summonedEntities)
    local distance, closestChar = self:getDistanceToPlayer(player)
    if closestChar then
        local dx = closestChar.x - self.x
        local dy = closestChar.y - self.y
        local distSq = dx * dx + dy * dy
        if distSq > 0 then
            local invDist = 1 / sqrt(distSq)
            self.vx = dx * invDist * self.speed
            self.vy = dy * invDist * self.speed
        else
            self.vx, self.vy = 0, 0
        end

        local candidateX = self.x + self.vx * dt
        local candidateY = self.y + self.vy * dt

        local blocked = false
        if currentLevel then
            if currentLevel.objects then
                for _, obj in ipairs(currentLevel.objects) do
                    local width = self.radius * 2
                    local height = self.radius * 2
                    if Collision.checkObjectCollision(obj, candidateX, candidateY, width, height) then
                        blocked = true
                        break
                    end
                end
            end
            if not blocked and currentLevel.trees then
                for _, tree in ipairs(currentLevel.trees) do
                    if Collision.checkObjectCollision(tree, candidateX, candidateY, self.radius * 2, self.radius * 2) then
                        blocked = true
                        break
                    end
                end
            end
        end

        if not blocked then
            self.x = candidateX
            self.y = candidateY
        end
    end
end



-- Attack logic
function Enemy:attack(target, dt)
    self.attackTimer = (self.attackTimer or 0) + dt
    local attackSpeed = 1
    if self.attackTimer >= 1 / attackSpeed then
        self.attackTimer = 0
        local damage = 10
    
       if target.takeDamage then
    target:takeDamage(damage)
else
    target.health = target.health - damage
    if target.health < 0 then target.health = 0 end
end
    end
end

-- Find the nearest character (player)
function Enemy:findNearestCharacter(player)
    if not player then
      
      
        return nil
    end

    if not player.characters or type(player.characters) ~= "table" then
      
   
        return nil
    end

    local nearestChar = nil
    local minDistanceSquared = math.huge

    for _, char in pairs(player.characters) do
        if not player:isDefeated() then
            local dx = char.x - self.x
            local dy = char.y - self.y
            local distanceSquared = dx * dx + dy * dy
            if distanceSquared < minDistanceSquared then
                minDistanceSquared = distanceSquared
                nearestChar = char
            end
        end
    end

    return nearestChar
end





function Enemy:takeDamage(damage, damageNumbers, effects, sourceType, sourceCharacter, attackType, isCrit, enemies, sounds, summonedEntities, spawnEnemyFunc)
  if damage <= 0 then
    return
  end

  if self.spawnState == "dormant" then
    self.spawnState = "active"
  end

  if self.type == "kristoff" and BossAbilities.checkKristoffInvulnerability(self) then
    return
  end

  -- 1. Safety / initialization
  effects = effects or {}
  self.timers = self.timers or {}

  if not self.targetable then
    return -- Ignore damage if not targetable
  end

  if self.isHit then
    return -- Skip if recently hit (invulnerability frames)
  end
  self.isHit = true

  -- 2. Reduce health and trigger damage effects
  self.health = self.health - damage
  self.flashTimer = 0.1
  self:emitDamageParticles()

  -- Example snippet for skitter spider behavior
  if self.type == "skitter_spider" and not self.isDead then
    self.skitterState = "attack"
  end

  local colorMap = {
    Grimreaper       = {0.6, 0.4, 0.8, 1},  -- Purple/blue for Grimreaper abilities
    Emberfiend       = {1, 0.6, 0.2, 1},      -- Orange for Emberfiend abilities
    Stormlich        = {1, 1, 0, 1},          -- Yellow for Stormlich abilities
    poison           = {0, 1, 0, 1},          -- Green for poison ticks
    ignite           = {1, 0, 0, 1},          -- Red for ignite damage
    blood_explosion  = {0.5, 0, 0, 1},        -- Dark red for blood explosions
    necrotic_burst   = {0.7, 0.5, 1, 1},        -- Lavender/purple (example)
    chest_ignition   = {1, 0.5, 0, 1},        -- Orange (or any color you choose)
    explosion        = {1, 0.6, 0.2, 1},
  }
  local color = colorMap[sourceType] or {1, 1, 1}
  if addDamageNumber then
    addDamageNumber(self.x, self.y, damage, color, isCrit)
  end

  -- 3. Death handling logic
  if self.health <= 0 then
    self.activeParticles = {}  -- Clear any lingering particles
    if self.type == "kristoff" then
      -- Kristoff death logic remains unchanged (his death animation will play)
    elseif self.type == "spider" or self.type == "skitter_spider" or 
           self.type == "webber" or self.type == "elite_spider" or 
           self.type == "spiderv2" then
      if self.type == "elite_spider" then
        if _G.randomItems then
          _G.randomItems:spawnRewardChest(self.x, self.y)
        end
      end
      -- Trigger blood-spray particles on death
      table.insert(effects, Effects.new("disintegration_effect", self.x, self.y))
      self.isDead = true
      self.remove = true
    else
      self.isDead = true
      table.insert(effects, Effects.new("disintegration_effect", self.x, self.y))
      self.remove = true
    end
  end


 

  -------------------------------------------------------------------
  -- *** Sanguine Frenzy Autoattack Kill Trigger ***
  -------------------------------------------------------------------
  local frenzyOwner
  if sourceCharacter and sourceCharacter.hasSanguineFrenzy then
    frenzyOwner = sourceCharacter
  elseif sourceCharacter and sourceCharacter.owner and sourceCharacter.owner.hasSanguineFrenzy then
    frenzyOwner = sourceCharacter.owner
  end

  if frenzyOwner and (attackType == "attack" or attackType == "projectile") and (not frenzyOwner.sanguineFrenzyCooldown) then
    frenzyOwner.sanguineFrenzyCooldown = true
    frenzyOwner.sanguineFrenzyCooldownTimer = 5  -- Set cooldown timer to 5 seconds

    local radius    = 80
    local damageAoE = 30
    Abilities.sanguineFrenzyExplosion(self.x, self.y, radius, damageAoE, 
      effects, frenzyOwner, damageNumbers, enemies, sounds)
  end
  -------------------------------------------------------------------
  -- *** End Sanguine Frenzy Block ***
  -------------------------------------------------------------------

  -- 5. Schedule unsetting self.isHit
  table.insert(self.timers, {
    timeLeft = 0.1,
    action = function()
      self.isHit = false
    end
  })

  -- 6. Apply other onHit effects
  if effects and sourceType then
    Abilities.applyEffects(self, self, sourceType, enemies, effects, sounds, summonedEntities, damageNumbers)
  end
  if sourceCharacter and attackType == "attack" then
    Abilities.applyEffects(self, self, sourceCharacter, enemies, effects, sounds, summonedEntities, damageNumbers, attackType)
  end

  -- 7. Boss logic for Osskar
  if self.type == "Osskar" and not self.clonesSpawned and not self.isClone then
    if self.health <= (self.maxHealth * 0.35) then
      self.clonesSpawned = true
      self:startOsskarClonePhase(enemies, effects, spawnEnemyFunc)
      if not self.isEnraged then
        self.isEnraged = true
        self.speed     = self.speed     * 2
        self.dashSpeed = self.dashSpeed * 2
      end
    end
  end
end


-- Apply freeze effect to the enemy
function Enemy:applyFreeze(duration)
    self.statusEffects["Frozen"] = { duration = duration, timer = 0 }
    self.isFrozen = true
end


function Enemy:drawProjectiles()
    if not self.projectiles then return end
    for _, proj in ipairs(self.projectiles) do
        if proj.type == "webbomb" then
    
    Sprites.drawWebBomb(proj.x, proj.y, proj.animation)
     elseif proj.type == "spiderspit" then
    local flashColors = {
        {1, 0, 0},   -- red
        {0, 1, 0},   -- green
        {0, 0, 1},   -- blue
        {1, 1, 0},   -- yellow
        {1, 0, 1},   -- magenta
        {0, 1, 1},   -- cyan
    }
    local t = love.timer.getTime()
    local colorIndex = math.floor((t*5 + proj.x + proj.y) % #flashColors) + 1
    love.graphics.setColor(flashColors[colorIndex])
    love.graphics.circle("fill", proj.x, proj.y, proj.radius)
    love.graphics.setColor(1,1,1)

end
    end
end


function Enemy:updateParticles(dt)
  
    if self.isDying then
  if self.type == "kristoff" then
      self.deathAnimation:update(dt)
      self.deathAnimationTimer = self.deathAnimationTimer + dt
      local totalDuration = self.deathAnimation.numFrames * self.deathAnimation.frameDuration
      if self.deathAnimationTimer >= totalDuration then
        self.isDead = true
        self.remove = true
      end
      return  -- Continue death animation for Kristoff
  else
      self.isDead = true
      self.remove = true
      return
  end
end


    self.activeParticles = self.activeParticles or {}  -- Ensure it’s initialized

    for i = #self.activeParticles, 1, -1 do
        local p = self.activeParticles[i]

        if p.age == nil then
            p.age = 0
           
        end

        if p.lifetime == nil then
            p.lifetime = 1  -- Assign a default lifetime
          
        end

        p.age = p.age + dt

        if p.age >= p.lifetime then
            table.remove(self.activeParticles, i)
        else
            -- Update position
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt

            -- Optional: Apply friction to slow down over time
            local friction = 0.98
            p.vx = p.vx * friction
            p.vy = p.vy * friction

            -- Specific behavior based on particle type
            if p.type == "disintegration" then
                -- Gradually fade out disintegration particles
                local fadeFactor = 1 - (p.age / p.lifetime)
                p.color[4] = fadeFactor  -- Adjust alpha for fading
            end
            -- No special behavior needed for damage particles
        end
    end
end

-- Draw particles function
function Enemy:drawParticles()
    for _, p in ipairs(self.activeParticles) do
        local alpha = 1 - (p.age / p.lifetime)  -- General fade out
        if p.type == "disintegration" then
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.color[4] or alpha)
      
            elseif p.type == "damage" then
    love.graphics.setColor(173/255, 64/255, 48/255, alpha)  -- rustRed from palette

        end
        love.graphics.circle("fill", p.x, p.y, p.size * 0.25)
    end
    love.graphics.setColor(1, 1, 1)  -- Reset color to default
end

-- Main draw function for the enemy (with sprite flipping based on angle)
function Enemy:draw()
    self:drawParticles()
    if self.isDead then
        return
    end

  if self.isDying then
  if self.type == "kristoff" then
      local scaleX = (self.lastDirection == "left") and -2 or 2
      local scaleY = 2
      love.graphics.push()
      love.graphics.setColor(1,1,1,1)
      local quad = self.deathAnimation:getCurrentQuad()
      love.graphics.draw(Sprites.kristoffDeathSheet, quad, self.x, self.y, 0, scaleX, scaleY, 8, 8)
      love.graphics.pop()
      return
  else
      return  -- For all other enemy types, do not display a death animation.
  end
end



    if not self.radius then
        self.radius = DEFAULT_RADIUS
    end

    local scaleX = (self.lastDirection == "left") and -2 or 2
    local scaleY = 2

    love.graphics.push()

    if self.statusEffects["Fear"] and self.fearFlashState then
        love.graphics.setColor(self.colors.dustyLavender[1], self.colors.dustyLavender[2], self.colors.dustyLavender[3], 1)
    else
        if self.statusEffects["Frozen"] then
            love.graphics.setColor(self.colors.smokyBlue[1], self.colors.smokyBlue[2], self.colors.smokyBlue[3], 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end

        if self.flashTimer > 0 then
            love.graphics.setColor(self.colors.darkRose[1], self.colors.darkRose[2], self.colors.darkRose[3], 1)
        end
    end

    if self.type == "elite_spider" then
        local scaleX = 2
        if self.x < (self.prevX or self.x) then scaleX = -2 end
        if self.flashingColor then
            love.graphics.setColor(self.flashingColor)
        end
        Sprites.drawEliteSpider(self.x, self.y, false, scaleX)
        love.graphics.setColor(1,1,1)
        self:drawProjectiles()
        love.graphics.pop()
        return

    elseif self.type == "mimic" then
        Sprites.drawMimic(self.x, self.y, true, scaleX, 0)
        self:drawProjectiles()
        love.graphics.pop()
        return

    elseif self.type == "kristoff" then
        if self.behavior == "invulnerable" then
            love.graphics.setColor(1,1,1,1)
            Sprites.drawKristoffInvulnerable(self.x, self.y, scaleX, scaleY)
        else
            love.graphics.setColor(1,1,1,1)
            Sprites.drawKristoff(self.x, self.y, scaleX, scaleY)
        end
        if self.webLunge then
            BossAbilities.drawWebLunge(self.webLunge, self)
        end

    elseif self.type == "spiderv2" then
        Sprites.drawspiderv2(self.x, self.y, true, scaleX)
    elseif self.type == "spider" then
        Sprites.drawspider(self.x, self.y, true, scaleX)
    elseif self.type == "beholder" then
        Sprites.drawBeholder(self.x, self.y, true, scaleX)
    elseif self.type == "bat" then
        love.graphics.circle("fill", self.x, self.y, self.radius)
    elseif self.type == "spirit" then
        Sprites.drawSpirit(self.x, self.y, true, scaleX)
    elseif self.type == "Osskar" then
        Sprites.drawOsskar(self.x, self.y, scaleX, scaleY)
    elseif self.type == "skitter_spider" then
        Sprites.drawSkitterer(self.x, self.y, (self.lastDirection=="left") and -1 or 1)
    elseif self.type == "pumpkin" then
        Sprites.drawPumpkin(self.x, self.y, true, scaleX)
    elseif self.type == "webber" then
        Sprites.drawWebber(self.x, self.y, self.webberState == STATES.ATTACK, scaleX)
    elseif self.type == "web" then
        Sprites.drawWeb(self.x, self.y, scaleX)
    else
        love.graphics.circle("fill", self.x, self.y, self.radius)
    end

    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
    self:drawPoisonParticles()

    if self.projectiles then
        self:drawProjectiles()
    end
end


function Enemy:drawShockEffect()
    if self.isShocked then
       love.graphics.setColor(142/255, 184/255, 158/255, 0.5)  -- pastelMint for shock effect

        love.graphics.circle("fill", self.x, self.y, self.radius + 5)  -- Shock aura effect
        love.graphics.setColor(1, 1, 1)  -- Reset to default color
    end
end


function Enemy:drawPoisonParticles()
    -- Check if the enemy is poisoned
    if self.statusEffects["Poison"] then
        love.graphics.setColor(149/255, 182/255, 102/255, 0.8)  -- mutedOliveGreen with 60% opacity

        -- Draw a few random poison "drips" around the enemy
        for i = 1, 2 do  -- Reduced number of drips from 3 to 2
            local offsetX = math.random(-self.radius * 0.5, self.radius * 0.5)  -- Reduced offset range
            local offsetY = math.random(-self.radius * 0.5, self.radius * 0.5)  -- Reduced offset range
            love.graphics.circle("fill", self.x + offsetX, self.y + offsetY, math.random(1, 3))  -- Smaller drips
        end

        love.graphics.setColor(1, 1, 1)  -- Reset color to white after drawing
    end
end


function Enemy:calculateSeparation(neighbors)
    local desiredSeparation = 20
    local steerX, steerY = 0, 0
    local count = 0

    for _, other in ipairs(neighbors) do
        -- Ensure `other` is valid, not self, and has a valid health attribute
        if other and other ~= self and type(other.health) == "number" and other.health > 0 then
            local myLayer = self:getCollisionLayer()
            local otherLayer = other:getCollisionLayer()

            if myLayer == "Normal" and otherLayer == "Normal" then
                local dx = (self.x or 0) - (other.x or 0)
                local dy = (self.y or 0) - (other.y or 0)
                local distance = math.sqrt(dx * dx + dy * dy)

            if distance > 0 and distance < desiredSeparation then
    dx = dx / distance  -- Normalize
    dy = dy / distance
    dx = dx / distance  -- Smooth
    dy = dy / distance
    local speedFactor = 1
    if other.speed and self.speed > other.speed * 1.2 then
         speedFactor = 0.5
    end
    steerX = steerX + dx * speedFactor
    steerY = steerY + dy * speedFactor
    count = count + 1
end

            end
        end
    end

    if count > 0 then
        steerX = steerX / count
        steerY = steerY / count
        local magnitude = math.sqrt(steerX * steerX + steerY * steerY)
        if magnitude > 0 then
            steerX = steerX / magnitude
            steerY = steerY / magnitude
        end
    end

    return steerX, steerY
end


function Enemy:emitDamageParticles()
    local numParticles = 20  -- Number of particles to emit
    for i = 1, numParticles do
        local angle = math.random() * 2 * math.pi
        local speed = math.random(100, 200)
        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed
        local particle = {
            x = self.x,
            y = self.y,
            vx = vx,
            vy = vy,
            lifetime = 0.5,
            age = 0,
            size = math.random(2, 4),
            type = "damage",  -- Specify the particle type
            color = {173/255, 64/255, 48/255, 1}  -- rustRed for damage particles

        }
        table.insert(self.activeParticles, particle)
    end
end


function Enemy:emitDisintegrationParticles()
    local numFragments = 40 -- Number of particles to emit
    local direction = self.lastDirection == "left" and 1 or -1  -- Determine direction (1 for right, -1 for left)

    for i = 1, numFragments do
        -- Add a bias to the angle to create a backward effect
        local angleBias = math.pi * (direction == 1 and 0 or 1) -- 0 for right, π for left
        local spread = math.pi / 4  -- Adjust spread of particles
        local angle = angleBias + math.random() * spread - (spread / 2)

        local speed = math.random(100, 300)
        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed

        -- Particle properties
        local particle = {
            x = self.x,
            y = self.y,
            vx = vx,
            vy = vy,
            lifetime = math.random(0.5, 1),
            age = 0,
            size = math.random(4, 8),
            type = "disintegration",  -- Specify the particle type
            color = {173/255, 64/255, 48/255, 1}
        }

        table.insert(self.activeParticles, particle)
    end
end


-- Update function for Beholder
function Enemy:updateBeholder(dt, player, effects, enemies, damageNumbers, sounds)
    -- Update attack timer
    self.attackTimer = self.attackTimer + dt

    -- Find the closest character
    local distanceToPlayer, closestChar = self:getDistanceToPlayer(player)
    if not closestChar then return end

    -- Define safe and attack distances
    local safeDistance = 100  -- Reduced from 150 to allow players to get closer before fleeing
    local attackRange = self.attackRange or 500  -- Range to attack

    if self.attackState == "telegraphing" then
        -- Handle telegraphing state
        self.telegraphTimer = self.telegraphTimer + dt
       

        -- Prevent movement by setting velocities to 0
        self.vx = 0
        self.vy = 0

        if self.telegraphTimer >= self.telegraphDuration then
            -- Transition to attacking state
            self.attackState = "attacking"
            self.attackTimer = 0  -- Reset attack timer for attacking state
         

            -- Perform the actual magic ray attack
            self:performRayAttack(player, effects, enemies, damageNumbers, sounds)
        end

        -- Prevent movement during telegraphing
        return

    elseif self.attackState == "attacking" then
        -- Handle attacking state
        self.attackTimer = self.attackTimer + dt
    

        -- Prevent movement by setting velocities to 0
        self.vx = 0
        self.vy = 0

        if self.attackTimer >= self.rayDuration then
            -- Transition back to idle state after attack duration
            self.attackState = "idle"
            
        end

        -- Prevent movement during attacking
        return
    end

    -- Movement logic only when in idle state
    if distanceToPlayer <= safeDistance then
        -- Run away
        self:runAwayFromPlayer(dt, closestChar)
    elseif distanceToPlayer > attackRange then
        -- Move towards target
        self:moveTowardsTarget(dt, closestChar, attackRange - 10)
    else
        -- Within attack range
        if self.attackTimer >= self.rayCooldown then
            -- Transition to telegraphing state
            self.attackState = "telegraphing"
            self.telegraphTimer = 0
            self.attackTimer = 0  -- Reset attack timer
           

            -- Calculate the angle towards the player and determine the fixed end point
            local dx = closestChar.x - self.x
            local dy = closestChar.y - self.y
            local angle = math.atan2(dy, dx)
            self.storedRayAngle = angle  -- Store the angle for later use

            -- Define the ray's length
            local rayLength = 600

            -- Calculate and store the fixed end point
            self.storedRayEndX = self.x + math.cos(angle) * rayLength
            self.storedRayEndY = self.y + math.sin(angle) * rayLength

            -- Create the telegraph effect with the fixed end point
            table.insert(effects, Effects.new(
                "magic_ray_telegraph",
                self.x,
                self.y,
                self.storedRayEndX,
                self.storedRayEndY,
                nil,
                nil,
                effects
            ))

          
        end
    end

    -- Update projectiles (if any)
    self:updateProjectiles(dt, player)
end

-- Perform Ray Attack function remains mostly unchanged
function Enemy:performRayAttack(player, effects, enemies, damageNumbers, sounds)
    -- Use the stored end point; if not set, default to current player position
    if not self.storedRayEndX or not self.storedRayEndY then
        local distanceToPlayer, closestChar = self:getDistanceToPlayer(player)
        if not closestChar then return end

        local dx = closestChar.x - self.x
        local dy = closestChar.y - self.y
        local angle = math.atan2(dy, dx)
        local rayLength = 600

        self.storedRayEndX = self.x + math.cos(angle) * rayLength
        self.storedRayEndY = self.y + math.sin(angle) * rayLength
    end

    local endX = self.storedRayEndX
    local endY = self.storedRayEndY

    -- Play one of the Beholder attack sounds (50/50 chance)
    if sounds.enemyAttack and sounds.enemyAttack.beholder then
        local attackSounds = sounds.enemyAttack.beholder
        if attackSounds[1] and attackSounds[2] then
            if math.random() < 0.5 then
                attackSounds[1]:play()
            else
                attackSounds[2]:play()
            end
        end
    end

    -- Perform the magic ray attack
    for _, char in pairs(player.characters) do
        if not player:isDefeated() then
            local hit, point = Collision.lineCircle(self.x, self.y, endX, endY, char.x, char.y, char.radius)
           if hit then
    local damage = self.damage
    player:takeDamage(damage)
                if damageNumbers and damageNumbers.add then
                    damageNumbers.add(char.x, char.y, damage, {1, 0, 0})
                end

                table.insert(effects, Effects.new("magic_ray_hit", char.x, char.y))
               
            end
        end
    end

    table.insert(effects, Effects.new("magic_ray", self.x, self.y, endX, endY))
    

    -- Clear stored ray endpoints
    self.storedRayEndX = nil
    self.storedRayEndY = nil
    self.storedRayAngle = nil
end


function Enemy:updateOsskarDash(dt, player, effects, damageNumbers, sounds)
    -- Ensure all parameters are tables
    effects = effects or {}
    damageNumbers = damageNumbers or {}
    sounds = sounds or {}

    -- If dashing
    if self.isDashing then
        -- Set radius to 0 if not already done
        if self.radius ~= 0 then
            self.savedRadius = self.radius
            self.radius = 0
        end

        -- Dash movement logic
        self.x = self.x + self.dashDirectionX * self.dashSpeed * dt
        self.y = self.y + self.dashDirectionY * self.dashSpeed * dt
        self:spawnDashTrail()

        self.dashDistance = self.dashDistance - (self.dashSpeed * dt)
        if self.dashDistance <= 0 then
            self.isDashing = false
            self.speed = self.originalSpeed
            self.dashDistance = 300

            -- Restore radius after dash
            if self.savedRadius then
                self.radius = self.savedRadius
                self.savedRadius = nil
            end
        end

        -- Check collision with player during dash
        if player and player.characters and type(player.characters) == "table" then
            for _, char in pairs(player.characters) do
                if not player:isDefeated() then
                    local dx = char.x - self.x
                    local dy = char.y - self.y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if dist < (self.radius + char.radius) then
                        player:takeDamage(self.dashDamage)
                    end

                    if damageNumbers and addDamageNumber then
                        addDamageNumber(char.x, char.y, self.dashDamage, {1, 0, 0})
                    end

                    if effects then
                        table.insert(effects, Effects.new("magic_ray_hit", char.x, char.y))
                    end

                    -- End dash after hitting a player
                    self.isDashing = false
                    self.speed = self.originalSpeed
                    self.dashDistance = 300

                    -- Restore radius after dash
                    if self.savedRadius then
                        self.radius = self.savedRadius
                        self.savedRadius = nil
                    end
                    break
                end
            end
        end

        return
    end

    -- If telegraphing dash
    if self.isTelegraphingDash then
        self.dashTelegraphTimer = self.dashTelegraphTimer + dt
        if not self.savedSpeedForTelegraph then
            -- Store current speed and set to 0 so Osskar doesn't move
            self.savedSpeedForTelegraph = self.speed
            self.speed = 0
        end

        if self.dashTelegraphTimer >= self.dashTelegraphDuration then
            -- Start dash
            self.isTelegraphingDash = false
            self.dashTelegraphTimer = 0
            self.isDashing = true
            -- Radius will be set to 0 in the dashing block above
        else
            -- Spawn telegraph effect once
            if not self.dashTelegraphEffectSpawned then
                local dashEndX = self.x + self.dashDirectionX * self.dashDistance
                local dashEndY = self.y + self.dashDirectionY * self.dashDistance
                table.insert(effects, Effects.new("osskar_dash_telegraph", self.x, self.y, dashEndX, dashEndY))
                self.dashTelegraphEffectSpawned = true
            end
        end
        return
    end

    -- Normal behavior (not telegraphing, not dashing)
    -- If we were telegraphing and didn't dash, restore the original speed
    if self.savedSpeedForTelegraph and not self.isTelegraphingDash and not self.isDashing then
        self.speed = self.savedSpeedForTelegraph
        self.savedSpeedForTelegraph = nil
    end

    self.dashTimer = self.dashTimer + dt
    if self.dashTimer >= self.dashCooldown then
        local dist, closestChar = self:getDistanceToPlayer(player)
        if closestChar and dist < 300 then
            self.isTelegraphingDash = true
            self.dashTimer = 0
            self.dashTelegraphEffectSpawned = false

            local dx = closestChar.x - self.x
            local dy = closestChar.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance > 0 then
                self.dashDirectionX = dx / distance
                self.dashDirectionY = dy / distance
            end
        end
    end
end


function Enemy:spawnDashTrail()
    -- Calculate opposite direction for trail
    local angle = math.atan2(self.dashDirectionY, self.dashDirectionX) + math.pi
    local speed = 50
    local vx = math.cos(angle) * speed
    local vy = math.sin(angle) * speed

    -- Define Osskar's Trail Colors using game palette
    local colors = {
        self.colors.rustRed,   -- rustRed
        self.colors.orangeGold -- orangeGold
    }
    local color = colors[math.random(#colors)]

    -- Create Particle with larger size
    local particle = {
        x = self.x,
        y = self.y,
        vx = vx,
        vy = vy,
        lifetime = 0.4,  -- Short-lived
        age = 0,
        size = math.random(5, 10),  -- Larger particles
        type = "dash_trail",
        color = color
    }
    table.insert(self.activeParticles, particle)
end

function Enemy:startOsskarClonePhase(enemies, effects, spawnEnemyFunc)
    self.color = {1,1,1}
    local offsets = {
        {x=30,y=0},
        {x=-30,y=0},
        {x=0,y=30}
    }

    for i, offset in ipairs(offsets) do
        -- Use the passed spawnEnemyFunc
        local clone = spawnEnemyFunc("Osskar", self.x + offset.x, self.y + offset.y)
        clone.isClone = true  -- Mark this enemy as a clone
        -- ... (rest of clone setup) ...
        table.insert(enemies, clone)
    end

    if effects then
        table.insert(effects, Effects.new("summon", self.x, self.y))
    end
end

function Enemy:updateEliteSpider(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities)
    -- Initialize timers on first run if needed
    self.spreadTimer = self.spreadTimer or 0          -- counts total time toward the 20-second cycle
    self.spreadChargeTimer = self.spreadChargeTimer or 5  -- 5-second “charge” period
    self.buffTimer = self.buffTimer or 20              -- timer for periodic speed buff
    self.buffDuration = self.buffDuration or 0         -- how long the buff remains active

    -- Increase the spreadTimer by dt
    self.spreadTimer = self.spreadTimer + dt

    if self.spreadTimer >= 20 then
    -- Enter spread attack sequence: 5 rounds with 2-second intervals
    self.vx, self.vy = 0, 0  -- Stop movement
    -- Flash color effect during spread attack
    local flashColors = {
        {1, 0, 0},   -- red
        {0, 1, 0},   -- green
        {0, 0, 1},   -- blue
        {1, 1, 0},   -- yellow
        {1, 0, 1},   -- magenta
        {0, 1, 1}    -- cyan
    }
    local t = love.timer.getTime()
    local index = math.floor((t * 5) % #flashColors) + 1
    self.flashingColor = flashColors[index]
    
    if not self.spreadRoundsRemaining then
        self.spreadRoundsRemaining = 4    -- total rounds in the sequence
        self.spreadRoundCooldown = 2      -- cooldown (in seconds) before first shot
    else
        self.spreadRoundCooldown = self.spreadRoundCooldown - dt
        if self.spreadRoundCooldown <= 0 then
            -- Fire a three-shot spread
            self:shootProjectilePattern(player, effects, damageNumbers, sounds, 3)
            self.spreadRoundsRemaining = self.spreadRoundsRemaining - 1
            if self.spreadRoundsRemaining > 0 then
                self.spreadRoundCooldown = 2  -- reset cooldown for next round
            else
                -- End of spread sequence: reset timers
                self.spreadTimer = 0
                self.spreadRoundsRemaining = nil
                self.spreadRoundCooldown = nil
                self.storedTripleAngle = nil

            end
        end
    end
else
    self.flashingColor = nil
    self:chaseNearestCharacter(dt, player, effects, sounds, summonedEntities)
    
    self.buffTimer = self.buffTimer - dt
    if self.buffTimer <= 0 then
        self.speed = self.originalSpeed * 1.5
        self.buffDuration = 2
        self.buffTimer = 20
    end
    if self.buffDuration > 0 then
        self.buffDuration = self.buffDuration - dt
        if self.buffDuration <= 0 then
            self.speed = self.originalSpeed
        end
    end
end
  for _, other in ipairs(enemies) do
        if other.type == "spider" and not other.isDead then
            local dx = other.x - self.x
            local dy = other.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)
            local minDistance = self.radius + other.radius
            if distance < minDistance and distance > 0 then
                local pushForce = (minDistance - distance) * 50  -- Adjust force as needed
                local nx = dx / distance
                local ny = dy / distance
                other.x = other.x + nx * pushForce * dt
                other.y = other.y + ny * pushForce * dt
            end
        end
    end

    self:updateProjectiles(dt, player)
end

function Enemy:shootProjectilePattern(player, effects, damageNumbers, sounds, count)
   local distanceToPlayer, closestChar = self:getDistanceToPlayer(player)
   if not closestChar then return end
   local baseAngle = self.storedTripleAngle or math.atan2(closestChar.y - self.y, closestChar.x - self.x)
   self.storedTripleAngle = baseAngle

   local spread = math.rad(60)  -- total spread of 30 degrees
   local startAngle = baseAngle - spread/2
   local angleIncrement = (count > 1) and (spread / (count - 1)) or 0
   local projectileSpeed = 20  -- slow moving projectiles
   for i = 0, count - 1 do
       local angle = startAngle + i * angleIncrement
    local proj = EnemyProjectile:new(self.x, self.y,
    self.x + math.cos(angle)*1000, self.y + math.sin(angle)*1000, self.damage, {
      attackRange = 300,
      speed = projectileSpeed,
      radius = 5,
      color = {0, 1, 0},  -- adjust color as desired
      type  = "spiderspit",
      flashing = true,   -- flag to draw as flashing circle
})

       proj.rotation = angle
       proj.frameTimer = 0
       proj.currentFrame = 1
       table.insert(self.projectiles, proj)
   end
   if sounds and sounds.enemyAttack and sounds.enemyAttack.spider then
         sounds.enemyAttack.spider:play()
   end
end
------------------------------------------------------
-- The spit logic: create a "spiderspit" projectile
------------------------------------------------------
function Enemy:spitAtPlayer(player, effects, damageNumbers, sounds)
    local dist, closestChar = self:getDistanceToPlayer(player)
    if not closestChar then return end

    local dx = closestChar.x - self.x
    local dy = closestChar.y - self.y
    local distance = math.sqrt(dx*dx + dy*dy)
    if distance < 1 then distance = 1 end

    local speed = 75  -- Speed of spit projectile

    -- **Create the spit projectile with all necessary properties in config**
    local spitProj = EnemyProjectile:new(self.x, self.y, closestChar.x, closestChar.y, self.damage, {
        attackRange = 300,
        speed = speed,
        radius = 6,
        color = {0, 1, 0},  -- Green color
        type  = "spiderspit",
        frames = spitFrames,              -- Assign frames
        animationSpeed = spitAnimationSpeed,  -- Assign animation speed
    })

    -- **Initialize rotation based on movement direction**
    spitProj.rotation = math.atan2(dy, dx)

    -- **Initialize animation timers**
    spitProj.frameTimer = 0
    spitProj.currentFrame = 1

    -- Play spit sound
    if sounds and sounds.enemyAttack and sounds.enemyAttack.spider then
        sounds.enemyAttack.spider:play()
    end

    table.insert(self.projectiles, spitProj)
   
end


function Enemy:updateSkitterSpider(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities)
    -- If the skitter spider is in "attack" state, chase the player.
    if self.skitterState == "attack" then
        self:chaseNearestCharacter(dt, player, effects, sounds, summonedEntities)
        return
    end

    -- If no route is set, pick new route points near the player.
    if #self.route == 0 then
        local wanderRadius = 150  -- Adjust this value to control how close the wandering is to the player.
        local playerX, playerY = player.x, player.y
        local passX = playerX + math.random(-wanderRadius, wanderRadius)
        local passY = playerY + math.random(-wanderRadius, wanderRadius)
        local offX  = playerX + math.random(-wanderRadius, wanderRadius)
        local offY  = playerY + math.random(-wanderRadius, wanderRadius)
        self.route = {
            { x = passX, y = passY },
            { x = offX,  y = offY  }
        }
        self.currentWaypoint = 1
    end

    -- If currently pausing between route segments, count down.
    if self.pauseTimer and self.pauseTimer > 0 then
        self.pauseTimer = self.pauseTimer - dt
        if self.pauseTimer <= 0 then
            self.route = {}
        end
        return
    end

    -- Move toward the current waypoint.
    local wp = self.route[self.currentWaypoint]
    local dx = wp.x - self.x
    local dy = wp.y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 2 then
        local dirX = dx / dist
        local dirY = dy / dist
        self.vx = dirX * self.speed
        self.vy = dirY * self.speed
        self.x = self.x + self.vx * dt
        self.y = self.y + self.vy * dt
    else
        -- Reached current waypoint; move to next.
        self.currentWaypoint = self.currentWaypoint + 1
        if self.currentWaypoint > #self.route then
            self.pauseTimer = 2  -- Pause for 2 seconds before choosing a new route.
        end
    end
end


function Enemy:updateSpiderv2(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities)
    -- Update the dash attack timer (cooldown); if nil, default to 0.
    self.dashAttackTimer = (self.dashAttackTimer or 0) + dt

    local distance, closestChar = self:getDistanceToPlayer(player)

    if self.dashState == "idle" then
        -- If the player is within attack range and the cooldown is met, start the dash attack.
        if distance <= self.attackRange and self.dashAttackTimer >= self.dashAttackCooldown then
            self.dashState = "dashing"
            self.dashAttackTimer = 0
            -- Calculate dash direction toward the player.
            local dx = closestChar.x - self.x
            local dy = closestChar.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 0 then
                self.dashDirX = dx / dist
                self.dashDirY = dy / dist
            else
                self.dashDirX, self.dashDirY = 0, 0
            end
        else
            -- Otherwise, wander near the player with a fixed offset.
            if player then
                local offsetX = 30  -- horizontal offset from player
                local offsetY = 30  -- vertical offset from player
                local targetX = player.x + offsetX
                local targetY = player.y + offsetY
                local dx = targetX - self.x
                local dy = targetY - self.y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist > 1 then
                    self.vx = (dx / dist) * self.speed
                    self.vy = (dy / dist) * self.speed
                else
                    self.vx, self.vy = 0, 0
                end
                self.x = self.x + self.vx * dt
                self.y = self.y + self.vy * dt
            end
        end

    elseif self.dashState == "dashing" then
        -- Move quickly toward the player with a multiplier.
        self.x = self.x + self.dashDirX * self.dashSpeed * dt * 25
        self.y = self.y + self.dashDirY * self.dashSpeed * dt * 25
        self.dashDuration = self.dashDuration - dt
        if self.dashDuration <= 0 then
            if distance <= self.meleeRange then
                player:takeDamage(self.damage)
                table.insert(effects, Effects.new("goylebite", player.x, player.y, self.x, self.y, nil, nil, effects))
            end
            self.dashState = "retreating"
            self.dashDuration = 0.5  -- Reset duration for retreat phase.
            local angle = math.random() * 2 * math.pi
            self.retreatDirX = math.cos(angle)
            self.retreatDirY = math.sin(angle)
        end

    elseif self.dashState == "retreating" then
        -- Retreat with the same multiplier.
        self.x = self.x + self.retreatDirX * self.dashSpeed * dt * 25
        self.y = self.y + self.retreatDirY * self.dashSpeed * dt * 25
        self.dashDuration = self.dashDuration - dt
        if self.dashDuration <= 0 then
            self.dashState = "idle"
            self.dashDuration = 0.5  -- Reset for the next cycle.
        end
    end
end



function Enemy:updateWebber(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities, spawnEnemyFunc)
    -- Ensure cooldown timers are set and reduce them
    self.projectileCooldown = self.projectileCooldown or 0
    self.webCooldown = self.webCooldown or 0
    self.projectileCooldown = math.max(0, self.projectileCooldown - dt)
    self.webCooldown = math.max(0, self.webCooldown - dt)
    
    -- NEW: Apply the WebberLink negative link if within range and cooldown allows
    local distanceToPlayer, closestChar = self:getDistanceToPlayer(player)
  

   

    -- Continue with the existing webber behavior:
    if not closestChar then return end
    if distanceToPlayer > self.attackRange then
        self.webberState = STATES.ATTACK
    elseif distanceToPlayer <= self.safeDistance then
        self.webberState = STATES.RETREAT
    elseif self.webberState == STATES.RETREAT and distanceToPlayer > self.safeDistance then
        self.webberState = STATES.ATTACK
        self.projectileCooldown = 5
    end

    if self.webberState == STATES.ATTACK then
        self:moveTowardsTarget(dt, closestChar, self.attackRange - 10)
        if self.projectileCooldown == 0 then
            self:shootProjectileAtPlayer(player, effects, damageNumbers, sounds)
            self.projectileCooldown = 10
        end
    elseif self.webberState == STATES.RETREAT then
        self:runAwayFromPlayer(dt, closestChar)
        if self.webCooldown == 0 then
            self:dropWeb(effects, enemies, sounds, spawnEnemyFunc)
            self.webCooldown = 10
        end
    end
end


function Enemy:dropWeb(effects, enemies, sounds, spawnEnemyFunc)
    -- Ensure spawnEnemyFunc is valid before using
    if not spawnEnemyFunc then
        print("Warning: spawnEnemyFunc not provided to dropWeb")
        return
    end
    -- Use the passed spawnEnemyFunc
    local web = spawnEnemyFunc("web", self.x, self.y, 0, 0)  -- Parameters as needed
    table.insert(enemies, web)
end


function Enemy:getRandomOnScreen()
    local camX, camY = cameraX, cameraY
    local screenW    = love.graphics.getWidth()
    local screenH    = love.graphics.getHeight()
    
    local x = camX - screenW/2 + math.random(screenW)
    local y = camY - screenH/2 + math.random(screenH)
    return x, y
end

function Enemy:getRandomOffScreen()
    local camX, camY = cameraX, cameraY
    local screenW    = love.graphics.getWidth()
    local screenH    = love.graphics.getHeight()
    local buffer     = 100

    -- pick a random side (top, bottom, left, right)
    local side = math.random(4)
    if side == 1 then
        -- above
        return camX + math.random(-screenW/2, screenW/2),
               camY - screenH/2 - buffer
    elseif side == 2 then
        -- below
        return camX + math.random(-screenW/2, screenW/2),
               camY + screenH/2 + buffer
    elseif side == 3 then
        -- left
        return camX - screenW/2 - buffer,
               camY + math.random(-screenH/2, screenH/2)
    else
        -- right
        return camX + screenW/2 + buffer,
               camY + math.random(-screenH/2, screenH/2)
    end
end

function Enemy:shootProjectileAtPlayer(player, effects, damageNumbers, sounds)
    local distanceToPlayer, closestChar = self:getDistanceToPlayer(player)
    if not closestChar then return end

    -- Only shoot if within attackRange
    if distanceToPlayer > self.attackRange then
        return
    end

    local dx = closestChar.x - self.x
    local dy = closestChar.y - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance < 1 then distance = 1 end

    local speed = 35  -- Speed of Webber's projectile

    -- Create the projectile
   local projectile = EnemyProjectile:new(self.x, self.y, closestChar.x, closestChar.y, self.damage, {
    attackRange = self.attackRange,
    speed = speed,
    radius = 4,
    color = {0, 1, 0},  -- Green color
    type  = "spiderspit",
   
})
projectile.sourceEnemy = "webber"

    -- Initialize rotation based on movement direction
    projectile.rotation = math.atan2(dy, dx) or 0

    -- Initialize animation timers
    projectile.frameTimer = 0
    projectile.currentFrame = 1

    -- Play projectile firing sound
    if sounds and sounds.enemyAttack and sounds.enemyAttack.webber then
        sounds.enemyAttack.webber:play()
    end

    -- Add the projectile to the Webber's projectiles list
    table.insert(self.projectiles, projectile)
end






return Enemy