-- ui.lua 

local UI = {}
UI.__index = UI
local Overworld = require("overworld")
local StatsSystem = require("stats_system")
---------------------------------------------------------------------------
-- CandyObject Definition
---------------------------------------------------------------------------
local CandyObject = {}
CandyObject.__index = CandyObject

local candyFilenames = {
    "assets/candy.png",
    "assets/candy1.png",
    "assets/candy2.png",
    "assets/candy3.png",
    "assets/candy4.png",
    "assets/candy5.png",
    "assets/candy6.png",
    "assets/candy7.png",
    "assets/candy8.png",
    "assets/candy9.png",
    "assets/candy10.png",
    "assets/candy11.png"
}

local candyImages = {}

local function loadCandyImages()
    if #candyImages == 0 then
        for i, filename in ipairs(candyFilenames) do
            local img = love.graphics.newImage(filename)
            img:setFilter("nearest", "nearest")
            table.insert(candyImages, img)
        end
    end
end

-- CandyObject.new(spawnMode): 
--    spawnMode == "explosion" => from center, outward velocities
--    else => from top/side
function CandyObject.new(spawnMode)
    loadCandyImages()

    local self = setmetatable({}, CandyObject)
    self.image = candyImages[math.random(#candyImages)]
    self.width = self.image:getWidth()
    self.height = self.image:getHeight()
    self.scale = 3  -- 3× bigger candy

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    if spawnMode == "explosion" then
        -- Center explosion
        self.x = screenW / 2
        self.y = screenH / 2

        local angle = math.random() * 2 * math.pi
        local speed = math.random(160, 400)  -- 200% faster range
        self.vx = math.cos(angle) * speed
        self.vy = math.sin(angle) * speed
    else
        -- Normal top/side spawn
        local mode = math.random(1, 3)
        if mode == 1 then
            self.x = math.random(0, screenW)
            self.y = -self.height * self.scale - math.random(10, 50)
        elseif mode == 2 then
            self.x = -self.width * self.scale - math.random(10, 50)
            self.y = math.random(0, screenH)
        else
            self.x = screenW + math.random(10, 50)
            self.y = math.random(0, screenH)
        end

        self.vx = math.random(-80, 80)
        self.vy = math.random(20, 100)
        if math.random() < 0.3 then
            self.vy = -math.random(20, 100) 
        end
    end

    self.angle = math.random() * 2 * math.pi
    self.spin = (math.random() - 0.5) * 2

    self.lifetime = 6 + math.random() * 4
    self.creationTime = love.timer.getTime()

    return self
end

function CandyObject:getElapsed()
    return love.timer.getTime() - self.creationTime
end

function CandyObject:isDead()
    local e = self:getElapsed()
    if e > self.lifetime then
        return true
    end

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    if self.x < -self.width*self.scale*2 
       or self.x > screenW + self.width*self.scale*2
       or self.y < -self.height*self.scale*2 
       or self.y > screenH + self.height*self.scale*2
    then
        return true
    end

    return false
end

-- We simulate ~60FPS with dt=0.016 for candy movement
function CandyObject:update()
    local dt = 0.016
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    self.angle = self.angle + self.spin * dt
end

function CandyObject:draw()
    local e = self:getElapsed()
    local alpha = 1.0
    local fadeTime = 1.0
    if e >= (self.lifetime - fadeTime) then
        alpha = (self.lifetime - e) / fadeTime
    end

    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(
        self.image,
        self.x, self.y,
        self.angle,
        self.scale, self.scale,
        self.width / 2,
        self.height / 2
    )
end

---------------------------------------------------------------------------
-- UI Class
---------------------------------------------------------------------------
function UI.new(player, experience, gameState)
    local self = setmetatable({}, UI)
    self.player = player
    self.experience = experience
    self.gameState = gameState  -- Correctly assign the passed gameState

    self.isScoreVisible = false 
    self.scoreData = {}

    self.upgradeOptionsVisible = false
    self.upgradeOptions = {}
    self.onUpgradeSelected = nil
    self.elapsedTime = 0

    -- Fonts
    self.fonts = {}
    local success, err = pcall(function()
        self.fonts.title = love.graphics.newFont("fonts/gothic.ttf", 36)
        self.fonts.subtitle = love.graphics.newFont("fonts/gothic.ttf", 18)
        self.fonts.timer = love.graphics.newFont("fonts/gothic.ttf", 24)
    end)
    if not success then
        local defaultFont = love.graphics.getFont()
        self.fonts.title = defaultFont
        self.fonts.subtitle = defaultFont
        self.fonts.timer = defaultFont
    end

    -- Colors
    self.colors = {
        darkRedBrown     = {86/255, 33/255, 42/255, 1},
        deepPurple       = {67/255, 33/255, 66/255, 1},
        grayishPurple    = {95/255, 87/255, 94/255, 1},
        mutedTeal        = {77/255, 102/255, 96/255, 1},
        rustRed          = {173/255, 64/255, 48/255, 1},
        mutedBrick       = {144/255, 75/255, 65/255, 1},
        darkRose         = {155/255, 76/255, 99/255, 1},
        mutedOliveGreen  = {149/255, 182/255, 102/255, 1},
        peachyOrange     = {231/255, 155/255, 124/255, 1},
        warmGray         = {166/255, 153/255, 152/255, 1},
        paleYellow       = {246/255, 242/255, 195/255, 1},
        darkTeal         = {47/255, 61/255, 58/255, 1},
        orangeGold       = {239/255, 158/255, 78/255, 1},
        pastelMint       = {142/255, 184/255, 158/255, 1},
        smokyBlue        = {70/255, 85/255, 95/255, 1},
        burntSienna      = {233/255, 116/255, 81/255, 1},
        sageGreen        = {148/255, 163/255, 126/255, 1},
        dustyLavender    = {174/255, 160/255, 189/255, 1},
        mustardYellow    = {218/255, 165/255, 32/255, 1},
        terraCotta       = {226/255, 114/255, 91/255, 1},
        charcoalGray     = {54/255, 69/255, 79/255, 1},
        blushPink        = {222/255, 173/255, 190/255, 1},
        forestGreen      = {34/255, 85/255, 34/255, 1},
        midnightBlue     = {25/255, 25/255, 112/255, 1}
    }

    -- TWO ARRAYS for candy:
    self.fallingCandies = {}     -- Normal candies behind popup
    self.explosionCandies = {}   -- Explosion candies on top

    self.candyEffectActive = false
    self.didExplosion = false

    -- Potion images
    self.potionImages = {}
    self.potionImages[0] = love.graphics.newImage("assets/potion.png")
    for i = 1, 10 do
        self.potionImages[i] = love.graphics.newImage("assets/potion" .. i .. ".png")
    end
    
    -- Load new health and dash images
    self.healthImages = {
        love.graphics.newImage("assets/healthbar0.png"),
        love.graphics.newImage("assets/healthbar20.png"),
        love.graphics.newImage("assets/healthbar40.png"),
        love.graphics.newImage("assets/healthbar60.png"),
        love.graphics.newImage("assets/healthbar80.png"),
        love.graphics.newImage("assets/healthbar100.png")
    }
    for i, img in ipairs(self.healthImages) do
        img:setFilter("nearest", "nearest")
    end

    self.dashImages = {
        love.graphics.newImage("assets/dash0.png"),
        love.graphics.newImage("assets/dash20.png"),
        love.graphics.newImage("assets/dash40.png"),
        love.graphics.newImage("assets/dash60.png"),
        love.graphics.newImage("assets/dash80.png"),
        love.graphics.newImage("assets/dash100.png")
    }
    for i, img in ipairs(self.dashImages) do
        img:setFilter("nearest", "nearest")
    end
    
    -- Load link UI asset for link background element.
    self.linkUIImage = love.graphics.newImage("assets/linkui.png")
    self.linkUIImage:setFilter("nearest", "nearest")

    -- <<< ADD THIS BLOCK TO PRELOAD RESOLVED BACKGROUNDS >>>
    self.linkUIResolvedImages = {
        [0] = self.linkUIImage, -- Default for 0 available reels
        [1] = love.graphics.newImage("assets/linkui1.png"),
        [2] = love.graphics.newImage("assets/linkui2.png"),
        [3] = love.graphics.newImage("assets/linkui3.png")
    }
    for _, img in pairs(self.linkUIResolvedImages) do
        if img then img:setFilter("nearest", "nearest") end
    end
    -- <<< END ADDED BLOCK >>>

    self.linkUIX = 0      -- horizontal adjustment (change as needed)
    self.linkUIY = 0      -- vertical adjustment (change as needed)
    self.linkUIScale = 4  -- scale adjustment (change as needed)

    self.linkIconOffsetX = 50  -- horizontal offset for link icons (adjust as needed)
    self.linkIconOffsetY = 0   -- vertical offset for link icons (adjust as needed)
    self.linkIconIndividualOffsets = {
  { x = 4,  y = 27 },  -- slot 1: buff reel
  { x = 4,  y = 27 },  -- slot 2
  { x = 2,  y = 27 },  -- slot 3
  { x = 3,  y = 27 },  -- slot 4
  { x = 4,  y = 27 }   -- slot 5
}

    
    -- Load spin animation for link UI (slot machine reel)
    -- Load different reel animations based on player level:
    self.linkUISpinlvl1 = love.graphics.newImage("assets/linkuispinlvl1.png")
    self.linkUISpinlvl1:setFilter("nearest", "nearest")
    self.linkUISpinlvl2 = love.graphics.newImage("assets/linkuispinlvl2.png")
    self.linkUISpinlvl2:setFilter("nearest", "nearest")
    self.linkUISpinlvl3 = love.graphics.newImage("assets/linkuispinlvl3.png")
    self.linkUISpinlvl3:setFilter("nearest", "nearest")
    self.linkUISpinlvl5 = love.graphics.newImage("assets/linkuispin.png")  -- level 5 reel sprite
    self.linkUISpinlvl5:setFilter("nearest", "nearest")
    -- Default reel image (will be selected based on player level)
    self.linkUISpin = self.linkUISpinlvl1
    self.linkUISpinScale = 4  -- adjust as needed
    self.linkSpinTimer = 0
    self.linkUISpinQuads = {}
    for i = 1, 5 do
        self.linkUISpinQuads[i] = love.graphics.newQuad((i-1)*96, 0, 96, 32, self.linkUISpin:getDimensions())
    end

    self.buffIcons = {
        Fury    = love.graphics.newImage("assets/fury.png"),
        Haste   = love.graphics.newImage("assets/haste.png"),
        Regen   = love.graphics.newImage("assets/regen.png"),
        Poison  = love.graphics.newImage("assets/poisoned.png"),
        Slow    = love.graphics.newImage("assets/slow.png"),
        Harrowing = love.graphics.newImage("assets/harrowing.png"),
        Magnetic = love.graphics.newImage("assets/experiencegem.png"),
        Undeath   = love.graphics.newImage("assets/undeath_buff.png"),
        Clovis    = love.graphics.newImage("assets/clovis.png"),
        Ignite    = love.graphics.newImage("assets/ignite.png"),
    }
    for _, icon in pairs(self.buffIcons) do
        icon:setFilter("nearest","nearest")
    end

    return self
end


function UI:updateAvailableReels()
  local level = self.player.experience.level or 1
  if level < 2 then
    self.player.availableAbilityLinks = 0
  elseif level < 5 then
    self.player.availableAbilityLinks = 1
  elseif level < 8 then
    self.player.availableAbilityLinks = 2
  else
    self.player.availableAbilityLinks = 3
  end

  -- Set the spinning reel image based on player level.
  if level >= 8 then
    self.linkUISpin = self.linkUISpinlvl5  -- Level 8+ uses advanced reel.
  elseif level >= 5 then
    self.linkUISpin = self.linkUISpinlvl3  -- Level 5–7 reel.
  elseif level >= 2 then
    self.linkUISpin = self.linkUISpinlvl2  -- Level 2–4 reel.
  else
    self.linkUISpin = self.linkUISpinlvl1  -- Level 1 reel.
  end

  -- Rebuild the quads using the selected spinning image.
  self.linkUISpinQuads = {}
  for i = 1, 5 do
    self.linkUISpinQuads[i] = love.graphics.newQuad((i - 1) * 96, 0, 96, 32, self.linkUISpin:getDimensions())
  end
end



function UI:showScore(finalScore, itemQuality, rewardItem, soulsGained, souls, breakdown, bonus)
    self.isScoreVisible = true
    self.scoreData = {
        finalScore   = finalScore,
        itemQuality  = itemQuality,
        rewardItem   = rewardItem,
        soulsGained  = soulsGained,
        breakdown    = breakdown  -- store the entire breakdown
    }
    self.souls = souls
    self.bonusSouls = bonus  -- store the bonus souls
end

function UI:drawScoreScreen()
    if not self.isScoreVisible then return end

    local screenWidth  = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local centerX      = screenWidth / 2

    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    local breakdown    = self.scoreData.breakdown or {}
    local timeScore    = math.ceil(breakdown.timePoints or 0)
    local expScore     = math.ceil(breakdown.expPoints or 0)
    local totalScore   = math.ceil(breakdown.baseFinalScore or 0)
    local baseSouls    = breakdown.baseSouls or 0
    local bonusSouls   = self.bonusSouls or 0
    local totalSouls   = baseSouls + bonusSouls

    local startY       = 50
    local lineSpacing  = 40
    local yPos         = startY

    local titleFont    = love.graphics.newFont("fonts/gothic.ttf", 40)
    local subtitleFont = love.graphics.newFont("fonts/gothic.ttf", 32)
    local textFont     = love.graphics.newFont("fonts/gothic.ttf", 28)

    local function flashColor(r1, g1, b1, r2, g2, b2, freq)
        local t = love.timer.getTime()
        local alpha = math.abs(math.sin(t * freq))
        return {
            r1 + (r2 - r1) * alpha,
            g1 + (g2 - g1) * alpha,
            b1 + (b2 - b1) * alpha,
            1
        }
    end

    local phase = math.floor((love.timer.getTime() * 4) % 3)
    local resultsColor
    if phase == 0 then resultsColor = {1, 0, 0, 1}
    elseif phase == 1 then resultsColor = {0, 1, 0, 1}
    else resultsColor = {0, 0, 1, 1} end
    love.graphics.setFont(titleFont)
    love.graphics.setColor(resultsColor)
    love.graphics.printf("RESULTS", 0, yPos, screenWidth, "center")
    yPos = yPos + lineSpacing

    love.graphics.setFont(subtitleFont)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("---------------------------", 0, yPos, screenWidth, "center")
    yPos = yPos + lineSpacing

    love.graphics.setFont(subtitleFont)
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.printf("TIME: " .. timeScore, 0, yPos, screenWidth, "center")
    yPos = yPos + lineSpacing

    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.printf("EXPERIENCE: " .. expScore, 0, yPos, screenWidth, "center")
    yPos = yPos + lineSpacing

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("---------------------------", 0, yPos, screenWidth, "center")
    yPos = yPos + lineSpacing

    local totalColor = flashColor(0, 0, 1, 1, 1, 0, 3)
    love.graphics.setColor(totalColor)
    love.graphics.printf("TOTAL SCORE: " .. totalScore, 0, yPos, screenWidth, "center")
    yPos = yPos + lineSpacing

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("SOULS EARNED: " .. baseSouls, 0, yPos, screenWidth, "center")
    yPos = yPos + lineSpacing

    love.graphics.printf("BONUS SOULS: " .. (self.bonusSouls or 0), 0, yPos, screenWidth, "center")
    yPos = yPos + lineSpacing

    local r = math.abs(math.sin(love.timer.getTime() * 2))
    local g = math.abs(math.sin(love.timer.getTime() * 2 + 2))
    local b = math.abs(math.sin(love.timer.getTime() * 2 + 4))
    love.graphics.setColor(r, g, b, 1)
    love.graphics.printf("TOTAL SOULS EARNED: " .. totalSouls, 0, yPos, screenWidth, "center")
    yPos = yPos + lineSpacing

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("---------------------------", 0, yPos, screenWidth, "center")
    yPos = yPos + lineSpacing

    local barWidth  = 300
    local barHeight = 30
    local barX      = (screenWidth - barWidth) / 2
    local barY      = yPos + 20
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)

    local fillRatio = (self.souls.current or 0) / (self.souls.max or 1)
    if fillRatio > 1 then fillRatio = 1 end
    love.graphics.setColor(0.8, 0.8, 0.2, 1)
    love.graphics.rectangle("fill", barX, barY, barWidth * fillRatio, barHeight)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight)

    love.graphics.setFont(love.graphics.newFont("fonts/gothic.ttf", 24))
    love.graphics.printf("Souls Level: " .. (self.souls.level or 1), 0, barY + barHeight + 10, screenWidth, "center")

    local rewardText = ""
    if self.scoreData.itemQuality and self.scoreData.rewardItem then
        rewardText = "Reward: " .. tostring(self.scoreData.rewardItem.name)
    else
        rewardText = "No Reward"
    end
    love.graphics.setFont(textFont)
    love.graphics.printf(rewardText, 0, barY + barHeight + 50, screenWidth, "center")

    local promptAlpha = (math.sin(love.timer.getTime() * 2) + 1) / 2
    love.graphics.setColor(1, 1, 1, promptAlpha)
    love.graphics.setFont(textFont)
    love.graphics.printf("Press Enter to Continue", 0, barY + barHeight + 90, screenWidth, "center")
    love.graphics.setColor(1, 1, 1, 1)
end

---------------------------------------------------------------------------
-- Candy Celebration: Start/Stop
---------------------------------------------------------------------------
function UI:startCandyCelebration()
    self.candyEffectActive = true
    self.didExplosion = false
end

function UI:stopCandyCelebration()
    self.candyEffectActive = false
    self.didExplosion = false
    self.fallingCandies = {}
    self.explosionCandies = {}
end

---------------------------------------------------------------------------
-- Spawn Normal (Falling) Candy
---------------------------------------------------------------------------
function UI:spawnRegularCandy()
    local c = CandyObject.new(nil)  -- top/side
    table.insert(self.fallingCandies, c)
end

function UI:spawnRegularCandies(count)
    for i = 1, count do
        self:spawnRegularCandy()
    end
end

---------------------------------------------------------------------------
-- Spawn Explosion Candy in the Center
---------------------------------------------------------------------------
function UI:spawnCandyExplosionCenter(count)
    for i = 1, count do
        local c = CandyObject.new("explosion")  -- center explosion
        table.insert(self.explosionCandies, c)
    end
end

---------------------------------------------------------------------------
-- Update/Draw Normal Candies (Behind popup)
---------------------------------------------------------------------------
function UI:drawNormalCandiesBehind()
    if self.candyEffectActive then
        if math.random() < 0.33 then
            self:spawnRegularCandies(5)
        end
    end

    for i = #self.fallingCandies, 1, -1 do
        local candy = self.fallingCandies[i]
        candy:update()
        if candy:isDead() then
            table.remove(self.fallingCandies, i)
        else
            candy:draw()
        end
    end
end

---------------------------------------------------------------------------
-- Update/Draw Explosion Candies (On top of popup)
---------------------------------------------------------------------------
function UI:drawExplosionCandiesOnTop()
    if self.candyEffectActive and (not self.didExplosion) then
        self:spawnCandyExplosionCenter(100)  -- Increased from 20 to 100
        self.didExplosion = true
    end

    for i = #self.explosionCandies, 1, -1 do
        local candy = self.explosionCandies[i]
        candy:update()
        if candy:isDead() then
            table.remove(self.explosionCandies, i)
        else
            candy:draw()
        end
    end
end

---------------------------------------------------------------------------
-- LÖVE Callbacks
---------------------------------------------------------------------------
function UI:update(dt)
    self.elapsedTime = self.elapsedTime + dt
    if #self.player.uiLinks == 0 then
         self.linkSpinTimer = self.linkSpinTimer + dt
    else
         self.linkSpinTimer = 0
    end
    if mistParticleSystem then
        mistParticleSystem:update(dt)
    end
    if self.isScoreVisible then
        -- (existing score update code)
    end
end

function UI:draw()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Team HP using new health bar images
    local x = 10
    local y = 10
    local teamHealth = self.player._teamHealth  
    local teamMaxHealth = self.player.teamMaxHealth
    local healthRatio = math.min(math.max(teamHealth / teamMaxHealth, 0), 1)
    local healthIndex = math.floor(healthRatio * 5) + 1
    local healthImage = self.healthImages[healthIndex]
    local healthScale = 4
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(healthImage, x, y, 0, healthScale, healthScale)
    local healthText = math.floor(teamHealth) .. "/" .. math.floor(teamMaxHealth)
    love.graphics.setFont(self.fonts.subtitle)
    local barWidth = healthImage:getWidth() * healthScale
    love.graphics.printf(healthText, x, y + (healthImage:getHeight() * healthScale / 2) - self.fonts.subtitle:getHeight() / 2, barWidth, "center")

    -- EXP Bar
    local expBarWidth = screenW
    local expBarHeight = 25
    local topBarY = screenH - expBarHeight
    love.graphics.setColor(self.colors.darkTeal)
    local expBarX = (screenW - expBarWidth) / 2
    love.graphics.rectangle("fill", expBarX, topBarY, expBarWidth, expBarHeight)
    local expRatio = math.max(self.experience.currentExp / self.experience.expToLevel, 0)
    if expRatio <= 0.25 then
        love.graphics.setColor(self.colors.darkRedBrown)
    elseif expRatio <= 0.5 then
        love.graphics.setColor(self.colors.orangeGold)
    elseif expRatio <= 0.75 then
        love.graphics.setColor(self.colors.mustardYellow)
    else
        love.graphics.setColor(self.colors.forestGreen)
    end
    love.graphics.rectangle("fill", expBarX, topBarY, expBarWidth * expRatio, expBarHeight)
    love.graphics.setColor(self.colors.paleYellow)
    love.graphics.setFont(self.fonts.subtitle)
    local levelText = string.format("Level: %d (%d/%d)",
        self.experience.level,
        math.floor(self.experience.currentExp),
        math.floor(self.experience.expToLevel)
    )
    local expTextY = topBarY + (expBarHeight - self.fonts.subtitle:getHeight()) / 2
    love.graphics.printf(levelText, expBarX, expTextY, expBarWidth, "center")

    -- Timer
    local minutes = math.floor(self.elapsedTime / 60)
    local seconds = math.floor(self.elapsedTime % 60)
    local timerText = string.format("%02d:%02d", minutes, seconds)
    local timerX = screenW - 150
    local timerY = 10
    local timerWidth = 120
    local timerHeight = 30
    love.graphics.setColor(0.676, 0.251, 0.188, 0.9)
    love.graphics.rectangle("fill", timerX, timerY, timerWidth, timerHeight)
    love.graphics.setColor(self.colors.orangeGold)
    love.graphics.rectangle("line", timerX, timerY, timerWidth, timerHeight)
    love.graphics.setColor(self.colors.paleYellow)
    love.graphics.setFont(self.fonts.timer)
    love.graphics.printf(timerText, timerX, timerY + (timerHeight - self.fonts.timer:getHeight()) / 2, timerWidth, "center")

    if self.gameState:getState() == "title" then
        self:drawTitlePrompt()
    end

    if self.player.damageFlashTimer and self.player.damageFlashTimer > 0 then
        love.graphics.setColor(1, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)
        love.graphics.setColor(1, 1, 1)
    end

    if self.isScoreVisible then
        self:drawScoreScreen()
    end

    self:drawBuffIcons(x + 20, y + healthImage:getHeight() + 55)
    self:drawLinkUI()
    self:drawPotionAndDashUI()
    self:drawNormalCandiesBehind()

    if self.upgradeOptionsVisible then
        self:drawUpgradeOptions()
    end

    self:drawExplosionCandiesOnTop()
end

function UI:drawBuffIcons(startX, startY)
    local activeEffects, effectDurations = self:collectActiveEffects()
    local currentX = startX
    local spacing = 2
    local scale = 2

    for i, effectName in ipairs(activeEffects) do
        local icon = self.buffIcons[effectName]
        if icon then
            local iconX = currentX
            local iconY = startY
            local flashAlpha = (math.sin(love.timer.getTime() * 8) + 1) / 2
            love.graphics.setColor(1, 1, 1, flashAlpha)
            love.graphics.draw(icon, iconX, iconY, 0, scale, scale)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(self.fonts.subtitle)
            local timeLeft = effectDurations[effectName] or 0
            if timeLeft > 0 then
                local sec = math.ceil(timeLeft)
                local textX = iconX
                local textY = iconY + (icon:getHeight() * scale) + 2
                local textW = icon:getWidth() * scale
                love.graphics.printf(sec, textX, textY, textW, "center")
            end
            currentX = currentX + (icon:getWidth() * scale) + spacing
        end
    end

    if self.player.hasHarrowingInstincts and self.player.harrowingInstinctStacks > 0 then
        local icon = self.buffIcons["Harrowing"]
        if icon then
            local harrowingScale = scale
            local harrowingSpacing = spacing
            local harrowingX = currentX
            local harrowingY = startY
            local flashAlpha = (math.sin(love.timer.getTime() * 8) + 1) / 2
            love.graphics.setColor(1, 1, 1, flashAlpha)
            love.graphics.draw(icon, harrowingX, harrowingY, 0, harrowingScale, harrowingScale)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(self.fonts.subtitle)
            local stackStr = tostring(self.player.harrowingInstinctStacks)
            local stackTextX = harrowingX
            local stackTextY = harrowingY + (icon:getHeight() * harrowingScale) + 2
            local stackTextW = icon:getWidth() * harrowingScale
            love.graphics.printf(stackStr, stackTextX, stackTextY, stackTextW, "center")
            currentX = currentX + (icon:getWidth() * harrowingScale) + harrowingSpacing
        end
    end

    love.graphics.setColor(1,1,1,1)
end

---------------------------------------------------------------------------
-- Draw Upgrade Options
---------------------------------------------------------------------------
function UI:drawUpgradeOptions()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local popupWidth = 800
    local popupHeight = 600
    local boxWidth = 700
    local boxHeight = 100
    local popupX = (screenW - popupWidth) / 2
    local popupY = (screenH - popupHeight) / 2

    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", popupX, popupY, popupWidth, popupHeight, 15, 15)

    love.graphics.setScissor(popupX, popupY, popupWidth, popupHeight)
    if mistParticleSystem then
        mistParticleSystem:setPosition(popupX + popupWidth / 2, popupY + popupHeight / 2)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.draw(mistParticleSystem, 0, 0)
    end
    love.graphics.setScissor()

    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.setFont(self.fonts.title)
    local titleText = (self.upgradeOptionsType == "bonus"
        and "CHOOSE A BONUS UPGRADE:"
        or "Choose an Upgrade:")
    love.graphics.printf(titleText, popupX, popupY + 20, popupWidth, "center")

    local mouseX, mouseY = love.mouse.getPosition()
    local optionCount = #self.upgradeOptions
    if optionCount == 0 then return end

    local topPadding = 80
    local bottomPadding = 80
    local availableHeight = popupHeight - topPadding - bottomPadding
    local optionSpacing = availableHeight / (optionCount + 1)

    love.graphics.setFont(self.fonts.subtitle)

    for i, option in ipairs(self.upgradeOptions) do
        if option.class == "Grimreaper" then
            love.graphics.setColor(self.colors.deepPurple)
        elseif option.class == "Emberfiend" then
            love.graphics.setColor(self.colors.darkRose)
        elseif option.class == "Stormlich" then
            love.graphics.setColor(self.colors.orangeGold)
        else
            love.graphics.setColor(1, 1, 1)
        end

        local boxX = popupX + (popupWidth - boxWidth) / 2
        local boxY = popupY + topPadding + i * optionSpacing - boxHeight / 2

        local borderColor
        if option.milestone == 1 then
            borderColor = {1, 1, 1}
        elseif option.milestone == 5 then
            borderColor = {0, 1, 0}
        elseif option.milestone == 8 then
            borderColor = {0.5, 0, 0.5}
        elseif option.milestone == 10 then
            borderColor = {1, 0, 1}
        else
            borderColor = {1, 1, 1}
        end

        if mouseX >= boxX and mouseX <= boxX + boxWidth
           and mouseY >= boxY and mouseY <= boxY + boxHeight then
            love.graphics.setColor(1, 0, 0)
        else
            love.graphics.setColor(borderColor)
        end
        love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 10, 10)

        love.graphics.setColor(1, 1, 1)
        love.graphics.print(option.name, boxX + 10, boxY + 10)

        if option.class == "Emberfiend" then
            love.graphics.setColor(1, 0, 0)
        elseif option.class == "Stormlich" then
            love.graphics.setColor(1, 0.780, 0)
        elseif option.class == "Grimreaper" then
            love.graphics.setColor(0.678, 0.047, 0.910)
        else
            love.graphics.setColor(1, 1, 1)
        end
        local classText = "(" .. tostring(option.class) .. ")"
        love.graphics.print(classText,
            boxX + 10 + self.fonts.subtitle:getWidth(option.name) + 5,
            boxY + 10)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(option.description, boxX + 10, boxY + 40, boxWidth - 20, "left")
    end
end

function UI:mousepressed(x, y, button)
    if self.upgradeOptionsVisible and button == 1 then
        local screenW = love.graphics.getWidth()
        local screenH = love.graphics.getHeight()
        local popupWidth = 800
        local popupHeight = 600

        local boxWidth = 700
        local boxHeight = 100

        local popupX = (screenW - popupWidth) / 2
        local popupY = (screenH - popupHeight) / 2

        local optionCount = #self.upgradeOptions
        if optionCount == 0 then return end

        local topPadding = 80
        local bottomPadding = 80
        local availableHeight = popupHeight - topPadding - bottomPadding
        local optionSpacing = availableHeight / (optionCount + 1)

        for i, option in ipairs(self.upgradeOptions) do
            local boxX = popupX + (popupWidth - boxWidth) / 2
            local boxY = popupY + topPadding + i * optionSpacing - boxHeight / 2

            if x >= boxX and x <= boxX + boxWidth
               and y >= boxY and y <= boxY + boxHeight
            then
                self.upgradeOptionsVisible = false
                if self.onUpgradeSelected then
                    self.onUpgradeSelected(option)
                end
                break
            end
        end
    end
end

---------------------------------------------------------------------------
-- Title Prompt
---------------------------------------------------------------------------
function UI:drawTitlePrompt()
    local time = love.timer.getTime()
    local alpha = (math.sin(time * 2) + 1) / 2
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.setFont(self.fonts.subtitle)
    love.graphics.printf("Press Any Key to Continue", 0, 550, 800, "center")
end

---------------------------------------------------------------------------
-- showUpgradeOptions
---------------------------------------------------------------------------
function UI:showUpgradeOptions(options, callback, upgradeType)
    self.upgradeOptionsVisible = true
    self.upgradeOptions = options
    self.upgradeOptionsType = upgradeType or "main"
    self.onUpgradeSelected = callback
end

---------------------------------------------------------------------------
-- Potion & Dash UI
---------------------------------------------------------------------------
function UI:drawPotionAndDashUI()
    local margin = 20
    local flaskWidth = 32
    local flaskHeight = 32
    local offsetFromBottom = 100
    local bottomY = love.graphics.getHeight() - margin - flaskHeight - offsetFromBottom - 20

    -- Draw dash at the left (dash bar)
    local dashOffsetX = 0
    local dashOffsetY = -50
    local dashX = margin + dashOffsetX
    local dashY = bottomY + dashOffsetY
    local dashCooldown = self.player.dashCooldown
    local maxDashCooldown = self.player.maxDashCooldown
    local dashRatio = 1 - (dashCooldown / maxDashCooldown)
    local dashIndex = math.floor(dashRatio * 5) + 1
    if dashIndex > 6 then dashIndex = 6 end
    local dashImage = self.dashImages[dashIndex]
    local dashScale = math.min(flaskWidth / dashImage:getWidth(), flaskHeight / dashImage:getHeight()) * 5
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(dashImage, dashX, dashY, 0, dashScale, dashScale)
    love.graphics.setFont(self.fonts.subtitle)
    love.graphics.setColor(1, 1, 1)
    local dashLabelOffset = -10
    local dashLabelY = dashY + (dashImage:getHeight() * dashScale) + dashLabelOffset
    love.graphics.printf("SPACE", dashX, dashLabelY, flaskWidth * 2, "right")

    local potionX = dashX + (dashImage:getWidth() * dashScale) + 20
    local potionY = bottomY + 30
    local potionCharge = self.player.potionCharge
    local chargeLevel = math.floor(potionCharge * 10 + 0.5)
    if chargeLevel > 10 then chargeLevel = 10 end
    local potionImage = self.potionImages[chargeLevel] or self.potionImages[0]
    local potionScaleX = 2 * (flaskWidth / potionImage:getWidth())
    local potionScaleY = 2 * (flaskHeight / potionImage:getHeight())
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(potionImage, potionX, potionY, 0, potionScaleX, potionScaleY)
    love.graphics.setFont(self.fonts.subtitle)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("E", potionX, potionY + (potionImage:getHeight() * potionScaleY) + 5, flaskWidth * 2, "center")
end

---------------------------------------------------------------------------
-- Keypressed Handler
---------------------------------------------------------------------------
function UI:keypressed(key)
    if self.isScoreVisible then
        if key == "return" or key == "space" then
            self.isScoreVisible = false
            self.gameState:setState("overworld")
            Overworld.init()
        end
    end
end

function UI:collectActiveEffects()
    local active = {}
    local effectDurations = {}

    for effectName, data in pairs(self.player.statusEffects) do
        local timeLeft = (data.duration or 0) - (data.timer or 0)
        if timeLeft > 0 then
            active[effectName] = true
            effectDurations[effectName] = math.max(effectDurations[effectName] or 0, timeLeft)
        end
    end

    for _, char in pairs(self.player.characters) do
        for effectName, data in pairs(char.statusEffects) do
            local timeLeft = (data.duration or 0) - (data.timer or 0)
            if timeLeft > 0 then
                active[effectName] = true
                effectDurations[effectName] = math.max(effectDurations[effectName] or 0, timeLeft)
            end
        end
    end

    local list = {}
    for effectName, _ in pairs(active) do
        table.insert(list, effectName)
    end
    table.sort(list)

    return list, effectDurations
end

function UI:drawLinkUI()
    local screenW = love.graphics.getWidth()
    local spacing = 1       -- spacing between icons
    local iconScale = 4     -- scale factor for link icons
    local sampleImg = love.graphics.newImage("assets/greylink.png")
    sampleImg:setFilter("nearest", "nearest")
    local iconWidth = sampleImg:getWidth() * iconScale
    local iconHeight = sampleImg:getHeight() * iconScale

    local fixedMaxLinks = 5
    local totalWidth = fixedMaxLinks * (iconWidth + spacing) - spacing
    local startX = (screenW - totalWidth) / 2
    local y = 20  -- fixed top margin

    if #self.player.uiLinks == 0 then
        -- No links resolved yet; draw the spinning reel animation.
        local frame = (math.floor(self.linkSpinTimer / 0.05) % 5) + 1
        local uiX = startX + self.linkUIX - 10
        local uiY = y + self.linkUIY - 5
        love.graphics.draw(self.linkUISpin, self.linkUISpinQuads[frame], uiX, uiY, 0, self.linkUISpinScale, self.linkUISpinScale)
    else
        -- Choose the resolved background image based on available ability reels.
        local available = self.player.availableAbilityLinks or 0
        local bgImage = self.linkUIResolvedImages[available] or self.linkUIResolvedImages[0] -- Use preloaded image

        local uiX = startX + self.linkUIX - 10
        local uiY = y + self.linkUIY - 5
        love.graphics.draw(bgImage, uiX, uiY, 0, self.linkUIScale, self.linkUIScale)
        
        -- Now draw the resolved link icons in order.
        local iconsStartX = startX + self.linkIconOffsetX
        local iconsY = y + self.linkIconOffsetY
        for i, link in ipairs(self.player.uiLinks) do
            local offset = self.linkIconIndividualOffsets[i] or { x = 0, y = 0 }
            link.x = iconsStartX + (i - 1) * (iconWidth + spacing) + iconWidth/2 + offset.x
            link.y = iconsY + iconHeight/2 + offset.y
            link:draw(iconScale)
        end
    end
end


function UI:drawEnemyLinkUI()
    local screenW = love.graphics.getWidth()
    local maxLinks = 5
    local spacing = 10
    local iconScale = 4
    local sampleImg = love.graphics.newImage("assets/greylink.png")
    sampleImg:setFilter("nearest", "nearest")
    local iconWidth = sampleImg:getWidth() * iconScale
    local iconHeight = sampleImg:getHeight() * iconScale
    local fixedMaxLinks = 5
    local totalWidth = fixedMaxLinks * (iconWidth + spacing) - spacing
    local startX = (screenW - totalWidth) / 2
    local y = 20 + iconHeight + 20
    for i, link in ipairs(self.player.negativeLinks) do
        link.x = startX + (i - 1) * (iconWidth + spacing) + iconWidth/2
        link.y = y + iconHeight/2
        link:draw(iconScale)
    end
end

return UI
