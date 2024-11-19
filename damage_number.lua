-- damage_number.lua

local DamageNumber = {}
DamageNumber.__index = DamageNumber

function DamageNumber.new(x, y, amount, color)
    local self = setmetatable({}, DamageNumber)
    self.x = x
    self.y = y
    self.amount = amount or 0
    self.alpha = 1
    self.dy = -50  -- Floating upwards
    self.color = color or {0, 0, 1}  -- Default to yellow if no color provided

   
    return self
end

function DamageNumber:update(dt)
    self.y = self.y + self.dy * dt
    self.alpha = math.max(self.alpha - dt, 0)
    self.scale = self.scale or 1
    self.scale = self.scale + dt * 0.5  -- Scale up over time
    if self.alpha <= 0 then
        self.isDead = true
    end
end

function DamageNumber:draw()
    local amountStr = tostring(self.amount)
    if self.alpha > 0 then
        love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.alpha)
        love.graphics.printf(
            amountStr,
            self.x,
            self.y,
            100,  -- Width for centering
            "center",
            0,
            self.scale,
            self.scale
        )
    end
end


return DamageNumber
