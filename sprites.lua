-- sprites.lua

local Sprites = {}

local Animation = {}
Animation.__index = Animation

function Animation.new(spriteSheet, frameWidth, frameHeight, numFrames, frameDuration, loop)
    local self = setmetatable({}, Animation)
    self.spriteSheet = spriteSheet
    self.quads = {}
    self.currentFrame = 1
    self.time = 0
    self.frameDuration = frameDuration
    self.numFrames = numFrames
    self.loop = (loop == nil) and true or loop

    local sheetWidth = spriteSheet:getWidth()
    local sheetHeight = spriteSheet:getHeight()

    if sheetWidth < frameWidth * numFrames or sheetHeight < frameHeight then
        error("Sprite sheet dimensions are smaller than expected.")
    end

    for i = 0, numFrames - 1 do
        local x = (i * frameWidth) % sheetWidth
        local y = math.floor((i * frameWidth) / sheetWidth) * frameHeight
        local quad = love.graphics.newQuad(x, y, frameWidth, frameHeight, sheetWidth, sheetHeight)
        table.insert(self.quads, quad)
    end

    return self
end

function Animation:update(dt)
    self.time = self.time + dt
    if self.time >= self.frameDuration then
        self.time = self.time - self.frameDuration
        if self.loop then
            self.currentFrame = self.currentFrame % self.numFrames + 1
        else
            if self.currentFrame < self.numFrames then
                self.currentFrame = self.currentFrame + 1
            end
        end
    end
end

function Animation:getCurrentQuad()
    return self.quads[self.currentFrame]
end

local function loadSprite(name, path)
    local status, image = pcall(love.graphics.newImage, path)
    if status then
        image:setFilter("nearest", "nearest")
        Sprites[name] = image
    else
        error("Error loading sprite "..name..": "..tostring(image))
    end
end

-- Existing sprites
loadSprite("spiderSheet", "assets/spider.png")
loadSprite("spiderv2Sheet", "assets/spiderv2.png")
loadSprite("spiritSheet", "assets/spirit.png")
loadSprite("beholderSheet", "assets/beholder.png")
loadSprite("osskarSheet", "assets/osskar.png")
loadSprite("pumpkinSheet", "assets/pumpkin.png")
loadSprite("eliteSpiderSheet", "assets/elitespider.png")
loadSprite("skittererSheet", "assets/skitterer.png")
loadSprite("webberSheet", "assets/webber.png")
loadSprite("webSheet", "assets/web.png")
loadSprite("kristoffSheet", "assets/kristofftheinfested.png")
loadSprite("mimicSheet", "assets/mimic.png")
loadSprite("kristoffDeathSheet", "assets/Kristoffdeath.png")
loadSprite("batSheet", "assets/bat.png")
loadSprite("firelizardSheet", "assets/firelizard.png")
loadSprite("fireslimeSheet", "assets/fireslime.png")
loadSprite("goyleSheet", "assets/goyle.png")
loadSprite("greenslimeSheet", "assets/greenslime.png")
loadSprite("greensnakeSheet", "assets/greensnake.png")
loadSprite("mageenemySheet", "assets/mageenemy.png")
loadSprite("magmagolemSheet", "assets/magmagolem.png")
loadSprite("manenemy1Sheet", "assets/manenemy1.png")
loadSprite("manenemy2Sheet", "assets/manenemy2.png")
loadSprite("manenemy3Sheet", "assets/manenemy3.png")
loadSprite("orcSheet", "assets/orc.png")
loadSprite("reddragonSheet", "assets/reddragon.png")
loadSprite("skeletonSheet", "assets/Skeleton.png")
loadSprite("waspsSheet", "assets/wasps.png")
-- Remove death sprite sheets for non-Kristoff enemies if desired:
loadSprite("kristoff_invulnerableSheet", "assets/Kristoff_invulnerable.png")
-- New ice/snow enemy sprites
loadSprite("icesnakeSheet", "assets/icesnake.png")
loadSprite("icelichSheet", "assets/icelich.png")
loadSprite("icebatSheet", "assets/icebat.png")
loadSprite("icelizardSheet", "assets/icelizard.png")
loadSprite("snowbearSheet", "assets/snowbear.png")
loadSprite("snowmanSheet", "assets/snowman.png")
loadSprite("spiderv2Sheet", "assets/spiderv2.png")
loadSprite("webBombSheet", "assets/webbomb.png")

-- Animation definitions (removed death animations except for Kristoff)
Sprites.animations = {
    spiderv2         = Animation.new(Sprites.spiderv2Sheet, 16, 16, 3, 0.1),
    spider           = Animation.new(Sprites.spiderSheet, 16, 16, 3, 0.1),
    spirit           = Animation.new(Sprites.spiritSheet, 16, 16, 3, 0.1),
    beholder         = Animation.new(Sprites.beholderSheet, 16, 16, 3, 0.1),
    osskar           = Animation.new(Sprites.osskarSheet, 32, 32, 3, 0.1),
    pumpkin          = Animation.new(Sprites.pumpkinSheet, 16, 16, 3, 0.1),
    elite_spider     = Animation.new(Sprites.eliteSpiderSheet, 32, 32, 3, 0.1),
    skitter_spider   = Animation.new(Sprites.skittererSheet, 16, 16, 3, 0.1),
    webber           = Animation.new(Sprites.webberSheet, 16, 16, 3, 0.1),
    web              = Animation.new(Sprites.webSheet, 16, 16, 3, 0.1),
    kristoff         = Animation.new(Sprites.kristoffSheet, 16, 16, 3, 0.1),
    kristoff_invulnerable = Animation.new(Sprites.kristoff_invulnerableSheet, 16, 16, 3, 0.1),
    mimic            = Animation.new(Sprites.mimicSheet, 16, 16, 3, 0.1),
    bat              = Animation.new(Sprites.batSheet, 16, 16, 3, 0.1),
    firelizard       = Animation.new(Sprites.firelizardSheet, 16, 16, 3, 0.1),
    fireslime        = Animation.new(Sprites.fireslimeSheet, 16, 16, 3, 0.1),
    goyle            = Animation.new(Sprites.goyleSheet, 16, 16, 3, 0.1),
    greenslime       = Animation.new(Sprites.greenslimeSheet, 16, 16, 3, 0.1),
    greensnake       = Animation.new(Sprites.greensnakeSheet, 16, 16, 3, 0.1),
    mageenemy        = Animation.new(Sprites.mageenemySheet, 16, 16, 3, 0.1),
    magmagolem       = Animation.new(Sprites.magmagolemSheet, 16, 16, 3, 0.1),
    manenemy1        = Animation.new(Sprites.manenemy1Sheet, 16, 16, 3, 0.1),
    manenemy2        = Animation.new(Sprites.manenemy2Sheet, 16, 16, 3, 0.1),
    manenemy3        = Animation.new(Sprites.manenemy3Sheet, 16, 16, 3, 0.1),
    orc              = Animation.new(Sprites.orcSheet, 16, 16, 3, 0.1),
    reddragon        = Animation.new(Sprites.reddragonSheet, 16, 16, 3, 0.1),
    skeleton         = Animation.new(Sprites.skeletonSheet, 16, 16, 3, 0.1),
    wasps            = Animation.new(Sprites.waspsSheet, 16, 16, 3, 0.1),
    icesnake         = Animation.new(Sprites.icesnakeSheet, 16, 16, 3, 0.1),
    icelich          = Animation.new(Sprites.icelichSheet, 16, 16, 3, 0.1),
    icebat           = Animation.new(Sprites.icebatSheet, 16, 16, 3, 0.1),
    icelizard        = Animation.new(Sprites.icelizardSheet, 16, 16, 3, 0.1),
    snowbear         = Animation.new(Sprites.snowbearSheet, 16, 16, 3, 0.1),
    snowman          = Animation.new(Sprites.snowmanSheet, 16, 16, 3, 0.1),
    webbomb          = Animation.new(Sprites.webBombSheet, 16, 16, 3, 0.1),
    -- Retain Kristoff's death animation if needed; all others use immediate removal.
    kristoff_death   = Animation.new(Sprites.kristoffDeathSheet, 16, 16, 11, 0.7)
}

function Sprites.updateAnimations(dt)
    for _, animation in pairs(Sprites.animations) do
        animation:update(dt)
    end
end

-- Existing draw functions (updated to accept a rotation parameter)

function Sprites.drawMimic(x, y, isWalking, scaleX, rotation)
    scaleX = scaleX or 2
    local scaleY = 2
    local bounceOffset = isWalking and 5 * math.sin(love.timer.getTime() * 5) or 0
    local animation = Sprites.animations.mimic
    local quad = animation:getCurrentQuad()
    local originX = 16/2
    local originY = 16/2
    rotation = rotation or 0
    love.graphics.draw(Sprites.mimicSheet, quad, x, y + bounceOffset, rotation, scaleX, scaleY, originX, originY)
end

function Sprites.drawspider(x, y, isWalking, scaleX, rotation)
    scaleX = scaleX or 2
    local scaleY = 2
    local crawlOffsetX = isWalking and 2 * math.sin(love.timer.getTime() * 7) or 0
    local animation = Sprites.animations.spider
    local quad = animation:getCurrentQuad()
    local originX = 16/2
    local originY = 16/2
    rotation = rotation or 0
    love.graphics.draw(Sprites.spiderSheet, quad, x + crawlOffsetX, y, rotation, scaleX, scaleY, originX, originY)
end

function Sprites.drawspiderv2(x, y, isWalking, scaleX, rotation)
    scaleX = scaleX or 2
    local scaleY = 2
    local crawlOffsetX = isWalking and 2 * math.sin(love.timer.getTime() * 7) or 0
    local animation = Sprites.animations.spiderv2
    local quad = animation:getCurrentQuad()
    local originX = 16/2
    local originY = 16/2
    rotation = rotation or 0
    love.graphics.draw(Sprites.spiderv2Sheet, quad, x + crawlOffsetX, y, rotation, scaleX, scaleY, originX, originY)
end

function Sprites.drawEliteSpider(x, y, isZigZagging, scaleX, rotation)
    scaleX = scaleX or 2
    local scaleY = 2
    local offset = isZigZagging and 5 * math.sin(love.timer.getTime() * 10) or 0
    local animation = Sprites.animations.elite_spider
    local quad = animation:getCurrentQuad()
    local originX = 32/2
    local originY = 32/2
    rotation = rotation or 0
    love.graphics.draw(Sprites.eliteSpiderSheet, quad, x, y + offset, rotation, scaleX, scaleY, originX, originY)
end

function Sprites.drawSpirit(x, y, isFloating, scaleX, rotation)
    scaleX = scaleX or 2
    local scaleY = 2
    local floatOffset = isFloating and math.sin(love.timer.getTime() * 5) * 3 or 0
    local animation = Sprites.animations.spirit
    local quad = animation:getCurrentQuad()
    local originX = 16/2
    local originY = 16/2
    rotation = rotation or 0
    love.graphics.draw(Sprites.spiritSheet, quad, x, y + floatOffset, rotation, scaleX, scaleY, originX, originY)
end

function Sprites.drawBeholder(x, y, isFloating, scaleX, rotation)
    scaleX = scaleX or 2
    local scaleY = 2
    local floatOffset = isFloating and math.sin(love.timer.getTime() * 5) * 3 or 0
    local animation = Sprites.animations.beholder
    local quad = animation:getCurrentQuad()
    local originX = 16/2
    local originY = 16/2
    rotation = rotation or 0
    love.graphics.draw(Sprites.beholderSheet, quad, x, y + floatOffset, rotation, scaleX, scaleY, originX, originY)
end

function Sprites.drawOsskar(x, y, scaleX, scaleY, rotation)
    scaleX = scaleX or 2
    scaleY = scaleY or 2
    local animation = Sprites.animations.osskar
    local quad = animation:getCurrentQuad()
    local originX = 32/2
    local originY = 32/2
    rotation = rotation or 0
    love.graphics.draw(Sprites.osskarSheet, quad, x, y, rotation, scaleX, scaleY, originX, originY)
end

function Sprites.drawSkitterer(x, y, scaleX, rotation)
    scaleX = scaleX or 1
    local scaleY = 1
    local flutterOffset = 3 * math.sin(love.timer.getTime() * 6)
    local animation = Sprites.animations.skitter_spider
    local quad = animation:getCurrentQuad()
    local origin = 8
    rotation = rotation or 0
    love.graphics.draw(Sprites.skittererSheet, quad, x, y + flutterOffset, rotation, scaleX, scaleY, origin, origin)
end

function Sprites.drawWebber(x, y, isAttacking, scaleX, rotation)
    scaleX = scaleX or 2
    local scaleY = 2
    local animation = Sprites.animations.webber
    local quad = animation:getCurrentQuad()
    local originX = 16/2
    local originY = 16/2
    rotation = rotation or 0
    love.graphics.draw(Sprites.webberSheet, quad, x, y, rotation, scaleX, scaleY, originX, originY)
end

function Sprites.drawWeb(x, y, scaleX, rotation)
    scaleX = scaleX or 2
    local scaleY = 2
    local animation = Sprites.animations.web
    local quad = animation:getCurrentQuad()
    local originX = 16/2
    local originY = 16/2
    rotation = rotation or 0
    love.graphics.draw(Sprites.webSheet, quad, x, y, rotation, scaleX, scaleY, originX, originY)
end

function Sprites.drawPumpkin(x, y, isBouncing, scaleX, rotation)
    scaleX = scaleX or 2
    local scaleY = 2
    local bounceOffset = isBouncing and 5 * math.sin(love.timer.getTime() * 5) or 0
    local animation = Sprites.animations.pumpkin
    local quad = animation:getCurrentQuad()
    local originX, originY = 8, 8
    rotation = rotation or 0
    love.graphics.draw(Sprites.pumpkinSheet, quad, x, y + bounceOffset, rotation, scaleX, scaleY, originX, originY)
end

function Sprites.drawWebBomb(x, y, animation, scale, rotation)
    scale = scale or 2
    rotation = rotation or 0
    local quad = animation:getCurrentQuad()
    local originX, originY = 8, 8
    love.graphics.draw(Sprites.webBombSheet, quad, x, y, rotation, scale, scale, originX, originY)
end

function Sprites.drawKristoff(x, y, isFloating, scaleX, rotation)
    scaleX = scaleX or 2
    local scaleY = 2
    local floatOffset = isFloating and math.sin(love.timer.getTime() * 5) * 3 or 0
    local animation = Sprites.animations.kristoff
    local quad = animation:getCurrentQuad()
    local originX, originY = 16/2, 16/2
    rotation = rotation or 0
    love.graphics.draw(Sprites.kristoffSheet, quad, x, y, rotation, scaleX, scaleY, originX, originY)
end

function Sprites.drawKristoffInvulnerable(x, y, isFloating, scaleX, rotation)
    scaleX = scaleX or 2
    local scaleY = 2
    local animation = Sprites.animations.kristoff_invulnerable
    local quad = animation:getCurrentQuad()
    local originX, originY = 16/2, 16/2
    rotation = rotation or 0
    love.graphics.draw(Sprites.kristoff_invulnerableSheet, quad, x, y, rotation, scaleX, scaleY, originX, originY)
end

-- The dedicated death drawing function has been removed for non-Kristoff enemies.
-- If needed, Kristoff's death animation is still available:
function Sprites.drawKristoffDeath(x, y, scaleX, rotation)
    scaleX = scaleX or 2
    local scaleY = 2
    local anim = Sprites.animations.kristoff_death
    local quad = anim:getCurrentQuad()
    local originX, originY = 16/2, 16/2
    rotation = rotation or 0
    love.graphics.draw(Sprites.kristoffDeathSheet, quad, x, y, 0, scaleX, scaleY, originX, originY)
end

-- New draw functions for additional enemy types using a helper
local function createDrawFunction(name, sheetName)
    return function(x, y, isFloating, scaleX, rotation)
        scaleX = scaleX or 2
        local scaleY = 2
        local floatOffset = isFloating and math.sin(love.timer.getTime() * 5) * 3 or 0
        local animation = Sprites.animations[name]
        local quad = animation:getCurrentQuad()
        local originX = 16/2
        local originY = 16/2
        rotation = rotation or 0
        love.graphics.draw(Sprites[sheetName], quad, x, y + floatOffset, rotation, scaleX, scaleY, originX, originY)
    end
end

Sprites.drawBat         = createDrawFunction("bat",         "batSheet")
Sprites.drawFirelizard  = createDrawFunction("firelizard",  "firelizardSheet")
Sprites.drawFireslime   = createDrawFunction("fireslime",   "fireslimeSheet")
Sprites.drawGoyle       = createDrawFunction("goyle",       "goyleSheet")
Sprites.drawGreenslime   = createDrawFunction("greenslime",  "greenslimeSheet")
Sprites.drawGreensnake   = createDrawFunction("greensnake",  "greensnakeSheet")
Sprites.drawMageenemy    = createDrawFunction("mageenemy",   "mageenemySheet")
Sprites.drawMagmagolem   = createDrawFunction("magmagolem",  "magmagolemSheet")
Sprites.drawManenemy1    = createDrawFunction("manenemy1",   "manenemy1Sheet")
Sprites.drawManenemy2    = createDrawFunction("manenemy2",   "manenemy2Sheet")
Sprites.drawManenemy3    = createDrawFunction("manenemy3",   "manenemy3Sheet")
Sprites.drawOrc          = createDrawFunction("orc",         "orcSheet")
Sprites.drawReddragon    = createDrawFunction("reddragon",   "reddragonSheet")
Sprites.drawSkeleton     = createDrawFunction("skeleton",    "skeletonSheet")
Sprites.drawWasps        = createDrawFunction("wasps",       "waspsSheet")
-- New ice/snow draw functions
Sprites.drawIcesnake     = createDrawFunction("icesnake",    "icesnakeSheet")
Sprites.drawIcelich      = createDrawFunction("icelich",     "icelichSheet")
Sprites.drawIcebat       = createDrawFunction("icebat",      "icebatSheet")
Sprites.drawIcelizard    = createDrawFunction("icelizard",   "icelizardSheet")
Sprites.drawSnowbear     = createDrawFunction("snowbear",    "snowbearSheet")
Sprites.drawSnowman      = createDrawFunction("snowman",     "snowmanSheet")

return Sprites
