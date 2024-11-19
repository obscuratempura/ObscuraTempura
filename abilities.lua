local Abilities = {}
local Effects = require("effects")
local Collision = require("collision")
local wolfImage = love.graphics.newImage("assets/wolf.png")
wolfImage:setFilter("nearest", "nearest") 
local shieldImage = love.graphics.newImage("assets/shield_throw.png")
shieldImage:setFilter("nearest", "nearest")


-- Define status effects
Abilities.statusEffects = {
    Poison = { name = "Poison", duration = 5, damagePerSecond = 10 },
    Ignite = { name = "Ignite", duration = 5, damagePerSecond = 5 },
    Shock =  { name = "Shock", duration = 2 }, 
}

-- Define all abilities here
Abilities.abilityList = {
    -- Ranger Abilities
    ["Arrow Spread Shot"] = {
        name = "Arrow Spread Shot",
        procChance = 0.3,  -- Base proc chance
        attackType = "projectile",
        rank = 1,
        maxRank = 3,
        damageBonus = 0.1,  -- Damage multiplier bonus
         class = { name = "Ranger", color = {0, 1, 0} },  -- Green for Ranger
        description = "Shoots multiple arrows in a spread, damaging multiple enemies.",
        effect = function(char, enemy, effects, sounds, summonedEntities, enemies)
            local Projectile = require("projectile")
            local projCount = 5 + char.abilities["Arrow Spread Shot"].rank  -- Increase projectiles by 1 each rank
            local spreadAngle = math.rad(45 + 5 * char.abilities["Arrow Spread Shot"].rank)  -- Increase angle by 5 per rank
            local baseAngle = math.atan2(enemy.y - char.y, enemy.x - char.x) - (spreadAngle / 2)

            for i = 0, projCount - 1 do
                local angle = baseAngle + i * (spreadAngle / (projCount - 1))
                local projRange = char.attackRange
                local targetX = char.x + math.cos(angle) * projRange
                local targetY = char.y + math.sin(angle) * projRange

                local damageBonus = char.abilities["Arrow Spread Shot"].damageBonus or 0
                local proj = Projectile.new(char.x, char.y, targetX, targetY, char.type, char.damage * (1 + damageBonus), char.abilities, char)
                proj.hasTrail = true
                proj.sourceType = char.type
                table.insert(char.owner.projectiles, proj)
            end

            if sounds.ability.arrowSpreadShot then
                sounds.ability.arrowSpreadShot:play()
            end

            table.insert(effects, Effects.new("arrow_spread_shot", char.x, char.y, enemy.x, enemy.y))
         
        end
    },

    ["Poison Shot"] = {
    name = "Poison Shot",
    procChance = 0.35,  -- Base proc chance
    attackType = "projectile",
    rank = 1,
    maxRank = 3,
        class = { name = "Ranger", color = {0, 1, 0} },
      description = " Attacks have a chance to poison enemies, dealing damage over time.",
    effect = function(char, enemy, effects, sounds, summonedEntities, enemies)
        local Projectile = require("projectile")

        -- Create the poison shot projectile
        local proj = Projectile.new(char.x, char.y, enemy.x, enemy.y, char.type, char.damage, char.abilities, char)
        
        if not char.abilities["Poison Shot"] then
    print("Poison Shot abilities not passed correctly for", char.type)
end
        
        -- On-hit logic for Poison Shot
        proj.onHit = function(self, target)
            if target and not target.statusEffects["Poison"] then
                local scaledDPS = Abilities.statusEffects.Poison.damagePerSecond + (2 * char.abilities["Poison Shot"].rank)
                local duration = Abilities.statusEffects.Poison.duration + char.abilities["Poison Shot"].rank
                local poisonEffect = { name = "Poison", duration = duration, damagePerSecond = scaledDPS }
                
                -- Apply the poison effect
                target:applyStatusEffect(poisonEffect)
                table.insert(effects, Effects.new("poison", target.x, target.y))

                -- Play the poison effect sound
                if sounds.statusEffect.Poison then
                    sounds.statusEffect.Poison:play()
                end

            
            end
        end

        -- Add the projectile to the list of projectiles
        table.insert(char.owner.projectiles, proj)
    end
},


    ["Summon Wolf"] = {
        name = "Summon Wolf",
        procChance = 0.25,
         attackType = "projectile",
        rank = 1,
        maxRank = 3,
            class = { name = "Ranger", color = {0, 1, 0} },
        description = "Attacks have a chance to summon a wolf companion for a limited time.",
        effect = function(char, enemy, effects, sounds, summonedEntities, enemies)
            local maxSummons = char.abilities["Summon Wolf"].rank  -- Maximum number of wolves based on rank
            local currentSummons = (char.owner.summonedEntities and #char.owner.summonedEntities) or 0

            -- If we've already summoned the max number of wolves, don't summon more
            if currentSummons >= maxSummons then
                return
            end

            -- Increase duration and speed based on rank
            local duration = 10 + char.abilities["Summon Wolf"].rank * 2  -- Rank 1: 10s, Rank 2: 12s, Rank 3: 14s
            local speed = 120 + (char.abilities["Summon Wolf"].rank - 1) * 24  -- Rank 1: 120, Rank 2: 144, Rank 3: 168
            local damageMultiplier = 2 + (char.abilities["Summon Wolf"].rank * 0.1)

            -- Safeguard: Initialize summonedEntities if it's nil
            summonedEntities = summonedEntities or {}

            -- Summon the wolf
            Abilities.summonWolf(char, duration, speed, damageMultiplier, char.owner.summonedEntities)

            -- Play the summon wolf sound
            if sounds.ability.summon_wolf then
                sounds.ability.summon_wolf:play()
            end

            -- Add a visual effect for summoning the wolf
            table.insert(effects, Effects.new("summon_wolf", char.x, char.y))

          
        end
    },

    -- Mage Abilities
    ["Explosive Fireballs"] = {
        name = "Explosive Fireballs",
        procChance = 0.3,  -- Adjusted with each rank
         attackType = "projectile",
        rank = 1,
        maxRank = 3,
         class = { name = "Mage", color = {0.5, 0, 1} },  -- Purple for Mage
        description = "Attacks have a chance to explode on impact, dealing area damage.",
        effect = function(char, enemy, effects, sounds, summonedEntities, enemies)
            local Projectile = require("projectile")

            -- Create the fireball projectile
            local proj = Projectile.new(char.x, char.y, enemy.x, enemy.y, char.type, char.damage, char.abilities, char)
            if not char.abilities["Explosive Fireballs"] then
    print("Explosive Fireballs abilities not passed correctly for", char.type)
end
            proj.onHit = function(self, target)
                if target then
                    -- Explosion happens 100% on hit
                    Abilities.areaDamage(target.x, target.y, 50 + (5 * char.abilities["Explosive Fireballs"].rank), char.damage, enemies)
                    table.insert(effects, Effects.new("explosion", target.x, target.y))

                    if sounds.ability.explosion then
                        sounds.ability.explosion:play()
                    end

                    -- Apply Ignite with a proc chance
                    if math.random() < char.abilities["Explosive Fireballs"].procChance then
                        if char.abilities["Explosive Fireballs"].rank >= 3 and not target.statusEffects["Ignite"] then
                            local igniteEffect = {
                                name = "Ignite",
                                duration = Abilities.statusEffects.Ignite.duration,
                                damagePerSecond = Abilities.statusEffects.Ignite.damagePerSecond
                            }
                            target:applyStatusEffect(igniteEffect)

                            -- Visual effect for Ignite
                            table.insert(effects, Effects.new("ignite", target.x, target.y))

                            if sounds.statusEffect.Ignite then
                                sounds.statusEffect.Ignite:play()
                            end
                        end
                    end
                end
            end

            -- Add the fireball to the list of projectiles
            table.insert(char.owner.projectiles, proj)
        end
    },

    ["Frost Explosion"] = {
        name = "Frost Explosion",
        procChance = 0.35,  -- Adjusted with each rank
         attackType = "projectile",
        rank = 1,
        maxRank = 3,
         class = { name = "Mage", color = {0.5, 0, 1} },  -- Purple for Mage
          description = "Attacks have a chance to freeze and damage enemies in an area",
        effect = function(char, enemy, effects, sounds, summonedEntities, enemies)
            local Projectile = require("projectile")
            
            local proj = Projectile.new(char.x, char.y, enemy.x, enemy.y, char.type, char.damage, char.abilities, char)
            
            if not char.abilities["Frost Explosion"] then
   
end
            proj.onHit = function(self, target)
             
                local stunDuration = 1 + (0.5 * char.abilities["Frost Explosion"].rank)  -- Increase stun duration by 0.5 seconds per rank
                local radius = 60 + (5 * char.abilities["Frost Explosion"].rank)  -- Increase radius by 5 per rank
                Abilities.areaStun(target.x, target.y, radius, char.damage, stunDuration, enemies, effects)

             
                table.insert(effects, Effects.new("snow_explosion", target.x, target.y, target.x, target.y))

                if sounds.ability.frostExplosion then
                    sounds.ability.frostExplosion:play()
                end
            end

            
            table.insert(char.owner.projectiles, proj)
        end
    },

  
    -- Spearwarden Abilities
["Charged Spear Toss"] = {
    name = "Charged Spear Toss",
    procChance = 0.25,  -- Base proc chance
    attackType = "projectile",
    rank = 1,
    maxRank = 3,
    class = { name = "Spearwarden", color = {1, 1, 0} },  -- Yellow for Spearwarden
    description = "Throws a supercharged spear that explodes on impact, sending out lightning projectiles.",
    effect = function(char, enemy, effects, sounds, summonedEntities, enemies)
        local Projectile = require("projectile")

        -- Create the supercharged spear projectile
        local proj = Projectile.new(char.x, char.y, enemy.x, enemy.y, char.type, char.damage, char.abilities, char)

        -- On-hit logic for the spear projectile
        proj.onHit = function(self, target)
            if target then
                -- Release smaller lightning projectiles only, no explosion
                Abilities.releaseLightningProjectiles(target.x, target.y, char, enemies, effects, sounds)
            end
        end

        -- Add the spear projectile to the list of projectiles
        table.insert(char.owner.projectiles, proj)
    end
},

    
    
    ["Chain Lightning"] = {
    name = "Chain Lightning",
    procChance = 0.4,  -- Adjusted with each rank
     attackType = "projectile",
    rank = 1,
    maxRank = 3,
      class = { name = "Spearwarden", color = {1, 1, 0} },  -- Yellow for Spearwarden
    description = "Attacks have a chance to unleash lightning that chains to multiple enemies.",
    effect = function(char, enemy, effects, sounds, summonedEntities, enemies)
        local Projectile = require("projectile")

        -- Create the spear projectile
        local proj = Projectile.new(char.x, char.y, enemy.x, enemy.y, char.type, char.damage, char.abilities, char)
        
        if not char.abilities["Chain Lightning"] then
    print("Chain Lightning abilities not passed correctly for", char.type)
end

        -- On-hit logic for Chain Lightning
        proj.onHit = function(self, target)
            if target then
                -- Trigger Chain Lightning on hit
                local baseDamage = 10 + (2 * char.abilities["Chain Lightning"].rank)
                Abilities.chainLightning(target, baseDamage, enemies, effects)
                table.insert(effects, Effects.new("chain_lightning", self.x, self.y, target.x, target.y))

                -- Play the chain lightning sound
                if sounds.ability.chain_lightning then
                    sounds.ability.chain_lightning:play()
                end

            end
        end

        -- Add the spear to the list of projectiles
        table.insert(char.owner.projectiles, proj)
    end
},

    ["Shield Throw"] = {
        name = "Shield Throw",
        procChance = 0.3,  -- Adjusted with each rank
         attackType = "projectile",
        rank = 1,
        maxRank = 3,
          class = { name = "Spearwarden", color = {1, 1, 0} },  -- Yellow for Spearwarden
         description = "Attacks have a chance to throw a shield that returns, hitting enemies along its path.",
        effect = function(char, enemy, effects, sounds, summonedEntities, enemies)
            local damageMultiplier = 1 + (char.abilities["Shield Throw"].rank * 0.1)
            local duration = 3 + (char.abilities["Shield Throw"].rank)  -- Increase boomerang duration by 1 per rank
            local speed = 300 + (char.abilities["Shield Throw"].rank * 20)  -- Increase speed by 20 per rank

            Abilities.throwShieldBoomerang(char, damageMultiplier, duration, effects, enemies)

            if sounds.ability.shieldThrow then
                sounds.ability.shieldThrow:play()
            end

          
        end
    }
}






Abilities.generalUpgrades = {
    ["Increase Attack Speed"] = {
        name = "Increase Attack Speed",
        effect = function(character)
            character.attackSpeedUpgradeCount = character.attackSpeedUpgradeCount or 0  -- Initialize count if it doesn't exist
            if character.attackSpeedUpgradeCount < 5 then  -- Limit to max of 5 upgrades
                character.attackSpeed = character.attackSpeed * 1.1  -- Increase attack speed by 10%
                character.attackSpeedUpgradeCount = character.attackSpeedUpgradeCount + 1
            end
        end
    },
    ["Increase Attack Damage"] = {
        name = "Increase Attack Damage",
        effect = function(character)
            character.attackDamageUpgradeCount = character.attackDamageUpgradeCount or 0  -- Initialize count if it doesn't exist
            if character.attackDamageUpgradeCount < 5 then  -- Limit to max of 5 upgrades
                character.damage = character.damage * 1.1  -- Increase attack damage by 10%
                character.attackDamageUpgradeCount = character.attackDamageUpgradeCount + 1
            end
        end
    },
    ["Increase Movement Speed"] = {
        name = "Increase Movement Speed",
        effect = function(character)
            character.speedUpgradeCount = character.speedUpgradeCount or 0  -- Initialize count if it doesn't exist
            if character.speedUpgradeCount < 5 then  -- Limit to max of 5 upgrades
                character.speed = character.speed + 5  -- Increase speed by 5 points
                character.speedUpgradeCount = character.speedUpgradeCount + 1
            end
        end
    },
    ["Increase Attack Range"] = {
        name = "Increase Attack Range",
        effect = function(character)
            character.attackRangeUpgradeCount = character.attackRangeUpgradeCount or 0  -- Initialize count if it doesn't exist
            if character.attackRangeUpgradeCount < 5 then  -- Limit to max of 5 upgrades
                character.attackRange = character.attackRange * 1.1  -- Increase attack range by 10%
                character.attackRangeUpgradeCount = character.attackRangeUpgradeCount + 1
            end
        end
    }
}


-- Area Stun function
function Abilities.areaStun(x, y, radius, damage, stunDuration, enemies, effects)
    for _, enemy in ipairs(enemies) do
        local dx = enemy.x - x
        local dy = enemy.y - y
        if dx * dx + dy * dy <= radius * radius then
            -- Apply damage
            enemy:takeDamage(damage)

            -- Apply stun effect
            local stunEffect = { name = "Frozen", duration = stunDuration }
            enemy:applyStatusEffect(stunEffect)

            -- Add freeze visual effect
            table.insert(effects, Effects.new("freeze", enemy.x, enemy.y))
        end
    end
end


function Abilities.applyGeneralUpgrade(upgradeName, characters)
    local upgrade = Abilities.generalUpgrades[upgradeName]
    if upgrade then
      
        for _, char in pairs(characters) do
            upgrade.effect(char)
          
        end
    else
      
    end
end



-- Function to upgrade an ability
function Abilities.upgradeAbility(character, abilityName)
    character.abilities = character.abilities or {}

    -- Check if the ability exists in the centralized list
    local abilityDef = Abilities.abilityList[abilityName]
    if not abilityDef then
       print("Ability not found:", abilityName)
      
        
        return
    end

    -- Check if the character already has the ability
    local ability = character.abilities[abilityName]
if not ability then
    -- Initialize ability
    character.abilities[abilityName] = {
        rank = 1,
        procChance = abilityDef.procChance,
        effect = abilityDef.effect,  -- Assign the effect function
        damageBonus = abilityDef.damageBonus or 0  -- Initialize damageBonus here
    }
    
          -- Debug print: ability has been added
        print("Assigned ability", abilityName, "to character", character.type)
  
elseif ability.rank < abilityDef.maxRank then
    -- Upgrade the ability
    ability.rank = ability.rank + 1
    ability.procChance = math.min(ability.procChance * 1.5, 0.9)
    -- Re-assign the effect function to ensure it's present
    ability.effect = abilityDef.effect
    ability.damageBonus = (ability.damageBonus or 0) + (abilityDef.damageBonus or 0)  -- Ensure damageBonus is upgraded
      -- Debug print: ability has been upgraded
        print("Upgraded ability", abilityName, "to rank", ability.rank)

    else
        print("Max rank reached for ability:", abilityName)
end

end


-- Summon Wolf function
function Abilities.summonWolf(owner, duration, speed, damageMultiplier, summonedEntities)
    summonedEntities = summonedEntities or owner.summonedEntities

    local wolf = {
        x = owner.x,
        y = owner.y,
        vx = 0,
        vy = 0,
        damage = owner.damage * damageMultiplier,
        health = 50,
        duration = duration,
        speed = speed * 2,      -- Adjust speed as needed
        attackRange = 20,
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
        image = wolfImage,         -- Load the wolf image
        lastDirection = "left",    -- Default last direction
        angleToTarget = 0,         -- To track angle towards target
    }

    -- Update function for the wolf
    wolf.update = function(self, dt, enemies, effects, summonedEntities)
        -- Update lifetime timer
        self.lifeTimer = self.lifeTimer + dt
        if self.lifeTimer >= self.duration then
            self.isDead = true
            return
        end

        -- Update attack and dash timers
        self.attackTimer = self.attackTimer + dt
        self.dashTimer = self.dashTimer + dt

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
                -- Match enemy's velocity to move smoothly with it
                desiredVx = 0
                desiredVy = 0

                -- Attack the enemy if cooldown has elapsed
                if self.attackTimer >= self.attackCooldown then
                    closestEnemy:takeDamage(self.damage)
                    self.attackTimer = 0  -- Reset attack cooldown

                    -- Add the bite effect
                    table.insert(effects, Effects.new("wolfbite", closestEnemy.x, closestEnemy.y))
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

        -- Set the velocity directly for immediate responsiveness
        self.vx = desiredVx
        self.vy = desiredVy

        -- Update position
        self.x = self.x + self.vx * dt
        self.y = self.y + self.vy * dt
    end

   -- Draw the wolf with rotation based on angleToTarget
wolf.draw = function(self)
    if not self.isDead then
        local scaleX = 2  -- Adjust size scaling as needed
        local scaleY = 2
        -- Flip horizontally based on whether the wolf should face right or left
        if math.cos(self.angleToTarget) > 0 then
            scaleX = -scaleX  -- Flip horizontally if facing right
        end
        love.graphics.draw(self.image, self.x, self.y, 0, scaleX, scaleY, self.image:getWidth() / 2, self.image:getHeight() / 2)
    end
end


    -- Insert the wolf into the summoned entities
    table.insert(summonedEntities, wolf)
end









-- Area Damage function
function Abilities.areaDamage(x, y, radius, damage, enemies, effects)
    for _, enemy in ipairs(enemies) do
        local dx = enemy.x - x
        local dy = enemy.y - y
        if dx * dx + dy * dy <= radius * radius then
            enemy:takeDamage(damage)
        end
    end
end

function Abilities.releaseLightningProjectiles(x, y, char, enemies, effects, sounds)
    local Projectile = require("projectile")
    local rank = char.abilities["Charged Spear Toss"].rank or 1
    local numProjectiles = 5 + rank  -- 3 at rank 1, up to 5 at rank 3
    local stunDuration = 1 + 1 * rank  -- Increase stun duration per rank
    local radius = 1000  -- Adjust radius if needed

    local angleStep = (2 * math.pi) / numProjectiles
    for i = 0, numProjectiles - 1 do
        local angle = i * angleStep
        local targetX = x + math.cos(angle) * 200  -- Adjust range as needed
        local targetY = y + math.sin(angle) * 200

        -- Create the lightning projectile
        local proj = Projectile.new(x, y, targetX, targetY, char.type, char.damage, char.abilities, char)
        proj.sourceType = char.type

        -- On-hit logic for each lightning projectile to apply Shock on hit
        proj.onHit = function(self, target)
            if target then
                -- Apply direct Shock effect as a stun on the enemy hit
                Abilities.applyShockEffect(target.x, target.y, radius, stunDuration, { target }, effects)

                -- Visual and audio feedback for shock effect
                if sounds.statusEffect.Shock then
                    sounds.statusEffect.Shock:play()
                end
            end
        end

        -- Add the lightning projectile to the list of projectiles
        table.insert(char.owner.projectiles, proj)
    end
end

-- Function to directly apply Shock effect as a stun to any nearby enemies
function Abilities.applyShockEffect(x, y, radius, stunDuration, enemies, effects)
    for _, enemy in ipairs(enemies) do
        local dx = enemy.x - x
        local dy = enemy.y - y
        if dx * dx + dy * dy <= radius * radius then
            -- Apply stun (shock effect)
            local shockEffect = { name = "Shock", duration = stunDuration }
            enemy:applyStatusEffect(shockEffect)

            -- Visual and audio effect for Shock
            table.insert(effects, Effects.new("shock", enemy.x, enemy.y))
            print("Shock effect applied to enemy at", enemy.x, enemy.y)
        end
    end
end



-- Chain Lightning function
function Abilities.chainLightning(enemy, damage, enemies, effects)
    local chainRange = 100
    local maxChains = 5
    local chainedEnemies = { [enemy] = true }

    local function chain(currentEnemy, chainsLeft)
        if chainsLeft <= 0 then return end
        for _, nextEnemy in ipairs(enemies) do
            if not chainedEnemies[nextEnemy] then
                local dx = nextEnemy.x - currentEnemy.x
                local dy = nextEnemy.y - currentEnemy.y
                if dx * dx + dy * dy <= chainRange * chainRange then
                    nextEnemy:takeDamage(damage)
                    table.insert(effects, Effects.new("chain_lightning", currentEnemy.x, currentEnemy.y, nextEnemy.x, nextEnemy.y))
                    chainedEnemies[nextEnemy] = true
                    chain(nextEnemy, chainsLeft - 1)
                    break
                end
            end
        end
    end

    chain(enemy, maxChains)
end

function Abilities.throwShieldBoomerang(owner, damageMultiplier, duration, effects, enemies)
    duration = duration or 3 -- Default duration if not provided

    -- The closest enemy should already be nearby due to auto-attack logic, so we can directly calculate it.
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

    -- Proceed only if there is an enemy to target
    if closestEnemy then
        local shield = {
            x = owner.x,
            y = owner.y,
            speed = 300,
            radius = 15,
            maxDistance = 150, -- Maximum distance the shield can travel
            traveledDistance = 0, -- Track how far it has traveled
            damage = owner.damage * damageMultiplier,
            direction = math.atan2(closestEnemy.y - owner.y, closestEnemy.x - owner.x), -- Target the closest enemy
            returning = false,
            startX = owner.x,
            startY = owner.y,
            timer = 0,
            duration = duration,
            isDead = false,
            rotation = 0, -- Initial rotation angle
            rotationSpeed = 10 -- Speed of rotation (adjust as needed)
        }

        -- Update function for the shield
        shield.update = function(self, dt)
            self.timer = self.timer + dt
            if self.isDead then return end
            
             -- Increment the rotation angle
            self.rotation = self.rotation + self.rotationSpeed * dt

            if not self.returning then
                -- Move toward the target
                local dx = math.cos(self.direction) * self.speed * dt
                local dy = math.sin(self.direction) * self.speed * dt
                self.x = self.x + dx
                self.y = self.y + dy
                self.traveledDistance = self.traveledDistance + math.sqrt(dx * dx + dy * dy)

                -- Start returning if the shield reaches max distance
                if self.traveledDistance >= self.maxDistance then
                    self.returning = true
                end
            else
                -- Return back to the owner
                local dx = owner.x - self.x
                local dy = owner.y - self.y
                local distToOwner = math.sqrt(dx * dx + dy * dy)
                if distToOwner < self.speed * dt then
                    self.isDead = true -- End the boomerang effect
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
                    enemy:takeDamage(self.damage)
                end
            end
        end

        -- Draw the shield visually
   shield.draw = function(self)
    love.graphics.setColor(1, 1, 1)  -- Ensure the sprite is drawn with full color
    love.graphics.draw(
        shieldImage,
        self.x,
        self.y,
        self.rotation,  -- Use self.rotation for spinning
        2, 2,
        shieldImage:getWidth() / 2,
        shieldImage:getHeight() / 2
    )
end


        -- Add the shield to the effects list
        table.insert(effects, shield)
    end
end


-- Function to apply effects based on projectile type and abilities
function Abilities.applyEffects(proj, enemy, attacker, enemies, effects, sounds, summonedEntities, damageNumbers, attackType)


    -- Determine the abilities based on attack type
    local abilities = attacker and attacker.abilities
    if not abilities then return end

    -- Iterate over abilities and apply relevant ones based on attack type
 for abilityName, ability in pairs(abilities) do
        if ability.attackType == attackType then
            if math.random() < ability.procChance then
                if ability.effect then
                    -- Ensure statusEffect exists before applying
                    if ability.statusEffect then
                        ability.effect(attacker, enemy, effects, sounds, summonedEntities, enemies)
                    else
                        print("Warning: statusEffect is nil for ability " .. abilityName)
                    end
                end
            end
        end
    end
end




return Abilities
