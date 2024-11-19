damageNumbers = {}  -- Table to store active damage numbers
effects = {}

local Player = require("player")
local Enemy = require("enemy")
local Maze = require("maze")
local UI = require("ui")
local Experience = require("experience")
local Collision = require("collision")
local Effects = require("effects")
local DamageNumber = require("damage_number")
local DevMenu = require("devmenu") -- Your dev menu file
local gamePaused = false
local showMenu = false
local Overworld = require("overworld")
local Level2 = require("level2")




enemies = {}  -- Global list of enemies

-- Camera variables
cameraX, cameraY = 0, 0

-- Shake variables
local shakeDuration = 0
local shakeMagnitude = 0

function love.load()
  print("Game Started")    
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.window.setTitle("Vector Souls")
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
    love.window.setMode(800, 600, { resizable = true, minwidth = 800, minheight = 600 })
    
    love.window.maximize()

    -- Initialize damage and effects
    damageNumbers = {}
    effects = {}

    -- Seed random numbers
    math.randomseed(os.time())

    -- Initialize game state
    gameState = "title"

    -- Initialize title screen elements
    titleEnemies = {}
    for i = 1, 20 do
        local x = math.random(0, 800)
        local y = math.random(0, 600)
        local dx = math.random(-100, 100)
        local dy = math.random(-100, 100)
        table.insert(titleEnemies, { x = x, y = y, dx = dx, dy = dy, type = Enemy.randomType(), radius = 10 })
    end

    -- Initialize sounds
    sounds = {}
    loadSounds()

    -- Initialize mist particle system
    mistParticles = {}
    createMistParticles()

    -- **Initialize fonts table and load fonts**
    fonts = {}
    fonts.title = love.graphics.newFont("fonts/gothic.ttf", 64) -- Load your gothic font here
    fonts.prompt = love.graphics.newFont("fonts/gothic.ttf", 24)
end


function love.resize(w, h)
    -- This function gets called whenever the window is resized
   
    -- You can dynamically adjust any elements, or just let Love2D automatically handle the scaling
end

function createMistParticles()
    -- Load mist image
    mistImage = love.graphics.newImage("mist.png") -- Ensure mist.png is in your project directory

    -- Create particle system
    mistParticleSystem = love.graphics.newParticleSystem(mistImage, 500)
    mistParticleSystem:setParticleLifetime(5, 10) -- Particles live between 5 to 10 seconds
    mistParticleSystem:setEmissionRate(50)
    mistParticleSystem:setSizeVariation(0.5)
    mistParticleSystem:setLinearAcceleration(-20, -20, 20, 20) -- Slow movement
    mistParticleSystem:setColors(255, 255, 255, 100, 255, 255, 255, 0) -- Fade out
    mistParticleSystem:setEmissionArea("normal", 400, 300, 0, true) -- Emit from center
    mistParticleSystem:setDirection(math.rad(0))
    mistParticleSystem:setSpread(math.rad(360))
    mistParticleSystem:setSpeed(10, 20)
    mistParticleSystem:setSizes(1, 2, 3)
    mistParticleSystem:setSpin(0, 0)
    mistParticleSystem:setPosition(400, 300) -- Center of the screen
    mistParticleSystem:setRelativeRotation(false)
    mistParticleSystem:emit(100)
end


function loadSounds()
    -- Load your sounds here...
    -- Example:
    sounds.backgroundMusic = love.audio.newSource("background.mp3", "stream")
    sounds.backgroundMusic:setLooping(true)
    sounds.backgroundMusic:play()

-- Load title screen music
    --sounds.titleMusic = love.audio.newSource("titlemusic.wav", "stream")
    --sounds.titleMusic:setLooping(true)
    
    -- Enemy death sounds
    sounds.enemyDeath = {
        goblin = love.audio.newSource("goblin_death.wav", "static"),
        skeleton = love.audio.newSource("skeleton_death.wav", "static"),
        bat = love.audio.newSource("bat_death.wav", "static"),
        orc_archer = love.audio.newSource("orc_archer_death.wav", "static"),
        slime = love.audio.newSource("slime_death.wav", "static"),
        vampire_boss = love.audio.newSource("vampire_boss_death.wav", "static"),
        mage_enemy = love.audio.newSource("mage_enemy_death.wav", "static"),
        viper = love.audio.newSource("viper_death.wav", "static"),
    }

    -- Player attack sounds
    sounds.playerAttack = {
        ranger = love.audio.newSource("ranger_attack.wav", "static"),
        mage = love.audio.newSource("mage_attack.wav", "static"),
        spearwarden = love.audio.newSource("spearwarden_attack.wav", "static"),
    }

    -- Ability sounds
    sounds.ability = {
        ignite = love.audio.newSource("ignite.wav", "static"),
        chainLightning = love.audio.newSource("chain_lightning.wav", "static"),
        explosion = love.audio.newSource("explosion.wav", "static"),
        summonwolf = love.audio.newSource("summon_wolf.wav", "static"),
        poisonshot = love.audio.newSource("poison.wav", "static"),
        frostexplosion = love.audio.newSource("frost_explosion.wav", "static"),
        
    }

    -- Boss spawn sound
    sounds.bossSpawn = love.audio.newSource("boss_spawn.wav", "static")
end

function love.update(dt)
    -- Always update mist particles, even if the game is paused
    mistParticleSystem:update(dt)

    if gameState == "title" then
        --if not sounds.titleMusic:isPlaying() then
            --sounds.titleMusic:play()
        --end
        if sounds.backgroundMusic:isPlaying() then
            sounds.backgroundMusic:stop()
        end
        updateTitleScreen(dt)

    elseif gameState == "overworld" then
        Overworld.update(dt)  -- Update the overworld

    elseif gameState == "playing" then
        -- Play the background music and stop the title music if the game is in playing state
        if not sounds.backgroundMusic:isPlaying() then
            sounds.backgroundMusic:play()
        end
        --if sounds.titleMusic:isPlaying() then
            --sounds.titleMusic:stop()
        --end

        -- Keep game logic running if the dev menu is up but stop when the escape menu is open
        if not showMenu then
          updateGame(dt)
            handleCollisions()
            
        end

    elseif gameState == "gameOver" then
        -- Ensure background music stops and title music plays in the game over state
        if sounds.backgroundMusic:isPlaying() then
            sounds.backgroundMusic:stop()
        end
        --if not sounds.titleMusic:isPlaying() then
            --sounds.titleMusic:play()
        --end
    end

    -- Update all active damage numbers (this can continue even if the game is paused)
    for i = #damageNumbers, 1, -1 do
        local dn = damageNumbers[i]
        dn:update(dt)
        if dn.alpha <= 0 then
            table.remove(damageNumbers, i)
        end
    end
end


function updateGame(dt)
  

    -- Level up logic
    if experience.isLevelingUp then
    
        --gamePaused = true
        ui:showUpgradeOptions(experience.upgradeOptions, function(selectedUpgrade)
          
            selectedUpgrade.apply()
            experience.isLevelingUp = false
            --gamePaused = false
           
        end)
        return
    end

    -- Check if the player is defeated
    if player:isDefeated() then
        gameOver = true
        gamePaused = true
        gameState = "gameOver"
    end

    -- Handle boss spawn logic based on player level
    if not bossSpawned and experience.level >= bossLevels[nextBossLevel] then
        bossSpawned = true
        spawnBoss()
    end

    -- Adjust spawn interval and enemy health based on player level
    adjustDifficulty()

    -- Update spawn timer
   spawnTimer = spawnTimer + dt
    if spawnTimer >= spawnInterval then
        spawnTimer = 0
        if #enemies < maxEnemies and currentLevel.spawnEnemy then
            currentLevel:spawnEnemy()  -- Use the level-specific spawnEnemy
        end
    end

  if player.summonedEntities == nil then
        player.summonedEntities = {}
    end
    -- Update summoned entities (wolves, etc.)
    for i = #player.summonedEntities, 1, -1 do
        local entity = player.summonedEntities[i]
        entity:update(dt, enemies, effects, player.summonedEntities )
        if entity.isDead then
            table.remove(player.summonedEntities, i)
        end
    end

    -- Call the update functions for player, enemies, UI, and experience
    player:update(dt, enemies, effects, maze.zoomFactor)
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
       enemy:update(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities, maze.zoomFactor)

        if enemy.health <= 0 then
          
           if sounds and sounds.enemyDeath and sounds.enemyDeath[enemy.type] then
            sounds.enemyDeath[enemy.type]:play()
        end
            -- Handle enemy death and experience gain
            experience:addExperience(enemy.experience)
            table.remove(enemies, i)

            -- Check if the boss is defeated
            if enemy.isBoss then
                bossSpawned = false
                nextBossLevel = nextBossLevel + 1
                experience:grantTier3Talents()
            end
        end
    end

    -- Update UI and experience systems
    ui:update(dt)
    experience:update(dt)

    -- Handle any remaining effects
    for i = #effects, 1, -1 do
        local effect = effects[i]
        if effect.update then
            effect:update(dt, enemies)
        end
        if effect.isDead then
            table.remove(effects, i)
        end
    end
    
     if player.damageFlashTimer and player.damageFlashTimer > 0 then
        player.damageFlashTimer = player.damageFlashTimer - dt
    end

    -- Handle collision detection
    handleCollisions()

    -- Update camera position
    updateCamera(dt)
end



function updateTitleScreen(dt)
    -- Update title screen enemies
    for _, enemy in ipairs(titleEnemies) do
        enemy.x = enemy.x + enemy.dx * dt
        enemy.y = enemy.y + enemy.dy * dt

        -- Bounce off edges
        if enemy.x < enemy.radius or enemy.x > 800 - enemy.radius then
            enemy.dx = -enemy.dx
        end
        if enemy.y < enemy.radius or enemy.y > 600 - enemy.radius then
            enemy.dy = -enemy.dy
        end
    end

    -- Update mist particle system
    mistParticleSystem:update(dt)
end



function adjustDifficulty()
    local level = experience.level
    
    if level >= 10 and level < 20 then
        spawnInterval = 0.8
        for _, enemy in pairs(enemies) do
            enemy.damage = enemy.damage * 1.1  -- Increase enemy damage by 10%
        end
    elseif level >= 20 and level < 30 then
        spawnInterval = 0.6
        for _, enemy in pairs(enemies) do
            enemy.damage = enemy.damage * 1.15  -- Increase enemy damage by 15%
        end
    elseif level >= 30 then
        spawnInterval = 0.5
        for _, enemy in pairs(enemies) do
            enemy.damage = enemy.damage * 1.2   -- Increase enemy damage by 20%
        end
    end
end




local cameraZoom = 1.5  -- Adjust this value to control the zoom level

function updateCamera(dt)
    -- Calculate the average position of all characters
    local totalX, totalY = 0, 0
    local charCount = 0

    for _, char in pairs(player.characters) do
        if char.health > 0 then  -- Only include living characters
            totalX = totalX + char.x
            totalY = totalY + char.y
            charCount = charCount + 1
        end
    end

    -- Calculate the average position if there are any characters alive
    if charCount > 0 then
        local avgX = totalX / charCount
        local avgY = totalY / charCount

        -- Calculate screen center, considering the zoom factor
        local screenWidth = love.graphics.getWidth() / cameraZoom
        local screenHeight = love.graphics.getHeight() / cameraZoom

        -- Apply camera shake if applicable
        if shakeDuration > 0 then
            shakeDuration = shakeDuration - dt
            local shakeX = math.random(-shakeMagnitude, shakeMagnitude)
            local shakeY = math.random(-shakeMagnitude, shakeMagnitude)
            cameraX = avgX - (screenWidth / 2) + shakeX
            cameraY = avgY - (screenHeight / 2) + shakeY
        else
            cameraX = avgX - (screenWidth / 2)
            cameraY = avgY - (screenHeight / 2)
        end
    end
end




local cameraZoom = 1.5  -- Adjust this value to control the zoom level

function drawGame()
    love.graphics.push()  -- Save the current state before scaling and translating
    
    -- Apply the zoom and translate the camera
    love.graphics.scale(cameraZoom, cameraZoom)
    love.graphics.translate(-cameraX, -cameraY)

    -- Draw the background first (use a function if it involves more details)
    

    -- Draw maze, enemies, and summoned entities in the correct order
   if maze and maze.draw then maze:draw() end

    
    
    for _, enemy in ipairs(enemies) do
        if enemy and enemy.draw then enemy:draw() end
    end
    for _, entity in ipairs(player.summonedEntities or {}) do
        if entity and entity.draw then entity:draw() end
    end
    if player and player.draw then player:draw(maze.zoomFactor) end

    -- Draw projectiles last to keep them visible above all elements
    for _, proj in ipairs(player.projectiles or {}) do
        proj:draw()
    end

    -- Draw all active effects above other elements
    for _, effect in ipairs(effects) do
        if effect and effect.draw then
            effect:draw()
        end
    end

    love.graphics.pop()

    -- Draw UI elements separately after everything else to keep UI fixed on screen
    if ui and ui.draw then 
        ui:draw()  -- This ensures the UI is drawn after everything else
    end
end




function love.draw()
  
  
    if showMenu then
        drawMenu()
    else
        if gameState == "title" then
            drawTitleScreen()
        elseif gameState == "overworld" then
    Overworld.draw()  -- Draw the overworld
        elseif gameState == "playing" then
            drawGame()
            
  -- **Add the red flash effect here**
for _, char in pairs(player.characters) do
    if char.damageFlashTimer > 0 then
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()

        -- Set up the subtle gradient effect with fewer layers and thinner borders
        local numLayers = 5  -- Fewer layers for a thinner effect
        local maxBorderThickness = screenWidth * 0.05  -- Maximum thickness of the borders (5% of screen width)

        for i = 1, numLayers do
            local alpha = 0.4 * (1 - (i / numLayers))  -- Gradually reduce alpha toward the center
            local borderThickness = maxBorderThickness * (i / numLayers)  -- Thinner borders

            -- Top border
            love.graphics.setColor(1, 0, 0, alpha)
            love.graphics.rectangle("fill", 0, 0, screenWidth, borderThickness)

            -- Bottom border
            love.graphics.setColor(1, 0, 0, alpha)
            love.graphics.rectangle("fill", 0, screenHeight - borderThickness, screenWidth, borderThickness)

            -- Left border
            love.graphics.setColor(1, 0, 0, alpha)
            love.graphics.rectangle("fill", 0, 0, borderThickness, screenHeight)

            -- Right border
            love.graphics.setColor(1, 0, 0, alpha)
            love.graphics.rectangle("fill", screenWidth - borderThickness, 0, borderThickness, screenHeight)
        end

        love.graphics.setColor(1, 1, 1)  -- Reset to normal color after the flash
        break  -- Only need to draw the flash once
    end
end

 


            
        elseif gameState == "gameOver" then
            drawGameOverScreen()
        end
        
        -- Draw the DevMenu after drawing the game or title screen
        if DevMenu.isVisible then
            DevMenu.draw()
        end
        
        -- Draw all active damage numbers
        for _, dn in ipairs(damageNumbers) do
            dn:draw()
        end
    end  
end  


function addDamageNumber(x, y, amount)
    local dn = DamageNumber.new(x, y, amount)
    table.insert(damageNumbers, dn)
end

local menuOptions = {
    { text = "Continue", action = function() showMenu = false; gamePaused = false end },
    { text = "Restart", action = function() love.load(); showMenu = false; gamePaused = false end },
    { text = "Quit", action = function() love.event.quit() end },
    { text = "Dev Menu", action = function() 
        showMenu = false  -- Close the escape menu
        DevMenu.toggle()  -- Open the dev menu
        gamePaused = false  -- Ensure the game is not paused
    end }
}



local hoveredOption = nil
local fontSize = 28

function drawMenu()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(fontSize))  -- Set a bigger font

    love.graphics.printf("Pause Menu", 0, 100, love.graphics.getWidth(), "center")

    -- Draw menu options
    local xOffset = love.graphics.getWidth() / 2 - 100
    local yOffset = 150
    local optionHeight = 40  -- Height per menu option (adjustable)

    hoveredOption = nil

    for i, option in ipairs(menuOptions) do
        local isHovered = love.mouse.getX() >= xOffset and love.mouse.getX() <= xOffset + 200
                        and love.mouse.getY() >= yOffset and love.mouse.getY() <= yOffset + optionHeight

        if isHovered then
            love.graphics.setColor(1, 1, 0)  -- Highlight yellow when hovered
            hoveredOption = i  -- Set this option as the hovered one
        else
            love.graphics.setColor(1, 1, 1)  -- Default color
        end

        love.graphics.printf(option.text, 0, yOffset, love.graphics.getWidth(), "center")
        yOffset = yOffset + optionHeight  -- Move down for the next option
    end

    -- Draw unlocked abilities
    drawUnlockedAbilities()
end


function drawUnlockedAbilities()
    local xOffset = 50
    local yOffset = 250

    love.graphics.setFont(love.graphics.newFont(22))  -- Set a slightly smaller font for abilities
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Unlocked Abilities", xOffset, yOffset, love.graphics.getWidth() - 2 * xOffset, "left")
    yOffset = yOffset + 30

    for class, char in pairs(player.characters) do
        if class == "spearwarden" then
            love.graphics.setColor(0, 0.5, 1)  -- Blue for spearwarden
        elseif class == "mage" then
            love.graphics.setColor(1, 0, 0)  -- Red for mage
        elseif class == "ranger" then
            love.graphics.setColor(0, 1, 0)  -- Green for ranger
        end

        love.graphics.printf(class .. " Abilities", xOffset, yOffset, love.graphics.getWidth() - 2 * xOffset, "left")
        yOffset = yOffset + 30

        for abilityName, ability in pairs(char.abilities) do
            local procChance = math.floor((ability.procChance or 0) * 100) .. "%"
            local damage = ability.damageMultiplier and ("Damage Multiplier: " .. ability.damageMultiplier) or ("Damage: " .. char.damage)

            love.graphics.printf(" - " .. abilityName .. ": Proc Chance: " .. procChance .. ", " .. damage, xOffset + 20, yOffset, love.graphics.getWidth() - 2 * xOffset, "left")
            yOffset = yOffset + 25  -- Add extra space between abilities
        end
        yOffset = yOffset + 20  -- Extra space between classes
    end
end



function drawTitleScreen()
    -- Get current screen size
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Draw a dark, gothic background
    love.graphics.setColor(0.05, 0.05, 0.05) -- Dark gray background
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight) -- Now fills entire window

    -- Draw mist particles
    love.graphics.setColor(1, 1, 1, 0.5) -- Semi-transparent white
    love.graphics.draw(mistParticleSystem)

    -- Draw decorative gothic arches (repositioned based on window size)
    love.graphics.setColor(0.7, 0.7, 0.7) -- Light gray for arches
    local archWidth = screenWidth / 5  -- Scale arches based on screen width
    local archHeight = screenHeight / 8
    for i = 1, 4 do
        local centerX = archWidth * i
        love.graphics.arc("line", centerX, screenHeight * 0.65, archWidth, math.pi, 0, 100)
    end

    -- Draw ornamental borders
    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.5, 0.5, 0.5) -- Medium gray
    love.graphics.rectangle("line", 50, 50, screenWidth - 100, screenHeight - 100)

    -- Load and set gothic font (already loaded)
    love.graphics.setColor(0.8, 0.2, 0.2) -- Reddish color for title
    love.graphics.setFont(fonts.title)

    -- Draw main title text centered
    love.graphics.printf("VECTOR SOULS", 0, screenHeight * 0.25, screenWidth, "center")

    -- Flashing "Press any key to continue" prompt, also centered
    love.graphics.setFont(fonts.prompt)
    local alpha = (math.sin(love.timer.getTime() * 2) + 1) / 2 -- Oscillates between 0 and 1
    love.graphics.setColor(1, 1, 1, alpha) -- White color with variable alpha
    love.graphics.printf("Press enter to start", 0, screenHeight * 0.8, screenWidth, "center")
end



function love.keypressed(key)
    if gameState == "title" then
        if key == "return" or key == "space" then
            gameState = "overworld"  -- Move to the overworld map instead of directly to the game
        elseif key == "escape" then
            love.event.quit()
        end

    elseif gameState == "overworld" then
        Overworld.keypressed(key)  -- Handle input for overworld navigation

    elseif gameState == "playing" then
        if key == "escape" then
            -- Toggle the escape/pause menu
            showMenu = not showMenu
            gamePaused = showMenu  -- Only pause the game if the escape menu is up, not the DevMenu
        end

        -- If escape menu is open, allow navigation using the keyboard
        if showMenu then
            if key == "1" then
                menuOptions[1].action()  -- Continue game
            elseif key == "2" then
                menuOptions[2].action()  -- Restart game
            elseif key == "3" then
                menuOptions[3].action()  -- Quit game
            elseif key == "4" then
                -- Toggle the dev menu (and close the escape menu)
                DevMenu.toggle()
                showMenu = false  -- Close the escape menu
                gamePaused = false  -- Resume the game
            end
        else
            -- Allow player movement and actions even if the DevMenu is open
            if not showMenu then
                -- Only call keypressed if it's defined for the player object
                if player and player.keypressed then
                    player:keypressed(key)
                end
            end
        end

        -- Handle DevMenu key presses if visible
        if DevMenu.isVisible then
            DevMenu.handleKeyPress(key)
        end
    elseif gameState == "gameOver" then
        if key == "return" or key == "space" then
            love.load() -- Restart the game
        elseif key == "escape" then
            love.event.quit()
        end
    end

    -- Toggle the dev menu with F1 without pausing the game
    if key == "f1" then
        DevMenu.toggle()
    end
end


function startGame()
    gameState = "playing"
    math.randomseed(os.time())
    
    -- Initialize elements
    damageNumbers = {}
    effects = {}
    maze = Maze.new()
    player = Player.new()


    -- Set current level to maze for spawning purposes
    currentLevel = maze

    -- Safeguard: Ensure summonedEntities is initialized
    player.summonedEntities = player.summonedEntities or {}

    enemies = {}
    spawnTimer = 0
    spawnInterval = 1

    -- Initialize experience and UI
    experience = Experience.new(player)
    player.experience = experience
    ui = UI.new(player, experience)

    -- Game states
    gamePaused = false
    gameOver = false
    gameWon = false

    -- Boss settings
    bossLevels = {10, 20, 30}
    nextBossLevel = 1
    bossSpawned = false

    -- Maximum number of enemies
    maxEnemies = 50
end






function love.mousepressed(x, y, button)
    if gameState == "overworld" then
        Overworld.mousepressed(x, y, button)
    elseif gameState == "playing" and showMenu then
        -- Handle menu option selection with a mouse click
        if button == 1 and hoveredOption then
            menuOptions[hoveredOption].action()  -- Perform the action for the selected menu option
        end
    elseif gameState == "playing" then
        if button == 1 and DevMenu.isVisible then
            -- Handle clicks in the DevMenu while the game is running
            DevMenu.handleMouseClick(x, y)
        elseif button == 1 and ui.upgradeOptionsVisible then
            ui:mousepressed(x, y, button)
        elseif button == 2 then  -- Right-click (button 2) for moving characters
            -- Move all characters to a clicked location with some variation to prevent overlap
            local clickX = x + cameraX
            local clickY = y + cameraY
            player:setAllDestinations(clickX, clickY)
        end
    end
end








function spawnBoss()
    -- Spawn the vampire boss at a specific location
    local bossX, bossY = 2000, 2000 -- Center of the map
    table.insert(enemies, Enemy.new("vampire_boss", bossX, bossY))
    -- Play boss spawn sound
    if sounds.bossSpawn then
        sounds.bossSpawn:play()
    end
end

function handleCollisions()
    -- Ensure damageNumbers and effects are properly updated
    if not damageNumbers or not effects then
        return
    end

    -- Handle collisions between player projectiles and enemies
    for i = #player.projectiles, 1, -1 do
        local proj = player.projectiles[i]
        for j = #enemies, 1, -1 do
            local enemy = enemies[j]
            if Collision.checkCircle(proj.x, proj.y, proj.radius, enemy.x, enemy.y, enemy.radius) then
                if not (enemy.type == "vampire_boss" and enemy.abilities.isInvisible) then
                    enemy:takeDamage(proj.damage, damageNumbers, effects, proj.sourceType)
                    addDamageNumber(enemy.x, enemy.y, proj.damage)
                    player:applyAbilityEffects(proj, enemy, enemies, effects)
                    table.insert(effects, Effects.new("hit_spark", enemy.x, enemy.y))
                end
                table.remove(player.projectiles, i)
                break
            end
        end
    end

    -- **Handle collisions between enemy projectiles and player characters**
    for _, enemy in ipairs(enemies) do
        if enemy.projectiles then
            for i = #enemy.projectiles, 1, -1 do
                local proj = enemy.projectiles[i]
                for _, char in pairs(player.characters) do
                    if char.health > 0 then
                        local isCollision = Collision.checkCircle(proj.x, proj.y, proj.radius, char.x, char.y, char.radius)
                        print("Collision check for " .. char.type .. ": " .. tostring(isCollision))

                        if isCollision then
                            print("Collision detected with " .. char.type)
                            char.health = char.health - proj.damage
                            print("Collision damage: " .. char.type .. " takes " .. proj.damage .. " damage, remaining health: " .. char.health)

                            if char.health < 0 then
                                char.health = 0
                            end
                            -- Apply status effect if applicable
                            if proj.statusEffect then
                                char:applyStatusEffect(proj.statusEffect)
                            end
                            table.remove(enemy.projectiles, i)
                            break
                        end
                    end
                end
            end
        end
    end
end

