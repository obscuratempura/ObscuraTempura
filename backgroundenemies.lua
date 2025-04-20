local Sprites = require("sprites")  -- ensure we have access to your sprites module

local backgroundEnemies = {}

-- Configurable maximum number of enemies onscreen
backgroundEnemies.maxEnemies = 10

-- Spawn settings
local spawnInterval = 1.0  -- seconds between spawns
local spawnTimer = 0

backgroundEnemies.enemies = {}

-- Mapping enemy types to custom drawing functions (using your sprites drawing functions)
local enemyDrawFunctions = {
    spider = function(x, y) Sprites.drawspider(x, y, true, 2) end,
    spirit = function(x, y) Sprites.drawSpirit(x, y, true, 2) end,
    beholder = function(x, y) Sprites.drawBeholder(x, y, true, 2) end,
    osskar = function(x, y) Sprites.drawOsskar(x, y, 2, 2) end,
    pumpkin = function(x, y) Sprites.drawPumpkin(x, y, true, 2) end,
    elite_spider = function(x, y) Sprites.drawEliteSpider(x, y, true, 2) end,
    skitter_spider = function(x, y) Sprites.drawSkitterer(x, y, 1) end,
    webber = function(x, y) Sprites.drawWebber(x, y, false, 2) end,
    web = function(x, y) Sprites.drawWeb(x, y, 2) end,
}

-- Build a list of enemy type keys for random selection
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

-- Spawn a single enemy
local function spawnEnemy()
    local spawn, destination = getRandomSpawnAndDestination()
    local enemyType = enemyTypes[love.math.random(1, #enemyTypes)]
    local dx = destination.x - spawn.x
    local dy = destination.y - spawn.y
    local distance = math.sqrt(dx * dx + dy * dy)
    local speed = love.math.random(20, 60)  -- adjust as desired
    local vx = dx / distance * speed
    local vy = dy / distance * speed

    local enemy = {
        type = enemyType,
        x = spawn.x,
        y = spawn.y,
        vx = vx,
        vy = vy,
        traveled = 0,
        totalDistance = distance,
        drawFunc = enemyDrawFunctions[enemyType]
    }
    table.insert(backgroundEnemies.enemies, enemy)
end

-- Update function – spawns new enemies and moves existing ones.
function backgroundEnemies.update(dt)
    spawnTimer = spawnTimer + dt
    if spawnTimer >= spawnInterval then
        if #backgroundEnemies.enemies < backgroundEnemies.maxEnemies then
            spawnEnemy()
        end
        spawnTimer = 0
    end

    -- Update enemy positions and remove them once they reach their destination
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

-- Draw all enemies (drawn behind your menu)
function backgroundEnemies.draw()
    for _, enemy in ipairs(backgroundEnemies.enemies) do
        enemy.drawFunc(enemy.x, enemy.y)
    end
end

return backgroundEnemies
