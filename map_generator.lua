local MapGenerator = {}

local TileLoader = require("tile_loader")
local ObjectManager = require("object_manager") -- Ensure ObjectManager is required

-- Constants for map generation
local TILE_SIZE = 16 -- Pixels
local MAP_WIDTH_PIXELS = 2064
local MAP_HEIGHT_PIXELS = 2064

-- Tree generation parameters using Poisson Disk Sampling
local TREE_SPACING = 150       -- Minimum distance between trees
local K_SAMPLES = 30           -- Samples before rejection in Poisson Disk
local SAFE_ZONE_RADIUS = 200   -- <<< INCREASED FURTHER from 200
local TREE_TYPE = "hauntedtree"

-- Poisson Disk Sampling function (remains the same)
local function poissonDiskSampling(width, height, minSpacing, k)
    local cellSize = minSpacing / math.sqrt(2)
    local gridWidth = math.ceil(width / cellSize)
    local gridHeight = math.ceil(height / cellSize)
    local grid = {}
    for i = 1, gridWidth * gridHeight do
        grid[i] = nil
    end

    local samples = {}
    local processList = {}

    local function getGridIndex(x, y)
        local gx = math.floor(x / cellSize)
        local gy = math.floor(y / cellSize)
        return gy * gridWidth + gx + 1, gx, gy
    end

    local function inNeighbourhood(sample)
        local index, gx, gy = getGridIndex(sample.x, sample.y)
        for i = math.max(0, gx - 2), math.min(gridWidth - 1, gx + 2) do
            for j = math.max(0, gy - 2), math.min(gridHeight - 1, gy + 2) do
                local neighbor = grid[j * gridWidth + i + 1]
                if neighbor then
                    local dx = neighbor.x - sample.x
                    local dy = neighbor.y - sample.y
                    if math.sqrt(dx * dx + dy * dy) < minSpacing then
                        return true
                    end
                end
            end
        end
        return false
    end

    local function addSample(sample)
        table.insert(samples, sample)
        table.insert(processList, sample)
        local index, gx, gy = getGridIndex(sample.x, sample.y)
        grid[index] = sample
    end

    -- Start with a random sample.
    addSample({x = math.random() * width, y = math.random() * height})

    while #processList > 0 do
        local idx = math.random(#processList)
        local sample = processList[idx]
        local found = false
        for i = 1, k do
            local angle = math.random() * 2 * math.pi
            local mag = math.random() * minSpacing + minSpacing  -- between minSpacing and 2*minSpacing
            local newX = sample.x + math.cos(angle) * mag
            local newY = sample.y + math.sin(angle) * mag
            if newX >= 0 and newX < width and newY >= 0 and newY < height then
                local newSample = {x = newX, y = newY}
                if not inNeighbourhood(newSample) then
                    addSample(newSample)
                    found = true
                end
            end
        end
        if not found then
            table.remove(processList, idx)
        end
    end

    return samples
end

-- Modify the function signature to accept player spawn coordinates
function MapGenerator.generateMap(playerSpawnX, playerSpawnY)
    -- Default values if not provided (optional, but good practice)
    playerSpawnX = playerSpawnX or MAP_WIDTH_PIXELS / 2
    playerSpawnY = playerSpawnY or MAP_HEIGHT_PIXELS / 2

    local tiles = {} -- Use 'tiles' consistently for the tile map
    local tilesPerRow = MAP_WIDTH_PIXELS / TILE_SIZE
    local tilesPerCol = MAP_HEIGHT_PIXELS / TILE_SIZE

    -- Generate background tile map
    for y = 1, tilesPerCol do
        tiles[y] = {}
        for x = 1, tilesPerRow do
            tiles[y][x] = TileLoader.getRandomTile() or 1 -- Assign random tile ID
        end
    end

    -- Generate tree positions using Poisson Disk Sampling
    local samples = poissonDiskSampling(MAP_WIDTH_PIXELS, MAP_HEIGHT_PIXELS, TREE_SPACING, K_SAMPLES)
    local trees = {}
    local treeDef = ObjectManager.definitions[TREE_TYPE]

    if not treeDef then
        print("Warning: Tree definition not found for type:", TREE_TYPE)
        -- Handle error or return default values if necessary
    end

    for _, sample in ipairs(samples) do
        -- Calculate the minimum safe distance: player safe zone + tree's collision radius
        local treeRadius = math.max(treeDef.width or 0, treeDef.height or 0) * (treeDef.scale or 1) / 2
        local dx = sample.x - playerSpawnX
        local dy = sample.y - playerSpawnY
        if math.sqrt(dx * dx + dy * dy) >= (SAFE_ZONE_RADIUS + treeRadius) and treeDef then
            table.insert(trees, {
                x = sample.x,
                y = sample.y,
                type = TREE_TYPE,
                width = treeDef.width,
                height = treeDef.height,
                visualWidth = treeDef.visualWidth,
                visualHeight = treeDef.visualHeight,
                scale = treeDef.scale or 1,
                collisionType = treeDef.collisionType,
                collisionData = nil
            })
        end
    end

    local filteredTrees = {}
    for _, tree in ipairs(trees) do
        local dx = tree.x - playerSpawnX
        local dy = tree.y - playerSpawnY
        local treeRadius = math.max(tree.width or 0, tree.height or 0) * (tree.scale or 1) / 2
        if math.sqrt(dx * dx + dy * dy) >= (SAFE_ZONE_RADIUS + treeRadius) then
            table.insert(filteredTrees, tree)
        else
            print("Removed tree at", tree.x, tree.y, "too close to player")
        end
    end
    trees = filteredTrees

    -- Remove any trees too close to the boundary (64px margin)
    local boundaryMargin = 64
    local cleanTrees = {}
    local treeRadius = math.max(treeDef.width, treeDef.height) * (treeDef.scale or 1) / 2
    for _, t in ipairs(filteredTrees) do
        if t.x > (boundaryMargin + treeRadius)
        and t.x < (MAP_WIDTH_PIXELS  - boundaryMargin - treeRadius)
        and t.y > (boundaryMargin + treeRadius)
        and t.y < (MAP_HEIGHT_PIXELS - boundaryMargin - treeRadius) then
            table.insert(cleanTrees, t)
        end
    end
    trees = cleanTrees  -- only keep those well inside

    -- …after your player‐safe filtering, before drawing the hedge…

    -- 1) Peel off only those Poisson trees well inside all hedge layers + 64px
    local def            = ObjectManager.definitions[TREE_TYPE]
    local stepX, stepY   = def.visualWidth * def.scale, def.visualHeight * def.scale
    local layers         = 6
    local bufferMargin   = 64
    local boundaryMargin = layers * stepX + bufferMargin
    local treeRadius     = math.max(def.width, def.height) * def.scale * 0.5

    local interior = {}
    for _, t in ipairs(trees) do
      if t.x > (boundaryMargin + treeRadius)
      and t.x < (MAP_WIDTH_PIXELS  - boundaryMargin - treeRadius)
      and t.y > (boundaryMargin + treeRadius)
      and t.y < (MAP_HEIGHT_PIXELS - boundaryMargin - treeRadius)
      then
        table.insert(interior, t)
      end
    end
    trees = interior

    -- 2) Now build your multi‐layer hedge
    for layer = 0, layers - 1 do
        local insetX = stepX/2 + layer * stepX
        local insetY = stepY/2 + layer * stepY
        local maxX   = MAP_WIDTH_PIXELS - insetX
        local maxY   = MAP_HEIGHT_PIXELS - insetY

        -- top & bottom
        for x = insetX, maxX, stepX do
            table.insert(trees, { x = x, y = insetY, type = TREE_TYPE, scale = def.scale })
            table.insert(trees, { x = x, y = maxY,    type = TREE_TYPE, scale = def.scale })
        end
        -- left & right
        for y = insetY, maxY, stepY do
            table.insert(trees, { x = insetX, y = y,    type = TREE_TYPE, scale = def.scale })
            table.insert(trees, { x = maxX,    y = y,    type = TREE_TYPE, scale = def.scale })
        end
    end

    -- …after your multi‐layer hedge loop, before spawn logic…

    local marginX, marginY = stepX/2, stepY/2  -- <- add this

    -- 3) Now pick a spawn point *inside* that hedge, at least one full tree‐row + collision away
    local innerMarginX    = marginX + stepX
    local innerMarginY    = marginY + stepY
    local PLAYER_RADIUS   = 8
    local treeRadiusSpawn = math.max(def.width, def.height) * def.scale * 0.5

    local minX = innerMarginX + treeRadiusSpawn + PLAYER_RADIUS
    local maxX = MAP_WIDTH_PIXELS  - (innerMarginX + treeRadiusSpawn + PLAYER_RADIUS)
    local minY = innerMarginY + treeRadiusSpawn + PLAYER_RADIUS
    local maxY = MAP_HEIGHT_PIXELS - (innerMarginY + treeRadiusSpawn + PLAYER_RADIUS)

    local spawnX, spawnY
    repeat
        spawnX = math.random(minX, maxX)
        spawnY = math.random(minY, maxY)
        local ok = true
        for _, t in ipairs(trees) do
            local dx, dy = spawnX - t.x, spawnY - t.y
            if math.sqrt(dx*dx + dy*dy) < (treeRadiusSpawn + PLAYER_RADIUS) then
                ok = false
                break
            end
        end
    until ok

    return {
      tiles          = tiles,
      trees          = trees,
      width          = MAP_WIDTH_PIXELS,
      height         = MAP_HEIGHT_PIXELS,
      spawnX         = spawnX,
      spawnY         = spawnY,
      boundaryMargin = boundaryMargin  -- NEW
    }
end

return MapGenerator
