-- Projectile.lua

local Projectile = {}
Projectile.__index = Projectile

local EnemyProjectile = {}
EnemyProjectile.__index = EnemyProjectile

local Effects = require("effects")
local Collision = require("collision")
local Abilities = require("abilities")

local sqrt = math.sqrt
local sin = math.sin
local cos = math.cos
local random = math.random

-- EnemyProjectile Class (if needed)
function EnemyProjectile:new(startX, startY, targetX, targetY, damage, options)
    options = options or {}  -- Ensure options is a table
    local instance = setmetatable({}, EnemyProjectile)
    instance.x = startX
    instance.y = startY
    instance.startX = startX
    instance.startY = startY
    instance.targetX = targetX
    instance.targetY = targetY
    instance.damage = damage
    instance.speed = options.speed or 200
    instance.radius = options.radius or 5  -- Explicit default radius
    instance.isDead = false
    instance.statusEffect = options.statusEffect
    instance.attackRange = options.attackRange or 300

    -- Assign type and animation properties
    instance.type = options.type or "default"
    instance.frames = options.frames or {}
    instance.animationSpeed = options.animationSpeed or 0.2

    if instance.type == "spiderspit" then
        instance.frameTimer = 0
        instance.currentFrame = 1
    end

    -- Calculate direction
    local dx = targetX - startX
    local dy = targetY - startY
    local distance = sqrt(dx * dx + dy * dy)
    instance.velX = (dx / distance) * instance.speed
    instance.velY = (dy / distance) * instance.speed

    return instance
end

-- Projectile Constructor
function Projectile.new(x, y, targetX, targetY, type, damage, abilities, owner, attackRange, globalEffects, globalEnemies, sounds, summonedEntities, damageNumbers, options)
    options = options or {}
    local self = setmetatable({}, Projectile)
    self.x = x
    self.y = y
    self.startX = x
    self.startY = y
    self.targetX = targetX or x
    self.targetY = targetY or y
    self.type = type
    self.speed = 300
    self.damage = damage
    self.abilities = abilities or {}
    self.isDead = false
    self.radius = options.radius or 5
    self.hasTrail = options.hasTrail or false
    self.owner = owner
    self.attackRange = attackRange or 210
    self.life = 5  -- Default lifespan
    
    self.globalEffects = globalEffects
    self.globalEnemies = globalEnemies
    self.sounds = sounds
    self.summonedEntities = summonedEntities
    self.damageNumbers = damageNumbers
    
    self.color = options.color or {1, 1, 1, 1}
    self.particleSystem = options.particleSystem

    self.direction = math.atan2(self.targetY - self.y, self.targetX - self.x)
    self.velX = cos(self.direction) * self.speed
    self.velY = sin(self.direction) * self.speed

    if abilities and abilities["Explosive Fireballs"] and abilities["Explosive Fireballs"].rank >= 1 then
        self.onHit = function(self, enemy)
            if abilities["Explosive Fireballs"].rank >= 3 then
                enemy:applyStatusEffect({name = "Ignite", duration = 5, damagePerSecond = 10})
                table.insert(self.globalEffects, Effects.new("ignite", enemy.x, enemy.y, nil, nil, enemy))
            end
            Abilities.areaDamage(enemy.x, enemy.y, 100, self.damage, self.globalEnemies)
            table.insert(self.globalEffects, Effects.new("explosion", enemy.x, enemy.y))
        end
    elseif abilities and abilities["Snow Explosion"] and abilities["Snow Explosion"].rank >= 1 then
        self.onHit = function(self, enemy)
            enemy:applyStatusEffect({name = "Freeze", duration = 3, damagePerSecond = 0})
            table.insert(self.globalEffects, Effects.new("freeze", enemy.x, enemy.y, nil, nil, enemy))
            Abilities.areaDamage(enemy.x, enemy.y, 60, self.damage, self.globalEnemies)
            table.insert(self.globalEffects, Effects.new("snow_explosion", enemy.x, enemy.y, nil, nil, enemy))
        end
    else
        self.onHit = function(self, enemy)
            if self.damage > 0 then
                enemy:takeDamage(
                    self.damage,
                    self.damageNumbers,
                    self.globalEffects,
                    self.type,
                    self.owner,
                    "projectile",
                    false
                )
            end
        end
    end

    return self
end

-- Projectile:update (optimized)
function Projectile:update(dt, effects, enemies, damageNumbers)
    assert(self.radius, "Projectile missing radius.")
    if self.isDead then 
        return 
    end

    -- Move projectile
    self.x = self.x + self.velX * dt
    self.y = self.y + self.velY * dt

    if self.particleSystem then self.particleSystem:update(dt) end

    if self.hasTrail then
        if self.type == "Emberfiend" then
            table.insert(effects, Effects.new("fireball_trail", self.x, self.y, {1, 0.5, 0}, nil, self.type))
        elseif self.type == "Grimreaper" then
            table.insert(effects, Effects.new("arcane_trail", self.x, self.y, {0.6, 0, 1}, nil, self.type))
        elseif self.type == "Stormlich" then
            table.insert(effects, Effects.new("spear_glow", self.x, self.y, {0, 0, 1}, nil, self.type))
        elseif self.type == "ArcaneEcho" then
            table.insert(effects, Effects.new("arcane_echo_trail", self.x, self.y, {1, 0, 1}, nil, self.type))
        end
    end

    -- Collision check with enemies (using squared distances)
    for _, enemy in ipairs(enemies) do
        local cx, cy, cr = enemy:getCollisionData()
        if Collision.checkCircle(self.x, self.y, self.radius, cx, cy, cr) then
            if not self.isDead then
                table.insert(effects, Effects.new("hit_spark", enemy.x, enemy.y))
                if self.onHit then self.onHit(self, enemy) end
                self.isDead = true
            end
            break
        end
    end

    local dx = self.x - self.startX
    local dy = self.y - self.startY
    local distanceTraveled = sqrt(dx * dx + dy * dy)
    if distanceTraveled > self.attackRange then
        self.isDead = true
    end
end

-- Draw Method for a projectile.
function Projectile:draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.direction)
    love.graphics.setColor(unpack(self.color))

    if self.type == "Grimreaper" then
        self:drawArrow()
    elseif self.type == "Emberfiend" then
        self:drawFireball()
    elseif self.type == "Stormlich" then
        self:drawSpear()
    elseif self.type == "ArcaneEcho" then
        love.graphics.circle("fill", 0, 0, self.radius)
        love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.5)
        love.graphics.circle("line", 0, 0, self.radius + 3)
    else
        love.graphics.circle("fill", 0, 0, self.radius)
    end

    love.graphics.setColor(1, 1, 1, 1)
    if self.particleSystem then
        love.graphics.draw(self.particleSystem, 0, 0)
    end
    love.graphics.pop()
end

-- Specific Draw Functions (unchanged)
function Projectile:drawArrow()
    love.graphics.setColor(0.5, 0.25, 0)
    love.graphics.setLineWidth(2)
    love.graphics.line(-10, 0, 10, 0)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.polygon("fill", 10, 0, 5, -3, 5, 3)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.polygon("fill", -10, 0, -15, -3, -15, 3)
end

function Projectile:drawFireball()
    love.graphics.setColor(0.678, 0.251, 0.188, 1)
    love.graphics.circle("fill", 0, 0, 7)
    love.graphics.setColor(0.937, 0.62, 0.306, 1)
    love.graphics.polygon("fill", 
        0, -7,
        -3, -4,
        -1.5, -4,
        -1.5, 4,
        -3, 4,
        0, 7
    )
    love.graphics.polygon("fill", 
        0, -7,
        3, -4,
        1.5, -4,
        1.5, 4,
        3, 4,
        0, 7
    )
    love.graphics.setColor(0.651, 0.6, 0.596, 0.5)
    love.graphics.polygon("fill", 
        0, -7,
        -2, -5,
        -1, -5,
        -1, 5,
        -2, 5,
        0, 7
    )
    love.graphics.polygon("fill", 
        0, -7,
        2, -5,
        1, -5,
        1, 5,
        2, 5,
        0, 7
    )
    love.graphics.setColor(1, 1, 1, 1)
end

function Projectile:drawArcaneMissile()
    love.graphics.setColor(0.6, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(-10, 0, 10, 0)
    love.graphics.setColor(0.8, 0.5, 1)
    love.graphics.polygon("fill", 10, 0, 5, -3, 5, 3)
    love.graphics.setColor(0.3, 0.1, 0.3)
    love.graphics.polygon("fill", -10, 0, -15, -3, -15, 3)
end

function Projectile:drawSpear()
    love.graphics.setColor(1, 0.84, 0)
    love.graphics.setLineWidth(3)
    love.graphics.line(-15, 0, 15, 0)
    love.graphics.polygon("fill", 
        15, 0, 
        10, -5, 
        10, 5
    )
end

-- Batch removal helper: given a table of projectiles, return a new table with only those not marked dead.
function Projectile.batchRemove(projectiles)
    local newProjectiles = {}
    for i = 1, #projectiles do
        if not projectiles[i].isDead then
            table.insert(newProjectiles, projectiles[i])
        end
    end
    return newProjectiles
end

return {
    Projectile = Projectile,
    EnemyProjectile = EnemyProjectile
}
