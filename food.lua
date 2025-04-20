-- food.lua

local Food = {}
Food.__index = Food
local Abilities = require("abilities")
local talentSystem = require("talentSystem")


-- Preload the food images (3-frame animations), or you can load them dynamically if you prefer
local foodImages = {
    love.graphics.newImage("assets/food.png"),
    love.graphics.newImage("assets/food2.png"),
    love.graphics.newImage("assets/food3.png")
}

for _, image in ipairs(foodImages) do
    image:setFilter("nearest", "nearest")
end

function Food.new(x, y)
   local foodDropChance = talentSystem.getCurrentFoodDropChance()

    -- Determine whether to spawn food based on the updated chance
    if math.random() > foodDropChance then
        return nil -- Return nil if food doesn't spawn
    end

    local self = setmetatable({}, Food)
    
    -- Randomly pick which food animation to use
    self.foodIndex = math.random(#foodImages)
    self.image = foodImages[self.foodIndex]
    
    self.x = x
    self.y = y
    self.baseY = y
    self.radius = 10
    self.toRemove = false
    self.floatTimer = 0
    self.timer = 20  -- Food disappears after 20 seconds

   self.vx = math.random(-200, 200)  -- Increased horizontal speed
self.vy = math.random(-200, 200)  -- Increased vertical speed

    self.effectApplied = false
    
    return self
end

function Food:update(dt, characters)
      self.timer = self.timer - dt
    if self.timer <= 0 then
        self.toRemove = true
    end

    -- Apply velocity
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    self.vx = self.vx * 0.9
    self.vy = self.vy * 0.9

    -- Floating animation as an offset
    self.floatTimer = self.floatTimer + dt
    local floatOffset = math.sin(self.floatTimer * 2) * 2.5
    self.currentFloatY = floatOffset

    -- Magnet behavior (optional, can be adjusted or removed for testing)
    local closestChar, minDist = nil, 999999
    for _, char in pairs(characters) do
        if not player:isDefeated() then
            local dx = self.x - char.x
            local dy = self.y - char.y
            local distSq = dx*dx + dy*dy
            if distSq < minDist then
                minDist = distSq
                closestChar = char
            end
        end
    end
    
    if closestChar and math.sqrt(minDist) < 60 then
        local speed = 200
        local dx = closestChar.x - self.x
        local dy = closestChar.y - self.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist > 0 then
            self.x = self.x + (dx/dist)*speed*dt
            self.y = self.y + (dy/dist)*speed*dt
        end
    end
end


function Food:draw()
    -- Apply floating offset
    local scaleFactor = 2.0
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(
        self.image,
        self.x,
        self.y + (self.currentFloatY or 0),  -- Apply the floating offset
        0,
        scaleFactor,
        scaleFactor,
        self.image:getWidth()/2,
        self.image:getHeight()/2
    )
end

-- Function to apply a random effect on pickup
function Food:applyRandomEffect(player)
    local effectRoll = math.random(1,4)

    if player.noPoisonFood and effectRoll == 4 then
        effectRoll = math.random(1,3)
    end

    local maxHP = player.maxTeamHealth or 100
    local bonusDuration = player.ritualFeastBonus or 0  -- 0 if not active

    if effectRoll == 1 then
        -- Regen
        addDamageNumber(player.x, player.y - 10, "Regen", {0,1,0})
        Abilities.applyRegen(player, 5 + bonusDuration, 0.25)

    elseif effectRoll == 2 then
        -- Haste
        addDamageNumber(player.x, player.y - 10, "Haste", {1,1,0})
        Abilities.applyHaste(player, 5 + bonusDuration, 30)

    elseif effectRoll == 3 then
        -- Fury
        addDamageNumber(player.x, player.y - 10, "Fury", {1,0,0})
        Abilities.applyFury(player, 5 + bonusDuration, 2)

    elseif effectRoll == 4 then
        -- Poison remains unchanged
        addDamageNumber(player.x, player.y - 10, "Poisoned", {0.5,0,1})
        local totalPoisonDamage = 0.25 * maxHP
        local dps = totalPoisonDamage / 10
        for _, char in pairs(player.characters) do
            player:applyStatusEffect(char, "Poison", 10, dps)
        end
    end
     player:registerFoodConsumption()
end

return Food
