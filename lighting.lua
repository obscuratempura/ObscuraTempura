-- lighting.lua
local lighting = {}
lighting.lightSources = {}

local lightCanvas = nil
local lightImage

function lighting.load()
  local size = 256
  local imageData = love.image.newImageData(size, size)
  local center = size / 2
  for y = 0, size - 1 do
    for x = 0, size - 1 do
      local dx = x - center
      local dy = y - center
      local distance = math.sqrt(dx * dx + dy * dy)
      local alpha = 1 - math.min(distance / center, 1)
      imageData:setPixel(x, y, 1, 1, 1, alpha)
    end
  end
  lightImage = love.graphics.newImage(imageData)
  lightImage:setFilter("linear", "linear")
end

function lighting.addLight(x, y, radius)
  table.insert(lighting.lightSources, { x = x, y = y, radius = radius })
end

function lighting.clearLights()
  lighting.lightSources = {}
end

-- New helper: creates and returns an overlay canvas with full darkness and light spots added.
function lighting.drawOverlay()
  local overlay = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
  love.graphics.setCanvas(overlay)
    -- Fill with full darkness (black)
    love.graphics.clear(0, 0, 0, 1)
    -- Set additive blend so that light spots add brightness.
    love.graphics.setBlendMode("add")
    for _, light in ipairs(lighting.lightSources) do
      local scale = light.radius / (lightImage:getWidth() / 2)
      love.graphics.draw(lightImage, light.x, light.y, 0, scale, scale, lightImage:getWidth() / 2, lightImage:getHeight() / 2)
    end
    love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas()
  return overlay
end

return lighting
