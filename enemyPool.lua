-- filepath: c:\Users\rpinc\Desktop\tacticalautoshooterv0.7\enemyPool.lua

local EnemyPool = {}
EnemyPool._pools = {}   -- Stores idle instances: EnemyPool._pools[enemyType] = {enemy1, enemy2, ...}
EnemyPool._enemyNewFunc = nil   -- To store the Enemy.new function
EnemyPool._enemyResetFunc = nil -- To store the Enemy:reset function

-- NEW: Function to register the necessary Enemy methods
function EnemyPool.registerEnemyMethods(newFunc, resetFunc)
    if type(newFunc) ~= "function" or type(resetFunc) ~= "function" then
        error("EnemyPool.registerEnemyMethods requires valid 'new' and 'reset' functions.")
    end
    EnemyPool._enemyNewFunc = newFunc
    EnemyPool._enemyResetFunc = resetFunc
    print("Enemy methods registered with EnemyPool.") -- Debug print
end

-- Acquire an enemy instance (either from pool or create new)
function EnemyPool.acquire(type, x, y, playerLevel, level)
    -- Ensure methods are registered before acquiring
    if not EnemyPool._enemyNewFunc or not EnemyPool._enemyResetFunc then
        error("EnemyPool cannot acquire: Enemy methods not registered. Call EnemyPool.registerEnemyMethods first.")
    end

    local pool = EnemyPool._pools[type]
    local enemyInstance

    -- Check if a pool exists for this type and if it has idle instances
    if pool and #pool > 0 then
        -- Reuse an existing instance
        enemyInstance = table.remove(pool)
        -- Reset its state using the registered Enemy:reset method
        -- Note: resetFunc is a method, so it needs the instance passed first
        EnemyPool._enemyResetFunc(enemyInstance, type, x, y, playerLevel, level)
        -- print(string.format("Reused enemy of type: %s (Pool size: %d)", type, #pool)) -- Debug print
    else
        -- No idle instances available, create a new one using the registered Enemy.new
        enemyInstance = EnemyPool._enemyNewFunc(type, x, y, playerLevel, level)
        -- print(string.format("Created new enemy of type: %s", type)) -- Debug print
        -- Ensure the pool table exists for this type if it's the first time
        if not EnemyPool._pools[type] then
             EnemyPool._pools[type] = {}
        end
    end

    enemyInstance.isPooled = false -- Mark as active (not in pool)
    return enemyInstance
end

-- Release an enemy instance back into its type-specific pool
function EnemyPool.release(enemyInstance)
    -- Basic validation and prevent double-releasing
    if not enemyInstance or not enemyInstance.type or enemyInstance.isPooled then
        return
    end

    -- Ensure the pool table exists
    EnemyPool._pools[enemyInstance.type] = EnemyPool._pools[enemyInstance.type] or {}

    -- Optional: Perform any cleanup needed before pooling (e.g., stop particle systems)
    enemyInstance.activeParticles = {} -- Clear particles on release
    enemyInstance.vx = 0 -- Stop movement
    enemyInstance.vy = 0
    enemyInstance.statusEffects = {} -- Clear status effects
    enemyInstance.timers = {} -- Clear timers
    enemyInstance.projectiles = {} -- Clear projectiles

    -- Add the instance back to the pool
    enemyInstance.isPooled = true -- Mark as pooled
    table.insert(EnemyPool._pools[enemyInstance.type], enemyInstance)
    -- print(string.format("Released enemy of type: %s (Pool size: %d)", enemyInstance.type, #EnemyPool._pools[enemyInstance.type])) -- Debug print
end

-- Optional: Function to pre-warm the pool
function EnemyPool.prewarm(type, count)
     -- Ensure methods are registered before prewarming
    if not EnemyPool._enemyNewFunc then
        error("EnemyPool cannot prewarm: Enemy 'new' method not registered.")
    end
    EnemyPool._pools[type] = EnemyPool._pools[type] or {}
    local pool = EnemyPool._pools[type]
    local created = 0
    for i = 1, count do
        if #pool < count then -- Only create if needed
             -- Use the registered Enemy.new function
             local e = EnemyPool._enemyNewFunc(type, -1000, -1000) -- Create off-screen
             e.isPooled = true -- Mark as pooled immediately
             table.insert(pool, e)
             created = created + 1
        end
    end
    -- print(string.format("Prewarmed pool for %s: Added %d instances (Total: %d)", type, created, #pool))
end

-- Optional: Function to clear the pool (e.g., on level change)
function EnemyPool.clearPools()
    EnemyPool._pools = {}
    -- print("Cleared all enemy pools.")
end

return EnemyPool