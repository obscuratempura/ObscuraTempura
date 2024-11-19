local Overworld = {}
local Maze = require("maze")  -- Ensure the path to the Maze file is correct
local Level2 = require("level2")  -- Require the second level module
local OverworldEffects = require("overworld_effects")

-- Define the camera offset values
local cameraOffsetX = 100  -- Positive value shifts the camera to the right
local cameraOffsetY = -50  -- Negative value shifts the camera up




-- Load the spritesheet
Overworld.mapImage = love.graphics.newImage("assets/overworld_map_spritesheet.png")
Overworld.mapImage:setFilter("nearest", "nearest")

-- Number of frames in the spritesheet
Overworld.totalFrames = 8  -- Adjust this number to match your spritesheet

-- Frame dimensions
Overworld.frameWidth = Overworld.mapImage:getWidth() / Overworld.totalFrames
Overworld.frameHeight = Overworld.mapImage:getHeight()

-- Keep the overworld dimensions as the full map size
Overworld.width = Overworld.frameWidth
Overworld.height = Overworld.frameHeight

-- Animation variables
Overworld.currentFrame = 1
Overworld.animationTimer = 0
Overworld.animationSpeed = 0.5  -- Seconds per frame; adjust as needed

-- Set up quads for each frame
Overworld.frames = {}
for i = 0, Overworld.totalFrames - 1 do
    local quad = love.graphics.newQuad(
        i * Overworld.frameWidth, 0,
        Overworld.frameWidth, Overworld.frameHeight,
        Overworld.mapImage:getDimensions()
    )
    table.insert(Overworld.frames, quad)
end

Overworld.playerSprite = love.graphics.newImage("assets/ranger.png")
Overworld.playerSprite:setFilter("nearest", "nearest")  -- Keeps pixelated look
Overworld.visionRadius = 300
Overworld.nodeIcon = love.graphics.newImage("assets/bonepitnode.png")
Overworld.nodeIcon:setFilter("nearest", "nearest")
Overworld.nodeIcon2 = love.graphics.newImage("assets/draculsdennode.png")
Overworld.nodeIcon2:setFilter("nearest", "nearest")

Overworld.gothicFontLarge = love.graphics.newFont("fonts/gothic.ttf", 24)
Overworld.gothicFontSmall = love.graphics.newFont("fonts/gothic.ttf", 16)
Overworld.gothicFontTitle = love.graphics.newFont("fonts/gothic.ttf", 36)
Overworld.gothicFontLarge:setFilter("nearest", "nearest")
Overworld.gothicFontSmall:setFilter("nearest", "nearest")
Overworld.gothicFontTitle:setFilter("nearest", "nearest")

-- Bobbing parameters
Overworld.bobAmplitude = 5
Overworld.bobFrequency = 20
Overworld.bobOffset = -5

-- Window dimensions
Overworld.windowWidth = love.graphics.getWidth()
Overworld.windowHeight = love.graphics.getHeight()

Overworld.nodeHoverColors = {
    {0.0, 0.0, 1.0},    -- Blue for Node 1
    {0.6, 0.0, 0.0},    -- Blood red for Node 2
    -- Extend this list for additional nodes as needed
}

Overworld.hoveredButton = false
-- Define scaling factors
local scaleFactor
local zoomLevel = 4.5  -- Adjust zoom level as desired

-- Camera offset to center the player
local cameraX, cameraY = 0, 0

-- Function to dynamically scale node positions
function Overworld.scaleNodes()
    for _, node in ipairs(Overworld.nodes) do
        node.scaledX = node.x * scaleFactor
        node.scaledY = node.y * scaleFactor
    end
end

-- Node positions (positions are placeholders)
Overworld.nodes = {
    {x = 105, y = 550, name = "Node0", details = "Details about Node0"},
    {x = 105, y = 373, name = "Node1", details = "Details about Node1"},
    {x = 358, y = 373, name = "Node2", details = "Details about Node2"},
    {x = 358, y = 563, name = "Node3", details = "Details about Node3"},
    {x = 615, y = 563, name = "Node4", details = "Details about Node4"},
    {x = 615, y = 210, name = "Node5", details = "Details about Node5"},
    {x = 905, y = 210, name = "Node6", details = "Details about Node6"},
    {x = 905, y = 410, name = "Node7", details = "Details about Node7"},
    {x = 905, y = 630, name = "Node8", details = "Details about Node8"},
    {x = 1095, y = 630, name = "Node9", details = "Details about Node9"}
}


OverworldEffects.init(Overworld.nodes)

-- Node connections (paths)
Overworld.paths = {
    {1, 2}, -- Connect Node 0 to Node 1
    {2, 3}, {3, 4}, {4, 5}, {5, 6}, {6, 7}, {7, 8}, {8, 9}, {9, 10}
}


-- Start at the first node
Overworld.selectedNode = 2

-- Player properties
Overworld.playerSize = 10

-- Player position (will be updated to scaled positions)
Overworld.playerX = Overworld.nodes[Overworld.selectedNode].x
Overworld.playerY = Overworld.nodes[Overworld.selectedNode].y

-- Player movement variables
Overworld.moveSpeed = 300
Overworld.moving = false
Overworld.targetNode = Overworld.selectedNode
Overworld.playerDirection = -1  -- -1 for left-facing sprite, 1 for right-facing

-- Variables for the button position and size
Overworld.buttonX = 0
Overworld.buttonY = 0
Overworld.buttonWidth = 0
Overworld.buttonHeight = 0

function Overworld.getConnectedNodes(nodeIndex)
    local connectedNodes = {}
    for _, path in ipairs(Overworld.paths) do
        if path[1] == nodeIndex then
            table.insert(connectedNodes, path[2])
        elseif path[2] == nodeIndex then
            table.insert(connectedNodes, path[1])
        end
    end
    return connectedNodes
end
function Overworld.findConnectedNodeInDirection(nodeIndex, direction)
    local connectedNodes = Overworld.getConnectedNodes(nodeIndex)
    local currentNode = Overworld.nodes[nodeIndex]
    local bestNodeIndex = nil
    local minDistance = math.huge

    for _, connectedNodeIndex in ipairs(connectedNodes) do
        local node = Overworld.nodes[connectedNodeIndex]
        local dx = node.scaledX - currentNode.scaledX
        local dy = node.scaledY - currentNode.scaledY

        if direction == 'up' and dy < 0 then
            if math.abs(dy) < minDistance then
                minDistance = math.abs(dy)
                bestNodeIndex = connectedNodeIndex
            end
        elseif direction == 'down' and dy > 0 then
            if dy < minDistance then
                minDistance = dy
                bestNodeIndex = connectedNodeIndex
            end
        elseif direction == 'left' and dx < 0 then
            if math.abs(dx) < minDistance then
                minDistance = math.abs(dx)
                bestNodeIndex = connectedNodeIndex
            end
        elseif direction == 'right' and dx > 0 then
            if dx < minDistance then
                minDistance = dx
                bestNodeIndex = connectedNodeIndex
            end
        end
    end
    return bestNodeIndex
end


-- Function to handle window resizing
function Overworld.resize(w, h)
    Overworld.windowWidth = w
    Overworld.windowHeight = h

    -- Calculate scaling factors with zoom level
    scaleFactor = zoomLevel  -- Use fixed zoom level
    -- Re-scale node positions
    Overworld.scaleNodes()

    -- Update player position to scaled coordinates
    Overworld.updatePlayerPosition()
end

-- Function to update player position based on the selected node
function Overworld.updatePlayerPosition()
    Overworld.playerX = Overworld.nodes[Overworld.selectedNode].scaledX
    Overworld.playerY = Overworld.nodes[Overworld.selectedNode].scaledY
end

function Overworld.update(dt)
    if Overworld.moving then
        local target = Overworld.nodes[Overworld.targetNode]
        local dx = target.scaledX - Overworld.playerX
        local dy = target.scaledY - Overworld.playerY
        local distance = math.sqrt(dx * dx + dy * dy)

        if distance < Overworld.moveSpeed * dt then
            Overworld.playerX = target.scaledX
            Overworld.playerY = target.scaledY
            Overworld.selectedNode = Overworld.targetNode
            Overworld.moving = false
        else
            Overworld.playerX = Overworld.playerX + (dx / distance) * Overworld.moveSpeed * dt
            Overworld.playerY = Overworld.playerY + (dy / distance) * Overworld.moveSpeed * dt
            Overworld.bobOffset = Overworld.bobOffset + dt * Overworld.bobFrequency
        end
    end
    OverworldEffects.update(Overworld.playerX, Overworld.playerY, Overworld.nodes, dt, Overworld.visionRadius)

    -- Update animation timer
    Overworld.animationTimer = Overworld.animationTimer + dt
    if Overworld.animationTimer >= Overworld.animationSpeed then
        Overworld.animationTimer = Overworld.animationTimer - Overworld.animationSpeed
        Overworld.currentFrame = Overworld.currentFrame + 1
        if Overworld.currentFrame > Overworld.totalFrames then
            Overworld.currentFrame = 1
        end
    end

    -- Update camera position with the offset applied
    cameraX = (Overworld.playerX - Overworld.windowWidth / 2) + cameraOffsetX
    cameraY = (Overworld.playerY - Overworld.windowHeight / 2) + cameraOffsetY

    -- Clamp cameraX and cameraY to prevent moving beyond map boundaries
    cameraX = math.max(0, math.min(cameraX, Overworld.width * scaleFactor - Overworld.windowWidth))
    cameraY = math.max(0, math.min(cameraY, Overworld.height * scaleFactor - Overworld.windowHeight))

    -- Update hover state for the button
    local mouseX, mouseY = love.mouse.getPosition()
    Overworld.hoveredButton = (mouseX >= Overworld.buttonX and mouseX <= Overworld.buttonX + Overworld.buttonWidth and
                               mouseY >= Overworld.buttonY and mouseY <= Overworld.buttonY + Overworld.buttonHeight)
end

-- Draw function
function Overworld.draw()
    Overworld.drawMap()
    Overworld.drawPlayer()

    -- Draw the vision mask
    Overworld.drawVisionMask()
    OverworldEffects.draw(Overworld.playerX, Overworld.playerY, Overworld.visionRadius, cameraX, cameraY)
    -- Draw the UI on top of the vision mask
    Overworld.drawUI()
end

-- Function to draw the overworld map image with camera offset
function Overworld.drawMap()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(
        Overworld.mapImage,
        Overworld.frames[Overworld.currentFrame],
        -cameraX,
        -cameraY,
        0,
        scaleFactor,
        scaleFactor
    )
end

function Overworld.drawPlayer()
    local x = Overworld.playerX - cameraX
    local y = Overworld.playerY - cameraY + math.sin(Overworld.bobOffset) * Overworld.bobAmplitude
    local spriteScale = 3

    love.graphics.setColor(1, 1, 1)

    -- Flip the sprite horizontally based on playerDirection
    love.graphics.draw(
        Overworld.playerSprite,
        x, y,
        0,
        spriteScale * Overworld.playerDirection,
        spriteScale,
        Overworld.playerSprite:getWidth() / 2,
        Overworld.playerSprite:getHeight() / 2
    )
end

function Overworld.drawUI()
    if not Overworld.moving then
        -- Skip drawing the UI box if Node 0 is selected
        if Overworld.selectedNode == 1 then
            return
        end

        -- Check which node is selected and display the appropriate UI
        if Overworld.selectedNode == 2 then
            -- Node 1 UI settings (previously Node 1)
            drawNodeUI(
                "The Bone Pit",
                Overworld.nodeIcon,
                "A wretched place where the undead gather,\n drawn to the rotting remains of forsaken souls\n abandoned here by some dark, malevolent hand.",
                {0.192, 0.502, 0.627},
                {0.4, 0.4, 0.4},
                {0.7, 0.7, 0.7}
            )
        elseif Overworld.selectedNode == 3 then
            -- Node 2 UI settings (previously Node 2)
            drawNodeUI(
                "Dracul's Den",
                Overworld.nodeIcon2,
                "An ancient lair steeped in darkness, where Dracul himself awaits unwary adventurers.",
                {0.6, 0, 0},
                {0.5, 0, 0},
                {0.3, 0, 0}
            )
        end
    end
end



-- Helper function to draw the UI with button and highlight on hover
function drawNodeUI(titleText, iconImage, description, titleColor, outerBorderColor, innerBorderColor)
    Overworld.windowWidth, Overworld.windowHeight = love.graphics.getDimensions()

    local rightBuffer = 50
    local uiWidth = 300
    local uiHeight = 700
    local x = Overworld.windowWidth - uiWidth - rightBuffer
    local y = Overworld.windowHeight / 2 - uiHeight / 2

    local backgroundColor = {0, 0, 0}
    local descriptionColor = {0.85, 0.85, 0.8}

    -- Outer border
    love.graphics.setColor(outerBorderColor)
    love.graphics.setLineWidth(10)
    love.graphics.rectangle("line", x, y, uiWidth, uiHeight)

    -- Inner border
    love.graphics.setColor(innerBorderColor)
    love.graphics.setLineWidth(6)
    love.graphics.rectangle("line", x + 10, y + 10, uiWidth - 20, uiHeight - 20)

    -- Background fill
    love.graphics.setColor(backgroundColor)
    love.graphics.rectangle("fill", x + 10, y + 10, uiWidth - 20, uiHeight - 20)

    -- Icon
    local iconScale = 4
    local iconOffsetX = 10
    local iconOffsetY = 35
    local iconX = x + 40 + iconOffsetX
    local iconY = y + 10 + iconOffsetY
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(iconImage, iconX, iconY, 0, iconScale, iconScale)

    -- Title text
    love.graphics.setFont(Overworld.gothicFontTitle)
    love.graphics.setColor(titleColor)
    local titleStartX = x + 40 + iconImage:getWidth() * iconScale + 25
    local titleY = y + 30
    love.graphics.printf(titleText, titleStartX, titleY, uiWidth - (titleStartX - x) - 20, "center")

    -- Description text
    love.graphics.setFont(Overworld.gothicFontLarge)
    love.graphics.setColor(descriptionColor)
    local descriptionX = x + 20
    local descriptionY = iconY + iconImage:getHeight() * iconScale + 50
    love.graphics.printf(description, descriptionX, descriptionY, uiWidth - 40, "center")

    -- Button dimensions and position
    local buttonWidth = uiWidth - 40
    local buttonHeight = 50
    local buttonX = x + 20
    local buttonY = y + uiHeight - buttonHeight - 40
    Overworld.buttonX = buttonX
    Overworld.buttonY = buttonY
    Overworld.buttonWidth = buttonWidth
    Overworld.buttonHeight = buttonHeight

    -- Define hover colors based on node, using the specific blue color used in UI
    local hoverColors = {
        [1] = {0.192, 0.502, 0.627},  -- Blue for Node 1 (consistent with UI)
        [2] = {0.6, 0.0, 0.0},        -- Red for Node 2
        -- Add more colors for additional nodes here
    }

    -- Get mouse position and check hover state
    local mouseX, mouseY = love.mouse.getPosition()
    local isHovering = mouseX >= buttonX and mouseX <= buttonX + buttonWidth and mouseY >= buttonY and mouseY <= buttonY + buttonHeight

    -- Hover effect for the entire button
    if isHovering then
        local hoverColor = hoverColors[Overworld.selectedNode] or {1, 1, 1} -- Default to white if no specific color
        love.graphics.setColor(hoverColor)
        love.graphics.setLineWidth(6)
        love.graphics.rectangle("line", buttonX, buttonY, buttonWidth, buttonHeight)
    else
        love.graphics.setColor(1, 1, 1) -- Default white outline
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", buttonX, buttonY, buttonWidth, buttonHeight)
    end

    -- Button background and updated text
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight)
    love.graphics.setColor(1, 1, 1) -- Text color
    love.graphics.setFont(Overworld.gothicFontLarge)
    love.graphics.printf("Embark", buttonX, buttonY + buttonHeight / 2 - Overworld.gothicFontLarge:getHeight() / 2, buttonWidth, "center")
end


-- Function to draw the vision mask using stencil buffer
function Overworld.drawVisionMask()
    -- Define the stencil function
    local function stencilFunction()
        local x = Overworld.playerX - cameraX
        local y = Overworld.playerY - cameraY

        love.graphics.circle("fill", x, y, Overworld.visionRadius)
    end

    -- Set up the stencil
    love.graphics.stencil(stencilFunction, "replace", 1)
    love.graphics.setStencilTest("less", 1)

    -- Draw the semi-transparent black rectangle over the entire map area
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", -cameraX, -cameraY, Overworld.width * scaleFactor, Overworld.height * scaleFactor)

    -- Disable stencil test
    love.graphics.setStencilTest()
end

function Overworld.keypressed(key)
    if Overworld.moving then return end

    local directionKeys = {
        ['up'] = 'up',
        ['w'] = 'up',
        ['down'] = 'down',
        ['s'] = 'down',
        ['left'] = 'left',
        ['a'] = 'left',
        ['right'] = 'right',
        ['d'] = 'right',
    }

    local direction = directionKeys[key]
    if direction then
        local nextNode = Overworld.findConnectedNodeInDirection(Overworld.selectedNode, direction)
        if nextNode then
            Overworld.targetNode = nextNode
            Overworld.moving = true
            if direction == 'left' then
                Overworld.playerDirection = 1  -- Facing left
            elseif direction == 'right' then
                Overworld.playerDirection = -1  -- Facing right
            end
        end
    elseif key == "return" then
        -- Trigger loading the level when 'return' is pressed
        if not Overworld.moving then
            loadLevel(Overworld.selectedNode)
        end
    end
end


-- Function to load the selected level
function loadLevel(selectedNode)
    if selectedNode == 1 then
        currentLevel = Maze.new()  -- Load the Maze level
        print("Loading Maze level...")
        startGame()  -- Initialize the game
        gameState = "playing"
    elseif selectedNode == 2 then
        currentLevel = Level2.new()  -- Load Level2
        print("Loading Level2...")
        startGame()  -- Initialize the game
        gameState = "playing"
    else
        print("No level implemented for this node.")
    end
end

-- Function to handle mouse clicks on nodes and UI
function Overworld.mousepressed(x, y, button)
    if button == 1 then  -- Left mouse button
        -- Debugging information for the button click
        print("Mouse click detected at:", x, y)
        print("Button bounds:", Overworld.buttonX, Overworld.buttonY, Overworld.buttonWidth, Overworld.buttonHeight)

        -- Check if click is within the UI button's bounds
        if not Overworld.moving then
            if x >= Overworld.buttonX and x <= Overworld.buttonX + Overworld.buttonWidth and
               y >= Overworld.buttonY and y <= Overworld.buttonY + Overworld.buttonHeight then
                print("Enter Level button clicked")  -- Should print if the button click is detected
                loadLevel(Overworld.selectedNode)  -- Load the selected level
                return
            end
        end

        -- Adjust coordinates for map click detection with scale factor and camera offset
        local worldX = (x + cameraX) / scaleFactor
        local worldY = (y + cameraY) / scaleFactor

        -- Check if a node was clicked
        for i, node in ipairs(Overworld.nodes) do
            local distance = math.sqrt((worldX - node.x)^2 + (worldY - node.y)^2)
            if distance <= 25 then  -- Node radius (adjust as needed)
                if not Overworld.moving then
                    Overworld.targetNode = i
                    Overworld.moving = true
                    Overworld.playerDirection = (Overworld.playerX < node.scaledX) and -1 or 1
                end
                break
            end
        end
    end
end

-- Initialization function to set up scaling on game start
function Overworld.init()
    -- Calculate initial scaling factors
    scaleFactor = zoomLevel  -- Use fixed zoom level

    -- Scale node positions
    Overworld.scaleNodes()

    -- Update player position to scaled coordinates
    Overworld.updatePlayerPosition()
end

-- Call the initialization function
Overworld.init()

return Overworld