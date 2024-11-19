local Projectile = require("projectile")
local Abilities = require("abilities")
local Collision = require("collision")
local Effects = require("effects")
local DamageNumber = require("damage_number")

local rangerSprite = love.graphics.newImage("assets/ranger.png")
rangerSprite:setFilter("nearest", "nearest")

local spearwardenSprite = love.graphics.newImage("assets/spearwarden.png")
spearwardenSprite:setFilter("nearest", "nearest")

local mageSprite = love.graphics.newImage("assets/mage.png")
mageSprite:setFilter("nearest", "nearest")

local Player = {}
Player.__index = Player

local sounds = {
    playerAttack = {
        ranger = love.audio.newSource("ranger_attack.wav", "static"),
        mage = love.audio.newSource("mage_attack.wav", "static"),
        spearwarden = love.audio.newSource("spearwarden_attack.wav", "static"),
    },
    statusEffect = {
        Ignite = love.audio.newSource("ignite.wav", "static"),
        Poison = love.audio.newSource("poison.wav", "static"),
    },
    ability = {
        arrowSpreadShot = love.audio.newSource("arrow_spread_shot.wav", "static"),
        summon_wolf = love.audio.newSource("summon_wolf.wav", "static"),
        explosion = love.audio.newSource("explosion.wav", "static"),
        chain_lightning = love.audio.newSource("chain_lightning.wav", "static"),
      frost_explosion = love.audio.newSource("frost_explosion.wav", "static"),
        shieldThrow = love.audio.newSource("shield_throw.wav", "static"),
    },
}

function Player.new()
    local self = setmetatable({}, Player)
    
self.characters = {
    ranger = {
        x = 2000 - 8,  -- Adjust for half of the width
        y = 2000 - 8,  -- Adjust for half of the height
        type = "ranger",
        width = 32, height = 32,
        attackSpeed = 2, baseAttackSpeed = 2, attackTimer = 0, damage = 10, baseDamage = 10, 
        health = 110, maxHealth = 110, baseMaxHealth = 110, attackRange = 210, baseAttackRange = 210, 
        abilities = {},  -- Start with no abilities
        radius = 10, speed = 60, statusEffects = {},
        owner = self,  -- Reference to Player instance for projectiles
        damageFlashTimer = 0,
        sprite = rangerSprite,  -- Assign the sprite
        isFacingRight = true,   -- Start facing right
    },
    mage = {
        x = 2020 - 8,  -- Adjust for half of the width
        y = 2000 - 8,  -- Adjust for half of the height
        type = "mage",
        width = 32, height = 32,
        attackSpeed = 1, baseAttackSpeed = 1, attackTimer = 0, damage = 25, baseDamage = 25,
        health = 88, maxHealth = 88, baseMaxHealth = 88, attackRange = 185, baseAttackRange = 185,
        abilities = {},  -- Start with no abilities
        radius = 10, speed = 60, statusEffects = {},
        owner = self,
        damageFlashTimer = 0,
        sprite = mageSprite,  -- Assign the sprite
        isFacingRight = true,   -- Start facing right
    },
    spearwarden = {
        x = 2040 - 8,  -- Adjust for half of the width
        y = 2000 - 8,  -- Adjust for half of the height
        type = "spearwarden",
        width = 32, height = 32,
        attackSpeed = 1.5, baseAttackSpeed = 1.5, attackTimer = 0, damage = 35, baseDamage = 35,
        health = 132, maxHealth = 132, baseMaxHealth = 132, attackRange = 165, baseAttackRange = 165,
        abilities = {},  -- Start with no abilities
        radius = 10, speed = 60, statusEffects = {},
        owner = self,
        damageFlashTimer = 0,
        sprite = spearwardenSprite,  -- Assign the sprite
        isFacingRight = true,   -- Start facing right
    }
}

  
    self.damageFlashTimer = 0  -- Flash timer to control red flash when damaged
    self.summonedEntities = {}
    self.projectiles = {}
    self.damageNumbers = {}
    self:initializeAbilities()
    return self
end

function Player:initializeAbilities()
    -- Upgrade abilities for each character
    --Abilities.upgradeAbility(self.characters.ranger, "Arrow Spread Shot")
    --Abilities.upgradeAbility(self.characters.ranger, "Poison Shot")
    --Abilities.upgradeAbility(self.characters.ranger, "Summon Wolf")

    --Abilities.upgradeAbility(self.characters.mage, "Explosive Fireballs")
    --Abilities.upgradeAbility(self.characters.mage, "Frost Explosion")

    --Abilities.upgradeAbility(self.characters.spearwarden, "Chain Lightning")
    --Abilities.upgradeAbility(self.characters.spearwarden, "Shield Throw")
end


function Player:applyStatusEffect(char, effect)
    char.statusEffects[effect.name] = {
        duration = effect.duration,
        damagePerSecond = effect.damagePerSecond,
        timer = 0,
    }
end

function Player:draw(zoomFactor)
    for _, char in pairs(self.characters) do
        if char.health > 0 then
            love.graphics.push()
            love.graphics.setColor(1, 1, 1)
            
            -- Apply zoom factor to position
          love.graphics.translate(char.x, char.y)

            
            -- Adjust scaleFactor to include zoom
            local scaleFactor = 2 
            local scaleX = char.isFacingRight and -scaleFactor or scaleFactor
            local scaleY = scaleFactor
            
            love.graphics.draw(
                char.sprite,
                0, 0, 0,
                scaleX, scaleY,
                char.sprite:getWidth() / 2,
                char.sprite:getHeight() / 2
            )
            love.graphics.pop()
        end
    end

    
    -- Draw the projectiles
    for _, proj in ipairs(self.projectiles) do
        proj:draw()
    end
    
    -- Optionally, draw damage numbers
    for _, dmgNum in ipairs(self.damageNumbers) do
        dmgNum:draw()
    end
end

-- Restored movement logic
function Player:updateMovement(dt)
    local collisionDistance = 25  -- Adjust how close characters can get before they start avoiding each other
    local moveSpeedFactor = 0.5   -- Adjust this to slow down how strongly they avoid each other

    for _, char in pairs(self.characters) do
        if char.destination then
            local dirX = char.destination.x - char.x
            local dirY = char.destination.y - char.y
            local distance = math.sqrt(dirX^2 + dirY^2)
            
            -- Determine if the character is moving left or right
if dirX < 0 then
    char.isFacingRight = false  -- Moving left
elseif dirX > 0 then
    char.isFacingRight = true   -- Moving right
end


            -- Move towards destination with some slight randomness and avoid formation
            if distance > 5 then
             local movementSpeed = char.speed or 100  -- Use character's speed, with a fallback value
local dx = (dirX / distance) * movementSpeed * dt
local dy = (dirY / distance) * movementSpeed * dt


                -- Avoid other characters to create a natural movement behavior
                for _, otherChar in pairs(self.characters) do
                    if char ~= otherChar and otherChar.health > 0 then
                        local distX = otherChar.x - char.x
                        local distY = otherChar.y - char.y
                        local distBetween = math.sqrt(distX^2 + distY^2)

                        if distBetween < collisionDistance then
                            -- Apply repulsion to avoid colliding too closely
                            local repulsionFactor = (collisionDistance - distBetween) * moveSpeedFactor
                            dx = dx - (distX / distBetween) * repulsionFactor * dt
                            dy = dy - (distY / distBetween) * repulsionFactor * dt
                        end
                    end
                end

                -- Apply the calculated movement
                char.x = char.x + dx
                char.y = char.y + dy
            else
                char.destination = nil  -- Reached destination
            end
        end
    end
end

function Player:setAllDestinations(x, y)
    -- Add randomness to destination
    local offsets = {
        {x = math.random(-20, 20), y = math.random(-20, 20)},  -- Random offset for ranger
        {x = math.random(-20, 20), y = math.random(-20, 20)},  -- Random offset for mage
        {x = math.random(-20, 20), y = math.random(-20, 20)}   -- Random offset for spearwarden
    }

    local i = 1
    for _, char in pairs(self.characters) do
        char.destination = { x = x + offsets[i].x, y = y + offsets[i].y }
        i = i + 1
    end
end

-- Restored status checks
function Player:isDefeated()
    -- Check if all characters are dead
    for _, char in pairs(self.characters) do
        if char.health > 0 then
            return false
        end
    end
    return true
end

-- Restored attack and ability handling logic
function Player:updateAttacks(char, dt, enemies, effects)
    -- Update the attack timer
    char.attackTimer = char.attackTimer + dt

    -- Check if character is ready to attack
    if char.attackTimer >= (1 / char.attackSpeed) then
        char.attackTimer = 0 -- Reset attack timer

        -- Find an enemy within attack range
        for _, enemy in ipairs(enemies) do
            if self:isInRange(char, enemy) then
                -- Perform the attack
                self:attack(char, enemy, effects, self.summonedEntities, enemies, sounds, self.damageNumbers)

                break -- Attack only one enemy at a time
            end
        end
    end
end

function Player:updateStatusEffects(char, dt)
    -- Handle status effects like Poison and Ignite
    for effectName, effect in pairs(char.statusEffects) do
        effect.timer = effect.timer + dt
        if effect.timer >= effect.duration then
            char.statusEffects[effectName] = nil -- Remove expired status effect
        else
            -- Apply effect over time
if effectName == "Poison" or effectName == "Ignite" then
    char.health = char.health - effect.damagePerSecond * dt
    if char.health < 0 then
        char.health = 0
    end

    -- Add this line to trigger the red flash:
     char.damageFlashTimer = 1  -- Set the timer for 1 second red flash

    -- Add a damage number (if applicable)
    table.insert(self.damageNumbers, DamageNumber.new(char.x, char.y, effect.damagePerSecond * dt, {0, 1, 0}))
end

        end
    end
end

function Player:isInRange(char, enemy)
    local range = char.attackRange
    local dx = char.x - enemy.x
    local dy = char.y - enemy.y
    local distanceSquared = dx * dx + dy * dy
    return distanceSquared < range * range
end

function Player:update(dt, enemies, effects, zoomFactor)
    -- Decrease the damage flash timer
    for _, char in pairs(self.characters) do
        if char.damageFlashTimer > 0 then
            char.damageFlashTimer = char.damageFlashTimer - dt
            if char.damageFlashTimer < 0 then
                char.damageFlashTimer = 0
            end
        end
    end

    -- Update movement for each character
    for _, char in pairs(self.characters) do
        if char.health > 0 then
            -- Store last position before movement
            char.lastX = char.x
            char.lastY = char.y
            
            -- Update movement based on input or AI
            self:updateMovement(dt)
            
            -- Handle collisions
            checkPlayerWallCollision(char, maze.walls, maze.cornerCircles)
            
            -- Update attacks and status effects
            self:updateAttacks(char, dt, enemies, effects)
            self:updateStatusEffects(char, dt)
        end
    end

    -- Update projectiles and damage numbers
    for i = #self.projectiles, 1, -1 do
        local proj = self.projectiles[i]
        proj:update(dt, effects, enemies)
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
end


function Player:attack(char, enemy, effects, summonedEntities, enemies, sounds, damageNumbers)
    local abilities = char.abilities  -- This must contain the abilities for the character
    local projCount = 1
    local spreadAngle = 0
    local useAbility = false
    local damageMultiplier = 1

    -- Loop through the character's abilities to check if any abilities should proc
    for abilityName, ability in pairs(abilities) do
        if ability and ability.procChance and ability.effect then
            if math.random() < ability.procChance then
                -- Apply the ability's effect if it procs
                ability.effect(char, enemy, effects, sounds, summonedEntities, enemies)
                useAbility = true
            end
        end
    end

    -- Default to a normal attack if no abilities proc
    if not useAbility then
        projCount = 1
    end

    -- Process projectiles
    local angleBetween = projCount > 1 and spreadAngle / (projCount - 1) or 0
    local baseAngle = math.atan2(enemy.y - char.y, enemy.x - char.x) - (spreadAngle / 2)

    for i = 0, projCount - 1 do
        local angle = baseAngle + i * angleBetween
        local projRange = char.attackRange
        local targetX = char.x + math.cos(angle) * projRange
        local targetY = char.y + math.sin(angle) * projRange

        -- Create projectile and ensure abilities are attached
        local proj = Projectile.new(
            char.x, 
            char.y, 
            targetX, 
            targetY, 
            char.type, 
            char.damage * damageMultiplier,
            abilities,  -- Attach abilities to the projectile
            char
        )

        proj.abilities = char.abilities  -- Make sure abilities are passed to the projectile
        proj.hasTrail = true
        proj.sourceType = char.type

        -- Apply OnHit abilities for projectile attacks when the projectile hits
        proj.onHit = function(self, target)
            -- Apply damage to the target
            target:takeDamage(proj.damage, damageNumbers, effects, proj.sourceType, char)

            -- Apply any OnHit abilities
            Abilities.applyEffects(proj, target, char, enemies, effects, sounds, summonedEntities, damageNumbers)
        end

        table.insert(self.projectiles, proj)
    end

    -- Play attack sound
    if sounds and sounds.playerAttack and sounds.playerAttack[char.type] then
        sounds.playerAttack[char.type]:play()
    end
end





function Player:applyAbilityEffects(proj, enemy, enemies, effects)
    Abilities.applyEffects(proj, enemy, enemies, effects, sounds, self.summonedEntities, self.damageNumbers)
end

return Player
