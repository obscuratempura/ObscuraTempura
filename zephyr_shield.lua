-- zephyr_shield.lua
local ZephyrShield = {}
ZephyrShield.__index = ZephyrShield

function ZephyrShield:new(x, y, rotation)
    local shield = {
        x = x,
        y = y,
        rotation = rotation or 0,
        rotationSpeed = 10, -- degrees per second
        -- Removed 'layers' since internal lines are no longer needed
    }

    setmetatable(shield, ZephyrShield)
    return shield
end

function ZephyrShield:update(dt)
    -- Update the rotation angle
    self.rotation = self.rotation + math.rad(self.rotationSpeed) * dt
    -- No layers to update
end

function ZephyrShield:draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)

    -- Draw glow (reduced radius by 50%)
    love.graphics.setColor(0.556, 0.722, 0.620, 0.2)  -- Light blue glow
    love.graphics.circle("fill", 0, 0, 20) -- Changed from 40 to 20

    -- Draw gradient base shield (reduced radii by 50%)
    for i = 1, 5 do
        local radius = 15 + i * 1.5 -- Changed from 30 + i * 3 to 15 + i * 1.5
        local alpha = 0.05 * (6 - i) -- Decreasing opacity
        love.graphics.setColor(0.7, 0.9, 1, alpha)
        love.graphics.circle("fill", 0, 0, radius)
    end

    -- Removed wind layers drawing since they are no longer needed

    love.graphics.pop()
end

return ZephyrShield
