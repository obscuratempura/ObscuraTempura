local Collision = require("collision")
local Effects = require("effects")
local Abilities = require("abilities")
local DamageNumber = require("damage_number")
local EnemyProjectile = require("projectile")  -- or whatever file name contains the new EnemyProjectile
local Sprites = require("sprites")




local Enemy = {}
Enemy.__index = Enemy

-- Function to get a random enemy type
function Enemy.randomType()
    local enemyTypes = {"goblin", "skeleton", "bat", "orc_archer", "slime", "mage_enemy", "viper", "vampire_boss"}
    return enemyTypes[math.random(#enemyTypes)]
end

function Enemy:determineBehavior()
    if self.type == "orc_archer" or self.type == "mage_enemy" or self.type == "viper" then
        return "ranged"
    elseif self.type == "vampire_boss" then
        return "teleport"
    else
        return "aggressive"
    end
end

-- Constructor for new enemies
function Enemy.new(type, x, y, playerLevel)
    local self = setmetatable({}, Enemy)
    self.type = type
    self.x = x or 0
    self.y = y or 0
    self.prevX = x
    self.prevY = y
    self.health = 100  -- Base health
    self.maxHealth = self.health
    self.speed = 50
    self.damage = 10  -- Default damage
    self.radius = 10
    self.experience = 20 -- Experience granted upon defeat
    self.isBoss = false -- Flag to identify boss enemies
    self.statusEffects = {}
    self.projectiles = {}  -- If using projectiles
    self.lastDirection = "left" 
    self.lifeDrainTarget = nil
self.lifeDrainTimer = 0
self.lifeDrainDuration = 0
self.isLifeDraining = false

    -- Initialize timers with default values
    self.attackTimer = 0
    self.attackSpeed = 1 -- Default attack speed

    -- Animation properties
    self.animation = {
        timer = 0,
        speed = 2,  -- Controls the speed of the animation cycle
    }

    -- AI state and behavior initialization
    self.state = "idle"  -- Default AI state
    self.behavior = self:determineBehavior()  -- Determine behavior based on type
    self.target = nil  -- Enemy targets the player

    -- Unique enemy properties based on type
    if type == "goblin" then
        self.speed = 80
        self.health = 120
        self.maxHealth = self.health
        self.damage = 5
        self.color = {0.3, 0.8, 0.3}
        self.shape = "goblin"
        self.experience = 5
        self.radius = 10 * 2  -- Original sprite width / 2 * scale factor

      

    elseif type == "skeleton" then
        self.speed = 30
        self.health = 350
        self.maxHealth = self.health
        self.damage = 15
        self.color = {0.8, 0.8, 0.8}
        self.shape = "skeleton"
        self.experience = 15
         self.radius = 10 * 2

        -- Skeleton-specific animation properties
        self.animation.rattle = true
        self.animation.rattleOffset = 0
        self.animation.rattleSpeed = math.pi * 4  -- Rattle speed
        self.animation.rattleMaxOffset = 5    -- Maximum offset in pixels

    elseif type == "bat" then
        self.speed = 100
        self.health = 100
        self.maxHealth = self.health
        self.damage = 4
        self.color = {0.5, 0.0, 0.5}
        self.shape = "bat"
        self.experience = 5
         self.radius = 10 * 2

        -- Bat-specific animation properties
        self.animation.flap = true
        self.animation.flapAngle = 0
        self.animation.flapSpeed = math.pi * 4  -- Flap speed in radians per second
        self.animation.flapMaxAngle = math.pi / 6  -- Maximum flap angle

    elseif type == "orc_archer" then
        self.speed = 60
        self.health = 130
        self.maxHealth = self.health
        self.attackTimer = 0
        self.attackSpeed = 0.5
        self.attackRange = 350 -- Increased attack range
        self.damage = 12
        self.color = {0.6, 0.3, 0.1}
        self.shape = "orc_archer"
        self.projectiles = {}
        self.experience = 20
         self.radius = 10 * 2

        
    elseif type == "slime" then
        self.speed = 40
        self.health = 160
        self.maxHealth = self.health
        self.damage = 6
        self.color = {0.0, 0.5, 0.0}
        self.shape = "slime"
        self.experience = 10
         self.radius = 10 * 2
         
             -- Slime-specific animation properties
    self.animation.pulsate = true
    self.animation.pulseRange = 1.2  -- Maximum scale factor
    self.animation.pulseSpeed = 2    -- Pulsate speed
    self.currentScale = 1

      
    elseif type == "vampire_boss" then
        self.speed = 80
        self.health = 15000
        self.maxHealth = self.health
        self.damage = 25
        self.radius = 20
        self.color = {0.5, 0, 0.5}
        self.shape = "vampire_boss"
        self.isBoss = true
        self.experience = 100
         self.radius = 16 * 2
        self.abilities = {
            teleportCooldown = 5,
            teleportTimer = 0,
            lifeDrainCooldown = 10,
            lifeDrainTimer = 0,
            summonCooldown = 10,
            summonTimer = 0,
            shadowCloakCooldown = 30,
            shadowCloakTimer = 0,
            isInvisible = false,
            invisibilityDuration = 3,
            invisibilityTimer = 0,
        }

  

    elseif type == "mage_enemy" then
        self.speed = 50
        self.health = 180
        self.maxHealth = self.health
        self.damage = 18
        self.attackTimer = 0
        self.attackSpeed = 0.7
        self.attackRange = 200
        self.color = {1, 0, 0}
        self.shape = "mage_enemy"
        self.projectiles = {}
        self.experience = 25
         self.radius = 10 * 2

       

    elseif type == "viper" then
        self.speed = 70
        self.health = 160
        self.maxHealth = self.health
        self.damage = 14
        self.attackTimer = 0
        self.attackSpeed = 0.6
        self.attackRange = 250
        self.color = {0, 1, 0}
        self.shape = "viper"
        self.projectiles = {}
        self.experience = 25
         self.radius = 10 * 2

     
    end
     self.isInRange = false
    return self
end

-- Function to apply status effects to the enemy
function Enemy:applyStatusEffect(effect)
    self.statusEffects = self.statusEffects or {}
    self.statusEffects[effect.name] = {
        duration = effect.duration,
        timer = 0
    }

    -- Specific handling for Shock
    if effect.name == "Shock" then
        self.isShocked = true
    end
end


function Enemy:update(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities, zoomFactor)
    local prevX = self.x
    local prevY = self.y

    -- Update animation timer
    if self.animation then
        self.animation.timer = self.animation.timer + dt * self.animation.speed
    end

    -- Check if the enemy is frozen
    if self.statusEffects["Frozen"] then
        self.statusEffects["Frozen"].timer = self.statusEffects["Frozen"].timer + dt
        if self.statusEffects["Frozen"].timer >= self.statusEffects["Frozen"].duration then
            self.statusEffects["Frozen"] = nil
            self.isFrozen = false
        else
            return -- If frozen, skip the rest of the update
        end
    end

    -- Check if the enemy is shocked
    if self.statusEffects["Shock"] then
        self.statusEffects["Shock"].timer = self.statusEffects["Shock"].timer + dt
        if self.statusEffects["Shock"].timer >= self.statusEffects["Shock"].duration then
            self.statusEffects["Shock"] = nil
            self.isShocked = false
        else
            return -- If shocked, skip the rest of the update
        end
    end

    -- If we reached here, it means the enemy is neither frozen nor shocked, so we can continue with the rest of the update

    -- Update the attack timer (increment regardless of whether in range or not)
    self.attackTimer = self.attackTimer + dt

    -- Calculate distance to the player and check for melee attack range
    local meleeRange = 200 -- Example melee range for melee enemies
    local distanceToPlayer = self:getDistanceToPlayer(player)

    if distanceToPlayer <= meleeRange then
        if self.attackTimer >= (1 / self.attackSpeed) then
            -- Attack once the timer allows it
            self:performMeleeAttack(player, effects, sounds, summonedEntities)
            self.attackTimer = 0 -- Reset the attack timer after attacking
        end
    end

    -- AI behavior logic based on state and behavior type
    if not self.statusEffects["Frozen"] then
        if self.behavior == "aggressive" then
            self:moveTowardsPlayer(dt, player)
        elseif self.behavior == "ranged" then
            self:rangedAttack(dt, player)
        elseif self.behavior == "teleport" then
            self:teleportAI(dt, player)
        else
            self:chaseNearestCharacter(dt, player)
        end
    end

    -- Type-specific update logic
    if self.type == "vampire_boss" then
        self:updateVampireBoss(dt, player, effects or {}, enemies, damageNumbers, sounds)
    elseif self.type == "orc_archer" then
        self:updateOrcArcher(dt, player, effects, enemies)
    elseif self.type == "mage_enemy" then
        self:updateMageEnemy(dt, player, effects, enemies)
    elseif self.type == "viper" then
        self:updateViper(dt, player, effects, enemies)
    else
        self:chaseNearestCharacter(dt, player)
    end

    -- Collision with walls
    for _, wall in ipairs(maze.walls) do
        if Collision.checkCircleRectangle(self.x, self.y, self.radius, wall.x, wall.y, wall.width, wall.height) then
            self.x = self.prevX
            self.y = self.prevY
            break
        end
    end

    -- Collision with other enemies
    for _, otherEnemy in ipairs(enemies) do
        if otherEnemy ~= self then
            if Collision.checkCircle(self.x, self.y, self.radius, otherEnemy.x, otherEnemy.y, otherEnemy.radius) then
                self.x = self.prevX
                self.y = self.prevY
                break
            end
        end
    end
    
     -- Calculate movement delta after movement
    self.movementDx = self.x - prevX
    self.movementDy = self.y - prevY

    -- Update lastDirection based on movement
    if self.movementDx > 0 then
        self.lastDirection = "right"
    elseif self.movementDx < 0 then
        self.lastDirection = "left"
    end

    -- Now update self.prevX and self.prevY
    self.prevX = self.x
    self.prevY = self.y
    

    -- Handle status effects
   if self.statusEffects then
    for effectName, effect in pairs(self.statusEffects) do
        effect.timer = effect.timer + dt

        if effectName == "Ignite" or effectName == "Poison" then
            -- Existing logic for damage-over-time effects
            if effect.timer >= 1 then
                self.health = self.health - effect.damagePerSecond
                if self.health < 0 then
                    self.health = 0
                end
                effect.timer = effect.timer - 1
                if effects then
                    table.insert(effects, Effects.new(effectName, self.x, self.y, nil, nil, nil, self))
                end
            end

 

        -- Remove effect if timer exceeds duration
        if effect.timer >= effect.duration then
            self.statusEffects[effectName] = nil
            end
        end
    end
end

end

function Enemy:move(dt, player)
    if self.x and self.y and player.x and player.y then
        -- Calculate the direction from the enemy to the player
        local dx = player.x - self.x
        local dy = player.y - self.y

        -- Calculate the distance to the player
        local distance = math.sqrt(dx * dx + dy * dy)

        -- Always set angleToTarget, even if not moving
        self.angleToTarget = math.atan2(dy, dx) or 0  -- Default to 0 if nil

        -- Normalize the direction vector to maintain constant speed
        if distance > 0 then
            -- Move the enemy towards the player
            self.x = self.x + (dx / distance) * self.speed * dt
            self.y = self.y + (dy / distance) * self.speed * dt
        end
    end
end


-- AI behavior logic based on enemy type and state


-- AI behavior for aggressive enemies
function Enemy:moveTowardsPlayer(dt, player)
    if not player.x or not player.y or not self.x or not self.y then
        return -- Skip the update if positions are not properly initialized
    end
    local dx = player.x - self.x
    local dy = player.y - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    self.angleToTarget = math.atan2(dy, dx) or 0  -- Set angleToTarget
    if distance > 0 then
        self.x = self.x + (dx / distance) * self.speed * dt
        self.y = self.y + (dy / distance) * self.speed * dt
    end
    
  
end


--function Enemy:performMeleeAttack(player, effects)
function Enemy:performMeleeAttack(player, effects, sounds, summonedEntities)

    local meleeRange = 40 -- Example melee range for enemies
    local closestCharacter, closestDistance = nil, meleeRange + 1

    -- Loop through all characters and find the closest one to attack
    for _, char in pairs(player.characters) do
        local distanceToCharacter = self:getDistanceToPlayer(char)
          print("Checking melee attack range for " .. char.type .. ": Distance: " .. distanceToCharacter)
        if distanceToCharacter <= closestDistance then
            closestCharacter = char
            closestDistance = distanceToCharacter
        end
    end

    -- Apply damage to the closest character
    if closestCharacter and closestDistance <= meleeRange then
       print(self.type .. " is attacking " .. closestCharacter.type)
        if self.attackTimer == 0 or self.attackTimer >= (1 / self.attackSpeed) then
            -- Perform the attack
            self.attackTimer = 0 -- Reset attack timer
            local damage = self.damage or 10
            closestCharacter.health = closestCharacter.health - damage  -- Apply damage to the closest character
             print(closestCharacter.type .. " took " .. damage .. " damage, remaining health: " .. closestCharacter.health)
            if closestCharacter.health < 0 then closestCharacter.health = 0 end  -- Ensure health doesn't go below zero

         
             -- Add print statement for tracking damage
            print("Melee attack: " .. self.type .. " damages " .. closestCharacter.type .. " for " .. damage .. " damage. Remaining health: " .. closestCharacter.health)

            -- Handle additional effects, such as triggering the red flash or special effects
            closestCharacter.damageFlashTimer = 0.1  -- Set flash timer
            table.insert(effects, Effects.new("slash", closestCharacter.x, closestCharacter.y))
            
         
            
            
        end
    end
end











-- AI behavior for ranged enemies
function Enemy:rangedAttack(dt, player)
    local distanceToPlayer = self:getDistanceToPlayer(player)
    if distanceToPlayer <= self.attackRange then
        if self.attackTimer >= (1 / self.attackSpeed) then
            self.attackTimer = 0
            -- Create new enemy projectile
            local proj = EnemyProjectile:new(self.x, self.y, player.x, player.y, self.damage, {
                attackRange = self.attackRange,
                speed = 200,
                radius = 5,
                statusEffect = Abilities.statusEffects.Ignite
            })
            table.insert(self.projectiles, proj)
            print("Projectile created at:", proj.x, proj.y)  -- Debug: Confirm creation
        end
    else
        self:moveTowardsPlayer(dt, player)
    end
    self:updateProjectiles(dt)
end



-- AI behavior for teleporting enemies
function Enemy:teleportAI(dt, player)
    self.abilities.teleportTimer = self.abilities.teleportTimer + dt
    if self.abilities.teleportTimer >= self.abilities.teleportCooldown then
        self.abilities.teleportTimer = 0
        self:teleport()
    end
    self:moveTowardsPlayer(dt, player)
end

function Enemy:updateProjectiles(dt, player)
    if not player or not player.characters then return end  -- Ensure player is valid

    for i = #self.projectiles, 1, -1 do
        local proj = self.projectiles[i]
        local dx = proj.targetX - proj.x
        local dy = proj.targetY - proj.y
        local distance = math.sqrt(dx^2 + dy^2)

        if distance > 5 then
            -- Move the projectile towards the target
            proj.x = proj.x + (dx / distance) * proj.speed * dt
            proj.y = proj.y + (dy / distance) * proj.speed * dt
        else
            -- Mark projectile as dead if it reaches its target
            proj.isDead = true
        end

        -- Check for collisions with player characters
        for _, char in pairs(player.characters) do
            if char.health > 0 and Collision.checkCircle(proj.x, proj.y, proj.radius, char.x, char.y, char.radius) then
                -- Apply damage to the character
                char.health = char.health - proj.damage
                if char.health < 0 then
                    char.health = 0  -- Ensure health doesn't go below zero
                end

                -- Optional: Trigger damage feedback (e.g., flash effect)
                char.damageFlashTimer = 0.1  -- Set flash timer

                -- Mark projectile as dead after hit
                proj.isDead = true

                -- Log damage for debugging
                print("Enemy projectile hit " .. char.type .. " for " .. proj.damage .. " damage. Remaining health: " .. char.health)

                break  -- Exit loop after the first hit to avoid multiple hits from the same projectile
            end
        end

        -- Remove projectile if it is dead
        if proj.isDead then
            table.remove(self.projectiles, i)
        end
    end
end


-- Helper to calculate distance to the player
function Enemy:getDistanceToPlayer(player)
    -- Check if player and self positions are valid
    if not player.x or not player.y or not self.x or not self.y then
        return math.huge  -- Return a large number if positions are not valid to avoid errors
    end

    local dx = player.x - self.x
    local dy = player.y - self.y
    return math.sqrt(dx * dx + dy * dy)
end


-- Chase the nearest character
function Enemy:chaseNearestCharacter(dt, player)
    local target = self:findNearestCharacter(player)
    if target then
        local dx = target.x - self.x
        local dy = target.y - self.y
        local distance = math.sqrt(dx * dx + dy * dy)
        if distance > 0 then
            self.x = self.x + (dx / distance) * self.speed * dt
            self.y = self.y + (dy / distance) * self.speed * dt
        end
        if distance <= self.radius + target.radius then
            self:performMeleeAttack(player, effects)
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
        print(self.type .. " is attacking " .. target.type .. " for " .. damage .. " damage")
        target.health = target.health - damage
        if target.health < 0 then
            target.health = 0
        end
    end
end

-- Find the nearest character (player)
function Enemy:findNearestCharacter(player)
    local nearestChar = nil
    local minDistanceSquared = math.huge
    for _, char in pairs(player.characters) do
        if char.health > 0 then
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

-- Take damage logic
function Enemy:takeDamage(damage, damageNumbers, effects, sourceType, sourceCharacter, attackType)


   

    damage = damage or 0
  
    
    self.health = self.health - damage
    if self.health < 0 then
        self.health = 0
    end
   

    local colorMap = {
        ranger = {0, 1, 0},         -- Green for ranger
        mage = {0, 1, 1},           -- Cyan for mage
        spearwarden = {1, 1, 0},    -- Yellow for spearwarden
    }

    local color = colorMap[sourceType] or {0, 0, 1}  
   

    if damageNumbers then
        local dn = DamageNumber.new(self.x, self.y, damage, color)
        table.insert(damageNumbers, dn)
       end
       
 if sourceCharacter then
    Abilities.applyEffects(nil, self, sourceCharacter, enemies, effects, sounds, summonedEntities, damageNumbers, attackType)
end


end

-- Apply freeze effect to the enemy
function Enemy:applyFreeze(duration)
    self.statusEffects["Frozen"] = { duration = duration, timer = 0 }
    self.isFrozen = true
end


function Enemy:updateVampireBoss(dt, player, effects, enemies, damageNumbers, sounds)
    local abilities = self.abilities
    effects = effects or {}  -- Ensure effects is initialized

    -- Update timers for other abilities
    abilities.teleportTimer = abilities.teleportTimer + dt
    abilities.summonTimer = abilities.summonTimer + dt
    abilities.shadowCloakTimer = abilities.shadowCloakTimer + dt

    -- Update life drain cooldown timer
    if not self.isLifeDraining then
        abilities.lifeDrainTimer = abilities.lifeDrainTimer + dt
    end

    -- Handle invisibility duration
    if abilities.isInvisible then
        abilities.invisibilityTimer = abilities.invisibilityTimer + dt
        if abilities.invisibilityTimer >= abilities.invisibilityDuration then
            abilities.isInvisible = false
            abilities.invisibilityTimer = 0
        end
    end

    -- Handle life drain over time
    if self.isLifeDraining then
        self.lifeDrainDuration = self.lifeDrainDuration + dt
        self.lifeDrainTimer = self.lifeDrainTimer + dt

        -- Deal damage every 1 second
        if self.lifeDrainTimer >= 1 then
            self.lifeDrainTimer = self.lifeDrainTimer - 1  -- Keep excess time

            -- Deal damage to the target if it's valid
            if self.lifeDrainTarget and self.lifeDrainTarget.health > 0 then
                local drainAmount = 5
                self.lifeDrainTarget.health = self.lifeDrainTarget.health - drainAmount
                self.health = math.min(self.health + drainAmount, self.maxHealth)  -- Heal the vampire
                
                 -- Add the print statement here to track damage:
    print("Life Drain: Dealt", drainAmount, "damage to", self.lifeDrainTarget.type)

                -- Add damage number for visual feedback
                table.insert(damageNumbers, DamageNumber.new(self.lifeDrainTarget.x, self.lifeDrainTarget.y, drainAmount, {1, 0, 0}))
            else
                -- Stop life drain if the target is invalid
                self.isLifeDraining = false
                self.lifeDrainTarget = nil

                -- Start cooldown
                abilities.lifeDrainTimer = 0

                -- Remove the life drain effect
                if self.lifeDrainEffect then
                    self.lifeDrainEffect.isDead = true
                    self.lifeDrainEffect = nil
                end
            end
        end

        -- End the drain if the duration is complete or target is too far
        if self.lifeDrainDuration >= 6 or not self.lifeDrainTarget or self:getDistanceToPlayer(self.lifeDrainTarget) > 300 then
            self.isLifeDraining = false
            self.lifeDrainTarget = nil

            -- Start cooldown
            abilities.lifeDrainTimer = 0

            -- Remove the life drain effect
            if self.lifeDrainEffect then
                self.lifeDrainEffect.isDead = true
                self.lifeDrainEffect = nil
            end
        end
    else
        -- Only initiate life drain if cooldown has passed
        if abilities.lifeDrainTimer >= abilities.lifeDrainCooldown then
            self:lifeDrain(player)
        end
    end

    -- Handle other abilities (teleport, summon, shadow cloak)
    if abilities.teleportTimer >= abilities.teleportCooldown then
        abilities.teleportTimer = 0
        self:teleport()
        table.insert(effects, Effects.new("teleport", self.x, self.y))
    end

    if abilities.summonTimer >= abilities.summonCooldown then
        abilities.summonTimer = 0
        self:summonMinions(enemies)
        table.insert(effects, Effects.new("summon", self.x, self.y))
    end

    if abilities.shadowCloakTimer >= abilities.shadowCloakCooldown then
        abilities.shadowCloakTimer = 0
        abilities.isInvisible = true
        abilities.invisibilityTimer = 0
        table.insert(effects, Effects.new("shadow_cloak", self.x, self.y))
    end

    -- Movement when not life draining or invisible
    if not abilities.isInvisible and not self.isLifeDraining then
        self:chaseNearestCharacter(dt, player)
    end
end




-- Teleportation logic for Vampire Boss
function Enemy:teleport()
    local teleportDistance = 100
    local angle = math.random() * 2 * math.pi
    local dx = math.cos(angle) * teleportDistance
    local dy = math.sin(angle) * teleportDistance
    self.x = self.x + dx
    self.y = self.y + dy
    self.x = math.max(self.radius, math.min(4000 - self.radius, self.x))
    self.y = math.max(self.radius, math.min(4000 - self.radius, self.y))
end

-- Life Drain ability for Vampire Boss
function Enemy:lifeDrain(player)
  self.lifeDrainEffect = effect  -- Store the effect to manage its lifecycle
local target = self:findNearestCharacter(player)
    if target then
        self.lifeDrainTarget = target
        self.lifeDrainTimer = 0 -- reset drain timer
        self.lifeDrainDuration = 0 -- reset duration timer
        self.isLifeDraining = true

        -- Create an effect for the life drain that attaches to the vampire and player
        local effect = Effects.new("life_drain", self.x, self.y, target.x, target.y, nil, self, target)
        effect.attachedTo = self  -- Keeps the effect attached to the Vampire Boss position
        effect.targetAttachedTo = target -- keeps the effect’s end attached to the target player
        table.insert(effects, effect)
    end
end


-- Summon Minions ability for Vampire Boss
function Enemy:summonMinions(enemies)
    local minionType = math.random() < 0.5 and "bat" or "skeleton"
    local numMinions = 3
    for i = 1, numMinions do
        local angle = math.random() * 2 * math.pi
        local distance = math.random(50, 100)
        local x = self.x + math.cos(angle) * distance
        local y = self.y + math.sin(angle) * distance
        table.insert(enemies, Enemy.new(minionType, x, y))
    end
end

-- Update function for Orc Archer
function Enemy:updateOrcArcher(dt, player, effects, enemies)
    self.attackTimer = self.attackTimer + dt
    local target = self:findNearestCharacter(player)

    if target then
        local dx = target.x - self.x
        local dy = target.y - self.y
        local distance = math.sqrt(dx^2 + dy^2)

        if distance < 200 then
            self.x = self.x - (dx / distance) * self.speed * dt
            self.y = self.y - (dy / distance) * self.speed * dt
        end

        if distance <= self.attackRange then
            if self.attackTimer >= (1 / self.attackSpeed) then
                self.attackTimer = 0
                local proj = {
                    x = self.x,
                    y = self.y,
                    targetX = target.x,
                    targetY = target.y,
                    speed = 250,
                    damage = 15,
                    radius = 5,
                    isDead = false,
                    statusEffect = nil,
                }
                table.insert(self.projectiles, proj)

                self.animation.bowStretch = self.animation.bowMaxStretch
                self.animation.bowStretched = true
            end
        else
            self.x = self.x + (dx / distance) * self.speed * dt
            self.y = self.y + (dy / distance) * self.speed * dt
        end
    end

    for i = #self.projectiles, 1, -1 do
        local proj = self.projectiles[i]
        local dx = proj.targetX - proj.x
        local dy = proj.targetY - proj.y
        local distance = math.sqrt(dx^2 + dy^2)
        if distance > 5 then
            proj.x = proj.x + (dx / distance) * proj.speed * dt
            proj.y = proj.y + (dy / distance) * proj.speed * dt
        else
            proj.isDead = true
        end

        if proj.isDead then
            table.remove(self.projectiles, i)
        end
    end

    self:chaseNearestCharacter(dt, player)
end

-- Update function for Mage Enemy
function Enemy:updateMageEnemy(dt, player, effects, enemies)
    self.attackTimer = self.attackTimer + dt
    local target = self:findNearestCharacter(player)

    if target then
        local dx = target.x - self.x
        local dy = target.y - self.y
        local distance = math.sqrt(dx^2 + dy^2)

        if distance <= self.attackRange then
            if self.attackTimer >= (1 / self.attackSpeed) then
                self.attackTimer = 0
                local proj = {
                    x = self.x,
                    y = self.y,
                    targetX = target.x,
                    targetY = target.y,
                    speed = 200,
                    damage = 10,
                    radius = 5,
                    isDead = false,
                    statusEffect = Abilities.statusEffects.Ignite,
                }
                table.insert(self.projectiles, proj)
            end
        end

        if distance < 100 then
            self:teleportAway()
        else
            self:chaseNearestCharacter(dt, player)
        end
    end

    for i = #self.projectiles, 1, -1 do
        local proj = self.projectiles[i]
        local dx = proj.targetX - proj.x
        local dy = proj.targetY - proj.y
        local distance = math.sqrt(dx^2 + dy^2)
        
        if distance > 5 then
            proj.x = proj.x + (dx / distance) * proj.speed * dt
            proj.y = proj.y + (dy / distance) * proj.speed * dt
        else
            proj.isDead = true
        end

        if proj.isDead then
            table.remove(self.projectiles, i)
        end
    end
end

-- Update function for Viper
function Enemy:updateViper(dt, player, effects, enemies)
    self.attackTimer = self.attackTimer + dt
    local target = self:findNearestCharacter(player)

    if target then
        local dx = target.x - self.x
        local dy = target.y - self.y
        local distance = math.sqrt(dx^2 + dy^2)

        if distance <= self.attackRange then
            if self.attackTimer >= (1 / self.attackSpeed) then
                self.attackTimer = 0
                local proj = {
                    x = self.x,
                    y = self.y,
                    targetX = target.x,
                    targetY = target.y,
                    speed = 220,
                    damage = 8,
                    radius = 5,
                    isDead = false,
                    statusEffect = Abilities.statusEffects.Poison,
                }
                table.insert(self.projectiles, proj)
            end
        end

        if distance < 150 then
            self.x = self.x - (dx / distance) * self.speed * dt
            self.y = self.y - (dy / distance) * self.speed * dt
        else
            self:chaseNearestCharacter(dt, player)
        end
    end

    for i = #self.projectiles, 1, -1 do
        local proj = self.projectiles[i]
        local dx = proj.targetX - proj.x
        local dy = proj.targetY - proj.y
        local distance = math.sqrt(dx^2 + dy^2)
        
        if distance > 5 then
            proj.x = proj.x + (dx / distance) * proj.speed * dt
            proj.y = proj.y + (dy / distance) * proj.speed * dt
        else
            proj.isDead = true
        end

        if proj.isDead then
            table.remove(self.projectiles, i)
        end
    end
end

-- Teleport away logic for Mage Enemy
function Enemy:teleportAway()
    local teleportDistance = 200
    local angle = math.random() * 2 * math.pi
    local dx = math.cos(angle) * teleportDistance
    local dy = math.sin(angle) * teleportDistance
    self.x = self.x + dx
    self.y = self.y + dy
    self.x = math.max(self.radius, math.min(4000 - self.radius, self.x))
    self.y = math.max(self.radius, math.min(4000 - self.radius, self.y))
end

-- Draw projectiles
function Enemy:drawProjectiles()
    for _, proj in ipairs(self.projectiles) do
        love.graphics.setColor(1, 0.5, 0)
        love.graphics.circle("fill", proj.x, proj.y, proj.radius)
    end
end

-- Main draw function for the enemy (with sprite flipping based on angle)
function Enemy:draw()
    -- If the Vampire Boss is invisible, do not draw it
    if self.type == "vampire_boss" and self.abilities.isInvisible then
        return
    end

   -- Determine the direction based on the angle to the player
local scaleX = 1  -- Default scale for all enemies (not too large)
local scaleY = 1  -- Default scale for all enemies (ensure not upside down)

-- Flip horizontally if the enemy should face left (based on angleToTarget)
if math.cos(self.angleToTarget or 0) > 0 then
    scaleX = -scaleX  -- Flip horizontally if facing right
end

 -- Apply color tint based on status effects
    if self.statusEffects["Frozen"] then
        love.graphics.setColor(0.5, 0.8, 1)  -- Light blue tint for frozen effect
    elseif self.statusEffects["Poison"] then
        love.graphics.setColor(0.2, 0.8, 0.2)  -- Green tint for poison effect
    else
        love.graphics.setColor(1, 1, 1)  -- Default white color
    end

-- Handle drawing for each enemy type using sprites
if self.type == "goblin" then
    Sprites.drawGoblin(self.x, self.y, scaleX, scaleY)

elseif self.type == "skeleton" then
    Sprites.drawSkeleton(self.x, self.y, scaleX, scaleY)

elseif self.type == "bat" then
    Sprites.drawBat(self.x, self.y, scaleX, scaleY)

elseif self.type == "slime" then
 
 
        -- Slimes need to pulsate, so we adjust the scale dynamically but prevent it from flipping upside down
      local slimeScaleX = scaleX  -- Only scale horizontally
local slimeScaleY = 1 + 0.1 * math.abs(math.sin(self.animation.timer * self.animation.pulseSpeed))  -- Pulsate only vertically, ensuring it stays positive

-- Draw the slime with the calculated scales
Sprites.drawSlime(self.x, self.y, slimeScaleX, slimeScaleY)


elseif self.type == "orc_archer" then
    Sprites.drawOrcArcher(self.x, self.y, scaleX, scaleY)

elseif self.type == "mage_enemy" then
    Sprites.drawMageEnemy(self.x, self.y, scaleX, scaleY)

elseif self.type == "viper" then
    Sprites.drawViper(self.x, self.y, scaleX, scaleY)

elseif self.type == "vampire_boss" then
    Sprites.drawVampireBoss(self.x, self.y, scaleX, scaleY)
end

    -- Health bar above the enemy
    love.graphics.setColor(1, 0, 0)
    local healthBarWidth = 40
    love.graphics.rectangle("fill", self.x - healthBarWidth / 2, self.y - self.radius - 10,
                            healthBarWidth * (self.health / self.maxHealth), 5)

    -- Reset color to default
    love.graphics.setColor(1, 1, 1)

 --Draw poison particles if poisoned
    self:drawPoisonParticles()  -- <<< Add this line here


    -- If the enemy has projectiles, draw them
    if self.projectiles then
        self:drawProjectiles()
    end
end

function Enemy:drawShockEffect()
    if self.isShocked then
        love.graphics.setColor(0.4, 0.6, 1, 0.5)  -- Light blue semi-transparent
        love.graphics.circle("fill", self.x, self.y, self.radius + 5)  -- Shock aura effect
        love.graphics.setColor(1, 1, 1)  -- Reset to default color
    end
end


function Enemy:drawPoisonParticles()
    -- Check if the enemy is poisoned
    if self.statusEffects["Poison"] then
        love.graphics.setColor(0.2, 1, 0.2, 0.6)  -- Light green semi-transparent

        -- Draw a few random poison "drips" around the enemy
        for i = 1, 3 do
            local offsetX = math.random(-self.radius, self.radius)
            local offsetY = math.random(-self.radius, self.radius)
            love.graphics.circle("fill", self.x + offsetX, self.y + offsetY, math.random(3, 5))  -- Small green circles
        end

        love.graphics.setColor(1, 1, 1)  -- Reset color to white after drawing
    end
end


return Enemy
