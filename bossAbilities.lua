local Effects  = require("effects")
local Sprites  = require("sprites")
local Collision = require("collision")

local BossAbilities = {}

--------------------------------------------------------------------------------
-- Kristoff Boss Ambient Sounds Update (unchanged)
--------------------------------------------------------------------------------
function BossAbilities.updateKristoffSounds(boss, dt, sounds)
  boss.soundTimer = boss.soundTimer or 0
  boss.nextSoundInterval = boss.nextSoundInterval or math.random(5, 10)
  boss.soundTimer = boss.soundTimer + dt
  if boss.soundTimer >= boss.nextSoundInterval then
    if sounds and sounds.kristoffSpawn and #sounds.kristoffSpawn > 0 then
      local index = math.random(1, #sounds.kristoffSpawn)
      sounds.kristoffSpawn[index]:play()
    end
    boss.soundTimer = 0
    boss.nextSoundInterval = math.random(20, 25)
  end
end

--------------------------------------------------------------------------------
-- Constants for invulnerability thresholds and duration
--------------------------------------------------------------------------------
local THRESHOLD_70 = 0.70  -- Trigger when health falls below 70% (phase 1)
local THRESHOLD_50 = 0.50  -- Trigger when health falls below 50% (phase 2)
local THRESHOLD_30 = 0.30  -- Trigger when health falls below 30% (phase 3 extra boost)
local INVULN_DURATION = 60 -- 15 seconds duration

--------------------------------------------------------------------------------
-- Helper function to convert grid coordinates to world coordinates
--------------------------------------------------------------------------------
local function gridToWorld(gridX, gridY, gridOriginX, gridOriginY, cellSize)
    -- Center the effect within the grid cell
    local worldX = gridOriginX + (gridX - 0.5) * cellSize
    local worldY = gridOriginY + (gridY - 0.5) * cellSize
    return worldX, worldY
end

--------------------------------------------------------------------------------
-- Helper function to get valid neighbors for maze generation (jumps 2 cells)
--------------------------------------------------------------------------------
local function getMazeNeighbors(x, y, gridSize, grid)
    local neighbors = {}
    -- Directions check 2 cells away (N, S, E, W)
    local directions = {{0, -2}, {0, 2}, {-2, 0}, {2, 0}}

    for _, d in ipairs(directions) do
        local nx, ny = x + d[1], y + d[2]
        -- Check bounds and if the neighbor hasn't been visited (is still "poison")
        if nx >= 1 and nx <= gridSize and ny >= 1 and ny <= gridSize and grid[ny] and grid[ny][nx] == "poison" then
            table.insert(neighbors, {x = nx, y = ny})
        end
    end
    return neighbors
end

--------------------------------------------------------------------------------
-- New function to generate and spawn the poison maze pattern
--------------------------------------------------------------------------------
function BossAbilities.generateAndSpawnPoisonMaze(boss, effects, player)
    -- Configuration for the maze grid
    local gridSize = 20 -- Size of the grid (e.g., 20x20)
    local cellSize = 60 -- Size of each cell in pixels (adjust for path width)
    local gridOriginX = boss.x - (gridSize / 2) * cellSize
    local gridOriginY = boss.y - (gridSize / 2) * cellSize

    -- 1. Initialize Grid: Mark all cells as potential poison spots initially
    local grid = {}
    for y = 1, gridSize do
        grid[y] = {}
        for x = 1, gridSize do
            grid[y][x] = "poison" -- Start with all cells as poison
        end
    end

    -- 2. Generate Maze using Randomized DFS to carve safe paths
    local stack = {}
    -- Start carving from a random odd-numbered cell to ensure proper wall removal
    local startX = math.random(1, gridSize / 2) * 2 - 1
    local startY = math.random(1, gridSize / 2) * 2 - 1

    grid[startY][startX] = "safe" -- Mark the starting cell as safe
    table.insert(stack, {x = startX, y = startY})

    while #stack > 0 do
        local current = stack[#stack]
        local neighbors = getMazeNeighbors(current.x, current.y, gridSize, grid)

        if #neighbors > 0 then
            -- Choose a random unvisited neighbor
            local next = neighbors[math.random(#neighbors)]

            -- Carve the path: Mark the cell between current and next as safe
            local wallX = current.x + (next.x - current.x) / 2
            local wallY = current.y + (next.y - current.y) / 2
            if grid[wallY] then grid[wallY][wallX] = "safe" end

            -- Mark the neighbor as safe and move to it
            grid[next.y][next.x] = "safe"
            table.insert(stack, next) -- Push the neighbor onto the stack
        else
            -- No unvisited neighbors, backtrack
            table.remove(stack)
        end
    end

     -- Optional: Add a few extra random safe spots to make paths less strict
    local extraSafeSpots = math.floor(gridSize * gridSize * 0.05) -- e.g., 5% extra safe spots
    for _ = 1, extraSafeSpots do
        local rx = math.random(1, gridSize)
        local ry = math.random(1, gridSize)
        if grid[ry] then grid[ry][rx] = "safe" end
    end

    -- 3. Spawn Poison Zones: Place effects in cells marked "poison"
    for y = 1, gridSize do
        for x = 1, gridSize do
            if grid[y][x] == "poison" then
                local worldX, worldY = gridToWorld(x, y, gridOriginX, gridOriginY, cellSize)
                -- Create the poison zone effect with the correct duration
                local poisonWeb = Effects.new(
                    "poison_zone",
                    worldX,
                    worldY,
                    nil, nil, nil, nil, effects, nil, nil, nil, nil,
                    INVULN_DURATION -- <<< Use the invulnerability duration constant
                )
                poisonWeb.player = player -- Pass player reference if needed by the effect
                -- Adjust the visual/collision radius of the effect if necessary
                -- poisonWeb.radius = cellSize / 2 -- Example: Match radius to half cell size
                table.insert(effects, poisonWeb)
            end
        end
    end
    print("[BossAbilities] Generated and spawned poison maze.")
end

--------------------------------------------------------------------------------
-- Kristoff Boss Update Function (using behavior state switching)
--------------------------------------------------------------------------------
function BossAbilities.updateKristoff(boss, dt, player, effects, enemies, damageNumbers, sounds, summonedEntities, spawnEnemyFunc)
  -- Initialize cooldown variables on spawn if needed.
  if boss.webLungeCooldown == nil then boss.webLungeCooldown = 0 end
  if boss.webLungeCooldownTimer == nil then boss.webLungeCooldownTimer = 0 end
  
  boss.webLungeCooldown = math.max(boss.webLungeCooldown - dt, 0)
  boss.webLungeCooldownTimer = math.max(boss.webLungeCooldownTimer - dt, 0)
  
  -- Initialize phase and default properties on spawn.
  if not boss.phase then
    boss.phase = 1                -- Phase 1: initial vulnerable phase
    boss.behavior = "aggressive"  -- Normal behavior
    boss.originalAttackSpeed = boss.attackSpeed
    boss.originalDamage = boss.damage
    boss.originalSpeed = boss.speed
    boss.longMeleeRange = 300      -- Range for web lunge
    boss.webLungeTimer = 0         -- Timer for web lunge
    boss.invulTriggered70 = false  -- one‑time trigger flags
    boss.invulTriggered50 = false
    boss.invulTriggered30 = false
    -- Save the default sprite so we can revert later.
    boss.originalSprite = boss.sprite or nil
  end
  
  -- Update ambient sounds.
  BossAbilities.updateKristoffSounds(boss, dt, sounds)
  local healthRatio = boss.health / boss.maxHealth

  ------------------------------------------------------------------------------  
  -- Behavior: Invulnerable (only update once here)
  ------------------------------------------------------------------------------  
  if boss.behavior ~= "invulnerable" then
    if boss.phase == 1 and healthRatio <= THRESHOLD_70 and not boss.invulTriggered70 then
      print("Invulnerability triggered at 70%")
      boss.invulTriggered70 = true
      boss.behavior = "invulnerable"
      boss.invulTimer = INVULN_DURATION
      boss.flashTimer = 0  -- reset any flashing timer
      boss.originalSprite = boss.sprite  -- save current sprite
      boss.sprite = Sprites.animations.kristoff_invulnerable
       if boss.originalSprite then
    boss.sprite.offsetX = boss.originalSprite.offsetX or 0
    boss.sprite.offsetY = boss.originalSprite.offsetY or 0
  end
      boss.originalSpeed = boss.speed
      boss.speed = 0
      BossAbilities.generateAndSpawnPoisonMaze(boss, effects, player)
    elseif boss.phase == 2 and healthRatio <= THRESHOLD_50 and not boss.invulTriggered50 then
      print("Invulnerability triggered at 50%")
      boss.invulTriggered50 = true
      boss.behavior = "invulnerable"
      boss.invulTimer = INVULN_DURATION
      boss.flashTimer = 0
      boss.originalSprite = boss.sprite
      boss.sprite = Sprites.animations.kristoff_invulnerable
      if boss.originalSprite then
    boss.sprite.offsetX = boss.originalSprite.offsetX or 0
    boss.sprite.offsetY = boss.originalSprite.offsetY or 0
  end
      boss.originalSpeed = boss.speed
      boss.speed = 0
      BossAbilities.generateAndSpawnPoisonMaze(boss, effects, player)
    elseif boss.phase == 3 and healthRatio <= THRESHOLD_30 and not boss.invulTriggered30 then
      print("Extra invulnerability triggered at 30%")
      boss.invulTriggered30 = true
      boss.extraBoost = true
      boss.behavior = "invulnerable"
      boss.invulTimer = INVULN_DURATION
      boss.flashTimer = 0
      boss.originalSprite = boss.sprite
      boss.sprite = Sprites.animations.kristoff_invulnerable
       if boss.originalSprite then
    boss.sprite.offsetX = boss.originalSprite.offsetX or 0
    boss.sprite.offsetY = boss.originalSprite.offsetY or 0
  end
      boss.originalSpeed = boss.speed
      boss.speed = 0
      BossAbilities.generateAndSpawnPoisonMaze(boss, effects, player)
    end
  end

  if boss.behavior == "invulnerable" then
    -- Decrease timer only here (do not duplicate in Enemy:update)
    boss.invulTimer = boss.invulTimer - dt
    
    -- Force no movement and update sprite animation.
    boss.vx, boss.vy = 0, 0
    if boss.sprite and boss.sprite.update then
      boss.sprite:update(dt)
    end
    boss.flashingWhite = true

    if boss.invulTimer <= 0 then
      -- End invulnerability: revert to aggressive behavior.
      boss.behavior = "aggressive"
      boss.invulTimer = nil
      boss.flashingWhite = false
      boss.sprite = boss.originalSprite
      boss.speed = boss.originalSpeed

      if boss.phase == 1 then
        boss.phase = 2
        boss.attackSpeed = boss.originalAttackSpeed * 1.5
        boss.damage = boss.originalDamage * 1.2
        boss.speed = boss.originalSpeed * 1.2
        print("Transitioned to Phase 2")
      elseif boss.phase == 2 then
        boss.phase = 3
        boss.attackSpeed = boss.originalAttackSpeed * 1.8
        boss.damage = boss.originalDamage * 1.5
        boss.speed = boss.originalSpeed * 1.4
        print("Transitioned to Phase 3")
      elseif boss.phase == 3 and boss.extraBoost then
        boss.extraBoost = nil
        boss.attackSpeed = boss.attackSpeed * 1.1
        boss.damage = boss.damage * 1.1
        boss.speed = boss.speed * 1.1
        print("Phase 3 extra boost applied")
      end
    end
    return  -- Skip further updates while invulnerable.
  end

  ------------------------------------------------------------------------------  
  -- Normal Behavior (when not invulnerable)
  ------------------------------------------------------------------------------  
  boss.bombTimer = (boss.bombTimer or 0) + dt
  if boss.bombTimer >= (boss.bombCooldown or 10) then
    BossAbilities.throwSpiderBomb(boss, player, effects, enemies, damageNumbers, sounds)
    boss.bombTimer = 0
  end

  local distToPlayer = math.sqrt((player.x - boss.x)^2 + (player.y - boss.y)^2)
  if distToPlayer < boss.longMeleeRange and not boss.webLunge and boss.webLungeCooldownTimer <= 0 then
    print("Kristoff performs Web Lunge attack – Damage: " .. tostring(boss.damage))
    BossAbilities.performWebLunge(boss, player, effects, enemies, damageNumbers, sounds)
    boss.webLungeCooldownTimer = 3
  end

  if boss.webLunge then
    boss.webLunge.age = boss.webLunge.age + dt
    boss.webLunge.x = boss.webLunge.x + math.cos(boss.webLunge.angle) * boss.webLunge.speed * dt
    boss.webLunge.y = boss.webLunge.y + math.sin(boss.webLunge.angle) * boss.webLunge.speed * dt
    boss.webLunge.speed = math.max(boss.webLunge.speed - boss.webLunge.deceleration * dt, 0)
    local webLungeCollisionRadius = 20
    local dx = player.x - boss.webLunge.x
    local dy = player.y - boss.webLunge.y
    if math.sqrt(dx * dx + dy * dy) < webLungeCollisionRadius and not boss.webLunge.hasHit then
      print("Web Lunge hit player – Damage: " .. tostring(boss.damage))
      player:takeDamage(boss.damage)
      boss.webLunge.hasHit = true
      boss.webLunge = nil
    end
    if boss.webLunge and boss.webLunge.age >= boss.webLunge.lifetime then
      boss.webLunge = nil
    end
  end

  if boss.phase == 3 then
    boss.attackSpeed = boss.originalAttackSpeed * 1.8
    boss.damage = boss.originalDamage * 1.5
  end

  if player and player.characters and #player.characters > 0 then
    local target = player.characters[1]
    if target.x >= boss.x then
      boss.lastDirection = "right"
    else
      boss.lastDirection = "left"
    end
  end

  ------------------------------------------------------------------------------  
  -- Simplified Web Drop Ability:
  -- Every update, a timer is incremented. When it exceeds 1 second,
  -- a web enemy is spawned at a random position around Kristoff.
  ------------------------------------------------------------------------------  
  BossAbilities.webDrop(boss, dt, enemies, spawnEnemyFunc)
end

--------------------------------------------------------------------------------
-- Simplified Web Drop Ability
--------------------------------------------------------------------------------
function BossAbilities.webDrop(boss, dt, enemies, spawnEnemy)
  if not spawnEnemy then return end  -- Prevent error if spawnEnemy is nil
  boss.webDropInterval = boss.webDropInterval or 1.0
  boss.webDropMinRadius = boss.webDropMinRadius or 100
  boss.webDropMaxRadius = boss.webDropMaxRadius or 500
  
  boss.webDropTimer = (boss.webDropTimer or 0) + dt
  
  if boss.webDropTimer >= boss.webDropInterval then
    boss.webDropTimer = boss.webDropTimer - boss.webDropInterval
    local angle = math.random() * 2 * math.pi
    local distance = boss.webDropMinRadius + math.random() * (boss.webDropMaxRadius - boss.webDropMinRadius)
    local wx = boss.x + distance * math.cos(angle)
    local wy = boss.y + distance * math.sin(angle)
    -- Use the passed-in spawnEnemy function (should be EnemyPool.acquire)
    local web = spawnEnemy("web", wx, wy, nil, nil)
    table.insert(enemies, web)
  end
end

--------------------------------------------------------------------------------
-- Throw Spider Bomb Ability (Modified Target Logic)
--------------------------------------------------------------------------------
function BossAbilities.throwSpiderBomb(boss, player, effects, enemies, damageNumbers, sounds)
  local flightTime = 2
  local gravity    = 300

  -- --- MODIFICATION START ---
  -- Calculate a random target position around the player, avoiding directly in front.

  -- 1. Define min/max distance from player for the landing spot
  local minOffsetDistance = 100  -- Minimum distance from the player
  local maxOffsetDistance = 175 -- Maximum distance from the player

  -- 2. Generate random angle and distance
  local offsetAngle = math.random() * 2 * math.pi
  local offsetDistance = math.random(minOffsetDistance, maxOffsetDistance)

  -- 3. Calculate the target landing position based on player's current position + offset
  local targetX = player.x + math.cos(offsetAngle) * offsetDistance
  local targetY = player.y + math.sin(offsetAngle) * offsetDistance
  -- --- MODIFICATION END ---


  -- Calculate initial velocity needed to hit the targetX, targetY
  local dx = targetX - boss.x
  local dy = targetY - boss.y
  local vx = dx / flightTime
  local vy = (dy - 0.5 * gravity * flightTime^2) / flightTime -- Corrected gravity calculation

  local bomb = {
    x = boss.x,
    y = boss.y,
    vx = vx,
    vy = vy,
    gravity = gravity,
    radius = 8,
    type = "webbomb",
    lifetime = flightTime,
    age = 0,
    isDead = false,
    animation = Sprites.animations.webbomb,
  }

  -- Ensure boss.projectiles is initialized
  boss.projectiles = boss.projectiles or {}
  table.insert(boss.projectiles, bomb)

  if sounds and sounds.ability and sounds.ability.spiderBomb then
    sounds.ability.spiderBomb:play()
  end
end

--------------------------------------------------------------------------------
-- Web Lunge Attack (Long-Range Melee Variant)
--------------------------------------------------------------------------------
function BossAbilities.performWebLunge(boss, player, effects, enemies, damageNumbers, sounds)
  if boss.webLungeCooldown and boss.webLungeCooldown > 0 then return end
  
  local offsetX = math.random(-50, 50)
  local offsetY = math.random(-50, 50)
  local targetX = player.x + offsetX
  local targetY = player.y + offsetY
  
  local angle = math.atan2(targetY - boss.y, targetX - boss.x)
  local speed = 400
  local lifetime = 2.0
  local deceleration = 100
  
  boss.webLunge = {
    x = boss.x,
    y = boss.y,
    angle = angle,
    speed = speed,
    lifetime = lifetime,
    age = 0,
    deceleration = deceleration,
    type = "weblunge",
    color = {1, 1, 1, 1},
    hasHit = false,
  }
  
  boss.webLungeCooldown = 10
end

-- Revised draw function for Web Lunge:
function BossAbilities.drawWebLunge(webLunge, boss)
  if webLunge then
    local alpha = 1 - (webLunge.age / webLunge.lifetime)
    love.graphics.setColor(webLunge.color[1], webLunge.color[2], webLunge.color[3], alpha)
    love.graphics.setLineWidth(2)
    love.graphics.line(boss.x, boss.y, webLunge.x, webLunge.y)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

--------------------------------------------------------------------------------
-- Skitterer Spawn Ability (unchanged logic, uses spawnEnemy)
--------------------------------------------------------------------------------
function BossAbilities.spawnSkitterers(boss, enemies, spawnEnemy, more)
  if not spawnEnemy then return end -- Safety check
  local count = more and 5 or 3
  for i = 1, count do
    local angle = math.random() * 2 * math.pi
    local sx = boss.x + math.cos(angle) * 30
    local sy = boss.y + math.sin(angle) * 30
    -- Use the passed-in spawnEnemy function (should be EnemyPool.acquire)
    local skitter = spawnEnemy("skitter_spider", sx, sy, nil, nil)
    table.insert(enemies, skitter)
  end
  print("Spawned " .. count .. " skitterers")
end

--------------------------------------------------------------------------------
-- Simplified Check for Invulnerability (Used by enemy.lua)
--------------------------------------------------------------------------------
function BossAbilities.checkKristoffInvulnerability(boss)
  return boss.behavior == "invulnerable"
end

return BossAbilities
