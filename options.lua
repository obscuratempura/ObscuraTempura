local Settings = require("settings")

local Options = {}
Options.visible = false

local GameState = require("gameState")  -- Require the gameState module
local gameState = GameState.getInstance() -- Assuming a singleton pattern

local submenu = "main"
local confirmingResolution = false
local rebindingKey = false
local rebindAction = nil
local confirmationTimer = 0
local confirmationDuration = 10

local currentResolutionIndex = 1

local mainOptions = {"Video", "Sound", "Controls", "Back"}
local videoMenuOptions = {"Resolution", "Fullscreen: Off", "Back"} 
local soundOptions = { "Music Volume: 100%", "Effects Volume: 100%", "Back" }

local controlsList = {
    {action="esc", label="Escape/Menu", current=Settings.controls.esc},
    {action="talents", label="Talents", current=Settings.controls.talents},
    {action="equipment", label="Equipment", current=Settings.controls.equipment},
    {action="up", label="Move Up", current=Settings.controls.up},
    {action="down", label="Move Down", current=Settings.controls.down},
    {action="left", label="Move Left", current=Settings.controls.left},
    {action="right", label="Move Right", current=Settings.controls.right},
    {action="confirm", label="Confirm/Enter", current=Settings.controls.confirm},
    {action="Back", label="Back"}
}

local confirmOptions = {"OK", "Cancel"}
local confirmIndex = 1

local submenuOptions = {
    main = mainOptions,
    video = videoMenuOptions,
    sound = soundOptions,
    controls = controlsList,
    resolutionSelect = {}
}

local submenuIndex = {
    main = 1,
    video = 1,
    sound = 1,
    controls = 1,
    resolutionSelect = 1
}

local promptFont
local smallerFont
local arrowImage
local colorPalette
local lineSpacing
local normalPopupWidth = 600
local widePopupWidth = 800

local function playCursorSound() _G.GLOBAL_playCursorSound() end
local function playSelectionSound() _G.GLOBAL_playSelectionSound() end

-- Automatically detect and set the desktop resolution as current
local function setDesktopResolutionAsCurrent()
    local desktopW, desktopH = love.window.getDesktopDimensions(1)
    Settings.resolution.width = desktopW
    Settings.resolution.height = desktopH

    -- Try exact match
    local matchedIndex = nil
    for i, r in ipairs(Settings.availableResolutions) do
        if r.width == desktopW and r.height == desktopH then
            matchedIndex = i
            break
        end
    end

    if not matchedIndex then
        -- No exact match, pick closest by pixel count
        local bestDiff = math.huge
        for i, r in ipairs(Settings.availableResolutions) do
            local diff = math.abs((r.width*r.height) - (desktopW*desktopH))
            if diff < bestDiff then
                bestDiff = diff
                matchedIndex = i
            end
        end
    end

    currentResolutionIndex = matchedIndex
end

local function buildResolutionsList()
    local resolutionsList = {}
    for i, r in ipairs(Settings.availableResolutions) do
        local mark = (i == currentResolutionIndex) and "[" .. r.width .. "x" .. r.height .. "]" or r.width .. "x" .. r.height
        table.insert(resolutionsList, {action="res", index=i, label=mark})
    end
    table.insert(resolutionsList, {action="Back", label="Back"})
    return resolutionsList
end

local function updateVideoMenu()
    videoMenuOptions[2] = "Fullscreen: " .. (Settings.fullscreen and "On" or "Off")
end

local function updateSoundOptions()
    soundOptions[1] = "Music Volume: " .. math.floor(Settings.musicVolume * 100) .. "%"
    soundOptions[2] = "Effects Volume: " .. math.floor(Settings.effectsVolume * 100) .. "%"
end

function Options.load()
    submenu = "main"
    submenuIndex.main = 1
    submenuIndex.video = 1
    submenuIndex.sound = 1
    submenuIndex.controls = 1
    submenuIndex.resolutionSelect = 1
    Options.visible = true
    confirmingResolution = false
    rebindingKey = false
    rebindAction = nil
    confirmationTimer = 0

    -- Detect desktop resolution and set it as current
    setDesktopResolutionAsCurrent()

    updateVideoMenu()
    updateSoundOptions()
    
    --Pause the game
    gameState:setPause(true)
    
end

function Options.update(dt)
    if confirmingResolution then
        confirmationTimer = confirmationTimer + dt
        if confirmationTimer >= confirmationDuration then
            Settings.revertResolution()
            currentResolutionIndex = Options.findCurrentResolutionIndex()
            submenuOptions.resolutionSelect = buildResolutionsList()
            updateVideoMenu()
            confirmingResolution = false
        end
    end
end

function Options.findCurrentResolutionIndex()
    for i, r in ipairs(Settings.availableResolutions) do
        if r.width == Settings.resolution.width and r.height == Settings.resolution.height then
            return i
        end
    end
    return 1
end

local function getCurrentSet()
    return submenuOptions[submenu], submenuIndex[submenu], function(i) submenuIndex[submenu] = i end
end

local function drawCenteredText(font, text, x, y, maxWidth)
    love.graphics.setFont(font)
    local textWidth = font:getWidth(text)
    local drawX = x + (maxWidth - textWidth)/2
    love.graphics.print(text, drawX, y)
end

local function drawTwoColumns(options, currentIndex, popupX, popupY, popupWidth, popupHeight, fontUsed)
    local count = #options
    local half = math.ceil(count/2)
    local rows = half
    local totalHeight = rows * lineSpacing
    local startY = popupY + (popupHeight - totalHeight)/2
    local maxWidth = (popupWidth/2)-60
    local startX_left = popupX + 30
    local startX_right = popupX + popupWidth/2 + 30

    for i, option in ipairs(options) do
        local displayText
        if submenu == "controls" and option.action ~= "Back" then
            displayText = option.label..": "..option.current
        elseif type(option)=="table" then
            displayText = option.label
        else
            displayText = option
        end

        local col = (i <= half) and 1 or 2
        local row = (i <= half) and i or (i - half)
        local x = (col == 1) and startX_left or startX_right
        local y = startY + (row-1)*lineSpacing

        if i == currentIndex then
            local highlightColor = colorPalette[math.random(1, #colorPalette)]
            love.graphics.setColor(highlightColor)
            drawCenteredText(fontUsed, displayText, x, y, maxWidth)

            local textWidth = fontUsed:getWidth(displayText)
            local arrowScale = 2.0
            local arrowX = x + (maxWidth / 2) - (textWidth / 2) - (arrowImage:getWidth() * arrowScale) - 30
            local arrowY = y + (fontUsed:getHeight() / 2) - ((arrowImage:getHeight() * arrowScale) / 2)
            love.graphics.draw(arrowImage, arrowX, arrowY, 0, arrowScale, arrowScale)
        else
            if string.sub(displayText, 1, 1) == "[" and string.sub(displayText, -1) == "]" then
                love.graphics.setColor(1, 0, 0)
            else
                love.graphics.setColor(1,1,1)
            end
            drawCenteredText(fontUsed, displayText, x, y, maxWidth)
        end
    end
end

local function drawSingleColumn(options, currentIndex, popupX, popupY, popupWidth, popupHeight, fontUsed)
    local count = #options
    local totalHeight = count * lineSpacing
    local startY = popupY + (popupHeight - totalHeight)/2

    for i, option in ipairs(options) do
        local displayText
        if submenu == "controls" and option.action ~= "Back" then
            displayText = option.label..": "..option.current
        elseif type(option)=="table" then
            displayText = option.label
        else
            displayText = option
        end

        local y = startY + (i-1)*lineSpacing
        if i == currentIndex then
            local highlightColor = colorPalette[math.random(1, #colorPalette)]
            love.graphics.setColor(highlightColor)
            drawCenteredText(fontUsed, displayText, popupX, y, popupWidth)

            local textWidth = fontUsed:getWidth(displayText)
            local arrowScale = 2.0
            local arrowX = popupX + (popupWidth/2)-(textWidth/2)-(arrowImage:getWidth()*arrowScale)-30
            local arrowY = y+(fontUsed:getHeight()/2)-((arrowImage:getHeight()*arrowScale)/2)
            love.graphics.draw(arrowImage, arrowX, arrowY, 0, arrowScale, arrowScale)
        else
            if string.sub(displayText, 1, 1) == "[" and string.sub(displayText, -1) == "]" then
                love.graphics.setColor(1, 0, 0)
            else
                love.graphics.setColor(1,1,1)
            end
            drawCenteredText(fontUsed, displayText, popupX, y, popupWidth)
        end
    end
end

local function drawConfirmationPopup(messageLines, options, currentIndex)
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle("fill", 0,0, love.graphics.getWidth(), love.graphics.getHeight())

    local count = #messageLines + #options
    lineSpacing = promptFont:getHeight()+40
    local popupWidth = 400
    local popupHeight = 100 + count * lineSpacing
    local popupX = (love.graphics.getWidth() - popupWidth)/2
    local popupY = (love.graphics.getHeight() - popupHeight)/2

    love.graphics.setColor(0,0,0,0.9)
    love.graphics.rectangle("fill", popupX, popupY, popupWidth, popupHeight, 10,10)
    love.graphics.setColor(1,1,1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", popupX, popupY, popupWidth, popupHeight,10,10)

    local totalLines = count
    local totalHeight = totalLines * lineSpacing
    local startY = popupY + (popupHeight - totalHeight)/2

    for i, line in ipairs(messageLines) do
        local y = startY+(i-1)*lineSpacing
        love.graphics.setColor(1,1,1)
        drawCenteredText(promptFont, line, popupX, y, popupWidth)
    end

    local offset=#messageLines
    for i,opt in ipairs(options) do
        local y = startY+(offset+(i-1))*lineSpacing
        if i==currentIndex then
            local highlightColor=colorPalette[math.random(1,#colorPalette)]
            love.graphics.setColor(highlightColor)
            drawCenteredText(promptFont, opt, popupX, y, popupWidth)
            local textWidth=promptFont:getWidth(opt)
            local arrowScale=2.0
            local arrowX=popupX+(popupWidth/2)-(textWidth/2)-(arrowImage:getWidth()*arrowScale)-30
            local arrowY=y+(promptFont:getHeight()/2)-((arrowImage:getHeight()*arrowScale)/2)
            love.graphics.draw(arrowImage,arrowX,arrowY,0,arrowScale,arrowScale)
        else
            love.graphics.setColor(1,1,1)
            drawCenteredText(promptFont, opt, popupX, y, popupWidth)
        end
    end
end

local function drawRebindPopup(actionName)
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle("fill",0,0,love.graphics.getWidth(),love.graphics.getHeight())

    lineSpacing = promptFont:getHeight()+40
    local messageLines=2
    local popupWidth=400
    local popupHeight=100+messageLines*lineSpacing
    local popupX=(love.graphics.getWidth()-popupWidth)/2
    local popupY=(love.graphics.getHeight()-popupHeight)/2

    love.graphics.setColor(0,0,0,0.9)
    love.graphics.rectangle("fill",popupX,popupY,popupWidth,popupHeight,10,10)
    love.graphics.setColor(1,1,1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line",popupX,popupY,popupWidth,popupHeight,10,10)

    local totalHeight=messageLines*lineSpacing
    local startY=popupY+(popupHeight-totalHeight)/2

    love.graphics.setColor(1,1,1)
    drawCenteredText(promptFont, "Press a key to rebind '"..actionName.."'", popupX, startY, popupWidth)
    drawCenteredText(promptFont, "Press ESC to cancel", popupX, startY+lineSpacing, popupWidth)
end

function Options.draw(popupX, popupY, popupWidth, popupHeight, _promptFont, _colorPalette, _arrowImage)
    if not Options.visible then return end
    
    print("Options.draw called: visible=", Options.visible, "submenu=", submenu)
    
    promptFont = _promptFont
    arrowImage = _arrowImage
    colorPalette = _colorPalette

    if not smallerFont then
        smallerFont = love.graphics.newFont("fonts/gothic.ttf", 20)
    end

    lineSpacing = promptFont:getHeight() + 40

    local currentOptions = submenuOptions[submenu]
    local currentIndex = submenuIndex[submenu]

    if submenu == "resolutionSelect" then
        submenuOptions.resolutionSelect = buildResolutionsList()
        currentOptions = submenuOptions.resolutionSelect
    end

    if submenu == "video" then
        updateVideoMenu()
    elseif submenu == "sound" then
        updateSoundOptions()
    end

    local count = #currentOptions
    local baseHeight = 300
    local neededHeight = 50 + count*lineSpacing + 50
    local finalHeight = math.max(baseHeight, neededHeight)

    local useWide = (submenu=="resolutionSelect" or submenu=="controls")
    local fontUsed = useWide and smallerFont or promptFont
    local finalWidth = useWide and widePopupWidth or normalPopupWidth

    popupWidth = finalWidth
    popupHeight = finalHeight
    popupX=(love.graphics.getWidth()-popupWidth)/2
    popupY=(love.graphics.getHeight()-popupHeight)/2

    love.graphics.setColor(0,0,0,0.5)
    love.graphics.rectangle("fill",popupX,popupY,popupWidth,popupHeight,20,20)
    love.graphics.setColor(1,1,1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line",popupX,popupY,popupWidth,popupHeight,20,20)

    if confirmingResolution then
        local messageLines={
            "Confirm new resolution?",
            "Reverting in "..(confirmationDuration - math.floor(confirmationTimer)).."s"
        }
        drawConfirmationPopup(messageLines, confirmOptions, confirmIndex)
        return
    end

    if rebindingKey then
        drawRebindPopup(rebindAction)
        return
    end

    if submenu=="resolutionSelect" or submenu=="controls" then
        drawTwoColumns(currentOptions, currentIndex, popupX,popupY,popupWidth,popupHeight, fontUsed)
    else
        drawSingleColumn(currentOptions, currentIndex, popupX,popupY,popupWidth,popupHeight, fontUsed)
    end

    -- draw picked abilities on the right (no duplicates, show counts, border, shifted up more)
    local raw = (_G.player and _G.player.pickedAbilities) or {}
    if #raw > 0 then
        -- aggregate counts
        local agg = {}
        for _, name in ipairs(raw) do
            agg[name] = (agg[name] or 0) + 1
        end
        -- convert to list
        local list = {}
        for name, cnt in pairs(agg) do
            table.insert(list, { name = name, count = cnt })
        end
        table.sort(list, function(a,b) return a.name < b.name end)

        local panelW = 260
        local titleH = promptFont:getHeight()
        local itemSpacing = smallerFont:getHeight() + 6
        local panelH = titleH + 8 + (#list * itemSpacing) + 8
        local panelX = love.graphics.getWidth() - panelW - 20
        -- shift up an extra 40px
        local panelY = popupY + (popupHeight - panelH) / 2 - 40

        -- background
        love.graphics.setColor(0,0,0,0.7)
        love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 8,8)
        -- border
        love.graphics.setColor(1,1,1,0.9)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 8,8)

        -- rainbow title “ABILITIES”
        local title = "ABILITIES"
        love.graphics.setFont(promptFont)
        local totalW = promptFont:getWidth(title)
        local startX = panelX + (panelW - totalW)/2
        for i = 1, #title do
            local ch = title:sub(i,i)
            local col = colorPalette[((i-1) % #colorPalette) + 1]
            love.graphics.setColor(col)
            love.graphics.print(ch, startX + promptFont:getWidth(ch)*(i-1), panelY + 4)
        end

        -- list items
        love.graphics.setFont(smallerFont)
        love.graphics.setColor(1,1,1,1)
        for i, entry in ipairs(list) do
            local label = entry.name .. (entry.count > 1 and (" x"..entry.count) or "")
            local y = panelY + titleH + 8 + (i-1)*itemSpacing
            love.graphics.print(label, panelX + 10, y)
        end

        -- restore
        love.graphics.setFont(promptFont)
        love.graphics.setColor(1,1,1,1)
    end

    -- reset color
    love.graphics.setColor(1,1,1,1)
end

function Options.keypressed(key)
    if not Options.visible then return end

    if rebindingKey then
        if key=="escape" then
            rebindingKey=false
            rebindAction=nil
            return
        end
        Settings.rebindControl(rebindAction,key)
        for _, c in ipairs(submenuOptions.controls) do
            if c.action==rebindAction then
                c.current=key
                break
            end
        end
        rebindingKey=false
        rebindAction=nil
        playSelectionSound()
        return
    end

    if confirmingResolution then
        local currentOptions=confirmOptions
        if key=="up" or key=="w" then
            confirmIndex=confirmIndex-1
            if confirmIndex<1 then confirmIndex=#currentOptions end
            playCursorSound()
        elseif key=="down" or key=="s" then
            confirmIndex=confirmIndex+1
            if confirmIndex>#currentOptions then confirmIndex=1 end
            playCursorSound()
        elseif key=="return" then
            if currentOptions[confirmIndex]=="OK" then
                Settings.confirmResolution()
            else
                Settings.revertResolution()
            end
            currentResolutionIndex=Options.findCurrentResolutionIndex()
            submenuOptions.resolutionSelect=buildResolutionsList()
            updateVideoMenu()
            confirmingResolution=false
            playSelectionSound()
        elseif key=="escape" then
            Settings.revertResolution()
            currentResolutionIndex=Options.findCurrentResolutionIndex()
            submenuOptions.resolutionSelect=buildResolutionsList()
            updateVideoMenu()
            confirmingResolution=false
        end
        return
    end

    local currentOptions, currentIndex, setIndex = getCurrentSet()

    if submenu=="resolutionSelect" then
        if (key=="up" or key=="w") then
            currentIndex=currentIndex-1
            if currentIndex<1 then currentIndex=#currentOptions end
            setIndex(currentIndex)
            playCursorSound()
        elseif (key=="down" or key=="s") then
            currentIndex=currentIndex+1
            if currentIndex>#currentOptions then currentIndex=1 end
            setIndex(currentIndex)
            playCursorSound()
        elseif key=="return" then
            local choice=currentOptions[currentIndex]
            if choice.action=="Back" then
                submenu="video"
                playSelectionSound()
            else
                currentResolutionIndex=choice.index
                local r=Settings.availableResolutions[currentResolutionIndex]
                Settings.setResolution(r.width,r.height,Settings.fullscreen)
                confirmingResolution=true
                confirmationTimer=0
                playSelectionSound()
            end
        elseif key=="escape" then
            submenu="video"
        end
        return
    end

    if submenu=="video" then
        updateVideoMenu()
        if (key=="up" or key=="w") then
            currentIndex=currentIndex-1
            if currentIndex<1 then currentIndex=#currentOptions end
            setIndex(currentIndex)
            playCursorSound()
        elseif (key=="down" or key=="s") then
            currentIndex=currentIndex+1
            if currentIndex>#currentOptions then currentIndex=1 end
            setIndex(currentIndex)
            playCursorSound()
        elseif key=="return" then
            local opt=currentOptions[currentIndex]
            if opt=="Resolution" then
                submenuOptions.resolutionSelect=buildResolutionsList()
                submenu="resolutionSelect"
                submenuIndex.resolutionSelect=1
                playSelectionSound()
            elseif opt:find("Fullscreen") then
                Settings.setResolution(Settings.resolution.width,Settings.resolution.height,not Settings.fullscreen)
                confirmingResolution=true
                confirmationTimer=0
                playSelectionSound()
            elseif opt=="Back" then
                submenu="main"
                playSelectionSound()
            end
        elseif key=="escape" then
            submenu="main"
        end
        return
    end

    if submenu=="sound" then
        updateSoundOptions()
        if (key=="up" or key=="w") then
            currentIndex=currentIndex-1
            if currentIndex<1 then currentIndex=#currentOptions end
            setIndex(currentIndex)
            playCursorSound()
        elseif (key=="down" or key=="s") then
            currentIndex=currentIndex+1
            if currentIndex>#currentOptions then currentIndex=1 end
            setIndex(currentIndex)
            playCursorSound()
        elseif key=="return" then
            local opt=currentOptions[currentIndex]
            if opt=="Back" then
                submenu="main"
                playSelectionSound()
            elseif opt:find("Music Volume") then
                local newVol=Settings.musicVolume+0.1
                if newVol>1 then newVol=0 end
                Settings.setMusicVolume(newVol)
                updateSoundOptions()
                playSelectionSound()
            elseif opt:find("Effects Volume") then
                local newVol=Settings.effectsVolume+0.1
                if newVol>1 then newVol=0 end
                Settings.setEffectsVolume(newVol)
                updateSoundOptions()
                playSelectionSound()
            end
        elseif key=="escape" then
            submenu="main"
        end
        return
    end

    if submenu=="controls" then
        if (key=="up" or key=="w") then
            currentIndex=currentIndex-1
            if currentIndex<1 then currentIndex=#currentOptions end
            setIndex(currentIndex)
            playCursorSound()
        elseif (key=="down" or key=="s") then
            currentIndex=currentIndex+1
            if currentIndex>#currentOptions then currentIndex=1 end
            setIndex(currentIndex)
            playCursorSound()
        elseif key=="return" then
            local choice=currentOptions[currentIndex]
            if choice.action=="Back" then
                submenu="main"
                playSelectionSound()
            else
                rebindingKey=true
                rebindAction=choice.action
                playSelectionSound()
            end
        elseif key=="escape" then
            submenu="main"
        end
        return
    end

    if submenu=="main" then
        if (key=="up" or key=="w") then
            currentIndex=currentIndex-1
            if currentIndex<1 then currentIndex=#currentOptions end
            setIndex(currentIndex)
            playCursorSound()
        elseif (key=="down" or key=="s") then
            currentIndex=currentIndex+1
            if currentIndex>#currentOptions then currentIndex=1 end
            setIndex(currentIndex)
            playCursorSound()
        elseif key=="return" then
            local opt=currentOptions[currentIndex]
            if opt=="Video" then
                submenu="video"
                submenuIndex.video=1
                playSelectionSound()
            elseif opt=="Sound" then
                submenu="sound"
                submenuIndex.sound=1
                playSelectionSound()
            elseif opt=="Controls" then
                submenu="controls"
                submenuIndex.controls=1
                playSelectionSound()
            elseif opt=="Back" then
                Options.close()
                playSelectionSound()
            end
        elseif key=="escape" then
            Options.close()
        end
    end
end

function Options.mousemoved(x,y)
    if not Options.visible then return end
    if confirmingResolution or rebindingKey then return end

    local currentOptions, currentIndex, setIndex = getCurrentSet()
    local option, index = Options.getOptionAt(x,y)
    if option and index and index~=currentIndex then
        setIndex(index)
        playCursorSound()
    end
end

function Options.mousepressed(x, y, button)
    if not Options.visible or button~=1 then return end

    if confirmingResolution then
        local currentOptions=confirmOptions
        local messageCount=2
        local lineSpacingLocal=promptFont:getHeight()+40
        local totalLines=messageCount+#confirmOptions
        local popupWidth=400
        local popupHeight=100+totalLines*lineSpacingLocal
        local popupX=(love.graphics.getWidth()-popupWidth)/2
        local popupY=(love.graphics.getHeight()-popupHeight)/2
        local totalHeight=totalLines*lineSpacingLocal
        local startY=popupY+(popupHeight-totalHeight)/2
        local offset=messageCount

        for i,opt in ipairs(confirmOptions) do
            local yPos=startY+(offset+(i-1))*lineSpacingLocal
            local textHeight=promptFont:getHeight()
            if x>=popupX and x<=popupX+popupWidth and y>=yPos and y<=yPos+textHeight then
                if opt=="OK" then
                    Settings.confirmResolution()
                    currentResolutionIndex=Options.findCurrentResolutionIndex()
                    submenuOptions.resolutionSelect=buildResolutionsList()
                    updateVideoMenu()
                    confirmingResolution=false
                    playSelectionSound()
                elseif opt=="Cancel" then
                    Settings.revertResolution()
                    currentResolutionIndex=Options.findCurrentResolutionIndex()
                    submenuOptions.resolutionSelect=buildResolutionsList()
                    updateVideoMenu()
                    confirmingResolution=false
                end
                return
            end
        end
        return
    end

    if rebindingKey then
        return
    end

    local option, index = Options.getOptionAt(x,y)
    if option then
        local currentOptions, currentIndex, setIndex=getCurrentSet()
        if index then
            setIndex(index)
        end
        Options.selectOption(option)
        playSelectionSound()
    end
end

function Options.selectOption(option)
    if confirmingResolution or rebindingKey then return end
    local currentOptions, currentIndex, setIndex=getCurrentSet()

    if submenu=="main" then
        if option=="Video" then
            submenu="video"
            submenuIndex.video=1
        elseif option=="Sound" then
            submenu="sound"
            submenuIndex.sound=1
        elseif option=="Controls" then
            submenu="controls"
            submenuIndex.controls=1
        elseif option=="Back" then
            Options.close()
        end
    elseif submenu=="video" then
        if option=="Back" then
            submenu="main"
        elseif option=="Resolution" then
            submenuOptions.resolutionSelect=buildResolutionsList()
            submenu="resolutionSelect"
            submenuIndex.resolutionSelect=1
        elseif type(option)=="string" and option:find("Fullscreen") then
            Settings.setResolution(Settings.resolution.width,Settings.resolution.height,not Settings.fullscreen)
            confirmingResolution=true
            confirmationTimer=0
        end
    elseif submenu=="sound" then
        if option=="Back" then
            submenu="main"
        elseif type(option)=="string" and option:find("Music Volume") then
            local newVol=Settings.musicVolume+0.1
            if newVol>1 then newVol=0 end
            Settings.setMusicVolume(newVol)
            updateSoundOptions()
        elseif type(option)=="string" and option:find("Effects Volume") then
            local newVol=Settings.effectsVolume+0.1
            if newVol>1 then newVol=0 end
            Settings.setEffectsVolume(newVol)
            updateSoundOptions()
        end
    elseif submenu=="controls" then
        if option.action=="Back" then
            submenu="main"
        else
            rebindingKey=true
            rebindAction=option.action
        end
    elseif submenu=="resolutionSelect" then
        if option.action=="Back" then
            submenu="video"
        else
            currentResolutionIndex=option.index
            local r=Settings.availableResolutions[currentResolutionIndex]
            Settings.setResolution(r.width,r.height,Settings.fullscreen)
            confirmingResolution=true
            confirmationTimer=0
        end
    end
end

function Options.close()
    Options.visible=false
    
    --Unpause the game
    gameState:setPause(false)
end

return Options
