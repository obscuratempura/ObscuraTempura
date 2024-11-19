-- Projectile.lua

local Projectile = {}
local EnemyProjectile = {}

Projectile.__index = Projectile
EnemyProjectile.__index = EnemyProjectile

local Effects = require("effects")
local Collision = require("collision")
local Abilities = require("abilities")

-- In EnemyProjectile's constructor
function EnemyProjectile:new(startX, startY, targetX, targetY, damage, options)
     local instance = setmetatable({}, EnemyProjectile)  -- use 'instance' instead of 'self'
    self.x = startX
    self.y = startY
    self.startX = startX
    self.startY = startY
    self.targetX = targetX
    self.targetY = targetY
    self.damage = damage
    self.speed = options.speed or 200
    self.radius = options.radius or 5
    self.isDead = false
    self.statusEffect = options.statusEffect
    self.attackRange = options.attackRange or 300

    -- Calculate direction based on target
    local dx = targetX - startX
    local dy = targetY - startY
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Normalize direction
    self.velX = (dx / distance) * self.speed
    self.velY = (dy / distance) * self.speed

    return self
end



function EnemyProjectile:update(dt, players)
    print("Entering EnemyProjectile:update()")  -- Debug: Confirm entry
    -- Existing code follows...
    -- Move the projectile
    self.x = self.x + self.velX * dt
    self.y = self.y + self.velY * dt

    -- Check collision with player characters
    for _, char in pairs(players) do
        if char.health > 0 and Collision.checkCircle(self.x, self.y, self.radius, char.x, char.y, char.radius) then
            print("Collision detected with player:", char.type)
            
            -- Ensure damage is applied correctly
            if type(self.damage) == "number" and self.damage > 0 then
                char.health = char.health - self.damage
                print(char.type .. " took " .. self.damage .. " damage. Remaining health: " .. char.health)
                
                if char.health <= 0 then
                    char.health = 0
                    print(char.type .. " has died!")
                end

                -- Apply status effect if one exists
                if self.statusEffect then
                    char:applyStatusEffect(self.statusEffect)
                end

                -- Add hit effect
                table.insert(effects, Effects.new("hit_spark", char.x, char.y))

                -- Mark projectile as dead after collision
                self.isDead = true
                break
            else
                print("Invalid damage value: ", self.damage)
            end
        else
            print("No collision detected for player:", char.type)
        end
    end

    -- Check if projectile has traveled its range
    local distanceTraveled = math.sqrt((self.x - self.startX)^2 + (self.y - self.startY)^2)
    if distanceTraveled > self.attackRange then
        self.isDead = true
    end

    -- Remove if out of bounds
    if self.x < 0 or self.x > 4000 or self.y < 0 or self.y > 4000 then
        self.isDead = true
    end
end








function Projectile.new(x, y, targetX, targetY, type, damage, abilities, owner,  attackRange)
    local self = setmetatable({}, Projectile)
    self.x = x
    self.y = y
    self.startX = x
    self.startY = y

    -- Set default values for targetX and targetY if they are nil
    self.targetX = targetX or x
    self.targetY = targetY or y
    
    self.type = type
    self.speed = 300
    self.damage = damage
    self.abilities = abilities or {}
    self.isDead = false
    self.radius = 5
    self.hasTrail = false
    self.owner = owner -- Reference to the character who fired the projectile
    self.attackRange = attackRange or 210  -- Default attack range if nil
    -- Calculate direction
    self.direction = math.atan2(self.targetY - self.y, self.targetX - self.x) -- Calculate direction

    self.sourceType = type  -- Ensure sourceType is set if not already
  
    
    -- Calculate velocity components
    self.velX = math.cos(self.direction) * self.speed
    self.velY = math.sin(self.direction) * self.speed
   
      
       -- Always ensure that onHit is assigned, even if no special ability is present
    self.onHit = function(self, target)
        if abilities and abilities["Explosive Fireballs"] then
            Abilities.applyEffects(self, target, owner, enemies, effects, sounds, summonedEntities, damageNumbers, "projectile")
        elseif abilities and abilities["Frost Explosion"] then
            Abilities.applyEffects(self, target, owner, enemies, effects, sounds, summonedEntities, damageNumbers, "projectile")
        else
            -- Default action if no ability matches
            Abilities.applyEffects(self, target, owner, enemies, effects, sounds, summonedEntities, damageNumbers, "projectile")
        end
    end



    return self
end

function Projectile:update(dt, effects, enemies)
    -- Move towards target
    self.x = self.x + self.velX * dt
    self.y = self.y + self.velY * dt

    local distanceTraveled = math.sqrt((self.x - self.startX)^2 + (self.y - self.startY)^2)
    if distanceTraveled > self.attackRange then
        self.isDead = true
        return
    end

    -- Add particle trail if needed
    if self.hasTrail then
        if self.type == "ranger" then
            table.insert(effects, Effects.new("arrow_trail", self.x, self.y, {0, 1, 0}, nil, self.type))
            
        elseif self.type == "mage" then
            table.insert(effects, Effects.new("arcane_trail", self.x, self.y, {0.6, 0, 1}, nil, self.type))
        
        elseif self.type == "spearwarden" then
            table.insert(effects, Effects.new("spear_glow", self.x, self.y, {0, 0, 1}, nil, self.type))
            
        end  -- Close this block
    end  -- Also close the `if self.hasTrail` block


    -- Check for collision with enemies
    for _, enemy in ipairs(enemies) do
        if enemy and Collision.checkCircle(self.x, self.y, self.radius, enemy.x, enemy.y, enemy.radius) then
            -- Apply damage to the enemy
            enemy:takeDamage(self.damage, nil, effects, self.sourceType, self.owner, "projectile")

           

            -- Call the onHit function for special abilities (like Explosive Fireballs)
            if self.onHit then
               
                self.onHit(self, enemy)  -- Ensure that we call onHit here
            else
                
            end

            -- Apply status effects based on abilities or sourceType
            if self.type == "mage" and self.abilities["Explosive Fireballs"] and self.abilities["Explosive Fireballs"].rank >= 1 then
                -- Define what happens when the projectile hits an enemy (i.e., triggers the explosion)
                self.onHit = function(proj, enemy)
                    -- Check if the rank of Explosive Fireballs is 3 or higher
                    if self.abilities["Explosive Fireballs"].rank >= 3 then
                        -- Apply Ignite status effect only if the rank is 3 or higher
                        enemy:applyStatusEffect({name = "Ignite", duration = 5, damagePerSecond = 10})
                        table.insert(effects, Effects.new("ignite", enemy.x, enemy.y, nil, nil, enemy))
                    end

                    -- Explosion happens here, applying area damage
                    Abilities.areaDamage(enemy.x, enemy.y, 100, self.damage, enemies)
                    table.insert(effects, Effects.new("explosion", enemy.x, enemy.y))
                end
            end

            if self.abilities["Frost Explosion"] and self.abilities["Frost Explosion"].rank >= 1 then
                self.onHit = function(proj, enemy)
                    -- Apply Freeze effect to the enemy
                    enemy:applyStatusEffect({name = "Freeze", duration = 3, damagePerSecond = 0})
                    table.insert(effects, Effects.new("freeze", enemy.x, enemy.y, nil, nil, enemy))

                    -- Add snowy explosion effect on hit
                    Abilities.areaDamage(enemy.x, enemy.y, 60, self.damage, enemies)
                    table.insert(effects, Effects.new("snow_explosion", enemy.x, enemy.y, nil, nil, enemy))

                    -- Mark the projectile as dead upon collision
                    self.isDead = true
                end
            end

            -- Mark the projectile as dead upon collision
            self.isDead = true
        end
    end

    -- Remove projectile if it goes out of bounds (assuming game area is 4000x4000)
    if self.x < 0 or self.x > 4000 or self.y < 0 or self.y > 4000 then
        self.isDead = true
    end
end




function Projectile:draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.direction)  -- Rotate to face movement direction

    if self.type == "ranger" then
        self:drawArrow()
      elseif self.type == "mage" then
        self:drawArcaneMissile()
    elseif self.type == "spearwarden" then
        self:drawSpear()
    end

    love.graphics.pop()
end

-- Function to draw Ranger's Arrow
function Projectile:drawArrow()
    -- Draw arrow shaft
    love.graphics.setColor(0.5, 0.25, 0)  -- Brown color for shaft
    love.graphics.setLineWidth(2)
    love.graphics.line(-10, 0, 10, 0)  -- Shaft from (-10,0) to (10,0)

    -- Draw arrowhead
    love.graphics.setColor(0.6, 0.6, 0.6)  -- Gray color for arrowhead
    love.graphics.polygon("fill", 10, 0, 5, -3, 5, 3)

    -- Draw fletching
    love.graphics.setColor(0.3, 0.3, 0.3)  -- Grey color for fletching
    love.graphics.polygon("fill", -10, 0, -15, -3, -15, 3)
end


-- Function to draw Mage's Fireball
function Projectile:drawFireball()
    -- Draw main fireball
    love.graphics.setColor(1, 0.5, 0)  -- Orange color for fireball
    love.graphics.circle("fill", 0, 0, 7)

    -- Draw flames
    love.graphics.setColor(1, 1, 0)  -- Yellow color for flames
    love.graphics.polygon("fill", 
        0, -7, 
        -3, -12, 
        3, -12
    )
    love.graphics.polygon("fill", 
        0, 7, 
        -3, 12, 
        3, 12
    )
    love.graphics.polygon("fill", 
        -7, 0, 
        -12, -3, 
        -12, 3
    )
    love.graphics.polygon("fill", 
        7, 0, 
        12, -3, 
        12, 3
    )
end

-- Function to draw Mage's Arcane Missile with particle trail
function Projectile:drawArcaneMissile()
    -- Draw arrow shaft (purple color)
    love.graphics.setColor(0.6, 0, 1)  -- Purplish color for arcane shaft
    love.graphics.setLineWidth(2)
    love.graphics.line(-10, 0, 10, 0)  -- Shaft from (-10,0) to (10,0)

    -- Draw arrowhead (lighter purple)
    love.graphics.setColor(0.8, 0.5, 1)  -- Lighter purple color for arrowhead
    love.graphics.polygon("fill", 10, 0, 5, -3, 5, 3)

    -- Draw fletching (dark purple)
    love.graphics.setColor(0.3, 0.1, 0.3)  -- Darker purple for fletching
    love.graphics.polygon("fill", -10, 0, -15, -3, -15, 3)
end







-- Function to draw Spearwarden's Spear
function Projectile:drawSpear()
    -- Draw spear shaft (gold color)
    love.graphics.setColor(1, 0.84, 0)  -- Yellow-gold color for the entire spear shaft
    love.graphics.setLineWidth(3)
    love.graphics.line(-15, 0, 15, 0)  -- Shaft from (-15,0) to (15,0)

    -- Draw spear tip (same yellow-gold color as shaft)
    love.graphics.polygon("fill", 
        15, 0, 
        10, -5, 
        10, 5
    )
end


return Projectile
