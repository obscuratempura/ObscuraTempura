-- effects.lua

local Effects = {}
Effects.__index = Effects




local shieldImage = love.graphics.newImage("assets/shield_throw.png")

local thornImage = love.graphics.newImage("assets/thorn.png")
thornImage:setFilter("nearest", "nearest")
local visageImage = love.graphics.newImage("assets/visage.png")
visageImage:setFilter("nearest", "nearest")
-- Color Palette Definitions
local darkRedBrown = {86/255, 33/255, 42/255, 1}
local deepPurple = {67/255, 33/255, 66/255, 1}
local grayishPurple = {95/255, 87/255, 94/255, 1}
local mutedTeal = {77/255, 102/255, 96/255, 1}
local rustRed = {173/255, 64/255, 48/255, 1}
local mutedBrick = {144/255, 75/255, 65/255, 1}
local darkRose = {155/255, 76/255, 99/255, 1}
local mutedOliveGreen = {149/255, 182/255, 102/255, 1}
local peachyOrange = {231/255, 155/255, 124/255, 1}
local warmGray = {166/255, 153/255, 152/255, 1}
local paleYellow = {246/255, 242/255, 195/255, 1}
local darkTeal = {47/255, 61/255, 58/255, 1}
local orangeGold = {239/255, 158/255, 78/255, 1}
local pastelMint = {142/255, 184/255, 158/255, 1}

-- New Additions
local smokyBlue = {70/255, 85/255, 95/255, 1}
local burntSienna = {233/255, 116/255, 81/255, 1}
local sageGreen = {148/255, 163/255, 126/255, 1}
local dustyLavender = {174/255, 160/255, 189/255, 1}
local mustardYellow = {218/255, 165/255, 32/255, 1}
local terraCotta = {226/255, 114/255, 91/255, 1}
local charcoalGray = {54/255, 69/255, 79/255, 1}
local blushPink = {222/255, 173/255, 190/255, 1}
local forestGreen = {34/255, 85/255, 34/255, 1}
local midnightBlue = {25/255, 25/255, 112/255, 1}


-- Updated abilityColors Table
local abilityColors = {
    -- Emberfiend Abilities (Fire-Themed)
    meteor_swarm = rustRed,                -- {173/255, 64/255, 48/255, 1}
    explosive_fireballs = burntSienna,     -- {233/255, 116/255, 81/255, 1}
    ignite = terraCotta,                    -- {226/255, 114/255, 91/255, 1}

    -- Grimreaper Abilities (Dark/Purple-Themed)
    poison = deepPurple,                    -- {67/255, 33/255, 66/255, 1}
    arrow_spread_shot = dustyLavender,      -- {174/255, 160/255, 189/255, 1}
    necrotic_wave = grayishPurple,          -- {95/255, 87/255, 94/255, 1}

    -- Stormlich Abilities (Electric/Yellow-Themed)
    storm_arc = orangeGold,                 -- {239/255, 158/255, 78/255, 1}
    zephyr_shield = mustardYellow,          -- {218/255, 165/255, 32/255, 1}
    blizzard = mustardYellow,           -- {218/255, 165/255, 32/255, 1}

    -- Supportive/General Abilities
    freeze = smokyBlue,                     -- {70/255, 85/255, 95/255, 1}
    shock = paleYellow,                    -- {246/255, 242/255, 195/255, 1}
    life_drain = charcoalGray,             -- {54/255, 69/255, 79/255, 1}
    teleport = midnightBlue,                -- {25/255, 25/255, 112/255, 1}

    -- Defensive Abilities
    shield = darkTeal,                      -- {47/255, 61/255, 58/255, 1}

    -- Summoning Abilities
    summon_goyle = forestGreen,             -- {34/255, 85/255, 34/255, 1}

    -- Default/Fallback Color
    default = warmGray,                     -- {166/255, 153/255, 152/255, 1}
}




local function applyDamage(self, abilityType, radius, defaultDamage)
    for _, enemy in ipairs(self.enemies or {}) do
        if not enemy.isDead then
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            if dx * dx + dy * dy <= (radius or 50) ^ 2 then
                local damage = self.damage or defaultDamage
                enemy:takeDamage(damage, self.damageNumbers, self.effects, abilityType, nil, "damageTaken")
                local color = abilityColors[abilityType] or abilityColors.default
                addDamageNumber(enemy.x, enemy.y, damage, color)
            end
        end
    end
end

-- Load the poison web sprite and create quads for its 3 frames.
local poisonWebImage = love.graphics.newImage("assets/poisonweb.png")
poisonWebImage:setFilter("nearest", "nearest")
local poisonWebFrames = {
  love.graphics.newQuad(0, 0, 16, 16, poisonWebImage:getDimensions()),
  love.graphics.newQuad(16, 0, 16, 16, poisonWebImage:getDimensions()),
  love.graphics.newQuad(32, 0, 16, 16, poisonWebImage:getDimensions())
}


local flameImage = love.graphics.newImage("assets/flame.png")
flameImage:setFilter("nearest", "nearest")
local firebombFrames = {
    love.graphics.newQuad(0, 0, 16, 16, flameImage:getDimensions()),
    love.graphics.newQuad(16, 0, 16, 16, flameImage:getDimensions()),
    love.graphics.newQuad(32, 0, 16, 16, flameImage:getDimensions()),
    love.graphics.newQuad(48, 0, 16, 16, flameImage:getDimensions())
}


function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function Effects.new(type, x, y, targetX, targetY, ownerType, attachedTo, effects, impactRadius, damagePerMeteor, enemies, damageNumbers, duration)
    local self = setmetatable({}, Effects)
    self.source = ownerType  -- now the 'source' is correctly stored
    self.sourceCharacter = attachedTo  -- if that is what you intended

    self.damageNumbers = damageNumbers or {}
    self.type = type
    self.x = x
    self.y = y
    self.targetX = targetX or x
    self.targetY = targetY or y
    self.ownerType = ownerType or "generic"
    self.attachedTo = attachedTo or nil -- Reference to the enemy if attached
    self.targetAttachedTo = nil -- Ensure targetAttachedTo is always initialized
    self.timer = 0
   self.radius = impactRadius or 0

    self.lifetime = 1  -- Set appropriate lifetime based on effect type
    self.age = 0    
    self.isDead = false
    self.effects = effects
    self.impactRadius = impactRadius or 50  -- Default value if not provided
     
    self.damagePerMeteor = damagePerMeteor or 10  -- Default value if not provided
    self.enemies = enemies or {}

    self.color = abilityColors[self.type] or {0.964, 0.949, 0.764, 1} -- Use abilityColors based on type

    -- Set duration based on effect type
    local durations = {
        explosion = 0.3,
        bloodexplosion = 0.5,
        ignite = 5.0,
        fire = 0.5,
        zephyr_shield = 0.5,
        hellblast = 0.5,
        summon_goyle = 0.5,
        teleport = 0.5,
        life_drain = 6.0,
        summon = 0.5,
        shadow_cloak = 0.5,
        hit_spark = 0.2,
        arrow_trail = 0.3,
        fire_flame = 0.5,
        spear_glow = 0.3,
        storm_arc = 0.5,
        poison = 0.5,
        slash = 0.5,
        arcane_trail = 0.4,
        meteor_swarm = 4.0,
        meteor_impact = 0.5,
        static_wave = 1.0,
        freeze = 0.3,
        shock = 0.5, -- Define duration for shock
        magic_ray = 0.2,       -- Add duration for magic_ray
        magic_ray_hit = 0.3,   -- Add duration for magic_ray_hit
        unholy_ground = 5.0,
        fearExplosion = 1.5, 
        necrotic_chain = 0.5,
    }

     self.duration = duration or durations[self.type] or 1.0
    
   
   if type == "phantom_visage" then
    return {
        x = x,
        y = y,
        targetX = targetX or x,
        targetY = targetY or y,
        directionX = (targetX or x) - x,
        directionY = (targetY or y) - y,
        speed = 300,
        isDead = false,
        age = 0,
        duration = 2, -- default duration, adjusted in the ability code
        radius = 8,   -- collision radius
        enemiesHit = {},
        fearDuration = 3,  -- default, adjusted in ability code
        owner = nil,   -- set when created
        damageNumbers = damageNumbers,
        enemies = enemies,
        particles = {},
        particleTimer = 0,
        particleInterval = 0.05,

        update = function(self, dt)
            self.duration = self.duration - dt
            if self.duration <= 0 then
                self.isDead = true
                return
            end

            -- Normalize direction
            local dist = math.sqrt(self.directionX^2 + self.directionY^2)
            if dist > 0 then
                self.directionX = self.directionX / dist
                self.directionY = self.directionY / dist
            end

            -- Move forward
            self.x = self.x + self.directionX * self.speed * dt
            self.y = self.y + self.directionY * self.speed * dt

            -- Particle trail (purple-ish)
            self.particleTimer = self.particleTimer + dt
            if self.particleTimer >= self.particleInterval then
                self.particleTimer = 0
                table.insert(self.particles, {
                    x = self.x,
                    y = self.y,
                    size = love.math.random(2, 4),
                    age = 0,
                    lifetime = 0.5,
                    color = {0.5, 0, 0.5, 1}, -- purple
                })
            end

            -- Update particles
            for i = #self.particles, 1, -1 do
                local p = self.particles[i]
                p.age = p.age + dt
                if p.age >= p.lifetime then
                    table.remove(self.particles, i)
                end
            end

            -- Check collision with enemies
            if self.enemies then
                for _, enemy in ipairs(self.enemies) do
                    if not self.enemiesHit[enemy] and not enemy.isDead then
                        local dx = enemy.x - self.x
                        local dy = enemy.y - self.y
                        local distToEnemy = math.sqrt(dx * dx + dy * dy)
                        if distToEnemy <= self.radius then
                            self.enemiesHit[enemy] = true

                            -- Apply Fear status effect
                            -- The enemy should have a method applyStatusEffect that takes a table {name = "Fear", duration = fearDuration}
                            enemy:applyStatusEffect({
                                name = "Fear",
                                duration = self.fearDuration,
                            })

                            -- Optional: Make the enemy flash purple; handle that in enemy update code if desired.
                            -- Here we just rely on the enemy code to handle fear behavior.
                        end
                    end
                end
            end
        end,
draw = function(self)
    -- Determine scale factors for flipping based on direction
    local sx = self.directionX < 0 and -2 or 2  -- Flip horizontally if traveling left
    local sy = 2  -- Keep vertical scaling the same

    -- Draw the visage sprite
    love.graphics.setColor(1, 1, 1, 1) -- Reset color to full opacity
    love.graphics.draw(
        visageImage,          -- The image
        self.x, self.y,       -- Position
        0,                    -- Rotation
        sx, sy,               -- Scale (flip horizontally if sx is negative)
        visageImage:getWidth() / 2,  -- Offset X (center the image)
        visageImage:getHeight() / 2  -- Offset Y (center the image)
    )

            -- Draw particle trail
            for _, p in ipairs(self.particles) do
                local progress = p.age / p.lifetime
                love.graphics.setColor(p.color[1], p.color[2], p.color[3], (1 - progress))
                love.graphics.circle("fill", p.x, p.y, p.size * (1 - progress))
            end
        end,
    }
end

if type == "poison_explosion" then
    return {
        type = "poison_explosion",
        x = x,
        y = y,
        timer = 0,
        duration = 0.5,  -- same overall duration as your explosion
        isDead = false,
        update = function(self, dt)
            self.timer = self.timer + dt
            if self.timer >= self.duration then
                self.isDead = true
            end
        end,
        draw = function(self)
            local rank = self.attachedTo and self.attachedTo.abilities["Molten Orbs"].rank or 1
            local maxRadius = 50 + (5 * rank)
            local progress = math.min(self.timer / self.duration, 1)

            -- Outer particles: use forestGreen from your palette
            local numOuterParticles = 20
            love.graphics.setColor(forestGreen[1], forestGreen[2], forestGreen[3], 1)
            for i = 1, numOuterParticles do
                local angle = math.random() * (2 * math.pi)
                local distance = math.random() * maxRadius
                local size = math.random(3, 6) * (1 - progress)
                local px = self.x + math.cos(angle) * distance
                local py = self.y + math.sin(angle) * distance
                love.graphics.circle("fill", px, py, size)
            end

            -- Inner glow: use pastelMint from your palette
            love.graphics.setColor(pastelMint[1], pastelMint[2], pastelMint[3], 1 - progress)
            love.graphics.circle("fill", self.x, self.y, (maxRadius * 0.3) * (1 - progress))

            -- Center flash: use dustyLavender from your palette
            love.graphics.setColor(dustyLavender[1], dustyLavender[2], dustyLavender[3], 0.4 * (1 - progress))
            love.graphics.circle("fill", self.x, self.y, (maxRadius * 0.2) * (1 - progress))

            -- Center sparks: use deepPurple from your palette
            local numSparks = 10
            for i = 1, numSparks do
                local offsetX = math.random(-10, 10) * (1 - progress)
                local offsetY = math.random(-10, 10) * (1 - progress)
                love.graphics.setColor(deepPurple[1], deepPurple[2], deepPurple[3], 0.6 * (1 - progress))
                local sparkSize = math.random(1, 3) * (1 - progress)
                love.graphics.circle("fill", self.x + offsetX, self.y + offsetY, sparkSize)
            end

            -- Optional: add a few smoke-like particles for additional effect using charcoalGray
            local numSmokeParticles = 15
            love.graphics.setColor(charcoalGray[1], charcoalGray[2], charcoalGray[3], 0.3 * (1 - progress))
            for i = 1, numSmokeParticles do
                local angle = math.random() * (2 * math.pi)
                local distance = math.random() * (maxRadius * 0.8)
                local size = math.random(2, 4) * (1 - progress)
                local sx = self.x + math.cos(angle) * distance
                local sy = self.y + math.sin(angle) * distance
                love.graphics.circle("fill", sx, sy, size)
            end
        end,
    }
end




if type == "fireling_bite" then
    return {
        type = "fireling_bite",
        x = x,
        y = y,
        duration = 1,  -- Effect lasts 1 second
        timer = 0,
        isDead = false,
        baseAngle = math.random() * 2 * math.pi,  -- Random base angle for the arc
        update = function(self, dt)
            self.timer = self.timer + dt
            if self.timer >= self.duration then
                self.isDead = true
            end
        end,
        draw = function(self)
            local progress = self.timer / self.duration
            local alpha = 1 - progress
            local numParticles = 6      -- Number of small particles
            local arcWidth = math.rad(60) -- Total arc width of 60 degrees

            for i = 1, numParticles do
                local t = i / (numParticles + 1)
                local angle = self.baseAngle - arcWidth/2 + t * arcWidth
                local distance = 8 * progress  -- Particles move outward over time
                local px = self.x + math.cos(angle) * distance
                local py = self.y + math.sin(angle) * distance
                -- Use terraCotta for the arc particles:
                love.graphics.setColor(terraCotta[1], terraCotta[2], terraCotta[3], alpha)
                love.graphics.circle("fill", px, py, 2 * (1 - progress))
            end

            -- Draw a small central glow using orangeGold:
            love.graphics.setColor(orangeGold[1], orangeGold[2], orangeGold[3], alpha * 0.6)
            love.graphics.circle("fill", self.x, self.y, 3 * (1 - progress))
            love.graphics.setColor(1, 1, 1, 1)
        end,
    }
end



if type == "fearExplosion" then
    return {
        type = "fearExplosion",
        x = x,
        y = y,
        -- Use the smaller radius you wanted:
        impactRadius   = 50,   -- was 100
        fadeOutRadius = 75,    -- was 150
        duration = duration or durations["fearExplosion"] or 1.5,
        timer = 0,
        isDead = false,
        enemies = enemies or {},
        damageNumbers = damageNumbers or {},
        effects = effects or {},

        -- We'll keep a small batch of swirl particles for visual flair:
        swirlParticles = {},
        swirlSpawned = false,  -- so we only spawn once

        update = function(self, dt)
            self.timer = self.timer + dt
            if self.timer >= self.duration then
                self.isDead = true
                return
            end

            -- On first update, spawn swirl particles:
            if not self.swirlSpawned then
                self.swirlSpawned = true
                local numSwirls = 15
                for i = 1, numSwirls do
                    -- random angle & speed
                    local angle = math.random() * (2 * math.pi)
                    local speed = math.random(30, 60)
                    local lifetime = math.random(1,2)

                    table.insert(self.swirlParticles, {
                        x = self.x,
                        y = self.y,
                        vx = math.cos(angle) * speed,
                        vy = math.sin(angle) * speed,
                        age = 0,
                        lifetime = lifetime,
                        size = math.random(2,4),
                        color = {0.5, 0.0, 0.5, 1}, -- purple swirl
                    })
                end
            end

            -- Update swirl particles
            for i = #self.swirlParticles, 1, -1 do
                local p = self.swirlParticles[i]
                p.age = p.age + dt
                if p.age >= p.lifetime then
                    table.remove(self.swirlParticles, i)
                else
                    p.x = p.x + p.vx * dt
                    p.y = p.y + p.vy * dt
                    -- Fade out & slowly expand
                    p.color[4] = 1 - (p.age / p.lifetime)
                    p.size = p.size + (5 * dt)
                end
            end

            -- Calculate current radius based on timer
            self.currentRadius = self.impactRadius
              + (self.fadeOutRadius - self.impactRadius)
              * (self.timer / self.duration)

            -- Apply fear to enemies
            for _, enemy in ipairs(self.enemies) do
                if not enemy.isDead then
                    local dx = enemy.x - self.x
                    local dy = enemy.y - self.y
                    if (dx*dx + dy*dy) <= (self.currentRadius * self.currentRadius) then
                        if not enemy.statusEffects or not enemy.statusEffects["Fear"] then
                            enemy:applyStatusEffect({
                                name = "Fear",
                                duration = 3,
                            })
                        end
                    end
                end
            end
        end,

        draw = function(self)
            -- (1) Draw swirl particles first
            for _, p in ipairs(self.swirlParticles) do
                love.graphics.setColor(p.color)
                love.graphics.circle("fill", p.x, p.y, p.size)
            end

            -- (2) Then draw your smaller purple aura (exactly like your “worked” code):
            local progress = self.timer / self.duration
            local alpha = math.max(1 - progress, 0)

           

            -- Reset color
            love.graphics.setColor(1, 1, 1, 1)
        end,
    }
end


 if type == "bloodexplosion" then
        return {
            type = "bloodexplosion",
            x = x,
            y = y,
            timer = 0,
            duration = self.duration,
            impactRadius = self.impactRadius,
            damagePerMeteor = self.damagePerMeteor,
            enemies = self.enemies,
            damageNumbers = self.damageNumbers,
            effects = self.effects,
            color = {0.8, 0.0, 0.0, 1}, -- Dark Red

            update = function(self, dt)
                self.timer = self.timer + dt
                if self.timer >= self.duration then
                    self.isDead = true
                    return
                end

                local progress = math.min(self.timer / self.duration, 1)

                -- Apply damage to enemies within the impact radius
                for _, enemy in ipairs(self.enemies) do
                    if not enemy.isDead then
                        local dx = enemy.x - self.x
                        local dy = enemy.y - self.y
                        local distanceSq = dx * dx + dy * dy
                        if distanceSq <= self.impactRadius * self.impactRadius then
                            enemy:takeDamage(
                                self.damagePerMeteor,
                                self.damageNumbers,
                                self.effects,
                                "BloodExplosion",
                                nil,
                                "damageTaken"
                            )
                        end
                    end
                end
            end,

            draw = function(self)
                local progress = math.min(self.timer / self.duration, 1)
                local alpha = 1 - progress

                -- Outer blood particles within maxRadius with red shades
                local numOuterParticles = 20
                love.graphics.setColor(0.8, 0.0, 0.0, 1) -- Dark Red

                for i = 1, numOuterParticles do
                    local angle = math.random() * (2 * math.pi)
                    local distance = math.random() * self.impactRadius
                    local size = math.random(3, 6) * (1 - progress)
                    local px = self.x + math.cos(angle) * distance
                    local py = self.y + math.sin(angle) * distance
                    love.graphics.circle("fill", px, py, size)
                end

                -- Inner glow with red shades
                love.graphics.setColor(1, 0.0, 0.0, 1 - progress) -- Bright Red
                love.graphics.circle("fill", self.x, self.y, (self.impactRadius * 0.3) * (1 - progress))

                -- Subtle flash for a fiery center
                love.graphics.setColor(0.6, 0.0, 0.0, 0.4 * (1 - progress)) -- Darker Red
                love.graphics.circle("fill", self.x, self.y, (self.impactRadius * 0.2) * (1 - progress))

                -- Increased and more dynamic centered sparks with red hues
                local numSparks = 10
                for i = 1, numSparks do
                    local offsetX = math.random(-10, 10) * (1 - progress)
                    local offsetY = math.random(-10, 10) * (1 - progress)
                    love.graphics.setColor(0.8, 0.1, 0.1, 0.6 * (1 - progress)) -- Light Red

                    local sparkSize = math.random(1, 3) * (1 - progress)
                    love.graphics.circle("fill", self.x + offsetX, self.y + offsetY, sparkSize)
                end

                -- Optional: Add smoke particles with dark red/black shades for additional effect
                local numSmokeParticles = 15
                love.graphics.setColor(0.5, 0.0, 0.0, 0.3 * (1 - progress)) -- Maroon

                for i = 1, numSmokeParticles do
                    local angle = math.random() * (2 * math.pi)
                    local distance = math.random() * (self.impactRadius * 0.8)
                    local size = math.random(2, 4) * (1 - progress)
                    local px = self.x + math.cos(angle) * distance
                    local py = self.y + math.sin(angle) * distance
                    love.graphics.circle("fill", px, py, size)
                end
            end,
        }
    end
    
    
if type == "explodingmadness" then
    return {
        type = "explodingmadness",
        x = x,
        y = y,
        timer = 0,
        duration = 0.5,  -- Duration of the explosion effect in seconds
        impactRadius = radius or 50,  -- Radius within which Madness is applied
        enemies = enemies or {},  -- List of enemies to consider
        damageNumbers = damageNumbers or {},
        effects = effects or {},
        sounds = sounds or {},

        update = function(self, dt)
            self.timer = self.timer + dt
            if self.timer >= self.duration then
                self.isDead = true
                return
            end

         
        end,

        draw = function(self)
            local progress = math.min(self.timer / self.duration, 1)
            local alpha = 1 - progress

            -- Outer red particles
            local numParticles = 20
            love.graphics.setColor(0.8, 0, 0, alpha)  -- Dark Red
            for i = 1, numParticles do
                local angle = math.random() * 2 * math.pi
                local distance = math.random() * self.impactRadius
                local size = math.random(2, 4) * (1 - progress)
                local px = self.x + math.cos(angle) * distance
                local py = self.y + math.sin(angle) * distance
                love.graphics.circle("fill", px, py, size)
            end

            -- Inner glow
            love.graphics.setColor(1, 0, 0, alpha * 0.5)
            love.graphics.circle("fill", self.x, self.y, self.impactRadius * 0.3 * (1 - progress))

            -- Tiny blood-like particles
            local numSparks = 10
            for i = 1, numSparks do
                local offsetX = math.random(-10, 10) * (1 - progress)
                local offsetY = math.random(-10, 10) * (1 - progress)
                love.graphics.setColor(0.9, 0.1, 0.1, 0.6 * alpha)
                local sparkSize = math.random(1, 3) * (1 - progress)
                love.graphics.circle("fill", self.x + offsetX, self.y + offsetY, sparkSize)
            end

            -- Reset color to default
            love.graphics.setColor(1, 1, 1, 1)
        end,
    }
end
   
if type == "frost_field" then
  return {
    type = "frost_field",
    x = x,
    y = y,
    radius = 50,                -- visual radius (must match BlizzardData’s radius)
    duration = duration or 5,   -- visual duration
    timer = 0,
    spawnTimer = 0,             -- timer for spawning hail particles
    hailParticles = {},
    smashParticles = {},
    update = function(self, dt)
      self.timer = self.timer + dt
      self.spawnTimer = self.spawnTimer + dt

      if self.spawnTimer >= 0.04 then
        self.spawnTimer = self.spawnTimer - 0.04
        local numToSpawn = math.random(2, 3)
        for i = 1, numToSpawn do
          local r = self.radius * math.sqrt(math.random())
          local theta = math.random() * 2 * math.pi
          local targetX = self.x + r * math.cos(theta)
          local targetY = self.y + r * math.sin(theta)
          local spawnY = targetY - math.random(10, 20)
          local particle = {
            x = targetX,
            y = spawnY,
            targetY = targetY,
            speed = math.random(150, 200),
            angle = math.rad(80) + math.rad(math.random(-5, 5)),
            length = math.random(4, 8),
          }
          table.insert(self.hailParticles, particle)
        end
      end

      for i = #self.hailParticles, 1, -1 do
        local p = self.hailParticles[i]
        p.x = p.x + p.speed * math.cos(p.angle) * dt
        p.y = p.y + p.speed * math.sin(p.angle) * dt
        if p.y >= p.targetY then
          for j = 1, math.random(2, 4) do
            local shard = {
              x = p.x,
              y = p.targetY,
              vx = math.random(-30, 30),
              vy = math.random(-30, 0),
              lifetime = 0.3,
              age = 0,
              size = math.random(1, 2)
            }
            table.insert(self.smashParticles, shard)
          end
          table.remove(self.hailParticles, i)
        end
      end

      for i = #self.smashParticles, 1, -1 do
        local s = self.smashParticles[i]
        s.age = s.age + dt
        s.x = s.x + s.vx * dt
        s.y = s.y + s.vy * dt
        if s.age >= s.lifetime then
          table.remove(self.smashParticles, i)
        end
      end

      if self.timer >= self.duration then
         self.isDead = true
      end
    end,
    draw = function(self)
      -- Draw hail particles using smokyBlue from your palette
      for _, p in ipairs(self.hailParticles) do
        love.graphics.setColor(smokyBlue[1], smokyBlue[2], smokyBlue[3], 0.9)
        love.graphics.setLineWidth(1)
        local x2 = p.x + p.length * math.cos(p.angle)
        local y2 = p.y + p.length * math.sin(p.angle)
        love.graphics.line(p.x, p.y, x2, y2)
      end
      -- Draw smash particles using pastelMint from your palette
      for _, s in ipairs(self.smashParticles) do
        local alpha = 1 - (s.age / s.lifetime)
        love.graphics.setColor(pastelMint[1], pastelMint[2], pastelMint[3], alpha)
        love.graphics.circle("fill", s.x, s.y, s.size)
      end
      love.graphics.setColor(1, 1, 1, 1)
    end,
  }
end

if type == "frozen_shard" then
    local dx = (targetX or x) - x
    local dy = (targetY or y) - y
    local dist = math.sqrt(dx * dx + dy * dy)
    local dirX, dirY = 0, 0
    if dist > 0 then
       dirX = dx/dist
       dirY = dy/dist
    end
    return {
         type = "frozen_shard",
         x = x,
         y = y,
         directionX = dirX,
         directionY = dirY,
         speed = 200,
         isDead = false,
         timer = 0,
         duration = 1.5,
         piercing = true,
         enemies = enemies or {},  -- store the enemies passed in
         enemiesHit = {},
         update = function(self, dt)
             self.timer = self.timer + dt
             if self.timer >= self.duration then
                 self.isDead = true
             end

             -- Move the shard along its fixed direction
             self.x = self.x + self.directionX * self.speed * dt
             self.y = self.y + self.directionY * self.speed * dt

             -- Check collision with each enemy
             for _, enemy in ipairs(self.enemies) do
                 if not enemy.isDead and (not self.enemiesHit[enemy]) then
                     local ex = enemy.x - self.x
                     local ey = enemy.y - self.y
                     local d = math.sqrt(ex * ex + ey * ey)
                     local hitThreshold = enemy.collisionRadius or 10
                     if d < hitThreshold then
                         if self.onHitEnemy then
                             self.onHitEnemy(enemy)
                         end
                         self.enemiesHit[enemy] = true
                         if not self.piercing then
                             self.isDead = true
                         end
                     end
                 end
             end
         end,
         draw = function(self)
             -- Use pastelMint from your palette for the icy shard
             love.graphics.setColor(pastelMint[1], pastelMint[2], pastelMint[3], 1)
             local size = 4
             local points = {
                self.x, self.y - size,
                self.x + size, self.y,
                self.x, self.y + size,
                self.x - size, self.y,
             }
             love.graphics.polygon("fill", points)
         end,
    }
end



if type == "madness" then
    return {
        type       = "madness",
        x          = x,
        y          = y,
        attachedTo = attachedTo or nil,  -- Reference to the enemy
        timer      = 0,
        duration   = .5,    -- Use the same duration as your logical effect
        isDead     = false,
        -- Spiral parameters...
        spiralRotation = 0,
        spiralSpeed = math.rad(180),
        spiralSegments = 20,
        spiralRadius = 7.5,
        spiralGrowth = 2.5,
        spiralColor = {1, 1, 0, 0.6},
        spiralThickness = 1,
        pulseSpeed = 5,
        pulseAmplitude = 1.5,
        update = function(self, dt)
            self.timer = self.timer + dt

            -- NEW: Check if the enemy has died.
            if self.attachedTo and self.attachedTo.isDead then
                self.isDead = true
                return
            end

            -- Follow the enemy's position
            if self.attachedTo then
                self.x = self.attachedTo.x
                self.y = self.attachedTo.y
            end

            -- Update the spiral's rotation and optional pulsation
            self.spiralRotation = self.spiralRotation + self.spiralSpeed * dt
            local pulse = math.sin(self.timer * self.pulseSpeed * math.pi * 2)
            self.spiralRadius = 7.5 + pulse * self.pulseAmplitude
            self.spiralThickness = 1 + pulse * 0.25

            if self.timer >= self.duration then
                self.isDead = true
                -- Optionally restore the enemy's original color
                if self.attachedTo and self.attachedTo.originalColor then
                    self.attachedTo.color = self.attachedTo.originalColor
                    self.attachedTo.originalColor = nil
                end
            end
        end,
        draw = function(self)
            love.graphics.push()
            love.graphics.translate(self.x, self.y)
            love.graphics.rotate(self.spiralRotation)
            love.graphics.setLineWidth(self.spiralThickness)
            love.graphics.setColor(self.spiralColor)
            for i = 1, self.spiralSegments do
                local angle = (i / self.spiralSegments) * (2 * math.pi)
                local startX, startY = 0, 0
                local endX = math.cos(angle) * self.spiralRadius
                local endY = math.sin(angle) * self.spiralRadius
                local growth = (i / self.spiralSegments) * self.spiralGrowth
                endX = endX + math.cos(angle) * growth
                endY = endY + math.sin(angle) * growth
                love.graphics.line(startX, startY, endX, endY)
            end
            love.graphics.pop()
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setLineWidth(1)
        end,
    }
end


if type == "firebomb_projectile" then
    return {
        type = "firebomb_projectile",
        x = x,
        y = y,
        targetX = targetX or x,
        targetY = targetY or y,
        timer = 0,
        lifetime = lifetime or 0.8,
        vx = 0,
        vy = 0,
        g = 200,  -- gravity
        
        -- Animation properties:
        currentFrame = 1,
        frameTimer = 0,
        frameDuration = 0.1,  -- change as needed
        totalFrames = 4,
        
        -- Trail particles table:
        trailParticles = {},
        trailTimer = 0,
        trailInterval = 0.05,  -- adjust frequency as needed

        onImpact = nil,  -- callback (set in ability)
        
        update = function(self, dt)
            self.timer = self.timer + dt
            
            -- Update animation
            self.frameTimer = self.frameTimer + dt
            if self.frameTimer >= self.frameDuration then
                self.frameTimer = self.frameTimer - self.frameDuration
                self.currentFrame = (self.currentFrame % self.totalFrames) + 1
            end
            
            -- Update trail particles
            self.trailTimer = self.trailTimer + dt
            if self.trailTimer >= self.trailInterval then
                self.trailTimer = self.trailTimer - self.trailInterval
                -- Create a new trail particle using orangeGold from your palette:
                table.insert(self.trailParticles, {
                    x = self.x,
                    y = self.y,
                    life = 0.5,
                    age = 0,
                    size = math.random(2, 4),
                    color = { orangeGold[1], orangeGold[2], orangeGold[3], orangeGold[4] }
                })
            end
            for i = #self.trailParticles, 1, -1 do
                local p = self.trailParticles[i]
                p.age = p.age + dt
                if p.age >= p.life then
                    table.remove(self.trailParticles, i)
                end
            end
            
            -- Update vertical speed due to gravity and position
            self.vy = self.vy + self.g * dt
            self.x = self.x + self.vx * dt
            self.y = self.y + self.vy * dt
            
            if self.timer >= self.lifetime then
                self.isDead = true
                if self.onImpact then
                    self.onImpact(self, self.x, self.y)
                end
            end
        end,
        
        draw = function(self)
            -- Draw trail particles first
            for _, p in ipairs(self.trailParticles) do
                local alpha = 1 - (p.age / p.life)
                love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
                love.graphics.circle("fill", p.x, p.y, p.size)
            end
            
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                flameImage,
                firebombFrames[self.currentFrame],
                self.x, self.y,
                0,         -- rotation
                2, 2,      -- scaleX, scaleY (adjust if needed)
                8, 8       -- origin offsets (half of 16)
            )
        end,
    }
end


if type == "burn_patch" then
    return {
        type = "burn_patch",
        x = x,
        y = y,
        timer = 0,                           -- Overall lifetime timer for the burn patch
        duration = duration or 5,            -- Total duration of the burn patch (in seconds)
        tickInterval = tickInterval or 1,    -- How often damage is applied
        tickTimer = 0,                       -- Timer for damage ticks
        damagePerTick = damagePerTick or 5,    -- Damage applied each tick
        explosionTimer = 0,                  -- Timer for the explosion animation cycle
        explosionDuration = 0.3,             -- Duration of each explosion animation cycle
        update = function(self, dt)
            self.timer = self.timer + dt
            self.explosionTimer = self.explosionTimer + dt
            self.tickTimer = self.tickTimer + dt

            if self.explosionTimer >= self.explosionDuration then
                self.explosionTimer = self.explosionTimer - self.explosionDuration
            end

            if self.tickTimer >= self.tickInterval then
                self.tickTimer = self.tickTimer - self.tickInterval
                for _, enemy in ipairs(enemies or {}) do
                    local dx = enemy.x - self.x
                    local dy = enemy.y - self.y
                    if dx * dx + dy * dy <= (50 * 50) then
                        enemy:takeDamage(self.damagePerTick, nil, effects, "burn_patch", nil, "damageOverTime")
                    end
                end
            end

            if self.timer >= self.duration then
                self.isDead = true
            end
        end,
        draw = function(self)
            local progress = math.min(self.explosionTimer / self.explosionDuration, 1)
            local alpha = 1 - progress
            local maxRadius = 50  -- Maximum explosion radius

            -- Outer fiery particles: use orangeGold from your palette
            local numOuterParticles = 20
            love.graphics.setColor(orangeGold[1], orangeGold[2], orangeGold[3], alpha)
            for i = 1, numOuterParticles do
                local angle = math.random() * 2 * math.pi
                local distance = math.random() * maxRadius
                local size = math.random(3, 6) * (1 - progress)
                local px = self.x + math.cos(angle) * distance
                local py = self.y + math.sin(angle) * distance
                love.graphics.circle("fill", px, py, size)
            end

            -- Inner glow: use paleYellow from your palette
            love.graphics.setColor(paleYellow[1], paleYellow[2], paleYellow[3], alpha * 0.5)
            love.graphics.circle("fill", self.x, self.y, (maxRadius * 0.3) * (1 - progress))

            -- Center flash: use terraCotta from your palette for a warm core
            love.graphics.setColor(terraCotta[1], terraCotta[2], terraCotta[3], 0.4 * (1 - progress))
            love.graphics.circle("fill", self.x, self.y, (maxRadius * 0.2) * (1 - progress))

            -- Center sparks: use rustRed for flickering embers
            local numSparks = 10
            for i = 1, numSparks do
                local offsetX = math.random(-10, 10) * (1 - progress)
                local offsetY = math.random(-10, 10) * (1 - progress)
                love.graphics.setColor(rustRed[1], rustRed[2], rustRed[3], 0.6 * (1 - progress))
                local sparkSize = math.random(1, 3) * (1 - progress)
                love.graphics.circle("fill", self.x + offsetX, self.y + offsetY, sparkSize)
            end
        end,
    }
end



   
 -- In your Effects.lua file, modify the ignite update function
if type == "ignite" then
    return {
        type = "ignite",
        x = x,
        y = y,
        attachedTo = attachedTo or nil,
        source = source or nil,
        timer = 0,
        duration = duration or durations["ignite"] or 5.0,
        isDead = false,
        enemiesHit = {},
        particles = {},
        damageMultiplier = self and self.damageMultiplier or 1,
        update = function(self, dt)
            self.timer = self.timer + dt

            if self.attachedTo and self.attachedTo.isDead then
                self.isDead = true
                return
            end

            if self.attachedTo then
                self.x = self.attachedTo.x
                self.y = self.attachedTo.y
            end

            local numParticles = 2
            for i = 1, numParticles do
                local angle = math.random() * 2 * math.pi
                local distance = math.random() * 3
                local offsetX = math.cos(angle) * distance
                local offsetY = math.sin(angle) * distance
                table.insert(self.particles, {
                    x = self.x + offsetX,
                    y = self.y + offsetY,
                    size = 1 + math.random() * 0.5,
                    alpha = 1,
                    lifetime = 0.5,
                    age = 0,
                    angle = angle,
                    color = {173/255, 64/255, 48/255, 1},
                })
            end

            for i = #self.particles, 1, -1 do
                local p = self.particles[i]
                p.age = p.age + dt
                if p.age >= p.lifetime then
                    table.remove(self.particles, i)
                else
                    p.alpha = 1 - (p.age / p.lifetime)
                    p.x = p.x + math.cos(p.angle) * 5 * dt
                    p.y = p.y + math.sin(p.angle) * 5 * dt
                end
            end

            self.tickTimer = (self.tickTimer or 0) + dt
            if self.tickTimer >= 1 then
                self.tickTimer = 0
                local bonus = 0
                if self.source then
                    bonus = self.source.statusEffectDamageBonus or (self.source.owner and self.source.owner.statusEffectDamageBonus) or 0
                end

                local baseDPS = self.baseDPS or 15  -- use self.baseDPS if set
                local damage = baseDPS + bonus

                self.attachedTo:takeDamage(damage, self.damageNumbers, self.effects, "ignite", nil, "damageTaken")
            end

            if self.timer >= self.duration then
                self.isDead = true
            end
        end,
        draw = function(self)
            for _, p in ipairs(self.particles) do
                love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.alpha)
                love.graphics.circle("fill", p.x, p.y, p.size)
            end
            local alpha = math.max(1 - (self.timer / self.duration), 0)
            love.graphics.setColor(239/255, 158/255, 78/255, 0.5 * alpha)
            love.graphics.circle("fill", self.x, self.y, 3 * alpha)
            love.graphics.setColor(1, 1, 1, 1)
        end,
    }
end



   
    if type == "disintegration_effect" then
        local e = {}
        e.x, e.y = x, y
        e.type = "disintegration_effect"
        e.isDead = false
        e.particles = {}

        -- Emit disintegration particles
        local numFragments = 40
        for i = 1, numFragments do
            local angle = math.random() * 2 * math.pi
            local speed = math.random(100, 300)
            local vx = math.cos(angle) * speed
            local vy = math.sin(angle) * speed
            local lifetime = math.random(0.5, 1)
            table.insert(e.particles, {
                x = x, y = y,
                vx = vx, vy = vy,
                age = 0,
                lifetime = lifetime,
                size = math.random(4, 8),
                type = "disintegration",
                color = {173/255, 64/255, 48/255, 1}
            })
        end

        e.update = function(self, dt)
            for i = #self.particles, 1, -1 do
                local p = self.particles[i]
                p.age = p.age + dt
                if p.age >= p.lifetime then
                    table.remove(self.particles, i)
                else
                    p.x = p.x + p.vx * dt
                    p.y = p.y + p.vy * dt
                    local friction = 0.98
                    p.vx = p.vx * friction
                    p.vy = p.vy * friction
                    local fadeFactor = 1 - (p.age / p.lifetime)
                    p.color[4] = fadeFactor
                end
            end
            if #self.particles == 0 then
                self.isDead = true
            end
        end

        e.draw = function(self)
            for _, p in ipairs(self.particles) do
                love.graphics.setColor(p.color)
                love.graphics.circle("fill", p.x, p.y, p.size * 0.25)
            end
            love.graphics.setColor(1,1,1)
        end

        return e
    end


   

    -- Initialize properties based on effect type
    if self.type == "meteor_swarm" then
        self.meteorsSpawned = 0
        self.numberOfMeteors = 10  -- Default number of meteors, adjust as needed
        self.meteorInterval = 0.5  -- Default interval between meteors
        self.nextMeteorTime = 0  -- Initialize timer for next meteor
    end

    if self.type == "falling_meteor" then
        self.startX = x
        self.startY = y
        self.speed = 500
        self.rotation = math.atan2(targetY - y, targetX - x)
    end
 
    if self.type == "unholy_ground" then
        self.acidParticleInterval = 0.1
        self.acidParticles = {}
    end

if type == "necrotic_tendrils" then
    local effect = {
        x = x,
        y = y,
        targetX = targetX or x,
        targetY = targetY or y,
        isDead = false,
        lifetime = 0.3,  -- slightly longer to emphasize the tendril
        timer = 0,
        segments = 8,    -- more segments for a smoother tendril look
        offsetRange = 4, -- smaller random offsets for a more organic shape
update = function(self, dt)
    self.timer = self.timer + dt
    if self.timer >= self.lifetime then
        if self.target and self.onHitEnemy then
            self.onHitEnemy(self.target)
        end
        self.isDead = true
    end
end,


        draw = function(self)
            -- Purple to green gradient
            local startColor = {0.6, 0, 0.8}  -- purple
            local endColor   = {0, 1, 0}       -- green
            local dx = self.targetX - self.x
            local dy = self.targetY - self.y
            local segmentDX = dx / self.segments
            local segmentDY = dy / self.segments

            love.graphics.setLineWidth(2)
            local prevX, prevY = self.x, self.y
            for i = 1, self.segments do
                local t = i / self.segments
                local r = startColor[1] + (endColor[1] - startColor[1]) * t
                local g = startColor[2] + (endColor[2] - startColor[2]) * t
                local b = startColor[3] + (endColor[3] - startColor[3]) * t
                local alpha = 1 - (i / (self.segments * 1.2))
                love.graphics.setColor(r, g, b, alpha)

                local offsetX = (math.random() * 2 - 1) * self.offsetRange
                local offsetY = (math.random() * 2 - 1) * self.offsetRange
                local nextX = prevX + segmentDX + offsetX
                local nextY = prevY + segmentDY + offsetY
                love.graphics.line(prevX, prevY, nextX, nextY)
                prevX, prevY = nextX, nextY
            end

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setLineWidth(1)
        end,
    }
    return effect
end

 

if type == "discharge_jolt" then
    local effect = {
        x = x,
        y = y,
        targetX = targetX or x,
        targetY = targetY or y,
        isDead = false,
        lifetime = 0.2,  -- Very short for a quick strike
        timer = 0,

        -- Number of segments and randomness
        segments = 6,     -- Fewer segments for a simpler jolt
        offsetRange = 6,  -- Range of random offset per segment

        -- Update function
        update = function(self, dt)
            self.timer = self.timer + dt
            if self.timer >= self.lifetime then
                self.isDead = true
            end
        end,

        -- Draw function
        draw = function(self)
            -- Use palette colors:
            local startColor = orangeGold   -- from your palette, e.g., {239/255, 158/255, 78/255, 1}
            local endColor   = paleYellow     -- from your palette, e.g., {246/255, 242/255, 195/255, 1}

            local dx = self.targetX - self.x
            local dy = self.targetY - self.y
            local segmentDX = dx / self.segments
            local segmentDY = dy / self.segments

            love.graphics.setLineWidth(2)

            local prevX, prevY = self.x, self.y
            for i = 1, self.segments do
                local t = i / self.segments
                local r = startColor[1] + (endColor[1] - startColor[1]) * t
                local g = startColor[2] + (endColor[2] - startColor[2]) * t
                local b = startColor[3] + (endColor[3] - startColor[3]) * t
                local alpha = 1 - (i / (self.segments * 1.2))
                love.graphics.setColor(r, g, b, alpha)

                local offsetX = (math.random() * 2 - 1) * self.offsetRange
                local offsetY = (math.random() * 2 - 1) * self.offsetRange
                local nextX = prevX + segmentDX + offsetX
                local nextY = prevY + segmentDY + offsetY

                love.graphics.line(prevX, prevY, nextX, nextY)

                prevX, prevY = nextX, nextY
            end

            -- Start sparks: use orangeGold for bright sparks at the start
            for _ = 1, 3 do
                love.graphics.setColor(orangeGold[1], orangeGold[2], orangeGold[3], 0.7)
                local sx = self.x + math.random(-4, 4)
                local sy = self.y + math.random(-4, 4)
                love.graphics.circle("fill", sx, sy, 2)
            end
            -- End sparks: use paleYellow at the target end
            for _ = 1, 3 do
                love.graphics.setColor(paleYellow[1], paleYellow[2], paleYellow[3], 0.7)
                local ex = self.targetX + math.random(-4, 4)
                local ey = self.targetY + math.random(-4, 4)
                love.graphics.circle("fill", ex, ey, 2)
            end

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setLineWidth(1)
        end,
    }

    return effect
end





 
if type == "beholder_aura" then
    return {
        type = "beholder_aura",
        x = x,
        y = y,
        baseRadius = 28,            -- Reduced base radius by an additional 25%
        maxRadius = 34,             -- Reduced maximum radius by an additional 25%
        minRadius = 22,             -- Reduced minimum radius by an additional 25%
        pulseSpeed = 2,             -- Pulsating speed remains the same
        pulseAmplitude = 2.81,      -- Reduced pulsating amplitude by an additional 25%
        timer = 0,
        isDead = false,
        age = 0,
        attachedTo = attachedTo,    -- Beholder reference

        sparkles = {},              -- Sparkle particles
        sparkleTimer = 0,
        sparkleInterval = 0.3,      -- Emit sparkles every 0.3 seconds

        update = function(self, dt)
            if not self.attachedTo or self.attachedTo.isDead then
                self.isDead = true
                return
            end

            self.x = self.attachedTo.x
            self.y = self.attachedTo.y

            -- Update pulsating radius
            self.timer = self.timer + dt * self.pulseSpeed
            local pulse = math.sin(self.timer) * self.pulseAmplitude
            self.currentRadius = self.baseRadius + pulse

            -- Emit sparkles using paleYellow from your palette
            self.sparkleTimer = self.sparkleTimer + dt
            if self.sparkleTimer >= self.sparkleInterval then
                self.sparkleTimer = self.sparkleTimer - self.sparkleInterval
                local angle = math.random() * 2 * math.pi
                local distance = math.random(self.currentRadius - 10, self.currentRadius + 10)
                local px = self.x + math.cos(angle) * distance
                local py = self.y + math.sin(angle) * distance
                table.insert(self.sparkles, {
                    x = px,
                    y = py,
                    size = math.random(1, 3),
                    lifetime = 1,
                    age = 0,
                    color = { paleYellow[1], paleYellow[2], paleYellow[3], 1 },
                })
            end

            for i = #self.sparkles, 1, -1 do
                local sparkle = self.sparkles[i]
                sparkle.age = sparkle.age + dt
                if sparkle.age >= sparkle.lifetime then
                    table.remove(self.sparkles, i)
                else
                    sparkle.alpha = 1 - (sparkle.age / sparkle.lifetime)
                end
            end
        end,

        draw = function(self)
            -- Enable additive blending for a glowing effect
            love.graphics.setBlendMode("add")

            -- Draw multiple concentric circles for gradient glow using deepPurple from your palette
            local numLayers = 5
            for i = 1, numLayers do
                local layerRadius = self.currentRadius + (i * 2.8125)
                local alpha = 0.15 / i
                love.graphics.setColor(deepPurple[1], deepPurple[2], deepPurple[3], alpha)
                love.graphics.circle("fill", self.x, self.y, layerRadius)
            end

            -- Draw sparkles using paleYellow
            for _, sparkle in ipairs(self.sparkles) do
                love.graphics.setColor(sparkle.color[1], sparkle.color[2], sparkle.color[3], 1 - (sparkle.age / sparkle.lifetime))
                love.graphics.circle("fill", sparkle.x, sparkle.y, sparkle.size)
            end

            -- Reset blend mode and color to default
            love.graphics.setBlendMode("alpha")
            love.graphics.setColor(1, 1, 1, 1)
        end,
    }
end



if type == "necrotic_flame" then
    return {
        x = x,
        y = y,
        targetX = targetX or x,
        targetY = targetY or y,
        directionX = (targetX or x) - x,
        directionY = (targetY or y) - y,
        
        isDead = false,
        age = 0,
        scale = 0.5, -- Increased scale for better visibility
        impactRadius = 15, -- Reduced collision radius by 75%
        enemiesHit = {}, -- Initialize enemiesHit here
        particles = {},
        particleTimer = 0,
        particleInterval = 0.05, -- Slightly increased for smoother cone
        lifetime = 1.2, -- Extended lifetime for longer range
        onHitEnemy = nil, -- Callback function

        -- Cone Angle in radians (e.g., 60 degrees)
        coneAngle = math.rad(60),

        update = function(self, dt)
            -- Update lifetime
            self.lifetime = self.lifetime - dt
            if self.lifetime <= 0 then
                self.isDead = true
                return
            end

            -- Normalize direction vector
            local dist = math.sqrt(self.directionX^2 + self.directionY^2)
            if dist > 0 then
                self.directionX = self.directionX / dist
                self.directionY = self.directionY / dist
            end

            -- Move the necrotic flame (make sure self.speed is set externally)
            self.x = self.x + self.directionX * self.speed * dt
            self.y = self.y + self.directionY * self.speed * dt

            -- Spawn particles within the cone
            self.particleTimer = self.particleTimer + dt
            if self.particleTimer >= self.particleInterval then
                self.particleTimer = 0
                local angleOffset = (love.math.random() - 0.5) * self.coneAngle
                local emitAngle = math.atan2(self.directionY, self.directionX) + angleOffset
                local flameDirX = math.cos(emitAngle)
                local flameDirY = math.sin(emitAngle)

                table.insert(self.particles, {
                    x = self.x,
                    y = self.y,
                    vx = flameDirX * 45,
                    vy = flameDirY * 45,
                    size = love.math.random(4, 8),
                    age = 0,
                    lifetime = 0.4,
                    -- Set initial color to deepPurple from your palette
                    color = { deepPurple[1], deepPurple[2], deepPurple[3], 1 },
                })
            end

            -- Update particles
            for i = #self.particles, 1, -1 do
                local p = self.particles[i]
                p.age = p.age + dt
                if p.age >= p.lifetime then
                    table.remove(self.particles, i)
                else
                    -- Move particle
                    p.x = p.x + p.vx * dt
                    p.y = p.y + p.vy * dt
                end
            end

            -- Check for collision with enemies and trigger callback
            if self.enemies then
                for _, enemy in ipairs(self.enemies) do
                    if not self.enemiesHit[enemy] and not enemy.isDead then
                        local dx = enemy.x - self.x
                        local dy = enemy.y - self.y
                        local distToEnemy = math.sqrt(dx * dx + dy * dy)
                        if distToEnemy <= self.impactRadius then
                            self.enemiesHit[enemy] = true
                            if self.onHitEnemy then
                                self.onHitEnemy(enemy)
                            end
                        end
                    end
                end
            end
        end,

        draw = function(self)
            for _, p in ipairs(self.particles) do
                local t = p.age / p.lifetime
                local alpha = (1 - t)  -- lower overall opacity for a breathy feel
                -- Randomly interpolate between deepPurple and forestGreen from your palette:
                local mix = math.random()  -- random value between 0 and 1
                local r = deepPurple[1] * (1 - mix) + forestGreen[1] * mix
                local g = deepPurple[2] * (1 - mix) + forestGreen[2] * mix
                local b = deepPurple[3] * (1 - mix) + forestGreen[3] * mix
                love.graphics.setColor(r, g, b, alpha)
                local sizeFactor = 0.3 + math.random() * (1.2 - 0.3)
                love.graphics.circle("fill", p.x, p.y, p.size * sizeFactor)
            end
            love.graphics.setColor(1, 1, 1, 1)
        end,
    }
end


 if type == "necrotic_wave" then
    return {
        x = x,
        y = y,
        targetX = targetX or x,
        targetY = targetY or y,
        directionX = (targetX or x) - x,
        directionY = (targetY or y) - y,
        speed = 220,                -- Slightly increased speed for dynamic movement
        isDead = false,
        age = 0,
        scale = scale or 0.4,
        damage = damage or 0,
        enemies = enemies,
        effects = effects,
        radius = 12,                -- Slightly larger collision radius
        enemiesHit = {},
        particles = {},
        particleTimer = 0,
        particleInterval = 0.05,    -- Increased particle spawn rate for smoother trail
        lifetime = 1.8,             -- Extended wave lifetime for longer effect

        -- Update function
        update = function(self, dt)
            -- Update lifetime
            self.lifetime = self.lifetime - dt
            if self.lifetime <= 0 then
                self.isDead = true
                return
            end

            -- Normalize direction vector
            local dist = math.sqrt(self.directionX^2 + self.directionY^2)
            if dist > 0 then
                self.directionX = self.directionX / dist
                self.directionY = self.directionY / dist
            end

            -- Move the necrotic wave
            self.x = self.x + self.directionX * self.speed * dt
            self.y = self.y + self.directionY * self.speed * dt

            -- Spawn smaller, more opaque particles
            self.particleTimer = self.particleTimer + dt
            if self.particleTimer >= self.particleInterval then
                self.particleTimer = 0
                table.insert(self.particles, {
                    x = self.x,
                    y = self.y,
                    size = love.math.random(1, 3), -- Reduced particle size for finer trail
                    age = 0,
                    lifetime = 0.6,                 -- Slightly shorter lifetime for quicker dissipation
                    color = {0.6, 0.2, 0.7, 1},    -- Fully opaque purple
                })
            end

            -- Update particles
            for i = #self.particles, 1, -1 do
                local p = self.particles[i]
                p.age = p.age + dt
                if p.age >= p.lifetime then
                    table.remove(self.particles, i)
                else
                    -- Shrink particles as they age
                    local progress = p.age / p.lifetime
                    p.currentSize = p.size * (1 - progress * 0.8) -- Particles shrink up to 80%
                end
            end

            -- Check for collision with enemies and apply effects
            if self.enemies then
                for _, enemy in ipairs(self.enemies) do
                    if not self.enemiesHit[enemy] and not enemy.isDead then
                        local dx = enemy.x - self.x
                        local dy = enemy.y - self.y
                        local distToEnemy = math.sqrt(dx * dx + dy * dy)
                        if distToEnemy <= self.radius then
                            -- Apply damage
                            enemy:takeDamage(
                                self.damage or 0,
                                self.damageNumbers, -- Pass damageNumbers
                                self.effects,        -- Pass effects
                                "Grimreaper",     -- sourceType
                                nil,                 -- sourceCharacter (if applicable)
                                "damageTaken"        -- attackType
                            )

                            self.enemiesHit[enemy] = true

                            -- Add additional effects if needed
                            if self.onHitEnemy then
                                self.onHitEnemy(enemy)
                            end
                        end
                    end
                end
            end
        end,

        -- Draw function
        draw = function(self)
            -- Draw particles
            for _, p in ipairs(self.particles) do
                if p and p.color then
                    local progress = p.age / p.lifetime
                    local alpha = 1 - progress * 0.8 -- Retain more opacity longer
                    love.graphics.setColor(
                        p.color[1],
                        p.color[2],
                        p.color[3],
                        (p.color[4] or 1) * alpha
                    )
                    love.graphics.circle("fill", p.x, p.y, p.currentSize or p.size)
                end
            end

            -- Draw necrotic core with increased opacity
            love.graphics.setColor(0.4, 0.1, 0.4, 1) -- More opaque deep purple
            love.graphics.circle("fill", self.x, self.y, 4) -- Increased core size for visibility

            -- Draw core outline with higher opacity
            love.graphics.setColor(0.4, 0.1, 0.4, 0.7)
            love.graphics.circle("line", self.x, self.y, 8) -- Larger outline to match core
        end,
    }
end



-- effects.lua

if type == "magic_ray" then
    return {
        type = "magic_ray",
        x = x,
        y = y,
        targetX = targetX,
        targetY = targetY,
        duration = 0.2, -- Duration in seconds
        timer = 0,
        isDead = false,
        age = 0,

        -- Particle properties
        particles = {},
        particleTimer = 0,
        particleInterval = 0.05, -- Spawn particles every 0.05 seconds

        update = function(self, dt)
            self.timer = self.timer + dt
            if self.timer >= self.duration then
                self.isDead = true
            end

            -- Spawn particles
            self.particleTimer = self.particleTimer + dt
            if self.particleTimer >= self.particleInterval then
                self.particleTimer = self.particleTimer - self.particleInterval
                -- Spawn a new particle at a random position along the beam
                local t = math.random() -- Random progress along the beam (0 to 1)
                local px = self.x + (self.targetX - self.x) * t
                local py = self.y + (self.targetY - self.y) * t

                -- Calculate perpendicular direction for swirling
                local angle = math.atan2(self.targetY - self.y, self.targetX - self.x)
                local perpAngle1 = angle + math.pi / 2
                local perpAngle2 = angle - math.pi / 2
                local swirlDir = math.random() < 0.5 and perpAngle1 or perpAngle2

                local speed = math.random(30, 60)
                local vx = math.cos(swirlDir) * speed
                local vy = math.sin(swirlDir) * speed

                -- Particle colors from the palette with adjusted opacity for glow
                local colorOptions = {
                    {0.678, 0.251, 0.188, 0.4},   -- Rust Red (ad4030)
                    {0.184, 0.239, 0.227, 0.4},   -- Dark Teal (2f3d3a)
                    {0.608, 0.298, 0.388, 0.4},   -- Dark Rose (9b4c63)
                }
                local color = colorOptions[math.random(1, #colorOptions)]

                table.insert(self.particles, {
                    x = px,
                    y = py,
                    vx = vx,
                    vy = vy,
                    size = math.random(3, 6), -- Increased size for glow
                    lifetime = 0.7, -- Longer lifetime
                    age = 0,
                    color = color,
                })
            end

            -- Update particles
            for i = #self.particles, 1, -1 do
                local p = self.particles[i]
                p.age = p.age + dt
                if p.age >= p.lifetime then
                    table.remove(self.particles, i)
                else
                    -- Move particle
                    p.x = p.x + p.vx * dt
                    p.y = p.y + p.vy * dt

                    -- Fade out over time
                    p.color[4] = 0.4 * (1 - p.age / p.lifetime)
                end
            end
        end,

        draw = function(self)
            -- Define the gradient colors based on your palette
            local color1 = {0.678, 0.251, 0.188, 0.8} -- Rust Red (ad4030)
            local color2 = {0.184, 0.239, 0.227, 0.8} -- Dark Teal (2f3d3a)
            local color3 = {0.608, 0.298, 0.388, 0.8} -- Dark Rose (9b4c63)

            -- Number of segments for the gradient
            local segments = 40

            -- Calculate the total length of the ray
            local dx = self.targetX - self.x
            local dy = self.targetY - self.y
            local length = math.sqrt(dx * dx + dy * dy)

            -- Calculate the angle of the ray
            local angle = math.atan2(dy, dx)

            -- Set line width
            love.graphics.setLineWidth(6)

            -- Iterate through each segment to draw the gradient
            for i = 1, segments do
                local t_start = (i - 1) / segments
                local t_end = i / segments

                -- Determine which color range this segment falls into
                local color
                if t_start < (1/3) then
                    -- Transition from color1 to color2
                    local local_t = (t_start) / (1/3)
                    color = {
                        color1[1] + (color2[1] - color1[1]) * local_t,
                        color1[2] + (color2[2] - color1[2]) * local_t,
                        color1[3] + (color2[3] - color1[3]) * local_t,
                        color1[4] + (color2[4] - color1[4]) * local_t,
                    }
                elseif t_start < (2/3) then
                    -- Transition from color2 to color3
                    local local_t = (t_start - 1/3) / (1/3)
                    color = {
                        color2[1] + (color3[1] - color2[1]) * local_t,
                        color2[2] + (color3[2] - color2[2]) * local_t,
                        color2[3] + (color3[3] - color2[3]) * local_t,
                        color2[4] + (color3[4] - color2[4]) * local_t,
                    }
                else
                    -- Solid color3
                    color = {color3[1], color3[2], color3[3], color3[4]}
                end

                love.graphics.setColor(color)

                -- Calculate start and end points of the segment
                local startX = self.x + dx * t_start
                local startY = self.y + dy * t_start
                local endX = self.x + dx * t_end
                local endY = self.y + dy * t_end

                -- Draw the segment
                love.graphics.line(startX, startY, endX, endY)
            end

            -- Reset color to white for other drawings
            love.graphics.setColor(1, 1, 1, 1)

            -- Draw particles with additive blending for glow
            love.graphics.setBlendMode("add")
            for _, p in ipairs(self.particles) do
                love.graphics.setColor(p.color)
                love.graphics.circle("fill", p.x, p.y, p.size)
            end
            love.graphics.setBlendMode("alpha")

            -- Reset line width and color
            love.graphics.setLineWidth(1)
            love.graphics.setColor(1, 1, 1, 1)
        end,
    }
end


if type == "slash" then
    -- Calculate angle based on source (enemy) and target (character) positions
    local angle = math.atan2(targetY - y, targetX - x) -- Calculate angle based on target position
    
    return {
        x = x,
        y = y,
        angle = angle,
        lifetime = 0.2, -- Slash lasts 0.2 seconds
        age = 0,
        isDead = false,
        update = function(self, dt)
            self.age = self.age + dt
            if self.age >= self.lifetime then
                self.isDead = true -- Mark for removal
            end
        end,
        draw = function(self)
            if self.age < self.lifetime then
                love.graphics.push()
                love.graphics.translate(self.x, self.y)
                love.graphics.rotate(self.angle)

                -- White outline
               love.graphics.setColor(0.651, 0.6, 0.596, 1) -- warmGray

                love.graphics.rectangle("fill", -8, -2, 16, 4)

                -- Red center
                love.graphics.setColor(226/255, 114/255, 91/255, 1) -- terraCotta

                love.graphics.rectangle("fill", -8, -1, 16, 2)

                love.graphics.pop()
            end
        end,
    }
end


if type == "magic_ray_hit" then
    return {
        type = "magic_ray_hit",
        x = x,
        y = y,
        duration = 0.3, -- Duration in seconds
        timer = 0,
        isDead = false,
        update = function(self, dt)
            self.timer = self.timer + dt
            if self.timer >= self.duration then
                self.isDead = true
            end
        end,

        draw = function(self)
            local progress = math.min(self.timer / self.duration, 1)
            local alpha = 1 - progress

            -- Draw expanding and fading circles to simulate an impact
            love.graphics.setColor(226/255, 114/255, 91/255, alpha) -- terraCotta

            love.graphics.circle("fill", self.x, self.y, 10 * progress) -- Expanding circle

            love.graphics.setColor(1, 1, 1, alpha * 0.5) -- White glow with fading alpha

            love.graphics.circle("fill", self.x, self.y, 8 * progress) -- Slightly smaller expanding circle

            -- Add sparks or particles
            love.graphics.setColor(1, 1, 1, alpha * 0.7) -- White glow with fading alpha

            for i = 1, 5 do
                local offsetX = math.random(-5, 5)
                local offsetY = math.random(-5, 5)
                love.graphics.circle("fill", self.x + offsetX, self.y + offsetY, 2 * progress)
            end

            -- Reset color
            love.graphics.setColor(1, 1, 1, 1)
        end,
    }
end


if type == "poison_zone" then
  -- Capture the player reference from the outer scope if needed
  local playerRef = attachedTo -- Assuming 'attachedTo' might be the player in this context, or adjust as needed.
                               -- Or maybe it's passed via another argument? Let's assume it's passed correctly.
                               -- We need to ensure the 'player' variable used below is correctly sourced.
                               -- Let's assume the 12th argument `damageNumbers` is actually `player` based on bossAbilities call.
  local player = damageNumbers -- *** Assuming the 12th argument is the player ***

  return {
    type = "poison_zone",
    x = x,
    y = y,
    duration = duration or 60, -- <<< FIX: Use the passed 'duration' parameter, default to 60 if nil
    timer = 0,
    isDead = false,
    frameTimer = 0,
    frameDuration = 0.2,
    currentFrame = 1,
    zIndex = -1,
    player = player, -- Use the captured player reference
    damagePerSecond = 50,
    update = function(self, dt)
      self.timer = self.timer + dt
      self.frameTimer = self.frameTimer + dt
      if self.frameTimer >= self.frameDuration then
        self.frameTimer = self.frameTimer - self.frameDuration
        self.currentFrame = (self.currentFrame % 3) + 1
      end
      if self.timer >= self.duration then
        self.isDead = true
      end
      -- Check collision with the player and apply damage
      if self.player and self.player.takeDamage and not self.player.isDead then -- Added check for takeDamage method
        local dx = self.player.x - self.x
        local dy = self.player.y - self.y
        local collisionRadius = 16 -- Half the base size (16px) since scale is 2x
        if dx * dx + dy * dy <= collisionRadius * collisionRadius then
          self.player:takeDamage((self.damagePerSecond or 5) * dt)
        end
      end
    end,
    draw = function(self)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(poisonWebImage, poisonWebFrames[self.currentFrame], self.x, self.y, 0, 2, 2, 8, 8)
    end,
  }
end





if type == "magic_ray_telegraph" then
    return {
        type = "magic_ray_telegraph",
        x = x,
        y = y,
        targetX = targetX,
        targetY = targetY,
        duration = 1.0, -- Telegraph duration in seconds
        timer = 0,
        isDead = false,
        flashFrequency = 5, -- Number of flashes per second

        update = function(self, dt)
            self.timer = self.timer + dt
            if self.timer >= self.duration then
                self.isDead = true
            end
        end,

        draw = function(self)
            local progress = math.min(self.timer / self.duration, 1)
            local alpha = 0.4 * math.abs(math.sin(self.timer * self.flashFrequency * math.pi * 2))

            love.graphics.setLineWidth(4)
            love.graphics.setColor(1, 0, 0, alpha) -- Semi-transparent red

            -- Draw the telegraph line
            love.graphics.line(self.x, self.y, self.targetX, self.targetY)

            -- Reset line width and color
            love.graphics.setLineWidth(1)
            love.graphics.setColor(1, 1, 1, 1)
        end,
    }
end

if type == "osskar_dash_telegraph" then
    return {
        type = "osskar_dash_telegraph",
        x = x,
        y = y,
        targetX = targetX,
        targetY = targetY,
        duration = 1.0,  -- same as dashTelegraphDuration
        timer = 0,
        isDead = false,
        flashFrequency = 5, -- 5 flashes per second
        update = function(self, dt)
            self.timer = self.timer + dt
            if self.timer >= self.duration then
                self.isDead = true
            end
        end,
        draw = function(self)
            local progress = math.min(self.timer / self.duration, 1)
            local alpha = 0.4 * math.abs(math.sin(self.timer * self.flashFrequency * math.pi * 2))

            -- Use Osskar colors: ef9e4e (239/255,158/255,78/255) and ad4030 (173/255,64/255,48/255)
            -- We'll choose one (ef9e4e) for the line
            love.graphics.setLineWidth(4)
            love.graphics.setColor(239/255, 158/255, 78/255, alpha)
            love.graphics.line(self.x, self.y, self.targetX, self.targetY)
            love.graphics.setLineWidth(1)
            love.graphics.setColor(1,1,1,1)
        end,
    }
end


if type == "flame_wave" then
    -- Define the orangeGold color
    local orangeGold = {239/255, 158/255, 78/255, 1}

    -- Predefine flame frames (assuming each frame is 16x16; adjust if different)
    local flameFrames = {
        love.graphics.newQuad(0, 0, 16, 16, flameImage:getDimensions()),
        love.graphics.newQuad(16, 0, 16, 16, flameImage:getDimensions()),
        love.graphics.newQuad(32, 0, 16, 16, flameImage:getDimensions())
    }

    return {
        x = x,
        y = y,
        startX = x,   -- Track initial position
        startY = y,
        targetX = targetX or x,
        targetY = targetY or y,
        directionX = (targetX or x) - x,
        directionY = (targetY or y) - y,
        speed = 300,  -- Speed of the wave
        isDead = false,
        scale = scale or 0.3,  -- Adjusted scale for smaller size
        damage = damage or 0,
        enemies = enemies,
        effects = effects,
        radius = 10,
        enemiesHit = {},
        particles = {},
        trailTimer = 0,
        trailInterval = 0.1,

        -- Animation data
        animation = {
            currentFrame = 1,
            frameTimer = 0,
            frameDuration = 0.1,  -- Time per frame
            totalFrames = #flameFrames
        },

        update = function(self, dt)
            -- Normalize direction vector
            local dist = math.sqrt(self.directionX^2 + self.directionY^2)
            if dist > 0 then
                self.directionX = self.directionX / dist
                self.directionY = self.directionY / dist
            end

            -- Move the flame wave
            self.x = self.x + self.directionX * self.speed * dt
            self.y = self.y + self.directionY * self.speed * dt

            -- Update animation
            self.animation.frameTimer = self.animation.frameTimer + dt
            if self.animation.frameTimer >= self.animation.frameDuration then
                self.animation.frameTimer = 0
                self.animation.currentFrame = self.animation.currentFrame % self.animation.totalFrames + 1
            end

            -- Update trail particles
            for i = #self.particles, 1, -1 do
                local p = self.particles[i]
                p.age = p.age + dt
                if p.age >= p.lifetime then
                    table.remove(self.particles, i)
                else
                    p.x = p.x + p.vx * dt
                    p.y = p.y + p.vy * dt
                end
            end

            -- Spawn new particles
            self.trailTimer = self.trailTimer + dt
            if self.trailTimer >= self.trailInterval then
                self.trailTimer = 0
                table.insert(self.particles, {
                    x = self.x,
                    y = self.y,
                    vx = -self.directionX * 100,  -- Reduced velocity for smaller trail
                    vy = -self.directionY * 100,
                    size = love.math.random(1, 3),  -- Reduced size for smaller particles
                    age = 0,
                    lifetime = .1,
                    color = orangeGold,  -- Set trail color to orangeGold
                })
            end

            -- Calculate distance traveled from start
            local distanceTraveled = math.sqrt((self.x - self.startX)^2 + (self.y - self.startY)^2)
            if distanceTraveled >= 600 then
                self.isDead = true
                return
            end

            -- Collision with enemies
            if self.enemies then
                for _, enemy in ipairs(self.enemies) do
                    if not self.enemiesHit[enemy] and not enemy.isDead then
                        local dx = enemy.x - self.x
                        local dy = enemy.y - self.y
                        local distToEnemy = math.sqrt(dx*dx + dy*dy)
                        if distToEnemy <= self.radius then
                            enemy:takeDamage(
                                self.damage or 0,
                                self.damageNumbers,
                                self.effects,
                                "Emberfiend",
                                nil,
                                "damageTaken"
                            )

                            self.enemiesHit[enemy] = true
                            -- Optionally apply Ignite, etc.
                    if self.effects then
    local igniteEffect = Effects.new("ignite", enemy.x, enemy.y, nil, nil, self.source, enemy)
    -- Optionally, override default DPS or duration:
 local bonus = 0
if self.source and self.source.owner then
  bonus = self.source.owner.statusEffectDamageBonus or 0
end
igniteEffect.damagePerSecond = 15 + bonus


    igniteEffect.duration = 5  -- or any desired value
    table.insert(self.effects, igniteEffect)
end



                        end
                    end
                end
            end
        end,

        draw = function(self)
            -- Pick current frame
            local frame = flameFrames[self.animation.currentFrame]
            love.graphics.setColor(1, 1, 1, 1)
    -- Fixed smaller scale (e.g., 0.3)
    local fixedScale = 2

            -- Draw the flame sprite using the current frame with scaling
            love.graphics.draw(
                flameImage,
                frame,
                self.x,
                self.y,
                0,             -- Rotation
                fixedScale,    -- Scale X
                fixedScale,    -- Scale Y
                8,             -- Origin X (half of 16)
                8              -- Origin Y (half of 16)
            )
            -- Draw particle trail
            for _, p in ipairs(self.particles) do
                local alpha = math.max(p.age / p.lifetime, 0)
                love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
                love.graphics.circle("fill", p.x, p.y, p.size * alpha)
            end
        end,
    }
end


 local visualEffects = {
    "arrow_trail", "fire_flame", "spear_glow", "arcane_trail",
    "hit_spark", "explosion", "hellblast", "meteor_impact",
    "necrotic_wave", "necrotic_chain", "static_wave",
    "ignite",
}


-- Set `isEffect` flag
self.isEffect = table.contains(visualEffects, self.type)

 
    return self
   

   
   end
 
function Effects:updateUnholyGround(dt)
    -- Initialize initial_duration if not set
    if not self.initial_duration then
        self.initial_duration = self.duration
    end

    -- Decrease the duration timer
    self.duration = self.duration - dt
    if self.duration <= 0 then
        self.isDead = true
        return
    end

    -- Spawn acid particles
    self.acidParticleTimer = (self.acidParticleTimer or 0) + dt
    if self.acidParticleTimer >= self.acidParticleInterval then
        self.acidParticleTimer = self.acidParticleTimer - self.acidParticleInterval
        local angle = math.random() * 2 * math.pi
        local dist = math.random() * self.radius * 0.8
        local px = self.x + math.cos(angle) * dist
        local py = self.y + math.sin(angle) * dist
        table.insert(self.acidParticles, {
            x = px,
            y = py,
            vx = (love.math.random() - 0.5) * 20,
            vy = (love.math.random() * -20) - 10,
            lifetime = 1,
            age = 0,
            size = math.random(2,4),
            color = {0.3, 0.1, 0.3, 1},
        })
    end

    -- Update acid particles
    for i = #self.acidParticles, 1, -1 do
        local p = self.acidParticles[i]
        p.age = p.age + dt
        if p.age >= p.lifetime then
            table.remove(self.acidParticles, i)
        else
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.color[4] = 1 - (p.age / p.lifetime)
        end
    end

    -- Damage Timer Logic (unchanged)
    self.damageTimer = (self.damageTimer or 0) + dt
    if self.damageTimer >= 1.0 then
        self.damageTimer = self.damageTimer - 1.0
        self.shouldApplyDamage = true
    end
end


function Effects:drawUnholyGround()
    -- Calculate the alpha based on remaining duration
    local alpha = self.initial_duration and math.max(self.duration / self.initial_duration, 0) or 1

    -- Draw the main unholy ground circle using darkRedBrown
    love.graphics.setColor(darkRedBrown[1], darkRedBrown[2], darkRedBrown[3], 0.4 * alpha)
    love.graphics.circle("fill", self.x, self.y, self.radius)

    -- Draw concentric layers using mutedBrick
    local layers = 5
    for i = 1, layers do
        local layer_alpha = 0.2 * (1 - (i / layers)) * alpha
        love.graphics.setColor(mutedBrick[1], mutedBrick[2], mutedBrick[3], layer_alpha)
        love.graphics.circle("fill", self.x, self.y, self.radius * (1 - i * 0.1))
    end

    -- Optional: Draw a secondary glow using darkRose
    love.graphics.setColor(darkRose[1], darkRose[2], darkRose[3], 0.8 * alpha)
    love.graphics.setLineWidth(2)
    -- (You can add additional glow elements here if desired.)

    -- Draw acid particles (assumes each particle's color is already set)
    if self.acidParticles then
        for _, p in ipairs(self.acidParticles) do
            love.graphics.setColor(p.color)
            love.graphics.circle("fill", p.x, p.y, p.size)
        end
    end
end





 
function Effects:update(dt)
    if not self.type then return end
    
    self.age = self.age + dt
    if self.age >= self.lifetime then
        self.isDead = true
    end

    self.enemies = self.enemies or {} -- Ensure enemies is always a table
    self.timer = self.timer + dt

    -- Remove the effect if its duration has elapsed
    if self.timer >= self.duration then
        self.isDead = true
        return
    end

    -- Remove the effect if it’s attached to an entity that is dead
    if self.attachedTo and self.attachedTo.isDead then
        self.isDead = true
        return
    end

if self.type == "unholy_ground" then
    self:updateUnholyGround(dt)
end


if self.type == "poison" then
    self.poisonTimer = (self.poisonTimer or 0) + dt
    local poisonDamageInterval = 1.0 -- Damage every second
    if self.poisonTimer >= poisonDamageInterval then
        self.poisonTimer = self.poisonTimer - poisonDamageInterval

        if self.attachedTo and not self.attachedTo.isDead then
            -- Recalculate bonus dynamically
            local bonus = (self.source and self.source.statusEffectDamageBonus) or 0

            local baseDPS = Abilities.statusEffects.Poison.damagePerSecond or 3
            -- Optionally add a rank bonus if you store a rank in the applied effect:
            local rankBonus = (self.attachedTo.statusEffects["Poison"] and self.attachedTo.statusEffects["Poison"].rank and 2 * self.attachedTo.statusEffects["Poison"].rank) or 0
            local damage = baseDPS + rankBonus + bonus
            self.attachedTo:takeDamage(damage, nil, self.effects, "poison", nil, "damageOverTime")
        else
            self.isDead = true
            return
        end
    end

    if self.attachedTo then
        self.x = self.attachedTo.x
        self.y = self.attachedTo.y
    end
end


  


    -- Apply area of effect damage for specific types
    if self.type == "fireball" then
        applyDamage(self, "fireball", self.impactRadius, 15)
    elseif self.type == "explosive_fireballs" then
        applyDamage(self, "explosive_fireballs", self.impactRadius, 18)
    elseif self.type == "hellblast" then
        applyDamage(self, "hellblast", self.impactRadius, 12)
    elseif self.type == "flame_burst" then
        applyDamage(self, "flame_burst", self.impactRadius, 14)
    elseif self.type == "Necrotic_Burst" then
        applyDamage(self, "Necrotic_Burst", self.impactRadius, 14)
    elseif self.type == "blizzard" then
        applyDamage(self, "blizzard", self.impactRadius, 20)
    elseif self.type == "zephyr_shield" then
        applyDamage(self, "zephyr_shield", self.impactRadius, 16)
    elseif self.type == "storm_arc" then
        applyDamage(self, "storm_arc", self.impactRadius, 20)
    end

    -- Handle meteor swarm effect
    if self.type == "meteor_swarm" then
        self.damageTimer = self.damageTimer or 0
        self.damageInterval = self.damageInterval or 0.5 -- Adjust as needed
        self.damageTimer = self.damageTimer + dt

        if self.damageTimer >= self.damageInterval then
            self.damageTimer = 0
            for _, enemy in ipairs(self.enemies or {}) do
                if enemy and not enemy.isDead then
                    local ex = enemy.x - self.x
                    local ey = enemy.y - self.y
                    if ex * ex + ey * ey <= (self.impactRadius or 50) ^ 2 then
                        local damage = self.damagePerMeteor or 0
                        enemy:takeDamage(damage, self.damageNumbers, self.effects, "Emberfiend")
                        
                    end
                end
            end
        end

        -- Spawn meteors periodically
        if self.meteorsSpawned and self.meteorsSpawned >= self.numberOfMeteors then
            self.isDead = true
            return
        end

        self.nextMeteorTime = (self.nextMeteorTime or 0) - dt
        if self.nextMeteorTime <= 0 then
            self.nextMeteorTime = self.meteorInterval
            self.meteorsSpawned = (self.meteorsSpawned or 0) + 1

            local spawnOffsetX = love.math.random(-self.impactRadius, self.impactRadius)
            local spawnOffsetY = love.math.random(-600, -self.impactRadius)
            local startX = self.x + spawnOffsetX
            local startY = self.y + spawnOffsetY

            local angle = love.math.random() * 2 * math.pi
            local distance = love.math.random() * self.impactRadius
            local offsetX = math.cos(angle) * distance
            local offsetY = math.sin(angle) * distance
            local targetX = self.x + offsetX
            local targetY = self.y + offsetY

            local fallingMeteor = Effects.new(
                "falling_meteor",
                startX,
                startY,
                targetX,
                targetY,
                nil,
                nil,
                self.effects,
                self.impactRadius,
                self.damagePerMeteor,
                self.enemies,
                self.damageNumbers
            )
            fallingMeteor.speed = 500
            fallingMeteor.infernalRainCenterX = self.x
            fallingMeteor.infernalRainCenterY = self.y
            table.insert(self.effects, fallingMeteor)
        end
    end

    -- Handle falling meteor effect
    if self.type == "falling_meteor" then
        local dx = self.targetX - self.x
        local dy = self.targetY - self.y
        local previousDistance = math.sqrt(dx * dx + dy * dy)
        local directionX = dx / previousDistance
        local directionY = dy / previousDistance

        self.x = self.x + directionX * self.speed * dt
        self.y = self.y + directionY * self.speed * dt

        dx = self.targetX - self.x
        dy = self.targetY - self.y
        local newDistance = math.sqrt(dx * dx + dy * dy)

        if newDistance > previousDistance then
            self.isDead = true
            for _, enemy in ipairs(self.enemies or {}) do
                local ex = enemy.x - self.infernalRainCenterX
                local ey = enemy.y - self.infernalRainCenterY
                if ex * ex + ey * ey <= (self.impactRadius or 50) ^ 2 then
                    local damage = self.damagePerMeteor or 10
                    enemy:takeDamage(damage, self.damageNumbers, self.effects, "Emberfiend", nil, "aoe")
                end
            end

            local impact = Effects.new("meteor_impact", self.targetX, self.targetY, nil, nil, nil, nil, self.effects)
            impact.duration = 0.5
            table.insert(self.effects, impact)
        end
    end

if type == "flame_circle" then
  local owner = ownerType          -- capture the Emberfiend (or any character passed in)
  return {
    type     = "flame_circle",
    timer    = 0,
    duration = duration or 5,
    radius   = impactRadius or 100,
    damage   = damagePerMeteor or 10,
    enemies  = enemies or {},
    damageNumbers = damageNumbers or {},
    update = function(self, dt)
      self.timer = self.timer + dt
      -- orbit around owner
      local t = self.timer * 2  -- angular speed
      self.x = owner.x + math.cos(t) * self.radius
      self.y = owner.y + math.sin(t) * self.radius
      -- ignite on contact
      for _, e in ipairs(self.enemies) do
        local dx, dy = e.x - self.x, e.y - self.y
        if dx*dx + dy*dy <= (16*16) then
          e:applyStatusEffect({ name = "Ignite", duration = 3, damagePerSecond = self.damage * 0.2 })
          table.insert(self.effects,
            Effects.new("ignite", e.x, e.y, nil, nil, owner, e))
        end
      end
      -- explode outward after finish
      if self.timer >= self.duration then
        for _, e in ipairs(self.enemies) do
          local dx, dy = e.x - owner.x, e.y - owner.y
          local dist = math.sqrt(dx*dx + dy*dy)
          if dist > 0 then
            local tx = owner.x + dx/dist * 300
            local ty = owner.y + dy/dist * 300
            local proj = Effects.new("flame_wave", owner.x, owner.y, tx, ty,
                                     owner, nil, self.effects, nil, self.damage, self.enemies, self.damageNumbers)
            proj.damage = self.damage
            table.insert(self.effects, proj)
          end
        end
        self.isDead = true
      end
    end,
    draw = function(self) end
  }
end

 end



function Effects:draw()
    if not self.enemies then
        self.enemies = {} -- Ensure enemies is always a table
    end
    
    if self.isDead then return end
    if self.attachedTo and self.attachedTo.isDead then return end
    
     if self.type == "unholy_ground" then
    self:drawUnholyGround()
end

     
     if self.type == "splash" then
        local progress = self.timer / self.duration
        local alpha = 1 - progress

        -- Draw multiple particles emanating from the splash point
        local numParticles = 12
        for i = 1, numParticles do
            local angle = (i / numParticles) * (2 * math.pi)
            local distance = 10 * progress  -- Particles move outward
            local size = 3 * (1 - progress)  -- Particles shrink over time

            local px = self.x + math.cos(angle) * distance
            local py = self.y + math.sin(angle) * distance

            love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha)
            love.graphics.circle("fill", px, py, size)
        end

        -- Optional: Central glow that fades out
        love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha * 0.5)
        love.graphics.circle("fill", self.x, self.y, 5 * (1 - progress))
    end

   if self.type == "hellblast" then
        -- We now use red and yellow particles (rustRed, mustardYellow) instead of a freeze style.
        local progress = math.min(self.timer / self.duration, 1)
        local numParticles = 14  -- a few more for visual punch
        local alpha = 1 - progress

        -- Outer ring of random red or yellow particles
        for i = 1, numParticles do
            local angle = (i / numParticles) * (2 * math.pi)
            local distance = 40 + 40 * progress
            local size = 8 * alpha
            local px = self.x + math.cos(angle) * distance
            local py = self.y + math.sin(angle) * distance

            -- Randomly pick red or yellow from the palette
            local color = (math.random() < 0.5) and rustRed or mustardYellow

            love.graphics.setColor(color[1], color[2], color[3], alpha)
            love.graphics.circle("fill", px, py, size)
        end

        -- Central glow
        love.graphics.setColor(rustRed[1], rustRed[2], rustRed[3], 0.5 * alpha)
        love.graphics.circle("fill", self.x, self.y, 22 * alpha)

        -- Slight yellow highlight in center
        love.graphics.setColor(mustardYellow[1], mustardYellow[2], mustardYellow[3], 0.4 * alpha)
        love.graphics.circle("fill", self.x, self.y, 14 * alpha)



        
        
  elseif self.type == "shock" then
    local progress = math.min(self.timer / self.duration, 1)
    local alpha = 1 - progress
    love.graphics.setColor(0.964, 0.949, 0.764, alpha) -- paleYellow

    local numBolts = 5
    for i = 1, numBolts do
        local angle = math.random() * 2 * math.pi
        local length = 15 * (1 - progress)
        local x1 = self.x
        local y1 = self.y
        local x2 = x1 + math.cos(angle) * length
        local y2 = y1 + math.sin(angle) * length
        love.graphics.setLineWidth(2)
        love.graphics.line(x1, y1, x2, y2)
    end

   
if self.type == "hit_splash" then

    local progress = math.min(self.timer / self.duration, 1)
    local alpha = 1 - progress
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha)
    love.graphics.circle("fill", self.x, self.y, self.radius * (1 - progress))
end







   elseif self.type == "meteor_swarm" then
    -- Drawing code for meteor_swarm
    love.graphics.setColor(173/255, 64/255, 48/255, 0.3) -- rustRed

    love.graphics.circle("line", self.x, self.y, self.impactRadius)
    
  elseif self.type == "meteor_impact" then
    local progress = self.timer / self.duration
    local maxParticles = 15  -- Number of explosion particles
    local size = 5 * (1 - progress)  -- Shrinking size of particles

    for i = 1, maxParticles do
        -- Calculate random offsets for explosion particles
        local angle = math.random() * 2 * math.pi
        local distance = math.random(20, 50) * progress  -- Particles move outward with progress
        local particleX = self.x + math.cos(angle) * distance
        local particleY = self.y + math.sin(angle) * distance

        -- Randomly select a color (gray, orange, or yellow)
        local colors = {
            {0.5, 0.5, 0.5},  -- Gray
            {1, 0.5, 0},      -- Orange
            {1, 1, 0},        -- Yellow
        }
        local color = colors[math.random(1, #colors)]

        -- Set the particle color with fading alpha
        love.graphics.setColor(color[1], color[2], color[3], 1 - progress)

        -- Draw the particle
        love.graphics.circle("fill", particleX, particleY, size)
    end

        
        
    elseif self.type == "falling_meteor" then
      love.graphics.setColor(239/255, 158/255, 78/255, 1) -- orangeGold

      love.graphics.setLineWidth(3)
      love.graphics.line(self.x, self.y, self.x - 20 * math.cos(self.rotation), self.y - 20 * math.sin(self.rotation))
      love.graphics.setColor(1, 1, 0, 0.5)  -- Yellowish glow
      love.graphics.circle("fill", self.x, self.y, 5)  -- Glowing meteor head

  
  
  


    elseif self.type == "zephyr_shield" then
    love.graphics.setColor(1, 1, 1)  -- Ensure the sprite is drawn with full color
    -- Assuming `self` has a `draw` method now
    if self.draw then
        self:draw()
    else
        love.graphics.draw(shieldImage, self.x, self.y, self.rotation or 0, 1, 1, shieldImage:getWidth() / 2, shieldImage:getHeight() / 2)
    end



  

    -- Ensure it follows the enemy
    if self.attachedTo then
        self.x = self.attachedTo.x
        self.y = self.attachedTo.y
    end

    local progress = math.min(self.timer / self.duration, 1)
    local numParticles = 8
    for i = 1, numParticles do
        local angle = math.random() * 2 * math.pi
        local distance = math.random() * 10
        local offsetX = math.cos(angle) * distance
        local offsetY = math.sin(angle) * distance
        local size = 5 + 3 * math.sin(self.timer * 10 + i)
        local alpha = 0.5 + 0.5 * math.sin(self.timer * 5 + i)
       love.graphics.setColor(0.678, 0.251, 0.188, alpha) -- rustRed

        love.graphics.circle("fill", self.x + offsetX, self.y + offsetY, size * (1 - progress))
    end

    -- Central glow effect
    love.graphics.setColor(0.678, 0.251, 0.188, 0.8 * (1 - progress)) -- rustRed

    love.graphics.circle("fill", self.x, self.y, 10 * (1 - progress))

elseif self.type == "storm_arc_enhanced" then
    love.graphics.setLineWidth(1)
    -- Use light blue colors for enhanced chain
    local startColor = {0.5, 0.8, 1, 1}    -- light blue start
    local endColor = {0.8, 0.9, 1, 1}        -- lighter blue end
    local segments = 6                      -- you can adjust if needed
    local previousX, previousY = self.x, self.y

    for i = 1, segments do
        local progress = i / segments
        local dx = (self.targetX - self.x) / segments
        local dy = (self.targetY - self.y) / segments

        local offsetX = math.random(-6, 6)
        local offsetY = math.random(-6, 6)
        local nextX = previousX + dx + offsetX
        local nextY = previousY + dy + offsetY

        -- Interpolate the light blue colors:
        local r = startColor[1] + progress * (endColor[1] - startColor[1])
        local g = startColor[2] + progress * (endColor[2] - startColor[2])
        local b = startColor[3] + progress * (endColor[3] - startColor[3])
        love.graphics.setColor(r, g, b, 1 - progress)
        love.graphics.line(previousX, previousY, nextX, nextY)

        previousX, previousY = nextX, nextY
    end


elseif self.type == "goylebite" then
    -- Increase the progress multiplier to speed up the effect
    local speedMultiplier = 5  -- Adjust this value for faster or slower speed
    local progress = math.min((self.timer / self.duration) * speedMultiplier, 1)
    local alpha = 1 - progress  -- Fade out over time
   love.graphics.setColor(0.964, 0.949, 0.764, alpha) -- paleYellow


    -- Use linear movement for constant speed
    local initialDistance = 30  -- Reduced initial distance
    local moveDistance = initialDistance * (1 - progress)  -- Linear movement

    -- Upper teeth (moving down, pointing down, starting closer together)
    love.graphics.polygon("fill", 
        self.x - 8, self.y - 2 - moveDistance,   -- Adjusted Y-coordinates
        self.x - 5, self.y + 1 - moveDistance,   
        self.x - 2, self.y - 2 - moveDistance    
    )
    love.graphics.polygon("fill", 
        self.x + 8, self.y - 2 - moveDistance,   
        self.x + 5, self.y + 1 - moveDistance,   
        self.x + 2, self.y - 2 - moveDistance    
    )

    -- Lower teeth (moving up, pointing up, starting closer together)
    love.graphics.polygon("fill", 
        self.x - 8, self.y + 2 + moveDistance,   -- Adjusted Y-coordinates
        self.x - 5, self.y + 5 + moveDistance,   
        self.x - 2, self.y + 2 + moveDistance    
    )
    love.graphics.polygon("fill", 
        self.x + 8, self.y + 2 + moveDistance,   
        self.x + 5, self.y + 5 + moveDistance,   
        self.x + 2, self.y + 2 + moveDistance    
    )






 

   elseif self.type == "explosion" then
    local rank = self.attachedTo and self.attachedTo.abilities["Molten Orbs"].rank or 1
    local maxRadius = 50 + (5 * rank)  -- Match to ability's damage radius
    local progress = math.min(self.timer / self.duration, 1)

    -- Outer fiery particles within maxRadius
    local numOuterParticles = 20  -- Increased number of outer particles
    love.graphics.setColor(0.937, 0.62, 0.306, 1) -- orangeGold

    for i = 1, numOuterParticles do
        local angle = math.random() * (2 * math.pi)  -- Random angle for more dynamic spread
        local distance = math.random() * maxRadius  -- Random distance within maxRadius
        local size = math.random(3, 6) * (1 - progress)  -- Varying sizes
        local x = self.x + math.cos(angle) * distance
        local y = self.y + math.sin(angle) * distance
        love.graphics.circle("fill", x, y, size)
    end

    -- Inner glow within a fraction of maxRadius
    love.graphics.setColor(0.964, 0.949, 0.764, 1 - progress) -- paleYellow
    love.graphics.circle("fill", self.x, self.y, (maxRadius * 0.3) * (1 - progress))  -- Increased inner core size

    -- Subtle flash for a fiery center
    love.graphics.setColor(0.651, 0.6, 0.596, 0.4 * (1 - progress)) -- warmGray
    love.graphics.circle("fill", self.x, self.y, (maxRadius * 0.2) * (1 - progress))

    -- Increased and more dynamic centered sparks
    local numSparks = 10  -- Increased number of sparks
    for i = 1, numSparks do
        local offsetX = math.random(-10, 10) * (1 - progress)
        local offsetY = math.random(-10, 10) * (1 - progress)
        love.graphics.setColor(222/255, 173/255, 190/255, 0.6 * (1 - progress)) -- blushPink

        local sparkSize = math.random(1, 3) * (1 - progress)
        love.graphics.circle("fill", self.x + offsetX, self.y + offsetY, sparkSize)
    end

    -- Optional: Add smoke particles for additional effect
    local numSmokeParticles = 15
    love.graphics.setColor(54/255, 69/255, 79/255, 0.3 * (1 - progress)) -- charcoalGray

    for i = 1, numSmokeParticles do
        local angle = math.random() * (2 * math.pi)
        local distance = math.random() * (maxRadius * 0.8)
        local size = math.random(2, 4) * (1 - progress)
        local x = self.x + math.cos(angle) * distance
        local y = self.y + math.sin(angle) * distance
        love.graphics.circle("fill", x, y, size)
    end



   
   
   
        

elseif self.type == "freeze" then
    local progress = math.min(self.timer / self.duration, 1)

    -- Frosty glow (smaller and subtler)
    love.graphics.setColor(70/255, 85/255, 95/255, 0.4 * (1 - progress)) -- smokyBlue

    love.graphics.circle("fill", self.x, self.y, 8 + 2 * progress) -- Smaller glow effect

    -- Central ice core (reduced size)
    love.graphics.setColor(70/255, 85/255, 95/255, 0.7) -- smokyBlue

    love.graphics.circle("fill", self.x, self.y, 6)

    -- Jagged icy shards (smaller and fewer particles)
    love.graphics.setColor(142/255, 184/255, 158/255, 0.6 * (1 - progress)) -- pastelMint

    local numShards = 4 + math.floor(1 * (1 - progress)) -- Reduced number of shards
    for i = 1, numShards do
        local angle = (i / numShards) * (2 * math.pi)
        local shardLength = 6 + 2 * (1 - progress) -- Shorter shards
        local shardThickness = 1.5 + 0.5 * (1 - progress) -- Thinner shards
        local x1 = self.x + math.cos(angle) * 6 -- Start closer to the center
        local y1 = self.y + math.sin(angle) * 6
        local x2 = x1 + math.cos(angle) * shardLength -- Extend outward
        local y2 = y1 + math.sin(angle) * shardLength
        love.graphics.setLineWidth(shardThickness)
        love.graphics.line(x1, y1, x2, y2)
    end




    elseif self.type == "teleport" then
        local progress = math.min(self.timer / self.duration, 1)
        love.graphics.setColor(25/255, 25/255, 112/255, 1 - progress) -- midnightBlue

        love.graphics.circle("line", self.x, self.y, 30 * progress)

   elseif self.type == "life_drain" then
    -- Set up the beam properties
    local segments = 20  -- Number of segments in the beam
    local amplitude = 10  -- Amplitude of the wave
    local frequency = 2   -- Frequency of the wave

    -- Calculate the distance and angle between source and target
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    local angle = math.atan2(dy, dx)

    -- Set the color to solid purple
   love.graphics.setColor(67/255, 33/255, 66/255, 1) -- deepPurple


    love.graphics.setLineWidth(4)
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(angle)

    -- Draw the wavy beam
    local points = {}
    for i = 0, segments do
        local t = i / segments
        local x = t * distance
        local y = math.sin(t * frequency * math.pi * 2 + self.timer * 5) * amplitude
        table.insert(points, x)
        table.insert(points, y)
    end
    love.graphics.line(points)
    love.graphics.pop()

    -- Draw a glowing effect at the target end
    love.graphics.setColor(166/255, 153/255, 152/255, 1) -- warmGray
    love.graphics.circle("fill", self.targetX, self.targetY, 8)

    -- Draw a glowing effect at the source end
    love.graphics.setColor(67/255, 33/255, 66/255, 0.7) -- deepPurple

    love.graphics.circle("fill", self.x, self.y, 8)

   
   
   elseif self.type == "storm_arc" then
    love.graphics.setLineWidth(1)

    -- Set the electric colors using the palette:
    local startColor = paleYellow         -- Use paleYellow from your palette
    local endColor = {1, 1, 0.9}            -- Brighter yellow-white end color
    local segments = 6                      -- Same number of segments for the lightning chain
    local previousX, previousY = self.x, self.y

    -- Loop through segments to create electric-style jagged lines
    for i = 1, segments do
        local progress = i / segments
        local dx = (self.targetX - self.x) / segments
        local dy = (self.targetY - self.y) / segments

        -- Add randomness for more electric, jagged movement
        local offsetX = math.random(-6, 6)
        local offsetY = math.random(-6, 6)
        local nextX = previousX + dx + offsetX
        local nextY = previousY + dy + offsetY

        -- Interpolate between the start and end color (for reference)
        local r = startColor[1] + progress * (endColor[1] - startColor[1])
        local g = startColor[2] + progress * (endColor[2] - startColor[2])
        local b = startColor[3] + progress * (endColor[3] - startColor[3])

        -- (The drawn line still uses orangeGold here; you can change that if desired)
        love.graphics.setColor(239/255, 158/255, 78/255, 1 - progress)
        love.graphics.line(previousX, previousY, nextX, nextY)

        previousX, previousY = nextX, nextY
    end

    



elseif self.type == "necrotic_chain" then
    love.graphics.setLineWidth(1)

    -- Set the necrotic chain colors (purple tones)
    local startColor = {0.6, 0.0, 0.6}  -- Dark purple start color
    local endColor = {0.8, 0.4, 0.8}    -- Lighter purple end color
    local segments = 3  -- Same number of segments for the chain
    local previousX, previousY = self.x, self.y

    -- Loop through segments to create a jagged chain
    for i = 1, segments do
        local progress = i / segments
        local dx = (self.targetX - self.x) / segments
        local dy = (self.targetY - self.y) / segments

        -- Add randomness for a jagged effect
        local offsetX = math.random(-6, 6)
        local offsetY = math.random(-6, 6)
        local nextX = previousX + dx + offsetX
        local nextY = previousY + dy + offsetY

        -- Interpolate between the start and end purple colors
        local r = startColor[1] + progress * (endColor[1] - startColor[1])
        local g = startColor[2] + progress * (endColor[2] - startColor[2])
        local b = startColor[3] + progress * (endColor[3] - startColor[3])
        love.graphics.setColor(r, g, b, 1 - progress)

        love.graphics.line(previousX, previousY, nextX, nextY)

        previousX, previousY = nextX, nextY
    end








  elseif self.type == "spear_glow" then
    local progress = math.min(self.timer / self.duration, 1)
    
    -- Set the color for the electric glow (gold/yellow)
   love.graphics.setColor(0.964, 0.949, 0.764, 1 - progress) -- paleYellow

    
    -- Draw subtle electric-style random bolts around the spear
    local numBolts = 4  -- Reduce the number of bolts for a toned-down effect
    for i = 1, numBolts do
        local startX = self.x + math.random(-2, 2)  -- Smaller random offset for the starting point
        local startY = self.y + math.random(-2, 2)
        local endX = startX + math.random(-6, 6)  -- Shorter, less jagged lines
        local endY = startY + math.random(-6, 6)
        love.graphics.setLineWidth(1.5)
        love.graphics.line(startX, startY, endX, endY)
    end

    -- Faint secondary glow around the spear for added electric effect
     love.graphics.setColor(0.964, 0.949, 0.764, 0.2 * (1 - progress)) -- paleYellow

    love.graphics.circle("fill", self.x, self.y, 7 * (1 - progress))  -- Electric aura around spear

elseif self.type == "fireball_trail" then
    local progress = math.min(self.timer / self.duration, 1)

    -- Draw the fireball itself
   love.graphics.setColor(0.937, 0.62, 0.306, 1 - progress) -- orangeGold

    love.graphics.circle("fill", self.x, self.y, 4 * (1 - progress))  -- Larger core with fade-out effect

    -- Add trailing particles
    for i = 1, 3 do
        local offsetX = math.random(-3, 3)
        local offsetY = math.random(-3, 3)
        local particleProgress = progress + (i * 0.1)
        local particleSize = 2 * (1 - particleProgress)
        
        if particleProgress < 1 then
            -- Alternate between red, yellow, and gray particles
           if i % 3 == 0 then
    love.graphics.setColor(222/255, 173/255, 190/255, 0.8 * (1 - particleProgress)) -- blushPink

elseif i % 3 == 1 then
    love.graphics.setColor(0.964, 0.949, 0.764, 0.8 * (1 - particleProgress))  -- paleYellow
else
    love.graphics.setColor(222/255, 173/255, 190/255, 0.8 * (1 - particleProgress)) -- blushPink

end

            love.graphics.circle("fill", self.x + offsetX, self.y + offsetY, particleSize)
        end
    end




        
     elseif self.type == "arcane_trail" then
    local progress = math.min(self.timer / self.duration, 1)
    local numParticles = 4  -- Reduce number of particles for a more subtle effect
  love.graphics.setColor(0.263, 0.129, 0.259, 1 - progress) -- deepPurple


    for i = 1, numParticles do
        local angle = math.random() * 2 * math.pi
        local distance = math.random() * 8 * (1 - progress)  -- Reduce distance for smaller spread
        local size = 2 * (1 - progress)  -- Smaller particle size
        local x = self.x + math.cos(angle) * distance
        local y = self.y + math.sin(angle) * distance
        love.graphics.circle("fill", x, y, size)  -- Smaller particles trailing behind
    end
    love.graphics.setColor(0.557, 0.722, 0.619, 0.4 * (1 - progress)) -- pastelMint

    love.graphics.circle("fill", self.x, self.y, 4 * (1 - progress))  -- Smaller core circle
end


end 




-- Flame circle that orbits then explodes
if type == "flame_circle" then
  return {
    type     = "flame_circle",
    x        = x, y = y,
    timer    = 0,
    duration = duration or 5,
    damage   = damagePerMeteor,
    radius   = impactRadius,
    enemies  = enemies or {},
    damageNumbers = damageNumbers or {},
    update = function(self, dt)
      self.timer = self.timer + dt
      -- orbit position
      local t = self.timer * 2  -- speed
      self.x = owner.x + math.cos(t) * self.radius
      self.y = owner.y + math.sin(t) * self.radius
      -- ignite on contact
      for _, e in ipairs(self.enemies) do
        local dx,dy = e.x-self.x,e.y-self.y
        if dx*dx+dy*dy <= 16*16 then
          e:applyStatusEffect({name="Ignite",duration=3,damagePerSecond=damagePerMeteor*0.2})
          table.insert(effects, Effects.new("ignite",e.x,e.y,nil,nil,owner,e))
        end
      end
      if self.timer >= self.duration then
        -- explode outward
        for _, e in ipairs(self.enemies) do
          local dx,dy = e.x-owner.x,e.y-owner.y
          local dist = math.sqrt(dx*dx+dy*dy)
          if dist>0 then
            local tx = owner.x + dx/dist * 300
            local ty = owner.y + dy/dist * 300
            local proj = Effects.new("flame_wave", owner.x, owner.y, tx, ty)
            proj.damage = self.damage
            proj.enemies = self.enemies
            proj.effects = effects
            table.insert(effects, proj)
          end
        end
        self.isDead = true
      end
    end,
    draw = function(self) end
  }
end

-- Jolt‐chain trail
if type == "jolt_chain" then
  return {
    type     = "jolt_chain",
    x        = x, y = y,
    targetX  = targetX, targetY = targetY,
    timer    = 0,
    duration = 0.3,
    update = function(self, dt)
      self.timer = self.timer + dt
      if self.timer>=self.duration then self.isDead=true end
    end,
    draw = function(self)
      love.graphics.setColor(1,1,0,1-self.timer/self.duration)
      love.graphics.setLineWidth(2)
      love.graphics.line(self.x,self.y,self.targetX,self.targetY)
      love.graphics.setColor(1,1,1,1)
    end
  }
end


return Effects