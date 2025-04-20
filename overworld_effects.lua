-- overworld_effects.lua

local OverworldEffects = {}

OverworldEffects.effects = {}
OverworldEffects.leafParticles = nil
OverworldEffects.seagullParticles = nil
OverworldEffects.mistParticles = nil  -- Mist Particle System
OverworldEffects.thunderTimer = 0
OverworldEffects.flashScreen = false
OverworldEffects.flashDuration = 0.1  -- Flash effect duration
OverworldEffects.sharedRainParticles = nil

-- Volume multipliers for background tracks
OverworldEffects.oceanVolumeMultiplier = 1.5    -- +50%
OverworldEffects.rainVolumeMultiplier = 1.2     -- +20%
OverworldEffects.BonepitVolumeMultiplier = 1.0  -- No change
OverworldEffects.forestVolumeMultiplier = 1.3   -- +30%

-- Initialize volume variables
OverworldEffects.oceanVolume = 0
OverworldEffects.rainVolume = 0
OverworldEffects.BonepitVolume = 0
OverworldEffects.forestVolume = 0  -- Forest sound volume

OverworldEffects.batwingsSound = nil
OverworldEffects.batwingsTimer = 30    -- Timer for batwings sound

-- Load sound files
local oceanSound = love.audio.newSource("assets/ocean.mp3", "stream")
oceanSound:setLooping(true)
oceanSound:setVolume(0)

-- Rain sound
OverworldEffects.rainSound = love.audio.newSource("assets/rain_sound.mp3", "stream")
OverworldEffects.rainSound:setLooping(true)
OverworldEffects.rainSound:setVolume(0)

local BonepitSound = love.audio.newSource("assets/Bonepit.mp3", "stream")
BonepitSound:setLooping(true)
BonepitSound:setVolume(0)

local forestSound = love.audio.newSource("assets/sounds/effects/forest.mp3", "stream")  -- Forest sound
forestSound:setLooping(true)
forestSound:setVolume(0)

local thunderSound = love.audio.newSource("assets/thunder_sound.mp3", "static")
local batwingsSound = love.audio.newSource("assets/batwings.mp3", "static")

-- Owlhoot sound
local owlhootSound = love.audio.newSource("assets/sounds/effects/owlhoot.wav", "static")  -- Owl hoot

-- Snow wind and wolf howl sounds
OverworldEffects.snowwindSound = love.audio.newSource("assets/sounds/effects/snowwind.wav", "stream")
OverworldEffects.snowwindSound:setLooping(true)
OverworldEffects.snowwindSound:setVolume(0)

OverworldEffects.wolfhowlSound = love.audio.newSource("assets/sounds/effects/wolfhowl.mp3", "static")  -- Wolf howl

-- Fog texture
local fogImage

local fadeSpeed = 0.3  -- Volume fade speed

local nodeWidth = 40  -- Example width
local nodeHeight = 40 -- Example height

-- Initialize volume for snow wind
OverworldEffects.snowWindVolume = 0

-- Initialize wolf howl timer
OverworldEffects.wolfHowlTimer = math.random(30, 60)  -- Initial timer

-- Initialize effects for specific nodes
function OverworldEffects.init(nodes)
    fogImage = love.graphics.newImage("assets/fog.png")
    fogImage:setFilter("nearest", "nearest")
    fogImage:setWrap("clamp", "clamp")

    OverworldEffects.createSeagullParticles()
    OverworldEffects.createLeafParticles()
    OverworldEffects.batwingsSound = batwingsSound

    for i, node in ipairs(nodes) do
        local scaledX = node.scaledX or 0
        local scaledY = node.scaledY or 0

        -- Calculate center position by adding half the node's width and height
        local centerX = scaledX + nodeWidth / 2
        local centerY = scaledY + nodeHeight / 2

        if i == 1 or i == 2 then
            local batParticles = OverworldEffects.createBatParticles()
            local rainParticles = OverworldEffects.createRainParticles()

            OverworldEffects.effects[i] = {
                effectType = "deadForestHaze",
                strength = 0,
                bats = true,
                rain = true,
                effectRadius = 500,
                batParticles = batParticles,
                rainParticles = rainParticles,
                fogOverlay = {
                    baseX = centerX,
                    baseY = centerY,
                    driftX = 0,
                    driftY = 0,
                    speedX = 10,
                    speedY = 10,
                    scale = 1.0,
                    opacity = 0,
                    baseOpacity = 0.9
                }
            }
        elseif i == 3 then
            OverworldEffects.effects[i] = {
                effectType = "darkForestHaze",
                strength = 0,
                leafParticles = OverworldEffects.leafParticles,
                effectRadius = 600,
                fogOverlay = {
                    baseX = centerX,
                    baseY = centerY,
                    driftX = 0,
                    driftY = 0,
                    speedX = 5,
                    speedY = 5,
                    scale = 1.2,
                    opacity = 0,
                    baseOpacity = 0.3
                }
            }
        elseif i == 4 or i == 5 then
            local snowParticles = OverworldEffects.createSnowParticles()

            OverworldEffects.effects[i] = {
                effectType = "snowHaze",
                strength = 0,
                snowParticles = snowParticles,
                effectRadius = 800,
                fogOverlay = {
                    baseX = centerX,
                    baseY = centerY,
                    driftX = 0,
                    driftY = 0,
                    speedX = 2,
                    speedY = 2,
                    scale = 1.0,
                    opacity = 0,
                    baseOpacity = 0.7
                }
            }
        else
            OverworldEffects.effects[i] = {
                effectType = "none",
                strength = 0,
                effectRadius = 0,
                batParticles = nil,
                rainParticles = nil,
                snowParticles = nil,
                fogOverlay = nil
            }
        end
    end

    OverworldEffects.createMistParticles()
    OverworldEffects.initVisionShader()

    if not OverworldEffects.rainSound:isPlaying() then
        OverworldEffects.rainSound:play()
    end
    if not OverworldEffects.snowwindSound:isPlaying() then
        OverworldEffects.snowwindSound:play()
    end
end

-- Create seagull particle system
function OverworldEffects.createSeagullParticles()
    local seagullImage = love.graphics.newImage("assets/seagull.png")
    OverworldEffects.seagullParticles = love.graphics.newParticleSystem(seagullImage, 100)
    OverworldEffects.seagullParticles:setEmissionRate(5)
    OverworldEffects.seagullParticles:setParticleLifetime(3, 5)
    OverworldEffects.seagullParticles:setSizes(0.6, 1.2)
    OverworldEffects.seagullParticles:setSpeed(30, 60)
    OverworldEffects.seagullParticles:setLinearAcceleration(-20, -10, 20, 10)
    OverworldEffects.seagullParticles:setSpread(math.pi / 3)
    OverworldEffects.seagullParticles:setRelativeRotation(false)
    OverworldEffects.seagullParticles:start()
end

-- Create leaf particle system
function OverworldEffects.createLeafParticles()
    local leafImage = love.graphics.newImage("assets/leaf.png")
    OverworldEffects.leafParticles = love.graphics.newParticleSystem(leafImage, 500)

    OverworldEffects.leafParticles:setEmissionRate(20)
    OverworldEffects.leafParticles:setParticleLifetime(7, 12)
    OverworldEffects.leafParticles:setSizes(1.5, 2)
    OverworldEffects.leafParticles:setSpeed(20, 40)
    OverworldEffects.leafParticles:setLinearAcceleration(-15, 15, 15, 25)
    OverworldEffects.leafParticles:setDirection(math.pi * 1.5)
    OverworldEffects.leafParticles:setSpread(math.pi)
    OverworldEffects.leafParticles:setColors(1, 1, 1, 1, 1, 1, 1, 0)

    OverworldEffects.leafParticles:setSpin(math.pi / 4, math.pi / 2)
    OverworldEffects.leafParticles:setSpinVariation(1)
    OverworldEffects.leafParticles:setRotation(0, math.pi * 2)
    OverworldEffects.leafParticles:setRelativeRotation(true)
    OverworldEffects.leafParticles:emit(250)
    OverworldEffects.leafParticles:start()
end

-- Create bat particle system
function OverworldEffects.createBatParticles()
    local batImage = love.graphics.newImage("assets/batparticle.png")
    local batParticles = love.graphics.newParticleSystem(batImage, 100)
    
    -- Set emission parameters
    batParticles:setEmissionRate(5)
    batParticles:setParticleLifetime(1, 2)
    batParticles:setSizes(1, 2)
    batParticles:setSpeed(40, 80)
    
    -- Set linear acceleration to allow movement in both directions
    batParticles:setLinearAcceleration(-30, -10, 30, 10)
    
    -- Set direction to upwards and allow spread to both left and right
    batParticles:setDirection(math.pi / 2)  -- Upwards
    batParticles:setSpread(math.pi)         -- 180 degrees spread
    
    batParticles:setRelativeRotation(false)
    batParticles:start()
    
    return batParticles
end

-- Create rain particle system
function OverworldEffects.createRainParticles()
    local rainImage = love.graphics.newImage("assets/raindrop.png")
    local rainParticles = love.graphics.newParticleSystem(rainImage, 1000)

    rainParticles:setEmissionRate(150)
    rainParticles:setParticleLifetime(2, 3)
    rainParticles:setSizes(1, 1.5)
    rainParticles:setSpeed(400, 500)
    rainParticles:setDirection(math.pi / 2)
    rainParticles:setSpread(0.05)
    rainParticles:setColors(0.8, 0.8, 0.8, 1)
    rainParticles:start()
    return rainParticles
end

-- Create snow particle system
function OverworldEffects.createSnowParticles()
    local snowImage = love.graphics.newImage("assets/snow.png")
    local snowParticles = love.graphics.newParticleSystem(snowImage, 500)

    -- Configure snow particles
    snowParticles:setEmissionRate(50)  -- Adjust based on desired density
    snowParticles:setParticleLifetime(5, 10)  -- Lifetime in seconds
    snowParticles:setSizes(2, 3)  -- Start size to end size
    snowParticles:setSpeed(20, 40)  -- Slow falling speed
    snowParticles:setLinearAcceleration(-10, 20, 10, 30)  -- Gentle drift
    snowParticles:setDirection(math.pi / 2)  -- Falling downwards
    snowParticles:setSpread(math.pi / 2)  -- 90 degrees spread
    snowParticles:setSpin(math.pi / 8, math.pi / 4)  -- Slight swirl
    snowParticles:setSpinVariation(1)
    snowParticles:setRotation(0, math.pi * 2)
    snowParticles:setRelativeRotation(true)
    snowParticles:setColors(1, 1, 1, 1, 1, 1, 1, 0)  -- Fade out
    snowParticles:setEmissionArea("uniform", 2000, 2000)  -- Large area to cover the map
    snowParticles:start()

    return snowParticles
end

-- Create mist particle system
function OverworldEffects.createMistParticles()
    local mistImage = love.graphics.newImage("assets/mist.png")  -- Ensure this image exists
    OverworldEffects.mistParticles = love.graphics.newParticleSystem(mistImage, 500)

    -- Configure mist particles
    OverworldEffects.mistParticles:setEmissionRate(10)  -- Adjust as needed
    OverworldEffects.mistParticles:setParticleLifetime(5, 10)  -- Lifetime in seconds
    OverworldEffects.mistParticles:setSizes(1, 2)  -- Start size to end size
    OverworldEffects.mistParticles:setSpeed(20, 40)  -- Pixels per second
    OverworldEffects.mistParticles:setLinearAcceleration(0, 0, 0, 0)  -- No acceleration
    OverworldEffects.mistParticles:setDirection(0)  -- Direction irrelevant due to full spread
    OverworldEffects.mistParticles:setSpread(math.pi * 2)  -- Full circle
    OverworldEffects.mistParticles:setColors(1, 1, 1, 0.5, 1, 1, 1, 0)  -- Fade out
    OverworldEffects.mistParticles:setEmissionArea("uniform", 2000, 2000)  -- Large area
    OverworldEffects.mistParticles:start()
end

-- Initialize the shader-based vision effect
function OverworldEffects.initVisionShader()
    -- Shader code
    local visionShaderCode = [[
extern vec2 playerPosition;    // Player's position in screen coordinates
extern float visionRadius;     // Radius of the illuminated area
extern float fadeWidth;        // Width over which the darkness fades
extern float maxOpacity;       // Maximum opacity of the darkness
extern float darknessMultiplier; // Multiplier to enhance darkness

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Distance from the current pixel to the player's position
    float dist = distance(screen_coords, playerPosition);

    // Compute alpha based on distance
    float alpha = smoothstep(visionRadius, visionRadius + fadeWidth, dist);

    // Scale alpha to respect maximum opacity and darkness multiplier
    alpha *= maxOpacity * darknessMultiplier;

    // Return black color with computed alpha
    return vec4(0.0, 0.0, 0.0, alpha);
}
]]

    -- Create shader
    OverworldEffects.visionShader = love.graphics.newShader(visionShaderCode)
    print("Vision shader initialized.")
end

-- Helper function to draw tiled fog
function OverworldEffects.drawTiledFog(fogOverlay, cameraX, cameraY)
    local tileWidth = fogImage:getWidth() * fogOverlay.scale
    local tileHeight = fogImage:getHeight() * fogOverlay.scale

    -- Screen dimensions
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Calculate offset based on drift
    local offsetX = fogOverlay.driftX % tileWidth
    local offsetY = fogOverlay.driftY % tileHeight

    -- Starting point relative to camera
    local startX = math.floor((fogOverlay.baseX - cameraX) - offsetX - tileWidth)
    local startY = math.floor((fogOverlay.baseY - cameraY) - offsetY - tileHeight)

    -- Draw tiles
    for x = startX, math.floor((fogOverlay.baseX - cameraX) + screenWidth + tileWidth), tileWidth do
        for y = startY, math.floor((fogOverlay.baseY - cameraY) + screenHeight + tileHeight), tileHeight do
            local xPos = math.floor(x)
            local yPos = math.floor(y)
            love.graphics.setColor(1, 1, 1, fogOverlay.opacity) -- Set opacity
            love.graphics.draw(
                fogImage,
                xPos,
                yPos,
                fogOverlay.rotation or 0,
                fogOverlay.scale,
                fogOverlay.scale
            )
        end
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end


-- Update function
function OverworldEffects.update(playerX, playerY, nodes, dt, visionRadius, cameraX, cameraY)
    cameraX = cameraX or 0
    cameraY = cameraY or 0

    -- Update effect strengths and particle positions in world coords
    for i, node in ipairs(nodes) do
        local effect = OverworldEffects.effects[i]
        if effect.effectType ~= "none" then
            local dx = node.scaledX - playerX
            local dy = node.scaledY - playerY
            local distance = math.sqrt(dx * dx + dy * dy)

            if distance < effect.effectRadius then
                effect.strength = (1 - (distance / effect.effectRadius)) ^ 2

                -- Set particle systems in WORLD coordinates
                if effect.effectType == "deadForestHaze" then
                    if effect.batParticles then
                        effect.batParticles:setEmissionRate(5 * effect.strength)
                        effect.batParticles:setPosition(effect.fogOverlay.baseX, effect.fogOverlay.baseY)
                        effect.batParticles:setEmissionArea("uniform", effect.effectRadius, effect.effectRadius)
                    end
                    if effect.rainParticles then
                        effect.rainParticles:setEmissionRate(150 * effect.strength)
                        effect.rainParticles:setPosition(effect.fogOverlay.baseX, effect.fogOverlay.baseY)
                        effect.rainParticles:setEmissionArea("uniform", effect.effectRadius, effect.effectRadius)
                    end
                    if effect.fogOverlay then
                        effect.fogOverlay.opacity = effect.fogOverlay.baseOpacity * effect.strength
                    end
                elseif effect.effectType == "darkForestHaze" then
                    if effect.leafParticles then
                        effect.leafParticles:setEmissionRate(30 * effect.strength)
                        effect.leafParticles:setPosition(effect.fogOverlay.baseX, effect.fogOverlay.baseY)
                        effect.leafParticles:setEmissionArea("uniform", effect.effectRadius, effect.effectRadius)
                    end
                    if effect.fogOverlay then
                        effect.fogOverlay.opacity = effect.fogOverlay.baseOpacity * effect.strength
                    end
                elseif effect.effectType == "snowHaze" then
                    if effect.snowParticles then
                        effect.snowParticles:setEmissionRate(50 * effect.strength)
                        effect.snowParticles:setPosition(effect.fogOverlay.baseX, effect.fogOverlay.baseY)
                        effect.snowParticles:setEmissionArea("uniform", effect.effectRadius, effect.effectRadius)
                    end
                    if effect.fogOverlay then
                        effect.fogOverlay.opacity = effect.fogOverlay.baseOpacity * effect.strength
                    end
                end
            else
                effect.strength = 0
                -- Turn off emissions
                if effect.batParticles then effect.batParticles:setEmissionRate(0) end
                if effect.rainParticles then effect.rainParticles:setEmissionRate(0) end
                if effect.leafParticles then effect.leafParticles:setEmissionRate(0) end
                if effect.snowParticles then effect.snowParticles:setEmissionRate(0) end
                if effect.fogOverlay then effect.fogOverlay.opacity = 0 end
            end
        end
    end

    -- Update particle systems
    for _, effect in ipairs(OverworldEffects.effects) do
        if effect.effectType ~= "none" then
            if effect.leafParticles then effect.leafParticles:update(dt) end
            if effect.batParticles then effect.batParticles:update(dt) end
            if effect.rainParticles then effect.rainParticles:update(dt) end
            if effect.snowParticles then effect.snowParticles:update(dt) end
        end
    end

    -- Update fog drift
    for _, effect in ipairs(OverworldEffects.effects) do
        if effect.effectType ~= "none" and effect.strength > 0 and effect.fogOverlay then
            local fog = effect.fogOverlay
            if type(fog.baseX) == "number" and type(fog.baseY) == "number" then
                fog.driftX = (fog.driftX + fog.speedX * dt) % fogImage:getWidth()
                fog.driftY = (fog.driftY + fog.speedY * dt) % fogImage:getHeight()
            end
        end
    end



    -- Sound management with volume multipliers and fading
    -- Reset target volumes
    local targetOceanVolume = 0
    local targetBonepitVolume = 0
    local targetRainVolume = 0
    local targetForestVolume = 0  -- Forest sound
    local targetSnowWindVolume = 0  -- Snow wind sound

    -- Calculate target volumes based on active nodes
    for i, effect in ipairs(OverworldEffects.effects) do
        if effect.effectType == "deadForestHaze" then
            targetBonepitVolume = math.min(targetBonepitVolume + (effect.strength * OverworldEffects.BonepitVolumeMultiplier), 1)
            targetRainVolume = math.min(targetRainVolume + (effect.strength * OverworldEffects.rainVolumeMultiplier), 1)
        elseif effect.effectType == "darkForestHaze" then
            targetForestVolume = math.min(targetForestVolume + (effect.strength * OverworldEffects.forestVolumeMultiplier), 1)
        elseif effect.effectType == "snowHaze" then
            targetSnowWindVolume = math.min(targetSnowWindVolume + (effect.strength * 1.0), 1)  -- Adjust multiplier as needed
        end
    end

    -- Manage Rain Sound
    if targetRainVolume > 0 then
        if not OverworldEffects.rainSound:isPlaying() then
            OverworldEffects.rainSound:play()
            print("Rain sound started.")
        end
    end

    -- Smoothly adjust rain volume
    if OverworldEffects.rainVolume < targetRainVolume then
        OverworldEffects.rainVolume = math.min(OverworldEffects.rainVolume + fadeSpeed * dt, targetRainVolume)
    elseif OverworldEffects.rainVolume > targetRainVolume then
        OverworldEffects.rainVolume = math.max(OverworldEffects.rainVolume - fadeSpeed * dt, targetRainVolume)
    end

    OverworldEffects.rainSound:setVolume(OverworldEffects.rainVolume)

    -- Manage Snow Wind Sound
    if targetSnowWindVolume > 0 then
        if not OverworldEffects.snowwindSound:isPlaying() then
            OverworldEffects.snowwindSound:play()
            print("Snow wind sound started.")
        end
    end

    -- Smoothly adjust snow wind volume
    if OverworldEffects.snowWindVolume < targetSnowWindVolume then
        OverworldEffects.snowWindVolume = math.min(OverworldEffects.snowWindVolume + fadeSpeed * dt, targetSnowWindVolume)
    elseif OverworldEffects.snowWindVolume > targetSnowWindVolume then
        OverworldEffects.snowWindVolume = math.max(OverworldEffects.snowWindVolume - fadeSpeed * dt, targetSnowWindVolume)
    end

    OverworldEffects.snowwindSound:setVolume(OverworldEffects.snowWindVolume)

    -- Removed stopping snowwindSound to prevent resets

    -- Bonepit sound management
    if targetBonepitVolume > 0 then
        if not BonepitSound:isPlaying() then
            BonepitSound:play()
            print("Bonepit sound started.")
        end
    end

    -- Smoothly adjust Bonepit volume
    if OverworldEffects.BonepitVolume < targetBonepitVolume then
        OverworldEffects.BonepitVolume = math.min(OverworldEffects.BonepitVolume + fadeSpeed * dt, targetBonepitVolume)
    elseif OverworldEffects.BonepitVolume > targetBonepitVolume then
        OverworldEffects.BonepitVolume = math.max(OverworldEffects.BonepitVolume - fadeSpeed * dt, targetBonepitVolume)
    end

    BonepitSound:setVolume(OverworldEffects.BonepitVolume)

    if OverworldEffects.BonepitVolume <= 0 and BonepitSound:isPlaying() then
        BonepitSound:stop()
        print("Bonepit sound stopped.")
    end

    -- Forest sound management
    if targetForestVolume > 0 then
        if not forestSound:isPlaying() then
            forestSound:play()
            print("Forest sound started.")
        end
    end

    -- Smoothly adjust forest volume
    if OverworldEffects.forestVolume < targetForestVolume then
        OverworldEffects.forestVolume = math.min(OverworldEffects.forestVolume + fadeSpeed * dt, targetForestVolume)
    elseif OverworldEffects.forestVolume > targetForestVolume then
        OverworldEffects.forestVolume = math.max(OverworldEffects.forestVolume - fadeSpeed * dt, targetForestVolume)
    end

    forestSound:setVolume(OverworldEffects.forestVolume)

    if OverworldEffects.forestVolume <= 0 and forestSound:isPlaying() then
        forestSound:stop()
        print("Forest sound stopped.")
    end

    -- Wolf Howl sound management for Snow Haze
    local hasSnowHaze = false
    for i, effect in ipairs(OverworldEffects.effects) do
        if effect.effectType == "snowHaze" and effect.strength > 0 then
            hasSnowHaze = true
            break
        end
    end

    if hasSnowHaze then
        OverworldEffects.wolfHowlTimer = OverworldEffects.wolfHowlTimer or math.random(30, 60)
        OverworldEffects.wolfHowlTimer = OverworldEffects.wolfHowlTimer - dt
        if OverworldEffects.wolfHowlTimer <= 0 then
            if math.random() < 0.3 then  -- 30% chance
                love.audio.play(OverworldEffects.wolfhowlSound)
                print("Wolf howl played.")
            end
            OverworldEffects.wolfHowlTimer = math.random(30, 60)  -- Reset timer
        end
    end

    -- Batwings sound effect management
    local hasDeadForestHaze = false
    for i, effect in ipairs(OverworldEffects.effects) do
        if effect.effectType == "deadForestHaze" and effect.strength > 0 then
            hasDeadForestHaze = true
            break
        end
    end

    if hasDeadForestHaze then
        OverworldEffects.batwingsTimer = OverworldEffects.batwingsTimer - dt
        if OverworldEffects.batwingsTimer <= 0 then
            OverworldEffects.batwingsTimer = 30
            if math.random() < 0.1 then  -- 10% chance
                love.audio.play(OverworldEffects.batwingsSound)
                print("Batwings sound played.")
            end
        end

        -- Thunder effect
        OverworldEffects.thunderTimer = OverworldEffects.thunderTimer - dt
        if OverworldEffects.thunderTimer <= 0 then
            OverworldEffects.triggerThunder()
            OverworldEffects.thunderTimer = math.random(5, 15)
        end
    end

    -- Owlhoot sound management for Dark Forest Haze
    local hasDarkForestHaze = false
    for i, effect in ipairs(OverworldEffects.effects) do
        if effect.effectType == "darkForestHaze" and effect.strength > 0 then
            hasDarkForestHaze = true
            break
        end
    end

    if hasDarkForestHaze then
        OverworldEffects.owlhootTimer = OverworldEffects.owlhootTimer or math.random(10, 20)
        OverworldEffects.owlhootTimer = OverworldEffects.owlhootTimer - dt
        if OverworldEffects.owlhootTimer <= 0 then
            love.audio.play(owlhootSound)
            print("Owlhoot sound played.")
            OverworldEffects.owlhootTimer = math.random(10, 20)  -- Reset timer
        end
    end

    -- Flash screen effect management
    if OverworldEffects.flashScreen then
        OverworldEffects.flashDuration = OverworldEffects.flashDuration - dt
        if OverworldEffects.flashDuration <= 0 then
            OverworldEffects.flashScreen = false
            OverworldEffects.flashDuration = 0.1
        end
    end
end

-- Draw function
function OverworldEffects.draw(playerX, playerY, visionRadius, cameraX, cameraY)
    visionRadius = visionRadius or 100

    if OverworldEffects.visionShader then
        love.graphics.setShader(OverworldEffects.visionShader)

        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        local playerScreenX = playerX - cameraX
        local playerScreenY = playerY - cameraY

        OverworldEffects.visionShader:send("playerPosition", { playerScreenX, playerScreenY })
        OverworldEffects.visionShader:send("visionRadius", visionRadius)
        OverworldEffects.visionShader:send("fadeWidth", 100)
        OverworldEffects.visionShader:send("maxOpacity", 0.6)
        OverworldEffects.visionShader:send("darknessMultiplier", 2.0)

        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
        love.graphics.setShader()
    end

    local totalHazeA = 0
    for _, effect in pairs(OverworldEffects.effects) do
        if effect.effectType == "deadForestHaze" and effect.strength > 0 then
            totalHazeA = totalHazeA + (0.1 * effect.strength)
        elseif effect.effectType == "darkForestHaze" and effect.strength > 0 then
            totalHazeA = totalHazeA + (0.3 * effect.strength)
        elseif effect.effectType == "snowHaze" and effect.strength > 0 then
            totalHazeA = totalHazeA + (0.5 * effect.strength)
        end
    end
    totalHazeA = math.min(totalHazeA, 1)
    if totalHazeA > 0 then
        OverworldEffects.applyColorHaze(0, 0, 0, totalHazeA)
    end

    -- Draw particle systems with camera offset applied once at draw time
    for _, effect in ipairs(OverworldEffects.effects) do
        if effect.effectType ~= "none" and effect.strength > 0 then
            if effect.batParticles then
                love.graphics.draw(effect.batParticles, -cameraX, -cameraY)
            end
            if effect.rainParticles then
                love.graphics.draw(effect.rainParticles, -cameraX, -cameraY)
            end
            if effect.leafParticles then
                love.graphics.draw(effect.leafParticles, -cameraX, -cameraY)
            end
            if effect.snowParticles then
                love.graphics.draw(effect.snowParticles, -cameraX, -cameraY)
            end

            if effect.fogOverlay then
                OverworldEffects.drawTiledFog(effect.fogOverlay, cameraX, cameraY)
            end
        end
    end

    if OverworldEffects.flashScreen then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1)
    end
end

-- Thunder effect with screen flash
function OverworldEffects.triggerThunder()
    love.audio.play(thunderSound)
    OverworldEffects.flashScreen = true
    OverworldEffects.flashDuration = 0.1
end

-- Apply color haze
function OverworldEffects.applyColorHaze(r, g, b, strength)
    local alpha = 0.5 * strength
    love.graphics.setColor(r, g, b, alpha)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1)
end

-- Stop all sounds
function OverworldEffects.stopAllSounds()
    if oceanSound:isPlaying() then oceanSound:stop() end
    if OverworldEffects.rainSound:isPlaying() then OverworldEffects.rainSound:stop() end
    if OverworldEffects.snowwindSound:isPlaying() then OverworldEffects.snowwindSound:stop() end  -- Stop snow wind sound
    if BonepitSound:isPlaying() then BonepitSound:stop() end
    if forestSound:isPlaying() then forestSound:stop() end  -- Stop forest sound
    if OverworldEffects.mistParticles then
        OverworldEffects.mistParticles:stop()
    end
    -- Stop other particle systems if necessary
end

return OverworldEffects
