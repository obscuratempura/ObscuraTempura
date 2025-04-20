-- object_manager.lua
local ObjectManager = {}
local love = love  -- Ensure love is in scope

-- Table to store object definitions
ObjectManager.definitions = {
    hauntedtree = {
        sprite = "assets/bonepittiles/hauntedtree.png",
        width = 32,    -- Collision width
        height = 32,   -- Collision height
        visualWidth = 32,  -- Visual width
        visualHeight = 32, -- Visual height
        collisionType = "rectangle",
        collisionBox = {
            width = 32,
            height = 32
        },
        scale = 2  -- Add scale factor
    },
    -- Add more definitions here...
}

-- Update the handleCollision function
function ObjectManager.handleCollision(object, character)
    local def = ObjectManager.definitions[object.type]
    if not def then return false end

    local scale = def.scale or 1
    -- Use the defined collision dimensions, scaled
    local objWidth = (def.collisionBox and def.collisionBox.width or def.width) * scale
    local objHeight = (def.collisionBox and def.collisionBox.height or def.height) * scale
    local halfWidth = objWidth / 2
    local halfHeight = objHeight / 2
    local charRadius = character.radius or 8  -- Default character radius

    -- Calculate object bounds (centered)
    local leftBound = object.x - halfWidth
    local rightBound = object.x + halfWidth
    local topBound = object.y - halfHeight
    local bottomBound = object.y + halfHeight

    -- Simple AABB vs Circle collision check
    local closestX = math.max(leftBound, math.min(character.x, rightBound))
    local closestY = math.max(topBound, math.min(character.y, bottomBound))
    local distX = character.x - closestX
    local distY = character.y - closestY
    local distanceSquared = (distX * distX) + (distY * distY)

    if distanceSquared < (charRadius * charRadius) then
        -- Collision detected!
        local distance = math.sqrt(distanceSquared)
        local overlap = charRadius - distance

        -- Avoid division by zero if distance is very small (character center is inside)
        if distance < 0.0001 then
             -- If directly on top, push slightly away (e.g., upwards)
             character.x = character.x + 0.1 -- Small nudge
             character.y = character.y - charRadius -- Push out vertically
             return true
        end

        -- Calculate push direction (away from the closest point on the rectangle)
        local pushX = distX / distance
        local pushY = distY / distance

        -- Move character out of collision
        character.x = character.x + pushX * overlap
        character.y = character.y + pushY * overlap

        return true -- Indicate collision occurred and was handled
    end

    return false -- No collision
end

-- Load object assets into memory (you can extend this to load from files)
function ObjectManager.loadAssets()
    for name, def in pairs(ObjectManager.definitions) do
        def.image = love.graphics.newImage(def.sprite)
        def.image:setFilter("nearest", "nearest")
    end
end

-- Spawn an object off-screen relative to the player's position
function ObjectManager.spawnObject(name, playerX, playerY)
    local def = ObjectManager.definitions[name]
    if not def then
        error("Object definition for " .. name .. " not found.")
    end

    local angle = math.random() * 2 * math.pi
    local distance = math.random(800, 1000)
    local posX = playerX + math.cos(angle) * distance
    local posY = playerY + math.sin(angle) * distance

    local object = {
        type = name,
        x = posX,
        y = posY,
        width = def.width,
        height = def.height,
        visualWidth = def.visualWidth,
        visualHeight = def.visualHeight,
        scale = def.scale or 2
    }

    return object
end

-- Draw a spawned object
function ObjectManager.drawObject(object)
    local def = ObjectManager.definitions[object.type]
    if not def then return end

    local scale = def.scale or 1
    love.graphics.draw(
        def.image,
        object.x - (def.visualWidth * scale)/2,
        object.y - (def.visualHeight * scale)/2,
        0,
        scale,
        scale
    )
end

return ObjectManager
