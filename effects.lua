-- effects.lua

local Effects = {}
Effects.__index = Effects
local shieldImage = love.graphics.newImage("assets/shield_throw.png")


function Effects.new(type, x, y, targetX, targetY, ownerType, attachedTo)
    local self = setmetatable({}, Effects)
    self.type = type
    self.x = x
    self.y = y
    self.targetX = targetX or x
    self.targetY = targetY or y
    self.ownerType = ownerType or "generic"
    self.attachedTo = attachedTo or nil -- Reference to the enemy if attached
    self.targetAttachedTo = targetAttachedTo or nil  -- Reference to the player
    self.timer = 0
    self.isDead = false

    -- Set duration based on effect type
    local durations = {
        explosion = 0.3,  -- Reduced duration for a faster explosion
        ignite = 5.0,     -- Ignite lasts the full duration of the status effect
        fire = 0.5,
        shield_throw = 0.5,
        frost_explosion = 0.5,
        summon_wolf = 0.5,
        teleport = 0.5,
        life_drain = 6.0,
        summon = 0.5,
        shadow_cloak = 0.5,
        hit_spark = 0.2,
        arrow_trail = 0.3,
        fire_flame = 0.5,      -- Duration for fire_flame effect
        spear_glow = 0.3,      -- Duration for spear_glow effect
        chain_lightning = 0.5,
        poison = 0.5,  -- Duration of the poison visual effect upon proc
        slash = 0.2, -- Short duration for quick slash effect
        arcane_trail = 0.4, -- Quick duration for trail particles
    }
    self.duration = durations[self.type] or 1

    return self
end

function Effects:update(dt)
    self.timer = self.timer + dt
    if self.timer >= self.duration then
        self.isDead = true
    end

    -- Update positions to stay attached to both the Vampire Boss and player
    if self.attachedTo then
        self.x = self.attachedTo.x
        self.y = self.attachedTo.y
    end

    if self.targetAttachedTo then
        self.targetX = self.targetAttachedTo.x
        self.targetY = self.targetAttachedTo.y
    end
end


function Effects:draw()
    if self.isDead then return end

    if self.type == "snow_explosion" then
        local progress = math.min(self.timer / self.duration, 1)
        local numParticles = 10
        love.graphics.setColor(0.8, 0.9, 1, 1 - progress)  -- Light blue/white color, fading out
        for i = 1, numParticles do
            local angle = (i / numParticles) * (2 * math.pi)
            local distance = 30 + 40 * progress
            local size = 8 * (1 - progress)
            local x = self.x + math.cos(angle) * distance
            local y = self.y + math.sin(angle) * distance
            love.graphics.circle("fill", x, y, size)
        end
        love.graphics.setColor(1, 1, 1, 0.5 * (1 - progress))  -- A fading white core
        love.graphics.circle("fill", self.x, self.y, 15 * (1 - progress))
        
        elseif self.type == "shock" then
    local progress = math.min(self.timer / self.duration, 1)
    local alpha = 1 - progress
    love.graphics.setColor(1, 1, 0.5, alpha)  -- Yellowish color
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


    elseif self.type == "shield_throw" then
    love.graphics.setColor(1, 1, 1)  -- Ensure the sprite is drawn with full color
    love.graphics.draw(shieldImage, self.x, self.y, self.rotation or 0, 1, 1, shieldImage:getWidth() / 2, shieldImage:getHeight() / 2)

    elseif self.type == "ignite" then
        local progress = math.min(self.timer / self.duration, 1)
        local numParticles = 8
        for i = 1, numParticles do
            local angle = math.random() * 2 * math.pi
            local distance = math.random() * 10
            local offsetX = math.cos(angle) * distance
            local offsetY = math.sin(angle) * distance
            local size = 5 + 3 * math.sin(self.timer * 10 + i)
            local alpha = 0.5 + 0.5 * math.sin(self.timer * 5 + i)
            love.graphics.setColor(1, 0.5 + 0.2 * math.random(), 0, alpha)
            love.graphics.circle("fill", self.x + offsetX, self.y + offsetY, size * (1 - progress))
        end
        love.graphics.setColor(1, 0.3, 0, 0.8 * (1 - progress))
        love.graphics.circle("fill", self.x, self.y, 10 * (1 - progress))

    elseif self.type == "slash" then
        local progress = math.min(self.timer / self.duration, 0.1)
        local alpha = 1 - progress
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.setLineWidth(1)
        love.graphics.line(self.x - 20, self.y - 10, self.x + 20, self.y + 10)
        love.graphics.setColor(1, 0, 0, alpha)
        love.graphics.setLineWidth(1)
        love.graphics.line(self.x - 18, self.y - 8, self.x + 18, self.y + 8)

elseif self.type == "wolfbite" then
    -- Increase the progress multiplier to speed up the effect
    local speedMultiplier = 5  -- Adjust this value for faster or slower speed
    local progress = math.min((self.timer / self.duration) * speedMultiplier, 1)
    local alpha = 1 - progress  -- Fade out over time
    love.graphics.setColor(1, 1, 1, alpha)  -- Set color with alpha fade

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






    elseif self.type == "poison" then
        local progress = math.min(self.timer / self.duration, 1)
        love.graphics.setColor(0, 1, 0, 1 - progress)
        love.graphics.circle("fill", self.x, self.y, 15 * progress)

   elseif self.type == "explosion" then
    local rank = self.attachedTo and self.attachedTo.abilities["Explosive Fireballs"].rank or 1
    local maxRadius = 50 + (5 * rank)  -- Match to ability's damage radius
    local progress = math.min(self.timer / self.duration, 1)
    
    -- Outer fiery particles within maxRadius
    local numParticles = 8
    love.graphics.setColor(1, 0.4, 0.1)
    for i = 1, numParticles do
        local angle = (i / numParticles) * (2 * math.pi)
        local distance = (maxRadius * 0.6) + (maxRadius * 0.4) * progress  -- Constrain within maxRadius
        local size = 4 * (1 - progress)      -- Smaller particles
        local x = self.x + math.cos(angle) * distance
        local y = self.y + math.sin(angle) * distance
        love.graphics.circle("fill", x, y, size)
    end

    -- Inner glow within a fraction of maxRadius
    love.graphics.setColor(1, 0.8, 0.2, 1 - progress)  
    love.graphics.circle("fill", self.x, self.y, (maxRadius * 0.2) * (1 - progress))  -- Inner core

    -- Subtle flash for a fiery center
    love.graphics.setColor(1, 0.9, 0.6, 0.4 * (1 - progress))  
    love.graphics.circle("fill", self.x, self.y, (maxRadius * 0.15) * (1 - progress))

    -- Smaller, centered sparks
    for i = 1, 4 do
        local offsetX = math.random(-6, 6) * (1 - progress)
        local offsetY = math.random(-6, 6) * (1 - progress)
        love.graphics.setColor(1, 0.5, 0.2, 0.6 * (1 - progress))
        love.graphics.circle("fill", self.x + offsetX, self.y + offsetY, 2 * (1 - progress))
    end


   
   
    elseif self.type == "frost_explosion" then
        love.graphics.setColor(0.7, 0.9, 1)
        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        love.graphics.rotate(self.rotation or 0)
        love.graphics.polygon("fill", 0, -20, -14, 0, 0, 20)
        love.graphics.polygon("fill", 0, 20, 14, 0, 0, -20)
        love.graphics.pop()

    elseif self.type == "freeze" then
        love.graphics.setColor(0.5, 0.8, 1, 0.7)
        love.graphics.circle("fill", self.x, self.y, 12)

    elseif self.type == "teleport" then
        local progress = math.min(self.timer / self.duration, 1)
        love.graphics.setColor(0.5, 0, 0.5, 1 - progress)
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
    love.graphics.setColor(0.8, 0, 0.8, 1)  -- Solid purple color

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
    love.graphics.setColor(1, 0, 0, 0.7)  -- Red glow
    love.graphics.circle("fill", self.targetX, self.targetY, 8)

    -- Draw a glowing effect at the source end
    love.graphics.setColor(0.8, 0, 0.8, 0.7)  -- Purple glow
    love.graphics.circle("fill", self.x, self.y, 8)

   
   
   elseif self.type == "chain_lightning" then
    love.graphics.setLineWidth(2)

    -- Set the electric colors (gold/yellow with white for more brightness)
    local startColor = {1, 0.85, 0.2}  -- Gold/yellow start color
    local endColor = {1, 1, 0.9}  -- Brighter yellow-white end color
    local segments = 6  -- Same number of segments for the lightning chain
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

        -- Interpolate between the start and end color, including some white
        local r = startColor[1] + progress * (endColor[1] - startColor[1])
        local g = startColor[2] + progress * (endColor[2] - startColor[2])
        local b = startColor[3] + progress * (endColor[3] - startColor[3])

        -- Set color with white mixed in, and slight fade towards the end
        love.graphics.setColor(r, g, b, 1 - progress)
        love.graphics.line(previousX, previousY, nextX, nextY)

        previousX, previousY = nextX, nextY
    end

    -- Add small electric sparks near the start and end points with white
    for i = 1, 3 do
        -- Gold sparks at the start
        love.graphics.setColor(1, 0.85, 0.2, 0.7)
        local sparkX = self.x + math.random(-4, 4)
        local sparkY = self.y + math.random(-4, 4)
        love.graphics.circle("fill", sparkX, sparkY, 2)

        -- White sparks at the end
        love.graphics.setColor(1, 1, 1, 0.9)  -- Bright white for stronger impact
        sparkX = self.targetX + math.random(-4, 4)
        sparkY = self.targetY + math.random(-4, 4)
        love.graphics.circle("fill", sparkX, sparkY, 2)
    end

    -- Highlight start and end points with faint electric glows, adding white
    love.graphics.setColor(1, 0.85, 0.2, 0.4)  -- Faint gold glow at start
    love.graphics.circle("fill", self.x, self.y, 6)

    love.graphics.setColor(1, 1, 1, 0.6)  -- Faint white glow at the end
    love.graphics.circle("fill", self.targetX, self.targetY, 6)




  elseif self.type == "spear_glow" then
    local progress = math.min(self.timer / self.duration, 1)
    
    -- Set the color for the electric glow (gold/yellow)
    love.graphics.setColor(1, 0.85, 0.2, 1 - progress)  -- Gold/yellow color fading out
    
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
    love.graphics.setColor(1, 0.85, 0.2, 0.2 * (1 - progress))  -- Fainter yellow glow
    love.graphics.circle("fill", self.x, self.y, 7 * (1 - progress))  -- Electric aura around spear

elseif self.type == "arrow_trail" then
    local progress = math.min(self.timer / self.duration, 1)
    love.graphics.setColor(0.6, 0.4, 0.2, 1 - progress)  -- Brownish glow, fading out
    love.graphics.circle("fill", self.x, self.y, 2 * (1 - progress))  -- Small particles trailing behind


        
     elseif self.type == "arcane_trail" then
    local progress = math.min(self.timer / self.duration, 1)
    local numParticles = 4  -- Reduce number of particles for a more subtle effect
    love.graphics.setColor(0.6, 0, 1, 1 - progress)  -- Purplish glow, fading out
    for i = 1, numParticles do
        local angle = math.random() * 2 * math.pi
        local distance = math.random() * 8 * (1 - progress)  -- Reduce distance for smaller spread
        local size = 2 * (1 - progress)  -- Smaller particle size
        local x = self.x + math.cos(angle) * distance
        local y = self.y + math.sin(angle) * distance
        love.graphics.circle("fill", x, y, size)  -- Smaller particles trailing behind
    end
    love.graphics.setColor(0.8, 0.5, 1, 0.4 * (1 - progress))  -- Core of the arcane trail, faint
    love.graphics.circle("fill", self.x, self.y, 4 * (1 - progress))  -- Smaller core circle
end


end -- Close the `draw` function



return Effects
