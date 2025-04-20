local Sprites = require("sprites")  -- ensure we have access to your sprites module

local backgroundEnemies = {}

backgroundEnemies.maxEnemies = 100
local spawnInterval = 0.1  -- seconds between spawns
local spawnTimer = 0

backgroundEnemies.enemies = {}

-- Mapping enemy types to drawing functions.
-- We pass false (no bounce) and a custom scaleX.
local enemyDrawFunctions = {
    spider         = function(x, y, scaleX) Sprites.drawspider(x, y, false, scaleX, 0) end,
    spirit         = function(x, y, scaleX) Sprites.drawSpirit(x, y, false, scaleX, 0) end,
    beholder       = function(x, y, scaleX) Sprites.drawBeholder(x, y, false, scaleX, 0) end,
    osskar         = function(x, y, scaleX) Sprites.drawOsskar(x, y, scaleX, 2, 0) end,
    kristoff       = function(x, y, scaleX) Sprites.drawKristoff(x, y, scaleX, 2, 0) end,
    pumpkin        = function(x, y, scaleX) Sprites.drawPumpkin(x, y, false, scaleX, 0) end,
    elite_spider   = function(x, y, scaleX) Sprites.drawEliteSpider(x, y, false, scaleX, 0) end,
    webber         = function(x, y, scaleX) Sprites.drawWebber(x, y, false, scaleX, 0) end,
    bat            = function(x, y, scaleX) Sprites.drawBat(x, y, false, scaleX, 0) end,
    firelizard     = function(x, y, scaleX) Sprites.drawFirelizard(x, y, false, scaleX, 0) end,
    fireslime      = function(x, y, scaleX) Sprites.drawFireslime(x, y, false, scaleX, 0) end,
    goyle          = function(x, y, scaleX) Sprites.drawGoyle(x, y, false, scaleX, 0) end,
    greenslime     = function(x, y, scaleX) Sprites.drawGreenslime(x, y, false, scaleX, 0) end,
    greensnake     = function(x, y, scaleX) Sprites.drawGreensnake(x, y, false, scaleX, 0) end,
    mageenemy      = function(x, y, scaleX) Sprites.drawMageenemy(x, y, false, scaleX, 0) end,
    magmagolem     = function(x, y, scaleX) Sprites.drawMagmagolem(x, y, false, scaleX, 0) end,
    manenemy1      = function(x, y, scaleX) Sprites.drawManenemy1(x, y, false, scaleX, 0) end,
    manenemy2      = function(x, y, scaleX) Sprites.drawManenemy2(x, y, false, scaleX, 0) end,
    manenemy3      = function(x, y, scaleX) Sprites.drawManenemy3(x, y, false, scaleX, 0) end,
    orc            = function(x, y, scaleX) Sprites.drawOrc(x, y, false, scaleX, 0) end,
    reddragon      = function(x, y, scaleX) Sprites.drawReddragon(x, y, false, scaleX, 0) end,
    skeleton       = function(x, y, scaleX) Sprites.drawSkeleton(x, y, false, scaleX, 0) end,
    wasps          = function(x, y, scaleX) Sprites.drawWasps(x, y, false, scaleX, 0) end,
    -- New ice/snow enemy mappings
    icesnake       = function(x, y, scaleX) Sprites.drawIcesnake(x, y, false, scaleX, 0) end,
    icelich        = function(x, y, scaleX) Sprites.drawIcelich(x, y, false, scaleX, 0) end,
    icebat         = function(x, y, scaleX) Sprites.drawIcebat(x, y, false, scaleX, 0) end,
    icelizard      = function(x, y, scaleX) Sprites.drawIcelizard(x, y, false, scaleX, 0) end,
    snowbear       = function(x, y, scaleX) Sprites.drawSnowbear(x, y, false, scaleX, 0) end,
    snowman        = function(x, y, scaleX) Sprites.drawSnowman(x, y, false, scaleX, 0) end,
}

local enemyTypes = {}
for key, _ in pairs(enemyDrawFunctions) do
    table.insert(enemyTypes, key)
end

-- Returns spawn and destination points based on a random side.
local function getRandomSpawnAndDestination()
    local screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()
    local buffer = 50  -- spawn/dest outside the screen by 50 pixels
    local spawn, destination = {}, {}
    local side = love.math.random(1, 4)  -- 1:left, 2:right, 3:top, 4:bottom

    if side == 1 then -- spawn left, dest right
        spawn.x = -buffer
        spawn.y = love.math.random(0, screenHeight)
        destination.x = screenWidth + buffer
        destination.y = love.math.random(0, screenHeight)
    elseif side == 2 then -- spawn right, dest left
        spawn.x = screenWidth + buffer
        spawn.y = love.math.random(0, screenHeight)
        destination.x = -buffer
        destination.y = love.math.random(0, screenHeight)
    elseif side == 3 then -- spawn top, dest bottom
        spawn.x = love.math.random(0, screenWidth)
        spawn.y = -buffer
        destination.x = love.math.random(0, screenWidth)
        destination.y = screenHeight + buffer
    else -- side == 4; spawn bottom, dest top
        spawn.x = love.math.random(0, screenWidth)
        spawn.y = screenHeight + buffer
        destination.x = love.math.random(0, screenWidth)
        destination.y = -buffer
    end

    return spawn, destination
end

-- Spawn a single enemy.
local function spawnEnemy()
    local spawn, destination = getRandomSpawnAndDestination()
    local enemyType = enemyTypes[love.math.random(1, #enemyTypes)]
    local dx = destination.x - spawn.x
    local dy = destination.y - spawn.y
    local distance = math.sqrt(dx * dx + dy * dy)
    local speed = love.math.random(20, 60)  -- adjust as desired
    local vx = dx / distance * speed
    local vy = dy / distance * speed

    -- Only flip horizontally. If moving left (vx < 0), flip the sprite.
    local scaleX = 2
    if vx < 0 then
        scaleX = -2
    end

    local enemy = {
        type = enemyType,
        x = spawn.x,
        y = spawn.y,
        vx = vx,
        vy = vy,
        scaleX = scaleX,
        traveled = 0,
        totalDistance = distance,
        drawFunc = enemyDrawFunctions[enemyType]
    }
    table.insert(backgroundEnemies.enemies, enemy)
end

-- Update function: spawn new enemies and update positions.
function backgroundEnemies.update(dt)
    Sprites.updateAnimations(dt)
    spawnTimer = spawnTimer + dt
    if spawnTimer >= spawnInterval then
        if #backgroundEnemies.enemies < backgroundEnemies.maxEnemies then
            spawnEnemy()
        end
        spawnTimer = 0
    end

    for i = #backgroundEnemies.enemies, 1, -1 do
        local enemy = backgroundEnemies.enemies[i]
        local dx = enemy.vx * dt
        local dy = enemy.vy * dt
        enemy.x = enemy.x + dx
        enemy.y = enemy.y + dy
        enemy.traveled = enemy.traveled + math.sqrt(dx * dx + dy * dy)
        if enemy.traveled >= enemy.totalDistance then
            table.remove(backgroundEnemies.enemies, i)
        end
    end
end

-- Draw all enemies (drawn behind your menu).
function backgroundEnemies.draw()
    for _, enemy in ipairs(backgroundEnemies.enemies) do
        enemy.drawFunc(enemy.x, enemy.y, enemy.scaleX)
    end
end

return backgroundEnemies
