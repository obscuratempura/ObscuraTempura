-- MAIN.LUA

-- Initialize global tables
currentMusic = nil
damageNumbers = {}  
effects = {}
summonedEntities = {}
enemies = {}  
items = {}  
experienceGems = {}
bosses = {}         
showMenu = false
foodItems = {}
soulPickups = {}
npcs = {}

local timer = require("timer")
local Player = require("player")
local Enemy = require("enemy")
local EnemyPool = require("enemyPool") -- <<< ADD THIS REQUIRE
local Bonepit = require("bonepit")
local UI = require("ui")
local Experience = require("experience")
local Collision = require("collision")
local Effects = require("effects")
local DamageNumber = require("damage_number")
local DevMenu = require("devmenu")
local Overworld = require("overworld")
_G.Overworld = Overworld 
local Overworld_Effects = require("overworld_effects")
local Config = require("config")
local Debug = require("debug")
local ExperienceGem = require("experience_gem")
local Sprites = require("sprites")
local GameState = require("gameState")
local Abilities = require("abilities")
local Food = require("food")
local talentSystem = require("talentSystem")  -- 
local StatsSystem = require("stats_system")
local statsSystem = StatsSystem.new()
local Equipment   = require("equipment")
local Item        = require("item")
local RandomItems = require("random_items")
local statWindow      = require("stat_window")

local Settings = require("settings")
local MainMenu = require("mainmenu")
local Options = require("options")
local fadeTransition = require("fadeTransition")
local gameState = GameState.new()

local Dialog = require("dialog")
dialog = Dialog.new(gameState)

equipment   = Equipment.new()

-- >> ADDED: Tutorial Completion Flag
_G.tutorialCompleted = false -- Global flag, default to false
local TUTORIAL_FLAG_FILE = "tutorial_completed.flag"
-- << END ADDED

-- >> ADDED: Functions to manage tutorial completion flag
local function checkTutorialCompletion()
    local info = love.filesystem.getInfo(TUTORIAL_FLAG_FILE)
    if info and info.type == "file" then
        local content, size = love.filesystem.read(TUTORIAL_FLAG_FILE)
        if content == "true" then
            _G.tutorialCompleted = true
            print("[Main] Tutorial previously completed.")
        else
            _G.tutorialCompleted = false
            print("[Main] Tutorial flag file found but content is not 'true'.")
        end
    else
        _G.tutorialCompleted = false
        print("[Main] Tutorial flag file not found. Assuming first playthrough.")
    end
end

local function markTutorialCompleted()
    if not _G.tutorialCompleted then
        love.filesystem.write(TUTORIAL_FLAG_FILE, "true")
        _G.tutorialCompleted = true
        print("[Main] Tutorial marked as completed.")
    end
end
-- << END ADDED

-- Add near top with other globals
local levelEndedName = nil -- Store the name of the level that just ended

-- Timers, particles
local gameOverFadeTimer = 0
local gameOverFadeDuration = 1
local gameOverTimer = 0
local bloodParticleSystem = nil
local deathScale = 1
local deathRotation = 0

-- Camera
cameraX, cameraY = 0, 0
local shakeDuration = 0
local shakeMagnitude = 0

-- Fonts
local damageFont
fonts = {}

-- Logo screen variables
local logoImage
local logoSound
local logoTimer = 0

-- Define phases
local logoPhase = "wait_before_fade_in"

-- Define durations (in seconds)
local waitBeforeFadeIn = 1        -- Initial wait
local fadeInDuration = 4          -- Fade-in duration
local fadeOutDuration = 4         -- Fade-out duration
local waitAfterFadeOut = 1      -- Final wait after fade-out





-- Souls system variables
souls = {
    current = 0,
    max = 1,  -- Updated to require only 1 soul for the first level-up
    level = 1,
}

bonusSouls = 0




MainMenu.setGameState(gameState)

promptFont = love.graphics.newFont("fonts/gothic.ttf", 24)
arrowImage = love.graphics.newImage("assets/arrow.png")
colorPalette = {
    {1, 1, 0, 1},
    {0, 1, 1, 1},
    {1, 0, 1, 1},
    {1, 0.5, 0, 1},
    {0.5, 0, 1, 1},
}

local cursorImage, cursorQuads = nil, {}

function loadCursor()
  cursorImage = love.graphics.newImage("assets/cursor.png")
  -- Assume the image has two frames horizontally (total width = 32, height = 16)
  cursorQuads[1] = love.graphics.newQuad(0, 0, 16, 16, cursorImage:getDimensions())
  cursorQuads[2] = love.graphics.newQuad(16, 0, 16, 16, cursorImage:getDimensions())
  love.mouse.setVisible(false)  -- hide the system cursor
end



-- Helper function to profile a section of code.
local function profileSection(name, callback, threshold)
    local startTime = love.timer.getTime()
    callback()
    local elapsed = love.timer.getTime() - startTime
    if elapsed > (threshold or 0.005) then  -- Default threshold is 5ms
        print(string.format("[PROFILE] %s took %.4f seconds", name, elapsed))
    end
end


function love.load()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
   
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("Revenants & Realms")
    love.window.setMode(800, 600, { resizable = true, minwidth = 800, minheight = 600 })
    damageFont = love.graphics.newFont("fonts/gothic.ttf", 16)
    love.window.maximize()
    love.graphics.setFont(damageFont)
    
    lighting = require("lighting")
    lighting.load()


    effects = {}
    math.randomseed(os.time())

    -- Set initial game state to logo
    gameState:setState("logo")


    sounds = {}
    loadSounds()

    createMistParticles()

    fonts.title = love.graphics.newFont("fonts/gothic.ttf", 64)
    fonts.prompt = love.graphics.newFont("fonts/gothic.ttf", 24)
    fonts.gameOver = love.graphics.newFont("fonts/gothic.ttf", 128)
    
    Overworld.init()
    Overworld_Effects.init(Overworld.nodes)

    currentLevel = Bonepit.new()
   
    
    

 

    -- Load logo and sound for logo screen
    logoImage = love.graphics.newImage("assets/obscura.png")
    logoSound = love.audio.newSource("assets/sounds/music/obscura.wav", "static")
    
     loadCursor()

    -- >> ADDED: Check tutorial completion on load
    checkTutorialCompletion()
    -- << END ADDED

    -- IMPORTANT: Register Enemy methods with the EnemyPool <<< ADD THIS BLOCK
    EnemyPool.registerEnemyMethods(Enemy.new, Enemy.reset)

    -- Optional: Prewarm pools after registration
    EnemyPool.prewarm("spider", 20)
    EnemyPool.prewarm("web", 10)
    -- ... prewarm other types ...
end

function love.resize(w, h)
end

function playMusic(musicPath, volume)
    if not musicPath or not love.filesystem.getInfo(musicPath) then
       
        return
    end

    if currentMusic and currentMusic:isPlaying() then
        currentMusic:stop()
    end

    currentMusic = love.audio.newSource(musicPath, "stream")
    currentMusic:setLooping(true)
    currentMusic:setVolume(volume or 0.5)
    currentMusic:play()

end

function stopMusic()
    if currentMusic and currentMusic:isPlaying() then
        currentMusic:stop()
    end
    currentMusic = nil
end

function createBloodParticles()
    local bloodImagePath = "assets/blood.png"
    if love.filesystem.getInfo(bloodImagePath) then
        local bloodImage = love.graphics.newImage(bloodImagePath)
        bloodImage:setFilter("nearest", "nearest")

        bloodParticleSystem = love.graphics.newParticleSystem(bloodImage, 1000)
        bloodParticleSystem:setEmissionRate(500)
        bloodParticleSystem:setParticleLifetime(2, 5)
        bloodParticleSystem:setSizes(1, 2, 3)
        bloodParticleSystem:setSpeed(100, 200)
        bloodParticleSystem:setLinearAcceleration(-50, 300, 50, 400)
        bloodParticleSystem:setColors(173/255, 64/255, 48/255, 1, 173/255, 64/255, 48/255, 0)
        bloodParticleSystem:setSpread(math.rad(360))
        bloodParticleSystem:setDirection(math.rad(90))
        bloodParticleSystem:setEmissionArea("normal", love.graphics.getWidth(), 0, 0, true)
        bloodParticleSystem:stop()
       
    else
      
    end
end

function addDamageNumber(x, y, amount, color, isCrit)
    local dn = DamageNumber.new(x, y, amount, color, isCrit)
    table.insert(damageNumbers, dn)
end
_G.addDamageNumber = addDamageNumber


function createMistParticles()
    local mistImagePath = "mist.png"
    if love.filesystem.getInfo(mistImagePath) then
        mistImage = love.graphics.newImage(mistImagePath)
        mistParticleSystem = love.graphics.newParticleSystem(mistImage, 500)
        mistParticleSystem:setParticleLifetime(5, 10)
        mistParticleSystem:setEmissionRate(50)
        mistParticleSystem:setSizeVariation(0.5)
        mistParticleSystem:setLinearAcceleration(-20, -20, 20, 20)
        mistParticleSystem:setColors(255, 255, 255, 100, 255, 255, 255, 0)
        mistParticleSystem:setEmissionArea("normal", 400, 300, 0, true)
        mistParticleSystem:setDirection(math.rad(0))
        mistParticleSystem:setSpread(math.rad(360))
        mistParticleSystem:setSpeed(10, 20)
        mistParticleSystem:setSizes(1, 2, 3)
        mistParticleSystem:setSpin(0, 0)
        mistParticleSystem:setPosition(400, 300)
        mistParticleSystem:setRelativeRotation(false)
        mistParticleSystem:emit(100)
     
    else
    
    end
end

function loadSounds()
    local function loadSound(path, mode)
        if love.filesystem.getInfo(path) then
            return love.audio.newSource(path, mode)
        else
           
            return nil
        end
    end

    -- Existing sound loads...
    sounds.gameOver = loadSound("gameover.mp3", "static")
    
    sounds.mimic = {
    loadSound("assets/sounds/effects/mimic.wav", "static"),
    loadSound("assets/sounds/effects/mimic2.wav", "static")
}

    
    sounds.enemyAttack = {
        beholder = {
            loadSound("/assets/sounds/effects/enemies/beholderattack1.wav", "static"),
            loadSound("/assets/sounds/effects/enemies/beholderattack2.wav", "static"),
        }
    }

    sounds.enemyDeath = {
      
        skeleton = loadSound("/assets/sounds/effects/enemies/skeleton_death.wav", "static"),
        bat = loadSound("/assets/sounds/effects/enemies/bat_death.wav", "static"),
        beholder = loadSound("/assets/sounds/effects/enemies/beholderdeath.wav", "static"),
        
        spirit = {
            loadSound("spirit_death.wav", "static"),
            loadSound("spirit_death2.wav", "static"),
        },
        
         spider = {
            loadSound("/assets/sounds/effects/enemies/spider_death.wav", "static"),
            loadSound("/assets/sounds/effects/enemies/spider_death2.wav", "static"),
        },
        
        elite_spider = loadSound("/assets/sounds/effects/enemies/elite_spider_death.wav", "static"),
        golem = loadSound("/assets/sounds/effects/enemies/golemdeath.wav", "static"),
       kristoff = loadSound("assets/sounds/effects/enemies/kristoffdeath.wav", "static"),
        
        
        pumpkin = {
        loadSound("/assets/sounds/effects/enemies/pumpkindeath1.wav", "static"),
        loadSound("/assets/sounds/effects/enemies/pumpkindeath2.wav", "static"),
    },
    }

    sounds.playerAttack = {
        Grimreaper = loadSound("/assets/sounds/effects/Grimreaper_attack.wav", "static"),
        mage = loadSound("/assets/sounds/effects/emberfiend_attack.wav", "static"),
        Stormlich = loadSound("/assets/sounds/effects/Stormlich_attack.wav", "static"),
    }

       sounds.ability = {
        ignite = loadSound("/assets/sounds/effects/ignite.wav", "static"),
        soulblades = loadSound("/assets/sounds/effects/soulblades.wav", "static"),
        summon_goyle = loadSound("/assets/sounds/effects/summon_goyle.wav", "static"),
        explosion = loadSound("/assets/sounds/effects/explosion.wav", "static"),
        storm_arc = loadSound("/assets/sounds/effects/storm_arc.wav", "static"),
        Hellblast = loadSound("/assets/sounds/effects/freezinghellblast.wav", "static"),
        zephyrShield = loadSound("/assets/sounds/effects/zephyr_shield.wav", "static"),
        infernal_Rain = loadSound("/assets/sounds/effects/infernalrain.wav", "static"),
        poison = loadSound("/assets/sounds/effects/poison.wav", "static"),
        thunder_toss = loadSound("/assets/sounds/effects/thunder_toss.wav", "static")
    }

    sounds.summonPhantom = loadSound("assets/sounds/effects/summon_phantom.wav", "static")
    sounds.summonPhantom2 = loadSound("assets/sounds/effects/summon_phantom2.wav", "static")


    sounds.gemPickup = loadSound("gem_pickup.wav", "static")
    sounds.bossSpawn = loadSound("boss_spawn.wav", "static")

    -- **Load New Sounds**
    sounds.mainMenuMusic = loadSound("assets/sounds/music/moonlit_shadows.wav", "stream")
    sounds.cursor = loadSound("assets/sounds/effects/cursor.wav", "static")
    sounds.menuselection = loadSound("assets/sounds/effects/menuselection.wav", "static")
    
    sounds.foodPickup = loadSound("/assets/sounds/effects/gulp.wav", "static")
    
    sounds.eliteSpiderSpawn = {
    loadSound("assets/sounds/effects/enemies/elitespider1.wav", "static"),
    loadSound("assets/sounds/effects/enemies/elitespider2.wav", "static"),
    loadSound("assets/sounds/effects/enemies/elitespider3.wav", "static"),
    loadSound("assets/sounds/effects/enemies/elitespider4.wav", "static"),
    loadSound("assets/sounds/effects/enemies/elitespider5.wav", "static")
}

    sounds.kristoffSpawn = {
    loadSound("assets/sounds/effects/enemies/kristoff1.wav", "static"),
    loadSound("assets/sounds/effects/enemies/kristoff2.wav", "static"),
    loadSound("assets/sounds/effects/enemies/kristoff3.wav", "static"),
    loadSound("assets/sounds/effects/enemies/kristoff4.wav", "static")
}


  
    ----------------------------------------------------------
    -- CATEGORIZE INTO MUSIC AND EFFECTS
    ----------------------------------------------------------
    sounds.musicSources = {}
    sounds.effectSources = {}

    -- mainMenuMusic and gameOver considered music
    if sounds.mainMenuMusic then table.insert(sounds.musicSources, sounds.mainMenuMusic) end
    if sounds.gameOver then table.insert(sounds.musicSources, sounds.gameOver) end

    -- Everything else is effects
    if sounds.cursor then table.insert(sounds.effectSources, sounds.cursor) end
    if sounds.menuselection then table.insert(sounds.effectSources, sounds.menuselection) end
    if sounds.gemPickup then table.insert(sounds.effectSources, sounds.gemPickup) end
    if sounds.bossSpawn then table.insert(sounds.effectSources, sounds.bossSpawn) end
      if sounds.foodPickup then table.insert(sounds.effectSources, sounds.foodPickup) end

    for enemyType, snd in pairs(sounds.enemyDeath) do
        if type(snd) == "table" then
            for _, s in ipairs(snd) do
                if s then table.insert(sounds.effectSources, s) end
            end
        else
            if snd then table.insert(sounds.effectSources, snd) end
        end
    end

    for _, s in pairs(sounds.playerAttack) do
        if s then table.insert(sounds.effectSources, s) end
    end

    for _, s in pairs(sounds.ability) do
        if s then table.insert(sounds.effectSources, s) end
    end
end






function love.update(dt)
    timer.update(dt)
  
    -- Wrap Mist Particle Update
    profileSection("Mist Particle Update", function()
        if mistParticleSystem then
            mistParticleSystem:update(dt)
        end
    end, 0.001)

    local currentState = gameState:getState()
    -- local previousState = gameState:getPreviousState() -- REMOVE THIS LINE (Line 461)

    -- >> REMOVED: Mark tutorial complete check here, moved to score screen transition
    -- if currentState == "overworld" and previousState == "playing" then
    --     -- ... removed logic ...
    -- end
    -- << END REMOVED

    if currentState == "logo" then
        profileSection("Logo Update", function()
            logoTimer = logoTimer + dt
            if logoPhase == "wait_before_fade_in" then
                if logoTimer >= waitBeforeFadeIn then
                    logoPhase = "fade_in"
                    logoTimer = logoTimer - waitBeforeFadeIn
                    logoSound:play()  -- Play sound at the start of fade-in
                end
            elseif logoPhase == "fade_in" then
                if logoTimer >= fadeInDuration then
                    logoPhase = "fade_out"
                    logoTimer = logoTimer - fadeInDuration
                end
            elseif logoPhase == "fade_out" then
                if logoTimer >= fadeOutDuration then
                    logoPhase = "wait_after_fade_out"
                    logoTimer = logoTimer - fadeOutDuration
                end
            elseif logoPhase == "wait_after_fade_out" then
                if logoTimer >= waitAfterFadeOut then
                    gameState:setState("mainmenu")
                    MainMenu.load()
                end
            end
        end, 0.001)
    elseif currentState == "mainmenu" then
        profileSection("Main Menu Update", function()
            MainMenu.update(dt)
        end, 0.001)
    elseif currentState == "overworld" then
        profileSection("Overworld Update", function()
            Overworld.update(dt)
        end, 0.001)
    elseif currentState == "playing" then
        profileSection("Playing State Update", function()
            -- Handle music
            if currentLevel and currentLevel.musicPath and (not currentMusic or currentMusicPath ~= currentLevel.musicPath) then
                playMusic(currentLevel.musicPath)
                currentMusicPath = currentLevel.musicPath
            end

            -- Create player if missing
            if not player then
                startGame()
            end

            -- Wrap game updates
            profileSection("Game Logic Update", function()
                -- Only update game logic if not paused AND no dialog is active
                if not gameState.gamePaused and not gameState.isLevelingUp and not (_G.dialog and _G.dialog.active) then
                    updateGame(dt) -- Updates game objects, timers, etc.
                    -- handleCollisions() -- Moved inside updateGame or called after it
                end
            end, 0.001)

            -- Update things that should run even during dialog (like cooldowns, maybe animations)
            profileSection("Dialog-Independent Updates", function()
                -- Update player cooldowns
                if player and player.characters then
                    for _, char in pairs(player.characters) do Abilities.updateCooldowns(char, dt) end
                end
                for _, entity in ipairs(summonedEntities) do
                    if entity and entity.abilities then Abilities.updateCooldowns(entity, dt) end
                end
                if player and talentSystem.updateTalents then talentSystem.updateTalents(player, dt) end

                -- Update damage numbers (visual effect)
                for i = #damageNumbers, 1, -1 do
                    damageNumbers[i]:update(dt)
                    if damageNumbers[i].toRemove then table.remove(damageNumbers, i) end
                end
                while #damageNumbers > 100 do table.remove(damageNumbers, 1) end

                -- Update sprite animations
                if Sprites and Sprites.updateAnimations then Sprites.updateAnimations(dt) end

                -- Update random items floating text and lifetime (visuals/cleanup)
                if _G.randomItems then _G.randomItems:update(dt) end

            end, 0.001)


            -- Level state transitions (if applicable)
            profileSection("Level Transition Check", function()
                if currentLevel and currentLevel.handleStateTransition then
                    currentLevel:handleStateTransition()
                end
            end, 0.001)
        end, 0.001)
    elseif currentState == "gameOver" then
        profileSection("GameOver Update", function()
            if gameOverFadeTimer < gameOverFadeDuration then
                gameOverFadeTimer = gameOverFadeTimer + dt
                deathScale = deathScale + (dt * 1.0)
                deathRotation = deathRotation + (dt * 2.0)
            end
            gameOverTimer = gameOverTimer + dt
            if bloodParticleSystem then
                bloodParticleSystem:update(dt)
            end
            if gameOverTimer >= 30 then
                -- >> Store level name before transitioning
                if currentLevel and currentLevel.currentLevel then
                    levelEndedName = currentLevel.currentLevel
                else
                    levelEndedName = nil
                end
                -- << End Store
                gameState:setState("scoreScreen")
                if bloodParticleSystem then
                    bloodParticleSystem:stop()
                end
                showScoreScreen()
                endOfRunCleanup()
            end
        end, 0.001)
    end

    -- Wrap Camera Update
    profileSection("Camera Update", function()
        updateCamera(dt)
    end, 0.003)

    -- (Optionally add more wrappers for any other update sections)

    -- End of love.update profiling
    if dialog then
        dialog:update(dt)
    end

    fadeTransition.update(dt)
end



function updateGame(dt)
    -- Update the current level logic (spawning, timers, etc.)
    if currentLevel and currentLevel.update then
        currentLevel:update(dt)
        if currentLevel:isCompleted() then
            -- Calculate final score
            statsSystem:calculateFinalScore()
            statsSystem:printStats() -- For debugging
            -- Trigger score screen with finalScore
            showScoreScreen()
            -- Transition to overworld or next level
            gameState:setState("scoreScreen") -- New state for the score screen
        end
    end

    -- Update experience gems (movement)
    for i = #experienceGems, 1, -1 do
        local gem = experienceGems[i]
        if gem and gem.update then
            gem:update(dt, player.characters)
            -- Removal happens in collision check
        end
    end

    -- Update soul pickups (movement)
    for i = #soulPickups, 1, -1 do
        local soul = soulPickups[i]
        soul:update(dt, player.characters)
        -- Removal happens in collision check
    end

    -- Update food items (movement)
    for i = #foodItems, 1, -1 do
        local f = foodItems[i]
        f:update(dt, player.characters)
        -- Removal happens in collision check
    end

    -- Update player (movement, attacks, status effects)
    if player and player.update then
        player:update(dt, enemies, effects, Bonepit.zoomFactor) -- Assuming Bonepit.zoomFactor is still relevant
    end
    if player and player.characters and player.characters.Stormlich and player.characters.Stormlich.activeBlizzards then
        Abilities.updateBlizzards(player.characters.Stormlich, dt)
    end

    -- Update summoned entities
    if player and player.summonedEntities then
        for i = #player.summonedEntities, 1, -1 do
            local entity = player.summonedEntities[i]
            if entity and entity.update then
                entity:update(dt, enemies, effects, player.summonedEntities)
                if entity.isDead then table.remove(player.summonedEntities, i) end
            end
        end
    end

    -- Enemy update loop
    local enemyUpdateStart = love.timer.getTime()
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        if enemy and enemy.update then
            -- Pass EnemyPool.acquire as the spawnEnemyFunc argument <<< MODIFY THIS CALL
            enemy:update(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities, currentLevel, cameraZoom, bosses, EnemyPool.acquire)
        end
        -- Death handling and removal
        if enemy and enemy.isDead and not enemy.deathHandled then
            enemy.deathHandled = true
            local deathSounds = sounds.enemyDeath[enemy.type]
            if deathSounds then
                if type(deathSounds) == "table" then
                    local randomIndex = math.random(1, #deathSounds)
                    if deathSounds[randomIndex] then
                        deathSounds[randomIndex]:play()
                    end
                elseif type(deathSounds) == "userdata" then
                    deathSounds:play()
                end
            end
            print(string.format("Spawning Gem Check: Type=%s, Experience=%s, isDead=%s, deathHandled=%s",
                        enemy.type, tostring(enemy.experience), tostring(enemy.isDead), tostring(enemy.deathHandled)))
            spawnExperienceGem(enemy.x, enemy.y, enemy.experience)
            player:addPotionCharge(player.potionFillPerKill)
            enemy.remove = true  -- Mark for removal
        end

        if enemy and enemy.remove then
            EnemyPool.release(enemy) -- <<< ADD THIS LINE TO RELEASE ENEMY
            table.remove(enemies, i)
        end
    end
    -- ... (enemy update profiling) ...

    -- Boss update loop
    for i = #bosses, 1, -1 do
        local boss = bosses[i]
        if boss and boss.update then
             -- Pass EnemyPool.acquire as the spawnEnemyFunc argument <<< MODIFY THIS CALL
            boss:update(dt, player, effects, enemies, damageNumbers, sounds, summonedEntities, currentLevel, cameraZoom, bosses, EnemyPool.acquire)
        end
        -- Death handling and removal
        if boss and boss.isDead and not boss.deathHandled then
            boss.deathHandled = true
            if sounds.enemyDeath[boss.type] then
                sounds.enemyDeath[boss.type]:play()
            end
            spawnExperienceGem(boss.x, boss.y, boss.experience)
            table.remove(bosses, i)
        end
         if boss and boss.remove then
            EnemyPool.release(boss) -- <<< ADD THIS LINE TO RELEASE BOSS
            table.remove(bosses, i)
        end
    end

    -- Update UI elements (HUD)
    if ui and ui.update then
        ui:update(dt)
    end
    -- Update Experience system (leveling up logic, NOT the gems themselves)
    if experience and experience.update then
        experience:update(dt)
    end

    -- Update Effects
    for i = #effects, 1, -1 do
        local effect = effects[i]
        if effect and effect.update then effect:update(dt) end
        if effect and effect.isDead then table.remove(effects, i) end
    end

    for _, effect in ipairs(effects) do
        if effect.type == "unholy_ground" and not effect.isDead then
            effect.damageTimer = effect.damageTimer or 0
            effect.damageTimer = effect.damageTimer + dt
            if effect.damageTimer >= 1.0 then
                effect.damageTimer = effect.damageTimer - 1.0
                for _, enemy in ipairs(enemies) do
                    if not enemy.isDead then
                        local dx = enemy.x - effect.x
                        local dy = enemy.y - effect.y
                        local distSq = dx * dx + dy * dy
                        if distSq <= (effect.radius * effect.radius) then
                            local oldHP = enemy.health
                            enemy:takeDamage(effect.damagePerSecond, damageNumbers, effects, "unholy_ground", nil, "damageOverTime")
                            if enemy.isDead and oldHP > 0 then
                                local rank = (effect.owner.abilities and effect.owner.abilities["Unholy Ground"] and effect.owner.abilities["Unholy Ground"].rank) or 1
                                if effect.talentHolder and effect.talentHolder.goylesAwakeningRank and effect.talentHolder.goylesAwakeningRank >= 1 then
                                    local maxSummons = (rank == 3) and 4 or 3
                                    if #summonedEntities < maxSummons then
                                        local chance = 1 + (rank - 1) * 0.05
                                        if math.random() < chance then
                                            local duration = 10 + rank * 2
                                            local speed = 120 + (rank - 1) * 24
                                            local damageMultiplier = 30 + (rank * 0.1)
                                            Abilities.summongoyle(effect.owner, duration, speed, damageMultiplier, player.summonedEntities, enemies, effects, damageNumbers)
                                            table.insert(effects, Effects.new("summon_goyle", effect.owner.x, effect.owner.y))
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Update player damage flash timer
    if player and player.damageFlashTimer and player.damageFlashTimer > 0 then
        player.damageFlashTimer = player.damageFlashTimer - dt
    end

    -- Player defeat check (moved lower, after updates)
    if player and player:isDefeated() and gameState:getState() == "playing" then
        -- Calculate final score
        statsSystem:calculateFinalScore()
        statsSystem:printStats() -- For debugging
        -- Trigger score screen with finalScore
        stopMusic()
        gameOver = true
        gameState:setState("gameOver")
        gameOverFadeTimer = 0
        gameOverTimer = 0
        Overworld_Effects.stopAllSounds()
        if sounds.gameOver then
            sounds.gameOver:play()
        end
        createBloodParticles()
        if bloodParticleSystem then
            bloodParticleSystem:start()
        end
    end

    handleCollisions()
    updateCamera(dt)
    fadeTransition.update(dt)
end


function spawnExperienceGem(x, y, amount)
    local gem = ExperienceGem.new(x, y, amount)
    table.insert(experienceGems, gem)
    
    local newFood = Food.new(x + math.random(-10,10), y + math.random(-10,10))
    table.insert(foodItems, newFood)
end


local cameraZoom = 1.5

function updateCamera(dt)
    if not player or not player.characters then
        return
    end

    local totalX, totalY = 0, 0
    local charCount = 0

    for _, char in pairs(player.characters) do
    if not player:isDefeated() then
        totalX = totalX + char.x
        totalY = totalY + char.y
        charCount = charCount + 1
    end
end

    if charCount > 0 then
        local avgX = totalX / charCount
        local avgY = totalY / charCount

        local offsetX, offsetY = 0, 0
        if shakeDuration > 0 then
            shakeDuration = shakeDuration - dt
            offsetX = math.random(-shakeMagnitude, shakeMagnitude)
            offsetY = math.random(-shakeMagnitude, shakeMagnitude)
        end

        cameraX = avgX - (love.graphics.getWidth() / (2 * cameraZoom)) + offsetX
        cameraY = avgY - (love.graphics.getHeight() / (2 * cameraZoom)) + offsetY
    end
end

function drawGame()
      love.graphics.push()
    love.graphics.scale(cameraZoom, cameraZoom)
    love.graphics.translate(-cameraX, -cameraY)

    local mapWidth = Config.mapWidth or 0
    local mapHeight = Config.mapHeight or 0
    if mapWidth == 0 or mapHeight == 0 then
        error("Config values for mapWidth or mapHeight are not set!")
    end
    -- Draw background and level first.
    if bgImage then
        local bgX = math.floor(cameraX / mapWidth) * mapWidth
        local bgY = math.floor(cameraY / mapHeight) * mapHeight
        for x = -1, 1 do
            for y = -1, 1 do
                love.graphics.draw(bgImage, bgX + (x * mapWidth), bgY + (y * mapHeight))
            end
        end
    end

    if currentLevel and currentLevel.draw then
        currentLevel:draw(cameraZoom)
    end

    randomItems:draw()
    fadeTransition.draw()

    -- Draw poison web effects (ground layer) first.
    for _, effect in ipairs(effects) do
        if effect and effect.draw and effect.type == "poison_zone" then
            effect:draw()
        end
    end

    -- Draw game objects on top:
    for _, gem in ipairs(experienceGems) do
        if gem and gem.draw then
            gem:draw()
        end
    end

    table.sort(enemies, function(a, b)
      return a:getBottom() < b:getBottom()
    end)
    table.sort(bosses, function(a, b)
      return a:getBottom() < b:getBottom()
    end)

    for _, enemy in ipairs(enemies) do
        if enemy and enemy.draw then
            enemy:draw()
        end
    end
    for _, boss in ipairs(bosses) do
        if boss and boss.draw then
            boss:draw()
        end
    end
    for _, entity in ipairs(player.summonedEntities or {}) do
        if entity and entity.draw then
            entity:draw()
        end
    end

    if player and player.draw then
         player:draw(cameraX, cameraY, cameraZoom)
    end

    if gameState:getState() ~= "gameOver" then
        if player and player.draw then
            player:draw(cameraX, cameraY, cameraZoom)
        end
    end

    for _, proj in ipairs(player.projectiles or {}) do
        if proj and proj.draw then
            proj:draw()
        end
    end

    for _, f in ipairs(foodItems) do
        f:draw()
    end
    for _, soul in ipairs(soulPickups) do
        soul:draw()
    end

    for _, effect in ipairs(effects) do
        if effect and effect.draw and effect.type ~= "poison_zone" then
            effect:draw()
        end
    end

    randomItems:drawFloatingTexts()
    love.graphics.pop()
end


function love.draw()
    local currentState = gameState:getState()

    if currentState == "playing" then
        -- Composite world: draw game world to worldCanvas, add lighting overlay to litCanvas, etc.
        if not worldCanvas or worldCanvas:getWidth() ~= love.graphics.getWidth() or worldCanvas:getHeight() ~= love.graphics.getHeight() then
            worldCanvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
        end
        love.graphics.setCanvas(worldCanvas)
            love.graphics.clear()
            drawGame()  -- Draw world elements (background, level, player, enemies, etc.)
            for _, dmgNum in ipairs(damageNumbers) do
                if dmgNum and dmgNum.draw then
                    dmgNum:draw(cameraX, cameraY, cameraZoom)
                end
            end
        love.graphics.setCanvas()

        lighting.clearLights()
        if player then
            local playerScreenX = (player.x - cameraX) * cameraZoom
            local playerScreenY = (player.y - cameraY) * cameraZoom
            lighting.addLight(playerScreenX, playerScreenY, 500)
        end
        local overlayCanvas = lighting.drawOverlay()  -- Create the dark overlay

        if not litCanvas or litCanvas:getWidth() ~= love.graphics.getWidth() or litCanvas:getHeight() ~= love.graphics.getHeight() then
            litCanvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
        end
        love.graphics.setCanvas(litCanvas)
            love.graphics.clear()
            love.graphics.draw(worldCanvas, 0, 0)
            love.graphics.setBlendMode("multiply", "premultiplied")
            love.graphics.draw(overlayCanvas, 0, 0)
            love.graphics.setBlendMode("alpha")
        love.graphics.setCanvas()

        love.graphics.draw(litCanvas, 0, 0)
        if dialog then
            dialog:draw()
        end

        -- Draw the in–game UI (HUD, etc.).
        if Options.visible then
    love.graphics.setBlendMode("alpha")  -- reset blend mode
    love.graphics.setColor(1, 1, 1, 1)      -- reset color
    love.graphics.origin()                  -- reset transform to screen space
    local popupW, popupH = 600, 400
    local popupX = (love.graphics.getWidth() - popupW) / 2
    local popupY = (love.graphics.getHeight() - popupH) / 2
    Options.draw(popupX, popupY, popupW, popupH, promptFont, colorPalette, arrowImage)
end

        
        if ui and ui.draw then
            ui:draw()
        end

        -- Now, draw the pause menu.
        if showMenu then
            love.graphics.setBlendMode("alpha")  -- Ensure default blend mode.
            love.graphics.setColor(1, 1, 1, 1)      -- Reset color.
            drawMenu()  -- Draw your pause menu.
        end
        
        -- DEBUG: FPS, Enemy Count, and Memory Usage
love.graphics.setColor(1, 1, 1, 1)  -- White text for visibility
local fpsText = "FPS: " .. tostring(love.timer.getFPS())
local enemyCountText = "Enemies: " .. tostring(#enemies)
local memText = "Memory: " .. math.floor(collectgarbage("count")) .. " KB"
local rightMargin = 150  -- Distance from the right edge
local xPos = love.graphics.getWidth() - rightMargin
love.graphics.print(fpsText, xPos, 10)
love.graphics.print(enemyCountText, xPos, 30)
love.graphics.print(memText, xPos, 50)


    elseif currentState == "logo" then
        drawLogoScreen()
    elseif currentState == "mainmenu" then
        love.graphics.setColor(1, 1, 1, 1)
        MainMenu.draw()
    elseif currentState == "overworld" then
        Overworld.draw()
    elseif currentState == "gameOver" then
        drawGameOverScreen()
    elseif currentState == "scoreScreen" then
        ui:drawScoreScreen()
    end

    if DevMenu.isVisible then
        DevMenu.draw()
    end
    
    local mx, my = love.mouse.getPosition()
local frame = love.mouse.isDown(1) and 2 or 1
love.graphics.draw(cursorImage, cursorQuads[frame], mx, my, 0, 2, 2)

    fadeTransition.draw()
end





function drawLogoScreen()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local imgW, imgH = logoImage:getWidth(), logoImage:getHeight()

    -- Calculate opacity based on the current phase and logoTimer
    local opacity = 0

       -- Draw a solid black background
    love.graphics.setColor(0, 0, 0, 1)  -- Black color
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    if logoPhase == "wait_before_fade_in" then
        opacity = 0  -- Fully transparent

    elseif logoPhase == "fade_in" then
        opacity = logoTimer / fadeInDuration  -- Gradually increase opacity from 0 to 1

    elseif logoPhase == "fade_out" then
        opacity = 1 - (logoTimer / fadeOutDuration)  -- Gradually decrease opacity from 1 to 0

    elseif logoPhase == "wait_after_fade_out" then
        opacity = 0  -- Fully transparent
    end

    -- Clamp opacity between 0 and 1
    opacity = math.max(0, math.min(1, opacity))

    -- Apply opacity
    love.graphics.setColor(1, 1, 1, opacity)

    -- Draw the logo centered on the screen
    love.graphics.draw(logoImage, (screenWidth - imgW)/2, (screenHeight - imgH)/2)

    -- Reset color to full opacity for other drawings
    love.graphics.setColor(1, 1, 1, 1)
end



function drawMenu()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(28))
    love.graphics.printf("Pause Menu", 0, 100, love.graphics.getWidth(), "center")

    local xOffset = love.graphics.getWidth() / 2 - 100
    local yOffset = 150
    local optionHeight = 40

    hoveredOption = nil

    for i, option in ipairs(menuOptions) do
        local isHovered = love.mouse.getX() >= xOffset and love.mouse.getX() <= xOffset + 200
                        and love.mouse.getY() >= yOffset and love.mouse.getY() <= yOffset + optionHeight

        if isHovered then
            love.graphics.setColor(1, 1, 0)
            hoveredOption = i
        else
            love.graphics.setColor(1, 1, 1)
        end

        love.graphics.printf(option.text, 0, yOffset, love.graphics.getWidth(), "center")
        yOffset = yOffset + optionHeight
    end

    drawUnlockedAbilities()

    -- draw recently picked abilities
    local picks = player and player.pickedAbilities or {}
    if #picks > 0 then
        local w, h = 250, (#picks * 30) + 20
        local x = love.graphics.getWidth() - w - 20
        local y = (love.graphics.getHeight() - h) / 2
        love.graphics.setColor(0,0,0,0.7)
        love.graphics.rectangle("fill", x, y, w, h, 8,8)
        love.graphics.setColor(1,1,1,1)
        love.graphics.setFont(promptFont)
        for i, name in ipairs(picks) do
            love.graphics.print(name, x + 10, y + 10 + (i-1)*30)
        end
    end
end

function drawUnlockedAbilities()
    if not player or not player.characters then
        return
    end

    local xOffset = 50
    local yOffset = 250

    love.graphics.setFont(love.graphics.newFont(22))
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Unlocked Abilities", xOffset, yOffset, love.graphics.getWidth() - 2*xOffset, "left")
    yOffset = yOffset + 30

    for class, char in pairs(player.characters) do
        if class == "Stormlich" then
            love.graphics.setColor(0, 0.5, 1)
        elseif class == "Emberfiend" then
            love.graphics.setColor(1, 0, 0)
        elseif class == "Grimreaper" then
            love.graphics.setColor(0, 1, 0)
        end

        love.graphics.printf(class .. " Abilities", xOffset, yOffset, love.graphics.getWidth() - 2*xOffset, "left")
        yOffset = yOffset + 30

        for abilityName, ability in pairs(char.abilities) do
            local procChance = math.floor((ability.procChance or 0)*100) .. "%"
            local damage = ability.damageMultiplier and ("Damage Multiplier: " .. ability.damageMultiplier) or ("Damage: " .. char.damage)

            love.graphics.printf(" - " .. abilityName .. ": Proc Chance: " .. procChance .. ", " .. damage, xOffset + 20, yOffset, love.graphics.getWidth() - 2*xOffset, "left")
            yOffset = yOffset + 25
        end
        yOffset = yOffset + 20
    end
end

function drawGameOverScreen()
    if not gameOverSoundPlayed then
        love.audio.stop()
        if sounds and sounds.gameOver then
            sounds.gameOver:play()
       
        end
        gameOverSoundPlayed = true
    end

    damageNumbers = {}

    -- Draw a semi-transparent black overlay
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Draw blood particles over the overlay
    if bloodParticleSystem then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(bloodParticleSystem)
    end

  

    -- Fade in the "DEATH" text
    local alpha = gameOverFadeTimer / gameOverFadeDuration
    if alpha > 1 then alpha = 1 end
    love.graphics.setColor(173/255, 64/255, 48/255, alpha)
    love.graphics.setFont(fonts.gameOver)
    local text = "DEATH"
    local textWidth = fonts.gameOver:getWidth(text)
    local x = (love.graphics.getWidth() - textWidth) / 2
    love.graphics.print(text, x, 40)
    love.graphics.setColor(1, 1, 1, 1)
end





function love.keypressed(key)
    local currentState = gameState:getState()

    if currentState == "logo" then
        if logoSound and logoSound:isPlaying() then
            logoSound:stop()
        end
        gameState:setState("mainmenu")
        MainMenu.load()
        logoTimer = 0
        logoPhase = "wait_before_fade_in"

    elseif currentState == "mainmenu" then
        MainMenu.keypressed(key)
        if key == "escape" then
            love.event.quit()
        end

    elseif currentState == "overworld" then
        Overworld.keypressed(key)

    elseif currentState == "playing" then
        -- If dialog is active, Esc, Enter/Return or left‑click completes/advances it.
        if dialog and dialog.active then
            if key == "escape" or key == "return" then
                dialog:mousepressed(0, 0, 1)
                return
            end
        else
            if currentLevel and currentLevel.keypressed then
                currentLevel:keypressed(key)
            end
        end

    elseif currentState == "gameOver" then
        if gameOverFadeTimer >= gameOverFadeDuration then
            if key == "return" or key == "escape" then
                gameState:setState("scoreScreen")
                if bloodParticleSystem then
                    bloodParticleSystem:stop()
                end
                showScoreScreen()
            end
        end

    elseif currentState == "scoreScreen" then
        if key == "return" or key == "escape" then -- Assuming Enter/Esc continues
             -- >> Check if the ended level was the tutorial
             if levelEndedName == "tutorial" then
                 markTutorialCompleted()
             end
             levelEndedName = nil -- Reset for next time
             -- << End Check
             gameState:setState("overworld")
             -- Optionally stop score screen music, start overworld music
             stopMusic()
        end
        if ui and ui.keypressed then
            ui:keypressed(key)
        end
    end

    if key == "f1" then
        DevMenu.toggle()
    end
end

function startGame(level)
    gameState:setState("playing")
    math.randomseed(os.time())
    damageNumbers = {}
    effects = {}

    print("[startGame] Starting game. Creating player...")
    player = Player.new(statsSystem, persistentEquipment)
    print("[startGame] Player created.")
    Overworld.player = player

    -- … existing setup …
    player = Player.new(statsSystem, persistentEquipment)

    -- ← ADD THIS BLOCK AFTER player = Player.new(...)
    if level.spawnX and level.spawnY then
        player.x, player.y = level.spawnX, level.spawnY
        -- also position each sub‑character
        for _, char in pairs(player.characters) do
            char.x, char.y = level.spawnX, level.spawnY
        end
        cameraX, cameraY = level.spawnX, level.spawnY
    end

    -- … the rest of startGame …

    -- >> MODIFIED: Determine if tutorial scripting should run
    local runTutorialScripting = false
    if level and level.currentLevel == "tutorial" then
        -- Only run scripting if the global flag says tutorial is NOT completed
        runTutorialScripting = not _G.tutorialCompleted
        print("[startGame] Starting Tutorial. Run scripting:", runTutorialScripting)
        -- Pass the flag to the Tutorial constructor
        level:setScripting(runTutorialScripting) -- We'll add this method to Tutorial
    end
    -- << END MODIFIED

    if level then
        currentLevel = level
        -- ... (randomItems setup) ...
        randomItems = level.randomItems
    end

    player.summonedEntities = player.summonedEntities or {}
    enemies = {}

    -- DEBUGGING: Check the level object and triggerManager status
    print("[startGame] Checking level object...")
    if level then
        print("  - Level object exists.")
        print("  - level.currentLevel:", level.currentLevel) -- Check the value
        print("  - level.triggerManager exists?", (level.triggerManager ~= nil)) -- Check if triggerManager is present
    else
        print("  - Level object is nil.")
    end

    -- Only pass the triggerManager if the level is the tutorial AND scripting is enabled
    local tm = nil
    if level and level.currentLevel == "tutorial" and runTutorialScripting then -- << MODIFIED Condition
        print("  - Condition 'level.currentLevel == \"tutorial\" AND runScripting' is TRUE.") -- Confirm condition met
        tm = level.triggerManager
        if tm then
            print("  - TriggerManager instance found and will be passed.")
        else
            print("  - WARNING: level.currentLevel is 'tutorial', but level.triggerManager is nil!")
        end
    else
         if level and level.currentLevel == "tutorial" then
             print("  - Condition 'level.currentLevel == \"tutorial\" AND runScripting' is FALSE (Scripting disabled).")
         else
             print("  - Not the tutorial level.")
         end
    end
    -- END DEBUGGING

    -- Pass the level instance itself along with the trigger manager
    experience = Experience.new(player, tm, level) -- Pass triggerManager (or nil) AND level instance here
    player.experience = experience

    -- Rebuild the UI stat window for the new player.
    ui = UI.new(player, experience, gameState)
    Overworld.statsWindow = statWindow.new(player)

    statsSystem:resetStats(player)
    player:recalculateStats()

    gameState:setPause(false)
    gameState:setLevelingUp(false)
    gameOver = false
    gameWon = false
end


function love.mousepressed(x, y, button)
    local currentState = gameState:getState()
    
    if currentState == "mainmenu" then
        MainMenu.mousepressed(x, y, button)
    elseif currentState == "overworld" then
        Overworld.mousepressed(x, y, button)
    elseif currentState == "playing" then
        -- Dismiss dialog if active
        if button == 1 and dialog and dialog.active then
            dialog:mousepressed(x, y, button)
        end

        if showMenu then
            if button == 1 and hoveredOption then
                menuOptions[hoveredOption].action()
            end
        elseif button == 1 and DevMenu.isVisible then
            DevMenu.handleMouseClick(x, y)
        elseif button == 1 and ui and ui.upgradeOptionsVisible and ui.mousepressed then
            ui:mousepressed(x, y, button)
        end
    elseif currentState == "scoreScreen" then
         if button == 1 then -- Assuming click progresses
             -- >> Check if the ended level was the tutorial
             if levelEndedName == "tutorial" then
                 markTutorialCompleted()
             end
             levelEndedName = nil -- Reset for next time
             -- << End Check
             gameState:setState("overworld")
             stopMusic()
         end
         if ui and ui.mousepressed then ui:mousepressed(x, y, button) end
     end
end


function resetLevel()
   

    damageNumbers = {}
    effects = {}
    summonedEntities = {}
    enemies = {}
    bosses = {}
    experienceGems = {}

    if player then
        player.projectiles = {}
        if player.characters then
            for _, char in pairs(player.characters) do
                char.damageFlashTimer = 0
              
            end
        end
    end

    gameOver = false
    gameWon = false
    gameOverFadeTimer = 0
    gameOverTimer = 0

    if bloodParticleSystem then
        bloodParticleSystem:stop()
        bloodParticleSystem = nil
    end

    cameraX, cameraY = 0, 0
    shakeDuration = 0
    shakeMagnitude = 0

    if ui and ui.reset then
        ui:reset()
    end

    player = nil
  

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)


end

function handleCollisions()
    local overallCollisionStartTime = love.timer.getTime()
    if not player or not player.characters or not damageNumbers or not effects then
        return -- Ensure player exists before proceeding
    end

    local allEnemies = {}
    for _, enemy in ipairs(enemies) do table.insert(allEnemies, enemy) end
    for _, boss in ipairs(bosses) do table.insert(allEnemies, boss) end

    -- 1. Handle Player Projectiles Hitting Enemies and Bosses
    profileSection("Collisions: Player Proj vs Enemies", function()
        if player and player.projectiles then
            for i = #player.projectiles, 1, -1 do
                local proj = player.projectiles[i]
                if proj and not (proj.isEffect or proj.isCustom) then -- Added check for proj existence
                    local projRemoved = false -- Flag to prevent double removal/processing
                    for j = #allEnemies, 1, -1 do
                        local enemy = allEnemies[j]
                        if enemy and enemy.getCollisionData then
                            local cx, cy, r = enemy:getCollisionData()
                            if Collision.checkCircle(proj.x, proj.y, proj.radius, cx, cy, r) then
                                if proj.onHit then
                                    proj:onHit(enemy)
                                else
                                    enemy:takeDamage(proj.damage, damageNumbers, effects, proj.sourceType, nil, "damageTaken")
                                    if player.applyAbilityEffects then
                                        player:applyAbilityEffects(proj, enemy, enemies, effects)
                                    end
                                    table.insert(effects, Effects.new("hit_spark", enemy.x, enemy.y))
                                end
                                -- Remove projectile only if it hasn't been removed already in this inner loop
                                if i <= #player.projectiles and player.projectiles[i] == proj then
                                     table.remove(player.projectiles, i)
                                     projRemoved = true -- Mark as removed
                                end
                                break -- Exit inner loop once hit is registered
                            end
                        end
                    end
                    if projRemoved then goto continue_proj_outer end -- Skip to next projectile if removed
                end
                ::continue_proj:: -- Original label, might be redundant now but kept for safety
            end
            ::continue_proj_outer:: -- Label to jump to after removing a projectile
        end
    end, 0.002) -- Use a lower threshold if needed

    -- 2. Handle Experience Gems Collection
    profileSection("Collisions: Gem Collection", function()
        for k = #experienceGems, 1, -1 do
            local gem = experienceGems[k]
            local collected = false
            if gem and player and player.characters then -- Added gem existence check
                for _, char in pairs(player.characters) do
                    if not player:isDefeated() then
                        -- Use gem's radius and char's radius
                        if Collision.checkCircle(gem.x, gem.y, gem.radius or 5, char.x, char.y, char.radius or 16) then
                            if experience and experience.addExperience then experience:addExperience(gem.amount) end
                            if sounds.gemPickup then sounds.gemPickup:play() end
                            if statsSystem and statsSystem.addExperience then statsSystem:addExperience(gem.amount) end
                            collected = true
                            break
                        end
                    end
                end
            end
            if collected then
                -- ... (vital surge check could go here if needed) ...
                table.remove(experienceGems, k)
            end
        end
    end, 0.002)

    -- 2.5 Handle Random Item Collection
    profileSection("Collisions: Random Item Collection", function()
        if _G.randomItems then
            _G.randomItems:checkCollisions()
        end
    end, 0.002)

    -- 2.7 Handle Soul Pickups Collection
    profileSection("Collisions: Soul Collection", function()
        for i = #soulPickups, 1, -1 do
            local soul = soulPickups[i]
            if soul and soul.pickupDelay <= 0 then -- Added soul existence check
                local collected = false
                if player and player.characters then
                    for _, char in pairs(player.characters) do
                        -- Use soul's radius and char's radius for collision
                        if Collision.checkCircle(soul.x, soul.y, soul.radius or 8, char.x, char.y, char.radius or 16) then
                            addSouls(1)
                            bonusSouls = bonusSouls + 1
                            if _G.randomItems then -- Check if randomItems exists
                                _G.randomItems:addFloatingText(soul.x, soul.y, "1 SOUL", {0, 1, 1})
                            end

                            -- *** TRIGGER SOUL EXPLANATION DIALOG ***
                            if currentLevel and currentLevel.currentLevel == "tutorial" and currentLevel.triggerManager then
                                currentLevel.triggerManager:try("soulExplanation")
                            end
                            -- ****************************************

                            collected = true
                            break -- Stop checking characters once collected
                        end
                    end
                end
                if collected then
                    table.remove(soulPickups, i)
                end
            end
        end
    end, 0.002)

    -- 3. Handle Food Items Collection
    profileSection("Collisions: Food Collection", function()
        for i = #foodItems, 1, -1 do
            local f = foodItems[i]
            local collected = false
            if f and player and player.characters then -- Added food existence check
                for _, char in pairs(player.characters) do
                    -- Use food's radius and char's radius
                    if Collision.checkCircle(f.x, f.y, f.radius or 8, char.x, char.y, char.radius or 16) then
                        f:applyRandomEffect(player)
                        f.toRemove = true -- Mark for removal (though it's removed immediately after)
                        collected = true
                        if sounds.foodPickup then sounds.foodPickup:play() end
                        break
                    end
                end
            end
            if collected then
                table.remove(foodItems, i) -- Remove here after loop iteration
            end
        end
    end, 0.002)

    -- 4. Handle Enemy Projectiles Hitting Players
    profileSection("Collisions: Enemy Proj vs Player", function()
        for _, enemy in ipairs(allEnemies) do
            if enemy and enemy.projectiles then -- Added enemy existence check
                for l = #enemy.projectiles, 1, -1 do
                    local proj = enemy.projectiles[l]
                    if proj and player and player.characters then -- Added proj and player checks
                        local projRemoved = false -- Flag for removal
                        for _, char in pairs(player.characters) do
                            if not player:isDefeated() then
                                if Collision.checkCircle(proj.x, proj.y, proj.radius, char.x, char.y, char.radius) then
                                    player._teamHealth = player._teamHealth - proj.damage
                                    if player._teamHealth < 0 then
                                        player._teamHealth = 0
                                    end

                                    if proj.statusEffect and char.applyStatusEffect then
                                        char:applyStatusEffect(proj.statusEffect)
                                    end

                                    -- Apply effects before removing projectile
                                    Abilities.applyEffects(proj, char, enemy, allEnemies, effects, sounds, summonedEntities, damageNumbers, "damageTaken")

                                    -- Remove projectile only if it hasn't been removed already
                                    if l <= #enemy.projectiles and enemy.projectiles[l] == proj then
                                        table.remove(enemy.projectiles, l)
                                        projRemoved = true
                                    end
                                    break -- Exit character loop once hit
                                end
                            end
                        end
                        if projRemoved then goto continue_enemy_proj_outer end -- Skip to next projectile if removed
                    end
                end
                ::continue_enemy_proj_outer:: -- Label to jump to after removing an enemy projectile
            end
        end
    end, 0.002)

    -- 5. Enemy-to-Enemy Collision Resolution
    profileSection("Collisions: Enemy vs Enemy Separation", function()
        for i = 1, #allEnemies do
            for j = i + 1, #allEnemies do
                local enemy1 = allEnemies[i]
                local enemy2 = allEnemies[j]

                -- Ensure both enemies exist before proceeding
                if not enemy1 or not enemy2 then goto continue_enemy_collision end

                local layer1 = enemy1:getCollisionLayer()
                local layer2 = enemy2:getCollisionLayer()

                -- Skip separation if either enemy is a web.
                if layer1 == "Web" or layer2 == "Web" then
                    goto continue_enemy_collision
                end

                -- Ensure collision data methods exist
                if not enemy1.getCollisionData or not enemy2.getCollisionData then
                    goto continue_enemy_collision
                end

                local cx1, cy1, r1 = enemy1:getCollisionData()
                local cx2, cy2, r2 = enemy2:getCollisionData()

                if Collision.checkCircle(cx1, cy1, r1, cx2, cy2, r2) then
                    local dx, dy, distance, overlap, pushX, pushY

                    if layer1 == "Boss" then
                        if layer2 ~= "Boss" then
                            dx = cx2 - cx1
                            dy = cy2 - cy1
                            distance = math.sqrt(dx * dx + dy * dy)
                            if distance == 0 then distance = 1 end -- Avoid division by zero
                            overlap = (r1 + r2) - distance
                            if overlap > 0 then
                                pushX = (dx / distance) * overlap
                                pushY = (dy / distance) * overlap
                                enemy2.x = enemy2.x + pushX
                                enemy2.y = enemy2.y + pushY
                            end
                        end
                        -- Note: Boss vs Boss separation is intentionally ignored here
                    elseif layer2 == "Boss" then
                         -- layer1 cannot be "Boss" here due to the previous check
                         dx = cx1 - cx2
                         dy = cy1 - cy2
                         distance = math.sqrt(dx * dx + dy * dy)
                         if distance == 0 then distance = 1 end -- Avoid division by zero
                         overlap = (r1 + r2) - distance
                         if overlap > 0 then
                             pushX = (dx / distance) * overlap
                             pushY = (dy / distance) * overlap
                             enemy1.x = enemy1.x + pushX
                             enemy1.y = enemy1.y + pushY
                         end
                    else
                        -- If both are non-boss, push both equally.
                        dx = cx1 - cx2
                        dy = cy1 - cy2
                        distance = math.sqrt(dx * dx + dy * dy)
                        if distance == 0 then
                            -- If perfectly overlapping, push horizontally
                            distance = 1
                            dx = 1
                            dy = 0
                        end
                        overlap = (r1 + r2) - distance
                        if overlap > 0 then
                            pushX = (dx / distance) * (overlap / 2)
                            pushY = (dy / distance) * (overlap / 2)
                            enemy1.x = enemy1.x + pushX
                            enemy1.y = enemy1.y + pushY
                            enemy2.x = enemy2.x - pushX
                            enemy2.y = enemy2.y - pushY
                        end
                    end
                end
                ::continue_enemy_collision:: -- Label for skipping pairs
            end
        end
    end, 0.002) -- Monitor this closely

    local overallCollisionTime = love.timer.getTime() - overallCollisionStartTime
    if overallCollisionTime > 0.005 then -- Keep original threshold for overall check
        print("[DEBUG] Overall Collision handling took: " .. overallCollisionTime .. " seconds")
    end
end


function showScoreScreen()
    statsSystem:calculateFinalScore()
    if not statsSystem.finalScore then
      
        ui:showScore(0, "None", nil, 0, souls)
        return
    end

    local itemQuality = statsSystem:determineItemReward()
    local rewardItem = nil
    if itemQuality then
        rewardItem = Item.create(itemQuality)
        equipment:addItem(rewardItem)
    
    end

    local breakdown = statsSystem:getCalculationBreakdown()
    local soulsGained = breakdown.totalSouls

    addSouls(soulsGained)

    -- Pass the calculated data (using the original breakdown keys) into the UI.
   ui:showScore(statsSystem.finalScore, itemQuality or "None", rewardItem, soulsGained, souls, breakdown, bonusSouls)

end



function generateRewardItem(quality)
    -- Assuming you have an `Item` module that can generate items based on quality
    local Item = require("item") -- Ensure this path is correct

    -- Use the existing factory method for chest pieces
    local newItem = Item.createChestPiece()

    -- Add the new item to the player's inventory or the game world
   equipment:addItem(newItem)

    return newItem
end


-- Function to add souls and handle leveling up
function addSouls(amount)
    souls.current = souls.current + amount
  

    Overworld.checkSoulLevelUp()  -- Delegate the level-up handling to Overworld
end 

-- Function to grant a talent point
function grantTalentPoint()
    Overworld.availableTalentPoints = Overworld.availableTalentPoints + 2

    -- Optionally, trigger a UI notification or sound here to inform the player
end



function endOfRunCleanup()
    if equipment.equipped.chest then
        local equippedItem = equipment.equipped.chest
        -- Step 1: Unequip the item (which reverts its effect)
        equipment:unequipItem("chest")
        
        -- Step 2: Remove the equipped item from the inventory
        for i = #equipment.inventory, 1, -1 do
            if equipment.inventory[i] == equippedItem then
                table.remove(equipment.inventory, i)
         
                break  -- Assuming only one instance
            end
        end
    end
end

