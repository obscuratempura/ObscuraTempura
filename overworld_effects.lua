local OverworldEffects = {}

OverworldEffects.effects = {}
OverworldEffects.leafParticles = nil
OverworldEffects.batParticles = nil
OverworldEffects.seagullParticles = nil
OverworldEffects.rainParticles = nil
OverworldEffects.thunderTimer = 0
OverworldEffects.flashScreen = false
OverworldEffects.flashDuration = 0.1  -- Duration of the flash effect in seconds

-- Volume multipliers for background tracks
OverworldEffects.oceanVolumeMultiplier = 1.5    -- Increase ocean sound volume by 50%
OverworldEffects.rainVolumeMultiplier = 1.2     -- Increase rain sound volume by 20%
OverworldEffects.bonepitVolumeMultiplier = 1.0  -- Keep bonepit sound volume as is

-- Initialize volume variables
OverworldEffects.oceanVolume = 0
OverworldEffects.rainVolume = 0
OverworldEffects.bonepitVolume = 0

OverworldEffects.batwingsSound = nil
OverworldEffects.batwingsTimer = 30    -- Timer for triggering the batwings sound

-- Load sound files
local oceanSound = love.audio.newSource("assets/ocean.mp3", "stream")
oceanSound:setLooping(true)
oceanSound:setVolume(0)

local rainSound = love.audio.newSource("assets/rain_sound.mp3", "stream")
rainSound:setLooping(true)
rainSound:setVolume(0)

local bonepitSound = love.audio.newSource("assets/bonepit.mp3", "stream")
bonepitSound:setLooping(true)
bonepitSound:setVolume(0)

local thunderSound = love.audio.newSource("assets/thunder_sound.mp3", "static")
local batwingsSound = love.audio.newSource("assets/batwings.mp3", "static")

local fadeSpeed = 1  -- Adjust this value to control how quickly the volume fades

-- Initialize effects for specific nodes
function OverworldEffects.init(nodes)
    for i, node in ipairs(nodes) do
        if i == 1 then  -- Node 0 (Ocean Dock)
            OverworldEffects.effects[i] = {
                effectType = "oceanDock",
                strength = 1,
                seagulls = true,
                ocean = true,
                effectRadius = 600  -- Increase radius as desired
            }
        elseif i == 2 then  -- Node 2 (Bone Pit)
            OverworldEffects.effects[i] = {
                effectType = "hunterGreenHaze",
                strength = 1,
                leaves = true,
                bonepit = true,
                effectRadius = 500  -- Increase radius as desired
            }
        elseif i == 3 then  -- Node 3 (Dead Forest)
            OverworldEffects.effects[i] = {
                effectType = "deadForestHaze",
                strength = 1,
                bats = true,
                rain = true,
                effectRadius = 700  -- Increase radius as desired
            }
        else
            OverworldEffects.effects[i] = {
                effectType = "none",
                strength = 0,
                effectRadius = 0
            }
        end
    end
    OverworldEffects.createSeagullParticles()
    OverworldEffects.createLeafParticles()
    OverworldEffects.createBatParticles()
    OverworldEffects.createRainParticles()
    OverworldEffects.batwingsSound = batwingsSound
end

-- Create seagull particle system for Node 0
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

-- Create bat particle system for Node 3
function OverworldEffects.createBatParticles()
    local batImage = love.graphics.newImage("assets/batparticle.png")
    OverworldEffects.batParticles = love.graphics.newParticleSystem(batImage, 100)
    OverworldEffects.batParticles:setEmissionRate(5)
    OverworldEffects.batParticles:setParticleLifetime(1, 2)
    OverworldEffects.batParticles:setSizes(0.5, 1)
    OverworldEffects.batParticles:setSpeed(40, 80)
    OverworldEffects.batParticles:setLinearAcceleration(-30, -10, 30, 10)
    OverworldEffects.batParticles:setSpread(math.pi / 4)
    OverworldEffects.batParticles:setRelativeRotation(false)
    OverworldEffects.batParticles:start()
end

-- Create rain particle system for Node 3
function OverworldEffects.createRainParticles()
    local rainImage = love.graphics.newImage("assets/raindrop.png")
    OverworldEffects.rainParticles = love.graphics.newParticleSystem(rainImage, 1000)

    OverworldEffects.rainParticles:setEmissionRate(150)
    OverworldEffects.rainParticles:setParticleLifetime(2, 3)
    OverworldEffects.rainParticles:setSizes(1, 1.5)
    OverworldEffects.rainParticles:setSpeed(400, 500)
    OverworldEffects.rainParticles:setDirection(math.pi / 2)
    OverworldEffects.rainParticles:setSpread(0.05)
    OverworldEffects.rainParticles:setColors(0.8, 0.8, 0.8, 1)
    OverworldEffects.rainParticles:start()
end

-- Update function
function OverworldEffects.update(playerX, playerY, nodes, dt, visionRadius)
    -- Update effect strengths based on distance
    for i, node in ipairs(nodes) do
        local effect = OverworldEffects.effects[i]
        local dx, dy = node.scaledX - playerX, node.scaledY - playerY
        local distance = math.sqrt(dx * dx + dy * dy)
        local effectRadius = effect.effectRadius or visionRadius

        if effect.effectType ~= "none" then
            if distance < effectRadius then
                effect.strength = math.pow(1 - (distance / effectRadius), 2)
            else
                effect.strength = 0
            end
        end
    end

    -- Update particle systems
    -- Update seagull particles for Node 0
    if OverworldEffects.effects[1].strength > 0 then
        local nodeEffectRadius = OverworldEffects.effects[1].effectRadius
        OverworldEffects.seagullParticles:setEmissionRate(5 * OverworldEffects.effects[1].strength)
        OverworldEffects.seagullParticles:setPosition(playerX, playerY)
        OverworldEffects.seagullParticles:setEmissionArea("uniform", nodeEffectRadius, nodeEffectRadius)
    else
        OverworldEffects.seagullParticles:setEmissionRate(0)
    end
    OverworldEffects.seagullParticles:update(dt)

    -- Update leaf particles for Node 2
    if OverworldEffects.effects[2].strength > 0 then
        local nodeEffectRadius = OverworldEffects.effects[2].effectRadius
        OverworldEffects.leafParticles:setEmissionRate(20 * OverworldEffects.effects[2].strength)
        OverworldEffects.leafParticles:setPosition(nodes[2].scaledX, nodes[2].scaledY)
        OverworldEffects.leafParticles:setEmissionArea("uniform", nodeEffectRadius, nodeEffectRadius)
    else
        OverworldEffects.leafParticles:setEmissionRate(0)
    end
    OverworldEffects.leafParticles:update(dt)

    -- Update bat and rain particles for Node 3
    if OverworldEffects.effects[3].strength > 0 then
        local nodeEffectRadius = OverworldEffects.effects[3].effectRadius
        OverworldEffects.batParticles:setEmissionRate(5 * OverworldEffects.effects[3].strength)
        OverworldEffects.batParticles:setPosition(playerX, playerY)
        OverworldEffects.batParticles:setEmissionArea("uniform", nodeEffectRadius, nodeEffectRadius)

        OverworldEffects.rainParticles:setEmissionRate(150 * OverworldEffects.effects[3].strength)
        OverworldEffects.rainParticles:setPosition(playerX, playerY)
        OverworldEffects.rainParticles:setEmissionArea("uniform", nodeEffectRadius, nodeEffectRadius)
    else
        OverworldEffects.batParticles:setEmissionRate(0)
        OverworldEffects.rainParticles:setEmissionRate(0)
    end

    OverworldEffects.batParticles:update(dt)
    OverworldEffects.rainParticles:update(dt)

    -- Sound management with volume multipliers and fading
    -- Ocean sound management for Node 0
    local targetOceanVolume = math.min(OverworldEffects.effects[1].strength * OverworldEffects.oceanVolumeMultiplier, 1)
    if not oceanSound:isPlaying() and targetOceanVolume > 0 then
        oceanSound:play()
    end

    if OverworldEffects.oceanVolume < targetOceanVolume then
        OverworldEffects.oceanVolume = math.min(OverworldEffects.oceanVolume + fadeSpeed * dt, targetOceanVolume)
    elseif OverworldEffects.oceanVolume > targetOceanVolume then
        OverworldEffects.oceanVolume = math.max(OverworldEffects.oceanVolume - fadeSpeed * dt, targetOceanVolume)
    end

    oceanSound:setVolume(OverworldEffects.oceanVolume)

    if OverworldEffects.oceanVolume <= 0 and oceanSound:isPlaying() then
        oceanSound:stop()
    end

    -- Bonepit sound management for Node 2
    local targetBonepitVolume = math.min(OverworldEffects.effects[2].strength * OverworldEffects.bonepitVolumeMultiplier, 1)
    if not bonepitSound:isPlaying() and targetBonepitVolume > 0 then
        bonepitSound:play()
    end

    if OverworldEffects.bonepitVolume < targetBonepitVolume then
        OverworldEffects.bonepitVolume = math.min(OverworldEffects.bonepitVolume + fadeSpeed * dt, targetBonepitVolume)
    elseif OverworldEffects.bonepitVolume > targetBonepitVolume then
        OverworldEffects.bonepitVolume = math.max(OverworldEffects.bonepitVolume - fadeSpeed * dt, targetBonepitVolume)
    end

    bonepitSound:setVolume(OverworldEffects.bonepitVolume)

    if OverworldEffects.bonepitVolume <= 0 and bonepitSound:isPlaying() then
        bonepitSound:stop()
    end

    -- Rain sound management for Node 3
    local targetRainVolume = math.min(OverworldEffects.effects[3].strength * OverworldEffects.rainVolumeMultiplier, 1)
    if not rainSound:isPlaying() and targetRainVolume > 0 then
        rainSound:play()
    end

    if OverworldEffects.rainVolume < targetRainVolume then
        OverworldEffects.rainVolume = math.min(OverworldEffects.rainVolume + fadeSpeed * dt, targetRainVolume)
    elseif OverworldEffects.rainVolume > targetRainVolume then
        OverworldEffects.rainVolume = math.max(OverworldEffects.rainVolume - fadeSpeed * dt, targetRainVolume)
    end

    rainSound:setVolume(OverworldEffects.rainVolume)

    if OverworldEffects.rainVolume <= 0 and rainSound:isPlaying() then
        rainSound:stop()
    end

    -- Batwings sound effect management
    if OverworldEffects.effects[3].strength > 0 then
        OverworldEffects.batwingsTimer = OverworldEffects.batwingsTimer - dt
        if OverworldEffects.batwingsTimer <= 0 then
            OverworldEffects.batwingsTimer = 30
            if math.random() < 0.1 then
                love.audio.play(batwingsSound)
            end
        end

        -- Thunder effect
        OverworldEffects.thunderTimer = OverworldEffects.thunderTimer - dt
        if OverworldEffects.thunderTimer <= 0 then
            OverworldEffects.triggerThunder()
            OverworldEffects.thunderTimer = math.random(5, 15)
        end
    end

    -- Flash screen effect
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
    visionRadius = visionRadius or 300

    local function stencilFunction()
        love.graphics.circle("fill", playerX - cameraX, playerY - cameraY, visionRadius)
    end

    love.graphics.stencil(stencilFunction, "replace", 1)
    love.graphics.setStencilTest("greater", 0)

    -- Apply color haze and draw particle systems within the vision radius
    for i, effect in pairs(OverworldEffects.effects) do
        if effect.effectType == "oceanDock" and effect.strength > 0 then
            OverworldEffects.applyColorHaze(0.1, 0.1, 0.6, effect.strength * 0.5)
            love.graphics.setColor(1, 1, 1)  -- Reset color before drawing particles
            love.graphics.draw(OverworldEffects.seagullParticles, -cameraX, -cameraY)
        elseif effect.effectType == "hunterGreenHaze" and effect.strength > 0 then
            OverworldEffects.applyColorHaze(0.05, 0.25, 0.05, effect.strength * 0.7)
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(OverworldEffects.leafParticles, -cameraX, -cameraY)
        elseif effect.effectType == "deadForestHaze" and effect.strength > 0 then
            OverworldEffects.applyColorHaze(0.2, 0.1, 0.1, effect.strength)
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(OverworldEffects.batParticles, -cameraX, -cameraY)
            love.graphics.draw(OverworldEffects.rainParticles, -cameraX, -cameraY)
        end
    end

    love.graphics.setStencilTest()

    -- Flash screen effect
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

return OverworldEffects
