local MapGenerator = require("map_generator")
local TileLoader = require("tile_loader")

-- Ensure tiles are loaded
TileLoader.loadTiles()

local BackgroundMap = {}

local tileSize = 16
-- Dimensions are now taken from mapData
-- local mapWidth = 2064
-- local mapHeight = 2064

-- Generate map data (includes tiles and trees)
local mapData = MapGenerator.generateMap()
local mapTiles = mapData.tiles -- Extract the tile map
local mapWidth = mapData.width -- Get width from mapData
local mapHeight = mapData.height -- Get height from mapData

-- Create a canvas for the full map.
local canvas = love.graphics.newCanvas(mapWidth, mapHeight)

local function generateCanvas()
    love.graphics.setCanvas(canvas)
    love.graphics.clear()  -- clear canvas
    -- Iterate using the extracted mapTiles table
    for y = 1, #mapTiles do
        for x = 1, #mapTiles[y] do
            local tileID = mapTiles[y][x]
            local tile = TileLoader.tiles[tileID]
            if tile then
                love.graphics.draw(tile.image, tile.quad, (x-1)*tileSize, (y-1)*tileSize)
            else
                print("Warning: No tile found for tileID:", tileID)
            end
        end
    end
    -- Debug: draw a red border around the canvas so you know it’s being rendered.
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle("line", 0, 0, mapWidth, mapHeight)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setCanvas()  -- return to default canvas
end

generateCanvas()

function BackgroundMap.draw()
    love.graphics.draw(canvas, 0, 0)
end

-- Optionally, make trees accessible if needed elsewhere
-- BackgroundMap.trees = mapData.trees

return BackgroundMap
