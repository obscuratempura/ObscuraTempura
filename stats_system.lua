-- stats_system.lua

local StatsSystem = {}
StatsSystem.__index = StatsSystem
local Overworld = require("overworld")

-- Constructor
function StatsSystem.new()
    local self = setmetatable({}, StatsSystem)
    -- Basic stats
    self.timeSurvived         = 0  -- in seconds
    self.experienceCollected  = 0  -- total experience gems collected
    self.chestSouls           = 0  -- total souls collected from chests
    self.finalScore           = 0  -- final score calculation
    return self
end

-- Reset stats at the start of a run
function StatsSystem:resetStats()
    self.timeSurvived         = 0
    self.experienceCollected  = 0
    self.chestSouls           = 0
    self.finalScore           = 0
end

-- Update survival time each frame
function StatsSystem:updateTime(dt)
    dt = tonumber(dt) or 0
    self.timeSurvived = self.timeSurvived + dt
end

-- Increment experience collected
function StatsSystem:addExperience(amount)
    amount = tonumber(amount) or 0
    self.experienceCollected = self.experienceCollected + amount
end

-- Increment chest souls collected
function StatsSystem:addChestSouls(amount)
    amount = tonumber(amount) or 0
    self.chestSouls = self.chestSouls + amount
    print("addChestSouls: added", amount, "-> chestSouls now", self.chestSouls)
end

-- Calculate final score based on time survived, experience, and chest souls.
function StatsSystem:calculateFinalScore()
    local time = tonumber(self.timeSurvived) or 0
    local exp = tonumber(self.experienceCollected) or 0
    local chest = tonumber(self.chestSouls) or 0

    if time < 30 then
        self.finalScore = nil
        return nil
    end

    self.finalScore = ((time * 10) + (exp * 5) + (chest * 10)) * 0.25
    return self.finalScore
end

-- Print stats for debugging
function StatsSystem:printStats()
    print("----- Player Stats -----")
    print(string.format("Time Survived: %.2f seconds", self.timeSurvived or 0))
    print("Experience Collected:", self.experienceCollected or 0)
    print("Chest Souls Collected:", self.chestSouls or 0)
    print("Final Score:", self.finalScore or 0)
    print("------------------------")
end

-- Determine reward based on final score.
function StatsSystem:determineItemReward()
    if not self.finalScore or self.finalScore < 100 then
        return nil
    elseif self.finalScore >= 12000 then
        return "Legendary"
    elseif self.finalScore >= 8000 then
        return "Epic"
    elseif self.finalScore >= 2000 then
        return "Rare"
    else
        return "Common"
    end
end

function Overworld.addSouls(amount)
    local multiplier = 0.5  -- Reduce souls gained by 50%
    souls.current = souls.current + (amount * multiplier)
    while souls.current >= souls.max do
        souls.current = souls.current - souls.max
        souls.max = souls.max + 50
        souls.level = souls.level + 1
    end
end

-- Returns a breakdown of the score calculations.
function StatsSystem:getCalculationBreakdown()
    local time = tonumber(self.timeSurvived) or 0
    local exp = tonumber(self.experienceCollected) or 0
    local chest = tonumber(self.chestSouls) or 0

    local timePoints = time * 1
    local expPoints = exp * 1
    local basePoints = timePoints + expPoints
    local baseFinalScore = basePoints
    local baseSouls = math.floor(baseFinalScore / 100)
    local bonusSouls = chest
    local totalSouls = baseSouls + bonusSouls

    return {
        timePoints = timePoints,
        expPoints = expPoints,
        basePoints = basePoints,
        baseFinalScore = baseFinalScore,
        baseSouls = baseSouls,
        bonusSouls = bonusSouls,
        totalSouls = totalSouls
    }
end

return StatsSystem
