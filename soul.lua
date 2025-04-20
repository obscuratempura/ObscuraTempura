local Soul = {}
Soul.__index = Soul

-- Load the soul image from assets/soul.png
local soulImage = love.graphics.newImage("assets/soul.png")
soulImage:setFilter("nearest", "nearest")

function Soul.new(x, y)
    local self = setmetatable({}, Soul)
    self.x = x
    self.y = y
    self.baseX = x  -- Base position for bobbing
    self.baseY = y
    self.radius = 10  -- Collision radius
    self.toRemove = false
    self.floatTimer = 0
    self.pickupDelay = 0.5  -- New: delay (in seconds) before the soul can be collected
    return self
end

function Soul:update(dt, characters)
    self.floatTimer = self.floatTimer + dt
    if self.pickupDelay > 0 then
        self.pickupDelay = self.pickupDelay - dt
    end

    local t = self.floatTimer * 2  -- Frequency multiplier
    local amplitudeX = 3
    local amplitudeY = 3
    local offsetX = amplitudeX * math.sin(t)
    local offsetY = amplitudeY * math.sin(2 * t)
    self.drawX = self.baseX + offsetX
    self.drawY = self.baseY + offsetY

    -- Magnetic pickup: only move toward player if delay has passed.
    if self.pickupDelay <= 0 then
        local closestChar = nil
        local minDistSq = nil
        for _, char in pairs(characters) do
            if not player:isDefeated() then
                local dx = self.drawX - char.x
                local dy = self.drawY - char.y
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
            local speed = 200  -- Adjust pickup speed if needed
            local dx = closestChar.x - self.drawX
            local dy = closestChar.y - self.drawY
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 0 then
                self.x = self.x + (dx / dist) * speed * dt
                self.y = self.y + (dy / dist) * speed * dt
                self.baseX = self.x  -- Update base positions for smooth bobbing
                self.baseY = self.y
            end
        end
    end
end


function Soul:draw()
    love.graphics.setColor(1, 1, 1, 1)
    local scaleFactor = 1.5  -- Adjust the scale as needed
    love.graphics.draw(
        soulImage,
        self.drawX or self.x,
        self.drawY or self.y,
        0,           -- Rotation
        scaleFactor, -- Scale X
        scaleFactor, -- Scale Y
        soulImage:getWidth() / 2,  -- X offset (center)
        soulImage:getHeight() / 2  -- Y offset (center)
    )
    love.graphics.setColor(1, 1, 1, 1)
end

return Soul
