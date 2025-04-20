-- random_items.lua
local RandomItems = {}
RandomItems.__index = RandomItems

local Config      = require("config")   -- <<< ADD THIS
local Sprites     = require("sprites")
local Abilities   = require("abilities")
local timer       = require("timer")  -- HUMP timer
local GameState   = require("gameState")
local Soul        = require("soul") -- <<< ADD THIS REQUIRE

-- Cache math functions
local random  = math.random
local sqrt    = math.sqrt
local cos     = math.cos
local sin     = math.sin
local pi      = math.pi

-- Constructor; pass options.statsSystem in options.statsSystem
function RandomItems.new(options)
    local self = setmetatable({}, RandomItems)
    self.items         = {}   
    self.floatingTexts = {}   
    self.spawnTimer    = 0
    self.spawnChance   = options.spawnChance or 0.5  -- Use provided or default
    self.spawnInterval = options.spawnInterval or 10 -- Use provided or default
    self.itemLifetime  = options.itemLifetime or 12  -- Use provided or default
    self.maxItems      = options.maxItems or 5       -- Use provided or default
    self.spawnDistanceMin = options.spawnDistanceMin or 300
    self.spawnDistanceMax = options.spawnDistanceMax or 500
    self.statsSystem   = options.statsSystem -- Store statsSystem if needed later

    -- Load item images (assuming Sprites.itemImages exists)
    self.itemImages = Sprites.itemImages or {
        chest = love.graphics.newImage("assets/chest.png") -- Fallback
        -- Add other item images if needed
    }
    -- Load sounds (assuming sounds global exists)
    self.chestSound = _G.sounds and _G.sounds.chestOpen -- Example sound path

    -- Preload images and set filters
    self.itemImages = {}
    self.itemImages["chest"] = love.graphics.newImage("assets/chest.png")
    self.itemImages["chest"]:setFilter("nearest", "nearest")
    
    -- New reward chest image
    self.itemImages["rewardchest"] = love.graphics.newImage("assets/rewardchest.png")
    self.itemImages["rewardchest"]:setFilter("nearest", "nearest")
    
    self.itemImages["shrine"] = love.graphics.newImage("assets/shrine.png")
    self.itemImages["shrine"]:setFilter("nearest", "nearest")
    local shrineImage = self.itemImages["shrine"]
    local frameWidth, frameHeight = 16, 16
    self.shrineQuads = {}
    for i = 0, 2 do
        self.shrineQuads[i+1] = love.graphics.newQuad(i * frameWidth, 0, frameWidth, frameHeight, shrineImage:getDimensions())
    end

    self.itemImages["event"] = love.graphics.newImage("assets/webbomb.png")
    self.itemImages["event"]:setFilter("nearest", "nearest")
    local eventImage = self.itemImages["event"]
    self.eventQuads = {}
    for i = 0, 2 do
        self.eventQuads[i+1] = love.graphics.newQuad(i * frameWidth, 0, frameWidth, frameHeight, eventImage:getDimensions())
    end

    self.chestSound  = love.audio.newSource("assets/sounds/effects/chest.wav", "static")
    self.shrineSound = love.audio.newSource("assets/sounds/effects/shrine.wav", "static")
    
    return self
end

-- New function to spawn a reward chest at a given position
function RandomItems:spawnRewardChest(x, y)
    local chestSound = self.chestSound  -- capture RandomItems' chest sound
    local chest = {
       type = "rewardchest",
       x = x,
       y = y,
       radius = 16,
       collected = false,
       lifetime = 1000,  -- prevent auto-despawn
       image = self.itemImages["rewardchest"]
    }
    chest.onCollect = function(self)
        if chestSound then chestSound:play() end
        local explosionRadius = 100  -- items will scatter within this radius
        -- Drop souls: random count between 5 and 8
        local soulCount = random(5, 8)
        local Soul = require("soul")
        for i = 1, soulCount do
            local angle = random() * 2 * pi
            local distance = random(50, explosionRadius)
            local sx = self.x + math.cos(angle) * distance
            local sy = self.y + math.sin(angle) * distance
            local soulPickup = Soul.new(sx, sy)
            table.insert(soulPickups, soulPickup)
        end
        -- Drop experience gems: random count between 5 and 10, each worth 5 exp
        local gemCount = random(5, 10)
        local ExperienceGem = require("experience_gem")
        for i = 1, gemCount do
            local angle = random() * 2 * pi
            local distance = random(50, explosionRadius)
            local gx = self.x + math.cos(angle) * distance
            local gy = self.y + math.sin(angle) * distance
            local gem = ExperienceGem.new(gx, gy, 5)
            table.insert(experienceGems, gem)
        end
        -- Drop food: random count between 1 and 3
        local foodCount = random(1, 3)
        local Food = require("food")
        for i = 1, foodCount do
            local angle = random() * 2 * pi
            local distance = random(50, explosionRadius)
            local fx = self.x + math.cos(angle) * distance
            local fy = self.y + math.sin(angle) * distance
            local foodItem = Food.new(fx, fy, true)
            table.insert(foodItems, foodItem)
        end
        self.collected = true
    end
    table.insert(self.items, chest)
end

function RandomItems:addFloatingText(x, y, text, color)
    local ft = {
        x = x,
        y = y,
        text = text,
        color = color or {1, 1, 1},
        lifetime = 1.0,  -- lasts 1 second
        totalLifetime = 1.0,
    }
    table.insert(self.floatingTexts, ft)
end

function RandomItems:spawnItem()
    if not player then return end
    
    -- Check for max items first
    if #self.items >= self.maxItems then
        return
    end
    
    -- Only spawn if we pass the chance check
    if random() > self.spawnChance then
        return
    end
    
    local ang = random() * 2 * pi
    local dist = random(self.spawnDistanceMin, self.spawnDistanceMax)
    local spawnX = player.x + dist * cos(ang)
    local spawnY = player.y + dist * sin(ang)
    
    -- clamp inside hedge:
    local B = Config.boundaryMargin or 0
    local W,H = Config.mapWidth or 0, Config.mapHeight or 0
    local R = 16
    spawnX = math.max(B+R, math.min(W-(B+R), spawnX))
    spawnY = math.max(B+R, math.min(H-(B+R), spawnY))

    -- Update probability distribution for item types
    local rand = random()
    local itemType
    if rand < 0.50 then
        itemType = "chest"
    elseif rand < 0.80 then
        itemType = "shrine"
    else
        itemType = "event"
    end

    local item = {
        type = itemType,
        x = spawnX,
        y = spawnY,
        radius = 16,
        collected = false,
        lifetime = self.itemLifetime  -- Use new 6-second lifetime
    }

    if itemType == "chest" then
        item.image = self.itemImages["chest"]
        item.onCollect = function()
            if self.chestSound then self.chestSound:play() end
            local outcome = random(5)
            if outcome == 1 then
                self:addFloatingText(spawnX, spawnY, "EMPTY!", {1, 0, 0})
            elseif outcome == 2 then
                local soulsGained = random(1, 5)
                local Soul = require("soul")
                for i = 1, soulsGained do
                    local soulAng = random() * 2 * pi
                    local offsetDist = random(40, 70)
                    local soulX = spawnX + cos(soulAng) * offsetDist
                    local soulY = spawnY + sin(soulAng) * offsetDist
                    local soulPickup = Soul.new(soulX, soulY)
                    table.insert(soulPickups, soulPickup)
                end
                self:addFloatingText(spawnX, spawnY, "SOULS", {0, 1, 1})
            elseif outcome == 3 then
                local foodAng = random() * 2 * pi
                local offsetDist = random(30, 60)
                local foodX = spawnX + cos(foodAng) * offsetDist
                local foodY = spawnY + sin(foodAng) * offsetDist
                local Food = require("food")
                local foodItem = Food.new(foodX, foodY, true)
                if foodItem then
                    table.insert(foodItems, foodItem)
                    self:addFloatingText(spawnX, spawnY, "FOOD!", {0, 1, 0})
                else
                    self:addFloatingText(spawnX, spawnY, "EMPTY!", {1, 0, 0})
                end
            elseif outcome == 4 then
                local ExperienceGem = require("experience_gem")
                for i = 1, 10 do
                    local gemAng = random() * 2 * pi
                    local offsetDist = random(40, 70)
                    local gemX = spawnX + cos(gemAng) * offsetDist
                    local gemY = spawnY + sin(gemAng) * offsetDist
                    local gemAmount = random(1, 5)
                    local gem = ExperienceGem.new(gemX, gemY, gemAmount)
                    table.insert(experienceGems, gem)
                end
                self:addFloatingText(spawnX, spawnY, "CANDY!!", {0, 0, 1})
            elseif outcome == 5 then
                if Abilities.abilityList["Chest Ignition"] and Abilities.abilityList["Chest Ignition"].effect then
                    Abilities.abilityList["Chest Ignition"].effect(player, _G.effects, _G.enemies, _G.sounds)
                end
                self:addFloatingText(spawnX, spawnY, "Flame Trap!", {1, 0.5, 0})
            end
        end
    elseif itemType == "shrine" then
        item.image = self.itemImages["shrine"]
        item.quads = self.shrineQuads
        item.frame = 1
        item.frameTimer = 0
        item.frameDuration = 0.2
        item.onCollect = function()
            if self.shrineSound then self.shrineSound:play() end
            local outcome = random(4)
            if outcome == 1 then
                player:applyStatusEffect(nil, "Magnetic", 5, 200)
                self:addFloatingText(spawnX, spawnY, "Blessing of Pull!", {1, 0, 1})
            elseif outcome == 2 then
                for i = 1, 2 do
                    Abilities.summongoyle(player, 10, 60, 1, player.summonedEntities, _G.enemies, _G.effects, _G.damageNumbers)
                end
                self:addFloatingText(spawnX, spawnY, "Blessing of Undeath!", {0.5, 0, 0.5})
            elseif outcome == 3 then
                player:applyStatusEffect(nil, "Clovis", 5, 1)
                self:addFloatingText(spawnX, spawnY, "Curse of Clovis!", {0.5, 0, 0})
            elseif outcome == 4 then
                local messages = {"NOTHING!", "EMPTY!", "VACANT!"}
                self:addFloatingText(spawnX, spawnY, messages[random(#messages)], {0.5, 0.5, 0.5})
            end
        end
    elseif itemType == "event" then
        item.image = self.itemImages["event"]
        item.quads = self.eventQuads
        item.frame = 1
        item.frameTimer = 0
        item.frameDuration = 0.2
        item.onCollect = function()
            if self.eventSound then self.eventSound:play() end
            local eventRoll = random(100)
            
            -- 10% chance for NPC
            if eventRoll <= 10 then
                -- NPC event code (existing code)
                local npcX = spawnX + 10
                local npcY = spawnY - 10
                local npc = {
                    image = love.graphics.newImage("assets/grimreapernpc.png"),
                    quads = {},
                    frame = 1,
                    frameTimer = 0,
                    frameDuration = 0.2,
                    x = npcX,
                    y = npcY,
                    lifetime = 8,
                    disappear = false
                }
                local npcImage = npc.image
                local fw, fh = 16, 16
                for i = 0, 2 do
                    npc.quads[i+1] = love.graphics.newQuad(i * fw, 0, fw, fh, npcImage:getDimensions())
                end
                self:addFloatingText(npcX, npcY - 10, "THANKS!", {1, 1, 1})
                timer.after(3, function()
                    self:addFloatingText(npcX, npcY - 10, "TAKE THIS!", {1, 1, 1})
                    local Food = require("food")
                    for i = 1, random(1,3) do
                        local food = Food.new(npcX + random(-10,10), npcY + random(-10,10), true)
                        table.insert(foodItems, food)
                    end
                    local Soul = require("soul")
                    for i = 1, random(1,3) do
                        local soulAng = random() * 2 * pi
                        local offsetDist = random(20,40)
                        local soulX = npcX + cos(soulAng) * offsetDist
                        local soulY = npcY + sin(soulAng) * offsetDist
                        local soul = Soul.new(soulX, soulY)
                        table.insert(soulPickups, soul)
                    end
                    local ExperienceGem = require("experience_gem")
                    for i = 1, random(1,3) do
                        local gem = ExperienceGem.new(npcX + random(-10,10), npcY + random(-10,10), 10)
                        table.insert(experienceGems, gem)
                    end
                end)
                table.insert(npcs, npc)
            else
                -- 90% chance for enemy spawn events
                local enemyRoll = random(4) -- 1-4 for different enemy types
                local Enemy = require("enemy")
                
                if enemyRoll == 1 then
                    -- Spawn 7 skitterers (existing behavior)
                    for i = 1, 7 do
                        local skitter = Enemy.new("skitter_spider", spawnX, spawnY, 1, nil)
                        skitter.vx = cos(random() * 2 * pi) * 100
                        skitter.vy = sin(random() * 2 * pi) * 100
                        table.insert(enemies, skitter)
                    end
                    self:addFloatingText(spawnX, spawnY, "SKITTER AMBUSH!", {1, 0.5, 0})
                elseif enemyRoll == 2 then
                    -- Spawn 3 webbers
                    for i = 1, 3 do
                        local webber = Enemy.new("webber", spawnX, spawnY, 1, nil)
                        webber.vx = cos(random() * 2 * pi) * 50
                        webber.vy = sin(random() * 2 * pi) * 50
                        table.insert(enemies, webber)
                    end
                    self:addFloatingText(spawnX, spawnY, "WEBBER AMBUSH!", {0.5, 0.8, 1})
                elseif enemyRoll == 3 then
                    -- Spawn 3 spiders
                    for i = 1, 3 do
                        local spider = Enemy.new("spider", spawnX, spawnY, 1, nil)
                        spider.vx = cos(random() * 2 * pi) * 75
                        spider.vy = sin(random() * 2 * pi) * 75
                        table.insert(enemies, spider)
                    end
                    self:addFloatingText(spawnX, spawnY, "SPIDER AMBUSH!", {1, 0.3, 0.3})
                else
                    -- Mix of different spider types
                    for i = 1, 4 do
                        local enemyType = random(3)
                        local enemy
                        if enemyType == 1 then
                            enemy = Enemy.new("skitter_spider", spawnX, spawnY, 1, nil)
                        elseif enemyType == 2 then
                            enemy = Enemy.new("webber", spawnX, spawnY, 1, nil)
                        else
                            enemy = Enemy.new("spider", spawnX, spawnY, 1, nil)
                        end
                        enemy.vx = cos(random() * 2 * pi) * 85
                        enemy.vy = sin(random() * 2 * pi) * 85
                        table.insert(enemies, enemy)
                    end
                    self:addFloatingText(spawnX, spawnY, "MIXED AMBUSH!", {1, 0.5, 0.5})
                end
            end
        end
    end

    table.insert(self.items, item)
end

-- New function to spawn a chest containing only a specific number of souls
function RandomItems:spawnSoulChest(x, y, soulCount)
    if not soulCount or soulCount <= 0 then soulCount = 1 end -- Default to 1 if invalid count

    local chestImage = self.itemImages["chest"]
    if not chestImage then
        print("Error: Chest image not found in RandomItems.itemImages")
        return -- Can't spawn without an image
    end

    local chest = {
       type = "chest", -- Use standard chest appearance/type for collision checks
       x = x,
       y = y,
       radius = 16, -- Standard collision radius
       collected = false,
       lifetime = 60,  -- Give it a longer lifetime for the tutorial
       image = chestImage,
       onCollect = function(self)
            -- Custom behavior: Spawn souls
            if _G.sounds and _G.sounds.chestOpen then _G.sounds.chestOpen:play() end -- Play sound if available

            local explosionRadius = 70  -- items will scatter within this radius

            -- Drop the specified number of souls
            for i = 1, soulCount do
                local angle = random() * 2 * pi
                local distance = random(10, explosionRadius) -- Scatter them a bit
                local sx = self.x + cos(angle) * distance
                local sy = self.y + sin(angle) * distance
                -- Use the Soul module to create a new soul pickup
                local soulPickup = Soul.new(sx, sy)
                table.insert(_G.soulPickups, soulPickup) -- Add to the global soulPickups table
            end
            self.collected = true
            -- Add floating text indicating souls dropped
            _G.randomItems:addFloatingText(self.x, self.y, soulCount .. " SOULS!", {0, 1, 1}) -- Cyan color
       end
    }
    table.insert(self.items, chest)
    print("[RandomItems] Spawned special soul chest at", x, y) -- Debug print
end

function RandomItems:update(dt)
    for i = #self.items, 1, -1 do
        local item = self.items[i]
        item.lifetime = item.lifetime - dt
        if item.type == "shrine" or item.type == "event" then
            item.frameTimer = item.frameTimer + dt
            if item.frameTimer >= item.frameDuration then
                item.frameTimer = item.frameTimer - item.frameDuration
                item.frame = (item.frame % 3) + 1
            end
        end
        if item.collected or item.lifetime <= 0 then
            table.remove(self.items, i)
        end
    end

    -- Update spawn timer only if spawning is enabled
    if self.spawnChance > 0 and self.spawnInterval > 0 and self.maxItems > 0 then
        self.spawnTimer = self.spawnTimer - dt
        if self.spawnTimer <= 0 then
            self:spawnItem()
            -- Reset timer based on the current interval (which might have been changed by the tutorial)
            self.spawnTimer = self.spawnInterval
        end
    else
        -- Keep timer reset if spawning is disabled
        self.spawnTimer = self.spawnInterval
    end


    for i = #self.floatingTexts, 1, -1 do
        local ft = self.floatingTexts[i]
        ft.lifetime = ft.lifetime - dt
        ft.y = ft.y - 20 * dt
        if ft.lifetime <= 0 then
            table.remove(self.floatingTexts, i)
        end
    end

    for i = #npcs, 1, -1 do
        local npc = npcs[i]
        if npc then
            npc.frameTimer = npc.frameTimer + dt
            if npc.frameTimer >= npc.frameDuration then
                npc.frameTimer = npc.frameTimer - npc.frameDuration
                npc.frame = (npc.frame % 3) + 1
            end
            npc.lifetime = npc.lifetime - dt
            if npc.lifetime <= 0 or npc.disappear then
                table.remove(npcs, i)
            end
        end
    end
end

function RandomItems:draw()
    local scale = 2
    local pulse = 0.75 + 0.25 * sin(love.timer.getTime() * 4)
    for _, item in ipairs(self.items) do
        if item.image then
            if item.type == "shrine" then
                love.graphics.setColor(1, 1, 0, 0.5 * pulse)
                for ox = -2, 2 do
                    for oy = -2, 2 do
                        if item.quads then
                            love.graphics.draw(item.image, item.quads[item.frame], item.x + ox, item.y + oy, 0, scale, scale)
                        else
                            love.graphics.draw(item.image, item.x + ox, item.y + oy, 0, scale, scale)
                        end
                    end
                end
                love.graphics.setColor(1, 1, 1, 1)
                if item.quads then
                    love.graphics.draw(item.image, item.quads[item.frame], item.x, item.y, 0, scale, scale)
                else
                    love.graphics.draw(item.image, item.x, item.y, 0, scale, scale)
                end
            elseif item.type == "event" then
                if item.quads then
                    love.graphics.draw(item.image, item.quads[item.frame], item.x, item.y, 0, scale, scale)
                else
                    love.graphics.draw(item.image, item.x, item.y, 0, scale, scale)
                end
            else
                love.graphics.setColor(1, 1, 0, 0.5 * pulse)
                for ox = -2, 2 do
                    for oy = -2, 2 do
                        love.graphics.draw(item.image, item.x + ox, item.y + oy, 0, scale, scale)
                    end
                end
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(item.image, item.x, item.y, 0, scale, scale)
            end
        end
    end

    for _, npc in ipairs(npcs) do
        if npc.image then
            love.graphics.draw(npc.image, npc.quads[npc.frame], npc.x, npc.y, 0, scale, scale)
        end
    end
end

function RandomItems:drawFloatingTexts()
    for _, ft in ipairs(self.floatingTexts) do
        local alpha = ft.lifetime / ft.totalLifetime
        love.graphics.setColor(ft.color[1], ft.color[2], ft.color[3], alpha)
        love.graphics.print(ft.text, ft.x, ft.y)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function RandomItems:checkCollisions()
    if not player or not player.characters then return end
    for _, item in ipairs(self.items) do
        for _, char in pairs(player.characters) do
            local dx = item.x - char.x
            local dy = item.y - char.y
            local d = sqrt(dx * dx + dy * dy)
            if d < (item.radius + (char.radius or 16)) and not item.collected then
                item:onCollect()
                item.collected = true
            end
        end
    end
end

return RandomItems
