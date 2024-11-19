local Sprites = {}
Sprites.vampireMistPuffs = {}


-- Load enemy sprites
Sprites.goblin = love.graphics.newImage("assets/goblin.png")
Sprites.goblin:setFilter("nearest", "nearest")

Sprites.skeleton = love.graphics.newImage("assets/skeleton.png")
Sprites.skeleton:setFilter("nearest", "nearest")

Sprites.bat = love.graphics.newImage("assets/bat.png")
Sprites.bat:setFilter("nearest", "nearest")

Sprites.slime = love.graphics.newImage("assets/slime.png")
Sprites.slime:setFilter("nearest", "nearest")

Sprites.orcArcher = love.graphics.newImage("assets/orc_archer.png")
Sprites.orcArcher:setFilter("nearest", "nearest")

Sprites.mageEnemy = love.graphics.newImage("assets/mage_enemy.png")
Sprites.mageEnemy:setFilter("nearest", "nearest")

Sprites.viper = love.graphics.newImage("assets/viper.png")
Sprites.viper:setFilter("nearest", "nearest")

Sprites.vampireBoss = love.graphics.newImage("assets/vampire_boss.png")
Sprites.vampireBoss:setFilter("nearest", "nearest")


-- Function to draw a goblin with specified direction, scale, and bounce effect
function Sprites.drawGoblin(x, y, direction, isWalking)
    local scaleX = 2  -- 100% increase in size (double the size)
    local scaleY = 2

 

    local bounceOffset = 5 * math.sin(love.timer.getTime() * 5)
    if not isWalking then bounceOffset = 0 end

    love.graphics.draw(Sprites.goblin, x, y + bounceOffset, 0, scaleX, scaleY, Sprites.goblin:getWidth() / 2, Sprites.goblin:getHeight() / 2)
end

-- Function to draw a skeleton
function Sprites.drawSkeleton(x, y, direction, isWalking)
    local scaleX = 2
    local scaleY = 2

   
    local rattleOffset = 3 * math.sin(love.timer.getTime() * 10)
    love.graphics.draw(Sprites.skeleton, x, y + rattleOffset, 0, scaleX, scaleY, Sprites.skeleton:getWidth() / 2, Sprites.skeleton:getHeight() / 2)
end

-- Function to draw a bat
function Sprites.drawBat(x, y, direction, isFlying)
    local scaleX = direction == "right" and 1 or -1
    local scaleY = 1

    if isFlying then
        local flapOffset = math.sin(love.timer.getTime() * 10) * 2
        y = y + flapOffset
    end

    love.graphics.draw(Sprites.bat, x, y, 0, scaleX * 1.5, scaleY * 1.5, Sprites.bat:getWidth() / 2, Sprites.bat:getHeight() / 2)
end

-- Function to draw a slime
function Sprites.drawSlime(x, y, scaleX, scaleY)
  
    local scaleX = 2
    local scaleY = 2
    local spriteWidth = Sprites.slime:getWidth()
    local spriteHeight = Sprites.slime:getHeight()
     local baseScale = 2  -- Increase this number to make the slime bigger
    love.graphics.draw(Sprites.slime, x, y, 0, scaleX, scaleY, spriteWidth / 3, spriteHeight / 3)
end


-- Function to draw an orc archer
function Sprites.drawOrcArcher(x, y, direction, isWalking)
    local scaleX = 2
    local scaleY = 2


    local bounceOffset = 5 * math.sin(love.timer.getTime() * 5)
    if not isWalking then bounceOffset = 0 end

    love.graphics.draw(Sprites.orcArcher, x, y + bounceOffset, 0, scaleX, scaleY, Sprites.orcArcher:getWidth() / 2, Sprites.orcArcher:getHeight() / 2)
end

-- Function to draw a mage enemy
function Sprites.drawMageEnemy(x, y, direction, isWalking)
    local scaleX = 2
    local scaleY = 2

 
    love.graphics.draw(Sprites.mageEnemy, x, y, 0, scaleX, scaleY, Sprites.mageEnemy:getWidth() / 2, Sprites.mageEnemy:getHeight() / 2)
end

-- Function to draw a viper
function Sprites.drawViper(x, y, direction, isWalking)
    local scaleX = 2
    local scaleY = 2

   

    local slitherOffset = 3 * math.sin(love.timer.getTime() * 10)
    love.graphics.draw(Sprites.viper, x + slitherOffset, y, 0, scaleX, scaleY, Sprites.viper:getWidth() / 2, Sprites.viper:getHeight() / 2)
end

function Sprites.drawVampireBoss(x, y, direction, isWalking)
    local scaleX = 4
    local scaleY = 4

    -- Occasionally emit mist puffs when the vampire is moving
    if isWalking and math.random() < 0.3 then  -- Emit a puff with 30% chance each frame
        table.insert(Sprites.vampireMistPuffs, {
            x = x,
            y = y,
            opacity = math.random() * 0.5 + 0.3,  -- Random initial opacity between 0.3 and 0.8
            size = math.random(8, 15),            -- Random initial size between 8 and 15
            dx = math.random(-10, 10) * 0.1,      -- Random drift in x direction
            dy = math.random(-10, 10) * 0.1,      -- Random drift in y direction
        })
    end

    -- Update and draw each mist puff
    for i = #Sprites.vampireMistPuffs, 1, -1 do
        local puff = Sprites.vampireMistPuffs[i]
        
        -- Draw the puff with a soft, smoke-like purple color
        love.graphics.setColor(0.6, 0, 1, puff.opacity)  
        love.graphics.circle("fill", puff.x, puff.y, puff.size)

        -- Update puff properties for fade-out and drift
        puff.opacity = puff.opacity - 0.005   -- Slow fade out
        puff.size = puff.size - 0.02          -- Gradual size decrease
        puff.x = puff.x + puff.dx             -- Apply random drift in x direction
        puff.y = puff.y + puff.dy             -- Apply random drift in y direction

        -- Remove puff if fully faded
        if puff.opacity <= 0 then
            table.remove(Sprites.vampireMistPuffs, i)
        end
    end

    -- Reset color and draw the vampire boss sprite
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(Sprites.vampireBoss, x, y, 0, scaleX, scaleY, Sprites.vampireBoss:getWidth() / 2, Sprites.vampireBoss:getHeight() / 2)
end



return Sprites
