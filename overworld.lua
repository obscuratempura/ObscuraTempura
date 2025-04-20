local Overworld = {}
local Bonepit         = require("Bonepit")
local Level2          = require("level2")
local OverworldEffects= require("overworld_effects")
local Options         = require("options")
local Tutorial        = require("tutorial")
local SpiderForest     = require("spiderforest")

local Item         = require("item")
local Equipment = require("equipment")
Overworld.equipment = Equipment.new()
equipment = Overworld.equipment  -- Global alias for compatibility


local talentSystem = require("talentSystem")
local statWindow      = require("stat_window")

local Player = require("player")
local playerInstance = Player.new(nil)  -- Pass nil if no StatsSystem is needed here.
Overworld.player = playerInstance         -- Store the player in Overworld for later use.
Overworld.statsWindow = statWindow.new(playerInstance)



Overworld.colors = {
    darkRedBrown     = {86/255, 33/255, 42/255, 1},        -- Retained for specific elements
    deepPurple       = {67/255, 33/255, 66/255, 1},        -- Retained for thematic accents
    grayishPurple    = {95/255, 87/255, 94/255, 1},        -- Retained for versatility
    mutedTeal        = {77/255, 102/255, 96/255, 1},       -- Retained for UI elements
    rustRed          = {173/255, 64/255, 48/255, 1},        -- Retained for specific accents
    mutedBrick       = {144/255, 75/255, 65/255, 1},        -- Retained for popup borders
    darkRose         = {155/255, 76/255, 99/255, 1},        -- Used for talent names
    mutedOliveGreen  = {149/255, 182/255, 102/255, 1},      -- Retained for balance
    peachyOrange     = {231/255, 155/255, 124/255, 1},       -- Retained for subtle accents
    warmGray         = {166/255, 153/255, 152/255, 1},       -- Used for common item quality
    paleYellow       = {246/255, 242/255, 195/255, 1},       -- Used for text readability
    darkTeal         = {54/255, 69/255, 79/255, 1},          -- Changed to charcoalGray for UI backgrounds
    orangeGold       = {239/255, 158/255, 78/255, 1},        -- Used for active tabs and borders
    pastelMint       = {142/255, 184/255, 158/255, 1},       -- Retained for potential use
    smokyBlue        = {70/255, 85/255, 95/255, 1},          -- Used for rare item quality
    burntSienna      = {233/255, 116/255, 81/255, 1},        -- Used for Combat tab
    sageGreen        = {148/255, 163/255, 126/255, 1},       -- Retained for balance
    dustyLavender    = {174/255, 160/255, 189/255, 1},       -- Used for Abilities tab
    mustardYellow    = {218/255, 165/255, 32/255, 1},        -- Used for talent points and legendary quality
    terraCotta       = {226/255, 114/255, 91/255, 1},         -- Retained for potential use
    charcoalGray     = {54/255, 69/255, 79/255, 1},          -- Used for tooltips and popups
    blushPink        = {222/255, 173/255, 190/255, 1},        -- Retained for potential use
    forestGreen      = {34/255, 85/255, 34/255, 1},          -- Retained for balance
    midnightBlue     = {25/255, 25/255, 112/255, 1},         -- Retained for specific elements
    
    talentName        = {155/255, 76/255, 99/255, 1},        -- darkRose
    talentDescription = {246/255, 242/255, 195/255, 1},      -- paleYellow
    talentPoints      = {218/255, 165/255, 32/255, 1},       -- mustardYellow
    talentRank        = {173/255, 64/255, 48/255, 1},        -- orangeGold (new color)
}



-- Quality Colors Mapping
local qualityColors = {
    common    = {227/255, 218/255, 201/255, 1},        -- grayishPurple
    rare      = {70/255, 85/255, 95/255, 1},        -- smokyBlue
    epic      = {155/255, 76/255, 99/255, 1},       -- darkRose
    legendary = {218/255, 165/255, 32/255, 1}       -- mustardYellow
}

local affixDisplayNames = {
    attackDamageFlat         = "Attack Damage",
    health                   = "Max Health",
    attackSpeedPercent       = "% Attack Speed",
    movementSpeed            = "Movement Speed",
    attackRange              = "Attack Range",
    grimReaperAbilityDamage  = "Grim Reaper Ability Damage",
    emberfiendAbilityDamage  = "Emberfiend Ability Damage",
    stormlichAbilityDamage   = "Stormlich Ability Damage",
    statusDuration           = "Status Duration",
    legendaryMaxHealth       = "Legendary Max Health"
}

-- Numerical values in affixes
local affixNumberColor = {0, 1, 0, 1} -- Green
local tooltipBackgroundColor = {0.1, 0.1, 0.1, 0.9}     -- charcoalGray
local tooltipBorderColor     = {239/255, 158/255, 78/255, 1}  -- orangeGold
local tooltipTextColor       = {246/255, 242/255, 195/255, 1} -- paleYellow
local tooltipPadding         = 10
local tooltipMaxWidth        = 300
local tooltipPosition        = {x = 550, y = 300}  -- Adjust X and Y as needed

Overworld.tooltip = {
    visible = false,
    lines = {},           -- Each entry: { text="...", color={r,g,b,a} }
    x = 550,
    y = 300,
    width = 200,
    height = 100
}

----------------------------------------------------------------
-- UI Colors, Fonts, and Dimensions
----------------------------------------------------------------
-- UI Colors Variables
local uiBackgroundColor    = {0.1, 0.1, 0.1, 0.9}     -- charcoalGray for UI background
local uiBorderColor        = {239/255, 158/255, 78/255, 1}    -- orangeGold for UI borders
local uiTextColor          = {246/255, 242/255, 195/255, 1}   -- paleYellow for UI text

-- Updated Talent Tabs Colors
local tabTalentsColor      = {67/255, 33/255, 66/255, 1}       -- deepPurple
local tabEquipmentColor    = {77/255, 102/255, 96/255, 1}      -- mutedTeal
local tabStatsColor        = {233/255, 116/255, 81/255, 1}     -- burntSienna

-- Popup Colors (Unchanged)
local popupBackgroundColor = {0.1, 0.1, 0.1, 0.9}            -- Blackish for popups background
local popupTitleBarColor   = {0, 0, 0, 0.7}                  -- Black with transparency for title bars
local popupBorderColor     = {239/255, 158/255, 78/255, 1}    -- orangeGold for popup borders
local popupTextColor       = {246/255, 242/255, 195/255, 1}   -- paleYellow for popup text

-- Increase popup size by 25%: from 400x300 to 450x375
local popupWidth  = 450
local popupHeight = 450

local generalTabColor   = {0.1, 0.1, 0.1, 0.9}   
local combatTabColor    = {0.1, 0.1, 0.1, 0.9}   
local abilitiesTabColor = {0.1, 0.1, 0.1, 0.9} 

-- Active Tab Color
local activeTabColor    = {173/255, 64/255, 48/255, 1}   

local promptFont   = love.graphics.newFont("fonts/gothic.ttf", 24)
local smallerFont  = love.graphics.newFont("fonts/gothic.ttf", 40)
local arrowImage   = love.graphics.newImage("assets/arrow.png")
local colorPalette = {
    {1, 1, 0, 1},
    {0, 1, 1, 1},
    {1, 0, 1, 1},
    {1, 0.5, 0, 1},
    {0.5, 0, 1, 1},
}
----------------------------------------------------------------
-- Popups for talents/equipment/stats
----------------------------------------------------------------
local popups = {
    talents = { visible = false, x = 20, y = 20, width = popupWidth, height = popupHeight },
    equipment = { visible = false, x = 800, y = 250, width = popupWidth, height = popupHeight },
    stats = { visible = false, x = 800, y = 250, width = popupWidth, height = popupHeight },
    removeConfirmation = { visible = false, item = nil, x = 0, y = 0, width = 300, height = 225 },
    soulLevelUp = { visible = false, lines = {}, x = 400, y = 215, width = 500, height = 300, timer = 0, duration = 10 },
    enterConfirmation = { visible = false, x = 0, y = 0, width = 300, height = 150 },  -- <-- NEW
}
local function closeAllPopupsExcept(exception)
  for key, popup in pairs(popups) do
    if key ~= exception then
      popup.visible = false
    end
  end
  Overworld.tooltip.visible = false
end

local function closeAllPopups()
  for key, popup in pairs(popups) do
    popup.visible = false
  end
  Overworld.tooltip.visible = false
end


local allTalents = talentSystem.getAllTalents()

-- 1) Create a table to hold talents by tab name
local talentTabData = {
    General   = {},
    Combat    = {},
    Abilities = {}
}

local talentTabs = {
    {name = "General",   active = true,  talents = {}},
    {name = "Combat",    active = false, talents = {}},
    {name = "Abilities", active = false, talents = {}}
}

-- 2) Put each talent from allTalents into the right sub-table
for _, t in ipairs(allTalents) do
    table.insert(talentTabData[t.tab], t)
end

-- 3) Now fill the talentTabs with those newly populated arrays
for _, tab in ipairs(talentTabs) do
    tab.talents = talentTabData[tab.name] or {}
end

local talentPopupWidth = 800
local talentPopupHeight = 625
popups.talents.width = talentPopupWidth
popups.talents.height = talentPopupHeight

local talentBoxSize = 144  -- Talent box size
local talentBoxSpacing = 10  -- Spacing between boxes
local talentBoxPadding = 20  -- Padding around grid
local talentTooltipWidth = 350


Overworld.availableTalentPoints = 5

local function getRequiredSouls(level)
    if level == 1 then
        return 1  -- Level 1 to 2 requires 1 soul
    elseif level == 2 then
        return 100  -- Level 2 to 3 requires 5 souls
    elseif level == 3 then
        return 150 -- Level 3 to 4 requires 10 souls
    else
        return getRequiredSouls(level - 1) + 50  -- Each subsequent level requires 10 more souls than the previous
    end
end


-- Overworld.lua

function Overworld.drawTalentPopup(popup)
    -- Draw popup background
    love.graphics.setColor(popupBackgroundColor)
    love.graphics.rectangle("fill", popup.x, popup.y, popup.width, popup.height, 10, 10)

    -- Draw popup border
    love.graphics.setColor(popupBorderColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", popup.x, popup.y, popup.width, popup.height, 10, 10)
    love.graphics.setLineWidth(1)

    -- Draw tabs (General, Combat, Abilities)
    local tabWidth = popup.width / 3
    local tabHeight = 40
    for i, tab in ipairs(talentTabs) do
        local tabX = popup.x + (i - 1) * tabWidth
        local tabY = popup.y

        -- Determine tab color based on its name and active state
        local tabColor
        if tab.name == "General" then
            tabColor = tab.active and activeTabColor or generalTabColor
        elseif tab.name == "Combat" then
            tabColor = tab.active and activeTabColor or combatTabColor
        elseif tab.name == "Abilities" then
            tabColor = tab.active and activeTabColor or abilitiesTabColor
        else
            tabColor = {0.2, 0.2, 0.2, 1}
        end

        love.graphics.setColor(tabColor)
        love.graphics.rectangle("fill", tabX, tabY, tabWidth, tabHeight, 5, 5)
        love.graphics.setColor(uiBorderColor)
        love.graphics.rectangle("line", tabX, tabY, tabWidth, tabHeight, 5, 5)
        love.graphics.setColor(uiTextColor)
        love.graphics.printf(tab.name, tabX, tabY + (tabHeight / 4), tabWidth, "center")
    end

   -- Identify the active tab
    local activeTab = talentTabs[1]
    for _, tab in ipairs(talentTabs) do
        if tab.active then
            activeTab = tab
            break
        end
    end

    -- Draw the talent grid
    local gridStartX = popup.x + talentBoxPadding
    local gridStartY = popup.y + tabHeight + talentBoxPadding
    popup.hoveredItem = nil  -- Reset hovered item

    for i, talent in ipairs(activeTab.talents) do
        local row = math.ceil(i / 3)
        local col = (i - 1) % 3 + 1
        local boxX = gridStartX + (col - 1) * (talentBoxSize + talentBoxSpacing)
        local boxY = gridStartY + (row - 1) * (talentBoxSize + talentBoxSpacing)

        -- Draw the talent box background
        love.graphics.setColor(0.4, 0.4, 0.4, 1)
        love.graphics.rectangle("fill", boxX, boxY, talentBoxSize, talentBoxSize, 5, 5)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", boxX, boxY, talentBoxSize, talentBoxSize, 5, 5)

        -- Draw "points spent" as X/Y if maxRank > 0
        if talent.maxRank > 0 then
            local rankStr = string.format("%d/%d", talent.currentRank, talent.maxRank)
            love.graphics.setColor(uiTextColor)
            love.graphics.printf(rankStr, boxX, boxY + (talentBoxSize / 2) - 8, talentBoxSize, "center")
        end

        -- Draw the talent icon if available
        if Overworld.talentIcons[talent.id] then
           
            local icon = Overworld.talentIcons[talent.id]
            local iconSize = 64  -- Desired icon size (64x64)
            local iconScale = (talentBoxSize - 16) / 64  -- (96 - 16) / 64 = 1.5

            love.graphics.draw(
                icon,
                boxX + (talentBoxSize - icon:getWidth() * iconScale) / 2,
                boxY + (talentBoxSize - icon:getHeight() * iconScale) / 2,
                0,
                iconScale,
                iconScale
            )
        else
            -- Optional: Draw a placeholder icon or skip
            
            -- Uncomment below to draw a placeholder
            -- if Overworld.placeholderIcon then
            --     local icon = Overworld.placeholderIcon
            --     local iconScale = (talentBoxSize - 16) / icon:getWidth()
            --     love.graphics.draw(
            --         icon,
            --         boxX + (talentBoxSize - icon:getWidth() * iconScale) / 2,
            --         boxY + (talentBoxSize - icon:getHeight() * iconScale) / 2,
            --         0,
            --         iconScale,
            --         iconScale
            --     )
            -- end
        end

       local mx, my = love.mouse.getPosition()
if mx >= boxX and mx <= (boxX + talentBoxSize) and
   my >= boxY and my <= (boxY + talentBoxSize) then

    popup.hoveredItem = talent
    -- Flashing border effect:
    local flashIndex = (math.floor(love.timer.getTime() * 10) % #colorPalette) + 1
    local flashColor = colorPalette[flashIndex]
    love.graphics.setColor(flashColor)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", boxX, boxY, talentBoxSize, talentBoxSize, 5, 5)
    love.graphics.setLineWidth(1)
    -- (Remove any old tooltip code here if not needed)
end
    end
    -- Draw info panel if a talent is hovered
    local infoPanelWidth = 230    -- Fixed width
    local infoPanelHeight = 150   -- Fixed height (adjust as needed)
    local infoPanelX = popup.x + popup.width - infoPanelWidth - talentBoxPadding  -- Fixed X position
    local infoPanelY = gridStartY     -- Fixed Y position within the popup

    

    if popup.hoveredItem then
        -- Define fixed Y offsets for text elements
        local nameYOffset        = 10
        local rankYOffset        = 40    -- Already swapped
        local bonusYOffset       = 70    -- New y-offset
        local descriptionYOffset = 100   -- Already swapped
        local textPadding        = 10    -- Horizontal padding for text

        -- Draw the talent information with fixed spacing
        love.graphics.setFont(Overworld.gothicFontSmall)

        -- Talent Name
        love.graphics.setColor(Overworld.colors.talentName)
        love.graphics.printf(
            popup.hoveredItem.name,
            infoPanelX + textPadding,
            infoPanelY + nameYOffset,
            infoPanelWidth - 2 * textPadding,
            "left"
        )

        -- Rank Information
        love.graphics.setColor(Overworld.colors.talentPoints)
        local rankStr = string.format("Rank: %d/%d", popup.hoveredItem.currentRank, popup.hoveredItem.maxRank)
        love.graphics.printf(
            rankStr,
            infoPanelX + textPadding,
            infoPanelY + rankYOffset,
            infoPanelWidth - 2 * textPadding,
            "left"
        )

        -- Total Bonus Information
        local totalBonus = popup.hoveredItem:getValue()
        local formattedBonus
        if totalBonus < 1 then
            formattedBonus = string.format("+%.0f%%", totalBonus * 100)
        else
            formattedBonus = string.format("+%d", totalBonus)
        end
        local bonusStr = string.format("Total: %s", formattedBonus)
        love.graphics.setColor(Overworld.colors.talentPoints)
        love.graphics.printf(
            bonusStr,
            infoPanelX + textPadding,
            infoPanelY + bonusYOffset,
            infoPanelWidth - 2 * textPadding,
            "left"
        )

-- Talent Description
love.graphics.setColor(Overworld.colors.talentDescription)

local descWidth = infoPanelWidth - 2 * textPadding
local descText = popup.hoveredItem.description

-- Get the wrapped lines.
local wrappedDesc, linesUsed = love.graphics.getFont():getWrap(descText, descWidth)
-- If the first return is a number, swap the values.
if type(wrappedDesc) == "number" then
    wrappedDesc, linesUsed = linesUsed, wrappedDesc
end
local descriptionHeight = #wrappedDesc * love.graphics.getFont():getHeight()

love.graphics.printf(
    descText,
    infoPanelX + textPadding,
    infoPanelY + descriptionYOffset,
    descWidth,
    "left"
)

-- Display the soul level requirement below the description if needed.
if souls.level < popup.hoveredItem.soulsReq then
    love.graphics.setColor(1, 0, 0, 1) -- Red color
    local reqText = string.format("REQUIRES SOUL LEVEL %d", popup.hoveredItem.soulsReq)
    love.graphics.printf(
        reqText,
        infoPanelX + textPadding,
        infoPanelY + descriptionYOffset + descriptionHeight + 10,
        descWidth,
        "center"
    )
end



    else
        -- Draw the default message in the fixed info panel
        love.graphics.setFont(Overworld.gothicFontSmall)
        love.graphics.setColor(uiTextColor)
        love.graphics.printf(
            "Hover over a talent\nto see details.",
            infoPanelX + 10,
            infoPanelY + 10,
            infoPanelWidth - 20,
            "left"
        )
    end

    -- Show how many leftover points we have
    love.graphics.setColor(uiTextColor)
    love.graphics.printf(
        "Available Talent Points: " .. Overworld.availableTalentPoints,
        popup.x,
        popup.y + popup.height - 50,
        popup.width,
        "center"
    )
end


----------------------------------------------------------------
-- Basic Overworld State
----------------------------------------------------------------
Overworld.currentLevel = {
    name = "The Infested Grove",
    difficulty = "Easy"
}

Overworld.mapImage = love.graphics.newImage("assets/overworldPROTO.png")
Overworld.mapImage:setFilter("nearest","nearest")

Overworld.totalFrames       = 1
Overworld.frameWidth        = Overworld.mapImage:getWidth() / Overworld.totalFrames
Overworld.frameHeight       = Overworld.mapImage:getHeight()
Overworld.width             = Overworld.frameWidth
Overworld.height            = Overworld.frameHeight
Overworld.currentFrame      = 1
Overworld.animationTimer    = 0
Overworld.animationSpeed    = 0.5
Overworld.frames            = {}

for i = 0, Overworld.totalFrames - 1 do
    local quad = love.graphics.newQuad(
        i * Overworld.frameWidth, 0,
        Overworld.frameWidth, Overworld.frameHeight,
        Overworld.mapImage:getDimensions()
    )
    table.insert(Overworld.frames, quad)
end

Overworld.playerSprite   = love.graphics.newImage("assets/wagon.png")
Overworld.playerSprite:setFilter("nearest","nearest")
Overworld.visionRadius   = 400

Overworld.nodeIcon       = love.graphics.newImage("assets/Bonepitnode.png")
Overworld.nodeIcon:setFilter("nearest","nearest")
Overworld.nodeIcon2      = love.graphics.newImage("assets/draculsdennode.png")
Overworld.nodeIcon2:setFilter("nearest","nearest")

Overworld.gothicFontLarge = love.graphics.newFont("fonts/gothic.ttf", 24)
Overworld.gothicFontSmall = love.graphics.newFont("fonts/gothic.ttf", 16)
Overworld.gothicFontTitle = love.graphics.newFont("fonts/gothic.ttf", 36)
Overworld.gothicFontLarge:setFilter("nearest","nearest")
Overworld.gothicFontSmall:setFilter("nearest","nearest")
Overworld.gothicFontTitle:setFilter("nearest","nearest")

-- Flag to indicate a new equipment item has been added
Overworld.newEquipmentItem = false

-- Load the exclamation mark image
Overworld.exclamationImage = love.graphics.newImage("assets/exclamation.png")
Overworld.exclamationImage:setFilter("nearest", "nearest")

Overworld.bobAmplitude    = 5
Overworld.bobFrequency    = 20
Overworld.bobOffset       = -5

Overworld.windowWidth     = love.graphics.getWidth()
Overworld.windowHeight    = love.graphics.getHeight()

Overworld.equipmentScrollY = 0

Overworld.nodeHoverColors = {
    {0.0, 0.0, 1.0},
    {0.6, 0.0, 0.0},
}

Overworld.hoveredButton   = false
local scaleFactor
local zoomLevel           = 3
local cameraX, cameraY    = 0, 0


----------------------------------------------------------------
-- Overworld Node Setup
----------------------------------------------------------------
Overworld.nodes = {
    {x = 358, y = 373, name = "Infested Grove", details = "", accessible = true},
    {x = 358, y = 563, name = "The Bonepit",     details = "", accessible = true},
    {x = 615, y = 563, name = "Overgrown Temple", details = "", accessible = true},
    {x = 615, y = 210, name = "Frozen Keep",      details = "", accessible = true},
    {x = 905, y = 210, name = "Armory",           details = "", accessible = true},
    {x = 905, y = 410, name = "Magma Prison",     details = "", accessible = true},
    {x = 905, y = 630, name = "Eternal Gate",     details = "", accessible = true},
    {x = 1095,y = 630, name = "UNKNOWN",          details = "", accessible = true}
}

function Overworld.wheelmoved(dx, dy)
    if popups.equipment.visible then
        Overworld.equipmentScrollY = Overworld.equipmentScrollY - (dy * 20)
    end
    if popups.stats.visible and Overworld.statsWindow then
        Overworld.statsWindow:wheelmoved(dx, dy)
    end
end


local function capitalizeFirstLetter(str)
    return (str:gsub("^%l", string.upper))
end

function Overworld.scaleNodes()
    for i, node in ipairs(Overworld.nodes) do
        node.scaledX = node.x * scaleFactor
        node.scaledY = node.y * scaleFactor
    end
end

function Overworld.updatePlayerPosition()
    Overworld.playerX = Overworld.nodes[Overworld.selectedNode].scaledX
    Overworld.playerY = Overworld.nodes[Overworld.selectedNode].scaledY
end

Overworld.paths = {
    {1,2}, {2,3}, {3,4}, {4,5}, {5,6}, {6,7}, {7,8}
}

Overworld.selectedNode    = 1
Overworld.targetNode      = Overworld.selectedNode
Overworld.playerSize      = 2
Overworld.playerX         = Overworld.nodes[Overworld.selectedNode].x
Overworld.playerY         = Overworld.nodes[Overworld.selectedNode].y
Overworld.moveSpeed       = 300
Overworld.moving          = false
Overworld.playerDirection = -1

-- Define the function within the Overworld table
function Overworld.findConnectedNodeInDirection(currentNodeIndex, direction)
    -- Validate current node
    local currentNode = Overworld.nodes[currentNodeIndex]
    if not currentNode then
      
        return nil
    end

    -- Find all nodes connected to the current node via Overworld.paths
    local connectedNodes = {}
    for _, path in ipairs(Overworld.paths) do
        if path[1] == currentNodeIndex then
            table.insert(connectedNodes, path[2])
        elseif path[2] == currentNodeIndex then
            table.insert(connectedNodes, path[1])
        end
    end

    -- Determine the node that best matches the desired direction
    local selectedNode = nil
    local minDistance = math.huge

    for _, nodeIndex in ipairs(connectedNodes) do
        local node = Overworld.nodes[nodeIndex]
        if node then
            local dx = node.x - currentNode.x
            local dy = node.y - currentNode.y

            -- Direction logic:
            if direction == "up" and dy < 0 then
                local distance = math.abs(dy)
                if distance < minDistance then
                    minDistance = distance
                    selectedNode = nodeIndex
                end
            elseif direction == "down" and dy > 0 then
                local distance = math.abs(dy)
                if distance < minDistance then
                    minDistance = distance
                    selectedNode = nodeIndex
                end
            elseif direction == "left" and dx < 0 then
                local distance = math.abs(dx)
                if distance < minDistance then
                    minDistance = distance
                    selectedNode = nodeIndex
                end
            elseif direction == "right" and dx > 0 then
                local distance = math.abs(dx)
                if distance < minDistance then
                    minDistance = distance
                    selectedNode = nodeIndex
                end
            end
        end
    end

    -- Debugging output
    if selectedNode then
        print(string.format("Moving from Node %d to Node %d (%s)", currentNodeIndex, selectedNode, direction))
    else
        print(string.format("No connected node found in direction '%s' from Node %d.", direction, currentNodeIndex))
    end

    return selectedNode
end

----------------------------------------------------------------
-- UI Settings
----------------------------------------------------------------
local uiScale      = 1.25
local baseWidth    = 250
local baseHeight   = 120
local width        = math.floor(baseWidth * uiScale)
local height       = math.floor(baseHeight * uiScale)
local uiX          = 850
local uiY          = 30

local baseTabWidth  = 80
local baseTabHeight = 30
local tabWidth      = math.floor(baseTabWidth  * uiScale)
local tabHeight     = math.floor(baseTabHeight * uiScale)

local tabXOffsets = {10*uiScale, 100*uiScale, 190*uiScale}
tabXOffsets[1] = math.floor(tabXOffsets[1])
tabXOffsets[2] = math.floor(tabXOffsets[2])
tabXOffsets[3] = math.floor(tabXOffsets[3])

----------------------------------------------------------------
-- Overworld Initialization
----------------------------------------------------------------
-- Overworld.lua

function Overworld.init()
    scaleFactor = zoomLevel
    Overworld.scaleNodes()
    Overworld.updatePlayerPosition()
    Overworld.moving = false

    -- Initialize the flag
    Overworld.newEquipmentItem = false

    -- Create equipment and print its state
   if not Overworld.equipment then
    Overworld.equipment = Equipment.new()
    equipment = Overworld.equipment  -- Global alias for compatibility
end



    -- Override the addItem function to set the new equipment flag
    local originalAddItem = equipment.addItem
    equipment.addItem = function(self, item)
        originalAddItem(self, item)
        Overworld.newEquipmentItem = true
       
    end

    -- Preload talent icons
    Overworld.talentIcons = {}
    local allTalents = talentSystem.getAllTalents()
    for _, talent in ipairs(allTalents) do
        if talent.iconPath then
            Overworld.talentIcons[talent.id] = love.graphics.newImage(talent.iconPath)
            Overworld.talentIcons[talent.id]:setFilter("nearest", "nearest")
        else
            -- Handle talents without an icon (optional)
            Overworld.talentIcons[talent.id] = nil
            
        end
    end

    -- start overworld music
    playMusic("assets/sounds/music/overworld.wave")

    -- end init
end




----------------------------------------------------------------
-- MAIN DRAW
----------------------------------------------------------------
function Overworld.draw()
    Overworld.drawMap()
    Overworld.drawPlayer()
    OverworldEffects.draw(Overworld.playerX, Overworld.playerY, Overworld.visionRadius, cameraX, cameraY)
     
    Overworld.drawPersistentUI()
     
    Overworld.drawPopups() 
     Overworld.drawTooltip()
     
    Overworld.drawSoulsBar()
    if Options.visible then
        love.graphics.push()
        love.graphics.origin()
        local popupW, popupH = 600, 400
        local popupX = (love.graphics.getWidth()-popupW)/2
        local popupY = (love.graphics.getHeight()-popupH)/2
        Options.draw(popupX, popupY, popupW, popupH, promptFont, colorPalette, arrowImage)
        love.graphics.pop()
    end
end


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

    love.graphics.setColor(1,1,1)
    love.graphics.draw(
        Overworld.playerSprite,
        x, y,
        0,
        spriteScale * Overworld.playerDirection,
        spriteScale,
        Overworld.playerSprite:getWidth()/1.5,
        Overworld.playerSprite:getHeight()/1.5
    )
end

----------------------------------------------------------------
-- UI: The Box in Top-Right Corner + Tabs
----------------------------------------------------------------
function Overworld.drawCurrentLevelDisplay()
    local x = uiX
    local y = uiY

    love.graphics.setColor(uiBackgroundColor)
    love.graphics.rectangle("fill", x, y, width, height, 10, 10)

    love.graphics.setColor(uiBorderColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height, 10, 10)

    love.graphics.setFont(Overworld.gothicFontTitle)
    love.graphics.setColor(uiTextColor)
    love.graphics.printf(Overworld.currentLevel.name, x + 10, y + 10, width - 20, "center")

    local tabY = y + height - (tabHeight / 2)
    local tabs = {
        {name = "Talents", popup = "talents", tx = x + tabXOffsets[1], ty = tabY, bg = tabTalentsColor},
        {name = "Relics", popup = "equipment", tx = x + tabXOffsets[2], ty = tabY, bg = tabEquipmentColor},
        {name = "Stats", popup = "stats", tx = x + tabXOffsets[3], ty = tabY, bg = tabStatsColor}
    }

    love.graphics.setFont(Overworld.gothicFontSmall)
    for _, tab in ipairs(tabs) do
        love.graphics.setColor(tab.bg)
        love.graphics.rectangle("fill", tab.tx, tab.ty, tabWidth, tabHeight, 5, 5)
        love.graphics.setColor(uiBorderColor)
        love.graphics.rectangle("line", tab.tx, tab.ty, tabWidth, tabHeight, 5, 5)
        love.graphics.setColor(uiTextColor)
        love.graphics.printf(tab.name, tab.tx, tab.ty + (tabHeight - Overworld.gothicFontSmall:getHeight()) / 2, tabWidth, "center")

        -- Check if the current tab is Equipment and if there's a new item
        if tab.name == "Equipment" and Overworld.newEquipmentItem then
            local exclamationScale = 0.5  -- Adjust scale as needed
            local exclamationWidth = Overworld.exclamationImage:getWidth() * exclamationScale
            local exclamationHeight = Overworld.exclamationImage:getHeight() * exclamationScale

            -- Position the exclamation mark at the top-right corner of the Equipment tab
            local exclamationX = tab.tx + tabWidth - exclamationWidth - 5  -- 5px padding from the right
            local exclamationY = tab.ty + 5  -- 5px padding from the top

            love.graphics.draw(Overworld.exclamationImage, exclamationX, exclamationY, 0, exclamationScale, exclamationScale)
        end
    end
end

function Overworld.drawPopups()
    for key, popup in pairs(popups) do
        if popup.visible and key ~= "enterConfirmation" then
            if key == "removeConfirmation" then
                Overworld.drawRemoveConfirmation(popup)
            elseif key == "talents" then
                Overworld.drawTalentPopup(popup)
            elseif key == "soulLevelUp" then
                Overworld.drawSoulLevelUpPopup(popup)
            else
                Overworld.drawPopup(popup, key)
            end
        end
    end

    if popups.enterConfirmation.visible then
        Overworld.drawEnterConfirmation(popups.enterConfirmation)
    end
    
    if popups.stats.visible then
    Overworld.statsWindow.visible = true
    Overworld.statsWindow:draw()
else
    Overworld.statsWindow.visible = false
end


end





function Overworld.drawRemoveConfirmation(popup)
    -- Draw the background
    love.graphics.setColor(popupBackgroundColor)
    love.graphics.rectangle("fill", popup.x, popup.y, popup.width, popup.height, 10, 10)

    -- Draw the border
    love.graphics.setColor(popupBorderColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", popup.x, popup.y, popup.width, popup.height, 10, 10)

    -- Draw the title
    love.graphics.setColor(popupTitleBarColor)
    love.graphics.rectangle("fill", popup.x, popup.y, popup.width, 40, 10, 10)

    -- Draw the title text
    love.graphics.setFont(Overworld.gothicFontSmall)
    love.graphics.setColor(popupTextColor)
    love.graphics.printf("Confirm Removal", popup.x, popup.y + 10, popup.width, "center")

    -- Draw the confirmation message
    love.graphics.setFont(Overworld.gothicFontSmall)
    love.graphics.setColor(1, 1, 1, 1)
    local message = string.format("Are you sure you want to remove '%s'?", popup.item.name)
    love.graphics.printf(message, popup.x + 10, popup.y + 60, popup.width - 20, "center")

    -- Draw the "Remove" and "Cancel" buttons with increased spacing
    local buttonWidth = 100
    local buttonHeight = 40
    local buttonSpacing = 40    -- Increased spacing from 20 to 40

    -- Remove Button
    local removeButtonX = popup.x + (popup.width / 2) - buttonWidth - (buttonSpacing / 2)
    local removeButtonY = popup.y + popup.height - buttonHeight - 30  -- Adjusted Y-position
    love.graphics.setColor(Overworld.colors.rustRed)
    love.graphics.rectangle("fill", removeButtonX, removeButtonY, buttonWidth, buttonHeight, 5, 5)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Remove", removeButtonX, removeButtonY + 10, buttonWidth, "center")

    -- Cancel Button
    local cancelButtonX = popup.x + (popup.width / 2) + (buttonSpacing / 2)
    local cancelButtonY = popup.y + popup.height - buttonHeight - 30  -- Adjusted Y-position
    love.graphics.setColor(Overworld.colors.warmGray)
    love.graphics.rectangle("fill", cancelButtonX, cancelButtonY, buttonWidth, buttonHeight, 5, 5)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Cancel", cancelButtonX, cancelButtonY + 10, buttonWidth, "center")
end

-- This function is called for each popup key: talents/equipment/stats
function Overworld.drawPopup(popup, key)
    love.graphics.setColor(popupBackgroundColor)
    love.graphics.rectangle("fill", popup.x, popup.y, popup.width, popup.height, 10, 10)

    love.graphics.setColor(popupBorderColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", popup.x, popup.y, popup.width, popup.height, 10, 10)

    love.graphics.setColor(popupTitleBarColor)
    love.graphics.rectangle("fill", popup.x, popup.y, popup.width, 30, 10, 10)

    love.graphics.setFont(Overworld.gothicFontSmall)
    love.graphics.setColor(popupTextColor)
    local displayKey = key == "equipment" and "Relics" or capitalizeFirstLetter(key)
    love.graphics.printf(displayKey, popup.x, popup.y + 5, popup.width, "center")


    if key == "equipment" then
        Overworld.drawEquipmentPopup(popup)
    else
        -- By default, just draw text in the middle for talents/stats
        love.graphics.setFont(Overworld.gothicFontLarge)
        love.graphics.setColor(popupTextColor)
        love.graphics.printf("[" .. capitalizeFirstLetter(key) .. " Content]", popup.x, popup.y + 40, popup.width, "center")
    end
end

function Overworld.drawEnterConfirmation(popup)
  -- Draw popup background
  love.graphics.setColor(popupBackgroundColor)
  love.graphics.rectangle("fill", popup.x, popup.y, popup.width, popup.height, 10, 10)

  -- Draw regular popup border using popupBorderColor
  love.graphics.setColor(popupBorderColor)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", popup.x, popup.y, popup.width, popup.height, 10, 10)
  love.graphics.setLineWidth(1)

  -- Draw the message above the buttons
  love.graphics.setFont(Overworld.gothicFontSmall)
  love.graphics.setColor(popupTextColor)
  love.graphics.printf("Do you wish to embark on this level?", popup.x + 10, popup.y + 20, popup.width - 20, "center")

  -- Button dimensions and positions
  local buttonWidth = 100
  local buttonHeight = 40
  local buttonSpacing = 40
  local embarkX = popup.x + (popup.width / 2) - buttonWidth - (buttonSpacing / 2)
  local embarkY = popup.y + popup.height - buttonHeight - 20
  local cancelX = popup.x + (popup.width / 2) + (buttonSpacing / 2)
  local cancelY = popup.y + popup.height - buttonHeight - 20

  -- Update selection based on mouse position
  local mx, my = love.mouse.getPosition()
  if mx >= embarkX and mx <= (embarkX + buttonWidth) and my >= embarkY and my <= (embarkY + buttonHeight) then
    popup.selectedButton = "embark"
  elseif mx >= cancelX and mx <= (cancelX + buttonWidth) and my >= cancelY and my <= (cancelY + buttonHeight) then
    popup.selectedButton = "cancel"
  end

  -- Draw Embark button (transparent fill)
  love.graphics.setColor(1, 1, 1, 0)
  love.graphics.rectangle("fill", embarkX, embarkY, buttonWidth, buttonHeight, 5, 5)
  love.graphics.setColor(popupBorderColor)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", embarkX, embarkY, buttonWidth, buttonHeight, 5, 5)
  love.graphics.setLineWidth(1)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf("Embark", embarkX, embarkY + 10, buttonWidth, "center")

  -- Draw Cancel button (transparent fill)
  love.graphics.setColor(1, 1, 1, 0)
  love.graphics.rectangle("fill", cancelX, cancelY, buttonWidth, buttonHeight, 5, 5)
  love.graphics.setColor(popupBorderColor)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", cancelX, cancelY, buttonWidth, buttonHeight, 5, 5)
  love.graphics.setLineWidth(1)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf("Cancel", cancelX, cancelY + 10, buttonWidth, "center")

  -- Highlight only the currently selected button using flashColor
  local flashIndex = (math.floor(love.timer.getTime() * 10) % #colorPalette) + 1
  local flashColor = colorPalette[flashIndex]
  if popup.selectedButton == "embark" then
    love.graphics.setColor(flashColor)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", embarkX, embarkY, buttonWidth, buttonHeight, 5, 5)
    love.graphics.setLineWidth(1)
  elseif popup.selectedButton == "cancel" then
    love.graphics.setColor(flashColor)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", cancelX, cancelY, buttonWidth, buttonHeight, 5, 5)
    love.graphics.setLineWidth(1)
  end
end

function Overworld.handleRemoveConfirmationClick(x, y)
    local popup = popups.removeConfirmation

    -- Define button dimensions
    local buttonWidth = 100
    local buttonHeight = 40
    local buttonSpacing = 20

    -- Remove Button
    local removeButtonX = popup.x + (popup.width / 2) - buttonWidth - (buttonSpacing / 2)
    local removeButtonY = popup.y + popup.height - buttonHeight - 20

    -- Cancel Button
    local cancelButtonX = popup.x + (popup.width / 2) + (buttonSpacing / 2)
    local cancelButtonY = popup.y + popup.height - buttonHeight - 20

    -- Check if Remove button is clicked
    if x >= removeButtonX and x <= (removeButtonX + buttonWidth) and
       y >= removeButtonY and y <= (removeButtonY + buttonHeight) then
       
        -- Remove the item from inventory
        local item = popup.item
        for i, invItem in ipairs(equipment.inventory) do
            if invItem == item then
                table.remove(equipment.inventory, i)
                print(string.format("Removed item '%s' from inventory.", item.name))
                break
            end
        end

        -- If the item was equipped, unequip it
        if equipment.equipped and equipment.equipped[item.slot] == item then
            equipment:unequipItem(item.slot)
            print(string.format("Item '%s' was equipped and has been unequipped.", item.name))
        end

        -- Close the confirmation popup
        popups.removeConfirmation.visible = false
        popups.removeConfirmation.item = nil

        -- Optionally, refresh the equipment popup to reflect changes
    end

    -- Check if Cancel button is clicked
    if x >= cancelButtonX and x <= (cancelButtonX + buttonWidth) and
       y >= cancelButtonY and y <= (cancelButtonY + buttonHeight) then
       
        -- Close the confirmation popup without removing
        popups.removeConfirmation.visible = false
        popups.removeConfirmation.item = nil
        print("Removal canceled by the player.")
    end
end

function Overworld.handleEnterConfirmationClick(x, y)
    local popup = popups.enterConfirmation
    local buttonWidth = 100
    local buttonHeight = 40
    local buttonSpacing = 40
    local embarkX = popup.x + (popup.width / 2) - buttonWidth - (buttonSpacing / 2)
    local embarkY = popup.y + popup.height - buttonHeight - 20
    local cancelX = popup.x + (popup.width / 2) + (buttonSpacing / 2)
    local cancelY = popup.y + popup.height - buttonHeight - 20

    if x >= embarkX and x <= (embarkX + buttonWidth) and
       y >= embarkY and y <= (embarkY + buttonHeight) then
        popup.visible = false
        Overworld.loadLevel(Overworld.selectedNode)
        return
    end

    if x >= cancelX and x <= (cancelX + buttonWidth) and
       y >= cancelY and y <= (cancelY + buttonHeight) then
        popup.visible = false
        return
    end
end

----------------------------------------------------------------
-- DRAW UI FRAME
----------------------------------------------------------------
function Overworld.drawPersistentUI()
    Overworld.drawCurrentLevelDisplay()
end



-- Overworld.addTestItem() after removing the random-quality approach

function Overworld.addTestItem()
   
    
    -- OR do a quick random approach with your existing qualities:
    local qualities = {"Common"}
    local itemQuality = qualities[math.random(#qualities)]
    
    -- Create a new item
    local rewardItem = Item.create(itemQuality)
    
    -- Add it to the global equipment that your Overworld uses
    equipment:addItem(rewardItem)

    -- Debug print
   
end


----------------------------------------------------------------
-- INPUT HANDLING
----------------------------------------------------------------
function Overworld.keypressed(key)
    if Options.visible then
        Options.keypressed(key)
        return
    end

    if Overworld.moving then return end

    if popups.soulLevelUp.visible then
        popups.soulLevelUp.visible = false
        popups.soulLevelUp.lines = {}
        popups.soulLevelUp.timer = 0
        return  -- Prevent other key presses while popup is active
    end


    local directionKeys = {
        ['up']='up',['w']='up',
        ['down']='down',['s']='down',
        ['left']='left',['a']='left',
        ['right']='right',['d']='right'
    }

    local direction = directionKeys[key]
    if direction then
        local nextNode = Overworld.findConnectedNodeInDirection(Overworld.selectedNode, direction)
        if nextNode then
            Overworld.targetNode = nextNode
            Overworld.moving = true
            if direction == 'left' then
                Overworld.playerDirection = 1
            elseif direction == 'right' then
                Overworld.playerDirection = -1
            end
        end
elseif key == "return" then
  if popups.enterConfirmation.visible then
    -- When already open, use arrow keys or return to confirm selection:
    if popups.enterConfirmation.selectedButton == "embark" then
      popups.enterConfirmation.visible = false
      Overworld.loadLevel(Overworld.selectedNode)
    else
      popups.enterConfirmation.visible = false
    end
    return
  end
  if not Overworld.moving then
    closeAllPopupsExcept("enterConfirmation")
    popups.enterConfirmation.visible = true
    popups.enterConfirmation.x = (love.graphics.getWidth() - popups.enterConfirmation.width) / 2
    popups.enterConfirmation.y = (love.graphics.getHeight() - popups.enterConfirmation.height) / 2
    popups.enterConfirmation.selectedButton = "cancel"  -- default selection
  end

    
    elseif key == "escape" then
        if Options.visible then
            Options.close()
        else
            Options.load()
            Options.visible = true
        end
 elseif key == "t" then
    if popups.talents.visible then
        popups.talents.visible = false
    else
        closeAllPopups()
        popups.talents.visible = true
    end
elseif key == "e" then
    if popups.equipment.visible then
        popups.equipment.visible = false
    else
        closeAllPopups()
        popups.equipment.visible = true
    end
elseif key == "c" then
    if popups.stats.visible then
        popups.stats.visible = false
    else
        closeAllPopups()
        popups.stats.visible = true
    end

    elseif key == "k" then  -- Add this condition
        Overworld.addTestItem()  -- Updated to reference the method
    end
    
    if popups.enterConfirmation.visible then
  if key == "left" or key == "right" then
    if popups.enterConfirmation.selectedButton == "cancel" then
      popups.enterConfirmation.selectedButton = "embark"
    else
      popups.enterConfirmation.selectedButton = "cancel"
    end
    return
  end
end

end

function Overworld.handleEquipmentRightClick(mx, my)
    local popup = popups.equipment
    local startY = popup.y + 40
    local rowHeight = 64 + 20  -- scaledH (64) + margin (15) = 79

    if not equipment or not equipment.inventory then return end

    local columns = 5
    local scaledW = 16 * 4      -- scale = 4, so 64 pixels
    local scaledH = 16 * 4      -- scale = 4, so 64 pixels
    local margin = 20
    local startX = popup.x + margin
    local columnWidth = scaledW + margin

    for i, item in ipairs(equipment.inventory) do
        local col = (i - 1) % columns
        local row = math.floor((i - 1) / columns)

        local itemX = startX + col * columnWidth
        local itemY = startY + row * rowHeight

        -- Define clickable area as the full item icon
        local clickableX = itemX
        local clickableY = itemY
        local clickableW = scaledW
        local clickableH = scaledH

        -- Check if mouse is within the item icon's bounds
        if mx >= clickableX and mx <= (clickableX + clickableW) and
           my >= clickableY and my <= (clickableY + clickableH) then

            -- Open the confirmation popup
            popups.removeConfirmation.visible = true
            popups.removeConfirmation.item = item

            -- Position the confirmation popup at the center of the screen
            popups.removeConfirmation.x = (love.graphics.getWidth() - popups.removeConfirmation.width) / 2
            popups.removeConfirmation.y = (love.graphics.getHeight() - popups.removeConfirmation.height) / 2

            print(string.format("Right-clicked on '%s'. Opened remove confirmation popup.", item.name))
            break
        end
    end
end

function Overworld.mousepressed(x, y, button)
  
    if popups.enterConfirmation and popups.enterConfirmation.visible then
    Overworld.handleEnterConfirmationClick(x, y)
    return
end
  
    if popups.soulLevelUp.visible then
        popups.soulLevelUp.visible = false
        popups.soulLevelUp.lines = {}
        popups.soulLevelUp.timer = 0
        return  -- Prevent other mouse clicks while popup is active
    end
  
    if button == 1 then
        -- 1) Check if they clicked top-level tabs: "Talents / Equipment / Stats"
        Overworld.handleTabClick(x, y)

        -- 2) If equipment is visible, handle equipment clicks
        if popups.equipment.visible then
            Overworld.handleEquipmentClick(x, y)
        end

        -- 3) If removeConfirmation is visible, handle removal
        if popups.removeConfirmation.visible then
            Overworld.handleRemoveConfirmationClick(x, y)
        end

        -- 4) If the Talents popup is open, let them:
        --    (a) switch sub‐tabs inside the popup,
        --    (b) click talents in the grid.
        if popups.talents.visible then
            -- The function that sets activeTab = General / Combat / Abilities
            -- so you can switch sub‐tabs within the popup.
            Overworld.handleTalentTabClick(x, y, popups.talents)

            -- The function that detects if you clicked on a specific talent box
            Overworld.handleTalentBoxClickDetection(x, y, popups.talents)
        end

    elseif button == 2 then
        if popups.equipment.visible then
            Overworld.handleEquipmentRightClick(x, y)
        end
    end
end


function Overworld.mousereleased(x, y, button)
end

function Overworld.mousemoved(x, y, dx, dy)
end

function Overworld.handleTabClick(x, y)
    local boxX = uiX
    local boxY = uiY
    local tabY = boxY + height - (tabHeight / 2)

    local tabs = {
        {name = "Talents", popup = "talents", tx = boxX + tabXOffsets[1], ty = tabY},
        {name = "Relics", popup = "equipment", tx = boxX + tabXOffsets[2], ty = tabY},
        {name = "Stats", popup = "stats", tx = boxX + tabXOffsets[3], ty = tabY}
    }

    for _, tab in ipairs(tabs) do
        if x >= tab.tx and x <= (tab.tx + tabWidth) and
           y >= tab.ty and y <= (tab.ty + tabHeight) then
            if not popups[tab.popup].visible then
                for key, p in pairs(popups) do
                    if key ~= tab.popup then
                        p.visible = false
                    end
                end
            end
            popups[tab.popup].visible = not popups[tab.popup].visible

            -- If Equipment tab is being opened, remove the exclamation mark
            if tab.name == "Equipment" and popups.equipment.visible then
                Overworld.newEquipmentItem = false
                print("Overworld.newEquipmentItem reset to false")  -- Debugging statement
            end

            -- Close the removeConfirmation popup if any other popup is opened
            if tab.popup ~= "removeConfirmation" then
                popups.removeConfirmation.visible = false
                popups.removeConfirmation.item = nil
            end

            return
        end
    end
end


-- Switch sub‐tabs (General / Combat / Abilities) inside the Talents popup
function Overworld.handleTalentTabClick(mx, my, popup)
    local tabWidth = popup.width / 3
    local tabHeight = 40

    for i, tab in ipairs(talentTabs) do
        local tabX = popup.x + (i - 1) * tabWidth
        local tabY = popup.y

        if mx >= tabX and mx <= (tabX + tabWidth) and
           my >= tabY and my <= (tabY + tabHeight) then
            -- Deactivate all other sub‐tabs
            for _, otherTab in ipairs(talentTabs) do
                otherTab.active = false
            end
            -- Activate the one clicked
            tab.active = true
            break
        end
    end
end

----------------------------------------------------------------
-- CLICK-TO-EQUIP/UNEQUIP LOGIC
----------------------------------------------------------------
function Overworld.handleEquipmentClick(mx, my)
    local popup = popups.equipment
    local startY = popup.y + 40  -- 
    local rowHeight = 64 + 20    -- scaledH (64) + margin (15) = 79

    if not equipment or not equipment.inventory then return end

    local columns = 5
    local scaledW = 16 * 4      -- scale = 4, so 64 pixels
    local scaledH = 16 * 4      -- scale = 4, so 64 pixels
    local margin = 20
    local startX = popup.x + margin
    local columnWidth = scaledW + margin

    for i, item in ipairs(equipment.inventory) do
        local col = (i - 1) % columns
        local row = math.floor((i - 1) / columns)

        local itemX = startX + col * columnWidth
        local itemY = startY + row * rowHeight

        -- Define clickable area as the full item icon
        local clickableX = itemX
        local clickableY = itemY
        local clickableW = scaledW
        local clickableH = scaledH

        -- Check if mouse is within the item icon's bounds
        if mx >= clickableX and mx <= (clickableX + clickableW) and
           my >= clickableY and my <= (clickableY + clickableH) then
           
            -- Debug: Confirm click detection
            print(string.format("Clicked on '%s' icon.", item.name))

            -- Check if item is already equipped
            local isEquipped = false
            if equipment.equipped and item.slot then
                isEquipped = (equipment.equipped[item.slot] == item)
            end

if isEquipped then
    equipment:unequipItem(item.slot)
    print(string.format("Unequipped item: %s", item.name))
else
    equipment:equipItem(item)
    print(string.format("Equipped item: %s", item.name))
    -- Save the current equipment table for use during level load
    persistentEquipment = equipment
    print("Persistent equipment set to:", persistentEquipment)
end

            -- Since one item is clicked at a time, exit the loop
            break
        end
    end
end

print("Overworld.equipment:", equipment, "Chest Item:", equipment.equipped.chest and equipment.equipped.chest.name or "none")


----------------------------------------------------------------
-- LOADING THE SELECTED LEVEL
----------------------------------------------------------------
function Overworld.loadLevel(selectedNode)
    closeAllPopupsExcept("enterConfirmation")
    OverworldEffects.stopAllSounds()
    print("loadLevel called with selectedNode =", selectedNode)

    if selectedNode == 1 then
        -- Node 1 is always SpiderForest
        print("Loading SpiderForest level (Node 1)")
        local sf = SpiderForest.new()
        Overworld.currentLevel.name = "The Infested Grove"
        startGame(sf)

    elseif selectedNode == 2 then
        print("Loading Bonepit level for Node 2")
        local bonepitLevel = Bonepit.new()
        Overworld.currentLevel.name = "The Bonepit"
        startGame(bonepitLevel)

    -- … other nodes …
    end
end

----------------------------------------------------------------
-- MOVEMENT/ANIMATION UPDATES
----------------------------------------------------------------
function Overworld.update(dt)
  
  
    if Overworld.moving then
        local target = Overworld.nodes[Overworld.targetNode]
        if not target or not target.scaledX or not target.scaledY then
            Overworld.moving = false
            return
        end

        local dx = target.scaledX - Overworld.playerX
        local dy = target.scaledY - Overworld.playerY
        local distance = math.sqrt(dx*dx + dy*dy)
        local moveSpeedDt = Overworld.moveSpeed * dt

        if distance < moveSpeedDt then
            Overworld.playerX = target.scaledX
            Overworld.playerY = target.scaledY
            Overworld.selectedNode = Overworld.targetNode
            Overworld.moving = false
            Overworld.updateCurrentLevelName()
        else
            Overworld.playerX = Overworld.playerX + (dx/distance)*Overworld.moveSpeed*dt
            Overworld.playerY = Overworld.playerY + (dy/distance)*Overworld.moveSpeed*dt
            Overworld.bobOffset = Overworld.bobOffset + dt*Overworld.bobFrequency
        end
    end


    cameraX = Overworld.playerX - Overworld.windowWidth/2
    cameraY = Overworld.playerY - Overworld.windowHeight/2
    cameraX = math.max(0, math.min(cameraX, Overworld.width * scaleFactor - Overworld.windowWidth))
    cameraY = math.max(0, math.min(cameraY, Overworld.height* scaleFactor - Overworld.windowHeight))
    
    Overworld.checkSoulLevelUp()
    
    if popups.soulLevelUp.visible then
        popups.soulLevelUp.timer = popups.soulLevelUp.timer + dt
        if popups.soulLevelUp.timer >= popups.soulLevelUp.duration then
            popups.soulLevelUp.visible = false
            popups.soulLevelUp.lines = {}
            popups.soulLevelUp.timer = 0
        end
    end
    
    OverworldEffects.update(Overworld.playerX, Overworld.playerY, Overworld.nodes, dt, Overworld.visionRadius, cameraX, cameraY)

    Overworld.animationTimer = Overworld.animationTimer + dt
    if Overworld.animationTimer >= Overworld.animationSpeed then
        Overworld.animationTimer = Overworld.animationTimer - Overworld.animationSpeed
        Overworld.currentFrame = Overworld.currentFrame + 1
        if Overworld.currentFrame > Overworld.totalFrames then
            Overworld.currentFrame = 1
        end
    end

    cameraX = Overworld.playerX - Overworld.windowWidth/2
    cameraY = Overworld.playerY - Overworld.windowHeight/2
    cameraX = math.max(0, math.min(cameraX, Overworld.width * scaleFactor - Overworld.windowWidth))
    cameraY = math.max(0, math.min(cameraY, Overworld.height* scaleFactor - Overworld.windowHeight))

    Overworld.hoveredButton = false
    
    
end

function Overworld.updateCurrentLevelName()
    local node = Overworld.nodes[Overworld.selectedNode]
    if node then
        Overworld.currentLevel.name = node.name or "Unknown Location"
    end
end

function Overworld.drawSoulsBar()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local barHeight = 30
    local barX, barY = 0, screenH - barHeight

    -- Background rectangle:
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", barX, barY, screenW, barHeight)

    -- Fill ratio:
    local ratio = souls.current / souls.max
    if ratio > 1 then ratio = 1 end

    -- Fill portion:
    love.graphics.setColor(1, 0.7, 0, 0.9)
    love.graphics.rectangle("fill", barX, barY, screenW * ratio, barHeight)

    -- Text: “Souls: current / max (Level X)”
    love.graphics.setColor(1, 1, 1, 1)
    local msg = string.format("Souls: %d/%d (Level %d)", souls.current, souls.max, souls.level)
    love.graphics.print(msg, barX + 10, barY + 5)
end


local function generateItemTooltip(item)
    local lines = {}
    table.insert(lines, item.name)
    for stat, value in pairs(item.bonusEffect) do
        table.insert(lines, string.format("+%d %s", value, capitalizeFirstLetter(stat)))
    end
    return table.concat(lines, "\n")
end


----------------------------------------------------------------
-- The Actual Equipment UI Drawing
----------------------------------------------------------------

function Overworld.drawEquipmentPopup(popup)
    if not equipment or not equipment.inventory then
        love.graphics.setFont(Overworld.gothicFontLarge)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("No equipment system found!", popup.x, popup.y + popup.height / 2 - 10, popup.width, "center")
        return
    end

   
    -- Limit the inventory to 20 items
    local maxItems = 20
    local displayInventory = {}
    for i = 1, math.min(maxItems, #equipment.inventory) do
        table.insert(displayInventory, equipment.inventory[i])
    end

    -- Grid parameters
    local iconSize    = 16    -- raw image size
    local scale       = 4     -- scale up from 16×16 to 64×64
    local scaledW     = iconSize * scale
    local scaledH     = iconSize * scale
    local margin      = 20    -- spacing between icons
    local columns     = 5     -- number of columns
    local rows        = 4     -- number of rows
    local startX      = popup.x + margin
    local startY      = popup.y + 40  -- Increased Y to prevent clipping by the title bar
    local columnWidth = scaledW + margin
    local rowHeight   = scaledH + margin

    -- Initialize hoveredItem to nil
    popup.hoveredItem = nil

    -- No scrolling needed as we're limiting to 20 items
    Overworld.equipmentScrollY = 0

    -- Loop through the displayInventory
    for i, item in ipairs(displayInventory) do
       
        local col = (i - 1) % columns
        local row = math.floor((i - 1) / columns)

        local itemX = startX + col * columnWidth
        local itemY = startY + row * rowHeight

        -- Draw item icon if present
        if item.image then
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(item.image, itemX, itemY, 0, scale, scale)
        else
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("fill", itemX, itemY, scaledW, scaledH)
        end
        
       

        -- Determine if the item is equipped
        local isEquipped = (equipment.equipped[item.slot] == item)

       if isEquipped then
    local flashIndex = (math.floor(love.timer.getTime() * 10) % #colorPalette) + 1
    local flashColor = colorPalette[flashIndex]
    love.graphics.setColor(flashColor)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", itemX - 2, itemY - 2, scaledW + 4, scaledH + 4)
    love.graphics.setLineWidth(1)
end


 -- Check if the mouse is hovering over this item
local mx, my = love.mouse.getPosition()
local mouseInside = (mx >= itemX and mx <= itemX + scaledW and
                     my >= itemY and my <= itemY + scaledH)
if mouseInside then
    popup.hoveredItem = item

    -- Use a default quality ("common") if item.quality is nil
    local quality = item.quality or "common"

    -- Set tooltip.lines for equipment
    local lines = {}
    table.insert(lines, {
        { text = item.name, color = qualityColors[string.lower(quality)] or tooltipTextColor }
    })
    -- For each bonus effect, use the mapping for display names
    for stat, value in pairs(item.bonusEffect) do
        local statName = affixDisplayNames[stat] or capitalizeFirstLetter(stat)
        local line = {
            { text = string.format("+%d", value), color = affixNumberColor },
            { text = " " .. statName, color = tooltipTextColor }
        }
        table.insert(lines, line)
    end

    Overworld.tooltip.lines = lines
    Overworld.tooltip.visible = true

    -- If the item is new, mark it as seen
    if item.isNew then
        item.isNew = false  -- Remove the new flag
    end
end



        -- Draw exclamation mark on new items
        if item.isNew then
            local exclamationScale = 1  -- Adjust scale as needed
            local exclamationWidth = Overworld.exclamationImage:getWidth() * exclamationScale
            local exclamationHeight = Overworld.exclamationImage:getHeight() * exclamationScale

            -- Position the exclamation mark at the top-right corner of the item
            local exclamationX = itemX + scaledW - exclamationWidth - 2  -- 2px padding from the right
            local exclamationY = itemY + 2  -- 2px padding from the top

            love.graphics.draw(Overworld.exclamationImage, exclamationX, exclamationY, 0, exclamationScale, exclamationScale)
        end
    end

    -- If no item is hovered, hide the tooltip
    if not popup.hoveredItem then
        Overworld.tooltip.visible = false
    end
end



function Overworld.drawTooltip()
    if not Overworld.tooltip.visible then
        return
    end

    local font = love.graphics.getFont()
    if not font then
        return
    end

    local lines = Overworld.tooltip.lines or {}
    if #lines == 0 then
        Overworld.tooltip.visible = false
        return
    end

    local lineSpacing = 5           -- spacing between lines
    local extraSpacingAfterSecondLine = 0  -- extra spacing after line 2
    local textHeight = font:getHeight()
    local tooltipPadding = tooltipPadding  -- using your existing global

    -- First, measure each line (now composed of segments)
    local measuredLines = {}  -- each element: { segments = { {text, color, width} }, totalWidth }
    local maxWidth = 0
    for i, line in ipairs(lines) do
        local segments = {}
        local totalWidth = 0
        for j, seg in ipairs(line) do
            local segWidth = font:getWidth(seg.text)
            table.insert(segments, { text = seg.text, color = seg.color, width = segWidth })
            totalWidth = totalWidth + segWidth
        end
        if totalWidth > maxWidth then
            maxWidth = totalWidth
        end
        table.insert(measuredLines, { segments = segments, totalWidth = totalWidth })
    end

    local tooltipWidth = math.min(maxWidth + 2 * tooltipPadding, tooltipMaxWidth)
    local tooltipHeight = (#measuredLines * (textHeight + lineSpacing)) + 2 * tooltipPadding + extraSpacingAfterSecondLine

    -- Position tooltip (using your existing logic)
    local popup = nil
    if popups.talents.visible and popups.talents.hoveredItem then
        popup = popups.talents
    elseif popups.equipment.visible and popups.equipment.hoveredItem then
        popup = popups.equipment
    end

    if popup == popups.talents then
        Overworld.tooltip.x = popup.x + popup.width - tooltipWidth - 10
        Overworld.tooltip.y = popup.y + 220
    elseif popup == popups.equipment then
        Overworld.tooltip.x = popup.x - tooltipWidth - 20
        Overworld.tooltip.x = math.max(10, Overworld.tooltip.x)
        Overworld.tooltip.y = popup.y + 60
    else
        Overworld.tooltip.x = tooltipPosition.x
        Overworld.tooltip.y = tooltipPosition.y
    end

    if popup then
        local maxBottom = popup.y + popup.height - 20
        if Overworld.tooltip.y + tooltipHeight > maxBottom then
            Overworld.tooltip.y = maxBottom - tooltipHeight
        end
    end

    -- Draw tooltip background and border
    love.graphics.setColor(tooltipBackgroundColor)
    love.graphics.rectangle("fill", Overworld.tooltip.x, Overworld.tooltip.y, tooltipWidth, tooltipHeight, 5, 5)
    love.graphics.setColor(tooltipBorderColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", Overworld.tooltip.x, Overworld.tooltip.y, tooltipWidth, tooltipHeight, 5, 5)
    love.graphics.setLineWidth(1)

    -- Draw each line (each segment in the line is printed sequentially)
    local cursorY = Overworld.tooltip.y + tooltipPadding
    for i, lineData in ipairs(measuredLines) do
        local cursorX = Overworld.tooltip.x + tooltipPadding
        for j, seg in ipairs(lineData.segments) do
            love.graphics.setColor(seg.color)
            love.graphics.print(seg.text, cursorX, cursorY)
            cursorX = cursorX + seg.width
        end

        if i == 2 then
            cursorY = cursorY + textHeight + lineSpacing + extraSpacingAfterSecondLine
        else
            cursorY = cursorY + textHeight + lineSpacing
        end
    end
end


function Overworld:addItemToEquipment(item)
    self.equipment:addItem(item)
    self.newEquipmentItem = true
end


------------------------------------------------------------------------------
-- NEW FUNCTION: handleTalentBoxClick
------------------------------------------------------------------------------
function Overworld.handleTalentBoxClick(clickedTalentIndex, activeTab)
    -- 'clickedTalentIndex' is the index in the activeTab.talents array
    -- 'activeTab' is something like {name="General", talents={...}}
    local t = activeTab.talents[clickedTalentIndex]
    if not t then return end  -- Safety check

    if t.maxRank <= 0 then
 
        return
    end

    if Overworld.availableTalentPoints <= 0 then
     
        return
    end

    -- Attempt to spend a point in the talent system:
       local success, errMsg = talentSystem.spendPoint(t.id, Overworld.availableTalentPoints, souls.level)
    if success then
        Overworld.availableTalentPoints = Overworld.availableTalentPoints - 1


if Overworld.player then
    talentSystem.applyTalentsToPlayer(Overworld.player)
end

if Overworld.statsWindow and Overworld.statsWindow.visible then
    Overworld.statsWindow:updateFromPlayer(Overworld.player)
end

    else
      
    end
end

------------------------------------------------------------------------------

function Overworld.handleTalentBoxClickDetection(mx, my, popup)
    local activeTab = talentTabs[1]
    for _, tab in ipairs(talentTabs) do
        if tab.active then
            activeTab = tab
            break
        end
    end

    local gridStartX = popup.x + talentBoxPadding
    local gridStartY = popup.y + tabHeight + talentBoxPadding

    for i, talent in ipairs(activeTab.talents) do
        local row = math.ceil(i / 3)  -- Changed from 4 to 3
        local col = (i - 1) % 3 + 1  -- Changed from 4 to 3
        local boxX = gridStartX + (col - 1) * (talentBoxSize + talentBoxSpacing)
        local boxY = gridStartY + (row - 1) * (talentBoxSize + talentBoxSpacing)

        if mx >= boxX and mx <= (boxX + talentBoxSize) and
           my >= boxY and my <= (boxY + talentBoxSize) then
           
            Overworld.handleTalentBoxClick(i, activeTab)
            return  -- Stop after the first match
        end
    end
end

-- Define level-up rewards
local levelUpRewards = {
    [2] = { "Reward: 2 Talent Points" },
    [3] = { "Reward: 2 Talent Points", "Unlocked: The Dark Forest" },
    [4] = { "Reward: 3 Talent Points", "Unlocked: Shadow Realm" },
    -- Add more levels and rewards as needed
}

function Overworld.checkSoulLevelUp()
    while souls.current >= souls.max do
        souls.current = souls.current - souls.max
        souls.level = souls.level + 1
        souls.max = getRequiredSouls(souls.level)
        Overworld.availableTalentPoints = Overworld.availableTalentPoints + 2
       
        
        -- Trigger Soul Level-Up Popup
        popups.soulLevelUp.visible = true
        popups.soulLevelUp.lines = {
            { text = "SOUL LEVEL INCREASED", color = {1, 1, 1, 1} },  -- White color
            { text = levelUpRewards[souls.level][1], color = Overworld.colors.talentPoints }
        }
        
        -- Add additional lines based on rewards
        if levelUpRewards[souls.level] then
            for i = 2, #levelUpRewards[souls.level] do
                table.insert(popups.soulLevelUp.lines, { text = levelUpRewards[souls.level][i], color = {1, 1, 1, 1} })
            end
        end

        -- Reset the timer
        popups.soulLevelUp.timer = 0
    end
end

function Overworld.drawSoulLevelUpPopup(popup)
    -- Darken the entire screen
    love.graphics.setColor(0, 0, 0, 0.5)  -- Semi-transparent black
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Draw the popup background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.9)  -- Dark gray
    love.graphics.rectangle("fill", popup.x, popup.y, popup.width, popup.height, 10, 10)

    -- Flashing border effect:
    local flashIndex = (math.floor(love.timer.getTime() * 10) % #colorPalette) + 1
    local flashColor = colorPalette[flashIndex]
    love.graphics.setColor(flashColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", popup.x, popup.y, popup.width, popup.height, 10, 10)

    -- Flashing title text:
    love.graphics.setFont(Overworld.gothicFontTitle)
    love.graphics.setColor(flashColor)
    love.graphics.printf("SOUL LEVEL INCREASED", popup.x, popup.y + 20, popup.width, "center")

    -- Draw the reward messages (non-flashing), skipping the duplicate title (index 1)
    love.graphics.setFont(Overworld.gothicFontSmall)
    local startY = popup.y + 80
    for i = 2, #popup.lines do
        local line = popup.lines[i]
        love.graphics.setColor(line.color)
        love.graphics.printf(line.text, popup.x, startY + (i - 2) * 30, popup.width, "center")
    end

    -- Instruction to dismiss the popup (non-flashing)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Press any key or click to continue...", popup.x, popup.y + popup.height - 40, popup.width, "center")
end



return Overworld
