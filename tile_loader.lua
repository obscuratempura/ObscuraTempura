-- tile_loader.lua
local TileLoader = {}
TileLoader.tiles = {}

function TileLoader.loadTiles()
    local tilesheet = love.graphics.newImage("assets/bonepittiles/tilesheet_updated.png")
    tilesheet:setFilter("nearest", "nearest")

    local tileSize = 16 -- Size of each tile
    local sheetWidth = tilesheet:getWidth()
    local sheetHeight = tilesheet:getHeight()

    -- Calculate number of tiles in the sheet
    local tilesPerRow = math.floor(sheetWidth / tileSize)
    local tilesPerCol = math.floor(sheetHeight / tileSize)

    for y = 0, tilesPerCol - 1 do
        for x = 0, tilesPerRow - 1 do
            local quad = love.graphics.newQuad(
                x * tileSize, y * tileSize,
                tileSize, tileSize,
                sheetWidth, sheetHeight
            )

            -- Define weights: Assume black tiles are in the first half of the tilesheet
            local isBlackTile = (y * tilesPerRow + x) < (tilesPerRow * tilesPerCol) / 2
            local weight = isBlackTile and 10 or 1 -- Black tiles get weight 10, others get weight 1

            -- Assign a unique ID to each tile
            local id = #TileLoader.tiles + 1

            table.insert(TileLoader.tiles, {
                id = id,
                quad = quad,
                image = tilesheet,
                weight = weight
            })
        end
    end

    if #TileLoader.tiles == 0 then
        error("Error: No tiles loaded from the tilesheet. Check the tilesheet file.")
    end
end


-- Function to get a weighted random tile
function TileLoader.getRandomTile()
    local cumulativeWeights = {}
    local totalWeight = 0

    -- Build a cumulative weight table
    for _, tile in ipairs(TileLoader.tiles) do
        totalWeight = totalWeight + tile.weight
        table.insert(cumulativeWeights, totalWeight)
    end

    -- Generate a random number between 1 and totalWeight
    local randomWeight = love.math.random(totalWeight)

    -- Find the tile corresponding to the randomWeight
    for i, weightThreshold in ipairs(cumulativeWeights) do
        if randomWeight <= weightThreshold then
            return TileLoader.tiles[i].id
        end
    end

    -- Fallback in case of an error
    return TileLoader.tiles[1].id
end


return TileLoader
