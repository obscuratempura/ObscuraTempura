-- damage_number.lua

local DamageNumber = {}
DamageNumber.__index = DamageNumber

function DamageNumber.new(x, y, amount, color, isCrit)
    local self = setmetatable({}, DamageNumber)
    
    self.x = x + math.random(-15, 15)
    self.y = y + math.random(-25, -5)

    if type(amount) == "number" then
        self.amount = math.floor((amount or 0) + 0.5)
    else
        self.amount = tostring(amount)
    end

    self.color = color or {166/255, 153/255, 152/255, 1}

       self.alpha = 1
    self.lifetime = 0.8
    self.elapsed = 0
    -- NEW: Random upward velocity using an angle between 60° and 120°
    local angle = math.rad(math.random(60, 120))
    local speed = math.random(50, 80)  -- pixels per second
    self.vx = speed * math.cos(angle)
    self.vy = -speed * math.sin(angle)  -- negative because y increases downward
    self.gravity = 50  -- downward acceleration in pixels/s^2


    -- NEW: scale up if crit
    self.scale = (isCrit and 1.5) or 1  -- 2 = bigger text on crit
 

    return self
end

function DamageNumber:update(dt)
       self.elapsed = self.elapsed + dt
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt + 0.5 * self.gravity * dt * dt
    self.vy = self.vy + self.gravity * dt
    self.alpha = 1 - (self.elapsed / self.lifetime)


    if self.alpha <= 0 then
        self.alpha = 0
        self.toRemove = true
    end
end

-- Keep the camera arguments (cameraX, cameraY, cameraZoom) so everything else works
function DamageNumber:draw(cameraX, cameraY, cameraZoom)
    local screenX = (self.x - cameraX) * cameraZoom
    local screenY = (self.y - cameraY) * cameraZoom

    love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.alpha)
    -- Multiply your existing 1.5 scale by self.scale
    love.graphics.print(
        tostring(self.amount), 
        screenX, 
        screenY, 
        0, 
        1.5 * self.scale, 
        1.5 * self.scale
    )

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return DamageNumber
