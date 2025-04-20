-- experience_gem.lua

local ExperienceGem = {}
ExperienceGem.__index = ExperienceGem

-- Load gem images once in this file
local images = {}
local imagePaths = {
    "assets/experiencegem.png",
    "assets/candy2.png",
    "assets/candy3.png",
    "assets/candy4.png",
    "assets/candy5.png",
    "assets/candy6.png",
    "assets/candy7.png",
    "assets/candy8.png",
    "assets/candy9.png"
}
for _, path in ipairs(imagePaths) do
    local img = love.graphics.newImage(path)
    img:setFilter("nearest", "nearest")
    table.insert(images, img)
end

function ExperienceGem.new(x, y, amount)
    local self = setmetatable({}, ExperienceGem)
    self.x = x
    self.y = y
    self.baseY = y  -- Original Y position
    self.amount = amount
    self.radius = 10  -- Collision radius
    self.toRemove = false
    self.floatTimer = 0  -- Timer for oscillation

    -- Randomly select one of the loaded images
    self.image = images[math.random(#images)]
    return self
end

function ExperienceGem:update(dt, characters)
    -- Oscillation for a floating effect
    self.floatTimer = self.floatTimer + dt
    local offsetY = math.sin(self.floatTimer * 2) * 2.5

    -- Move gem toward the nearest character (if within pull range)
    local closestChar = nil
    local minDistSq = nil
    for _, char in pairs(characters) do
        if not player:isDefeated() then
            local dx = self.x - char.x
            local dy = self.y - char.y
            local pullRange = char.pullRange + (player.magneticBonus or 0)
            local pullRangeSq = pullRange * pullRange
            local distSq = dx * dx + dy * dy
            if distSq < pullRangeSq then
                if not minDistSq or distSq < minDistSq then
                    closestChar = char
                    minDistSq = distSq
                end
            end
        end
    end

    if closestChar then
        local speed = 200  -- Speed toward the character
        local dx = closestChar.x - self.x
        local dy = closestChar.y - self.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist > 0 then
            self.x = self.x + (dx / dist) * speed * dt
            self.y = self.y + (dy / dist) * speed * dt
        end
    end

    self.drawY = self.y + offsetY
end

function ExperienceGem:draw()
    if self.image then
        local scaleFactor = 1.5  -- Scale the gem image
        love.graphics.setColor(1, 1, 1, 1)  -- Full opacity
        love.graphics.draw(
            self.image,
            self.x,
            self.drawY,    -- Use the oscillated position
            0,             -- No rotation
            scaleFactor,   -- Scale X
            scaleFactor,   -- Scale Y
            self.image:getWidth() / 2,  -- X offset (center)
            self.image:getHeight() / 2  -- Y offset (center)
        )
    else
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.circle("fill", self.x, self.y, self.radius)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return ExperienceGem
